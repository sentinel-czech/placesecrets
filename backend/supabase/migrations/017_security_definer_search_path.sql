-- Migration 017: Fix SET search_path on all SECURITY DEFINER functions + atomic PIN increment

-- 1. Fix search_path on existing functions from migration 005
CREATE OR REPLACE FUNCTION public.revenue_by_month(months_back INTEGER DEFAULT 12)
RETURNS TABLE(month TEXT, revenue DECIMAL, count BIGINT)
LANGUAGE sql SECURITY DEFINER
SET search_path = public
AS $$
  SELECT TO_CHAR(purchased_at, 'YYYY-MM') AS month,
    COALESCE(SUM(amount_eur), 0) AS revenue, COUNT(*) AS count
  FROM public.payment_receipts
  WHERE status = 'completed'
    AND purchased_at >= NOW() - (months_back || ' months')::INTERVAL
  GROUP BY 1 ORDER BY 1;
$$;

CREATE OR REPLACE FUNCTION public.daily_activity(days_back INTEGER DEFAULT 30)
RETURNS TABLE(day TEXT, visits BIGINT, new_users BIGINT)
LANGUAGE sql SECURITY DEFINER
SET search_path = public
AS $$
  SELECT d::TEXT AS day,
    COALESCE((SELECT COUNT(*) FROM public.free_visit_log WHERE visited_at::DATE = d), 0) AS visits,
    COALESCE((SELECT COUNT(*) FROM auth.users WHERE created_at::DATE = d), 0) AS new_users
  FROM generate_series(
    CURRENT_DATE - (days_back || ' days')::INTERVAL,
    CURRENT_DATE, '1 day'
  ) AS d;
$$;

CREATE OR REPLACE FUNCTION public.payment_summary(
  p_status TEXT DEFAULT NULL, p_method TEXT DEFAULT NULL,
  p_from TEXT DEFAULT NULL, p_to TEXT DEFAULT NULL
)
RETURNS TABLE(total_eur DECIMAL, count BIGINT, pending_revolut BIGINT)
LANGUAGE sql SECURITY DEFINER
SET search_path = public
AS $$
  SELECT COALESCE(SUM(amount_eur),0), COUNT(*),
    COUNT(*) FILTER (WHERE payment_method='revolut' AND status='pending')
  FROM public.payment_receipts
  WHERE (p_status IS NULL OR status=p_status)
    AND (p_method IS NULL OR payment_method=p_method)
    AND (p_from IS NULL OR purchased_at >= p_from::TIMESTAMPTZ)
    AND (p_to IS NULL OR purchased_at <= (p_to||'T23:59:59Z')::TIMESTAMPTZ);
$$;

-- 2. Fix search_path on poi_types_stats from migration 013
CREATE OR REPLACE FUNCTION public.poi_types_stats()
RETURNS TABLE(type_id UUID, type_name JSONB, slug TEXT, icon_name TEXT, color_hex TEXT, poi_count BIGINT)
LANGUAGE sql SECURITY DEFINER
SET search_path = public
AS $$
  SELECT t.id AS type_id, t.name AS type_name, t.slug, t.icon_name, t.color_hex, COUNT(p.id) AS poi_count
  FROM public.poi_types t
  LEFT JOIN public.pois p ON p.type_id = t.id AND p.is_active = TRUE
  WHERE t.is_active = TRUE
  GROUP BY t.id, t.name, t.slug, t.icon_name, t.color_hex
  ORDER BY t.sort_order;
$$;

-- 3. Fix search_path on poi_hall_of_fame (keep same signature as 010)
CREATE OR REPLACE FUNCTION public.poi_hall_of_fame(
  p_city_id UUID, p_limit INTEGER DEFAULT 10
)
RETURNS TABLE(
  rank BIGINT, contributor_id UUID, display_name TEXT, avatar_url TEXT,
  is_verified BOOLEAN, city_poi_count BIGINT, city_avg_rating DECIMAL,
  city_total_ratings BIGINT, hof_score DECIMAL, sample_poi_names JSONB
)
LANGUAGE sql STABLE SECURITY DEFINER
SET search_path = public
AS $$
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

-- 4. Atomic PIN attempt increment (prevents race condition)
CREATE OR REPLACE FUNCTION public.increment_pin_attempts(p_admin_id UUID)
RETURNS TABLE(new_attempts INTEGER, is_locked BOOLEAN)
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public
AS $fn$
DECLARE
  v_attempts INTEGER;
BEGIN
  UPDATE public.admin_users
  SET pin_attempts = COALESCE(pin_attempts, 0) + 1,
      pin_locked_until = CASE
        WHEN COALESCE(pin_attempts, 0) + 1 >= 5
        THEN NOW() + INTERVAL '15 minutes'
        ELSE pin_locked_until
      END
  WHERE id = p_admin_id
  RETURNING pin_attempts INTO v_attempts;

  RETURN QUERY SELECT v_attempts, (v_attempts >= 5);
END;
$fn$;

-- 5. Reset PIN attempts on successful login
CREATE OR REPLACE FUNCTION public.reset_pin_attempts(p_admin_id UUID)
RETURNS VOID
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public
AS $fn$
BEGIN
  UPDATE public.admin_users
  SET pin_attempts = 0, pin_locked_until = NULL
  WHERE id = p_admin_id;
END;
$fn$;

GRANT EXECUTE ON FUNCTION public.increment_pin_attempts TO service_role;
GRANT EXECUTE ON FUNCTION public.reset_pin_attempts TO service_role;
