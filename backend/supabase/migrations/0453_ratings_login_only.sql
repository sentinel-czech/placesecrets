-- Migration 0453: place ratings (poi_ratings) only for logged-in users.
-- Applies after 0452. Idempotent.
--
-- Previously poi_ratings allowed anonymous device-based ratings (insert policy with
-- user_id IS NULL + GRANT INSERT to anon). Per product decision, only authenticated
-- users may rate. The device_id column is kept for historical rows; new ratings must
-- carry user_id. The UNIQUE(poi_id,user_id) constraint already guarantees one per user.
-- poi_audio_guide_ratings is already login-only (user_id NOT NULL + auth-checked policy).

DROP POLICY IF EXISTS "ratings_insert" ON public.poi_ratings;
DROP POLICY IF EXISTS "ratings_insert_auth" ON public.poi_ratings;

CREATE POLICY "ratings_insert_auth" ON public.poi_ratings
  FOR INSERT TO authenticated
  WITH CHECK (auth.uid() = user_id AND user_id IS NOT NULL);

REVOKE INSERT ON public.poi_ratings FROM anon;
