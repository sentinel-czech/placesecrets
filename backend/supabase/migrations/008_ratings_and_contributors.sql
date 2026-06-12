-- 008: POI ratings, contributor profiles, Hall of Fame
-- Implements diff-specification-001 (D-001 through D-005)

-- =============================================
-- D-001: poi_ratings table
-- =============================================

CREATE TABLE public.poi_ratings (
  id           UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  poi_id       UUID NOT NULL REFERENCES public.pois(id) ON DELETE CASCADE,
  user_id      UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  device_id    TEXT,
  rating       SMALLINT NOT NULL CHECK (rating BETWEEN 1 AND 5),
  reason       TEXT CHECK (reason IN (
                 'inaccurate',
                 'too_short',
                 'boring',
                 'wrong_lang',
                 'other'
               )),
  lang_code    TEXT NOT NULL DEFAULT 'cs',
  created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),

  UNIQUE(poi_id, user_id),
  UNIQUE(poi_id, device_id)
);

CREATE INDEX idx_poi_ratings_poi   ON public.poi_ratings(poi_id);
CREATE INDEX idx_poi_ratings_user  ON public.poi_ratings(user_id);

ALTER TABLE public.poi_ratings ENABLE ROW LEVEL SECURITY;

CREATE POLICY "ratings_own_read" ON public.poi_ratings
  FOR SELECT USING (auth.uid() = user_id OR device_id IS NOT NULL);

CREATE POLICY "ratings_insert" ON public.poi_ratings
  FOR INSERT WITH CHECK (
    auth.uid() = user_id OR user_id IS NULL
  );

CREATE POLICY "ratings_own_update" ON public.poi_ratings
  FOR UPDATE USING (auth.uid() = user_id);

-- =============================================
-- D-002: contributor_profiles table
-- =============================================

