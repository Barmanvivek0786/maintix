-- ─── Admin role column on profiles (must exist before is_admin_user function) ──
ALTER TABLE public.profiles
ADD COLUMN IF NOT EXISTS is_admin BOOLEAN NOT NULL DEFAULT false;

-- ─── Add signup_bonus_awarded column to profiles ───────────────────────────
ALTER TABLE public.profiles
ADD COLUMN IF NOT EXISTS signup_bonus_awarded BOOLEAN NOT NULL DEFAULT false;

-- ─── Helper function: is_admin_user ───────────────────────────────────────
CREATE OR REPLACE FUNCTION public.is_admin_user()
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
AS $$
SELECT EXISTS (
    SELECT 1 FROM public.profiles
    WHERE id = auth.uid() AND is_admin = true
)
$$;

-- ─── Notifications table ──────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.notifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
    title TEXT NOT NULL DEFAULT '',
    body TEXT NOT NULL DEFAULT '',
    type TEXT NOT NULL DEFAULT 'general',
    is_read BOOLEAN NOT NULL DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_notifications_user_id ON public.notifications(user_id);
CREATE INDEX IF NOT EXISTS idx_notifications_created_at ON public.notifications(created_at);

ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "users_manage_own_notifications" ON public.notifications;
CREATE POLICY "users_manage_own_notifications"
ON public.notifications FOR ALL TO authenticated
USING (user_id = auth.uid())
WITH CHECK (user_id = auth.uid());

-- Admin can read/insert all notifications
DROP POLICY IF EXISTS "admin_manage_all_notifications" ON public.notifications;
CREATE POLICY "admin_manage_all_notifications"
ON public.notifications FOR ALL TO authenticated
USING (public.is_admin_user())
WITH CHECK (public.is_admin_user());

-- ─── Admin broadcasts table ────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.admin_broadcasts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title TEXT NOT NULL DEFAULT '',
    body TEXT NOT NULL DEFAULT '',
    sent_by UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

ALTER TABLE public.admin_broadcasts ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "admin_manage_broadcasts" ON public.admin_broadcasts;
CREATE POLICY "admin_manage_broadcasts"
ON public.admin_broadcasts FOR ALL TO authenticated
USING (public.is_admin_user())
WITH CHECK (public.is_admin_user());

-- ─── Allow admin to read all bookings ─────────────────────────────────────
DROP POLICY IF EXISTS "admin_manage_all_bookings" ON public.bookings;
CREATE POLICY "admin_manage_all_bookings"
ON public.bookings FOR ALL TO authenticated
USING (public.is_admin_user())
WITH CHECK (public.is_admin_user());

-- ─── Allow admin to read all profiles ─────────────────────────────────────
DROP POLICY IF EXISTS "admin_manage_all_profiles" ON public.profiles;
CREATE POLICY "admin_manage_all_profiles"
ON public.profiles FOR ALL TO authenticated
USING (public.is_admin_user())
WITH CHECK (public.is_admin_user());

-- ─── Allow admin to read all reviews ──────────────────────────────────────
DROP POLICY IF EXISTS "admin_manage_all_reviews" ON public.reviews;
CREATE POLICY "admin_manage_all_reviews"
ON public.reviews FOR ALL TO authenticated
USING (public.is_admin_user())
WITH CHECK (public.is_admin_user());

-- ─── Allow admin to manage all user_coins ─────────────────────────────────
DROP POLICY IF EXISTS "admin_manage_all_user_coins" ON public.user_coins;
CREATE POLICY "admin_manage_all_user_coins"
ON public.user_coins FOR ALL TO authenticated
USING (public.is_admin_user())
WITH CHECK (public.is_admin_user());
