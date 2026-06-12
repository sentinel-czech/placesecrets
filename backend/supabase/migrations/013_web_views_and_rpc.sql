-- 013: Web portal views, RPCs, contributor RLS

-- View: effective role for any authenticated user
CREATE OR REPLACE VIEW public.web_user_roles AS
SELECT
  au.user_id,
  au.role AS effective_role
FROM public.admin_users au
UNION ALL
SELECT
  cp.user_id,
  'contributor'::TEXT AS effective_role
FROM public.contributor_profiles cp
WHERE cp.is_active = TRUE
  AND NOT EXISTS (SELECT 1 FROM public.admin_users a WHERE a.user_id = cp.user_id);

GRANT SELECT ON public.web_user_roles TO authenticated, service_role;

-- RPC: poi_types_stats
CREATE OR REPLACE FUNCTION public.poi_types_stats()
RETURNS TABLE(type_id UUID, type_name JSONB, slug TEXT, icon_name TEXT, color_hex TEXT, poi_count BIGINT)
LANGUAGE sql STABLE SECURITY DEFINER AS $$
  SELECT pt.id, pt.name, pt.slug, pt.icon_name, pt.color_hex,
    COUNT(p.id) FILTER (WHERE p.is_active = TRUE)
  FROM public.poi_types pt
  LEFT JOIN public.pois p ON p.type_id = pt.id
  WHERE pt.is_active = TRUE
  GROUP BY pt.id, pt.name, pt.slug, pt.icon_name, pt.color_hex, pt.sort_order
  ORDER BY pt.sort_order;
$$;

GRANT EXECUTE ON FUNCTION public.poi_types_stats TO service_role;

-- Update admin_stats to include contributor metrics
CREATE OR REPLACE VIEW public.admin_stats AS SELECT
  (SELECT COUNT(*) FROM auth.users WHERE is_anonymous = FALSE) AS registered_users,
  (SELECT COUNT(*) FROM auth.users WHERE is_anonymous = TRUE)  AS anonymous_users,
  (SELECT COUNT(*) FROM public.pois WHERE is_active = TRUE)    AS active_pois,
  (SELECT COUNT(*) FROM public.cities WHERE is_active = TRUE)  AS active_cities,
  (SELECT COUNT(*) FROM public.user_access)                    AS total_purchases,
  (SELECT COALESCE(SUM(amount_eur), 0) FROM public.payment_receipts WHERE status = 'completed') AS total_revenue_eur,
  (SELECT COUNT(*) FROM public.free_visit_log WHERE year_month = TO_CHAR(NOW(), 'YYYY-MM')) AS free_visits_this_month,
  (SELECT COUNT(*) FROM public.payment_receipts WHERE payment_method = 'revolut' AND status = 'pending') AS pending_revolut,
  (SELECT COUNT(*) FROM public.contributor_profiles WHERE is_active = TRUE) AS total_contributors,
  (SELECT COUNT(*) FROM public.contributor_profiles WHERE is_verified = TRUE) AS verified_contributors,
  (SELECT COUNT(*) FROM public.poi_ratings) AS total_poi_ratings,
  (SELECT ROUND(AVG(rating)::NUMERIC, 2) FROM public.poi_ratings) AS global_avg_rating;

GRANT SELECT ON public.admin_stats TO service_role;

-- RLS: contributors can insert their own POIs
CREATE POLICY "pois_contributor_insert" ON public.pois
  FOR INSERT WITH CHECK (
    auth.uid() = contributor_id
    AND EXISTS (
      SELECT 1 FROM public.contributor_profiles cp
      WHERE cp.user_id = auth.uid() AND cp.is_active = TRUE
    )
  );

-- RLS: contributors can update their own POIs
CREATE POLICY "pois_contributor_update" ON public.pois
  FOR UPDATE USING (
    auth.uid() = contributor_id
    AND EXISTS (
      SELECT 1 FROM public.contributor_profiles cp
      WHERE cp.user_id = auth.uid() AND cp.is_active = TRUE
    )
  );

-- RLS: contributors can read their own POIs (including inactive)
CREATE POLICY "pois_contributor_read_own" ON public.pois
  FOR SELECT USING (auth.uid() = contributor_id);

-- contributor_own_insert already exists from migration 009

-- Service role full access on contributor_profiles
CREATE POLICY "contributor_service_all" ON public.contributor_profiles
  FOR ALL USING (auth.role() = 'service_role');
