-- ================================================================
-- ACL RPCs
-- D4-004: get_role_permissions, get_all_permissions
-- ================================================================

CREATE OR REPLACE FUNCTION get_role_permissions(target_role TEXT)
RETURNS TABLE (
  resource TEXT,
  can_read BOOLEAN,
  can_write BOOLEAN,
  can_delete BOOLEAN
)
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
STABLE
AS $$
  SELECT resource, can_read, can_write, can_delete
  FROM acl_permissions
  WHERE role = target_role
  ORDER BY resource;
$$;

CREATE OR REPLACE FUNCTION get_all_permissions()
RETURNS TABLE (
  id UUID,
  role TEXT,
  resource TEXT,
  can_read BOOLEAN,
  can_write BOOLEAN,
  can_delete BOOLEAN
)
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
STABLE
AS $$
  SELECT id, role, resource, can_read, can_write, can_delete
  FROM acl_permissions
  ORDER BY role, resource;
$$;
