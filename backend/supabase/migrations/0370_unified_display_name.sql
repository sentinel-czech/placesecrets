-- Add handle column to user_profiles
ALTER TABLE user_profiles
  ADD COLUMN IF NOT EXISTS display_name TEXT UNIQUE;

ALTER TABLE user_profiles
  ADD CONSTRAINT chk_display_name_handle
  CHECK (display_name ~ '^[a-z0-9_]{3,50}$');

-- Migrate existing contributor display_names (convert to handle format)
-- Pass 1: clean conversion
UPDATE user_profiles up
SET display_name = sub.handle
FROM (
  SELECT cp.user_id,
    lower(regexp_replace(regexp_replace(cp.display_name, '[^a-zA-Z0-9_ ]', '', 'g'), '\s+', '_', 'g')) AS handle
  FROM contributor_profiles cp
) sub
WHERE up.user_id = sub.user_id
  AND up.display_name IS NULL
  AND sub.handle ~ '^[a-z0-9_]{3,50}$';

-- Pass 2: duplicates or non-matching get _userNumber suffix
UPDATE user_profiles up
SET display_name = sub.handle || '_' || up.user_number
FROM (
  SELECT cp.user_id,
    lower(regexp_replace(regexp_replace(cp.display_name, '[^a-zA-Z0-9_ ]', '', 'g'), '\s+', '_', 'g')) AS handle
  FROM contributor_profiles cp
) sub
WHERE up.user_id = sub.user_id
  AND up.display_name IS NULL
  AND length(sub.handle || '_' || up.user_number) BETWEEN 3 AND 50;

-- Index for fast lookups
CREATE INDEX IF NOT EXISTS idx_user_profiles_display_name ON user_profiles(display_name);

-- Handle availability check RPC (public, SECURITY INVOKER)
CREATE OR REPLACE FUNCTION check_handle_available(p_handle TEXT)
RETURNS BOOLEAN LANGUAGE sql STABLE SECURITY INVOKER SET search_path = public
AS $$ SELECT NOT EXISTS (SELECT 1 FROM user_profiles WHERE display_name = lower(p_handle)); $$;

GRANT EXECUTE ON FUNCTION check_handle_available TO anon, authenticated;

-- Recreate admin_users_view with display_name
DROP VIEW IF EXISTS admin_users_view;
CREATE VIEW admin_users_view AS
SELECT
  u.id, u.email, u.is_anonymous, u.created_at, u.last_sign_in_at, u.email_confirmed_at,
  COALESCE(ua.access_count, 0) AS access_count,
  COALESCE(ua.total_spent, 0) AS total_spent,
  COALESCE(up.status, 'active') AS status,
  COALESCE(up.language, 'en') AS language,
  up.user_number, up.backup_email, up.display_name
FROM auth.users u
LEFT JOIN (
  SELECT user_id, COUNT(*) AS access_count, COALESCE(SUM(amount_eur), 0) AS total_spent
  FROM user_access GROUP BY user_id
) ua ON ua.user_id = u.id
LEFT JOIN user_profiles up ON up.user_id = u.id;
