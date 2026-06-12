import { useEffect, useState, useMemo, useCallback } from 'react'
import { Link } from 'react-router-dom'
import { useTranslation } from 'react-i18next'
import { adminSelect } from '@/lib/supabase/admin-api'
import type { City, Country, Poi } from '@/lib/supabase/types'
import { ActiveBadge } from '@/components/shared/StatusBadge'
import { CitiesMap } from '@/components/cities/CitiesMap'
import CityPoiTree from '@/components/shared/CityPoiTree'
import { Button } from '@/components/ui/button'
import { Plus, ChevronDown, ChevronUp, Search, Map, Globe, Check, X } from 'lucide-react'
import { useAuthStore } from '@/hooks/useAuth'
import { adminInsert } from '@/lib/supabase/admin-api'
import { TagInput } from '@/components/shared/TagInput'
import { toast } from 'sonner'

export default function CitiesPage() {
  const { t } = useTranslation()
  const { hasPermission } = useAuthStore()
  const canWrite = hasPermission('cities', 'write')

  const [cities, setCities] = useState<City[]>([])
  const [countries, setCountries] = useState<Country[]>([])
  const [allPois, setAllPois] = useState<Poi[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState('')
  const [showMap, setShowMap] = useState(true)
  const [search, setSearch] = useState('')
  const [searchInput, setSearchInput] = useState('')
  const [showNewCountry, setShowNewCountry] = useState(false)
  const [newCountryCode, setNewCountryCode] = useState('')
  const [newCountryName, setNewCountryName] = useState('')
  const [newCountryAliases, setNewCountryAliases] = useState<string[]>([])
  const [savingCountry, setSavingCountry] = useState(false)

  // Debounce search
  useEffect(() => {
    const timer = setTimeout(() => setSearch(searchInput), 200)
    return () => clearTimeout(timer)
  }, [searchInput])

  // Load cities + countries + all POIs in parallel
  useEffect(() => {
    let cancelled = false
    Promise.all([
      adminSelect('cities', { order: { column: 'name' } }),
      adminSelect('countries', { order: { column: 'name' } }),
      adminSelect('pois', {
        select: 'id, name, city_id, is_active, access_level, type_id, sort_order, aliases',
        order: { column: 'sort_order' },
      }),
    ]).then(([citiesRes, countriesRes, poisRes]) => {
      if (cancelled) return
      const errors: string[] = []
      if (citiesRes.error) errors.push(citiesRes.error)
      if (countriesRes.error) errors.push(countriesRes.error)
      if (poisRes.error) errors.push(poisRes.error)
      if (errors.length) setError(errors.join('; '))
      if (citiesRes.data) setCities(citiesRes.data as City[])
      if (countriesRes.data) setCountries(countriesRes.data as Country[])
      if (poisRes.data) setAllPois(poisRes.data as Poi[])
      setLoading(false)
    })
    return () => { cancelled = true }
  }, [])

  const poisByCity = useMemo(() => {
    const map: Record<string, Poi[]> = {}
    allPois.forEach(p => {
      if (!map[p.city_id]) map[p.city_id] = []
      map[p.city_id].push(p)
    })
    return map
  }, [allPois])

  async function handleCreateCountry() {
    const code = newCountryCode.trim().toUpperCase()
    const name = newCountryName.trim()
    if (!code || code.length !== 2 || !name) return
    setSavingCountry(true)
    const { error: err } = await adminInsert('countries', {
      code,
      name,
      aliases: newCountryAliases,
    })
    setSavingCountry(false)
    if (err) {
      toast.error(err)
    } else {
      toast.success(t('admin.cities.countryCreated'))
      setCountries(prev => [...prev, { code, name, aliases: newCountryAliases, created_at: '', updated_at: '' }])
      setShowNewCountry(false)
      setNewCountryCode('')
      setNewCountryName('')
      setNewCountryAliases([])
    }
  }

  const handleCountryUpdated = useCallback((updated: Country) => {
    setCountries(prev => prev.map(c => c.code === updated.code ? { ...c, name: updated.name, aliases: updated.aliases } : c))
  }, [])

  const renderCityActions = useCallback((city: City) => (
    <>
      <span className="text-sm text-muted-foreground whitespace-nowrap">
        {Number(city.price_eur).toFixed(2)} EUR
      </span>
      <ActiveBadge active={city.is_active} />
      <div className="flex items-center gap-1 shrink-0">
        <Link to={`/admin/cities/${city.id}/pois`}>
          <Button variant="ghost" size="sm">{t('admin.cities.managePois')}</Button>
        </Link>
        {canWrite && (
          <Link to={`/admin/cities/${city.id}`}>
            <Button variant="outline" size="sm">{t('common.edit')}</Button>
          </Link>
        )}
      </div>
    </>
  ), [canWrite, t])

  const renderPoiRow = useCallback((poi: Poi, city: City) => (
    <div className="flex items-center gap-2 pl-12 pr-4 py-1.5 text-sm border-b border-dashed hover:bg-accent/20 transition-colors">
      <Link
        to={`/admin/cities/${city.id}/pois/${poi.id}`}
        className="flex-1 truncate text-primary hover:underline"
      >
        {poi.name?.cs || poi.name?.en || Object.values(poi.name || {})[0] || '—'}
        {(poi.aliases || []).length > 0 && (
          <span className="text-muted-foreground font-normal"> ({(poi.aliases || []).slice(0, 3).join(', ')}{(poi.aliases || []).length > 3 ? ', …' : ''})</span>
        )}
      </Link>
      <span className="text-xs px-1.5 py-0.5 rounded bg-muted text-muted-foreground">
        {poi.access_level}
      </span>
      <ActiveBadge active={poi.is_active} />
    </div>
  ), [])

  if (loading) return <p>{t('common.loading')}</p>
  if (error) return <p className="text-destructive">{error}</p>

  return (
    <div className="space-y-4">
      {/* Header */}
      <div className="flex justify-between items-center gap-4 shrink-0">
        <div className="relative flex-1 max-w-sm">
          <Search className="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-muted-foreground" />
          <input
            type="text"
            value={searchInput}
            onChange={e => setSearchInput(e.target.value)}
            placeholder={t('admin.cities.searchAll', 'Search countries, cities, places...')}
            className="w-full rounded-md border border-input bg-background pl-9 pr-3 py-2 text-sm ring-offset-background placeholder:text-muted-foreground focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring"
          />
        </div>
        <div className="flex items-center gap-2">
          <Button variant="outline" size="sm" onClick={() => setShowMap(!showMap)} className="gap-1">
            <Map className="h-4 w-4" />
            {showMap ? <ChevronUp className="h-3 w-3" /> : <ChevronDown className="h-3 w-3" />}
          </Button>
          {canWrite && (
            <>
              <Button onClick={() => setShowNewCountry(!showNewCountry)}>
                <Globe className="h-4 w-4 mr-1" /> {t('admin.cities.addCountry', '+ New Country')}
              </Button>
              <Link to="/admin/cities/new">
                <Button><Plus className="h-4 w-4 mr-1" /> {t('admin.cities.addCity')}</Button>
              </Link>
            </>
          )}
        </div>
      </div>

      {/* Collapsible map */}
      {showMap && (
        <div className="shrink-0">
          <CitiesMap cities={cities} />
        </div>
      )}

      {/* New Country inline form */}
      {showNewCountry && (
        <div className="rounded-md border bg-card p-4 space-y-3">
          <h3 className="text-sm font-semibold">{t('admin.cities.addCountry', '+ New Country')}</h3>
          <div className="flex items-center gap-3">
            <div className="flex items-center gap-2">
              <label className="text-xs font-medium text-muted-foreground shrink-0">{t('admin.cities.countryCode')}</label>
              <input
                type="text"
                value={newCountryCode}
                onChange={e => setNewCountryCode(e.target.value.toUpperCase().slice(0, 2))}
                placeholder={t('admin.cities.countryCodePlaceholder')}
                maxLength={2}
                className="w-16 rounded-md border border-input bg-background px-2 py-1 text-sm uppercase"
                autoFocus
              />
            </div>
            <div className="flex items-center gap-2 flex-1">
              <label className="text-xs font-medium text-muted-foreground shrink-0">{t('admin.cities.countryName')}</label>
              <input
                type="text"
                value={newCountryName}
                onChange={e => setNewCountryName(e.target.value)}
                placeholder={t('admin.cities.countryNamePlaceholder')}
                className="flex-1 rounded-md border border-input bg-background px-2 py-1 text-sm"
                onKeyDown={e => {
                  if (e.key === 'Enter') { e.preventDefault(); handleCreateCountry() }
                  if (e.key === 'Escape') setShowNewCountry(false)
                }}
              />
            </div>
          </div>
          <div className="flex items-start gap-2">
            <label className="text-xs font-medium text-muted-foreground shrink-0 pt-2">{t('admin.cities.countryAliases')}</label>
            <div className="flex-1">
              <TagInput value={newCountryAliases} onChange={setNewCountryAliases} placeholder={t('admin.cities.countryAliasesPlaceholder')} />
            </div>
          </div>
          <div className="flex items-center gap-2">
            <Button
              size="sm"
              onClick={handleCreateCountry}
              disabled={savingCountry || newCountryCode.trim().length !== 2 || !newCountryName.trim()}
            >
              <Check className="h-3 w-3 mr-1" /> {savingCountry ? t('common.loading') : t('admin.cities.createCountry', 'Create')}
            </Button>
            <Button variant="outline" size="sm" onClick={() => setShowNewCountry(false)}>
              <X className="h-3 w-3 mr-1" /> {t('common.cancel')}
            </Button>
          </div>
        </div>
      )}

      {/* Tree */}
      <CityPoiTree
        cities={cities}
        countries={countries}
        poisByCity={poisByCity}
        search={search}
        renderCityActions={renderCityActions}
        renderPoiRow={renderPoiRow}
        onCountryUpdated={canWrite ? handleCountryUpdated : undefined}
        className="max-h-[calc(100vh-16rem)]"
      />
    </div>
  )
}
