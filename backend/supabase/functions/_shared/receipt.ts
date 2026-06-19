// deno-lint-ignore-file no-explicit-any
import { jsPDF } from 'https://esm.sh/jspdf@2.5.2'

// jsPDF's built-in Helvetica has no Czech glyphs, so dynamic text is folded to
// ASCII for the PDF (the client-rendered image keeps full diacritics).
const ascii = (s: unknown) =>
  String(s ?? '').normalize('NFD').replace(/\p{Diacritic}/gu, '')

/** Builds the receipt PDF, uploads it, and stores the signed URL on the row. */
export async function generateReceiptPdf(supabase: any, r: any): Promise<string | null> {
  const date = new Date(r.purchased_at ?? Date.now()).toLocaleDateString('cs-CZ', {
    day: 'numeric', month: 'long', year: 'numeric',
  })
  const itemLabel = r.item_label ?? r.cities?.name ?? 'PlaceSecrets purchase'

  const { data: cfg } = await supabase.from('payment_config').select('operator_name').maybeSingle()
  const operator = cfg?.operator_name ?? 'PlaceSecrets'

  let email = r.user?.email as string | undefined
  if (!email) {
    try {
      const { data: u } = await supabase.auth.admin.getUserById(r.user_id)
      email = u?.user?.email
    } catch { /* best effort */ }
  }

  const doc = new jsPDF({ unit: 'pt', format: 'a4' })
  doc.setFillColor(45, 106, 79)
  doc.rect(0, 0, 595, 90, 'F')
  doc.setTextColor(255, 255, 255)
  doc.setFont('helvetica', 'bold'); doc.setFontSize(22)
  doc.text(ascii(operator), 50, 50)
  doc.setFont('helvetica', 'normal'); doc.setFontSize(12)
  doc.text('Payment receipt', 50, 72)

  doc.setTextColor(25, 25, 25)
  let y = 140
  const row = (label: string, value: string) => {
    doc.setFont('helvetica', 'bold'); doc.setFontSize(11)
    doc.text(label, 50, y)
    doc.setFont('helvetica', 'normal')
    doc.text(ascii(value), 210, y)
    y += 24
  }
  row('Receipt no.:', String(r.receipt_number ?? ''))
  row('Date:', date)
  row('Customer:', email ?? 'Anonymous')
  row('Item:', itemLabel)
  row('Payment method:', String(r.payment_method ?? ''))
  if (r.transaction_id) row('Transaction ID:', String(r.transaction_id))

  y += 12
  doc.setDrawColor(216, 222, 219); doc.line(50, y, 545, y); y += 30
  doc.setFont('helvetica', 'bold'); doc.setFontSize(16)
  doc.setTextColor(45, 106, 79)
  doc.text('Total:', 50, y)
  doc.text(`${Number(r.amount_eur).toFixed(2)} ${r.currency}`, 210, y)

  doc.setTextColor(120, 120, 120)
  doc.setFont('helvetica', 'normal'); doc.setFontSize(9)
  doc.text(`${ascii(operator)} - cz.tuma.placesecrets`, 50, 800)
  doc.text('Tax details per operator configuration.', 50, 814)

  const pdfBytes = new Uint8Array(doc.output('arraybuffer'))
  const path = `${r.user_id}/${r.receipt_number}.pdf`

  const { error: upErr } = await supabase.storage.from('payment-receipts')
    .upload(path, pdfBytes, { contentType: 'application/pdf', upsert: true })
  if (upErr) { console.error('receipt upload failed:', upErr.message); return null }

  const { data: signed } = await supabase.storage.from('payment-receipts')
    .createSignedUrl(path, 60 * 60 * 24 * 365)
  await supabase.from('payment_receipts')
    .update({ receipt_pdf_url: signed?.signedUrl }).eq('id', r.id)
  return signed?.signedUrl ?? null
}

export type ReceiptInput = {
  userId: string
  cityId?: string | null
  itemType: 'city' | 'poi' | 'city_premium' | 'country'
  itemLabel: string
  amountEur: number
  currency?: string
  paymentMethod: string
  transactionId?: string | null
}

/**
 * Inserts a payment_receipts row and generates its PDF. Best-effort: never
 * throws (a failed receipt must not roll back a confirmed purchase). Returns the
 * inserted row or null.
 */
export async function createReceipt(supabase: any, input: ReceiptInput): Promise<any | null> {
  try {
    const { data: row, error } = await supabase.from('payment_receipts').insert({
      user_id: input.userId,
      city_id: input.cityId ?? null,
      item_type: input.itemType,
      item_label: input.itemLabel,
      amount_eur: input.amountEur,
      currency: input.currency ?? 'EUR',
      payment_method: input.paymentMethod,
      transaction_id: input.transactionId ?? null,
      status: 'completed',
    }).select('*').single()
    if (error || !row) {
      console.error('createReceipt insert failed:', error?.message)
      return null
    }
    await generateReceiptPdf(supabase, row)
    return row
  } catch (e) {
    console.error('createReceipt error:', e)
    return null
  }
}
