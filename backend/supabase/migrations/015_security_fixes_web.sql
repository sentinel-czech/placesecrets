-- 015: Security fixes for web portal

-- 1. PIN brute-force protection columns
ALTER TABLE public.admin_users
  ADD COLUMN IF NOT EXISTS pin_attempts INT DEFAULT 0,
  ADD COLUMN IF NOT EXISTS pin_locked_until TIMESTAMPTZ;

-- 2. Fix web_user_roles view: use UNION instead of UNION ALL to prevent duplicate roles
CREATE OR REPLACE VIEW public.web_user_roles AS
SELECT
  au.user_id,
  au.role AS effective_role
FROM public.admin_users au
UNION
SELECT
  cp.user_id,
  'contributor'::TEXT AS effective_role
FROM public.contributor_profiles cp
WHERE cp.is_active = TRUE
  AND NOT EXISTS (SELECT 1 FROM public.admin_users a WHERE a.user_id = cp.user_id);

GRANT SELECT ON public.web_user_roles TO authenticated, service_role;

-- 3. Add WITH CHECK to contributor update policy
DROP POLICY IF EXISTS "pois_contributor_update" ON public.pois;
CREATE POLICY "pois_contributor_update" ON public.pois
  FOR UPDATE
  USING (
    auth.uid() = contributor_id
    AND EXISTS (
      SELECT 1 FROM public.contributor_profiles cp
      WHERE cp.user_id = auth.uid() AND cp.is_active = TRUE
    )
  )
  WITH CHECK (
    auth.uid() = contributor_id
    AND EXISTS (
      SELECT 1 FROM public.contributor_profiles cp
      WHERE cp.user_id = auth.uid() AND cp.is_active = TRUE
    )
  );

-- 4. Audit log table
CREATE TABLE IF NOT EXISTS public.audit_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  actor_id UUID REFERENCES auth.users(id),
  action TEXT NOT NULL,
  target_type TEXT,
  target_id TEXT,
  metadata JSONB DEFAULT '{}',
  ip_address INET,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE public.audit_logs ENABLE ROW LEVEL SECURITY;

-- Only service_role can write audit logs
CREATE POLICY "audit_service_insert" ON public.audit_logs
  FOR INSERT WITH CHECK (auth.role() = 'service_role');

-- Admins can read audit logs
CREATE POLICY "audit_admin_read" ON public.audit_logs
  FOR SELECT USING (
    EXISTS (SELECT 1 FROM public.admin_users WHERE user_id = auth.uid())
  );

GRANT SELECT, INSERT ON public.audit_logs TO service_role;
GRANT SELECT ON public.audit_logs TO authenticated;

-- 5. Allow authenticated users to read web_user_roles for their own row
-- (already granted above, but ensure RLS allows it)
-- The view itself uses underlying table RLS, so we need to ensure
-- the view is accessible. It's a SECURITY INVOKER view by default.

-- 6. Grant authenticated users access to read admin_stats (read-only)
GRANT SELECT ON public.admin_stats TO authenticated;

-- 7. Grant poi_types_stats RPC to authenticated
GRANT EXECUTE ON FUNCTION public.poi_types_stats TO authenticated;
