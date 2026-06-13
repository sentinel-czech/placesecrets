-- Migration 0452: Comgate payment gateway scaffolding.
-- Applies after 0451. Idempotent. Real credentials are supplied later via env
-- secrets (COMGATE_MERCHANT / COMGATE_SECRET); comgate_merchant may also be stored
-- here for display. comgate_secret is a blocked column (never exposed via admin-api).

ALTER TABLE public.payment_config
  ADD COLUMN IF NOT EXISTS comgate_merchant  TEXT,
  ADD COLUMN IF NOT EXISTS comgate_secret    TEXT,
  ADD COLUMN IF NOT EXISTS country_price_eur NUMERIC(10,2);

-- Allow 'comgate' as a payment_method on the entitlement / receipt tables.
DO $$
DECLARE r RECORD;
BEGIN
  FOR r IN
    SELECT conname, conrelid::regclass AS tbl
    FROM pg_constraint
    WHERE contype = 'c'
      AND conrelid IN ('public.user_access'::regclass, 'public.payment_receipts'::regclass)
      AND pg_get_constraintdef(oid) LIKE '%payment_method%'
  LOOP
    EXECUTE format('ALTER TABLE %s DROP CONSTRAINT %I', r.tbl, r.conname);
  END LOOP;
END $$;

ALTER TABLE public.user_access
  ADD CONSTRAINT user_access_payment_method_check
  CHECK (payment_method IN ('google_pay','apple_pay','revolut','stripe','comgate','admin_grant'));

ALTER TABLE public.payment_receipts
  ADD CONSTRAINT payment_receipts_payment_method_check
  CHECK (payment_method IN ('google_pay','apple_pay','revolut','stripe','comgate','admin_grant'));
