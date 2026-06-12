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

  const authHeader = req.headers.get('Authorization')
  if (!authHeader?.startsWith('Bearer ')) {
    return adminErrorResponse('Invalid authorization', req, 401)
  }
  const token = authHeader.substring(7)

  const supabase = createClient(
    Deno.env.get('SUPABASE_URL')!,
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
  )

  const { data: { user }, error: authError } = await supabase.auth.getUser(token)
  if (authError || !user) return adminErrorResponse('Unauthorized', req, 401)

  let body: Record<string, unknown>
  try {
    body = await req.json()
  } catch {
    return adminErrorResponse('Invalid JSON body', req)
  }

  const { amount, currency, cityId } = body as {
    amount?: number; currency?: string; cityId?: string
  }

  if (!amount || !cityId) {
    return adminErrorResponse('Missing required fields: amount, cityId', req)
  }

  if (typeof amount !== 'number' || amount <= 0 || amount > 10000) {
    return adminErrorResponse('Invalid amount', req)
  }

  const uuidRegex = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i
  if (!uuidRegex.test(cityId)) {
    return adminErrorResponse('Invalid cityId format', req)
  }

  // Validate city exists
  const { data: city, error: cityError } = await supabase.from('cities').select('id').eq('id', cityId).single()
  if (cityError || !city) {
    return adminErrorResponse('City not found', req, 404)
  }

  try {
    const stripe = new Stripe(Deno.env.get('STRIPE_SECRET_KEY')!, {
      apiVersion: '2023-10-16',
      httpClient: Stripe.createFetchHttpClient(),
    })

    const intent = await stripe.paymentIntents.create({
      amount: Math.round(amount * 100),
      currency: currency || 'eur',
      metadata: { city_id: cityId, user_id: user.id },
    })

    return adminJsonResponse({ clientSecret: intent.client_secret }, req)
  } catch (err) {
    console.error('create-payment-intent error:', err)
    return adminErrorResponse('Failed to create payment intent', req, 500)
  }
})
