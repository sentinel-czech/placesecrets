-- ================================================================
-- 018: ACCESS LEVELS + PREMIUM CONTENT + SMART URI
-- ================================================================

-- 1. New columns on pois
ALTER TABLE pois ADD COLUMN IF NOT EXISTS slug TEXT;
ALTER TABLE pois ADD COLUMN IF NOT EXISTS access_level TEXT
  NOT NULL DEFAULT 'city_access'
  CHECK (access_level IN ('public', 'registered', 'city_access', 'premium_poi'));
ALTER TABLE pois ADD COLUMN IF NOT EXISTS perex TEXT;
ALTER TABLE pois ADD COLUMN IF NOT EXISTS premium_price NUMERIC(10,2);

-- 2. New columns on cities
ALTER TABLE cities ADD COLUMN IF NOT EXISTS slug TEXT;
ALTER TABLE cities ADD COLUMN IF NOT EXISTS registered_sample_poi_id UUID
  REFERENCES pois(id) ON DELETE SET NULL;
ALTER TABLE cities ADD COLUMN IF NOT EXISTS premium_bundle_price NUMERIC(10,2);

-- 3. Slugify function
CREATE OR REPLACE FUNCTION slugify(input TEXT)
RETURNS TEXT
LANGUAGE plpgsql IMMUTABLE
SET search_path = public, pg_catalog
AS $fn$
BEGIN
  RETURN lower(
    regexp_replace(
      regexp_replace(
        translate(
          input,
          'áäčďéěíľňóöřšťúůüýžÁÄČĎÉĚÍĽŇÓÖŘŠŤÚŮÜÝŽ',
          'aacdeeillnoorstuuuyzAACDEEILLNOORSTUUUYZ'
        ),
        '[^a-zA-Z0-9\s-]', '', 'g'
      ),
      '\s+', '-', 'g'
    )
  );
END;
$fn$;

-- 4. Auto-slug trigger for pois (name is JSONB, uses city_id)
CREATE OR REPLACE FUNCTION pois_auto_slug()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_catalog
AS $fn$
DECLARE
  base_slug TEXT;
  final_slug TEXT;
  counter INTEGER := 0;
BEGIN
  IF NEW.slug IS NULL OR NEW.slug = '' THEN
    base_slug := slugify(
      COALESCE(NEW.name->>'cs', NEW.name->>'en', NEW.name::TEXT, 'poi')
    );
    final_slug := base_slug;
    WHILE EXISTS (
      SELECT 1 FROM pois WHERE slug = final_slug AND city_id = NEW.city_id AND id != NEW.id
    ) LOOP
      counter := counter + 1;
      final_slug := base_slug || '-' || counter;
    END LOOP;
    NEW.slug := final_slug;
  END IF;
  RETURN NEW;
END;
$fn$;

DROP TRIGGER IF EXISTS pois_slug_trigger ON pois;
CREATE TRIGGER pois_slug_trigger
  BEFORE INSERT OR UPDATE ON pois
  FOR EACH ROW EXECUTE FUNCTION pois_auto_slug();

-- 5. Auto-slug trigger for cities (name is TEXT)
CREATE OR REPLACE FUNCTION cities_auto_slug()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_catalog
AS $fn$
DECLARE
  base_slug TEXT;
  final_slug TEXT;
  counter INTEGER := 0;
BEGIN
  IF NEW.slug IS NULL OR NEW.slug = '' THEN
    base_slug := slugify(COALESCE(NEW.name, 'city'));
    final_slug := base_slug;
    WHILE EXISTS (SELECT 1 FROM cities WHERE slug = final_slug AND id != NEW.id) LOOP
      counter := counter + 1;
      final_slug := base_slug || '-' || counter;
    END LOOP;
    NEW.slug := final_slug;
  END IF;
  RETURN NEW;
END;
$fn$;

DROP TRIGGER IF EXISTS cities_slug_trigger ON cities;
CREATE TRIGGER cities_slug_trigger
  BEFORE INSERT OR UPDATE ON cities
  FOR EACH ROW EXECUTE FUNCTION cities_auto_slug();

