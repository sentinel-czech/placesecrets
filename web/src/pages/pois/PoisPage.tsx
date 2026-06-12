import { useEffect, useState } from 'react'
import { Link, useParams } from 'react-router-dom'
import { useTranslation } from 'react-i18next'
import { adminSelect } from '@/lib/supabase/admin-api'
import type { Poi, City } from '@/lib/supabase/types'
import { DataTable } from '@/components/shared/DataTable'
import { ActiveBadge } from '@/components/shared/StatusBadge'
import { Button } from '@/components/ui/button'
import { Plus, Star } from 'lucide-react'
import { Badge } from '@/components/ui/badge'
import type { PoiAccessLevel } from '@/lib/supabase/types'

const ACCESS_LEVEL_VARIANTS: Record<PoiAccessLevel, 'default' | 'secondary' | 'outline'> = {
  public: 'outline',
  registered: 'secondary',
  city_access: 'default',
  premium_poi: 'default',
}
import type { ColumnDef } from '@tanstack/react-table'
import { useAuthStore } from '@/hooks/useAuth'

export default function PoisPage() {
  const { t } = useTranslation()
  const { hasPermission } = useAuthStore()

  const ACCESS_LEVEL_LABELS: Record<PoiAccessLevel, string> = {
    public: t('poisPage.accessPublic'),
    registered: t('poisPage.accessRegistered'),
    city_access: t('poisPage.accessCityAccess'),
    premium_poi: t('poisPage.accessPremium'),
  }
  const canWrite = hasPermission('pois', 'write')
  const { cityId } = useParams<{ cityId: string }>()
  const [pois, setPois] = useState<Poi[]>([])
  const [city, setCity] = useState<City | null>(null)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState('')
  const [accessFilter, setAccessFilter] = useState<PoiAccessLevel | 'all'>('all')

  useEffect(() => {
    if (!cityId) return
    let cancelled = false
    Promise.all([
      adminSelect('cities', { filters: [{ column: 'id', op: 'eq', value: cityId }], single: true }),
      adminSelect('pois', {
        select: '*, poi_type:poi_types(*)',
        filters: [{ column: 'city_id', op: 'eq', value: cityId }],
        order: { column: 'sort_order' },
      }),
    ]).then(([cityRes, poisRes]) => {
      if (cancelled) return
      if (cityRes.data) setCity(cityRes.data as City)
      if (poisRes.data) setPois(poisRes.data as Poi[])
      if (cityRes.error || poisRes.error) setError(cityRes.error || poisRes.error || '')
      setLoading(false)
    })
    return () => { cancelled = true }
  }, [cityId])

  const columns: ColumnDef<Poi>[] = [
    { accessorKey: 'sort_order', header: '#', cell: ({ row }) => row.original.sort_order },
    {
      accessorKey: 'name',
      header: t('poisPage.colName'),
      cell: ({ row }) => row.original.name?.cs || row.original.name?.en || '—',
    },
    {
      id: 'type',
      header: t('poisPage.colType'),
      cell: ({ row }) => {
        const pt = row.original.poi_type
        return pt ? (pt.name?.cs || pt.name?.en || pt.slug) : '—'
      },
    },
    {
      id: 'rating',
      header: t('poisPage.colRating'),
      cell: ({ row }) => row.original.avg_rating ? (
        <span className="flex items-center gap-1">
          <Star className="h-3 w-3 fill-gold text-gold" />
          {Number(row.original.avg_rating).toFixed(1)} ({row.original.total_ratings})
        </span>
      ) : '—',
    },
    {
      id: 'access_level',
      header: t('poisPage.colAccess'),
      cell: ({ row }) => {
        const level = row.original.access_level || 'city_access'
        return (
          <Badge variant={ACCESS_LEVEL_VARIANTS[level as PoiAccessLevel] || 'outline'}>
            {ACCESS_LEVEL_LABELS[level as PoiAccessLevel] || level}
          </Badge>
        )
      },
    },
    {
      accessorKey: 'is_active',
      header: t('poisPage.colStatus'),
      cell: ({ row }) => <ActiveBadge active={row.original.is_active} />,
    },
    ...(canWrite ? [{
      id: 'actions',
      cell: ({ row }: { row: { original: Poi } }) => (
        <Link to={`/admin/cities/${cityId}/pois/${row.original.id}`}>
          <Button variant="outline" size="sm">{t('common.edit')}</Button>
        </Link>
      ),
    }] : []),
  ]

  if (loading) return <p>{t('common.loading')}</p>
  if (error) return <p className="text-destructive">{error}</p>

  return (
    <div className="space-y-4">
      <div className="flex items-center justify-between">
        <h2 className="text-lg font-semibold">{t('poisPage.title', { city: city?.name })}</h2>
        <div className="flex gap-2">
          <Link to={`/admin/cities/${cityId}/pricing`}>
            <Button variant="outline">{t('poisPage.pricing')}</Button>
          </Link>
          {canWrite && (
            <Link to={`/admin/cities/${cityId}/pois/new`}>
              <Button><Plus className="h-4 w-4 mr-1" /> {t('poisPage.newPoi')}</Button>
            </Link>
          )}
        </div>
      </div>

      <div className="flex gap-2 flex-wrap">
        {(['all', 'public', 'registered', 'city_access', 'premium_poi'] as const).map(level => (
          <button
            key={level}
            onClick={() => setAccessFilter(level)}
            className={`px-3 py-1 rounded-full text-xs font-medium border transition-colors ${
              accessFilter === level
                ? 'bg-primary text-primary-foreground border-primary'
                : 'bg-background hover:bg-accent border-border'
            }`}
          >
            {level === 'all' ? t('poisPage.all') : ACCESS_LEVEL_LABELS[level]}
          </button>
        ))}
      </div>

      <DataTable
        columns={columns}
        data={accessFilter === 'all' ? pois : pois.filter(p => (p.access_level || 'city_access') === accessFilter)}
        searchColumn="name"
        searchPlaceholder={t('poisPage.searchPlaceholder')}
      />
    </div>
  )
}
