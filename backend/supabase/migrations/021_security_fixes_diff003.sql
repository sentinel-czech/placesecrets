-- Migration 021: Security fixes for DIFF-003

-- C2: GRANT EXECUTE on poi_hall_of_fame_overall RPC
GRANT EXECUTE ON FUNCTION public.poi_hall_of_fame_overall TO anon, authenticated;

-- H1: Prevent users from deleting their own profile row
CREATE POLICY "Users cannot delete own profile"
  ON user_profiles FOR DELETE
  USING (FALSE);

-- M2: Auto-update updated_at on user_profiles
CREATE OR REPLACE FUNCTION public.update_user_profiles_updated_at()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$;

CREATE TRIGGER trg_user_profiles_updated_at
  BEFORE UPDATE ON user_profiles
  FOR EACH ROW
  EXECUTE FUNCTION update_user_profiles_updated_at();

-- M1: Recreate admin_users_view with explicit public. prefix
CREATE OR REPLACE VIEW public.admin_users_view AS
SELECT
  u.id,
  u.email,
  u.is_anonymous,
  u.created_at,
  u.last_sign_in_at,
  u.email_confirmed_at,
  COALESCE(ua.access_count, 0) AS access_count,
  COALESCE(ua.total_spent, 0) AS total_spent,
  COALESCE(up.status, 'active') AS status,
  COALESCE(up.language, 'en') AS language
FROM auth.users u
LEFT JOIN (
  SELECT user_id, COUNT(*) AS access_count, COALESCE(SUM(amount_eur), 0) AS total_spent
  FROM user_access
  GROUP BY user_id
) ua ON ua.user_id = u.id
LEFT JOIN user_profiles up ON up.user_id = u.id;
