-- Migration 0445: search_pois RPC for the free-version web (search + featured).
-- Applies after 0444. Idempotent.
--
-- One SECURITY DEFINER function serves both the authenticated search page and the
-- public (anon) landing "featured" strip:
--   * p_query NULL/empty  -> top active places by rating (featured)
--   * p_query set         -> ILIKE over name / aliases / perex / city name
-- Granted to anon + authenticated; only returns is_active places in active cities.
-- Column types mirror the pois/cities schema and get_poi_by_slug (photo_urls/perex
-- are JSONB, total_ratings INTEGER, avg_rating NUMERIC) so the result type matches.

CREATE OR REPLACE FUNCTION public.search_pois(p_query TEXT DEFAULT NULL, p_limit INT DEFAULT 30)
RETURNS TABLE (
  id            UUID,
  name          JSONB,
  slug          TEXT,
  perex         JSONB,
  access_level  TEXT,
  avg_rating    NUMERIC,
  total_ratings INTEGER,
  photo_urls    JSONB,
  city_slug     TEXT,
  country_code  TEXT
)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public, pg_catalog
AS $$
  SELECT
    p.id,
    p.name,
    p.slug,
    p.perex,
    p.access_level,
    p.avg_rating,
    p.total_ratings,
    p.photo_urls,
    c.slug AS city_slug,
    c.country_code
  FROM public.pois p
  JOIN public.cities c ON c.id = p.city_id
  WHERE p.is_active = TRUE
    AND c.is_active = TRUE
    AND (
      p_query IS NULL OR btrim(p_query) = ''
      OR p.name::TEXT ILIKE '%' || p_query || '%'
      OR array_to_string(p.aliases, ' ') ILIKE '%' || p_query || '%'
      OR COALESCE(p.perex::TEXT, '') ILIKE '%' || p_query || '%'
      OR c.name ILIKE '%' || p_query || '%'
    )
  ORDER BY
    CASE
      WHEN p_query IS NOT NULL AND btrim(p_query) <> '' AND p.name::TEXT ILIKE '%' || p_query || '%'
      THEN 0 ELSE 1
    END,
    COALESCE(p.avg_rating, 0) DESC,
    p.total_ratings DESC
  LIMIT LEAST(GREATEST(COALESCE(p_limit, 30), 1), 100);
$$;

GRANT EXECUTE ON FUNCTION public.search_pois(TEXT, INT) TO anon, authenticated;
