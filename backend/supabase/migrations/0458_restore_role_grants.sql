-- Migration 0458: restore standard Supabase role grants on schema public.
--
-- Migrations run as `postgres`. In this environment the default privileges for
-- postgres-owned tables in `public` grant the API roles (anon, authenticated,
-- service_role) only TRUNCATE/REFERENCES/TRIGGER — NOT SELECT/INSERT/UPDATE/DELETE.
-- As a result every Edge Function (service_role) and every RLS-governed client
-- query fails with `permission denied for table ...`, e.g. admin login via
-- verify-admin-pin returns 403 "Not an admin user".
--
-- The project was written against the standard Supabase grant model: all three
-- API roles hold table DML and row access is governed by RLS (service_role
-- bypasses RLS). Evidence: migration 0453 REVOKEs INSERT on poi_ratings FROM anon,
-- which is only meaningful if anon was granted INSERT in the first place.
--
-- This migration restores those grants for existing objects and as defaults for
-- future ones, then re-applies the one intentional exception (0453). Idempotent.

GRANT USAGE ON SCHEMA public TO anon, authenticated, service_role;

-- Existing objects
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public
  TO anon, authenticated, service_role;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public
  TO anon, authenticated, service_role;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public
  TO anon, authenticated, service_role;

-- Future objects created by postgres in this schema
ALTER DEFAULT PRIVILEGES IN SCHEMA public
  GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO anon, authenticated, service_role;
ALTER DEFAULT PRIVILEGES IN SCHEMA public
  GRANT USAGE, SELECT ON SEQUENCES TO anon, authenticated, service_role;
ALTER DEFAULT PRIVILEGES IN SCHEMA public
  GRANT EXECUTE ON FUNCTIONS TO anon, authenticated, service_role;

-- Re-apply the intentional exception from migration 0453: ratings are login-only.
REVOKE INSERT ON public.poi_ratings FROM anon;
