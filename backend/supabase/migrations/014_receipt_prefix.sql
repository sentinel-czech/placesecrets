-- 014: Change receipt prefix from HD- to PS- (PlaceSecrets rebrand)

CREATE OR REPLACE FUNCTION public.generate_receipt_number()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
  IF NEW.receipt_number IS NULL THEN
    NEW.receipt_number := 'PS-' || TO_CHAR(NOW(), 'YYYY') || '-'
      || LPAD(nextval('public.receipt_number_seq')::TEXT, 4, '0');
  END IF;
  RETURN NEW;
END;
$$;
