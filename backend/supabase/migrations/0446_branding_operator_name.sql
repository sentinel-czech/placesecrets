-- Migration 0446: rebrand leftover 'HeroDots' operator name to 'PlaceSecrets'.
-- Applies after 0445. Idempotent.
--
-- payment_config.operator_name still defaulted to 'HeroDots' (migration 001) and
-- any row created before the rename keeps that value (it appears on receipts and in
-- the admin settings UI). Update the default and any existing leftover row.

ALTER TABLE public.payment_config ALTER COLUMN operator_name SET DEFAULT 'PlaceSecrets';

UPDATE public.payment_config
SET operator_name = 'PlaceSecrets'
WHERE operator_name = 'HeroDots';
