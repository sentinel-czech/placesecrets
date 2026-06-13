-- Migration 0448: extend the access/entitlement model.
-- Applies after 0447. Idempotent.
--   * country-level purchases (whole country/republic)
--   * get_poi_access v2: honour country purchases + valid_until expiry
--   * configurable free limit (count + period) with server-side enforcement
--   * get_my_entitlements() for the unified "what do I own" profile view

-- 1. Country-level entitlement table
CREATE TABLE IF NOT EXISTS public.user_country_purchases (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id       UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  country_code  TEXT NOT NULL,
  purchased_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  price_paid    NUMERIC(10,2),
  valid_until   TIMESTAMPTZ,
  payment_method TEXT NOT NULL DEFAULT 'admin_grant'
    CHECK (payment_method IN ('google_pay','apple_pay','revolut','stripe','comgate','admin_grant')),
  UNIQUE (user_id, country_code)
);

ALTER TABLE public.user_country_purchases ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS user_country_purchases_own_read ON public.user_country_purchases;
CREATE POLICY user_country_purchases_own_read ON public.user_country_purchases
  FOR SELECT TO authenticated USING (auth.uid() = user_id);

DROP POLICY IF EXISTS user_country_purchases_service_all ON public.user_country_purchases;
CREATE POLICY user_country_purchases_service_all ON public.user_country_purchases
  FOR ALL USING (auth.role() = 'service_role');

GRANT SELECT ON public.user_country_purchases TO authenticated;
CREATE INDEX IF NOT EXISTS idx_user_country_purchases_user ON public.user_country_purchases(user_id);

-- 2. Configurable free limit
ALTER TABLE public.payment_config
  ADD COLUMN IF NOT EXISTS free_count  INTEGER NOT NULL DEFAULT 1,
  ADD COLUMN IF NOT EXISTS free_period TEXT    NOT NULL DEFAULT 'day'
    CHECK (free_period IN ('day','month'));

-- 3. get_poi_access v2 (country + expiry aware)
CREATE OR REPLACE FUNCTION public.get_poi_access(p_poi_id UUID)
RETURNS TEXT
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public, pg_catalog
AS $fn$
DECLARE
  v_user_id UUID := auth.uid();
  v_city_id UUID;
  v_country TEXT;
BEGIN
  SELECT p.city_id, c.country_code INTO v_city_id, v_country
  FROM public.pois p JOIN public.cities c ON c.id = p.city_id
  WHERE p.id = p_poi_id;

  IF v_user_id IS NULL THEN RETURN 'public'; END IF;

  IF EXISTS (SELECT 1 FROM public.admin_users WHERE user_id = v_user_id) THEN
    RETURN 'full';
  END IF;

  -- Country purchase (whole country), not expired
  IF EXISTS (
    SELECT 1 FROM public.user_country_purchases
    WHERE user_id = v_user_id AND country_code = v_country
      AND (valid_until IS NULL OR valid_until > NOW())
  ) THEN RETURN 'premium_poi'; END IF;

  -- Purchased specific POI
  IF EXISTS (SELECT 1 FROM public.user_poi_purchases WHERE user_id = v_user_id AND poi_id = p_poi_id) THEN
    RETURN 'premium_poi';
  END IF;

  -- City premium bundle
  IF EXISTS (SELECT 1 FROM public.user_city_premium_purchases WHERE user_id = v_user_id AND city_id = v_city_id) THEN
    RETURN 'premium_poi';
  END IF;

  -- City access pass (not expired)
  IF EXISTS (
    SELECT 1 FROM public.user_access
    WHERE user_id = v_user_id AND city_id = v_city_id
      AND (valid_until IS NULL OR valid_until > NOW())
  ) THEN RETURN 'city_access'; END IF;

  -- Free sample POI per city
  IF EXISTS (SELECT 1 FROM public.cities WHERE id = v_city_id AND registered_sample_poi_id = p_poi_id) THEN
    RETURN 'registered';
  END IF;

  RETURN 'registered_limited';
END;
$fn$;

