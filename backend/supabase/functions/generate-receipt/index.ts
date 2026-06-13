import { serve } from 'https://deno.land/std@0.177.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
import { handleAdminCors, adminJsonResponse, adminErrorResponse } from '../_shared/cors.ts'

serve(async (req: Request) => {
  const corsResp = handleAdminCors(req)
  if (corsResp) return corsResp

  // Auth check — require Authorization header (admin or internal service call)
  const authHeader = req.headers.get('Authorization')
  if (!authHeader?.startsWith('Bearer ')) return adminErrorResponse('Invalid authorization', req, 401)
  const token = authHeader.substring(7)

  const supabase = createClient(
    Deno.env.get('SUPABASE_URL')!,
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
  )
  const { data: { user: authUser }, error: authError } = await supabase.auth.getUser(token)
  if (authError || !authUser) return adminErrorResponse('Unauthorized', req, 401)

  const ct = req.headers.get('content-type') ?? ''
  if (!ct.includes('application/json')) {
    return adminErrorResponse('Content-Type must be application/json', req, 415)
  }

  let body: Record<string, unknown>
  try {
    body = await req.json()
  } catch {
    return adminErrorResponse('Invalid JSON body', req)
  }

  const { receipt_id, send_email = false } = body as {
    receipt_id?: string; send_email?: boolean
  }

  if (!receipt_id) {
    return adminErrorResponse('Missing required field: receipt_id', req)
  }

  const uuidRegex = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i
  if (!uuidRegex.test(receipt_id)) {
    return adminErrorResponse('Invalid receipt_id format', req)
  }

  try {
    const { data: r } = await supabase
      .from('payment_receipts')
      .select('*, cities(name), user:user_id(email)')
      .eq('id', receipt_id).single()
    if (!r) return adminErrorResponse('Receipt not found', req, 404)

    // Ownership check: user must own the receipt or be an admin
    const { data: adminRow } = await supabase
      .from('admin_users')
      .select('role')
      .eq('user_id', authUser.id)
      .maybeSingle()
    if (r.user_id !== authUser.id && !adminRow) {
      return adminErrorResponse('Forbidden', req, 403)
    }

    const date = new Date(r.purchased_at).toLocaleDateString('cs-CZ', {
      day: 'numeric', month: 'long', year: 'numeric'
    })
    const lines = [
      'PlaceSecrets - Payment Receipt', '',
      `Receipt #: ${r.receipt_number}`,
      `Date: ${date}`,
      `Customer: ${r.user?.email ?? 'Anonymous'}`,
      `City: ${r.cities?.name ?? ''}`,
      `Amount: ${Number(r.amount_eur).toFixed(2)} ${r.currency}`,
      `Payment method: ${r.payment_method}`,
      r.transaction_id ? `Transaction ID: ${r.transaction_id}` : '',
      '', 'PlaceSecrets - cz.tuma.placesecrets',
    ]

    const content = lines.filter(Boolean).join('\n')
    const pdfText = `%PDF-1.4
1 0 obj<</Type/Catalog/Pages 2 0 R>>endobj
2 0 obj<</Type/Pages/Kids[3 0 R]/Count 1>>endobj
3 0 obj<</Type/Page/Parent 2 0 R/MediaBox[0 0 595 842]/Contents 4 0 R/Resources<</Font<</F1 5 0 R>>>>>>endobj
4 0 obj<</Length ${content.length + 100}>>
stream
BT /F1 12 Tf 50 780 Td 16 TL
${lines.filter(Boolean).map(l => `(${l.replace(/[()\\]/g, c => '\\' + c)}) Tj T*`).join('\n')}
ET
endstream
endobj
5 0 obj<</Type/Font/Subtype/Type1/BaseFont/Helvetica>>endobj
xref
0 6
0000000000 65535 f
trailer<</Size 6/Root 1 0 R>>
startxref 0
%%EOF`

    const pdfBytes = new TextEncoder().encode(pdfText)
    const path = `${r.user_id}/${r.receipt_number}.pdf`

    const { error: uploadError } = await supabase.storage.from('payment-receipts')
      .upload(path, pdfBytes, { contentType: 'application/pdf', upsert: true })

    if (uploadError) {
      console.error('generate-receipt upload error:', uploadError.message)
      return adminErrorResponse('Failed to upload receipt PDF', req, 500)
    }

    const { data: signed, error: signedUrlError } = await supabase.storage.from('payment-receipts')
      .createSignedUrl(path, 60 * 60 * 24 * 365)

    if (signedUrlError) {
      console.error('generate-receipt signed URL error:', signedUrlError.message)
      return adminErrorResponse('Failed to create signed URL', req, 500)
    }

    await supabase.from('payment_receipts')
      .update({ receipt_pdf_url: signed?.signedUrl }).eq('id', receipt_id)

    if (send_email === true && r.user?.email) {
      const key = Deno.env.get('RESEND_API_KEY')
      if (key) {
        const esc = (s: string | undefined | null) =>
          (s ?? '').replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;')

        try {
          await fetch('https://api.resend.com/emails', {
            method: 'POST',
            headers: { Authorization: `Bearer ${key}`, 'Content-Type': 'application/json' },
            body: JSON.stringify({
              from: 'PlaceSecrets <noreply@placesecrets.app>',
              to: r.user.email,
              subject: `Payment receipt ${r.receipt_number} - PlaceSecrets`,
              html: `<div style="font-family:sans-serif;max-width:500px">
                <div style="background:#2D6A4F;padding:20px;border-radius:8px 8px 0 0">
                  <h1 style="color:white;margin:0;font-size:22px">PlaceSecrets</h1>
                  <p style="color:#b7ddc8;margin:4px 0 0">Payment Receipt</p>
                </div>
                <div style="border:1px solid #e5e7eb;border-top:none;padding:24px;border-radius:0 0 8px 8px">
                  <p>Receipt #: <strong>${esc(r.receipt_number)}</strong></p>
                  <p>City: <strong>${esc(r.cities?.name)}</strong></p>
                  <p>Amount: <strong style="color:#2D6A4F;font-size:20px">${esc(Number(r.amount_eur).toFixed(2))} ${esc(r.currency)}</strong></p>
                  <p>Method: ${esc(r.payment_method)}</p>
                  <p>Date: ${esc(date)}</p>
                  ${signed?.signedUrl ? `<p><a href="${signed.signedUrl}" style="background:#2D6A4F;color:white;padding:10px 20px;border-radius:6px;text-decoration:none;display:inline-block">Download PDF Receipt</a></p>` : ''}
                </div>
              </div>`
            })
          })
          await supabase.from('payment_receipts')
            .update({ receipt_sent_at: new Date().toISOString() }).eq('id', receipt_id)
        } catch (emailErr) {
          console.error('generate-receipt email error:', emailErr)
        }
      }
    }

    return adminJsonResponse({ success: true, pdf_url: signed?.signedUrl }, req)
  } catch (err) {
    console.error('generate-receipt error:', err)
    return adminErrorResponse('Failed to generate receipt', req, 500)
  }
})
