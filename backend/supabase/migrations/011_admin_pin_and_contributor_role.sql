-- 011: Add PIN auth for admin users + contributor role

ALTER TABLE public.admin_users
  ADD COLUMN pin_hash   TEXT,
  ADD COLUMN pin_set_at TIMESTAMPTZ;

-- Expand role CHECK to include 'contributor'
ALTER TABLE public.admin_users
  DROP CONSTRAINT admin_users_role_check;

ALTER TABLE public.admin_users
  ADD CONSTRAINT admin_users_role_check
    CHECK (role IN ('superadmin', 'editor', 'viewer', 'contributor'));
