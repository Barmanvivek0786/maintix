-- ============================================================
-- Maintix Backend Migration
-- Tables: profiles, bookings
-- Storage: avatars bucket
-- Auth: trigger-based profile provisioning
-- ============================================================

-- 1. PROFILES TABLE
CREATE TABLE IF NOT EXISTS public.profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    full_name TEXT NOT NULL DEFAULT '',
    phone_number TEXT NOT NULL DEFAULT '',
    location TEXT NOT NULL DEFAULT '',
    avatar_url TEXT,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- 2. BOOKINGS TABLE
CREATE TABLE IF NOT EXISTS public.bookings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    service_name TEXT NOT NULL DEFAULT '',
    date TEXT NOT NULL DEFAULT '',
    status TEXT NOT NULL DEFAULT 'Confirmed',
    price INTEGER NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- 3. INDEXES
CREATE INDEX IF NOT EXISTS idx_profiles_id ON public.profiles(id);
CREATE INDEX IF NOT EXISTS idx_bookings_user_id ON public.bookings(user_id);
CREATE INDEX IF NOT EXISTS idx_bookings_created_at ON public.bookings(created_at);

-- 4. TRIGGER FUNCTION: auto-create profile on new auth user
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    INSERT INTO public.profiles (id, full_name, phone_number, location, avatar_url)
    VALUES (
        NEW.id,
        COALESCE(NEW.raw_user_meta_data->>'full_name', split_part(NEW.email, '@', 1)),
        COALESCE(NEW.raw_user_meta_data->>'phone_number', ''),
        COALESCE(NEW.raw_user_meta_data->>'location', ''),
        COALESCE(NEW.raw_user_meta_data->>'avatar_url', NULL)
    )
    ON CONFLICT (id) DO NOTHING;
    RETURN NEW;
END;
$$;

-- 5. ENABLE RLS
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.bookings ENABLE ROW LEVEL SECURITY;

-- 6. RLS POLICIES - PROFILES
DROP POLICY IF EXISTS "users_manage_own_profiles" ON public.profiles;
CREATE POLICY "users_manage_own_profiles"
ON public.profiles
FOR ALL
TO authenticated
USING (id = auth.uid())
WITH CHECK (id = auth.uid());

-- 7. RLS POLICIES - BOOKINGS
DROP POLICY IF EXISTS "users_manage_own_bookings" ON public.bookings;
CREATE POLICY "users_manage_own_bookings"
ON public.bookings
FOR ALL
TO authenticated
USING (user_id = auth.uid())
WITH CHECK (user_id = auth.uid());

-- 8. TRIGGER
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_new_user();

-- 9. AVATARS STORAGE BUCKET
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
    'avatars',
    'avatars',
    true,
    5242880,
    ARRAY['image/jpeg', 'image/png', 'image/webp', 'image/gif']
)
ON CONFLICT (id) DO NOTHING;

-- 10. STORAGE RLS POLICIES
DROP POLICY IF EXISTS "public_read_avatars" ON storage.objects;
CREATE POLICY "public_read_avatars" ON storage.objects
FOR SELECT TO public
USING (bucket_id = 'avatars');

DROP POLICY IF EXISTS "authenticated_upload_avatars" ON storage.objects;
CREATE POLICY "authenticated_upload_avatars" ON storage.objects
FOR INSERT TO authenticated
WITH CHECK (bucket_id = 'avatars');

DROP POLICY IF EXISTS "owners_update_avatars" ON storage.objects;
CREATE POLICY "owners_update_avatars" ON storage.objects
FOR UPDATE TO authenticated
USING (bucket_id = 'avatars' AND owner = auth.uid());

DROP POLICY IF EXISTS "owners_delete_avatars" ON storage.objects;
CREATE POLICY "owners_delete_avatars" ON storage.objects
FOR DELETE TO authenticated
USING (bucket_id = 'avatars' AND owner = auth.uid());
