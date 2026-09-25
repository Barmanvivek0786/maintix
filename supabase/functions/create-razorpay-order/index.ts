const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

const json = (body: unknown, status = 200) =>
  new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });

Deno.serve(async (request) => {
  if (request.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  if (request.method !== "POST") {
    return json({ error: "Method not allowed" }, 405);
  }

  const keyId = Deno.env.get("RAZORPAY_KEY_ID") ?? "";
  const keySecret = Deno.env.get("RAZORPAY_KEY_SECRET") ?? "";
  if (!keyId || !keySecret) {
    return json({ error: "Razorpay is not configured on the server" }, 500);
  }

  try {
    const input = await request.json();
    const amount = Number(input.amount);
    const currency = String(input.currency ?? "INR");
    const receipt = String(input.receipt ?? "");

    if (!Number.isInteger(amount) || amount <= 0 || amount > 100000000) {
      return json({ error: "Invalid payment amount" }, 400);
    }
    if (!/^[A-Z]{3}$/.test(currency) || receipt.length > 40) {
      return json({ error: "Invalid order details" }, 400);
    }

    const auth = btoa(`${keyId}:${keySecret}`);
    const razorpayResponse = await fetch(
      "https://api.razorpay.com/v1/orders",
      {
        method: "POST",
        headers: {
          Authorization: `Basic ${auth}`,
          "Content-Type": "application/json",
        },
        body: JSON.stringify({ amount, currency, receipt }),
      },
    );

    const payload = await razorpayResponse.json();
    if (!razorpayResponse.ok) {
      console.error("Razorpay order creation failed", razorpayResponse.status, JSON.stringify(payload));
      return json({ error: "Could not create payment order" }, 502);
    }

    // Return the server's own key_id alongside the order so the client
    // checkout ALWAYS uses the exact key that created this order. Using a
    // different (e.g. stale hardcoded) key on the client than the one that
    // created the order causes Razorpay to reject every payment attempt
    // with a generic "Payment could not be completed" error, regardless of
    // the payment method tried. The key_id is public and safe to return.
    return json({
      id: payload.id,
      amount: payload.amount,
      currency: payload.currency,
      key: keyId,
    });
  } catch (error) {
    console.error("create-razorpay-order error", error);
    return json({ error: "Invalid request" }, 400);
  }
});
