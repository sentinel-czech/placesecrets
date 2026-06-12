-- Migration 022: Add user_number (stable sequential ID) and backup_email to user_profiles

-- Sequence starting at 100000 for human-readable 6-digit numbers
CREATE SEQUENCE IF NOT EXISTS user_number_seq START WITH 100000;

-- Add columns
ALTER TABLE user_profiles
  ADD COLUMN IF NOT EXISTS user_number BIGINT UNIQUE NOT NULL DEFAULT nextval('user_number_seq');

ALTER TABLE user_profiles
  ADD COLUMN IF NOT EXISTS backup_email TEXT DEFAULT NULL;

-- Index on user_number for fast lookups
CREATE INDEX IF NOT EXISTS idx_user_profiles_user_number ON user_profiles (user_number);

-- Backfill: create user_profiles rows for registered users who don't have one yet
INSERT INTO user_profiles (user_id)
SELECT u.id
FROM auth.users u
LEFT JOIN user_profiles up ON up.user_id = u.id
WHERE up.id IS NULL
  AND u.is_anonymous = false
ON CONFLICT (user_id) DO NOTHING;

-- Recreate admin_users_view to include user_number and backup_email
DROP VIEW IF EXISTS admin_users_view;

CREATE VIEW admin_users_view AS
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
  COALESCE(up.language, 'en') AS language,
  up.user_number,
  up.backup_email
FROM auth.users u
LEFT JOIN (
  SELECT user_id, COUNT(*) AS access_count, COALESCE(SUM(amount_eur), 0) AS total_spent
  FROM user_access
  GROUP BY user_id
) ua ON ua.user_id = u.id
LEFT JOIN user_profiles up ON up.user_id = u.id;
