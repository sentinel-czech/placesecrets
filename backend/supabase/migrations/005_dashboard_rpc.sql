-- Dashboard views and RPCs for admin panel

CREATE OR REPLACE FUNCTION public.revenue_by_month(months_back INTEGER DEFAULT 12)
RETURNS TABLE(month TEXT, revenue DECIMAL, count BIGINT)
LANGUAGE sql SECURITY DEFINER AS $$
  SELECT TO_CHAR(purchased_at, 'YYYY-MM') AS month,
    COALESCE(SUM(amount_eur), 0) AS revenue, COUNT(*) AS count
  FROM public.payment_receipts
  WHERE status = 'completed'
    AND purchased_at >= NOW() - (months_back || ' months')::INTERVAL
  GROUP BY 1 ORDER BY 1;
$$;

CREATE OR REPLACE FUNCTION public.daily_activity(days_back INTEGER DEFAULT 30)
RETURNS TABLE(day TEXT, visits BIGINT, new_users BIGINT)
LANGUAGE sql SECURITY DEFINER AS $$
  SELECT TO_CHAR(d.d, 'YYYY-MM-DD'), COALESCE(v.cnt,0), COALESCE(u.cnt,0)
  FROM generate_series(CURRENT_DATE - (days_back || ' days')::INTERVAL, CURRENT_DATE, '1 day'::INTERVAL) d(d)
  LEFT JOIN (SELECT DATE(visited_at) AS d, COUNT(*) AS cnt FROM public.free_visit_log GROUP BY 1) v ON v.d = d.d
  LEFT JOIN (SELECT DATE(created_at) AS d, COUNT(*) AS cnt FROM auth.users WHERE is_anonymous = FALSE GROUP BY 1) u ON u.d = d.d
  ORDER BY d.d;
$$;

CREATE OR REPLACE FUNCTION public.top_visited_pois(limit_count INTEGER DEFAULT 10)
RETURNS TABLE(poi_id UUID, poi_name JSONB, city_name TEXT, visit_count BIGINT)
LANGUAGE sql SECURITY DEFINER AS $$
  SELECT p.id, p.name, c.name, COUNT(fvl.id)
  FROM public.pois p JOIN public.cities c ON c.id=p.city_id
  LEFT JOIN public.free_visit_log fvl ON fvl.poi_id=p.id
  WHERE p.is_active=TRUE GROUP BY p.id, p.name, c.name
  ORDER BY 4 DESC LIMIT limit_count;
$$;

CREATE OR REPLACE FUNCTION public.payment_summary(
  p_status TEXT DEFAULT NULL, p_method TEXT DEFAULT NULL,
  p_from TEXT DEFAULT NULL, p_to TEXT DEFAULT NULL
)
RETURNS TABLE(total_eur DECIMAL, count BIGINT, pending_revolut BIGINT)
LANGUAGE sql SECURITY DEFINER AS $$
  SELECT COALESCE(SUM(amount_eur),0), COUNT(*),
    COUNT(*) FILTER (WHERE payment_method='revolut' AND status='pending')
  FROM public.payment_receipts
  WHERE (p_status IS NULL OR status=p_status)
    AND (p_method IS NULL OR payment_method=p_method)
    AND (p_from IS NULL OR purchased_at >= p_from::TIMESTAMPTZ)
    AND (p_to IS NULL OR purchased_at <= (p_to||'T23:59:59Z')::TIMESTAMPTZ);
$$;

CREATE OR REPLACE VIEW public.admin_stats AS SELECT
  (SELECT COUNT(*) FROM auth.users WHERE is_anonymous=FALSE) AS registered_users,
  (SELECT COUNT(*) FROM auth.users WHERE is_anonymous=TRUE)  AS anonymous_users,
  (SELECT COUNT(*) FROM public.pois WHERE is_active=TRUE)    AS active_pois,
  (SELECT COUNT(*) FROM public.cities WHERE is_active=TRUE)  AS active_cities,
  (SELECT COUNT(*) FROM public.user_access)                  AS total_purchases,
  (SELECT COALESCE(SUM(amount_eur),0) FROM public.payment_receipts WHERE status='completed') AS total_revenue_eur,
  (SELECT COUNT(*) FROM public.free_visit_log WHERE year_month=TO_CHAR(NOW(),'YYYY-MM')) AS free_visits_this_month,
  (SELECT COUNT(*) FROM public.payment_receipts WHERE payment_method='revolut' AND status='pending') AS pending_revolut;

CREATE OR REPLACE VIEW public.admin_users_view AS
SELECT u.id, u.email, u.is_anonymous, u.created_at, u.last_sign_in_at, u.email_confirmed_at,
  COUNT(DISTINCT ua.id) AS access_count,
  COALESCE(SUM(pr.amount_eur) FILTER (WHERE pr.status='completed'), 0) AS total_spent
FROM auth.users u
LEFT JOIN public.user_access ua ON ua.user_id=u.id
LEFT JOIN public.payment_receipts pr ON pr.user_id=u.id
GROUP BY u.id, u.email, u.is_anonymous, u.created_at, u.last_sign_in_at, u.email_confirmed_at;

GRANT EXECUTE ON FUNCTION public.revenue_by_month TO service_role;
GRANT EXECUTE ON FUNCTION public.daily_activity TO service_role;
GRANT EXECUTE ON FUNCTION public.top_visited_pois TO service_role;
GRANT EXECUTE ON FUNCTION public.payment_summary TO service_role;
GRANT SELECT ON public.admin_stats TO service_role;
GRANT SELECT ON public.admin_users_view TO service_role;
