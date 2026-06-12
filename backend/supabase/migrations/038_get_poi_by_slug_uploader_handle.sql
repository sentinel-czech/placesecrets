-- 038: Add uploaded_by and uploader_handle to audio_guides in get_poi_by_slug
DROP FUNCTION IF EXISTS get_poi_by_slug(TEXT, TEXT, TEXT);

CREATE OR REPLACE FUNCTION get_poi_by_slug(p_country_code TEXT, p_city_slug TEXT, p_poi_slug TEXT)
RETURNS TABLE(
  poi_id UUID, poi_name JSONB, poi_description JSONB, poi_perex JSONB,
  poi_access_level TEXT, poi_premium_price NUMERIC,
  poi_lat DOUBLE PRECISION, poi_lng DOUBLE PRECISION,
  poi_photo_urls JSONB, poi_audio_urls JSONB,
  poi_avg_rating NUMERIC, poi_total_ratings INTEGER,
  poi_aliases TEXT[],
  audio_guides JSONB,
  poi_type_id UUID, poi_type_name JSONB, poi_type_icon TEXT, poi_type_color TEXT,
  contributor_id UUID, contributor_name TEXT, contributor_avatar TEXT, contributor_verified BOOLEAN,
  city_id UUID, city_name TEXT, city_slug TEXT, country_code TEXT
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_catalog
AS $fn$
BEGIN
  RETURN QUERY
  SELECT
    p.id,
    p.name,
    p.description,
    p.perex,
    p.access_level,
    p.premium_price,
    p.latitude,
    p.longitude,
    p.photo_urls,
    p.audio_urls,
    p.avg_rating,
    p.total_ratings,
    p.aliases,
    COALESCE(
      (SELECT jsonb_agg(jsonb_build_object(
        'id', ag.id,
        'lang_code', ag.lang_code,
        'title', ag.title,
        'duration_sec', ag.duration_sec,
        'sort_order', ag.sort_order,
        'uploaded_by', ag.uploaded_by,
        'uploader_handle', COALESCE(
          up2.display_name,
          split_part(au2.email::TEXT, '@', 1),
          (SELECT up3.display_name FROM user_profiles up3 WHERE up3.user_id = p.contributor_id),
          (SELECT split_part(au3.email::TEXT, '@', 1) FROM auth.users au3 WHERE au3.id = p.contributor_id)
        )
      ) ORDER BY ag.lang_code, ag.sort_order)
      FROM poi_audio_guides ag
      LEFT JOIN user_profiles up2 ON up2.user_id = ag.uploaded_by
      LEFT JOIN auth.users au2 ON au2.id = ag.uploaded_by
      WHERE ag.poi_id = p.id),
      '[]'::JSONB
    ),
    pt.id,
    pt.name,
    pt.icon_name,
    pt.color_hex,
    cp.user_id,
    cp.display_name,
    cp.avatar_url,
    cp.is_verified,
    c.id,
    c.name,
    c.slug,
    c.country_code
  FROM pois p
  JOIN cities c ON c.id = p.city_id
  LEFT JOIN poi_types pt ON pt.id = p.type_id
  LEFT JOIN contributor_profiles cp ON cp.user_id = p.contributor_id
  WHERE lower(c.country_code) = lower(p_country_code)
    AND c.slug = p_city_slug
    AND p.slug = p_poi_slug
    AND p.is_active = TRUE
  LIMIT 1;
END;
$fn$;
