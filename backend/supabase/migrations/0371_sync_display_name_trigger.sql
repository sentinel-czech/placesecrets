-- Sync display_name from user_profiles to contributor_profiles
-- Canonical source is user_profiles.display_name
CREATE OR REPLACE FUNCTION sync_display_name_to_contributor()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
BEGIN
  IF NEW.display_name IS DISTINCT FROM OLD.display_name AND NEW.display_name IS NOT NULL THEN
    UPDATE contributor_profiles SET display_name = NEW.display_name, updated_at = NOW()
    WHERE user_id = NEW.user_id;
  END IF;
  RETURN NEW;
END; $$;

CREATE TRIGGER trg_sync_display_name
  AFTER UPDATE OF display_name ON user_profiles
  FOR EACH ROW EXECUTE FUNCTION sync_display_name_to_contributor();
