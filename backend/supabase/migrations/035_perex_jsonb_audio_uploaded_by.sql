-- 035: Convert perex TEXT -> JSONB, add uploaded_by to poi_audio_guides

-- 1. Convert perex column from TEXT to JSONB, migrating existing values
ALTER TABLE pois
  ALTER COLUMN perex TYPE JSONB
  USING CASE
    WHEN perex IS NOT NULL THEN jsonb_build_object('en', perex)
    ELSE NULL
  END;

-- 2. Add uploaded_by column to poi_audio_guides
ALTER TABLE poi_audio_guides
  ADD COLUMN IF NOT EXISTS uploaded_by UUID REFERENCES auth.users(id) ON DELETE SET NULL;
