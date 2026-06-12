import { serve } from 'https://deno.land/std@0.177.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
import { handleCors, jsonResponse, errorResponse } from '../_shared/cors.ts'

serve(async (req: Request) => {
  const corsResp = handleCors(req)
  if (corsResp) return corsResp

  if (req.method !== 'POST') {
    return errorResponse('Method Not Allowed', 405)
  }

  // Content-Type check
  const ct = req.headers.get('content-type') ?? ''
  if (!ct.includes('application/json')) {
    return errorResponse('Content-Type must be application/json', 415)
  }

  // Timing-safe webhook secret verification
  const webhookSecret = req.headers.get('x-webhook-secret') ?? ''
  const expectedSecret = Deno.env.get('WEBHOOK_SECRET') ?? ''

  if (!expectedSecret) {
    console.error('WEBHOOK_SECRET not configured')
    return errorResponse('Internal server error', 500)
  }

  // Constant-time comparison: hash both values and compare the digests
  // This avoids length-leak from early return and ensures fixed-size comparison
  const encoder = new TextEncoder()
  const hashA = new Uint8Array(
    await crypto.subtle.digest('SHA-256', encoder.encode(webhookSecret))
  )
  const hashB = new Uint8Array(
    await crypto.subtle.digest('SHA-256', encoder.encode(expectedSecret))
  )

  let diff = 0
  for (let i = 0; i < hashA.length; i++) {
    diff |= hashA[i] ^ hashB[i]
  }
  if (diff !== 0) {
    return errorResponse('Unauthorized', 401)
  }

  // Input validation
  let body: Record<string, unknown>
  try {
    body = await req.json()
  } catch {
    return errorResponse('Invalid JSON body')
  }

  const { user_id, city_id, payment_method, transaction_id, amount_eur } = body as {
    user_id?: string; city_id?: string; payment_method?: string;
    transaction_id?: string; amount_eur?: number
  }

  if (!user_id || !city_id || !payment_method || amount_eur == null) {
    return errorResponse('Missing required fields: user_id, city_id, payment_method, amount_eur')
  }

  const uuidRegex = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i
  if (!uuidRegex.test(user_id) || !uuidRegex.test(city_id)) {
    return errorResponse('Invalid UUID format for user_id or city_id')
  }

  const validMethods = ['stripe', 'google_pay', 'apple_pay', 'revolut', 'admin_grant']
  if (!validMethods.includes(payment_method)) {
    return errorResponse('Invalid payment method')
  }

  const supabase = createClient(
    Deno.env.get('SUPABASE_URL')!,
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
  )

  const { error } = await supabase
    .from('user_access')
    .upsert({ user_id, city_id, payment_method, transaction_id, amount_eur, valid_until: null })

  if (error) {
    console.error('payment-webhook upsert error:', error.message)
    return errorResponse('Failed to process webhook', 500)
  }

  return jsonResponse({ success: true })
})
