-- 012: poi_types table + seed data

CREATE TABLE public.poi_types (
  id         UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name       JSONB NOT NULL DEFAULT '{"cs": "", "en": ""}',
  slug       TEXT NOT NULL UNIQUE,
  icon_name  TEXT NOT NULL DEFAULT 'place',
  color_hex  TEXT NOT NULL DEFAULT '#2D6A4F',
  sort_order INTEGER NOT NULL DEFAULT 0,
  is_active  BOOLEAN NOT NULL DEFAULT TRUE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE public.poi_types ENABLE ROW LEVEL SECURITY;

CREATE POLICY "poi_types_public_read" ON public.poi_types
  FOR SELECT USING (is_active = TRUE);

CREATE POLICY "poi_types_service_write" ON public.poi_types
  FOR ALL USING (auth.role() = 'service_role');

CREATE TRIGGER poi_types_updated_at
  BEFORE UPDATE ON public.poi_types
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

-- FK on pois
ALTER TABLE public.pois
  ADD COLUMN type_id UUID REFERENCES public.poi_types(id) ON DELETE SET NULL;

CREATE INDEX idx_pois_type_id ON public.pois(type_id);

-- Seed 12 types
INSERT INTO public.poi_types (name, slug, icon_name, color_hex, sort_order) VALUES
  ('{"cs":"Budova","en":"Building"}',       'building',    'apartment',      '#4A90D9', 1),
  ('{"cs":"Socha","en":"Statue"}',          'statue',      'emoji_people',   '#8B5CF6', 2),
  ('{"cs":"Hrad / Zamek","en":"Castle"}',   'castle',      'castle',         '#92400E', 3),
  ('{"cs":"Kostel","en":"Church"}',         'church',      'church',         '#DC2626', 4),
  ('{"cs":"Muzeum","en":"Museum"}',         'museum',      'museum',         '#D97706', 5),
  ('{"cs":"Priroda","en":"Nature"}',        'nature',      'park',           '#059669', 6),
  ('{"cs":"Vyhlidka","en":"Viewpoint"}',    'viewpoint',   'landscape',      '#0891B2', 7),
  ('{"cs":"Restaurace","en":"Restaurant"}', 'restaurant',  'restaurant',     '#E11D48', 8),
  ('{"cs":"Kavarna","en":"Cafe"}',          'cafe',        'local_cafe',     '#78350F', 9),
  ('{"cs":"Bar","en":"Bar"}',               'bar',         'local_bar',      '#7C3AED', 10),
  ('{"cs":"Obchod","en":"Shop"}',           'shop',        'storefront',     '#0D9488', 11),
  ('{"cs":"Divadlo","en":"Theatre"}',       'theatre',     'theater_comedy', '#BE185D', 12);

GRANT SELECT ON public.poi_types TO anon, authenticated;
