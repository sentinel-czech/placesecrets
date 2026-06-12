import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
import Stripe from 'https://esm.sh/stripe@14'
import { handleCors, corsHeaders, jsonResponse, errorResponse } from '../_shared/cors.ts'

const UUID_RE = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i

Deno.serve(async (req) => {
  const corsResp = handleCors(req)
  if (corsResp) return corsResp

  if (req.method !== 'POST') {
    return errorResponse('Method Not Allowed', 405)
  }

  const ct = req.headers.get('content-type') ?? ''
  if (!ct.includes('application/json')) {
    return errorResponse('Content-Type must be application/json', 415)
  }

  const authHeader = req.headers.get('Authorization')
  if (!authHeader?.startsWith('Bearer ')) {
    return errorResponse('Invalid authorization', 401)
  }
  const token = authHeader.substring(7)

  const supabase = createClient(
    Deno.env.get('SUPABASE_URL')!,
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
    { auth: { persistSession: false } }
  )

  const { data: { user }, error: authError } = await supabase.auth.getUser(token)
  if (authError || !user) return errorResponse('Unauthorized', 401)

  let body: Record<string, unknown>
  try {
    body = await req.json()
  } catch {
    return errorResponse('Invalid JSON body')
  }

  const purchaseType = body.purchase_type as string
  if (!['poi', 'city_premium'].includes(purchaseType)) {
    return errorResponse('Invalid purchase_type')
  }

  const appUrl = Deno.env.get('APP_URL') || 'https://placesecrets.app'

  try {
    const stripe = new Stripe(Deno.env.get('STRIPE_SECRET_KEY')!, {
      apiVersion: '2023-10-16',
      httpClient: Stripe.createFetchHttpClient(),
    })

    if (purchaseType === 'poi') {
      const poiId = body.poi_id as string
      if (!poiId || !UUID_RE.test(poiId)) {
        return errorResponse('Invalid poi_id')
      }

      const { data: poi, error: poiError } = await supabase
        .from('pois')
        .select('name, premium_price, cities!inner(slug)')
        .eq('id', poiId)
        .single()

      if (poiError || !poi) return errorResponse('POI not found', 404)
      if (!poi.premium_price || poi.premium_price <= 0) {
        return errorResponse('POI has no premium price set')
      }

      const poiName = (poi.name as Record<string, string>)?.cs
        || (poi.name as Record<string, string>)?.en
        || 'Premium POI'

      const session = await stripe.checkout.sessions.create({
        mode: 'payment',
        line_items: [{
          price_data: {
            currency: 'eur',
            product_data: { name: `Premium: ${poiName}` },
            unit_amount: Math.round(poi.premium_price * 100),
          },
          quantity: 1,
        }],
        metadata: {
          purchase_type: 'poi',
          user_id: user.id,
          poi_id: poiId,
        },
        customer_email: user.email,
        success_url: `${appUrl}/purchase/success?session_id={CHECKOUT_SESSION_ID}`,
        cancel_url: `${appUrl}/purchase/cancel`,
      })

      return jsonResponse({ url: session.url, session_id: session.id }, 200, corsHeaders)
    }

    // city_premium bundle
    const cityId = body.city_id as string
    if (!cityId || !UUID_RE.test(cityId)) {
      return errorResponse('Invalid city_id')
    }

    const { data: city, error: cityError } = await supabase
      .from('cities')
      .select('name, premium_bundle_price, slug')
      .eq('id', cityId)
      .single()

    if (cityError || !city) return errorResponse('City not found', 404)
    if (!city.premium_bundle_price || city.premium_bundle_price <= 0) {
      return errorResponse('City has no premium bundle price set')
    }

    const session = await stripe.checkout.sessions.create({
      mode: 'payment',
      line_items: [{
        price_data: {
          currency: 'eur',
          product_data: { name: `Premium Bundle: ${city.name}` },
          unit_amount: Math.round(city.premium_bundle_price * 100),
        },
        quantity: 1,
      }],
      metadata: {
        purchase_type: 'city_premium',
        user_id: user.id,
        city_id: cityId,
      },
      customer_email: user.email,
      success_url: `${appUrl}/purchase/success?session_id={CHECKOUT_SESSION_ID}`,
      cancel_url: `${appUrl}/purchase/cancel`,
    })

    return jsonResponse({ url: session.url, session_id: session.id }, 200, corsHeaders)
  } catch (err) {
    console.error('create-poi-checkout error:', err)
    return errorResponse('Failed to create checkout session', 500)
  }
})
