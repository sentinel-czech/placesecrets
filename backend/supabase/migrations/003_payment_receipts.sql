-- Payment receipts for EU consumer law compliance

CREATE SEQUENCE public.receipt_number_seq START 1;

CREATE TABLE public.payment_receipts (
  id               UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id          UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  city_id          UUID NOT NULL REFERENCES public.cities(id),
  purchased_at     TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  payment_method   TEXT NOT NULL
    CHECK (payment_method IN ('google_pay','apple_pay','revolut','stripe','admin_grant')),
  transaction_id   TEXT,
  amount_eur       DECIMAL(10,2) NOT NULL,
  currency         TEXT NOT NULL DEFAULT 'EUR',
  status           TEXT NOT NULL DEFAULT 'completed'
    CHECK (status IN ('pending','completed','refunded','disputed')),
  revolut_note     TEXT,
  confirmed_by     UUID REFERENCES auth.users(id),
  confirmed_at     TIMESTAMPTZ,
  receipt_number   TEXT UNIQUE,
  receipt_pdf_url  TEXT,
  receipt_sent_at  TIMESTAMPTZ,
  created_at       TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE OR REPLACE FUNCTION public.generate_receipt_number()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
  IF NEW.receipt_number IS NULL THEN
    NEW.receipt_number := 'HD-' || TO_CHAR(NOW(), 'YYYY') || '-'
      || LPAD(nextval('public.receipt_number_seq')::TEXT, 4, '0');
  END IF;
  RETURN NEW;
END;
$$;

CREATE TRIGGER set_receipt_number
  BEFORE INSERT ON public.payment_receipts
  FOR EACH ROW EXECUTE FUNCTION public.generate_receipt_number();

ALTER TABLE public.payment_receipts ENABLE ROW LEVEL SECURITY;
CREATE POLICY "receipts_own_read" ON public.payment_receipts
  FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "receipts_service_all" ON public.payment_receipts
  FOR ALL USING (auth.role() = 'service_role');

CREATE INDEX idx_receipts_user ON public.payment_receipts(user_id, purchased_at DESC);
CREATE INDEX idx_receipts_status ON public.payment_receipts(status);
CREATE INDEX idx_receipts_method ON public.payment_receipts(payment_method);
