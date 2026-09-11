-- Fix: Allow public (unauthenticated + authenticated) read access to approved reviews
-- This ensures all users can see reviews where is_approved = true

-- Drop any existing public read policy to avoid conflicts
DROP POLICY IF EXISTS "public_read_approved_reviews" ON public.reviews;
DROP POLICY IF EXISTS "anyone_read_approved_reviews" ON public.reviews;

-- Allow EVERYONE (anon + authenticated) to SELECT approved reviews
CREATE POLICY "public_read_approved_reviews"
ON public.reviews
FOR SELECT
TO public
USING (is_approved = true);
