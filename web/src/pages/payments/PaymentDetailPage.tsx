import { useEffect, useState } from 'react'
import { useParams } from 'react-router-dom'
import { useTranslation } from 'react-i18next'
import { adminSelect, adminUpdate } from '@/lib/supabase/admin-api'
import { supabase } from '@/lib/supabase/client'
import type { PaymentReceipt } from '@/lib/supabase/types'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Button } from '@/components/ui/button'
import { StatusBadge } from '@/components/shared/StatusBadge'
import { ConfirmDialog } from '@/components/shared/ConfirmDialog'
import { Skeleton } from '@/components/ui/skeleton'
import { format } from 'date-fns'
import { toast } from 'sonner'
import { useAuthStore } from '@/hooks/useAuth'
import { RefreshCw, Mail } from 'lucide-react'

export default function PaymentDetailPage() {
  const { t } = useTranslation()
  const { id } = useParams<{ id: string }>()
  const { hasPermission } = useAuthStore()
  const [receipt, setReceipt] = useState<(PaymentReceipt & { city?: { name: string } }) | null>(null)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState('')
  const [refunding, setRefunding] = useState(false)
  const [regenerating, setRegenerating] = useState(false)
  const [emailing, setEmailing] = useState(false)

  async function loadReceipt() {
    if (!id) return
    const { data, error: err } = await adminSelect('payment_receipts', {
      select: '*, city:cities(name)',
      filters: [{ column: 'id', op: 'eq', value: id }],
      single: true,
    })
    if (err) setError(err)
    else setReceipt(data as typeof receipt)
    setLoading(false)
  }

  useEffect(() => { loadReceipt() }, [id])

  async function confirmPayment() {
    if (!id) return
    const { error } = await adminUpdate('payment_receipts', {
      status: 'completed',
      confirmed_at: new Date().toISOString(),
    }, [{ column: 'id', op: 'eq', value: id }])
    if (error) toast.error(error)
    else { toast.success(t('paymentsPage.paymentConfirmed')); loadReceipt() }
  }

  async function refundPayment() {
    if (!id) return
    setRefunding(true)
    const { error: fnError } = await supabase.functions.invoke('stripe-refund', {
      body: { payment_id: id },
    })
    if (fnError) {
      toast.error(`Refund failed: ${fnError.message}`)
      setRefunding(false)
      return
    }
    const { error } = await adminUpdate('payment_receipts', {
      status: 'refunded',
    }, [{ column: 'id', op: 'eq', value: id }])
    setRefunding(false)
    if (error) toast.error(error)
    else { toast.success(t('paymentsPage.paymentRefunded')); loadReceipt() }
  }

  async function regenerateReceipt() {
    if (!id) return
    setRegenerating(true)
    const { error: fnError } = await supabase.functions.invoke('generate-receipt', {
      body: { payment_id: id },
    })
    setRegenerating(false)
    if (fnError) toast.error(`Receipt generation failed: ${fnError.message}`)
    else { toast.success(t('paymentsPage.receiptRegenerated')); loadReceipt() }
  }

  async function emailReceipt() {
    if (!id) return
    setEmailing(true)
    const { error: fnError } = await supabase.functions.invoke('generate-receipt', {
      body: { payment_id: id, send_email: true },
    })
    setEmailing(false)
    if (fnError) toast.error(`Email failed: ${fnError.message}`)
    else toast.success(t('paymentsPage.receiptEmailed'))
  }

  if (loading) return <Skeleton className="h-64 max-w-2xl" />
  if (error) return <p className="text-destructive">{error}</p>
  if (!receipt) return <p>{t('paymentsPage.paymentNotFound')}</p>

  return (
    <div className="max-w-2xl space-y-6">
      <Card>
        <CardHeader>
          <div className="flex items-center justify-between">
            <CardTitle className="text-base font-mono">{receipt.receipt_number || t('paymentsPage.noReceiptNumber')}</CardTitle>
            <StatusBadge status={receipt.status} />
          </div>
        </CardHeader>
        <CardContent className="grid gap-2 text-sm">
          <div><span className="text-muted-foreground">{t('paymentsPage.city')}:</span> {receipt.city?.name}</div>
          <div><span className="text-muted-foreground">{t('paymentsPage.amount')}:</span> {Number(receipt.amount_eur).toFixed(2)} {receipt.currency}</div>
          <div><span className="text-muted-foreground">{t('paymentsPage.method')}:</span> {receipt.payment_method}</div>
          <div><span className="text-muted-foreground">{t('paymentsPage.date')}:</span> {format(new Date(receipt.purchased_at), 'dd.MM.yyyy HH:mm')}</div>
          {receipt.transaction_id && (
            <div><span className="text-muted-foreground">{t('paymentsPage.transactionId')}:</span> <span className="font-mono text-xs">{receipt.transaction_id}</span></div>
          )}
          {receipt.revolut_note && (
            <div><span className="text-muted-foreground">{t('paymentsPage.revolutNote')}:</span> {receipt.revolut_note}</div>
          )}
          {receipt.receipt_pdf_url && (
            <div>
              <a href={receipt.receipt_pdf_url} target="_blank" rel="noopener noreferrer" className="text-primary underline text-sm">
                {t('paymentsPage.downloadReceiptPdf')}
              </a>
            </div>
          )}
        </CardContent>
      </Card>

      {hasPermission('payments', 'write') && (
        <div className="flex flex-wrap gap-3">
          {receipt.status === 'pending' && (
            <ConfirmDialog
              trigger={<Button>{t('paymentsPage.confirmPayment')}</Button>}
              title={t('paymentsPage.confirmPaymentTitle')}
              description={t('paymentsPage.confirmPaymentDesc')}
              onConfirm={confirmPayment}
              confirmLabel="Confirm"
            />
          )}
          {receipt.status === 'completed' && (
            <ConfirmDialog
              trigger={<Button variant="destructive" disabled={refunding}>{refunding ? t('paymentsPage.refunding') : t('paymentsPage.refundPayment')}</Button>}
              title={t('paymentsPage.refundTitle')}
              description={t('paymentsPage.refundDesc')}
              onConfirm={refundPayment}
              confirmLabel="Refund"
              destructive
            />
          )}
          {receipt.status === 'completed' && (
            <>
              <Button variant="outline" onClick={regenerateReceipt} disabled={regenerating}>
                <RefreshCw className={`h-4 w-4 mr-1 ${regenerating ? 'animate-spin' : ''}`} />
                {regenerating ? t('paymentsPage.generating') : t('paymentsPage.regenerateReceipt')}
              </Button>
              <Button variant="outline" onClick={emailReceipt} disabled={emailing}>
                <Mail className={`h-4 w-4 mr-1`} />
                {emailing ? t('paymentsPage.sending') : t('paymentsPage.emailReceipt')}
              </Button>
            </>
          )}
        </div>
      )}
    </div>
  )
}
