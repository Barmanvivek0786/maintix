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

function toHex(bytes: ArrayBuffer) {
  return [...new Uint8Array(bytes)]
    .map((byte) => byte.toString(16).padStart(2, "0"))
    .join("");
}

Deno.serve(async (request) => {
  if (request.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }
  if (request.method !== "POST") {
    return json({ error: "Method not allowed" }, 405);
  }

  const secret = Deno.env.get("RAZORPAY_KEY_SECRET") ?? "";
  if (!secret) return json({ error: "Razorpay is not configured on the server" }, 500);

  try {
    const { orderId, paymentId, signature } = await request.json();
    if (
      typeof orderId !== "string" ||
      typeof paymentId !== "string" ||
      typeof signature !== "string" ||
      !orderId ||
      !paymentId ||
      !signature
    ) {
      return json({ verified: false, error: "Invalid payment details" }, 400);
    }

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
      new TextEncoder().encode(`${orderId}|${paymentId}`),
    );
    const expected = toHex(digest);
    return json({ verified: expected === signature.toLowerCase() });
  } catch (error) {
    console.error("verify-razorpay-payment error", error);
    return json({ verified: false, error: "Invalid request" }, 400);
  }
});