-- Public approved reviews must be readable by anonymous and authenticated users.
-- The app also filters approved reviews client-side for an explicit contract.
DROP POLICY IF EXISTS "public_read_approved_reviews" ON public.reviews;
CREATE POLICY "public_read_approved_reviews"
ON public.reviews
FOR SELECT
TO public
USING (is_approved = true);

-- A broadcast row contains only the message shown to users. Allowing reads
-- lets authenticated clients receive the Supabase Realtime INSERT event.
DROP POLICY IF EXISTS "authenticated_read_admin_broadcasts"
  ON public.admin_broadcasts;
CREATE POLICY "authenticated_read_admin_broadcasts"
ON public.admin_broadcasts
FOR SELECT
TO authenticated
USING (true);

-- Realtime is required for the in-app listener that raises a system tray alert
-- while the app is running. Duplicate_object keeps this migration rerunnable.
DO $$
BEGIN
  ALTER PUBLICATION supabase_realtime ADD TABLE public.notifications;
EXCEPTION
  WHEN duplicate_object THEN NULL;
END
$$;

DO $$
BEGIN
  ALTER PUBLICATION supabase_realtime ADD TABLE public.admin_broadcasts;
EXCEPTION
  WHEN duplicate_object THEN NULL;
END
$$;