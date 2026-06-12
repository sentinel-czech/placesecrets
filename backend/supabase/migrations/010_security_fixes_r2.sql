-- 010: Security fixes round 2
-- Fixes from post-fix verification audit

-- =============================================
-- Fix 1: Add SET search_path to SECURITY DEFINER function
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
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS $$
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

-- =============================================
-- Fix 5: DELETE policy on poi_ratings
-- =============================================

CREATE POLICY "ratings_own_delete" ON public.poi_ratings
  FOR DELETE USING (auth.uid() = user_id);

GRANT DELETE ON public.poi_ratings TO authenticated;

-- =============================================
-- Fix 6: Limit specializations array length
-- =============================================

ALTER TABLE public.contributor_profiles ADD CONSTRAINT chk_specializations_len
  CHECK (array_length(specializations, 1) IS NULL OR array_length(specializations, 1) <= 20);

-- =============================================
-- Fix 10: Replace heavy WITH CHECK policy with trigger
-- =============================================

DROP POLICY "contributor_own_update" ON public.contributor_profiles;

CREATE POLICY "contributor_own_update" ON public.contributor_profiles
  FOR UPDATE USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

CREATE OR REPLACE FUNCTION public.protect_contributor_fields()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
  NEW.is_verified := OLD.is_verified;
  NEW.avg_rating := OLD.avg_rating;
  NEW.total_ratings := OLD.total_ratings;
  NEW.total_pois := OLD.total_pois;
  RETURN NEW;
END;
$$;

CREATE TRIGGER trg_protect_contributor_fields
  BEFORE UPDATE ON public.contributor_profiles
  FOR EACH ROW
  WHEN (current_setting('role') != 'service_role')
  EXECUTE FUNCTION public.protect_contributor_fields();

-- =============================================
-- Fix 11: Add WITH CHECK to ratings_own_update
-- =============================================

DROP POLICY "ratings_own_update" ON public.poi_ratings;
CREATE POLICY "ratings_own_update" ON public.poi_ratings
  FOR UPDATE USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);
