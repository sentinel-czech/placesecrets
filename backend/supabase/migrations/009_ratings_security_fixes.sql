-- 009: Security hardening for ratings & contributor profiles
-- Fixes from code review of diff-specification-001

-- =============================================
-- 2a. Fix ratings_own_read — only allow reading own rows
-- =============================================

DROP POLICY "ratings_own_read" ON public.poi_ratings;
CREATE POLICY "ratings_own_read" ON public.poi_ratings
  FOR SELECT USING (auth.uid() = user_id);

-- =============================================
-- 2b. Fix contributor_own_write — prevent self-setting is_verified, stats
-- =============================================

DROP POLICY "contributor_own_write" ON public.contributor_profiles;

CREATE POLICY "contributor_own_insert" ON public.contributor_profiles
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "contributor_own_update" ON public.contributor_profiles
  FOR UPDATE USING (auth.uid() = user_id)
  WITH CHECK (
    auth.uid() = user_id
    AND is_verified = (SELECT cp.is_verified FROM public.contributor_profiles cp WHERE cp.user_id = auth.uid())
    AND avg_rating = (SELECT cp.avg_rating FROM public.contributor_profiles cp WHERE cp.user_id = auth.uid())
    AND total_ratings = (SELECT cp.total_ratings FROM public.contributor_profiles cp WHERE cp.user_id = auth.uid())
    AND total_pois = (SELECT cp.total_pois FROM public.contributor_profiles cp WHERE cp.user_id = auth.uid())
  );

-- =============================================
-- 2c. Orphaned ratings constraint
-- =============================================

ALTER TABLE public.poi_ratings ADD CONSTRAINT chk_rating_owner
  CHECK (user_id IS NOT NULL OR device_id IS NOT NULL);

-- =============================================
-- 2d. Text length constraints
-- =============================================

ALTER TABLE public.poi_ratings ADD CONSTRAINT chk_device_id_len
  CHECK (length(device_id) <= 256);
ALTER TABLE public.poi_ratings ADD CONSTRAINT chk_lang_code_fmt
  CHECK (lang_code ~ '^[a-z]{2}$');

ALTER TABLE public.contributor_profiles ADD CONSTRAINT chk_display_name_len
  CHECK (length(display_name) <= 100);
ALTER TABLE public.contributor_profiles ADD CONSTRAINT chk_bio_len
  CHECK (bio IS NULL OR length(bio) <= 2000);
ALTER TABLE public.contributor_profiles ADD CONSTRAINT chk_avatar_url_len
  CHECK (avatar_url IS NULL OR length(avatar_url) <= 2048);
ALTER TABLE public.contributor_profiles ADD CONSTRAINT chk_website_url_len
  CHECK (website_url IS NULL OR length(website_url) <= 2048);

-- =============================================
-- 3a. Fix rating trigger — handle DELETE + use COALESCE for poi_id
-- =============================================

CREATE OR REPLACE FUNCTION public.update_poi_rating_stats()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
DECLARE
  v_poi_id UUID;
  v_avg    DECIMAL(3,2);
  v_count  INTEGER;
  v_contributor_id UUID;
BEGIN
  v_poi_id := COALESCE(NEW.poi_id, OLD.poi_id);

  SELECT ROUND(AVG(rating)::NUMERIC, 2), COUNT(*)
    INTO v_avg, v_count
    FROM public.poi_ratings WHERE poi_id = v_poi_id;

  UPDATE public.pois
    SET avg_rating = v_avg, total_ratings = COALESCE(v_count, 0)
    WHERE id = v_poi_id
    RETURNING contributor_id INTO v_contributor_id;

  IF v_contributor_id IS NOT NULL THEN
    UPDATE public.contributor_profiles SET
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

  RETURN COALESCE(NEW, OLD);
END;
$$;

DROP TRIGGER trg_update_poi_rating_stats ON public.poi_ratings;
CREATE TRIGGER trg_update_poi_rating_stats
  AFTER INSERT OR UPDATE OR DELETE ON public.poi_ratings
  FOR EACH ROW EXECUTE FUNCTION public.update_poi_rating_stats();

-- =============================================
-- 3b. Fix POI contributor change — decrement old contributor
-- =============================================

