-- ================================================================
-- DATABASE TESTS for PlaceSecrets/HeroDots
-- Run against local Supabase: psql $DATABASE_URL < database_test.sql
-- ================================================================

-- Helper: assertion function
CREATE OR REPLACE FUNCTION assert_equals(label TEXT, expected TEXT, actual TEXT)
RETURNS VOID LANGUAGE plpgsql AS $$
BEGIN
  IF expected IS DISTINCT FROM actual THEN
    RAISE EXCEPTION 'FAIL [%]: expected=% actual=%', label, expected, actual;
  ELSE
    RAISE NOTICE 'PASS [%]', label;
  END IF;
END;
$$;

CREATE OR REPLACE FUNCTION assert_true(label TEXT, condition BOOLEAN)
RETURNS VOID LANGUAGE plpgsql AS $$
BEGIN
  IF NOT condition THEN
    RAISE EXCEPTION 'FAIL [%]: expected TRUE', label;
  ELSE
    RAISE NOTICE 'PASS [%]', label;
  END IF;
END;
$$;

CREATE OR REPLACE FUNCTION assert_false(label TEXT, condition BOOLEAN)
RETURNS VOID LANGUAGE plpgsql AS $$
BEGIN
  IF condition THEN
    RAISE EXCEPTION 'FAIL [%]: expected FALSE', label;
  ELSE
    RAISE NOTICE 'PASS [%]', label;
  END IF;
END;
$$;

-- ================================================================
-- 1. SLUGIFY TESTS
-- ================================================================
DO $$
BEGIN
  PERFORM assert_equals('slugify: basic latin', 'hello-world', slugify('Hello World'));
  PERFORM assert_equals('slugify: czech diacritics', 'karluv-most', slugify('Karlův most'));
  PERFORM assert_equals('slugify: multiple spaces', 'one-two', slugify('one   two'));
  PERFORM assert_equals('slugify: special chars stripped', 'cafe-bar', slugify('Café & Bar!'));
  PERFORM assert_equals('slugify: empty string', '', slugify(''));
  PERFORM assert_equals('slugify: already slug', 'my-slug', slugify('my-slug'));
  PERFORM assert_equals('slugify: all diacritics', 'aacdeeillnoorstuuuy', slugify('áäčďéěíľňóöřšťúůüýž'));
END $$;

-- ================================================================
-- 2. POIS AUTO-SLUG TRIGGER TESTS
-- ================================================================

-- Setup: ensure a test city exists
INSERT INTO cities (id, name, country_code, latitude, longitude)
VALUES ('00000000-0000-0000-0000-000000000001', 'TestCity', 'CZ', 50.0, 14.0)
ON CONFLICT (id) DO NOTHING;

INSERT INTO cities (id, name, country_code, latitude, longitude)
VALUES ('00000000-0000-0000-0000-000000000002', 'TestCity2', 'CZ', 49.0, 15.0)
ON CONFLICT (id) DO NOTHING;

DO $$
DECLARE
  slug1 TEXT;
  slug2 TEXT;
  slug3 TEXT;
