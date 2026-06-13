-- Migration 0451: moderation flag for audio-guide ratings (parity with poi_ratings).
-- Applies after 0450. Idempotent. User deactivation reuses the existing
-- user_profiles.status column (active|deactivated) added in migration 019.

ALTER TABLE public.poi_audio_guide_ratings
  ADD COLUMN IF NOT EXISTS is_hidden BOOLEAN NOT NULL DEFAULT FALSE;
