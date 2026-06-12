-- 040: Audio guide ratings table + columns on poi_audio_guides

-- Add rating columns to poi_audio_guides
ALTER TABLE poi_audio_guides
  ADD COLUMN IF NOT EXISTS avg_rating DECIMAL(3,2) DEFAULT 0,
  ADD COLUMN IF NOT EXISTS total_ratings INTEGER DEFAULT 0;

-- Audio guide ratings table
CREATE TABLE IF NOT EXISTS poi_audio_guide_ratings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  audio_guide_id UUID NOT NULL REFERENCES poi_audio_guides(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  rating SMALLINT NOT NULL CHECK (rating >= 1 AND rating <= 5),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE(audio_guide_id, user_id)
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_audio_guide_ratings_guide ON poi_audio_guide_ratings(audio_guide_id);
CREATE INDEX IF NOT EXISTS idx_audio_guide_ratings_user ON poi_audio_guide_ratings(user_id);

-- RLS
ALTER TABLE poi_audio_guide_ratings ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can read audio guide ratings"
  ON poi_audio_guide_ratings FOR SELECT USING (true);

CREATE POLICY "Authenticated users can insert own ratings"
  ON poi_audio_guide_ratings FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Authenticated users can update own ratings"
  ON poi_audio_guide_ratings FOR UPDATE
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);
