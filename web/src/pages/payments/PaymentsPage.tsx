import { useEffect, useRef, useState } from 'react'
import { Link } from 'react-router-dom'
import { useTranslation } from 'react-i18next'
import { adminSelect } from '@/lib/supabase/admin-api'
import type { PaymentReceipt } from '@/lib/supabase/types'
import { DataTable } from '@/components/shared/DataTable'
import { StatusBadge } from '@/components/shared/StatusBadge'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { Download } from 'lucide-react'
import { format } from 'date-fns'
import type { ColumnDef } from '@tanstack/react-table'

export default function PaymentsPage() {
  const { t } = useTranslation()
  const [receipts, setReceipts] = useState<(PaymentReceipt & { city?: { name: string } })[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState('')
  const [filterStatus, setFilterStatus] = useState('')
  const [filterMethod, setFilterMethod] = useState('')
  const [filterFrom, setFilterFrom] = useState('')
  const [filterTo, setFilterTo] = useState('')
  const abortRef = useRef(0)

  async function loadReceipts() {
    const requestId = ++abortRef.current
    const filters: { column: string; op: string; value: unknown }[] = []
    if (filterStatus) filters.push({ column: 'status', op: 'eq', value: filterStatus })
    if (filterMethod) filters.push({ column: 'payment_method', op: 'eq', value: filterMethod })
    if (filterFrom) filters.push({ column: 'purchased_at', op: 'gte', value: filterFrom })
    if (filterTo) filters.push({ column: 'purchased_at', op: 'lte', value: filterTo + 'T23:59:59Z' })

    try {
      const { data, error: err } = await adminSelect('payment_receipts', {
        select: '*, city:cities(name)',
        filters: filters.length > 0 ? filters : undefined,
        order: { column: 'purchased_at', ascending: false },
      })
      if (requestId !== abortRef.current) return
      if (err) setError(err)
      else if (data) setReceipts(data as typeof receipts)
    } catch (err) {
      if (requestId !== abortRef.current) return
      setError(String(err))
    } finally {
      if (requestId === abortRef.current) setLoading(false)
    }
  }

  useEffect(() => { loadReceipts() }, [filterStatus, filterMethod, filterFrom, filterTo])

  function exportCsv() {
    const headers = ['Receipt #', 'Date', 'City', 'Amount EUR', 'Method', 'Status']
    const rows = receipts.map(r => [
      r.receipt_number || '',
      format(new Date(r.purchased_at), 'yyyy-MM-dd HH:mm'),
      r.city?.name || '',
      Number(r.amount_eur).toFixed(2),
      r.payment_method,
      r.status,
    ])
    const csv = [headers, ...rows].map(r => r.join(',')).join('\n')
    const blob = new Blob([csv], { type: 'text/csv' })
    const url = URL.createObjectURL(blob)
    const a = document.createElement('a')
    a.href = url
    a.download = `payments-${format(new Date(), 'yyyy-MM-dd')}.csv`
    a.click()
    URL.revokeObjectURL(url)
  }

  const columns: ColumnDef<typeof receipts[0]>[] = [
    {
      accessorKey: 'receipt_number',
      header: t('paymentsPage.receiptNumber'),
      cell: ({ row }) => <span className="font-mono text-xs">{row.original.receipt_number || '—'}</span>,
    },
    {
      accessorKey: 'purchased_at',
      header: t('paymentsPage.date'),
      cell: ({ row }) => format(new Date(row.original.purchased_at), 'dd.MM.yyyy HH:mm'),
    },
    { id: 'city', header: t('paymentsPage.city'), cell: ({ row }) => row.original.city?.name || '—' },
    {
      accessorKey: 'amount_eur',
      header: t('paymentsPage.amount'),
      cell: ({ row }) => `${Number(row.original.amount_eur).toFixed(2)} EUR`,
    },
    { accessorKey: 'payment_method', header: t('paymentsPage.method') },
    {
      accessorKey: 'status',
      header: t('paymentsPage.filterStatus'),
      cell: ({ row }) => <StatusBadge status={row.original.status} />,
    },
    {
      id: 'actions',
      cell: ({ row }) => (
        <Link to={`/admin/payments/${row.original.id}`}>
          <Button variant="outline" size="sm">{t('admin.users.detail')}</Button>
        </Link>
      ),
    },
  ]

  return (
    <div className="space-y-4">
      <div className="flex flex-wrap gap-3 items-end">
        <div className="space-y-1">
          <Label className="text-xs">{t('paymentsPage.filterStatus')}</Label>
          <select value={filterStatus} onChange={e => setFilterStatus(e.target.value)} className="rounded-md border px-3 py-2 text-sm" aria-label="Filter by status">
            <option value="">{t('paymentsPage.all')}</option>
            <option value="completed">{t('paymentsPage.completed')}</option>
            <option value="pending">{t('paymentsPage.pending')}</option>
            <option value="refunded">{t('paymentsPage.refunded')}</option>
            <option value="disputed">{t('paymentsPage.disputed')}</option>
          </select>
        </div>
        <div className="space-y-1">
          <Label className="text-xs">{t('paymentsPage.filterMethod')}</Label>
          <select value={filterMethod} onChange={e => setFilterMethod(e.target.value)} className="rounded-md border px-3 py-2 text-sm" aria-label="Filter by method">
            <option value="">{t('paymentsPage.all')}</option>
            <option value="stripe">{t('paymentsPage.stripe')}</option>
            <option value="revolut">{t('paymentsPage.revolut')}</option>
            <option value="google_pay">{t('paymentsPage.googlePay')}</option>
            <option value="apple_pay">{t('paymentsPage.applePay')}</option>
            <option value="admin_grant">{t('paymentsPage.adminGrant')}</option>
          </select>
        </div>
        <div className="space-y-1">
          <Label className="text-xs">{t('paymentsPage.filterFrom')}</Label>
          <Input type="date" value={filterFrom} onChange={e => setFilterFrom(e.target.value)} className="w-36" />
        </div>
        <div className="space-y-1">
          <Label className="text-xs">{t('paymentsPage.filterTo')}</Label>
          <Input type="date" value={filterTo} onChange={e => setFilterTo(e.target.value)} className="w-36" />
        </div>
        <Button variant="outline" onClick={exportCsv}>
          <Download className="h-4 w-4 mr-1" /> CSV
        </Button>
      </div>
      {error && <p className="text-destructive text-sm">{error}</p>}
      {loading ? <p>{t('common.loading')}</p> : <DataTable columns={columns} data={receipts} />}
    </div>
  )
}