BEGIN
  -- Test: INSERT with NULL slug auto-generates
  INSERT INTO pois (id, city_id, name, description, latitude, longitude, geofence_radius)
  VALUES (
    '10000000-0000-0000-0000-000000000001',
    '00000000-0000-0000-0000-000000000001',
    '{"cs": "Karlův most", "en": "Charles Bridge"}'::jsonb,
    '{"cs": "Popis"}'::jsonb, 50.08, 14.41, 100
  ) ON CONFLICT (id) DO UPDATE SET slug = NULL;

  SELECT slug INTO slug1 FROM pois WHERE id = '10000000-0000-0000-0000-000000000001';
  PERFORM assert_equals('poi slug: auto-generate from cs name', 'karluv-most', slug1);

  -- Test: INSERT with explicit slug keeps it
  INSERT INTO pois (id, city_id, name, description, latitude, longitude, geofence_radius, slug)
  VALUES (
    '10000000-0000-0000-0000-000000000002',
    '00000000-0000-0000-0000-000000000001',
    '{"cs": "Test"}'::jsonb, '{"cs": "Desc"}'::jsonb, 50.0, 14.0, 50, 'my-custom-slug'
  ) ON CONFLICT (id) DO UPDATE SET slug = EXCLUDED.slug;

  SELECT slug INTO slug1 FROM pois WHERE id = '10000000-0000-0000-0000-000000000002';
  PERFORM assert_equals('poi slug: explicit slug kept', 'my-custom-slug', slug1);

  -- Test: Collision — same name, same city → gets suffix
  INSERT INTO pois (id, city_id, name, description, latitude, longitude, geofence_radius)
  VALUES (
    '10000000-0000-0000-0000-000000000003',
    '00000000-0000-0000-0000-000000000001',
    '{"cs": "Karlův most"}'::jsonb, '{"cs": "Desc"}'::jsonb, 50.1, 14.5, 50
  ) ON CONFLICT (id) DO UPDATE SET slug = NULL;

  SELECT slug INTO slug2 FROM pois WHERE id = '10000000-0000-0000-0000-000000000003';
  PERFORM assert_equals('poi slug: collision gets suffix', 'karluv-most-1', slug2);

  -- Test: Third collision
  INSERT INTO pois (id, city_id, name, description, latitude, longitude, geofence_radius)
  VALUES (
    '10000000-0000-0000-0000-000000000004',
    '00000000-0000-0000-0000-000000000001',
    '{"cs": "Karlův most"}'::jsonb, '{"cs": "Desc"}'::jsonb, 50.2, 14.6, 50
  ) ON CONFLICT (id) DO UPDATE SET slug = NULL;

  SELECT slug INTO slug3 FROM pois WHERE id = '10000000-0000-0000-0000-000000000004';
  PERFORM assert_equals('poi slug: triple collision', 'karluv-most-2', slug3);

  -- Test: Same name in different city → same slug allowed
  INSERT INTO pois (id, city_id, name, description, latitude, longitude, geofence_radius)
  VALUES (
    '10000000-0000-0000-0000-000000000005',
    '00000000-0000-0000-0000-000000000002',
    '{"cs": "Karlův most"}'::jsonb, '{"cs": "Desc"}'::jsonb, 49.1, 15.1, 50
  ) ON CONFLICT (id) DO UPDATE SET slug = NULL;

  SELECT slug INTO slug1 FROM pois WHERE id = '10000000-0000-0000-0000-000000000005';
  PERFORM assert_equals('poi slug: different city same slug', 'karluv-most', slug1);

  -- Test: Fallback to 'en' key
  INSERT INTO pois (id, city_id, name, description, latitude, longitude, geofence_radius)
  VALUES (
    '10000000-0000-0000-0000-000000000006',
    '00000000-0000-0000-0000-000000000002',
    '{"en": "Tower"}'::jsonb, '{"en": "Desc"}'::jsonb, 49.2, 15.2, 50
  ) ON CONFLICT (id) DO UPDATE SET slug = NULL;

  SELECT slug INTO slug1 FROM pois WHERE id = '10000000-0000-0000-0000-000000000006';
  PERFORM assert_equals('poi slug: fallback to en', 'tower', slug1);

  -- Cleanup
  DELETE FROM pois WHERE id IN (
    '10000000-0000-0000-0000-000000000001',
    '10000000-0000-0000-0000-000000000002',
    '10000000-0000-0000-0000-000000000003',
    '10000000-0000-0000-0000-000000000004',
    '10000000-0000-0000-0000-000000000005',
    '10000000-0000-0000-0000-000000000006'
  );
END $$;

-- ================================================================
-- 3. CITIES AUTO-SLUG TRIGGER TESTS
-- ================================================================
DO $$
DECLARE
  slug1 TEXT;
  slug2 TEXT;
BEGIN
  -- Already inserted TestCity with NULL slug → trigger fired
  SELECT slug INTO slug1 FROM cities WHERE id = '00000000-0000-0000-0000-000000000001';
  PERFORM assert_equals('city slug: auto-generated', 'testcity', slug1);

  -- Test collision
  INSERT INTO cities (id, name, country_code, latitude, longitude)
  VALUES ('00000000-0000-0000-0000-000000000003', 'TestCity', 'CZ', 48.0, 16.0)
  ON CONFLICT (id) DO UPDATE SET slug = NULL;

  SELECT slug INTO slug2 FROM cities WHERE id = '00000000-0000-0000-0000-000000000003';
  PERFORM assert_equals('city slug: collision', 'testcity-1', slug2);

  -- Cleanup
  DELETE FROM cities WHERE id = '00000000-0000-0000-0000-000000000003';
END $$;

