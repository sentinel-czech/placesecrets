-- poi_audio_guides table: multiple audio guides per POI per language

CREATE TABLE public.poi_audio_guides (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  poi_id      UUID NOT NULL REFERENCES public.pois(id) ON DELETE CASCADE,
  lang_code   TEXT NOT NULL CHECK (lang_code ~ '^[a-z]{2}$'),
  title       TEXT NOT NULL DEFAULT '',
  url         TEXT NOT NULL,
  duration_sec INTEGER,
  sort_order  INTEGER NOT NULL DEFAULT 0,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_poi_audio_guides_poi ON public.poi_audio_guides(poi_id);
CREATE INDEX idx_poi_audio_guides_poi_lang ON public.poi_audio_guides(poi_id, lang_code);

ALTER TABLE public.poi_audio_guides ENABLE ROW LEVEL SECURITY;
CREATE POLICY "poi_audio_guides_select" ON public.poi_audio_guides FOR SELECT USING (true);

-- Migrate existing data from pois.audio_urls JSONB
INSERT INTO public.poi_audio_guides (poi_id, lang_code, title, url, sort_order)
SELECT p.id, kv.key, '', kv.value::TEXT, 0
FROM public.pois p, LATERAL jsonb_each_text(p.audio_urls) AS kv(key, value)
WHERE p.audio_urls IS NOT NULL AND p.audio_urls != '{}'::JSONB
  AND kv.value IS NOT NULL AND kv.value != '';

-- Expand get_poi_by_slug RPC with description, audio guides metadata, type, contributor, aliases
DROP FUNCTION IF EXISTS get_poi_by_slug(TEXT, TEXT, TEXT);

CREATE OR REPLACE FUNCTION get_poi_by_slug(p_country_code TEXT, p_city_slug TEXT, p_poi_slug TEXT)
RETURNS TABLE(
  poi_id UUID, poi_name JSONB, poi_description JSONB, poi_perex TEXT,
  poi_access_level TEXT, poi_premium_price NUMERIC,
  poi_lat DOUBLE PRECISION, poi_lng DOUBLE PRECISION,
  poi_photo_urls TEXT[], poi_audio_urls JSONB,
  poi_avg_rating NUMERIC, poi_total_ratings BIGINT,
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
        'sort_order', ag.sort_order
      ) ORDER BY ag.lang_code, ag.sort_order)
      FROM poi_audio_guides ag WHERE ag.poi_id = p.id),
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
