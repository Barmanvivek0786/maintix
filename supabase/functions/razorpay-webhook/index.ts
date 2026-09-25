// Razorpay webhook — the actual fix for "Payment could not be completed:
// the order is already paid" retries.
//
// Root cause of that error: the app previously only knew a payment
// succeeded if Razorpay's client SDK called onSuccess. If that callback
// never reached the app (killed while switching back from a UPI app, a
// dropped network response, the WebView being torn down, etc.) Razorpay
// had still CAPTURED the money, but Maintix had no record of it. The user,
// seeing what looked like a failure, retried — and Razorpay correctly
// refused to charge the same already-paid order again, showing exactly
// this screen. Money taken, no booking, confusing retry error.
//
// This endpoint is called directly by Razorpay's servers (not the app), so
// it doesn't depend on the phone at all. On `payment.captured` it looks up
// the PENDING row that create-razorpay-order wrote before checkout ever
// opened, marks it SUCCESS, and — if the client hasn't already created the
// booking — creates it from the stored cart snapshot. Idempotent: safe to
// receive the same event more than once (Razorpay retries on non-2xx).
//
// Setup required (one-time):
//   1. Razorpay Dashboard → Settings → Webhooks → add an endpoint pointing
//      at this function's URL, subscribe to `payment.captured` (and
//      optionally `payment.failed`), and set a webhook secret there.
//   2. `supabase secrets set RAZORPAY_WEBHOOK_SECRET=<that same secret>`

import { createClient } from "npm:@supabase/supabase-js@2";

const json = (body: unknown, status = 200) =>
  new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json" },
  });

function toHex(bytes: ArrayBuffer) {
  return [...new Uint8Array(bytes)]
    .map((byte) => byte.toString(16).padStart(2, "0"))
    .join("");
}

async function verifySignature(rawBody: string, signature: string, secret: string) {
  const cryptoKey = await crypto.subtle.importKey(
    "raw",
    new TextEncoder().encode(secret),
    { name: "HMAC", hash: "SHA-256" },
    false,
    ["sign"],
  );
  const digest = await crypto.subtle.sign(
    "HMAC",
    cryptoKey,
    new TextEncoder().encode(rawBody),
  );
  return toHex(digest) === signature;
}

