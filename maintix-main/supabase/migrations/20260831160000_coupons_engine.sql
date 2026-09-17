-- Migration: Coupons table + admin controls + coins rules update
-- Timestamp: 20260831160000

-- ─── COUPONS TABLE ──────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.coupons (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  code TEXT NOT NULL UNIQUE,
  description TEXT DEFAULT '',
  discount_amount INTEGER NOT NULL DEFAULT 0,
  discount_type TEXT NOT NULL DEFAULT 'flat', -- 'flat' or 'percent'
  is_active BOOLEAN NOT NULL DEFAULT true,
  max_uses INTEGER DEFAULT NULL, -- NULL = unlimited
  used_count INTEGER NOT NULL DEFAULT 0,
  expires_at TIMESTAMPTZ DEFAULT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE public.coupons ENABLE ROW LEVEL SECURITY;

-- Drop policies if they already exist, then recreate
DROP POLICY IF EXISTS "Admins manage coupons" ON public.coupons;
DROP POLICY IF EXISTS "Users read active coupons" ON public.coupons;

-- Admins can do everything; users can only read active coupons
CREATE POLICY "Admins manage coupons" ON public.coupons
  FOR ALL USING (public.is_admin_user());

CREATE POLICY "Users read active coupons" ON public.coupons
  FOR SELECT USING (is_active = true);

-- ─── SEED DEFAULT COUPONS ────────────────────────────────────────────────────
INSERT INTO public.coupons (code, description, discount_amount, discount_type, is_active, max_uses)
VALUES
  ('WEL100', 'Welcome offer - ₹100 off on first booking', 100, 'flat', true, NULL),
  ('TANK500', '₹500 off on 3 tank cleaning bookings', 500, 'flat', true, NULL)
ON CONFLICT (code) DO NOTHING;

-- ─── INCREMENT COUPON USAGE FUNCTION ────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.increment_coupon_usage(coupon_id UUID)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  UPDATE public.coupons
  SET used_count = used_count + 1,
      updated_at = NOW()
  WHERE id = coupon_id;
END;
$$;

-- ─── UPDATE SIGNUP BONUS COLUMN (ensure it exists) ──────────────────────────
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public'
      AND table_name = 'profiles'
      AND column_name = 'signup_bonus_awarded'
  ) THEN
    ALTER TABLE public.profiles ADD COLUMN signup_bonus_awarded BOOLEAN DEFAULT false;
  END IF;
END $$;

-- ─── ADMIN BROADCASTS TABLE (ensure exists) ──────────────────────────────────
CREATE TABLE IF NOT EXISTS public.admin_broadcasts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  title TEXT NOT NULL,
  body TEXT NOT NULL,
  type TEXT DEFAULT 'broadcast',
  sent_at TIMESTAMPTZ DEFAULT NOW(),
  sent_by UUID REFERENCES auth.users(id)
);

ALTER TABLE public.admin_broadcasts ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Admins manage broadcasts" ON public.admin_broadcasts;

CREATE POLICY "Admins manage broadcasts" ON public.admin_broadcasts
  FOR ALL USING (public.is_admin_user());
