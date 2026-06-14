import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

// Comgate status callback (server-to-server, x-www-form-urlencoded). On a PAID
// status we grant the entitlement encoded in refId.
//
// Hardening: we do NOT trust the callback body alone. After the shared-secret
// gate we re-verify the transaction by calling Comgate's status API
// (merchant + secret + transId) and grant ONLY when that authoritative response
// reports PAID. The grant target and price are taken from the verified status
// response, not the (forgeable) callback body. Grants are idempotent (upsert on
// the natural key), so replays are safe.

const COMGATE_STATUS_URL = 'https://payments.comgate.cz/v1.0/status'

Deno.serve(async (req) => {
  if (req.method !== 'POST') return new Response('Method Not Allowed', { status: 405 })

  const merchant = Deno.env.get('COMGATE_MERCHANT')
  const secret = Deno.env.get('COMGATE_SECRET')
  if (!merchant || !secret) return new Response('Comgate not configured', { status: 503 })

  const text = await req.text()
  const p = new URLSearchParams(text)

  // First gate: shared secret echoed by Comgate.
  if (p.get('secret') !== secret) {
    return new Response('Invalid secret', { status: 401 })
  }

  const transId = p.get('transId') || ''
  if (!transId) return new Response('Missing transId', { status: 400 })

  // Second gate: re-verify the transaction against Comgate's status API. This
  // is the authoritative check — a forged callback cannot pass it.
  let verified: URLSearchParams
  try {
    const statusRes = await fetch(COMGATE_STATUS_URL, {
      method: 'POST',
      headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
      body: new URLSearchParams({ merchant, secret, transId }),
    })
    verified = new URLSearchParams(await statusRes.text())
  } catch (err) {
    console.error('comgate-webhook status verify failed:', err)
    return new Response('Verification failed', { status: 502 })
  }

  if (verified.get('code') !== '0') {
    return new Response('Unverifiable transaction', { status: 400 })
  }
  if (verified.get('status') !== 'PAID') {
    return new Response('OK', { status: 200 }) // not paid (yet) — ignore
  }

  // Use the VERIFIED refId and price, not the callback body.
  const refId = verified.get('refId') || ''
  const priceEur = (parseInt(verified.get('price') || '0', 10) || 0) / 100
  const [purchaseType, userId, itemRef] = refId.split('~')
  if (!purchaseType || !userId || !itemRef) return new Response('Bad refId', { status: 400 })

  const supabase = createClient(
    Deno.env.get('SUPABASE_URL')!,
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
    { auth: { persistSession: false } }
  )

  try {
    if (purchaseType === 'poi') {
      await supabase.from('user_poi_purchases').upsert(
        { user_id: userId, poi_id: itemRef, price_paid: priceEur, payment_id: transId },
        { onConflict: 'user_id,poi_id' }
      )
    } else if (purchaseType === 'city_premium') {
      await supabase.from('user_city_premium_purchases').upsert(
        { user_id: userId, city_id: itemRef, price_paid: priceEur, payment_id: transId },
        { onConflict: 'user_id,city_id' }
      )
    } else if (purchaseType === 'country') {
      await supabase.from('user_country_purchases').upsert(
        { user_id: userId, country_code: itemRef, price_paid: priceEur, payment_method: 'comgate' },
        { onConflict: 'user_id,country_code' }
      )
    } else {
      return new Response('Unknown purchase type', { status: 400 })
    }
    return new Response('OK', { status: 200 })
  } catch (err) {
    console.error('comgate-webhook error:', err)
    return new Response('DB error', { status: 500 })
  }
})
