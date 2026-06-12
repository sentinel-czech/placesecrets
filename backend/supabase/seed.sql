-- Seed data: Test city Plzen with 2 POIs

INSERT INTO public.countries (code, name)
VALUES ('CZ', 'Czechia')
ON CONFLICT (code) DO NOTHING;

INSERT INTO public.cities (name, country_code, latitude, longitude, bounding_box_radius_km, price_eur)
VALUES ('Plzen', 'CZ', 49.7475, 13.3776, 10, 1.00)
ON CONFLICT DO NOTHING;

INSERT INTO public.pois (city_id, name, description, latitude, longitude, geofence_radius, is_premium, sort_order)
VALUES
  (
    (SELECT id FROM public.cities WHERE name = 'Plzen'),
    '{"cs": "Namesti Republiky", "en": "Republic Square"}',
    '{"cs": "Hlavni namesti v centru Plzne s morovym sloupem a kasnou.", "en": "Main square in the center of Pilsen with a plague column and fountain."}',
    49.7474, 13.3776, 150, FALSE, 1
  ),
  (
    (SELECT id FROM public.cities WHERE name = 'Plzen'),
    '{"cs": "Katedrala sv. Bartolomeje", "en": "Cathedral of St. Bartholomew"}',
    '{"cs": "Goticka katedrala s nejvyssi kostelni vezi v Cesku (102,6 m).", "en": "Gothic cathedral with the tallest church spire in Czechia (102.6 m)."}',
    49.7472, 13.3775, 100, TRUE, 2
  )
ON CONFLICT DO NOTHING;

-- Backfill slugs for rows inserted before migration 018 triggers
UPDATE public.cities SET updated_at = NOW() WHERE slug IS NULL;
UPDATE public.pois SET updated_at = NOW() WHERE slug IS NULL;

-- Enrich POI data with type, perex, aliases, photos, access_level
UPDATE public.pois SET
  type_id      = (SELECT id FROM public.poi_types WHERE slug = 'building'),
  perex        = '{"cs": "Srdce Plzně — nádherné náměstí s morovým sloupem a renesanční kašnou.", "en": "The heart of Pilsen — a stunning square with a plague column and Renaissance fountain."}'::jsonb,
  aliases      = ARRAY['Náměstí Republiky', 'Republic Sq.', 'Hauptplatz'],
  photo_urls   = '["https://images.unsplash.com/photo-1600596542815-ffad4c1539a9?w=800", "https://images.unsplash.com/photo-1580137189272-c9379f8864fd?w=800"]'::jsonb,
  access_level = 'public'
WHERE slug = 'namesti-republiky';

UPDATE public.pois SET
  type_id      = (SELECT id FROM public.poi_types WHERE slug = 'church'),
  perex        = '{"cs": "Gotická katedrála s nejvyšší kostelní věží v Česku (102,6 m).", "en": "Gothic cathedral with the tallest church spire in Czechia at 102.6 m."}'::jsonb,
  aliases      = ARRAY['Katedrála sv. Bartoloměje', 'St. Bartholomew Cathedral', 'Bartolomějský chrám'],
  photo_urls   = '["https://images.unsplash.com/photo-1548625149-fc4a29cf7092?w=800", "https://images.unsplash.com/photo-1572252009286-268acec5ca0a?w=800"]'::jsonb,
  access_level = 'city_access',
  premium_price = 0.99
WHERE slug = 'katedrala-sv-bartolomeje';

-- Audio guides for POIs
INSERT INTO public.poi_audio_guides (poi_id, lang_code, title, url, duration_sec, sort_order)
VALUES
  (
    (SELECT id FROM public.pois WHERE slug = 'namesti-republiky'),
    'cs', 'Historie náměstí',
    'https://placesecrets.app/audio/demo/namesti-republiky-cs.mp3',
    180, 1
  ),
  (
    (SELECT id FROM public.pois WHERE slug = 'namesti-republiky'),
    'en', 'Square History',
    'https://placesecrets.app/audio/demo/namesti-republiky-en.mp3',
    195, 2
  ),
  (
    (SELECT id FROM public.pois WHERE slug = 'katedrala-sv-bartolomeje'),
    'cs', 'Gotická katedrála',
    'https://placesecrets.app/audio/demo/katedrala-cs.mp3',
    240, 1
  ),
  (
    (SELECT id FROM public.pois WHERE slug = 'katedrala-sv-bartolomeje'),
    'en', 'Gothic Cathedral',
    'https://placesecrets.app/audio/demo/katedrala-en.mp3',
    250, 2
  )
