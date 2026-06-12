import { useEffect, useState, useMemo, useCallback } from 'react'
import { Link } from 'react-router-dom'
import { useAuthStore } from '@/hooks/useAuth'
import { supabase } from '@/lib/supabase/client'
import { adminSelect } from '@/lib/supabase/admin-api'
import type { City, Country, Poi } from '@/lib/supabase/types'
import { Button } from '@/components/ui/button'
import { ActiveBadge } from '@/components/shared/StatusBadge'
import CityPoiTree from '@/components/shared/CityPoiTree'
import { Plus, Star, Search } from 'lucide-react'
import { useTranslation } from 'react-i18next'

type PoiWithCity = Poi & { city?: { id: string; name: string; country_code: string; price_eur: number; is_active: boolean; latitude: number; longitude: number; aliases: string[] } }

export default function MyPoisPage() {
  const { user } = useAuthStore()
  const [pois, setPois] = useState<PoiWithCity[]>([])
  const [countries, setCountries] = useState<Country[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState('')
  const [search, setSearch] = useState('')
  const [searchInput, setSearchInput] = useState('')
  const { t } = useTranslation()

  // Debounce search
  useEffect(() => {
    const timer = setTimeout(() => setSearch(searchInput), 200)
    return () => clearTimeout(timer)
  }, [searchInput])

  useEffect(() => {
    if (!user) return
    let cancelled = false
    Promise.all([
      supabase
        .from('pois')
        .select('*, city:cities(id, name, country_code, price_eur, is_active, latitude, longitude, aliases)')
        .eq('contributor_id', user.id)
        .order('created_at', { ascending: false }),
      adminSelect('countries', { order: { column: 'name' } }),
    ]).then(([poisRes, countriesRes]) => {
      if (cancelled) return
      const errors: string[] = []
      if (poisRes.error) errors.push(poisRes.error.message)
      if (countriesRes.error) errors.push(countriesRes.error)
      if (errors.length) setError(errors.join('; '))
      if (poisRes.data) setPois(poisRes.data as PoiWithCity[])
      if (countriesRes.data) setCountries(countriesRes.data as Country[])
      setLoading(false)
    })
    return () => { cancelled = true }
  }, [user])

  // Derive cities and poisByCity from POIs data
  const { cities, poisByCity } = useMemo(() => {
    const cityMap = new Map<string, City>()
    const poisMap: Record<string, Poi[]> = {}

    pois.forEach(poi => {
      if (poi.city) {
        const c = poi.city
        if (!cityMap.has(c.id)) {
          cityMap.set(c.id, {
            id: c.id,
            name: c.name,
            country_code: c.country_code,
            price_eur: c.price_eur,
            is_active: c.is_active,
            latitude: c.latitude,
            longitude: c.longitude,
            aliases: c.aliases || [],
            bounding_box_radius_km: 0,
            slug: null,
            registered_sample_poi_id: null,
            premium_bundle_price: null,
            created_at: '',
            updated_at: '',
          } as City)
        }
        if (!poisMap[c.id]) poisMap[c.id] = []
        poisMap[c.id].push(poi)
      }
    })

    return {
      cities: Array.from(cityMap.values()),
      poisByCity: poisMap,
    }
  }, [pois])

  const renderPoiRow = useCallback((poi: Poi, _city: City) => (
    <div className="flex items-center gap-2 pl-12 pr-4 py-1.5 text-sm border-b border-dashed hover:bg-accent/20 transition-colors">
      <Link
        to={`/admin/my-pois/${poi.id}`}
        className="flex-1 truncate text-primary hover:underline"
      >
        {poi.name?.cs || poi.name?.en || '—'}
      </Link>
      {poi.avg_rating != null && (
        <span className="flex items-center gap-1 text-xs text-muted-foreground">
          <Star className="h-3 w-3 fill-gold text-gold" />
          {Number(poi.avg_rating).toFixed(1)}
        </span>
      )}
      <ActiveBadge active={poi.is_active} />
      <Link to={`/admin/my-pois/${poi.id}`}>
        <Button variant="outline" size="sm">{t('common.edit')}</Button>
      </Link>
    </div>
  ), [t])

  if (loading) return <p>{t('common.loading')}</p>
  if (error) return <p className="text-destructive">{error}</p>

  return (
    <div className="space-y-4">
      {/* Header */}
      <div className="flex items-center justify-between gap-4 shrink-0">
        <h1 className="text-xl font-semibold">{t('admin.myPois.title', 'My Places')}</h1>
        <div className="flex items-center gap-2">
          <div className="relative max-w-sm">
            <Search className="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-muted-foreground" />
            <input
              type="text"
              value={searchInput}
              onChange={e => setSearchInput(e.target.value)}
              placeholder={t('admin.myPois.searchPlaceholder', 'Search places...')}
              className="w-full rounded-md border border-input bg-background pl-9 pr-3 py-2 text-sm ring-offset-background placeholder:text-muted-foreground focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring"
            />
          </div>
          <Link to="/admin/my-pois/new">
            <Button><Plus className="h-4 w-4 mr-1" /> {t('admin.myPois.addNew', 'New Place')}</Button>
          </Link>
        </div>
      </div>

      {/* Tree */}
      {pois.length === 0 ? (
        <p className="text-sm text-muted-foreground">{t('admin.myPois.noPois')}</p>
      ) : (
        <CityPoiTree
          cities={cities}
          countries={countries}
          poisByCity={poisByCity}
          search={search}
          renderPoiRow={renderPoiRow}
          className="max-h-[calc(100vh-14rem)]"
        />
      )}
    </div>
  )
}
