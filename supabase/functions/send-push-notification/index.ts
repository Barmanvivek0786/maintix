// Triggered by a Supabase Database Webhook on INSERT into `notifications`
// and `admin_broadcasts`. Sends a real OS push notification via OneSignal
// (which delivers through Firebase FCM on Android / APNs on iOS), so users
// get notified even when the app is closed or killed.
//
// Required Edge Function secrets (set via `supabase secrets set`):
//   ONESIGNAL_APP_ID          - Maintix App's OneSignal App ID
//   ONESIGNAL_REST_API_KEY    - Maintix App's OneSignal REST API Key (secret)
//   PUSH_WEBHOOK_SECRET       - shared secret; must match the custom header
//                               configured on the Database Webhook, so this
//                               public endpoint can't be spammed by outsiders.

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type, x-webhook-secret",
};

const json = (body: unknown, status = 200) =>
  new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });

interface WebhookPayload {
  type: "INSERT" | "UPDATE" | "DELETE";
  table: string;
  schema: string;
  record: Record<string, unknown> | null;
}

Deno.serve(async (request) => {
  if (request.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  if (request.method !== "POST") {
    return json({ error: "Method not allowed" }, 405);
  }

  const webhookSecret = Deno.env.get("PUSH_WEBHOOK_SECRET") ?? "";
  const oneSignalAppId = Deno.env.get("ONESIGNAL_APP_ID") ?? "";
  const oneSignalRestApiKey = Deno.env.get("ONESIGNAL_REST_API_KEY") ?? "";

  if (!oneSignalAppId || !oneSignalRestApiKey) {
    console.error("OneSignal is not configured on the server");
    return json({ error: "Push is not configured on the server" }, 500);
  }

  // Verify the shared secret so random internet traffic can't trigger
  // pushes to your users. Configure the same value as a custom header on
  // the Supabase Database Webhook.
  if (webhookSecret) {
    const provided = request.headers.get("x-webhook-secret") ?? "";
    if (provided !== webhookSecret) {
      return json({ error: "Unauthorized" }, 401);
    }
  }

  try {
    const payload = (await request.json()) as WebhookPayload;
    const record = payload.record;
    if (payload.type !== "INSERT" || !record) {
      return json({ skipped: true });
    }

    const title = String(record.title ?? "Maintix");
    const body = String(record.body ?? "");
    if (!body) {
      return json({ skipped: true, reason: "empty body" });
    }

    // Admin broadcasts insert one `admin_broadcasts` row (pushed to every
    // subscribed device below) plus one in-app `notifications` row per user
    // (type = 'broadcast'). Those per-user rows are only for the in-app list,
    // so skip them here or every user would get the same push twice.
    if (payload.table === "notifications" && record.type === "broadcast") {
      return json({ skipped: true, reason: "broadcast fan-out row" });
    }

    const notificationPayload: Record<string, unknown> = {
      app_id: oneSignalAppId,
      headings: { en: title },
      contents: { en: body },
    };

    if (payload.table === "admin_broadcasts") {
      // Broadcast — every subscribed device.
      notificationPayload.included_segments = ["Subscribed Users"];
    } else {
      // Single-user notification — target by Supabase user id, which the
      // app links via OneSignal.login(userId) (external_id) on sign-in.
      const userId = record.user_id;
      if (!userId) {
        return json({ skipped: true, reason: "missing user_id" });
      }
      notificationPayload.include_aliases = { external_id: [String(userId)] };
      notificationPayload.target_channel = "push";
    }

    const response = await fetch("https://api.onesignal.com/notifications", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        Authorization: `Key ${oneSignalRestApiKey}`,
      },
      body: JSON.stringify(notificationPayload),
    });

    const result = await response.json();
    if (!response.ok) {
      console.error("OneSignal send failed", response.status, result);
      return json({ error: "Failed to send push", details: result }, 502);
    }

    return json({ success: true, id: result.id, recipients: result.recipients });
  } catch (error) {
    console.error("send-push-notification error", error);
    return json({ error: "Invalid request" }, 400);
  }
});
