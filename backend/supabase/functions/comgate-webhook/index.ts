import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

// Comgate status callback (server-to-server, x-www-form-urlencoded). On a PAID
// status we grant the entitlement encoded in refId. Credentials supplied later.
//
// NOTE for production hardening: instead of trusting the echoed `secret`, verify
// the payment by calling Comgate's status API (merchant+secret+transId) before
// granting. This scaffolding checks the shared secret Comgate echoes back.

Deno.serve(async (req) => {
  if (req.method !== 'POST') return new Response('Method Not Allowed', { status: 405 })

  const secret = Deno.env.get('COMGATE_SECRET')
  if (!secret) return new Response('Comgate not configured', { status: 503 })

  const text = await req.text()
  const p = new URLSearchParams(text)

  if (p.get('secret') !== secret) {
    return new Response('Invalid secret', { status: 401 })
  }

  const status = p.get('status')
  if (status !== 'PAID') return new Response('OK', { status: 200 }) // ignore non-paid states

  const refId = p.get('refId') || ''
  const transId = p.get('transId') || ''
  const priceEur = (parseInt(p.get('price') || '0', 10) || 0) / 100
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
