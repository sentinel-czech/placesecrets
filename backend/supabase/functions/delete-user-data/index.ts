import { serve } from 'https://deno.land/std@0.177.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
import { handleAdminCors, adminJsonResponse, adminErrorResponse } from '../_shared/cors.ts'

serve(async (req: Request) => {
  const corsResp = handleAdminCors(req)
  if (corsResp) return corsResp

  // Auth check
  const authHeader = req.headers.get('Authorization')
  if (!authHeader?.startsWith('Bearer ')) return adminErrorResponse('Invalid authorization', req, 401)
  const token = authHeader.substring(7)

  const supabase = createClient(
    Deno.env.get('SUPABASE_URL')!,
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
  )
  const { data: { user }, error: authError } = await supabase.auth.getUser(token)
  if (authError || !user) return adminErrorResponse('Unauthorized', req, 401)

  const userId = user.id

  try {
    // Atomic: delete all user data from tables in a single transaction
    const { error: rpcError } = await supabase.rpc('delete_user_data_atomic', {
      p_user_id: userId,
    })

    if (rpcError) {
      console.error('delete-user-data atomic RPC error:', rpcError.message)
      return adminErrorResponse('Failed to delete user data', req, 500)
    }

    // Storage cleanup (non-transactional, best-effort)
    const { data: files } = await supabase.storage
      .from('user-photos')
      .list(userId)

    if (files && files.length > 0) {
      const paths = files.map((f: { name: string }) => `${userId}/${f.name}`)
      await supabase.storage.from('user-photos').remove(paths)
    }

    const { data: receiptFiles } = await supabase.storage
      .from('payment-receipts')
      .list(userId)

    if (receiptFiles && receiptFiles.length > 0) {
      const receiptPaths = receiptFiles.map((f: { name: string }) => `${userId}/${f.name}`)
      await supabase.storage.from('payment-receipts').remove(receiptPaths)
    }

    // Compliance evidence: record the erasure request before the auth user is
    // removed. `target_id` is TEXT so it survives the actor_id FK being nulled
    // (audit_logs.actor_id is ON DELETE SET NULL). Best-effort — never block the
    // deletion on logging.
    try {
      await supabase.from('audit_logs').insert({
        actor_id: userId,
        action: 'gdpr_account_deletion',
        target_type: 'user',
        target_id: userId,
        metadata: { email: user.email ?? null, deleted_at: new Date().toISOString() },
      })
    } catch (logErr) {
      console.error('delete-user-data audit log failed (non-fatal):', logErr)
    }

    // Delete auth user (cascades FK deletes)
    const { error: deleteError } = await supabase.auth.admin.deleteUser(userId)
    if (deleteError) {
      console.error('delete-user-data auth.admin.deleteUser error:', deleteError.message)
      return adminErrorResponse('Failed to delete user', req, 500)
    }

    return adminJsonResponse({ success: true }, req)
  } catch (err) {
    console.error('delete-user-data unexpected error:', err)
    return adminErrorResponse('Internal server error', req, 500)
  }
})