-- 4. Free-visit limit (server-side, period bucket stored in free_visit_log.year_month)
CREATE OR REPLACE FUNCTION public.free_period_key()
RETURNS TEXT LANGUAGE sql STABLE SET search_path = public, pg_catalog AS $$
  SELECT CASE (SELECT free_period FROM public.payment_config LIMIT 1)
    WHEN 'month' THEN to_char(NOW(), 'YYYY-MM')
    ELSE to_char(NOW(), 'YYYY-MM-DD')
  END;
$$;

CREATE OR REPLACE FUNCTION public.can_use_free_visit()
RETURNS BOOLEAN LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = public, pg_catalog AS $$
DECLARE v_limit INT; v_used INT; v_key TEXT := public.free_period_key();
BEGIN
  SELECT COALESCE(free_count, 1) INTO v_limit FROM public.payment_config LIMIT 1;
  SELECT count(*) INTO v_used FROM public.free_visit_log
    WHERE user_id = auth.uid() AND year_month = v_key;
  RETURN v_used < COALESCE(v_limit, 1);
END;
$$;

CREATE OR REPLACE FUNCTION public.consume_free_visit(p_poi_id UUID)
RETURNS BOOLEAN LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, pg_catalog AS $$
DECLARE v_city UUID; v_key TEXT := public.free_period_key();
BEGIN
  IF auth.uid() IS NULL THEN RETURN FALSE; END IF;
  IF NOT public.can_use_free_visit() THEN RETURN FALSE; END IF;
  SELECT city_id INTO v_city FROM public.pois WHERE id = p_poi_id;
  INSERT INTO public.free_visit_log (user_id, poi_id, city_id, year_month)
  VALUES (auth.uid(), p_poi_id, v_city, v_key);
  RETURN TRUE;
END;
$$;

GRANT EXECUTE ON FUNCTION public.can_use_free_visit() TO authenticated;
GRANT EXECUTE ON FUNCTION public.consume_free_visit(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.free_period_key() TO authenticated, anon;

-- 5. Unified entitlements for the current user
CREATE OR REPLACE FUNCTION public.get_my_entitlements()
RETURNS JSONB LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = public, pg_catalog AS $$
DECLARE v_uid UUID := auth.uid(); v_limit INT; v_used INT; v_key TEXT := public.free_period_key();
BEGIN
  IF v_uid IS NULL THEN RETURN '{}'::jsonb; END IF;
  SELECT COALESCE(free_count,1) INTO v_limit FROM public.payment_config LIMIT 1;
  SELECT count(*) INTO v_used FROM public.free_visit_log WHERE user_id = v_uid AND year_month = v_key;
  RETURN jsonb_build_object(
    'free', jsonb_build_object('used', v_used, 'limit', COALESCE(v_limit,1), 'period', (SELECT free_period FROM public.payment_config LIMIT 1)),
    'pois', COALESCE((SELECT jsonb_agg(jsonb_build_object('poi_id', upp.poi_id, 'name', p.name, 'purchased_at', upp.purchased_at))
              FROM public.user_poi_purchases upp JOIN public.pois p ON p.id = upp.poi_id WHERE upp.user_id = v_uid), '[]'::jsonb),
    'cities', COALESCE((SELECT jsonb_agg(jsonb_build_object('city_id', ua.city_id, 'name', c.name, 'valid_until', ua.valid_until))
              FROM public.user_access ua JOIN public.cities c ON c.id = ua.city_id WHERE ua.user_id = v_uid), '[]'::jsonb),
    'city_bundles', COALESCE((SELECT jsonb_agg(jsonb_build_object('city_id', ucp.city_id, 'name', c.name))
              FROM public.user_city_premium_purchases ucp JOIN public.cities c ON c.id = ucp.city_id WHERE ucp.user_id = v_uid), '[]'::jsonb),
    'countries', COALESCE((SELECT jsonb_agg(jsonb_build_object('country_code', country_code, 'valid_until', valid_until))
              FROM public.user_country_purchases WHERE user_id = v_uid), '[]'::jsonb)
  );
END;
$$;

GRANT EXECUTE ON FUNCTION public.get_my_entitlements() TO authenticated;