-- 6. Backfill slugs for existing records
UPDATE pois SET slug = NULL WHERE slug IS NULL;
UPDATE cities SET slug = NULL WHERE slug IS NULL;

-- 7. Unique indexes for slugs
CREATE UNIQUE INDEX IF NOT EXISTS pois_slug_city_idx ON pois(slug, city_id);
CREATE UNIQUE INDEX IF NOT EXISTS cities_slug_idx ON cities(slug);
CREATE INDEX IF NOT EXISTS pois_slug_idx ON pois(slug);

-- 8. Premium content table
CREATE TABLE IF NOT EXISTS poi_premium_content (
  id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  poi_id       UUID NOT NULL REFERENCES pois(id) ON DELETE CASCADE,
  audio_url    TEXT,
  text_content TEXT,
  extra_photos JSONB DEFAULT '[]',
  related_poi_ids UUID[] DEFAULT '{}',
  created_at   TIMESTAMPTZ DEFAULT NOW(),
  updated_at   TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(poi_id)
);

CREATE TRIGGER poi_premium_content_updated_at
  BEFORE UPDATE ON poi_premium_content
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- 9. User POI purchases table
CREATE TABLE IF NOT EXISTS user_poi_purchases (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id         UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  poi_id          UUID NOT NULL REFERENCES pois(id) ON DELETE CASCADE,
  purchased_at    TIMESTAMPTZ DEFAULT NOW(),
  price_paid      NUMERIC(10,2),
  payment_id      TEXT,
  stripe_session_id TEXT,
  UNIQUE(user_id, poi_id)
);

-- 10. User city premium bundle purchases table
CREATE TABLE IF NOT EXISTS user_city_premium_purchases (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id         UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  city_id         UUID NOT NULL REFERENCES cities(id) ON DELETE CASCADE,
  purchased_at    TIMESTAMPTZ DEFAULT NOW(),
  price_paid      NUMERIC(10,2),
  payment_id      TEXT,
  stripe_session_id TEXT,
  UNIQUE(user_id, city_id)
);

-- 11. RLS on new tables
ALTER TABLE poi_premium_content ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_poi_purchases ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_city_premium_purchases ENABLE ROW LEVEL SECURITY;

-- Premium content: SELECT for purchasers, area bundle owners, or admin
CREATE POLICY "premium_content_select" ON poi_premium_content
  FOR SELECT USING (
    auth.uid() IN (
      SELECT user_id FROM user_poi_purchases WHERE poi_id = poi_premium_content.poi_id
    )
    OR auth.uid() IN (
      SELECT ucpp.user_id FROM user_city_premium_purchases ucpp
      JOIN pois p ON p.city_id = ucpp.city_id
      WHERE p.id = poi_premium_content.poi_id
    )
    OR EXISTS (SELECT 1 FROM admin_users WHERE user_id = auth.uid())
  );

-- User POI purchases: own records only
CREATE POLICY "user_poi_purchases_select" ON user_poi_purchases
  FOR SELECT USING (user_id = auth.uid());

-- User city premium purchases: own records only
CREATE POLICY "user_city_premium_purchases_select" ON user_city_premium_purchases
  FOR SELECT USING (user_id = auth.uid());

-- 12. Indexes for performance
CREATE INDEX IF NOT EXISTS user_poi_purchases_poi_id_idx ON user_poi_purchases(poi_id);
CREATE INDEX IF NOT EXISTS user_city_premium_purchases_city_id_idx ON user_city_premium_purchases(city_id);

-- 13. Storage bucket for premium audio
INSERT INTO storage.buckets (id, name, public)
VALUES ('premium-audio', 'premium-audio', false)
ON CONFLICT DO NOTHING;

-- Premium audio storage RLS: access for purchasers or admin
CREATE POLICY "premium_audio_select" ON storage.objects
  FOR SELECT USING (
    bucket_id = 'premium-audio' AND (
      EXISTS (
        SELECT 1 FROM user_poi_purchases upp
        WHERE upp.user_id = auth.uid()
          AND storage.objects.name LIKE upp.poi_id::TEXT || '/%'
      )
      OR EXISTS (
        SELECT 1 FROM user_city_premium_purchases ucpp
        JOIN pois p ON p.city_id = ucpp.city_id
        WHERE ucpp.user_id = auth.uid()
          AND storage.objects.name LIKE p.id::TEXT || '/%'
      )
      OR EXISTS (SELECT 1 FROM admin_users WHERE user_id = auth.uid())
    )
  );

