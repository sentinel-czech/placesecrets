-- Migration 0450: editable landing-page content (admin CMS), per-language JSONB.
-- Applies after 0448. Idempotent. Single-row config table; LandingPage falls back to
-- i18n keys when a value is missing, so this is non-breaking.

CREATE TABLE IF NOT EXISTS public.landing_config (
  id             INT PRIMARY KEY DEFAULT 1,
  hero_title_1   JSONB NOT NULL DEFAULT '{}'::jsonb,
  hero_title_2   JSONB NOT NULL DEFAULT '{}'::jsonb,
  hero_title_3   JSONB NOT NULL DEFAULT '{}'::jsonb,
  hero_subtitle  JSONB NOT NULL DEFAULT '{}'::jsonb,
  tagline        JSONB NOT NULL DEFAULT '{}'::jsonb,
  footer_tagline JSONB NOT NULL DEFAULT '{}'::jsonb,
  updated_at     TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT landing_config_singleton CHECK (id = 1)
);

ALTER TABLE public.landing_config ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS landing_config_public_read ON public.landing_config;
CREATE POLICY landing_config_public_read ON public.landing_config
  FOR SELECT USING (true);

DROP POLICY IF EXISTS landing_config_service_all ON public.landing_config;
CREATE POLICY landing_config_service_all ON public.landing_config
  FOR ALL USING (auth.role() = 'service_role');

GRANT SELECT ON public.landing_config TO anon, authenticated;

INSERT INTO public.landing_config
  (id, hero_title_1, hero_title_2, hero_title_3, hero_subtitle, tagline, footer_tagline)
VALUES (
  1,
  '{"en":"Discover the","cs":"Objevte"}'::jsonb,
  '{"en":"Hidden Stories","cs":"skryté příběhy"}'::jsonb,
  '{"en":"Behind Every Place","cs":"každého místa"}'::jsonb,
  '{"en":"Explore cities through immersive audio guides.","cs":"Poznávejte města pomocí pohlcujících audioprůvodců."}'::jsonb,
  '{"en":"Audio-guided discovery","cs":"Objevování s audioprůvodcem"}'::jsonb,
  '{"en":"Your personal audio guide to hidden stories behind every place.","cs":"Váš osobní audioprůvodce příběhy ukrytými za každým místem."}'::jsonb
)
ON CONFLICT (id) DO NOTHING;