CREATE TABLE public.contributor_profiles (
  id               UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id          UUID NOT NULL UNIQUE REFERENCES auth.users(id) ON DELETE CASCADE,

  display_name     TEXT NOT NULL,
  bio              TEXT,
  avatar_url       TEXT,
  website_url      TEXT,

  specializations  TEXT[] DEFAULT '{}',

  total_pois       INTEGER NOT NULL DEFAULT 0,
  avg_rating       DECIMAL(3,2),
  total_ratings    INTEGER NOT NULL DEFAULT 0,

  is_verified      BOOLEAN NOT NULL DEFAULT FALSE,
  is_active        BOOLEAN NOT NULL DEFAULT TRUE,

  created_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at       TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_contributor_user ON public.contributor_profiles(user_id);
CREATE INDEX idx_contributor_rating ON public.contributor_profiles(avg_rating DESC NULLS LAST);

ALTER TABLE public.contributor_profiles ENABLE ROW LEVEL SECURITY;

CREATE POLICY "contributor_public_read" ON public.contributor_profiles
  FOR SELECT USING (is_active = TRUE);

CREATE POLICY "contributor_own_write" ON public.contributor_profiles
  FOR ALL USING (auth.uid() = user_id);

-- =============================================
-- D-005: ALTER pois table + triggers
-- =============================================

ALTER TABLE public.pois
  ADD COLUMN contributor_id   UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  ADD COLUMN contributor_note TEXT;

ALTER TABLE public.pois
  ADD COLUMN avg_rating     DECIMAL(3,2),
  ADD COLUMN total_ratings  INTEGER NOT NULL DEFAULT 0;

CREATE INDEX idx_pois_contributor ON public.pois(contributor_id);

-- Trigger: recalculate POI avg_rating/total_ratings and contributor stats on rating change
CREATE OR REPLACE FUNCTION public.update_poi_rating_stats()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
DECLARE
  v_avg    DECIMAL(3,2);
  v_count  INTEGER;
  v_contributor_id UUID;
BEGIN
  SELECT ROUND(AVG(rating)::NUMERIC, 2), COUNT(*)
    INTO v_avg, v_count
    FROM public.poi_ratings
    WHERE poi_id = NEW.poi_id;

  UPDATE public.pois
    SET avg_rating = v_avg, total_ratings = v_count
    WHERE id = NEW.poi_id
    RETURNING contributor_id INTO v_contributor_id;

  IF v_contributor_id IS NOT NULL THEN
    UPDATE public.contributor_profiles
      SET
        avg_rating = (
          SELECT ROUND(AVG(pr.rating)::NUMERIC, 2)
          FROM public.poi_ratings pr
          JOIN public.pois p ON p.id = pr.poi_id
          WHERE p.contributor_id = v_contributor_id
        ),
        total_ratings = (
          SELECT COUNT(*)
          FROM public.poi_ratings pr
          JOIN public.pois p ON p.id = pr.poi_id
          WHERE p.contributor_id = v_contributor_id
        ),
        updated_at = NOW()
      WHERE user_id = v_contributor_id;
  END IF;

  RETURN NEW;
END;
$$;

CREATE TRIGGER trg_update_poi_rating_stats
  AFTER INSERT OR UPDATE ON public.poi_ratings
  FOR EACH ROW EXECUTE FUNCTION public.update_poi_rating_stats();

-- Trigger: recalculate total_pois in contributor_profile on POI change
CREATE OR REPLACE FUNCTION public.update_contributor_poi_count()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
  IF NEW.contributor_id IS NOT NULL THEN
    UPDATE public.contributor_profiles
      SET total_pois = (
        SELECT COUNT(*) FROM public.pois
        WHERE contributor_id = NEW.contributor_id AND is_active = TRUE
      ),
      updated_at = NOW()
    WHERE user_id = NEW.contributor_id;
  END IF;
  RETURN NEW;
END;
$$;

CREATE TRIGGER trg_update_contributor_poi_count
  AFTER INSERT OR UPDATE OF is_active, contributor_id ON public.pois
  FOR EACH ROW EXECUTE FUNCTION public.update_contributor_poi_count();

-- =============================================
-- D-003: contributor_rankings view
-- =============================================

CREATE OR REPLACE VIEW public.contributor_rankings AS
SELECT
  cp.id                AS contributor_id,
  cp.user_id,
  cp.display_name,
  cp.avatar_url,
  cp.is_verified,
  cp.total_pois,
  cp.avg_rating,
  cp.total_ratings,
  c.id                 AS city_id,
  c.name               AS city_name,

  COUNT(p.id)          AS city_poi_count,

  ROUND(AVG(
    (SELECT AVG(r.rating) FROM public.poi_ratings r WHERE r.poi_id = p.id)
  )::NUMERIC, 2)       AS city_avg_rating,

  SUM(
    (SELECT COUNT(*) FROM public.poi_ratings r WHERE r.poi_id = p.id)
  )                    AS city_total_ratings,

  CASE
    WHEN SUM(
      (SELECT COUNT(*) FROM public.poi_ratings r WHERE r.poi_id = p.id)
    ) >= 10
    THEN ROUND((
      AVG(
        (SELECT AVG(r.rating) FROM public.poi_ratings r WHERE r.poi_id = p.id)
      ) * LOG(
        SUM(
          (SELECT COUNT(*) FROM public.poi_ratings r WHERE r.poi_id = p.id)
        ) + 1
      )
    )::NUMERIC, 4)
    ELSE NULL
  END                  AS hof_score,

  RANK() OVER (
    PARTITION BY c.id
    ORDER BY CASE
      WHEN SUM(
        (SELECT COUNT(*) FROM public.poi_ratings r WHERE r.poi_id = p.id)
      ) >= 10
      THEN AVG(
        (SELECT AVG(r.rating) FROM public.poi_ratings r WHERE r.poi_id = p.id)
      ) * LOG(
        SUM(
          (SELECT COUNT(*) FROM public.poi_ratings r WHERE r.poi_id = p.id)
        ) + 1
      )
      ELSE NULL
    END DESC NULLS LAST
  )                    AS city_rank

FROM public.contributor_profiles cp
JOIN public.pois p ON p.contributor_id = cp.user_id AND p.is_active = TRUE
JOIN public.cities c ON c.id = p.city_id
GROUP BY cp.id, cp.user_id, cp.display_name, cp.avatar_url,
         cp.is_verified, cp.total_pois, cp.avg_rating, cp.total_ratings,
         c.id, c.name;

GRANT SELECT ON public.contributor_rankings TO anon, authenticated, service_role;

-- =============================================
-- D-004: poi_hall_of_fame() RPC
-- =============================================

CREATE OR REPLACE FUNCTION public.poi_hall_of_fame(
  p_city_id   UUID,
  p_limit     INTEGER DEFAULT 10
)
RETURNS TABLE (
  rank            BIGINT,
  contributor_id  UUID,
  display_name    TEXT,
  avatar_url      TEXT,
  is_verified     BOOLEAN,
  city_poi_count  BIGINT,
  city_avg_rating DECIMAL,
  city_total_ratings BIGINT,
  hof_score       DECIMAL,
  sample_poi_names JSONB
)
LANGUAGE sql STABLE SECURITY DEFINER AS $$
  SELECT
    cr.city_rank        AS rank,
    cr.contributor_id,
    cr.display_name,
    cr.avatar_url,
    cr.is_verified,
    cr.city_poi_count,
    cr.city_avg_rating,
    cr.city_total_ratings,
    cr.hof_score,
    (
      SELECT jsonb_agg(p.name ORDER BY p.sort_order)
      FROM public.pois p
      WHERE p.contributor_id = cr.user_id
        AND p.city_id = p_city_id
        AND p.is_active = TRUE
      LIMIT 3
    ) AS sample_poi_names
  FROM public.contributor_rankings cr
  WHERE cr.city_id = p_city_id
    AND cr.hof_score IS NOT NULL
    AND cr.city_rank <= p_limit
  ORDER BY cr.city_rank
  LIMIT p_limit;
$$;

GRANT EXECUTE ON FUNCTION public.poi_hall_of_fame TO anon, authenticated;
