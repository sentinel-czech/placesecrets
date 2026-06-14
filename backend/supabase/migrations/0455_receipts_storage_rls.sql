-- Migration 0455: defense-in-depth RLS on the private `payment-receipts` bucket.
-- Applies after 0454. Idempotent.
--
-- Receipt PDFs are served to users via short-lived signed URLs created by the
-- `generate-receipt` edge function, and the bucket is private (public=false,
-- migration 016), so direct object access was already default-denied. This adds
-- an explicit owner-only read policy as belt-and-braces: a user can only read
-- objects under their own `<user_id>/...` prefix. The edge functions use the
-- service_role key, which bypasses RLS, so no insert/update policy is needed.

DROP POLICY IF EXISTS "payment_receipts_owner_read" ON storage.objects;
CREATE POLICY "payment_receipts_owner_read" ON storage.objects
  FOR SELECT TO authenticated
  USING (
    bucket_id = 'payment-receipts'
    AND (storage.foldername(name))[1] = auth.uid()::text
  );
