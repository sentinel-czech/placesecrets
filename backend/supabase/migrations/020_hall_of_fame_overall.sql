-- Migration 020: Overall Hall of Fame RPC (cross-city aggregate)
CREATE OR REPLACE FUNCTION poi_hall_of_fame_overall(p_limit INT DEFAULT 10)
RETURNS TABLE (
  rank BIGINT,
  contributor_id UUID,
  display_name TEXT,
  avatar_url TEXT,
  is_verified BOOLEAN,
  city_poi_count BIGINT,
  city_avg_rating NUMERIC,
  city_total_ratings BIGINT,
  hof_score NUMERIC,
  sample_poi_names JSONB[]
)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  WITH contributor_stats AS (
    SELECT
      cp.id AS contributor_id,
      cp.display_name,
      cp.avatar_url,
      cp.is_verified,
      COUNT(p.id) AS city_poi_count,
      COALESCE(AVG(p.avg_rating), 0) AS city_avg_rating,
      COALESCE(SUM(p.total_ratings), 0) AS city_total_ratings,
      (COALESCE(AVG(p.avg_rating), 0) * 0.6 + LEAST(COUNT(p.id)::NUMERIC / 10, 1) * 0.2 + LEAST(COALESCE(SUM(p.total_ratings), 0)::NUMERIC / 50, 1) * 0.2) * 5 AS hof_score,
      ARRAY_AGG(p.name ORDER BY p.avg_rating DESC NULLS LAST) FILTER (WHERE p.name IS NOT NULL) AS sample_poi_names
    FROM contributor_profiles cp
    JOIN pois p ON p.contributor_id = cp.id AND p.is_active = true
    WHERE cp.is_active = true
    GROUP BY cp.id, cp.display_name, cp.avatar_url, cp.is_verified
    HAVING COALESCE(SUM(p.total_ratings), 0) >= 10
  )
  SELECT
    ROW_NUMBER() OVER (ORDER BY cs.hof_score DESC) AS rank,
    cs.contributor_id,
    cs.display_name,
    cs.avatar_url,
    cs.is_verified,
    cs.city_poi_count,
    cs.city_avg_rating,
    cs.city_total_ratings,
    cs.hof_score,
    cs.sample_poi_names[1:3]
  FROM contributor_stats cs
  ORDER BY cs.hof_score DESC
  LIMIT p_limit;
$$;
