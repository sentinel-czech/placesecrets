-- Atomic refund function
CREATE OR REPLACE FUNCTION public.process_refund_atomic(
  p_receipt_id UUID
) RETURNS VOID LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_user_id UUID;
  v_city_id UUID;
BEGIN
  UPDATE public.payment_receipts
  SET status = 'refunded'
  WHERE id = p_receipt_id
  RETURNING user_id, city_id INTO v_user_id, v_city_id;
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Receipt not found: %', p_receipt_id;
  END IF;
  DELETE FROM public.user_access
  WHERE user_id = v_user_id AND city_id = v_city_id;
END;
$$;