-- ================================================================
-- 4. CONSTRAINTS TESTS
-- ================================================================
DO $$
BEGIN
  -- Test CHECK constraint on access_level
  BEGIN
    INSERT INTO pois (id, city_id, name, description, latitude, longitude, geofence_radius, access_level)
    VALUES (
      '10000000-0000-0000-0000-000000000099',
      '00000000-0000-0000-0000-000000000001',
      '{"cs": "Test"}'::jsonb, '{"cs": "D"}'::jsonb, 50.0, 14.0, 50, 'invalid_level'
    );
    RAISE EXCEPTION 'FAIL [constraint: invalid access_level should be rejected]';
  EXCEPTION WHEN check_violation THEN
    RAISE NOTICE 'PASS [constraint: invalid access_level rejected]';
  END;

  -- Test UNIQUE(poi_id) on poi_premium_content
  INSERT INTO pois (id, city_id, name, description, latitude, longitude, geofence_radius)
  VALUES (
    '10000000-0000-0000-0000-000000000010',
    '00000000-0000-0000-0000-000000000001',
    '{"cs": "Content Test"}'::jsonb, '{"cs": "D"}'::jsonb, 50.0, 14.0, 50
  ) ON CONFLICT (id) DO NOTHING;

  INSERT INTO poi_premium_content (poi_id, text_content)
  VALUES ('10000000-0000-0000-0000-000000000010', 'Test content')
  ON CONFLICT DO NOTHING;

  BEGIN
    INSERT INTO poi_premium_content (poi_id, text_content)
    VALUES ('10000000-0000-0000-0000-000000000010', 'Duplicate content');
    RAISE EXCEPTION 'FAIL [constraint: duplicate poi_premium_content should fail]';
  EXCEPTION WHEN unique_violation THEN
    RAISE NOTICE 'PASS [constraint: duplicate poi_premium_content rejected]';
  END;

  -- Cleanup
  DELETE FROM poi_premium_content WHERE poi_id = '10000000-0000-0000-0000-000000000010';
  DELETE FROM pois WHERE id = '10000000-0000-0000-0000-000000000010';
END $$;

-- ================================================================
-- 5. CASCADE DELETE TESTS
-- ================================================================
DO $$
DECLARE
  content_exists BOOLEAN;
BEGIN
  -- Setup: POI + premium content
  INSERT INTO pois (id, city_id, name, description, latitude, longitude, geofence_radius)
  VALUES (
    '10000000-0000-0000-0000-000000000020',
    '00000000-0000-0000-0000-000000000001',
    '{"cs": "Cascade Test"}'::jsonb, '{"cs": "D"}'::jsonb, 50.0, 14.0, 50
  ) ON CONFLICT (id) DO NOTHING;

  INSERT INTO poi_premium_content (poi_id, text_content)
  VALUES ('10000000-0000-0000-0000-000000000020', 'Premium text')
  ON CONFLICT DO NOTHING;

  -- Delete POI → should cascade to premium content
  DELETE FROM pois WHERE id = '10000000-0000-0000-0000-000000000020';

  SELECT EXISTS (
    SELECT 1 FROM poi_premium_content WHERE poi_id = '10000000-0000-0000-0000-000000000020'
  ) INTO content_exists;

  PERFORM assert_false('cascade: delete POI deletes premium content', content_exists);
END $$;

-- ================================================================
-- 6. REGISTERED_SAMPLE_POI_ID ON DELETE SET NULL
-- ================================================================
DO $$
DECLARE
  sample_id UUID;
BEGIN
  -- Setup: POI as sample
  INSERT INTO pois (id, city_id, name, description, latitude, longitude, geofence_radius)
  VALUES (
    '10000000-0000-0000-0000-000000000030',
    '00000000-0000-0000-0000-000000000001',
    '{"cs": "Sample POI"}'::jsonb, '{"cs": "D"}'::jsonb, 50.0, 14.0, 50
  ) ON CONFLICT (id) DO NOTHING;

  UPDATE cities SET registered_sample_poi_id = '10000000-0000-0000-0000-000000000030'
  WHERE id = '00000000-0000-0000-0000-000000000001';

  -- Delete the POI → city.registered_sample_poi_id should be NULL
  DELETE FROM pois WHERE id = '10000000-0000-0000-0000-000000000030';

  SELECT registered_sample_poi_id INTO sample_id
  FROM cities WHERE id = '00000000-0000-0000-0000-000000000001';

  PERFORM assert_true('ON DELETE SET NULL: sample POI nullified', sample_id IS NULL);
END $$;

-- ================================================================
-- 7. VIEW user_all_purchases structure test
-- ================================================================
DO $$
DECLARE
  col_count INTEGER;
BEGIN
  SELECT count(*) INTO col_count
  FROM information_schema.columns
  WHERE table_name = 'user_all_purchases' AND table_schema = 'public';

  PERFORM assert_true('user_all_purchases view exists with columns', col_count > 0);
END $$;

