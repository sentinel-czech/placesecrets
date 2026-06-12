-- ================================================================
-- ACL PERMISSIONS TABLE
-- D4-001: Role-based access control permissions
-- ================================================================

CREATE TABLE IF NOT EXISTS acl_permissions (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  role        TEXT NOT NULL CHECK (role IN ('superadmin', 'editor', 'viewer', 'contributor', 'user')),
  resource    TEXT NOT NULL CHECK (resource IN (
    'cities', 'pois', 'own_pois', 'poi_types', 'users', 'payments',
    'settings', 'acl', 'hall_of_fame', 'contributors', 'own_profile',
    'audio', 'dashboard'
  )),
  can_read    BOOLEAN NOT NULL DEFAULT FALSE,
  can_write   BOOLEAN NOT NULL DEFAULT FALSE,
  can_delete  BOOLEAN NOT NULL DEFAULT FALSE,
  created_at  TIMESTAMPTZ DEFAULT NOW(),
  updated_at  TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(role, resource)
);

-- updated_at trigger
CREATE TRIGGER acl_permissions_updated_at
  BEFORE UPDATE ON acl_permissions
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- RLS
ALTER TABLE acl_permissions ENABLE ROW LEVEL SECURITY;

CREATE POLICY acl_permissions_select ON acl_permissions
  FOR SELECT USING (true);

CREATE POLICY acl_permissions_modify ON acl_permissions
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM admin_users
      WHERE user_id = auth.uid() AND role = 'superadmin'
    )
  );

-- Index
CREATE INDEX idx_acl_permissions_role ON acl_permissions(role);

-- Seed: superadmin — full access everywhere
INSERT INTO acl_permissions (role, resource, can_read, can_write, can_delete) VALUES
  ('superadmin', 'cities',       TRUE, TRUE, TRUE),
  ('superadmin', 'pois',         TRUE, TRUE, TRUE),
  ('superadmin', 'own_pois',     TRUE, TRUE, TRUE),
  ('superadmin', 'poi_types',    TRUE, TRUE, TRUE),
  ('superadmin', 'users',        TRUE, TRUE, TRUE),
  ('superadmin', 'payments',     TRUE, TRUE, TRUE),
  ('superadmin', 'settings',     TRUE, TRUE, FALSE),
  ('superadmin', 'acl',          TRUE, TRUE, FALSE),
  ('superadmin', 'hall_of_fame', TRUE, FALSE, FALSE),
  ('superadmin', 'contributors', TRUE, TRUE, TRUE),
  ('superadmin', 'own_profile',  TRUE, TRUE, FALSE),
  ('superadmin', 'audio',        TRUE, TRUE, TRUE),
  ('superadmin', 'dashboard',    TRUE, FALSE, FALSE)
ON CONFLICT (role, resource) DO NOTHING;

-- Seed: editor — can edit all POIs + audio, but NOT users/payments/settings/ACL/contributors
INSERT INTO acl_permissions (role, resource, can_read, can_write, can_delete) VALUES
  ('editor', 'cities',       TRUE, FALSE, FALSE),
  ('editor', 'pois',         TRUE, TRUE, FALSE),
  ('editor', 'own_pois',     TRUE, TRUE, TRUE),
  ('editor', 'poi_types',    TRUE, FALSE, FALSE),
  ('editor', 'users',        FALSE, FALSE, FALSE),
  ('editor', 'payments',     FALSE, FALSE, FALSE),
  ('editor', 'settings',     FALSE, FALSE, FALSE),
  ('editor', 'acl',          FALSE, FALSE, FALSE),
  ('editor', 'hall_of_fame', TRUE, FALSE, FALSE),
  ('editor', 'contributors', FALSE, FALSE, FALSE),
  ('editor', 'own_profile',  TRUE, TRUE, FALSE),
  ('editor', 'audio',        TRUE, TRUE, FALSE),
  ('editor', 'dashboard',    TRUE, FALSE, FALSE)
ON CONFLICT (role, resource) DO NOTHING;

-- Seed: viewer — anonymous browsing: can read public content, NO audio, NO own_profile
INSERT INTO acl_permissions (role, resource, can_read, can_write, can_delete) VALUES
  ('viewer', 'cities',       TRUE, FALSE, FALSE),
  ('viewer', 'pois',         TRUE, FALSE, FALSE),
  ('viewer', 'own_pois',     FALSE, FALSE, FALSE),
  ('viewer', 'poi_types',    TRUE, FALSE, FALSE),
  ('viewer', 'users',        FALSE, FALSE, FALSE),
  ('viewer', 'payments',     FALSE, FALSE, FALSE),
  ('viewer', 'settings',     FALSE, FALSE, FALSE),
  ('viewer', 'acl',          FALSE, FALSE, FALSE),
  ('viewer', 'hall_of_fame', TRUE, FALSE, FALSE),
  ('viewer', 'contributors', FALSE, FALSE, FALSE),
  ('viewer', 'own_profile',  FALSE, FALSE, FALSE),
  ('viewer', 'audio',        FALSE, FALSE, FALSE),
  ('viewer', 'dashboard',    TRUE, FALSE, FALSE)
ON CONFLICT (role, resource) DO NOTHING;

-- Seed: contributor
INSERT INTO acl_permissions (role, resource, can_read, can_write, can_delete) VALUES
  ('contributor', 'cities',       TRUE, FALSE, FALSE),
  ('contributor', 'pois',         FALSE, FALSE, FALSE),
  ('contributor', 'own_pois',     TRUE, TRUE, FALSE),
  ('contributor', 'poi_types',    TRUE, FALSE, FALSE),
  ('contributor', 'users',        FALSE, FALSE, FALSE),
  ('contributor', 'payments',     FALSE, FALSE, FALSE),
  ('contributor', 'settings',     FALSE, FALSE, FALSE),
  ('contributor', 'acl',          FALSE, FALSE, FALSE),
  ('contributor', 'hall_of_fame', TRUE, FALSE, FALSE),
  ('contributor', 'contributors', FALSE, FALSE, FALSE),
  ('contributor', 'own_profile',  TRUE, TRUE, FALSE),
  ('contributor', 'audio',        TRUE, TRUE, FALSE),
  ('contributor', 'dashboard',    TRUE, FALSE, FALSE)
ON CONFLICT (role, resource) DO NOTHING;

-- Seed: user — logged in, can read content + audio (R only), own_profile R/W
INSERT INTO acl_permissions (role, resource, can_read, can_write, can_delete) VALUES
  ('user', 'cities',       TRUE, FALSE, FALSE),
  ('user', 'pois',         TRUE, FALSE, FALSE),
  ('user', 'own_pois',     FALSE, FALSE, FALSE),
  ('user', 'poi_types',    TRUE, FALSE, FALSE),
  ('user', 'users',        FALSE, FALSE, FALSE),
  ('user', 'payments',     FALSE, FALSE, FALSE),
  ('user', 'settings',     FALSE, FALSE, FALSE),
  ('user', 'acl',          FALSE, FALSE, FALSE),
  ('user', 'hall_of_fame', TRUE, FALSE, FALSE),
  ('user', 'contributors', FALSE, FALSE, FALSE),
  ('user', 'own_profile',  TRUE, TRUE, FALSE),
  ('user', 'audio',        TRUE, FALSE, FALSE),
  ('user', 'dashboard',    TRUE, FALSE, FALSE)
ON CONFLICT (role, resource) DO NOTHING;
