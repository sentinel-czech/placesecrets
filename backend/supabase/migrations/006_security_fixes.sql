-- Security fixes: RLS hardening, missing indexes, FK cascade

-- 1. Fix payment_config RLS: drop overly permissive read, restrict to service_role
DROP POLICY IF EXISTS "payment_config_authenticated_read" ON public.payment_config;

CREATE POLICY "payment_config_service_read" ON public.payment_config
  FOR SELECT USING (auth.role() = 'service_role');

-- RPC to expose only public payment fields to authenticated users
CREATE OR REPLACE FUNCTION public.get_publishable_payment_config()
RETURNS TABLE (
  operator_name TEXT,
  revolut_username TEXT,
  stripe_publishable_key TEXT,
  google_pay_merchant_id TEXT,
  apple_pay_merchant_id TEXT
)
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT
    operator_name,
    revolut_username,
    stripe_publishable_key,
    google_pay_merchant_id,
    apple_pay_merchant_id
  FROM public.payment_config
  LIMIT 1;
$$;

GRANT EXECUTE ON FUNCTION public.get_publishable_payment_config() TO authenticated;

-- 2. Restrict UPDATE/DELETE on user_access to service_role only
CREATE POLICY "user_access_service_update" ON public.user_access
  FOR UPDATE USING (auth.role() = 'service_role');

CREATE POLICY "user_access_service_delete" ON public.user_access
  FOR DELETE USING (auth.role() = 'service_role');

-- 3. Add missing indexes
CREATE INDEX IF NOT EXISTS idx_user_access_city_id ON public.user_access(city_id);
CREATE INDEX IF NOT EXISTS idx_receipts_city_id ON public.payment_receipts(city_id);

-- 4. Add ON DELETE CASCADE to payment_receipts.city_id
ALTER TABLE public.payment_receipts
  DROP CONSTRAINT IF EXISTS payment_receipts_city_id_fkey,
  ADD CONSTRAINT payment_receipts_city_id_fkey
    FOREIGN KEY (city_id) REFERENCES public.cities(id) ON DELETE CASCADE;