-- ================================================================
-- 8. ACCESS_LEVEL CHECK CONSTRAINT — valid values
-- ================================================================
DO $$
BEGIN
  -- Valid: all 4 levels
  INSERT INTO pois (id, city_id, name, description, latitude, longitude, geofence_radius, access_level)
  VALUES (
    '10000000-0000-0000-0000-000000000040',
    '00000000-0000-0000-0000-000000000001',
    '{"cs": "AL1"}'::jsonb, '{"cs": "D"}'::jsonb, 50.0, 14.0, 50, 'public'
  ) ON CONFLICT (id) DO UPDATE SET access_level = 'public';
  PERFORM assert_equals('access_level: public ok', 'public',
    (SELECT access_level FROM pois WHERE id = '10000000-0000-0000-0000-000000000040'));

  UPDATE pois SET access_level = 'registered' WHERE id = '10000000-0000-0000-0000-000000000040';
  PERFORM assert_equals('access_level: registered ok', 'registered',
    (SELECT access_level FROM pois WHERE id = '10000000-0000-0000-0000-000000000040'));

  UPDATE pois SET access_level = 'city_access' WHERE id = '10000000-0000-0000-0000-000000000040';
  PERFORM assert_equals('access_level: city_access ok', 'city_access',
    (SELECT access_level FROM pois WHERE id = '10000000-0000-0000-0000-000000000040'));

  UPDATE pois SET access_level = 'premium_poi' WHERE id = '10000000-0000-0000-0000-000000000040';
  PERFORM assert_equals('access_level: premium_poi ok', 'premium_poi',
    (SELECT access_level FROM pois WHERE id = '10000000-0000-0000-0000-000000000040'));

  DELETE FROM pois WHERE id = '10000000-0000-0000-0000-000000000040';
END $$;

-- ================================================================
-- 9. DEFAULT VALUES TESTS
-- ================================================================
DO $$
DECLARE
  al TEXT;
  ep JSONB;
  rp UUID[];
BEGIN
  -- Default access_level is 'city_access'
  INSERT INTO pois (id, city_id, name, description, latitude, longitude, geofence_radius)
  VALUES (
    '10000000-0000-0000-0000-000000000050',
    '00000000-0000-0000-0000-000000000001',
    '{"cs": "Default Test"}'::jsonb, '{"cs": "D"}'::jsonb, 50.0, 14.0, 50
  ) ON CONFLICT (id) DO NOTHING;

  SELECT access_level INTO al FROM pois WHERE id = '10000000-0000-0000-0000-000000000050';
  PERFORM assert_equals('default access_level is city_access', 'city_access', al);

  -- poi_premium_content defaults
  INSERT INTO poi_premium_content (poi_id, text_content)
  VALUES ('10000000-0000-0000-0000-000000000050', 'Test')
  ON CONFLICT DO NOTHING;

  SELECT extra_photos, related_poi_ids INTO ep, rp
  FROM poi_premium_content
  WHERE poi_id = '10000000-0000-0000-0000-000000000050';

  PERFORM assert_equals('premium_content: extra_photos default', '[]', ep::text);
  PERFORM assert_equals('premium_content: related_poi_ids default', '{}', rp::text);

  -- Cleanup
  DELETE FROM poi_premium_content WHERE poi_id = '10000000-0000-0000-0000-000000000050';
  DELETE FROM pois WHERE id = '10000000-0000-0000-0000-000000000050';
END $$;

-- ================================================================
-- 10. VIEW user_all_purchases COLUMNS VERIFICATION
-- ================================================================
DO $$
DECLARE
  col_names TEXT[];
BEGIN
  SELECT array_agg(column_name ORDER BY ordinal_position) INTO col_names
  FROM information_schema.columns
  WHERE table_name = 'user_all_purchases' AND table_schema = 'public';

  PERFORM assert_true('view: has purchase_type', 'purchase_type' = ANY(col_names));
  PERFORM assert_true('view: has user_id', 'user_id' = ANY(col_names));
  PERFORM assert_true('view: has purchased_at', 'purchased_at' = ANY(col_names));
  PERFORM assert_true('view: has price_paid', 'price_paid' = ANY(col_names));
  PERFORM assert_true('view: has payment_id', 'payment_id' = ANY(col_names));
  PERFORM assert_true('view: has item_id', 'item_id' = ANY(col_names));
  PERFORM assert_true('view: has item_name', 'item_name' = ANY(col_names));
  PERFORM assert_true('view: has city_name', 'city_name' = ANY(col_names));
END $$;

-- ================================================================
-- 11. TABLE STRUCTURE VERIFICATION
-- ================================================================
DO $$
DECLARE
  tbl_exists BOOLEAN;
