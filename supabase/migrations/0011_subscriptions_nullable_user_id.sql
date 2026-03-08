-- Migration 0011: make subscriptions.user_id nullable
-- RevenueCat webhooks may arrive before a user links their Supabase account,
-- so user_id cannot be required at insert time.

ALTER TABLE public.subscriptions
  ALTER COLUMN user_id DROP NOT NULL,
  ALTER COLUMN user_id DROP DEFAULT;

-- Drop the FK so anonymous RevenueCat IDs don't fail the constraint.
-- The link is re-established when the user authenticates and their
-- RevenueCat app_user_id is updated to their Supabase UUID.
ALTER TABLE public.subscriptions
  DROP CONSTRAINT IF EXISTS subscriptions_user_id_fkey;
