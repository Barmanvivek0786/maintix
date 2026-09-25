-- Root-cause fix for the Razorpay "Payment could not be completed — the
-- order is already paid" error: previously the app only recorded a booking
-- when Razorpay's client SDK called onSuccess. If that callback never
-- arrived (app backgrounded/killed mid-UPI-flow, network drop switching
-- back from the UPI app, WebView hiccup, etc.) the payment was still
-- CAPTURED by Razorpay, but Maintix never knew — so when the user retried,
-- Razorpay correctly refused to charge the same already-paid order again
-- and showed this exact screen. There was no server-side safety net.
--
-- This migration prepares `payments` to be the source of truth that a
-- Razorpay webhook (server-to-server, independent of the client) can
-- reconcile against, regardless of what happens on the phone.

-- Snapshot of the cart at order-creation time, so a webhook that arrives
-- after the client has given up can still create the booking correctly.
ALTER TABLE public.payments
  ADD COLUMN IF NOT EXISTS cart_snapshot JSONB;

-- Safety: collapse any pre-existing duplicate rows for the same order
-- (keep the most recently updated one) before enforcing uniqueness below.
DELETE FROM public.payments p
USING public.payments p2
WHERE p.razorpay_order_id = p2.razorpay_order_id
  AND p.id <> p2.id
  AND (p.updated_at, p.id) < (p2.updated_at, p2.id);

-- Exactly one payments row per Razorpay order. Order creation INSERTs it
-- once (status PENDING); everything after that — client success/failure
-- callbacks AND the webhook — UPDATEs that same row. This is what lets the
-- webhook safely upsert without ever racing the client into duplicate rows.
CREATE UNIQUE INDEX IF NOT EXISTS payments_razorpay_order_id_key
  ON public.payments (razorpay_order_id);
