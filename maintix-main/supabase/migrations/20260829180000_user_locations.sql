-- Migration: user_locations table for GPS location tracking
-- Timestamp: 20260829180000

CREATE TABLE IF NOT EXISTS public.user_locations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  address TEXT NOT NULL DEFAULT '',
  latitude DOUBLE PRECISION NOT NULL DEFAULT 0,
  longitude DOUBLE PRECISION NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_user_locations_user_id ON public.user_locations(user_id);
CREATE INDEX IF NOT EXISTS idx_user_locations_created_at ON public.user_locations(created_at DESC);

ALTER TABLE public.user_locations ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "users_manage_own_user_locations" ON public.user_locations;
CREATE POLICY "users_manage_own_user_locations"
  ON public.user_locations
  FOR ALL
  TO authenticated
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());