BEGIN
  -- Verify new tables exist
  SELECT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'poi_premium_content' AND table_schema = 'public') INTO tbl_exists;
  PERFORM assert_true('table: poi_premium_content exists', tbl_exists);

  SELECT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'user_poi_purchases' AND table_schema = 'public') INTO tbl_exists;
  PERFORM assert_true('table: user_poi_purchases exists', tbl_exists);

  SELECT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'user_city_premium_purchases' AND table_schema = 'public') INTO tbl_exists;
  PERFORM assert_true('table: user_city_premium_purchases exists', tbl_exists);

  -- Verify pois has new columns
  SELECT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'pois' AND column_name = 'slug' AND table_schema = 'public'
  ) INTO tbl_exists;
  PERFORM assert_true('column: pois.slug exists', tbl_exists);

  SELECT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'pois' AND column_name = 'access_level' AND table_schema = 'public'
  ) INTO tbl_exists;
  PERFORM assert_true('column: pois.access_level exists', tbl_exists);

  SELECT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'pois' AND column_name = 'perex' AND table_schema = 'public'
  ) INTO tbl_exists;
  PERFORM assert_true('column: pois.perex exists', tbl_exists);

  SELECT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'pois' AND column_name = 'premium_price' AND table_schema = 'public'
  ) INTO tbl_exists;
  PERFORM assert_true('column: pois.premium_price exists', tbl_exists);

  -- Verify cities has new columns
  SELECT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'cities' AND column_name = 'slug' AND table_schema = 'public'
  ) INTO tbl_exists;
  PERFORM assert_true('column: cities.slug exists', tbl_exists);

  SELECT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'cities' AND column_name = 'registered_sample_poi_id' AND table_schema = 'public'
  ) INTO tbl_exists;
  PERFORM assert_true('column: cities.registered_sample_poi_id exists', tbl_exists);

  SELECT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'cities' AND column_name = 'premium_bundle_price' AND table_schema = 'public'
  ) INTO tbl_exists;
  PERFORM assert_true('column: cities.premium_bundle_price exists', tbl_exists);
END $$;

-- ================================================================
-- 12. INDEX VERIFICATION
-- ================================================================
DO $$
DECLARE
  idx_exists BOOLEAN;
BEGIN
  SELECT EXISTS (SELECT 1 FROM pg_indexes WHERE indexname = 'pois_slug_city_idx') INTO idx_exists;
  PERFORM assert_true('index: pois_slug_city_idx exists', idx_exists);

  SELECT EXISTS (SELECT 1 FROM pg_indexes WHERE indexname = 'cities_slug_idx') INTO idx_exists;
  PERFORM assert_true('index: cities_slug_idx exists', idx_exists);

  SELECT EXISTS (SELECT 1 FROM pg_indexes WHERE indexname = 'pois_slug_idx') INTO idx_exists;
  PERFORM assert_true('index: pois_slug_idx exists', idx_exists);

  SELECT EXISTS (SELECT 1 FROM pg_indexes WHERE indexname = 'user_poi_purchases_poi_id_idx') INTO idx_exists;
  PERFORM assert_true('index: user_poi_purchases_poi_id_idx exists', idx_exists);

  SELECT EXISTS (SELECT 1 FROM pg_indexes WHERE indexname = 'user_city_premium_purchases_city_id_idx') INTO idx_exists;
  PERFORM assert_true('index: user_city_premium_purchases_city_id_idx exists', idx_exists);
END $$;

-- ================================================================
-- 13. RLS ENABLED VERIFICATION
-- ================================================================
DO $$
DECLARE
  rls_enabled BOOLEAN;
BEGIN
  SELECT relrowsecurity INTO rls_enabled FROM pg_class WHERE relname = 'poi_premium_content';
  PERFORM assert_true('RLS: poi_premium_content enabled', rls_enabled);

  SELECT relrowsecurity INTO rls_enabled FROM pg_class WHERE relname = 'user_poi_purchases';
  PERFORM assert_true('RLS: user_poi_purchases enabled', rls_enabled);

  SELECT relrowsecurity INTO rls_enabled FROM pg_class WHERE relname = 'user_city_premium_purchases';
  PERFORM assert_true('RLS: user_city_premium_purchases enabled', rls_enabled);
END $$;

-- ================================================================
-- 14. FUNCTION EXISTENCE VERIFICATION
-- ================================================================
DO $$
DECLARE
  fn_exists BOOLEAN;
BEGIN
  SELECT EXISTS (SELECT 1 FROM pg_proc WHERE proname = 'slugify') INTO fn_exists;
  PERFORM assert_true('function: slugify exists', fn_exists);

  SELECT EXISTS (SELECT 1 FROM pg_proc WHERE proname = 'pois_auto_slug') INTO fn_exists;
  PERFORM assert_true('function: pois_auto_slug exists', fn_exists);

  SELECT EXISTS (SELECT 1 FROM pg_proc WHERE proname = 'cities_auto_slug') INTO fn_exists;
  PERFORM assert_true('function: cities_auto_slug exists', fn_exists);

  SELECT EXISTS (SELECT 1 FROM pg_proc WHERE proname = 'get_poi_access') INTO fn_exists;
  PERFORM assert_true('function: get_poi_access exists', fn_exists);

  SELECT EXISTS (SELECT 1 FROM pg_proc WHERE proname = 'get_poi_by_slug') INTO fn_exists;
  PERFORM assert_true('function: get_poi_by_slug exists', fn_exists);

  SELECT EXISTS (SELECT 1 FROM pg_proc WHERE proname = 'set_updated_at') INTO fn_exists;
  PERFORM assert_true('function: set_updated_at exists (reused)', fn_exists);
