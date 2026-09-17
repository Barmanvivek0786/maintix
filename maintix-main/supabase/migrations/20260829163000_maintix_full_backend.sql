-- ============================================================
-- Maintix Full Backend Migration v2
-- New Tables: reviews, user_coins, coin_transactions,
--             support_tickets, services
-- Alter: profiles (add email), bookings (add booking_time, address columns)
-- ============================================================

-- 1. ALTER profiles: add email column if missing
ALTER TABLE public.profiles
ADD COLUMN IF NOT EXISTS email TEXT NOT NULL DEFAULT '';

-- 2. ALTER bookings: add booking_time, address, booking_date columns
ALTER TABLE public.bookings
ADD COLUMN IF NOT EXISTS booking_date TEXT NOT NULL DEFAULT '';

ALTER TABLE public.bookings
ADD COLUMN IF NOT EXISTS booking_time TEXT NOT NULL DEFAULT '';

ALTER TABLE public.bookings
ADD COLUMN IF NOT EXISTS address TEXT NOT NULL DEFAULT '';

-- 3. REVIEWS TABLE
CREATE TABLE IF NOT EXISTS public.reviews (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    service_name TEXT NOT NULL DEFAULT '',
    rating NUMERIC NOT NULL DEFAULT 5,
    review_text TEXT NOT NULL DEFAULT '',
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- 4. USER_COINS TABLE
CREATE TABLE IF NOT EXISTS public.user_coins (
    user_id UUID PRIMARY KEY REFERENCES public.profiles(id) ON DELETE CASCADE,
    balance INTEGER NOT NULL DEFAULT 0,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- 5. COIN_TRANSACTIONS TABLE
CREATE TABLE IF NOT EXISTS public.coin_transactions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    amount INTEGER NOT NULL DEFAULT 0,
    type TEXT NOT NULL DEFAULT 'reward',
    description TEXT NOT NULL DEFAULT '',
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- 6. SUPPORT_TICKETS TABLE
CREATE TABLE IF NOT EXISTS public.support_tickets (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    subject TEXT NOT NULL DEFAULT '',
    message TEXT NOT NULL DEFAULT '',
    status TEXT NOT NULL DEFAULT 'open',
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- 7. SERVICES TABLE (public read)
CREATE TABLE IF NOT EXISTS public.services (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title TEXT NOT NULL DEFAULT '',
    description TEXT NOT NULL DEFAULT '',
    price NUMERIC NOT NULL DEFAULT 0,
    icon_url TEXT NOT NULL DEFAULT '',
    category TEXT NOT NULL DEFAULT ''
);

-- 8. INDEXES
CREATE INDEX IF NOT EXISTS idx_reviews_user_id ON public.reviews(user_id);
CREATE INDEX IF NOT EXISTS idx_reviews_created_at ON public.reviews(created_at);
CREATE INDEX IF NOT EXISTS idx_user_coins_user_id ON public.user_coins(user_id);
CREATE INDEX IF NOT EXISTS idx_coin_transactions_user_id ON public.coin_transactions(user_id);
CREATE INDEX IF NOT EXISTS idx_coin_transactions_created_at ON public.coin_transactions(created_at);
CREATE INDEX IF NOT EXISTS idx_support_tickets_user_id ON public.support_tickets(user_id);
CREATE INDEX IF NOT EXISTS idx_services_category ON public.services(category);

-- 9. ENABLE RLS
ALTER TABLE public.reviews ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_coins ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.coin_transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.support_tickets ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.services ENABLE ROW LEVEL SECURITY;

-- 10. RLS POLICIES - REVIEWS
DROP POLICY IF EXISTS "users_manage_own_reviews" ON public.reviews;
CREATE POLICY "users_manage_own_reviews"
ON public.reviews FOR ALL TO authenticated
USING (user_id = auth.uid())
WITH CHECK (user_id = auth.uid());

-- 11. RLS POLICIES - USER_COINS
DROP POLICY IF EXISTS "users_manage_own_coins" ON public.user_coins;
CREATE POLICY "users_manage_own_coins"
ON public.user_coins FOR ALL TO authenticated
USING (user_id = auth.uid())
WITH CHECK (user_id = auth.uid());

-- 12. RLS POLICIES - COIN_TRANSACTIONS
DROP POLICY IF EXISTS "users_manage_own_coin_transactions" ON public.coin_transactions;
CREATE POLICY "users_manage_own_coin_transactions"
ON public.coin_transactions FOR ALL TO authenticated
USING (user_id = auth.uid())
WITH CHECK (user_id = auth.uid());

-- 13. RLS POLICIES - SUPPORT_TICKETS
DROP POLICY IF EXISTS "users_manage_own_support_tickets" ON public.support_tickets;
CREATE POLICY "users_manage_own_support_tickets"
ON public.support_tickets FOR ALL TO authenticated
USING (user_id = auth.uid())
WITH CHECK (user_id = auth.uid());

-- 14. RLS POLICIES - SERVICES (public read, no write for users)
DROP POLICY IF EXISTS "public_read_services" ON public.services;
CREATE POLICY "public_read_services"
ON public.services FOR SELECT TO public
USING (true);

-- 15. SEED SERVICES DATA
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM public.services LIMIT 1) THEN
        INSERT INTO public.services (id, title, description, price, icon_url, category) VALUES
            (gen_random_uuid(), 'Water Tank Cleaning', '5-Stage professional water tank cleaning with TDS testing. Covers 500L to 2000L tanks.', 1000, 'water_drop', 'cleaning'),
            (gen_random_uuid(), 'Solar Maintenance & Repair', 'Inverter check, wiring inspection and solar panel repair by certified technicians.', 1500, 'solar_power', 'maintenance'),
            (gen_random_uuid(), 'Solar Panel Cleaning', 'Professional dust and grime removal from solar panels to maximize efficiency.', 800, 'wb_sunny', 'cleaning')
        ON CONFLICT (id) DO NOTHING;
    END IF;
END $$;
