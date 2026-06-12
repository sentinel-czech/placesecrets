-- Atomic payment confirmation function
CREATE OR REPLACE FUNCTION public.confirm_payment_atomic(
  p_user_id UUID, p_city_id UUID, p_payment_method TEXT, p_transaction_id TEXT, p_amount_eur NUMERIC
) RETURNS JSONB LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_receipt JSONB;
BEGIN
  INSERT INTO public.user_access (user_id, city_id, payment_method, transaction_id, amount_eur, valid_until)
  VALUES (p_user_id, p_city_id, p_payment_method, p_transaction_id, p_amount_eur, NULL)
  ON CONFLICT (user_id, city_id) DO UPDATE SET
    payment_method = EXCLUDED.payment_method,
    transaction_id = EXCLUDED.transaction_id,
    amount_eur = EXCLUDED.amount_eur,
    valid_until = NULL;
  INSERT INTO public.payment_receipts (user_id, city_id, payment_method, transaction_id, amount_eur, status)
  VALUES (p_user_id, p_city_id, p_payment_method, p_transaction_id, p_amount_eur, 'completed')
  RETURNING to_jsonb(payment_receipts.*) INTO v_receipt;
  RETURN v_receipt;
END;
$$;