END $$;

-- ================================================================
-- 15. TRIGGER EXISTENCE VERIFICATION
-- ================================================================
DO $$
DECLARE
  trg_exists BOOLEAN;
BEGIN
  SELECT EXISTS (SELECT 1 FROM information_schema.triggers WHERE trigger_name = 'pois_slug_trigger') INTO trg_exists;
  PERFORM assert_true('trigger: pois_slug_trigger exists', trg_exists);

  SELECT EXISTS (SELECT 1 FROM information_schema.triggers WHERE trigger_name = 'cities_slug_trigger') INTO trg_exists;
  PERFORM assert_true('trigger: cities_slug_trigger exists', trg_exists);

  SELECT EXISTS (SELECT 1 FROM information_schema.triggers WHERE trigger_name = 'poi_premium_content_updated_at') INTO trg_exists;
  PERFORM assert_true('trigger: poi_premium_content_updated_at exists', trg_exists);
END $$;

-- ================================================================
-- 16. STORAGE BUCKET VERIFICATION
-- ================================================================
DO $$
DECLARE
  bucket_exists BOOLEAN;
BEGIN
  SELECT EXISTS (SELECT 1 FROM storage.buckets WHERE id = 'premium-audio') INTO bucket_exists;
  PERFORM assert_true('storage: premium-audio bucket exists', bucket_exists);

  -- Premium-audio should be private
  SELECT NOT public INTO bucket_exists FROM storage.buckets WHERE id = 'premium-audio';
  PERFORM assert_true('storage: premium-audio is private', bucket_exists);
END $$;

-- Setup: create a test auth user for purchase tests
INSERT INTO auth.users (id, instance_id, aud, role, email, encrypted_password, email_confirmed_at, created_at, updated_at, confirmation_token, recovery_token, email_change_token_new, email_change)
VALUES (
  'aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee',
  '00000000-0000-0000-0000-000000000000',
  'authenticated', 'authenticated',
  'test@example.com', '$2a$10$abcdefghijklmnopqrstuuABCDEFGHIJKLMNOPQRSTUVWXYZ012',
  now(), now(), now(), '', '', '', ''
) ON CONFLICT (id) DO NOTHING;

-- ================================================================
-- 17. CASCADE DELETE: POI → user_poi_purchases
-- ================================================================
DO $$
DECLARE
  purchase_exists BOOLEAN;
  test_user_id UUID;
BEGIN
  test_user_id := 'aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee';

  -- Setup: POI + user_poi_purchase
  INSERT INTO pois (id, city_id, name, description, latitude, longitude, geofence_radius)
  VALUES (
    '10000000-0000-0000-0000-000000000060',
    '00000000-0000-0000-0000-000000000001',
    '{"cs": "Cascade POI Purchase"}'::jsonb, '{"cs": "D"}'::jsonb, 50.0, 14.0, 50
  ) ON CONFLICT (id) DO NOTHING;

  INSERT INTO user_poi_purchases (user_id, poi_id, price_paid, payment_id)
  VALUES (test_user_id, '10000000-0000-0000-0000-000000000060', 4.99, 'test-pay-1')
  ON CONFLICT DO NOTHING;

  -- Delete POI → should cascade to user_poi_purchases
  DELETE FROM pois WHERE id = '10000000-0000-0000-0000-000000000060';

  SELECT EXISTS (
    SELECT 1 FROM user_poi_purchases WHERE poi_id = '10000000-0000-0000-0000-000000000060'
  ) INTO purchase_exists;

  PERFORM assert_false('cascade: delete POI deletes user_poi_purchases', purchase_exists);
END $$;

-- ================================================================
-- 18. CASCADE DELETE: city → user_city_premium_purchases
-- ================================================================
DO $$
DECLARE
  purchase_exists BOOLEAN;
  test_user_id UUID;
BEGIN
  test_user_id := 'aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee';

  -- Setup: temp city + user_city_premium_purchase
  INSERT INTO cities (id, name, country_code, latitude, longitude)
  VALUES ('00000000-0000-0000-0000-000000000099', 'CascadeTestCity', 'CZ', 50.0, 14.0)
  ON CONFLICT (id) DO NOTHING;

  INSERT INTO user_city_premium_purchases (user_id, city_id, price_paid, payment_id)
  VALUES (test_user_id, '00000000-0000-0000-0000-000000000099', 9.99, 'test-pay-2')
  ON CONFLICT DO NOTHING;

  -- Delete city → should cascade to user_city_premium_purchases
  DELETE FROM cities WHERE id = '00000000-0000-0000-0000-000000000099';

  SELECT EXISTS (
    SELECT 1 FROM user_city_premium_purchases WHERE city_id = '00000000-0000-0000-0000-000000000099'
  ) INTO purchase_exists;

  PERFORM assert_false('cascade: delete city deletes user_city_premium_purchases', purchase_exists);
