-- Atomic user data deletion function
CREATE OR REPLACE FUNCTION public.delete_user_data_atomic(
  p_user_id UUID
) RETURNS VOID LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  DELETE FROM public.poi_ratings WHERE user_id = p_user_id;
  DELETE FROM public.user_access WHERE user_id = p_user_id;
  DELETE FROM public.free_visit_log WHERE user_id = p_user_id;
  DELETE FROM public.payment_receipts WHERE user_id = p_user_id;
END;
$$;
