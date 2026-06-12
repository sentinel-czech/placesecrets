-- Migration 0231: Trigger on auth.users to auto-create profile

DROP TRIGGER IF EXISTS trg_create_user_profile ON auth.users;

CREATE TRIGGER trg_create_user_profile
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION create_user_profile_on_signup();