CREATE OR REPLACE FUNCTION public.update_contributor_poi_count()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
  -- Decrement old contributor on UPDATE
  IF TG_OP = 'UPDATE' AND OLD.contributor_id IS DISTINCT FROM NEW.contributor_id AND OLD.contributor_id IS NOT NULL THEN
    UPDATE public.contributor_profiles SET
      total_pois = (SELECT COUNT(*) FROM public.pois WHERE contributor_id = OLD.contributor_id AND is_active = TRUE),
      updated_at = NOW()
    WHERE user_id = OLD.contributor_id;
  END IF;

  IF NEW.contributor_id IS NOT NULL THEN
    UPDATE public.contributor_profiles SET
      total_pois = (SELECT COUNT(*) FROM public.pois WHERE contributor_id = NEW.contributor_id AND is_active = TRUE),
      updated_at = NOW()
    WHERE user_id = NEW.contributor_id;
  END IF;
  RETURN NEW;
END;
$$;

-- =============================================
-- 3c. Explicit GRANTs for poi_ratings and contributor_profiles
-- =============================================

GRANT SELECT, INSERT ON public.poi_ratings TO anon, authenticated;
GRANT UPDATE ON public.poi_ratings TO authenticated;
GRANT SELECT ON public.contributor_profiles TO anon, authenticated;
GRANT INSERT, UPDATE ON public.contributor_profiles TO authenticated;

-- =============================================
-- 4. Optimized contributor_rankings view (CTE, no correlated subqueries)
-- =============================================

CREATE OR REPLACE VIEW public.contributor_rankings AS
WITH poi_stats AS (
  SELECT poi_id, AVG(rating) AS avg_r, COUNT(*) AS cnt
  FROM public.poi_ratings GROUP BY poi_id
)
SELECT
  cp.id AS contributor_id, cp.user_id, cp.display_name, cp.avatar_url,
  cp.is_verified, cp.total_pois, cp.avg_rating, cp.total_ratings,
  c.id AS city_id, c.name AS city_name,
  COUNT(p.id) AS city_poi_count,
  ROUND(AVG(ps.avg_r)::NUMERIC, 2) AS city_avg_rating,
  COALESCE(SUM(ps.cnt), 0) AS city_total_ratings,
  CASE WHEN COALESCE(SUM(ps.cnt), 0) >= 10
    THEN ROUND((AVG(ps.avg_r) * LOG(SUM(ps.cnt) + 1))::NUMERIC, 4)
    ELSE NULL
  END AS hof_score,
  RANK() OVER (PARTITION BY c.id ORDER BY
    CASE WHEN COALESCE(SUM(ps.cnt), 0) >= 10
      THEN AVG(ps.avg_r) * LOG(SUM(ps.cnt) + 1) ELSE NULL
    END DESC NULLS LAST
  ) AS city_rank
FROM public.contributor_profiles cp
JOIN public.pois p ON p.contributor_id = cp.user_id AND p.is_active = TRUE
JOIN public.cities c ON c.id = p.city_id
LEFT JOIN poi_stats ps ON ps.poi_id = p.id
GROUP BY cp.id, cp.user_id, cp.display_name, cp.avatar_url,
         cp.is_verified, cp.total_pois, cp.avg_rating, cp.total_ratings,
         c.id, c.name;

-- Composite index for contributor+city lookups
CREATE INDEX IF NOT EXISTS idx_pois_contributor_city
  ON public.pois(contributor_id, city_id) WHERE is_active = TRUE;

-- =============================================
-- 2e. Cap p_limit in HoF RPC + fix sample_poi_names subquery
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
      SELECT jsonb_agg(sub.name) FROM (
        SELECT p.name FROM public.pois p
        WHERE p.contributor_id = cr.user_id
          AND p.city_id = p_city_id
          AND p.is_active = TRUE
        ORDER BY p.sort_order LIMIT 3
      ) sub
    ) AS sample_poi_names
  FROM public.contributor_rankings cr
  WHERE cr.city_id = p_city_id
    AND cr.hof_score IS NOT NULL
    AND cr.city_rank <= LEAST(p_limit, 100)
  ORDER BY cr.city_rank
  LIMIT LEAST(p_limit, 100);
$$;