END $$;

-- ================================================================
-- 19. UNIQUE(user_id, poi_id) on user_poi_purchases
-- ================================================================
DO $$
DECLARE
  test_user_id UUID;
BEGIN
  test_user_id := 'aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee';

  -- Setup: POI for the test
  INSERT INTO pois (id, city_id, name, description, latitude, longitude, geofence_radius)
  VALUES (
    '10000000-0000-0000-0000-000000000070',
    '00000000-0000-0000-0000-000000000001',
    '{"cs": "Unique Test"}'::jsonb, '{"cs": "D"}'::jsonb, 50.0, 14.0, 50
  ) ON CONFLICT (id) DO NOTHING;

  INSERT INTO user_poi_purchases (user_id, poi_id, price_paid, payment_id)
  VALUES (test_user_id, '10000000-0000-0000-0000-000000000070', 4.99, 'test-pay-3')
  ON CONFLICT DO NOTHING;

  -- Duplicate insert should fail
  BEGIN
    INSERT INTO user_poi_purchases (user_id, poi_id, price_paid, payment_id)
    VALUES (test_user_id, '10000000-0000-0000-0000-000000000070', 4.99, 'test-pay-4');
    RAISE EXCEPTION 'FAIL [constraint: duplicate user_poi_purchases should fail]';
  EXCEPTION WHEN unique_violation THEN
    RAISE NOTICE 'PASS [constraint: duplicate user_poi_purchases rejected]';
  END;

  -- Cleanup
  DELETE FROM user_poi_purchases WHERE poi_id = '10000000-0000-0000-0000-000000000070';
  DELETE FROM pois WHERE id = '10000000-0000-0000-0000-000000000070';
END $$;

-- ================================================================
-- 20. SECURITY DEFINER + search_path on functions
-- ================================================================
DO $$
DECLARE
  security_type TEXT;
  search_path_set BOOLEAN;
BEGIN
  -- get_poi_access should be SECURITY DEFINER
  SELECT prosecdef::TEXT INTO security_type
  FROM pg_proc WHERE proname = 'get_poi_access';
  PERFORM assert_equals('get_poi_access is SECURITY DEFINER', 'true', security_type);

  -- get_poi_by_slug should be SECURITY DEFINER
  SELECT prosecdef::TEXT INTO security_type
  FROM pg_proc WHERE proname = 'get_poi_by_slug';
  PERFORM assert_equals('get_poi_by_slug is SECURITY DEFINER', 'true', security_type);

  -- pois_auto_slug should be SECURITY DEFINER
  SELECT prosecdef::TEXT INTO security_type
  FROM pg_proc WHERE proname = 'pois_auto_slug';
  PERFORM assert_equals('pois_auto_slug is SECURITY DEFINER', 'true', security_type);

  -- slugify should be IMMUTABLE
  SELECT provolatile INTO security_type
  FROM pg_proc WHERE proname = 'slugify';
  PERFORM assert_equals('slugify is IMMUTABLE', 'i', security_type);
END $$;

-- ================================================================
-- 21. RPC RETURN TYPE VALIDATION (call each TABLE-returning RPC)
-- Catches type mismatches between RETURNS TABLE(...) and actual query
-- ================================================================
DO $$
DECLARE
  _r RECORD;
BEGIN
  -- get_poi_by_slug: uses seed data if available, otherwise returns 0 rows (still validates types)
  SELECT * INTO _r FROM get_poi_by_slug('cz', 'plzen', 'namesti-republiky') LIMIT 1;
  RAISE NOTICE 'PASS [rpc_types: get_poi_by_slug]';
EXCEPTION WHEN others THEN
  RAISE EXCEPTION 'FAIL [rpc_types: get_poi_by_slug]: %', SQLERRM;
END $$;

DO $$
DECLARE _r RECORD;
BEGIN
  SELECT * INTO _r FROM get_poi_by_slug('xx', 'nonexistent', 'nope') LIMIT 1;
  RAISE NOTICE 'PASS [rpc_types: get_poi_by_slug empty]';
EXCEPTION WHEN others THEN
  RAISE EXCEPTION 'FAIL [rpc_types: get_poi_by_slug empty]: %', SQLERRM;
END $$;

