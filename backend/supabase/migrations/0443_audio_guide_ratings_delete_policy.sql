-- 0443: Add missing DELETE policy for audio guide ratings
CREATE POLICY "Authenticated users can delete own ratings"
  ON poi_audio_guide_ratings FOR DELETE
  USING (auth.uid() = user_id);
