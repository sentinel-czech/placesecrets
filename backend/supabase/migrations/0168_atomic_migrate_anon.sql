-- Atomic anonymous data migration function
CREATE OR REPLACE FUNCTION public.migrate_anonymous_data(
  p_old_device_id TEXT, p_new_user_id UUID
) RETURNS VOID LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  UPDATE public.free_visit_log
  SET user_id = p_new_user_id, device_id = NULL
  WHERE device_id = p_old_device_id AND user_id IS NULL;
  UPDATE public.poi_ratings
  SET user_id = p_new_user_id, device_id = NULL
  WHERE device_id = p_old_device_id AND user_id IS NULL
    AND poi_id NOT IN (
      SELECT poi_id FROM public.poi_ratings WHERE user_id = p_new_user_id
    );
  DELETE FROM public.poi_ratings
  WHERE device_id = p_old_device_id AND user_id IS NULL;
END;
$$;
