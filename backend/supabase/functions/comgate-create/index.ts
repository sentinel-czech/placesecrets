import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
import { handleCors, corsHeaders, jsonResponse, errorResponse } from '../_shared/cors.ts'
import { UUID_RE } from '../_shared/validation.ts'

// Comgate "create payment" endpoint. Credentials come from env secrets
// (COMGATE_MERCHANT / COMGATE_SECRET) — supplied later. Scaffolding only.
const COMGATE_URL = 'https://payments.comgate.cz/v1.0/create'

Deno.serve(async (req) => {
  const corsResp = handleCors(req)
  if (corsResp) return corsResp
  if (req.method !== 'POST') return errorResponse('Method Not Allowed', 405)

  const ct = req.headers.get('content-type') ?? ''
  if (!ct.includes('application/json')) return errorResponse('Content-Type must be application/json', 415)

  const authHeader = req.headers.get('Authorization')
  if (!authHeader?.startsWith('Bearer ')) return errorResponse('Invalid authorization', 401)
  const token = authHeader.substring(7)

  const merchant = Deno.env.get('COMGATE_MERCHANT')
  const secret = Deno.env.get('COMGATE_SECRET')
  if (!merchant || !secret) {
    return errorResponse('Comgate not configured (set COMGATE_MERCHANT / COMGATE_SECRET).', 503)
  }

  const supabase = createClient(
    Deno.env.get('SUPABASE_URL')!,
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
    { auth: { persistSession: false } }
  )
  const { data: { user }, error: authError } = await supabase.auth.getUser(token)
  if (authError || !user) return errorResponse('Unauthorized', 401)

  let body: Record<string, unknown>
  try { body = await req.json() } catch { return errorResponse('Invalid JSON body') }

  const purchaseType = body.purchase_type as string
  if (!['poi', 'city_premium', 'country'].includes(purchaseType)) return errorResponse('Invalid purchase_type')

  const appUrl = Deno.env.get('APP_URL') || 'https://placesecrets.app'

  // Resolve the item, its price and a label.
  let priceEur = 0
  let label = ''
  let itemRef = ''

  if (purchaseType === 'poi') {
    const poiId = body.poi_id as string
    if (!poiId || !UUID_RE.test(poiId)) return errorResponse('Invalid poi_id')
    const { data: poi } = await supabase.from('pois').select('name, premium_price').eq('id', poiId).single()
    if (!poi) return errorResponse('POI not found', 404)
    if (!poi.premium_price || (poi.premium_price as number) <= 0) return errorResponse('POI has no premium price set')
    priceEur = poi.premium_price as number
    label = `Premium: ${(poi.name as Record<string, string>)?.cs || (poi.name as Record<string, string>)?.en || 'Place'}`
    itemRef = poiId
  } else if (purchaseType === 'city_premium') {
    const cityId = body.city_id as string
    if (!cityId || !UUID_RE.test(cityId)) return errorResponse('Invalid city_id')
    const { data: city } = await supabase.from('cities').select('name, premium_bundle_price').eq('id', cityId).single()
    if (!city) return errorResponse('City not found', 404)
    if (!city.premium_bundle_price || (city.premium_bundle_price as number) <= 0) return errorResponse('City has no premium bundle price set')
    priceEur = city.premium_bundle_price as number
    label = `Premium Bundle: ${city.name}`
    itemRef = cityId
  } else {
    const cc = ((body.country_code as string) || '').toUpperCase()
    if (!/^[A-Z]{2}$/.test(cc)) return errorResponse('Invalid country_code')
    const { data: cfg } = await supabase.from('payment_config').select('country_price_eur').maybeSingle()
    const price = (cfg as { country_price_eur?: number } | null)?.country_price_eur
    if (!price || price <= 0) return errorResponse('Country price not set')
    priceEur = price
    label = `Country: ${cc}`
    itemRef = cc
  }

  // refId carries the grant target back to the webhook (no extra pending table).
  const refId = `${purchaseType}~${user.id}~${itemRef}`.slice(0, 250)

  const params = new URLSearchParams({
    merchant,
    secret,
    price: String(Math.round(priceEur * 100)),
    curr: 'EUR',
    label,
    refId,
    method: 'ALL',
    email: user.email ?? '',
    prepareOnly: 'true',
    country: 'CZ',
    lang: 'cs',
    url_paid: `${appUrl}/purchase/success`,
    url_cancelled: `${appUrl}/purchase/cancel`,
  })

  try {
    const res = await fetch(COMGATE_URL, {
      method: 'POST',
      headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
      body: params,
    })
    const text = await res.text()
    const out = new URLSearchParams(text)
    if (out.get('code') !== '0') {
      console.error('comgate-create error:', text)
      return errorResponse(`Comgate error: ${out.get('message') || 'unknown'}`, 502)
    }
    return jsonResponse({ redirect: out.get('redirect'), transId: out.get('transId') }, 200, corsHeaders)
  } catch (err) {
    console.error('comgate-create exception:', err)
    return errorResponse('Failed to create Comgate payment', 500)
  }
})
