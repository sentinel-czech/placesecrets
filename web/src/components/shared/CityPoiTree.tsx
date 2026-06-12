import { useMemo, useState, useCallback, type ReactNode } from 'react'
import { ChevronDown, ChevronRight, Pencil, Check, X } from 'lucide-react'
import type { City, Country, Poi } from '@/lib/supabase/types'
import { useTranslation } from 'react-i18next'
import { removeDiacritics } from '@/lib/utils'
import { TagInput } from '@/components/shared/TagInput'
import { adminUpdate } from '@/lib/supabase/admin-api'
import { toast } from 'sonner'

export interface CityPoiTreeProps {
  cities: City[]
  countries: Country[]
  poisByCity: Record<string, Poi[]>
  search: string
  renderCityActions?: (city: City) => ReactNode
  renderPoiRow?: (poi: Poi, city: City) => ReactNode
  emptyMessage?: string
  className?: string
  onCountryUpdated?: (country: Country) => void
}

function getPoiDisplayName(poi: Poi): string {
  return poi.name?.cs || poi.name?.en || Object.values(poi.name || {})[0] || '—'
}

const norm = (s: string) => removeDiacritics(s).toLowerCase()

interface CountryGroup {
  country: Country
  cities: City[]
}

export default function CityPoiTree({
  cities,
  countries,
  poisByCity,
  search,
  renderCityActions,
  renderPoiRow,
  emptyMessage,
  className = '',
  onCountryUpdated,
}: CityPoiTreeProps) {
  const { t } = useTranslation()
  const [manualExpandedCountries, setManualExpandedCountries] = useState<Set<string>>(new Set())
  const [manualExpandedCities, setManualExpandedCities] = useState<Set<string>>(new Set())
  const [editingCountry, setEditingCountry] = useState<string | null>(null)
  const [editName, setEditName] = useState('')
  const [editAliases, setEditAliases] = useState<string[]>([])
  const [savingCountry, setSavingCountry] = useState(false)

  // Build country lookup
  const countryByCode = useMemo(() => {
    const map = new Map<string, Country>()
    countries.forEach(c => map.set(c.code, c))
    return map
  }, [countries])

  // Group cities by country_code, lookup Country object
  const allCountries = useMemo<CountryGroup[]>(() => {
    const map = new Map<string, City[]>()
    cities.forEach(c => {
      const list = map.get(c.country_code) || []
      list.push(c)
      map.set(c.country_code, list)
    })
    // Include countries that have no cities yet
    countries.forEach(c => {
      if (!map.has(c.code)) map.set(c.code, [])
    })
    return Array.from(map.entries())
      .map(([code, cs]) => {
        const country = countryByCode.get(code) || { code, name: code, aliases: [], created_at: '', updated_at: '' }
        return { country, cities: cs }
      })
      .sort((a, b) => a.country.name.localeCompare(b.country.name))
  }, [cities, countries, countryByCode])

  // Cross-level search filtering with diacritics normalization
  // Also tracks which cities were auto-expanded due to POI match vs city/country match
  const { filteredCountries, autoExpandedCountries, autoExpandedCities, poiMatchCities } = useMemo(() => {
    const ns = norm(search.trim())
    if (!ns) {
      return {
        filteredCountries: allCountries,
        autoExpandedCountries: new Set<string>(),
        autoExpandedCities: new Set<string>(),
        poiMatchCities: new Set<string>(),
      }
    }

    const expandCountries = new Set<string>()
    const expandCities = new Set<string>()
    const poiCities = new Set<string>()
    const result: CountryGroup[] = []

    for (const group of allCountries) {
      const countryMatch = norm(group.country.name).includes(ns) ||
        group.country.aliases.some(a => norm(a).includes(ns))
      const matchedCities: City[] = []

      for (const city of group.cities) {
        const cityMatch = norm(city.name).includes(ns) ||
          (city.aliases || []).some(a => norm(a).includes(ns))
        const cityPois = poisByCity[city.id] || []
        const poiMatch = cityPois.some(poi => {
          const names = Object.values(poi.name || {})
          return names.some(n => norm(n).includes(ns)) ||
            (poi.aliases || []).some(a => norm(a).includes(ns))
        })

        if (poiMatch) {
          matchedCities.push(city)
          expandCountries.add(group.country.code)
          expandCities.add(city.id)
          poiCities.add(city.id)
        } else if (cityMatch) {
          matchedCities.push(city)
          expandCountries.add(group.country.code)
          expandCities.add(city.id)
        } else if (countryMatch) {
          matchedCities.push(city)
        }
      }

      if (countryMatch && matchedCities.length === 0) {
        result.push(group)
      } else if (matchedCities.length > 0) {
        result.push({ ...group, cities: matchedCities })
      }
    }

    return {
      filteredCountries: result,
      autoExpandedCountries: expandCountries,
      autoExpandedCities: expandCities,
      poiMatchCities: poiCities,
    }
  }, [allCountries, poisByCity, search])

  const isCountryExpanded = useCallback(
    (code: string) => {
      if (search.trim()) return autoExpandedCountries.has(code) || manualExpandedCountries.has(code)
      return manualExpandedCountries.has(code)
    },
    [search, autoExpandedCountries, manualExpandedCountries]
  )

  const isCityExpanded = useCallback(
    (cityId: string) => {
      if (search.trim()) return autoExpandedCities.has(cityId) || manualExpandedCities.has(cityId)
      return manualExpandedCities.has(cityId)
    },
    [search, autoExpandedCities, manualExpandedCities]
  )

  function toggleCountry(code: string) {
    setManualExpandedCountries(prev => {
      const next = new Set(prev)
      if (next.has(code)) next.delete(code)
      else next.add(code)
      return next
    })
  }

  function toggleCity(cityId: string) {
    setManualExpandedCities(prev => {
      const next = new Set(prev)
      if (next.has(cityId)) next.delete(cityId)
      else next.add(cityId)
      return next
    })
  }

  // Filter POIs within a city when searching
  // Bug fix: only filter POIs when expansion was due to POI match, not city/country match
  function getVisiblePois(cityId: string): Poi[] {
    const pois = poisByCity[cityId] || []
    const ns = norm(search.trim())
    if (!ns) return pois
    // Only filter POIs when city was expanded because a POI matched
    if (poiMatchCities.has(cityId)) {
      return pois.filter(poi => {
        const names = Object.values(poi.name || {})
        return names.some(n => norm(n).includes(ns)) ||
          (poi.aliases || []).some(a => norm(a).includes(ns))
      })
    }
    // City or country name matched → show ALL POIs
    return pois
  }

  function startEditCountry(country: Country, e: React.MouseEvent) {
    e.stopPropagation()
    setEditingCountry(country.code)
    setEditName(country.name)
    setEditAliases([...country.aliases])
  }

  function cancelEditCountry() {
    setEditingCountry(null)
    setEditName('')
    setEditAliases([])
  }

  async function saveCountry() {
    if (!editingCountry || !editName.trim()) return
    setSavingCountry(true)
    const { error } = await adminUpdate('countries', {
      name: editName.trim(),
      aliases: editAliases,
    }, [{ column: 'code', op: 'eq', value: editingCountry }])
    setSavingCountry(false)
    if (error) {
      toast.error(error)
    } else {
      toast.success('Country updated')
      onCountryUpdated?.({
        code: editingCountry,
        name: editName.trim(),
        aliases: editAliases,
        created_at: '',
        updated_at: '',
      })
      setEditingCountry(null)
    }
  }

  return (
    <div className={`flex-1 min-h-0 overflow-y-auto rounded-md border bg-card ${className}`}>
      {filteredCountries.length === 0 && (
        <p className="px-4 py-6 text-center text-sm text-muted-foreground">
          {emptyMessage || t('common.noResults')}
        </p>
      )}

      {filteredCountries.map(({ country, cities: countryCities }) => {
        const expanded = isCountryExpanded(country.code)
        const totalPois = countryCities.reduce(
          (sum, c) => sum + (poisByCity[c.id]?.length || 0),
          0
        )
        const isEditing = editingCountry === country.code

        return (
          <div key={country.code}>
            {/* Level 1 — Country */}
            <div className="flex w-full items-center gap-2 px-4 py-2 font-semibold bg-muted/50 hover:bg-muted/80 transition-colors border-b">
              <button
                type="button"
                onClick={() => toggleCountry(country.code)}
                className="flex items-center gap-2 flex-1 text-left min-w-0"
              >
                {expanded
                  ? <ChevronDown className="h-4 w-4 shrink-0" />
                  : <ChevronRight className="h-4 w-4 shrink-0" />
                }
                <span>
                  <span className="text-muted-foreground font-normal">{country.code}</span>
                  {' '}{country.name}
                  {country.aliases.length > 0 && (
                    <span className="font-normal text-muted-foreground">
                      {' '}({country.aliases.slice(0, 3).join(', ')}{country.aliases.length > 3 ? ', …' : ''})
                    </span>
                  )}
                </span>
                <span className="text-sm font-normal text-muted-foreground">
                  ({countryCities.length}{totalPois > 0 ? ` · ${totalPois} ${t('admin.hallOfFame.places')}` : ''})
                </span>
              </button>
              {onCountryUpdated && !isEditing && (
                <button
                  type="button"
                  onClick={(e) => startEditCountry(country, e)}
                  className="p-1 rounded hover:bg-accent/50 text-muted-foreground hover:text-foreground transition-colors"
                  title="Edit country"
                >
                  <Pencil className="h-3.5 w-3.5" />
                </button>
              )}
            </div>

            {/* Inline country edit form */}
            {isEditing && (
              <div className="px-6 py-3 bg-muted/30 border-b space-y-2">
                <div className="flex items-center gap-2">
                  <label className="text-xs font-medium text-muted-foreground w-14 shrink-0">Name</label>
                  <input
                    type="text"
                    value={editName}
                    onChange={e => setEditName(e.target.value)}
                    className="flex-1 rounded-md border border-input bg-background px-2 py-1 text-sm"
                    autoFocus
                    onKeyDown={e => {
                      if (e.key === 'Enter') { e.preventDefault(); saveCountry() }
                      if (e.key === 'Escape') cancelEditCountry()
                    }}
                  />
                </div>
                <div className="flex items-start gap-2">
                  <label className="text-xs font-medium text-muted-foreground w-14 shrink-0 pt-2">Aliases</label>
                  <div className="flex-1">
                    <TagInput value={editAliases} onChange={setEditAliases} placeholder="Type and press Enter..." />
                  </div>
                </div>
                <div className="flex items-center gap-2 pl-16">
                  <button
                    type="button"
                    onClick={saveCountry}
                    disabled={savingCountry || !editName.trim()}
                    className="inline-flex items-center gap-1 rounded-md bg-primary px-2.5 py-1 text-xs font-medium text-primary-foreground hover:bg-primary/90 disabled:opacity-50"
                  >
                    <Check className="h-3 w-3" /> {savingCountry ? 'Saving...' : 'Save'}
                  </button>
                  <button
                    type="button"
                    onClick={cancelEditCountry}
                    className="inline-flex items-center gap-1 rounded-md border px-2.5 py-1 text-xs font-medium hover:bg-accent"
                  >
                    <X className="h-3 w-3" /> Cancel
                  </button>
                </div>
              </div>
            )}

            {/* Level 2 — Cities */}
            {expanded && countryCities.map(city => {
              const cityExpanded = isCityExpanded(city.id)
              const visiblePois = getVisiblePois(city.id)

              return (
                <div key={city.id}>
                  <div className="flex items-center gap-2 pl-6 pr-4 py-2 border-b hover:bg-accent/30 transition-colors">
                    <button
                      type="button"
                      onClick={() => toggleCity(city.id)}
                      className="flex items-center gap-2 flex-1 text-left min-w-0"
                    >
                      {cityExpanded
                        ? <ChevronDown className="h-4 w-4 shrink-0" />
                        : <ChevronRight className="h-4 w-4 shrink-0" />
                      }
                      <span className="truncate font-medium">
                        {city.name}
                        {(city.aliases || []).length > 0 && (
                          <span className="font-normal text-muted-foreground">
                            {' '}({(city.aliases || []).slice(0, 3).join(', ')}{(city.aliases || []).length > 3 ? ', …' : ''})
                          </span>
                        )}
                      </span>
                    </button>

                    {renderCityActions?.(city)}
                  </div>

                  {/* Level 3 — POIs */}
                  {cityExpanded && (
                    <div>
                      {visiblePois.length === 0 && (
                        <div className="pl-12 pr-4 py-2 text-sm text-muted-foreground border-b border-dashed">
                          {t('common.noResults')}
                        </div>
                      )}

                      {visiblePois.map(poi =>
                        renderPoiRow ? (
                          <div key={poi.id}>{renderPoiRow(poi, city)}</div>
                        ) : (
                          <div
                            key={poi.id}
                            className="flex items-center gap-2 pl-12 pr-4 py-1.5 text-sm border-b border-dashed hover:bg-accent/20 transition-colors"
                          >
                            <span className="flex-1 truncate">
                              {getPoiDisplayName(poi)}
                              {(poi.aliases || []).length > 0 && (
                                <span className="text-muted-foreground">
                                  {' '}({(poi.aliases || []).slice(0, 3).join(', ')}{(poi.aliases || []).length > 3 ? ', …' : ''})
                                </span>
                              )}
                            </span>
                          </div>
                        )
                      )}
                    </div>
                  )}
                </div>
              )
            })}
          </div>
        )
      })}
    </div>
  )
}
