import { useEffect, useState } from 'react'
import { useTranslation } from 'react-i18next'
import { adminSelect } from '@/lib/supabase/admin-api'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { DataTable } from '@/components/shared/DataTable'
import { Badge } from '@/components/ui/badge'
import type { UserAllPurchase } from '@/lib/supabase/types'
import type { ColumnDef } from '@tanstack/react-table'
import { format } from 'date-fns'

const TYPE_VARIANTS: Record<string, 'default' | 'secondary' | 'outline'> = {
  poi: 'default',
  city_premium: 'secondary',
  city_access: 'outline',
}

export default function PurchasesOverviewPage() {
  const { t } = useTranslation()

  const TYPE_LABELS: Record<string, string> = {
    poi: t('purchasesPage.typePoi'),
    city_premium: t('purchasesPage.typeCityPremium'),
    city_access: t('purchasesPage.typeCityAccess'),
  }
  const [purchases, setPurchases] = useState<UserAllPurchase[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState('')

  useEffect(() => {
    adminSelect('user_all_purchases', {
      order: { column: 'purchased_at', ascending: false },
    }).then(({ data, error: err }) => {
      if (err) setError(err)
      else setPurchases(data as UserAllPurchase[])
      setLoading(false)
    })
  }, [])

  const totalRevenue = purchases.reduce((sum, p) => sum + (p.price_paid || 0), 0)
  const poiCount = purchases.filter(p => p.purchase_type === 'poi').length
  const bundleCount = purchases.filter(p => p.purchase_type === 'city_premium').length
  const accessCount = purchases.filter(p => p.purchase_type === 'city_access').length

  const columns: ColumnDef<UserAllPurchase>[] = [
    {
      accessorKey: 'purchased_at',
      header: t('purchasesPage.colDate'),
      cell: ({ row }) => format(new Date(row.original.purchased_at), 'dd.MM.yyyy HH:mm'),
    },
    {
      accessorKey: 'purchase_type',
      header: t('purchasesPage.colType'),
      cell: ({ row }) => (
        <Badge variant={TYPE_VARIANTS[row.original.purchase_type] || 'outline'}>
          {TYPE_LABELS[row.original.purchase_type] || row.original.purchase_type}
        </Badge>
      ),
    },
    {
      accessorKey: 'item_name',
      header: t('purchasesPage.colItem'),
    },
    {
      accessorKey: 'city_name',
      header: t('purchasesPage.colCity'),
    },
    {
      accessorKey: 'price_paid',
      header: t('purchasesPage.colPrice'),
      cell: ({ row }) => row.original.price_paid != null ? `€${Number(row.original.price_paid).toFixed(2)}` : '—',
    },
  ]

  if (loading) return <p>{t('common.loading')}</p>
  if (error) return <p className="text-destructive">{error}</p>

  return (
    <div className="space-y-6">
      <h2 className="text-lg font-semibold">{t('purchasesPage.title')}</h2>

      <div className="grid gap-4 md:grid-cols-4">
        <Card>
          <CardHeader className="pb-2"><CardTitle className="text-sm text-muted-foreground">{t('purchasesPage.totalRevenue')}</CardTitle></CardHeader>
          <CardContent><p className="text-2xl font-bold">€{totalRevenue.toFixed(2)}</p></CardContent>
        </Card>
        <Card>
          <CardHeader className="pb-2"><CardTitle className="text-sm text-muted-foreground">{t('purchasesPage.poiPurchases')}</CardTitle></CardHeader>
          <CardContent><p className="text-2xl font-bold">{poiCount}</p></CardContent>
        </Card>
        <Card>
          <CardHeader className="pb-2"><CardTitle className="text-sm text-muted-foreground">{t('purchasesPage.premiumBundles')}</CardTitle></CardHeader>
          <CardContent><p className="text-2xl font-bold">{bundleCount}</p></CardContent>
        </Card>
        <Card>
          <CardHeader className="pb-2"><CardTitle className="text-sm text-muted-foreground">{t('purchasesPage.cityAccess')}</CardTitle></CardHeader>
          <CardContent><p className="text-2xl font-bold">{accessCount}</p></CardContent>
        </Card>
      </div>

      <DataTable columns={columns} data={purchases} searchColumn="item_name" searchPlaceholder={t('purchasesPage.searchPlaceholder')} />
    </div>
  )
}
