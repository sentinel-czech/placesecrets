import { serve } from 'https://deno.land/std@0.177.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
import { handleAdminCors, adminJsonResponse, adminErrorResponse } from '../_shared/cors.ts'

const VALID_PAYMENT_METHODS = ['stripe', 'google_pay', 'apple_pay', 'revolut', 'admin_grant']

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
  const { data: { user: authUser }, error: authError } = await supabase.auth.getUser(token)
  if (authError || !authUser) return adminErrorResponse('Unauthorized', req, 401)

  let body: Record<string, unknown>
  try {
    body = await req.json()
  } catch {
    return adminErrorResponse('Invalid JSON body', req)
  }

  const { user_id, city_id, payment_method, transaction_id, amount_eur } = body as {
    user_id?: string; city_id?: string; payment_method?: string;
    transaction_id?: string; amount_eur?: number
  }

  if (!user_id || !city_id || !payment_method || amount_eur == null || typeof amount_eur !== 'number') {
    return adminErrorResponse('Missing required fields: user_id, city_id, payment_method, amount_eur', req)
  }

  const uuidRegex = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i
  if (!uuidRegex.test(user_id) || !uuidRegex.test(city_id)) {
    return adminErrorResponse('Invalid UUID format', req)
  }

  if (!VALID_PAYMENT_METHODS.includes(payment_method)) {
    return adminErrorResponse('Invalid payment method', req)
  }

  if (user_id !== authUser.id) {
    return adminErrorResponse('Forbidden: cannot confirm payment for another user', req, 403)
  }

  // Validate city exists
  const { data: city, error: cityError } = await supabase.from('cities').select('id, name').eq('id', city_id).single()
  if (cityError || !city) {
    return adminErrorResponse('City not found', req, 404)
  }

  try {
    // Atomic: upsert user_access + insert receipt in a single transaction
    const { data: receiptJson, error: rpcError } = await supabase.rpc('confirm_payment_atomic', {
      p_user_id: user_id,
      p_city_id: city_id,
      p_payment_method: payment_method,
      p_transaction_id: transaction_id || null,
      p_amount_eur: amount_eur,
    })

    if (rpcError) {
      console.error('confirm-payment atomic RPC error:', rpcError.message)
      return adminErrorResponse('Failed to confirm payment', req, 500)
    }

    const receipt = receiptJson as Record<string, unknown>

    const { data: { user } } = await supabase.auth.admin.getUserById(user_id)

    const esc = (s: string | undefined | null) =>
      (s ?? '').replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;')

    if (user?.email) {
      const resendKey = Deno.env.get('RESEND_API_KEY')
      if (resendKey) {
        try {
          await fetch('https://api.resend.com/emails', {
            method: 'POST',
            headers: { Authorization: `Bearer ${resendKey}`, 'Content-Type': 'application/json' },
            body: JSON.stringify({
              from: 'PlaceSecrets <noreply@placesecrets.app>',
              to: user.email,
              subject: `Payment confirmation ${receipt?.receipt_number} - PlaceSecrets`,
              html: `<h2>Thank you for your purchase!</h2>
                <p>Receipt #: <strong>${esc(receipt?.receipt_number as string)}</strong></p>
                <p>City: <strong>${esc(city?.name)}</strong></p>
                <p>Amount: <strong>${esc(String(amount_eur))} EUR</strong></p>
                <p>PDF receipt will be available in the app settings.</p>`
            })
          })
        } catch (emailErr) {
          console.error('confirm-payment email error:', emailErr)
        }
      }
    }

    if (receipt) {
      try {
        await supabase.functions.invoke('generate-receipt', {
          body: { receipt_id: receipt.id }
        })
      } catch (pdfErr) {
        console.error('confirm-payment PDF generation error:', pdfErr)
      }
    }

    return adminJsonResponse({ success: true, receipt }, req)
  } catch (err) {
    console.error('confirm-payment unexpected error:', err)
    return adminErrorResponse('Internal server error', req, 500)
  }
})
