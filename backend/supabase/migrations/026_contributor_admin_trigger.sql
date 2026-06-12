-- ================================================================
-- AUTO-CREATE admin_users ROW FOR NEW CONTRIBUTORS
-- D4-003: Trigger on contributor_profiles INSERT
-- ================================================================

CREATE OR REPLACE FUNCTION create_admin_user_for_contributor()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions
AS $$
DECLARE
  default_pin_hash TEXT;
  contributor_email TEXT;
BEGIN
  -- Get email from auth.users
  SELECT email INTO contributor_email
  FROM auth.users WHERE id = NEW.user_id;

  -- Bcrypt hash of '123456' (cost factor 10)
  default_pin_hash := crypt('123456', gen_salt('bf', 10));

  INSERT INTO admin_users (user_id, role, pin_hash, must_change_pin)
  VALUES (
    NEW.user_id,
    'contributor',
    default_pin_hash,
    TRUE
  )
  ON CONFLICT (user_id) DO NOTHING;

  RETURN NEW;
END;
$$;

CREATE TRIGGER contributor_auto_admin_user
  AFTER INSERT ON contributor_profiles
  FOR EACH ROW EXECUTE FUNCTION create_admin_user_for_contributor();

-- Backfill: create admin_users rows for existing contributors without one
INSERT INTO admin_users (user_id, role, pin_hash, must_change_pin)
SELECT
  cp.user_id,
  'contributor',
  crypt('123456', gen_salt('bf', 10)),
  TRUE
FROM contributor_profiles cp
WHERE NOT EXISTS (
  SELECT 1 FROM admin_users adm WHERE adm.user_id = cp.user_id
)
ON CONFLICT (user_id) DO NOTHING;
