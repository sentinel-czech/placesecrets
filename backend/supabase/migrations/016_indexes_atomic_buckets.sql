-- Migration 016: Indexes, storage buckets, FK fixes

-- 1. Missing indexes
CREATE INDEX IF NOT EXISTS idx_poi_ratings_device ON public.poi_ratings(device_id);
CREATE INDEX IF NOT EXISTS idx_audit_logs_actor ON public.audit_logs(actor_id);
CREATE INDEX IF NOT EXISTS idx_audit_logs_created ON public.audit_logs(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_audit_logs_target ON public.audit_logs(target_type, target_id);
CREATE INDEX IF NOT EXISTS idx_free_visit_log_poi ON public.free_visit_log(poi_id);

-- 2. Fix audit_logs FK cascade (actor deleted → set null)
ALTER TABLE public.audit_logs
  DROP CONSTRAINT IF EXISTS audit_logs_actor_id_fkey;
ALTER TABLE public.audit_logs
  ADD CONSTRAINT audit_logs_actor_id_fkey
  FOREIGN KEY (actor_id) REFERENCES auth.users(id) ON DELETE SET NULL;

-- 3. Change poi_types FK from SET NULL to RESTRICT (prevent orphaning POIs)
ALTER TABLE public.pois
  DROP CONSTRAINT IF EXISTS pois_type_id_fkey;
ALTER TABLE public.pois
  ADD CONSTRAINT pois_type_id_fkey
  FOREIGN KEY (type_id) REFERENCES public.poi_types(id) ON DELETE RESTRICT;

-- 4. Storage buckets
INSERT INTO storage.buckets (id, name, public) VALUES
  ('poi-photos', 'poi-photos', true),
  ('audio-guides', 'audio-guides', true),
  ('payment-receipts', 'payment-receipts', false)
ON CONFLICT DO NOTHING;