Deno.serve(async (request) => {
  if (request.method !== "POST") {
    return json({ error: "Method not allowed" }, 405);
  }

  const webhookSecret = Deno.env.get("RAZORPAY_WEBHOOK_SECRET") ?? "";
  const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
  const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";

  if (!webhookSecret || !serviceRoleKey) {
    console.error("razorpay-webhook is not configured (missing secret/service role)");
    // Ack anyway — nothing productive Razorpay retrying can do here, and we
    // don't want to leak configuration state to callers.
    return json({ error: "Webhook not configured" }, 500);
  }

  // IMPORTANT: read the raw body for signature verification before any
  // JSON.parse — the signature is computed over the exact bytes Razorpay
  // sent.
  const rawBody = await request.text();
  const signature = request.headers.get("x-razorpay-signature") ?? "";
  if (!signature) {
    return json({ error: "Missing signature" }, 400);
  }

  const validSignature = await verifySignature(rawBody, signature, webhookSecret);
  if (!validSignature) {
    console.error("razorpay-webhook: invalid signature");
    return json({ error: "Invalid signature" }, 400);
  }

  let event: {
    event?: string;
    payload?: {
      payment?: { entity?: Record<string, unknown> };
    };
  };
  try {
    event = JSON.parse(rawBody);
  } catch {
    return json({ error: "Invalid JSON" }, 400);
  }

  const eventType = event.event ?? "";
  const paymentEntity = event.payload?.payment?.entity;

  // Only payment.captured actually needs reconciliation — that's the case
  // where money moved. We still ack everything else with 200 so Razorpay
  // doesn't keep retrying events we don't act on.
  if (eventType !== "payment.captured" || !paymentEntity) {
    return json({ received: true, skipped: true, event: eventType });
  }

  const orderId = String(paymentEntity.order_id ?? "");
  const paymentId = String(paymentEntity.id ?? "");
  const amount = Number(paymentEntity.amount ?? 0);

  if (!orderId || !paymentId) {
    console.error("razorpay-webhook: payment.captured missing order_id/payment_id");
    return json({ received: true, error: "Missing order_id/payment_id" }, 200);
  }

  const admin = createClient(supabaseUrl, serviceRoleKey);

  try {
    const { data: existing, error: fetchError } = await admin
      .from("payments")
      .select("id, user_id, status, booking_id, cart_snapshot, razorpay_payment_id")
      .eq("razorpay_order_id", orderId)
      .maybeSingle();

    if (fetchError) throw fetchError;

    if (!existing) {
      // No PENDING row — most likely create-razorpay-order's insert failed
      // (see its logs) or this order predates this migration. We can't
      // safely create a booking without knowing the user, so just log it
      // for manual reconciliation and ack the webhook.
      console.error(
        `razorpay-webhook: payment.captured for unknown order ${orderId} (payment ${paymentId}) — needs manual reconciliation`,
      );
      return json({ received: true, reconciled: false }, 200);
    }

    // Idempotent: Razorpay may deliver the same event more than once.
    if (existing.status === "SUCCESS" && existing.razorpay_payment_id === paymentId) {
      return json({ received: true, alreadyReconciled: true }, 200);
    }

    const { error: updateError } = await admin
      .from("payments")
      .update({
        status: "SUCCESS",
        razorpay_payment_id: paymentId,
        updated_at: new Date().toISOString(),
      })
      .eq("id", existing.id);
    if (updateError) throw updateError;

    // If the client already created the booking (normal happy path — the
    // webhook usually arrives after the app's own onSuccess), don't create
    // a second one.
    if (existing.booking_id) {
      return json({ received: true, reconciled: true, bookingAlreadyExisted: true });
    }

    const snapshot = existing.cart_snapshot as Record<string, unknown> | null;
    if (!snapshot) {
      console.error(
        `razorpay-webhook: payment ${paymentId} captured but no cart snapshot for order ${orderId} — booking not auto-created`,
      );
      return json({ received: true, reconciled: true, bookingCreated: false });
    }

    const { data: booking, error: bookingError } = await admin
      .from("bookings")
      .insert({
        user_id: existing.user_id,
        service_name: String(snapshot.serviceName ?? "Tank Cleaning"),
        date: String(snapshot.date ?? ""),
        booking_date: String(snapshot.date ?? ""),
        booking_time: String(snapshot.timeSlot ?? ""),
        address: String(snapshot.address ?? ""),
        status: "CONFIRMED",
        price: Math.round(amount / 100),
      })
      .select()
      .maybeSingle();
    if (bookingError) throw bookingError;

    if (booking) {
      await admin
        .from("payments")
        .update({ booking_id: booking.id, updated_at: new Date().toISOString() })
        .eq("id", existing.id);

      // Same in-app notification the client-side success path sends, so
      // the user finds out their booking went through even though they
      // never saw the success screen.
      await admin.from("notifications").insert([
        {
          user_id: existing.user_id,
          title: "Booking Confirmed! 📅",
          body: "Your payment went through and your slot is confirmed.",
          type: "booking",
        },
        {
          user_id: existing.user_id,
          title: "Payment Received! 💳",
          body: "Service payment confirmed.",
          type: "payment",
        },
      ]);
    }

    return json({ received: true, reconciled: true, bookingCreated: Boolean(booking) });
  } catch (error) {
    console.error("razorpay-webhook error", error);
    // Non-2xx so Razorpay retries — this path is for transient DB errors,
    // not business-logic decisions (those already returned 200 above).
    return json({ error: "Internal error" }, 500);
  }
});
