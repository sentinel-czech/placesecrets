import { serve } from 'https://deno.land/std@0.177.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
import Stripe from 'https://esm.sh/stripe@14'
import { handleAdminCors, adminJsonResponse, adminErrorResponse } from '../_shared/cors.ts'

serve(async (req: Request) => {
  const corsResp = handleAdminCors(req)
  if (corsResp) return corsResp

  if (req.method !== 'POST') {
    return adminErrorResponse('Method Not Allowed', req, 405)
  }

  const ct = req.headers.get('content-type') ?? ''
  if (!ct.includes('application/json')) {
    return adminErrorResponse('Content-Type must be application/json', req, 415)
  }

  // Admin auth check — only admin users can trigger refunds
  const authHeader = req.headers.get('Authorization')
  if (!authHeader?.startsWith('Bearer ')) return adminErrorResponse('Invalid authorization', req, 401)
  const token = authHeader.substring(7)

  const supabase = createClient(
    Deno.env.get('SUPABASE_URL')!,
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
  )
  const { data: { user: authUser }, error: authError } = await supabase.auth.getUser(token)
  if (authError || !authUser) return adminErrorResponse('Unauthorized', req, 401)

  const { data: adminRow } = await supabase
    .from('admin_users')
    .select('role')
    .eq('user_id', authUser.id)
    .maybeSingle()
  if (!adminRow) return adminErrorResponse('Forbidden: admin access required', req, 403)

  // Only superadmin can issue refunds (payments write permission)
  if (adminRow.role !== 'superadmin') {
    // Check ACL for payments write permission
    const { data: perms } = await supabase.rpc('get_role_permissions', { target_role: adminRow.role })
    const paymentPerm = (perms as { resource: string; can_write: boolean }[] | null)
      ?.find(p => p.resource === 'payments')
    if (!paymentPerm?.can_write) {
      return adminErrorResponse('Forbidden: insufficient permissions', req, 403)
    }
  }

  // Input validation
  let body: Record<string, unknown>
  try {
    body = await req.json()
  } catch {
    return adminErrorResponse('Invalid JSON body', req)
  }

  const { payment_intent_id, receipt_id } = body as {
    payment_intent_id?: string; receipt_id?: string
  }

  if (!payment_intent_id || !receipt_id) {
    return adminErrorResponse('Missing required fields: payment_intent_id, receipt_id', req)
  }

  const uuidRegex = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i
  if (!uuidRegex.test(receipt_id)) {
    return adminErrorResponse('Invalid receipt_id format', req)
  }

  if (!/^pi_[a-zA-Z0-9]+$/.test(payment_intent_id)) {
    return adminErrorResponse('Invalid payment_intent_id format', req)
  }

  try {
    const stripe = new Stripe(Deno.env.get('STRIPE_SECRET_KEY')!, { apiVersion: '2023-10-16' })

    const refund = await stripe.refunds.create(
      { payment_intent: payment_intent_id },
      { idempotencyKey: receipt_id }
    )

    if (refund.status !== 'succeeded') {
      return adminErrorResponse('Refund was not successful', req, 500)
    }

    // Atomic: update receipt status + delete access in one transaction
    const { error: rpcError } = await supabase.rpc('process_refund_atomic', {
      p_receipt_id: receipt_id,
    })

    if (rpcError) {
      console.error('stripe-refund atomic RPC error:', rpcError.message)
      return adminErrorResponse('Refund succeeded but DB update failed', req, 500)
    }

    return adminJsonResponse({ success: true }, req)
  } catch (err) {
    console.error('stripe-refund error:', err)
    return adminErrorResponse('Failed to process refund', req, 500)
  }
})