DO $$
DECLARE _r RECORD;
BEGIN
  SELECT * INTO _r FROM poi_hall_of_fame('00000000-0000-0000-0000-000000000000') LIMIT 1;
  RAISE NOTICE 'PASS [rpc_types: poi_hall_of_fame]';
EXCEPTION WHEN others THEN
  RAISE EXCEPTION 'FAIL [rpc_types: poi_hall_of_fame]: %', SQLERRM;
END $$;

DO $$
DECLARE _r RECORD;
BEGIN
  SELECT * INTO _r FROM poi_hall_of_fame_overall() LIMIT 1;
  RAISE NOTICE 'PASS [rpc_types: poi_hall_of_fame_overall]';
EXCEPTION WHEN others THEN
  RAISE EXCEPTION 'FAIL [rpc_types: poi_hall_of_fame_overall]: %', SQLERRM;
END $$;

DO $$
DECLARE _r RECORD;
BEGIN
  SELECT * INTO _r FROM poi_types_stats() LIMIT 1;
  RAISE NOTICE 'PASS [rpc_types: poi_types_stats]';
EXCEPTION WHEN others THEN
  RAISE EXCEPTION 'FAIL [rpc_types: poi_types_stats]: %', SQLERRM;
END $$;

DO $$
DECLARE _r RECORD;
BEGIN
  SELECT * INTO _r FROM get_publishable_payment_config() LIMIT 1;
  RAISE NOTICE 'PASS [rpc_types: get_publishable_payment_config]';
EXCEPTION WHEN others THEN
  RAISE EXCEPTION 'FAIL [rpc_types: get_publishable_payment_config]: %', SQLERRM;
END $$;

DO $$
DECLARE _r RECORD;
BEGIN
  SELECT * INTO _r FROM get_all_permissions() LIMIT 1;
  RAISE NOTICE 'PASS [rpc_types: get_all_permissions]';
EXCEPTION WHEN others THEN
  RAISE EXCEPTION 'FAIL [rpc_types: get_all_permissions]: %', SQLERRM;
END $$;

DO $$
DECLARE _r RECORD;
BEGIN
  SELECT * INTO _r FROM get_role_permissions('superadmin') LIMIT 1;
  RAISE NOTICE 'PASS [rpc_types: get_role_permissions]';
EXCEPTION WHEN others THEN
  RAISE EXCEPTION 'FAIL [rpc_types: get_role_permissions]: %', SQLERRM;
END $$;

DO $$
DECLARE _r RECORD;
BEGIN
  SELECT * INTO _r FROM daily_activity(7) LIMIT 1;
  RAISE NOTICE 'PASS [rpc_types: daily_activity]';
EXCEPTION WHEN others THEN
  RAISE EXCEPTION 'FAIL [rpc_types: daily_activity]: %', SQLERRM;
END $$;

DO $$
DECLARE _r RECORD;
BEGIN
  SELECT * INTO _r FROM payment_summary() LIMIT 1;
  RAISE NOTICE 'PASS [rpc_types: payment_summary]';
EXCEPTION WHEN others THEN
  RAISE EXCEPTION 'FAIL [rpc_types: payment_summary]: %', SQLERRM;
END $$;

DO $$
DECLARE _r RECORD;
BEGIN
  SELECT * INTO _r FROM revenue_by_month() LIMIT 1;
  RAISE NOTICE 'PASS [rpc_types: revenue_by_month]';
EXCEPTION WHEN others THEN
  RAISE EXCEPTION 'FAIL [rpc_types: revenue_by_month]: %', SQLERRM;
END $$;

DO $$
DECLARE _r RECORD;
BEGIN
  SELECT * INTO _r FROM top_visited_pois(5) LIMIT 1;
  RAISE NOTICE 'PASS [rpc_types: top_visited_pois]';
EXCEPTION WHEN others THEN
  RAISE EXCEPTION 'FAIL [rpc_types: top_visited_pois]: %', SQLERRM;
END $$;

-- ================================================================
-- CLEANUP test data
-- ================================================================
DELETE FROM cities WHERE id IN (
  '00000000-0000-0000-0000-000000000001',
  '00000000-0000-0000-0000-000000000002'
);
DELETE FROM auth.users WHERE id = 'aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee';

-- Drop test helpers
DROP FUNCTION IF EXISTS assert_equals(TEXT, TEXT, TEXT);
DROP FUNCTION IF EXISTS assert_true(TEXT, BOOLEAN);
DROP FUNCTION IF EXISTS assert_false(TEXT, BOOLEAN);

-- Summary
DO $$ BEGIN RAISE NOTICE '========================================'; END $$;
DO $$ BEGIN RAISE NOTICE 'All database tests completed.'; END $$;
DO $$ BEGIN RAISE NOTICE '========================================'; END $$;
