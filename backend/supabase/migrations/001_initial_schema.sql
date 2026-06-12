-- HeroDots - Initial database schema

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- CITIES
CREATE TABLE public.cities (
  id                      UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name                    TEXT NOT NULL,
  country                 TEXT NOT NULL,
  country_code            TEXT NOT NULL DEFAULT 'CZ',
  latitude                DOUBLE PRECISION NOT NULL,
  longitude               DOUBLE PRECISION NOT NULL,
  bounding_box_radius_km  DOUBLE PRECISION NOT NULL DEFAULT 10,
  price_eur               DECIMAL(10, 2) NOT NULL DEFAULT 1.00,
  is_active               BOOLEAN NOT NULL DEFAULT TRUE,
  created_at              TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at              TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- POIS
CREATE TABLE public.pois (
  id               UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  city_id          UUID NOT NULL REFERENCES public.cities(id) ON DELETE CASCADE,
  name             JSONB NOT NULL DEFAULT '{"cs": "", "en": ""}',
  description      JSONB NOT NULL DEFAULT '{}',
  latitude         DOUBLE PRECISION NOT NULL,
  longitude        DOUBLE PRECISION NOT NULL,
  geofence_radius  DOUBLE PRECISION NOT NULL DEFAULT 100,
  photo_urls       JSONB NOT NULL DEFAULT '[]',
  audio_urls       JSONB NOT NULL DEFAULT '{}',
  is_premium       BOOLEAN NOT NULL DEFAULT TRUE,
  sort_order       INTEGER NOT NULL DEFAULT 0,
  is_active        BOOLEAN NOT NULL DEFAULT TRUE,
  created_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at       TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_pois_city_id ON public.pois(city_id);
CREATE INDEX idx_pois_location ON public.pois(latitude, longitude);
CREATE INDEX idx_pois_active ON public.pois(is_active);

-- USER_ACCESS
CREATE TABLE public.user_access (
  id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id         UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  city_id         UUID NOT NULL REFERENCES public.cities(id) ON DELETE CASCADE,
  purchased_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  valid_until     TIMESTAMPTZ,
  payment_method  TEXT NOT NULL
    CHECK (payment_method IN ('google_pay', 'apple_pay', 'revolut', 'stripe', 'admin_grant')),
  transaction_id  TEXT,
  amount_eur      DECIMAL(10, 2),
  UNIQUE(user_id, city_id)
);

CREATE INDEX idx_user_access_user_id ON public.user_access(user_id);

-- FREE_VISIT_LOG
CREATE TABLE public.free_visit_log (
  id           UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id      UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  device_id    TEXT,
  poi_id       UUID NOT NULL REFERENCES public.pois(id) ON DELETE CASCADE,
  city_id      UUID NOT NULL REFERENCES public.cities(id) ON DELETE CASCADE,
  visited_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  year_month   TEXT NOT NULL
);

CREATE INDEX idx_free_visit_log_user ON public.free_visit_log(user_id, year_month);
CREATE INDEX idx_free_visit_log_device ON public.free_visit_log(device_id, year_month);

-- PAYMENT_CONFIG
CREATE TABLE public.payment_config (
  id                     UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  operator_name          TEXT NOT NULL DEFAULT 'HeroDots',
  revolut_username       TEXT,
  revolut_iban           TEXT,
  stripe_publishable_key TEXT,
  stripe_secret_key      TEXT,
  google_pay_merchant_id TEXT,
  apple_pay_merchant_id  TEXT,
  updated_at             TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

INSERT INTO public.payment_config (operator_name) VALUES ('HeroDots');

-- TRIGGER: set_updated_at
CREATE OR REPLACE FUNCTION public.set_updated_at()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$;

CREATE TRIGGER cities_updated_at
  BEFORE UPDATE ON public.cities
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

CREATE TRIGGER pois_updated_at
  BEFORE UPDATE ON public.pois
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

CREATE TRIGGER payment_config_updated_at
  BEFORE UPDATE ON public.payment_config
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

-- ROW LEVEL SECURITY
ALTER TABLE public.cities ENABLE ROW LEVEL SECURITY;
CREATE POLICY "cities_public_read" ON public.cities
  FOR SELECT USING (is_active = TRUE);

ALTER TABLE public.pois ENABLE ROW LEVEL SECURITY;
CREATE POLICY "pois_public_read" ON public.pois
  FOR SELECT USING (is_active = TRUE);

ALTER TABLE public.user_access ENABLE ROW LEVEL SECURITY;
CREATE POLICY "user_access_own_read" ON public.user_access
  FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "user_access_own_insert" ON public.user_access
  FOR INSERT WITH CHECK (auth.uid() = user_id);

ALTER TABLE public.free_visit_log ENABLE ROW LEVEL SECURITY;
CREATE POLICY "free_visit_own_read" ON public.free_visit_log
  FOR SELECT USING (auth.uid() = user_id OR (auth.uid() IS NULL AND device_id IS NOT NULL));
CREATE POLICY "free_visit_own_insert" ON public.free_visit_log
  FOR INSERT WITH CHECK (auth.uid() = user_id OR user_id IS NULL);

ALTER TABLE public.payment_config ENABLE ROW LEVEL SECURITY;
CREATE POLICY "payment_config_authenticated_read" ON public.payment_config
  FOR SELECT USING (auth.role() = 'authenticated' OR auth.role() = 'service_role');
CREATE POLICY "payment_config_service_write" ON public.payment_config
  FOR ALL USING (auth.role() = 'service_role');
