-- Migration 019: user_profiles table for language & status
CREATE TABLE IF NOT EXISTS user_profiles (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID UNIQUE NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  language TEXT NOT NULL DEFAULT 'en',
  status TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'deactivated')),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- RLS
ALTER TABLE user_profiles ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can read own profile"
  ON user_profiles FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own profile"
  ON user_profiles FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own profile"
  ON user_profiles FOR UPDATE
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Service role full access on user_profiles"
  ON user_profiles FOR ALL
  USING (auth.role() = 'service_role');

-- Index
CREATE INDEX idx_user_profiles_user_id ON user_profiles(user_id);

-- Update admin_users_view to include status & language
CREATE OR REPLACE VIEW admin_users_view AS
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
