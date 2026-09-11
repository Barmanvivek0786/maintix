-- Add is_approved column to reviews table for moderation
ALTER TABLE public.reviews
  ADD COLUMN IF NOT EXISTS is_approved boolean NOT NULL DEFAULT false;

-- Index for fast filtering of approved reviews
CREATE INDEX IF NOT EXISTS idx_reviews_is_approved ON public.reviews(is_approved);
