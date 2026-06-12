-- Replace get_poi_by_slug to require country_code and return it
DROP FUNCTION IF EXISTS get_poi_by_slug(TEXT, TEXT);

CREATE OR REPLACE FUNCTION get_poi_by_slug(p_country_code TEXT, p_city_slug TEXT, p_poi_slug TEXT)
RETURNS TABLE(
  poi_id UUID, poi_name JSONB, poi_perex TEXT,
  poi_access_level TEXT, poi_premium_price NUMERIC,
  poi_lat DOUBLE PRECISION, poi_lng DOUBLE PRECISION,
  poi_photo_urls TEXT[], poi_avg_rating NUMERIC, poi_total_ratings BIGINT,
  city_id UUID, city_name TEXT, city_slug TEXT, country_code TEXT
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_catalog
AS $fn$
BEGIN
  RETURN QUERY
  SELECT
    p.id, p.name, p.perex,
    p.access_level, p.premium_price,
    p.latitude, p.longitude,
    p.photo_urls, p.avg_rating, p.total_ratings,
    c.id, c.name, c.slug, c.country_code
  FROM pois p
  JOIN cities c ON c.id = p.city_id
  WHERE lower(c.country_code) = lower(p_country_code)
    AND c.slug = p_city_slug
    AND p.slug = p_poi_slug
  LIMIT 1;
END;
$fn$;
