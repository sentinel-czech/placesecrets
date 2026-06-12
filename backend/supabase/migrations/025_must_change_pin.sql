-- ================================================================
-- MUST CHANGE PIN FLAG + DEFAULT PIN
-- D4-002: Forces PIN change on first login
-- ================================================================

ALTER TABLE admin_users
  ADD COLUMN IF NOT EXISTS must_change_pin BOOLEAN NOT NULL DEFAULT TRUE;

-- Existing admin users already have their own PINs — mark as changed
UPDATE admin_users SET must_change_pin = FALSE
  WHERE pin_hash IS NOT NULL AND pin_hash != '';
