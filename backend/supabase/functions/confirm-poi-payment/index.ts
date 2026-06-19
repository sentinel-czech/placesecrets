import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
import Stripe from 'https://esm.sh/stripe@14'
import { corsHeaders, handleCors, jsonResponse, errorResponse } from '../_shared/cors.ts'
import { UUID_RE } from '../_shared/validation.ts'
import { createReceipt } from '../_shared/receipt.ts'

Deno.serve(async (req) => {
  const corsResp = handleCors(req)
  if (corsResp) return corsResp

  if (req.method !== 'POST') {
    return errorResponse('Method Not Allowed', 405)
  }

  try {
    const stripe = new Stripe(Deno.env.get('STRIPE_SECRET_KEY')!, {
      apiVersion: '2023-10-16',
      httpClient: Stripe.createFetchHttpClient(),
    })

    const body = await req.text()
    const sig = req.headers.get('stripe-signature')
    const webhookSecret = Deno.env.get('STRIPE_POI_WEBHOOK_SECRET')

    if (!sig || !webhookSecret) {
      return errorResponse('Missing signature or webhook secret', 400)
    }

    let event: Stripe.Event
    try {
      event = stripe.webhooks.constructEvent(body, sig, webhookSecret)
    } catch (err) {
      console.error('Webhook signature verification failed:', err)
      return errorResponse('Invalid signature', 400)
    }

    if (event.type !== 'checkout.session.completed') {
      return jsonResponse({ received: true }, 200, corsHeaders)
    }

    const session = event.data.object as Stripe.Checkout.Session
    const metadata = session.metadata || {}
    const purchaseType = metadata.purchase_type
    const userId = metadata.user_id

    if (!userId || !purchaseType) {
      console.error('Missing metadata:', { userId, purchaseType })
      return errorResponse('Missing metadata', 400)
    }
    if (!UUID_RE.test(userId)) {
      return errorResponse('Invalid user_id in metadata', 400)
    }

    const supabase = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
      { auth: { persistSession: false } }
    )

    const pricePaid = session.amount_total ? session.amount_total / 100 : null

    if (purchaseType === 'poi') {
      const poiId = metadata.poi_id
      if (!poiId || !UUID_RE.test(poiId)) {
        return errorResponse('Invalid poi_id in metadata', 400)
      }

      const { error } = await supabase.from('user_poi_purchases').upsert({
        user_id: userId,
        poi_id: poiId,
        price_paid: pricePaid,
        payment_id: session.payment_intent as string,
        stripe_session_id: session.id,
      }, { onConflict: 'user_id,poi_id' })

      if (error) {
        console.error('Upsert user_poi_purchases error:', error.message)
        return errorResponse('Database error', 500)
      }
    } else if (purchaseType === 'city_premium') {
      const cityId = metadata.city_id
      if (!cityId || !UUID_RE.test(cityId)) {
        return errorResponse('Invalid city_id in metadata', 400)
      }

      const { error } = await supabase.from('user_city_premium_purchases').upsert({
        user_id: userId,
        city_id: cityId,
        price_paid: pricePaid,
        payment_id: session.payment_intent as string,
        stripe_session_id: session.id,
      }, { onConflict: 'user_id,city_id' })

      if (error) {
        console.error('Upsert user_city_premium_purchases error:', error.message)
        return errorResponse('Database error', 500)
      }
    } else {
      console.error('Unknown purchase_type:', purchaseType)
      return errorResponse('Unknown purchase type', 400)
    }

    // Issue a receipt for the Stripe purchase (best-effort).
    if (pricePaid != null) {
      let itemLabel = 'PlaceSecrets purchase'
      let receiptCityId: string | null = null
      if (purchaseType === 'poi') {
        const { data: poi } = await supabase.from('pois').select('name').eq('id', metadata.poi_id).maybeSingle()
        const n = poi?.name as Record<string, string> | undefined
        itemLabel = `Premium place: ${n?.en ?? n?.cs ?? (n ? Object.values(n)[0] : '') ?? ''}`
      } else {
        receiptCityId = metadata.city_id as string
        const { data: city } = await supabase.from('cities').select('name').eq('id', metadata.city_id).maybeSingle()
        itemLabel = `City bundle: ${city?.name ?? ''}`
      }
      await createReceipt(supabase, {
        userId,
        cityId: receiptCityId,
        itemType: purchaseType as 'poi' | 'city_premium',
        itemLabel,
        amountEur: pricePaid,
        paymentMethod: 'stripe',
        transactionId: session.payment_intent as string,
      })
    }

    // Send confirmation email via Resend (optional, best-effort)
    const resendKey = Deno.env.get('RESEND_API_KEY')
    if (resendKey && session.customer_email) {
      try {
        const { data: user } = await supabase.auth.admin.getUserById(userId)
        const email = session.customer_email || user?.user?.email
        if (email) {
          await fetch('https://api.resend.com/emails', {
            method: 'POST',
            headers: {
              'Authorization': `Bearer ${resendKey}`,
              'Content-Type': 'application/json',
            },
            body: JSON.stringify({
              from: 'PlaceSecrets <noreply@placesecrets.app>',
              to: email,
              subject: 'Purchase Confirmation - PlaceSecrets',
              html: `<p>Thank you for your purchase!</p><p>Type: ${purchaseType}</p><p>Amount: €${pricePaid?.toFixed(2) ?? '—'}</p>`,
            }),
          })
        }
      } catch (emailErr) {
        console.error('Email send error (non-fatal):', emailErr)
      }
    }

    return jsonResponse({ received: true, purchase_type: purchaseType }, 200, corsHeaders)
  } catch (err) {
    console.error('confirm-poi-payment error:', err)
    return errorResponse('Internal error', 500)
  }
})
