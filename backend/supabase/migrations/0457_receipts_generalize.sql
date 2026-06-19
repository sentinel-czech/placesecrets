-- Migration 0457: generalize payment_receipts so a receipt can represent any
-- paid purchase (city access, POI premium, city bundle, country), not only a
-- city. Applies after 0456. Idempotent.
--
-- Until now city_id was NOT NULL, which prevented issuing receipts for POI /
-- country purchases. We make it nullable and add item_type/item_label so the
-- receipt carries a human-readable description independent of city.

ALTER TABLE public.payment_receipts
  ALTER COLUMN city_id DROP NOT NULL;

ALTER TABLE public.payment_receipts
  ADD COLUMN IF NOT EXISTS item_type  TEXT,   -- 'city' | 'poi' | 'city_premium' | 'country'
  ADD COLUMN IF NOT EXISTS item_label TEXT;   -- e.g. "Prague — city access"

-- Allow the new payment methods on receipts (comgate already granted elsewhere).
ALTER TABLE public.payment_receipts
  DROP CONSTRAINT IF EXISTS payment_receipts_payment_method_check;
ALTER TABLE public.payment_receipts
  ADD CONSTRAINT payment_receipts_payment_method_check
  CHECK (payment_method IN ('google_pay','apple_pay','revolut','stripe','comgate','admin_grant'));