-- 14. RPC: get_poi_access
CREATE OR REPLACE FUNCTION get_poi_access(p_poi_id UUID)
RETURNS TEXT
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_catalog
AS $fn$
DECLARE
  v_user_id UUID := auth.uid();
  v_city_id UUID;
BEGIN
  SELECT city_id INTO v_city_id FROM pois WHERE id = p_poi_id;

  -- Anonymous
  IF v_user_id IS NULL THEN RETURN 'public'; END IF;

  -- Admin: full access
  IF EXISTS (SELECT 1 FROM admin_users WHERE user_id = v_user_id) THEN
    RETURN 'full';
  END IF;

  -- Purchased specific POI
  IF EXISTS (
    SELECT 1 FROM user_poi_purchases
    WHERE user_id = v_user_id AND poi_id = p_poi_id
  ) THEN RETURN 'premium_poi'; END IF;

  -- Purchased city premium bundle
  IF EXISTS (
    SELECT 1 FROM user_city_premium_purchases
    WHERE user_id = v_user_id AND city_id = v_city_id
  ) THEN RETURN 'premium_poi'; END IF;

  -- Has city access (from user_access table)
  IF EXISTS (
    SELECT 1 FROM user_access
    WHERE user_id = v_user_id AND city_id = v_city_id
  ) THEN RETURN 'city_access'; END IF;

  -- Registered: sample POI free
  IF EXISTS (
    SELECT 1 FROM cities
    WHERE id = v_city_id AND registered_sample_poi_id = p_poi_id
  ) THEN RETURN 'registered'; END IF;

  -- Authenticated but no purchase
  RETURN 'registered_limited';
END;
$fn$;

-- 15. RPC: get_poi_by_slug
CREATE OR REPLACE FUNCTION get_poi_by_slug(p_city_slug TEXT, p_poi_slug TEXT)
RETURNS TABLE(
  poi_id UUID, poi_name JSONB, poi_perex TEXT,
  poi_access_level TEXT, poi_premium_price NUMERIC,
  poi_lat DOUBLE PRECISION, poi_lng DOUBLE PRECISION,
  city_id UUID, city_name TEXT, city_slug TEXT
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
    c.id, c.name, c.slug
  FROM pois p
  JOIN cities c ON c.id = p.city_id
  WHERE c.slug = p_city_slug AND p.slug = p_poi_slug
  LIMIT 1;
END;
$fn$;

-- 16. View: user_all_purchases (union of all purchase types)
CREATE OR REPLACE VIEW user_all_purchases AS
SELECT
  'poi' AS purchase_type,
  upp.user_id,
  upp.purchased_at,
  upp.price_paid,
  upp.payment_id,
  p.id AS item_id,
  p.name->>'cs' AS item_name,
  p.slug AS item_slug,
  c.slug AS city_slug,
  c.name AS city_name
FROM user_poi_purchases upp
JOIN pois p ON p.id = upp.poi_id
JOIN cities c ON c.id = p.city_id

UNION ALL

SELECT
  'city_premium' AS purchase_type,
  ucpp.user_id,
  ucpp.purchased_at,
  ucpp.price_paid,
  ucpp.payment_id,
  c.id AS item_id,
  c.name AS item_name,
  c.slug AS item_slug,
  c.slug AS city_slug,
  c.name AS city_name
FROM user_city_premium_purchases ucpp
JOIN cities c ON c.id = ucpp.city_id

UNION ALL

SELECT
  'city_access' AS purchase_type,
  ua.user_id,
  ua.purchased_at,
  ua.amount_eur AS price_paid,
  ua.transaction_id AS payment_id,
  c.id AS item_id,
  c.name AS item_name,
  c.slug AS item_slug,
  c.slug AS city_slug,
  c.name AS city_name
FROM user_access ua
JOIN cities c ON c.id = ua.city_id;

ALTER VIEW user_all_purchases SET (security_invoker = true);
