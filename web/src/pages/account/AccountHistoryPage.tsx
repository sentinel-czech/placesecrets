import { useEffect, useState } from 'react'
import { useAuthStore } from '@/hooks/useAuth'
import { supabase } from '@/lib/supabase/client'
import { useTranslation } from 'react-i18next'
import { Card, CardContent } from '@/components/ui/card'
import { MapPin } from 'lucide-react'
import { StatsMap } from '@/components/account/StatsMap'
import { PoiTypeFilter } from '@/components/account/PoiTypeFilter'
import { VisitExport } from '@/components/account/VisitExport'
import type { PoiType } from '@/lib/supabase/types'
import { format, subDays } from 'date-fns'

interface VisitRecord {
  id: string
  poi_id: string
  poi_name: string
  latitude: number
  longitude: number
  visited_at: string
  color_hex: string
  type_id: string | null
  poi_type: string
  city_slug: string | null
  poi_slug: string | null
  country_code: string | null
}

type TimePeriod = 'all' | '30d' | '7d' | 'custom'

export default function AccountHistoryPage() {
  const { user } = useAuthStore()
  const { t } = useTranslation()

  const [visits, setVisits] = useState<VisitRecord[]>([])
  const [poiTypes, setPoiTypes] = useState<PoiType[]>([])
  const [selectedTypes, setSelectedTypes] = useState<Set<string>>(new Set())
  const [timePeriod, setTimePeriod] = useState<TimePeriod>('all')
  const [dateFrom, setDateFrom] = useState('')
  const [dateTo, setDateTo] = useState('')
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    async function loadTypes() {
      const { data: types } = await supabase
        .from('poi_types')
        .select('*')
        .eq('is_active', true)
        .order('sort_order')
      if (types) setPoiTypes(types as PoiType[])
      setLoading(false)
    }
    loadTypes()
  }, [])

  useEffect(() => {
    if (!user) return
    let cancelled = false
    let query = supabase
      .from('free_visit_log')
      .select('id, poi_id, visited_at, pois(name, latitude, longitude, slug, type_id, cities(slug, country_code), poi_types:type_id(color_hex, name))')
      .eq('user_id', user.id)
      .order('visited_at', { ascending: false })

    if (timePeriod === '30d') {
      query = query.gte('visited_at', subDays(new Date(), 30).toISOString())
    } else if (timePeriod === '7d') {
      query = query.gte('visited_at', subDays(new Date(), 7).toISOString())
    } else if (timePeriod === 'custom') {
      if (dateFrom) query = query.gte('visited_at', new Date(dateFrom).toISOString())
      if (dateTo) {
        const end = new Date(dateTo)
        end.setHours(23, 59, 59, 999)
        query = query.lte('visited_at', end.toISOString())
      }
    }

    query.then(({ data }) => {
      if (cancelled) return
      if (data) {
        setVisits(data.map((row: Record<string, unknown>) => {
          const poi = row.pois as Record<string, unknown> | null
          const poiType = poi?.poi_types as Record<string, unknown> | null
          const city = poi?.cities as Record<string, string> | null
          return {
            id: row.id as string,
            poi_id: row.poi_id as string,
            poi_name: (poi?.name as Record<string, string>)?.cs || (poi?.name as Record<string, string>)?.en || '',
            latitude: (poi?.latitude as number) || 0,
            longitude: (poi?.longitude as number) || 0,
            visited_at: row.visited_at as string,
            color_hex: (poiType?.color_hex as string) || '#2D6A4F',
            type_id: (poi?.type_id as string) || null,
            poi_type: (poiType?.name as Record<string, string>)?.en || '',
            city_slug: city?.slug || null,
            poi_slug: (poi?.slug as string) || null,
            country_code: city?.country_code || null,
          }
        }))
      }
    })
    return () => { cancelled = true }
  }, [user, timePeriod, dateFrom, dateTo])

  const filteredVisits = selectedTypes.size > 0
    ? visits.filter(v => v.type_id && selectedTypes.has(v.type_id))
    : visits

  const exportRows = filteredVisits.map(v => ({
    poi_name: v.poi_name,
    latitude: v.latitude,
    longitude: v.longitude,
    visited_at: format(new Date(v.visited_at), 'yyyy-MM-dd'),
    visited_time: format(new Date(v.visited_at), 'HH:mm'),
    poi_type: v.poi_type,
  }))

  return (
    <div className="space-y-6">
      <h1 className="text-2xl font-bold">{t('user.history.title')}</h1>

      <div className="flex flex-wrap items-center gap-4">
        <div className="flex gap-1 rounded-lg bg-muted p-1">
          {([
            { value: 'all', label: t('user.dashboard.stats.allTime') },
            { value: '30d', label: t('user.dashboard.stats.last30d') },
            { value: '7d', label: t('user.dashboard.stats.last7d') },
            { value: 'custom', label: t('user.history.customRange') },
          ] as { value: TimePeriod; label: string }[]).map(opt => (
            <button
              key={opt.value}
              onClick={() => setTimePeriod(opt.value)}
              className={`rounded-md px-3 py-1 text-xs font-medium transition-colors ${
                timePeriod === opt.value
                  ? 'bg-background shadow text-foreground'
                  : 'text-muted-foreground hover:text-foreground'
              }`}
            >
              {opt.label}
            </button>
          ))}
        </div>

        {timePeriod === 'custom' && (
          <div className="flex items-center gap-2">
            <label className="text-xs text-muted-foreground">{t('user.history.dateFrom')}</label>
            <input
              type="date"
              value={dateFrom}
              onChange={e => setDateFrom(e.target.value)}
              className="rounded-md border border-input bg-background px-2 py-1 text-sm"
            />
            <label className="text-xs text-muted-foreground">{t('user.history.dateTo')}</label>
            <input
              type="date"
              value={dateTo}
              onChange={e => setDateTo(e.target.value)}
              className="rounded-md border border-input bg-background px-2 py-1 text-sm"
            />
          </div>
        )}

        <VisitExport visits={exportRows} />
      </div>

      <PoiTypeFilter types={poiTypes} selected={selectedTypes} onChange={setSelectedTypes} />

      {loading ? (
        <p className="text-muted-foreground">{t('common.loading')}</p>
      ) : filteredVisits.length === 0 ? (
        <Card>
          <CardContent className="py-12 text-center">
            <MapPin className="h-12 w-12 mx-auto mb-4 text-muted-foreground" />
            <p className="text-lg font-medium">{t('user.dashboard.stats.noVisits')}</p>
          </CardContent>
        </Card>
      ) : (
        <StatsMap visits={filteredVisits} />
      )}
    </div>
  )
}
