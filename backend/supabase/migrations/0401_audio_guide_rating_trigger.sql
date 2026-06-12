-- 0401: Trigger to update avg_rating + total_ratings on poi_audio_guides

CREATE OR REPLACE FUNCTION update_audio_guide_rating_stats()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_catalog
AS $fn$
DECLARE
  target_id UUID;
BEGIN
  IF TG_OP = 'DELETE' THEN
    target_id := OLD.audio_guide_id;
  ELSE
    target_id := NEW.audio_guide_id;
  END IF;

  UPDATE poi_audio_guides
  SET
    avg_rating = COALESCE((
      SELECT ROUND(AVG(rating)::NUMERIC, 2)
      FROM poi_audio_guide_ratings
      WHERE audio_guide_id = target_id
    ), 0),
    total_ratings = COALESCE((
      SELECT COUNT(*)
      FROM poi_audio_guide_ratings
      WHERE audio_guide_id = target_id
    ), 0)
  WHERE id = target_id;

  RETURN NULL;
END;
$fn$;

CREATE TRIGGER trg_update_audio_guide_rating_stats
  AFTER INSERT OR UPDATE OR DELETE ON poi_audio_guide_ratings
  FOR EACH ROW
  EXECUTE FUNCTION update_audio_guide_rating_stats();
