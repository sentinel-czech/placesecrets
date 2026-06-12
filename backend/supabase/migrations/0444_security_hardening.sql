-- Migration 0444: security hardening (pre-release)
--
-- Applies after 0443. Idempotent.

-- 1. Restrict acl_permissions direct SELECT to authenticated users.
--    The previous policy used `USING (true)` with no role target, which exposed
--    the full role/permission matrix to the anon role (security-model
--    reconnaissance). Every functional read path bypasses RLS anyway:
--      * the admin panel writes/reads via the admin-api Edge Function (service_role)
--      * roles are resolved through the SECURITY DEFINER get_role_permissions() RPC
--    so restricting direct SELECT to authenticated does not affect the app.
DROP POLICY IF EXISTS acl_permissions_select ON public.acl_permissions;
CREATE POLICY acl_permissions_select ON public.acl_permissions
  FOR SELECT TO authenticated
  USING (true);

-- 2. Drop the dead, unused stripe_secret_key column from payment_config.
--    The Stripe secret is read exclusively from the STRIPE_SECRET_KEY environment
--    variable in every Edge Function (create-payment-intent, create-poi-checkout,
--    confirm-poi-payment, stripe-refund). This column is never read, and is already
--    in admin-api BLOCKED_COLUMNS so it cannot be selected or written via the API.
--    Removing it eliminates a latent "plaintext secret stored in DB" surface.
ALTER TABLE public.payment_config DROP COLUMN IF EXISTS stripe_secret_key;
