-- Migration 0454: store a device FCM push token per user so the backend can
-- deliver push notifications. Applies after 0453. Idempotent.
--
-- One token per user_profiles row is sufficient for this app (single primary
-- device). Owner-update is already covered by the existing user_profiles RLS
-- policies (user can update their own row); the column is just added here.

ALTER TABLE public.user_profiles
  ADD COLUMN IF NOT EXISTS fcm_token TEXT,
  ADD COLUMN IF NOT EXISTS fcm_token_updated_at TIMESTAMPTZ;