ON CONFLICT DO NOTHING;

-- Payment config
UPDATE public.payment_config SET
  operator_name = 'PlaceSecrets',
  revolut_username = 'placesecrets'
WHERE id = (SELECT id FROM public.payment_config LIMIT 1);

-- Superadmin user for local dev (vtm@placesecrets.cz / vtm999)
-- Must come BEFORE contributor block so auth.users is not empty
DO $$
DECLARE
  v_user_id UUID;
BEGIN
  SELECT id INTO v_user_id FROM auth.users WHERE email = 'vtm@placesecrets.cz';
  IF v_user_id IS NOT NULL THEN RETURN; END IF;

  INSERT INTO auth.users (
    instance_id, id, aud, role, email, encrypted_password,
    email_confirmed_at, created_at, updated_at,
    confirmation_token, recovery_token, email_change_token_new, email_change,
    is_sso_user
  )
  VALUES (
    '00000000-0000-0000-0000-000000000000',
    gen_random_uuid(), 'authenticated', 'authenticated',
    'vtm@placesecrets.cz',
    extensions.crypt('vtm999', extensions.gen_salt('bf')),
    NOW(), NOW(), NOW(),
    '', '', '', '',
    false
  )
  RETURNING id INTO v_user_id;

  INSERT INTO auth.identities (id, user_id, identity_data, provider, provider_id, last_sign_in_at, created_at, updated_at)
  VALUES (v_user_id, v_user_id, jsonb_build_object('sub', v_user_id::text, 'email', 'vtm@placesecrets.cz'), 'email', v_user_id::text, NOW(), NOW(), NOW());

  INSERT INTO public.admin_users (user_id, role, pin_hash)
  VALUES (v_user_id, 'superadmin', extensions.crypt('123456', extensions.gen_salt('bf')))
  ON CONFLICT (user_id) DO NOTHING;
END $$;

-- Sample contributor profile and ratings (for uploader_handle resolution)
DO $$
DECLARE
  v_user_id UUID;
  v_poi_id  UUID;
BEGIN
  SELECT id INTO v_user_id FROM auth.users LIMIT 1;
  IF v_user_id IS NULL THEN RETURN; END IF;

  INSERT INTO public.contributor_profiles (user_id, display_name, bio, specializations, is_verified)
  VALUES (v_user_id, 'Test Guide', 'A local history enthusiast.', ARRAY['monument','historic'], TRUE)
  ON CONFLICT (user_id) DO NOTHING;

  FOR v_poi_id IN
    SELECT id FROM public.pois WHERE city_id = (SELECT id FROM public.cities WHERE name = 'Plzen')
  LOOP
    INSERT INTO public.poi_ratings (poi_id, user_id, rating, lang_code, comment)
    VALUES (v_poi_id, v_user_id, 4, 'cs', 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.')
    ON CONFLICT (poi_id, user_id) DO NOTHING;
  END LOOP;
END $$;

-- Backfill contributor links for test data (runs after all inserts above)
DO $$
DECLARE
  v_user_id UUID;
BEGIN
  SELECT id INTO v_user_id FROM auth.users WHERE email = 'vtm@placesecrets.cz';
  IF v_user_id IS NULL THEN RETURN; END IF;

  -- 1. Link POIs to contributor
  UPDATE public.pois
  SET contributor_id = v_user_id
  WHERE contributor_id IS NULL
    AND city_id = (SELECT id FROM public.cities WHERE name = 'Plzen');

  -- 2. Link audio guides to uploader
  UPDATE public.poi_audio_guides
  SET uploaded_by = v_user_id
  WHERE uploaded_by IS NULL;

  -- 3. Set display_name handle in user_profiles
  UPDATE public.user_profiles
  SET display_name = 'vtm'
  WHERE user_id = v_user_id
    AND display_name IS NULL;
END $$;

