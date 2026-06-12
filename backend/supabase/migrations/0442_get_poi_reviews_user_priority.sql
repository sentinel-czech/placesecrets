-- 0442: Update get_poi_reviews to prioritize current user's review
-- Drop old 3-param overload to avoid PGRST203 ambiguity
DROP FUNCTION IF EXISTS get_poi_reviews(UUID, INT, INT);

CREATE OR REPLACE FUNCTION get_poi_reviews(
  p_poi_id  UUID,
  p_limit   INT DEFAULT 10,
  p_offset  INT DEFAULT 0,
  p_user_id UUID DEFAULT NULL
)
RETURNS TABLE(
  review_id UUID,
  rating SMALLINT,
  comment TEXT,
  is_hidden BOOLEAN,
  created_at TIMESTAMPTZ,
  display_name TEXT,
  total_count BIGINT,
  is_own BOOLEAN
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_catalog
AS $fn$
BEGIN
  RETURN QUERY
  SELECT
    r.id,
    r.rating,
    CASE WHEN r.is_hidden THEN NULL ELSE r.comment END,
    r.is_hidden,
    r.created_at,
    COALESCE(up.display_name, 'Anonymous'),
    COUNT(*) OVER(),
    (p_user_id IS NOT NULL AND r.user_id = p_user_id)
  FROM poi_ratings r
  LEFT JOIN user_profiles up ON up.user_id = r.user_id
  WHERE r.poi_id = p_poi_id
    AND (r.comment IS NOT NULL OR r.is_hidden = TRUE)
  ORDER BY (p_user_id IS NOT NULL AND r.user_id = p_user_id) DESC NULLS LAST, r.created_at DESC
  LIMIT p_limit
  OFFSET p_offset;
END;
$fn$;
