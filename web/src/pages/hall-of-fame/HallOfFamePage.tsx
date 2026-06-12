import { useEffect, useState } from 'react'
import { useSearchParams } from 'react-router-dom'
import { useTranslation } from 'react-i18next'
import { adminSelect, adminRpc } from '@/lib/supabase/admin-api'
import type { City, HallOfFameEntry, Poi } from '@/lib/supabase/types'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Badge } from '@/components/ui/badge'
import { Star, CheckCircle, Trophy, Medal, Award } from 'lucide-react'

const podiumConfig = [
  { place: 1, icon: Trophy, color: 'oklch(0.62 0.12 90)', bgColor: 'oklch(0.62 0.12 90 / 0.12)', label: '1.', height: 'h-32' },
  { place: 2, icon: Medal, color: 'oklch(0.7 0.02 260)', bgColor: 'oklch(0.7 0.02 260 / 0.12)', label: '2.', height: 'h-24' },
  { place: 3, icon: Award, color: 'oklch(0.55 0.1 55)', bgColor: 'oklch(0.55 0.1 55 / 0.12)', label: '3.', height: 'h-20' },
]

type HofContext = 'overall' | 'city' | 'place'

function PodiumCard({ entry, config, t }: { entry: HallOfFameEntry; config: typeof podiumConfig[number]; t: (k: string) => string }) {
  const IconComponent = config.icon
  return (
    <div className="flex flex-col items-center text-center">
      <div className="rounded-full p-3 mb-2" style={{ backgroundColor: config.bgColor }}>
        <IconComponent className="h-6 w-6" style={{ color: config.color }} />
      </div>
      <div className="flex items-center gap-1 mb-1">
        <span className="font-semibold text-sm">{entry.display_name}</span>
        {entry.is_verified && <CheckCircle className="h-3.5 w-3.5 text-blue-500" />}
      </div>
      <div className="flex items-center gap-1 text-xs text-muted-foreground">
        <Star className="h-3 w-3 fill-gold text-gold" />
        {Number(entry.city_avg_rating).toFixed(2)}
      </div>
      <div className="text-xs text-muted-foreground mt-0.5">
        {entry.city_poi_count} {t('admin.hallOfFame.places')} · {entry.city_total_ratings} {t('admin.hallOfFame.ratings')}
      </div>
      <Badge variant="secondary" className="mt-1.5 text-xs">
        {t('admin.hallOfFame.score')}: {Number(entry.hof_score).toFixed(2)}
      </Badge>
      <div
        className="w-20 rounded-t-lg mt-2"
        style={{ backgroundColor: config.bgColor, height: config.height.replace('h-', '') + 'px' }}
      />
    </div>
  )
}

export default function HallOfFamePage() {
  const { t } = useTranslation()
  const [searchParams, setSearchParams] = useSearchParams()
  const [cities, setCities] = useState<City[]>([])
  const [pois, setPois] = useState<Poi[]>([])
  const [entries, setEntries] = useState<HallOfFameEntry[]>([])
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState('')

  const context = (searchParams.get('context') as HofContext) || 'overall'
  const cityId = searchParams.get('city') || ''
  const placeId = searchParams.get('place') || ''

  function setContext(ctx: HofContext) {
    const params: Record<string, string> = { context: ctx }
    if (ctx === 'city' && cityId) params.city = cityId
    if (ctx === 'place') {
      if (cityId) params.city = cityId
      if (placeId) params.place = placeId
    }
    setSearchParams(params)
  }

  function setCityParam(cid: string) {
    const params: Record<string, string> = { context, city: cid }
    setSearchParams(params)
  }

  function setPlaceParam(pid: string) {
    const params: Record<string, string> = { context, city: cityId, place: pid }
    setSearchParams(params)
  }

  // Load cities
  useEffect(() => {
    let cancelled = false
    adminSelect('cities', {
      select: 'id, name',
      filters: [{ column: 'is_active', op: 'eq', value: true }],
      order: { column: 'name' },
    }).then(({ data, error: err }) => {
      if (cancelled) return
      if (err) setError(err)
      else if (data) setCities(data as City[])
    })
    return () => { cancelled = true }
  }, [])

  // Load POIs when city selected in place context
  useEffect(() => {
    if (context !== 'place' || !cityId) { setPois([]); return }
    let cancelled = false
    adminSelect('pois', {
      select: 'id, name',
      filters: [
        { column: 'city_id', op: 'eq', value: cityId },
        { column: 'is_active', op: 'eq', value: true },
      ],
      order: { column: 'name' },
    }).then(({ data, error: err }) => {
      if (cancelled) return
      if (err) setError(err)
      else if (data) setPois(data as Poi[])
    })
    return () => { cancelled = true }
  }, [context, cityId])

  // Load hall of fame data
  useEffect(() => {
    let cancelled = false
    setLoading(true)
    setEntries([])

    let rpcPromise: Promise<{ data: unknown; error: string | null }>

    if (context === 'overall') {
      rpcPromise = adminRpc('poi_hall_of_fame_overall', { p_limit: 10 })
    } else if (context === 'city' && cityId) {
      rpcPromise = adminRpc('poi_hall_of_fame', { p_city_id: cityId, p_limit: 10 })
    } else if (context === 'place' && cityId) {
      // Place mode uses same city RPC, filtered view in UI
      rpcPromise = adminRpc('poi_hall_of_fame', { p_city_id: cityId, p_limit: 10 })
    } else {
      setLoading(false)
      return
    }

    rpcPromise.then(({ data, error: err }) => {
      if (cancelled) return
      if (err) setError(err)
      else if (data) setEntries(data as HallOfFameEntry[])
      setLoading(false)
    })

    return () => { cancelled = true }
  }, [context, cityId])

  const top3 = entries.slice(0, 3)
  const rest = entries.slice(3)

  const podiumOrder = top3.length >= 3
    ? [{ entry: top3[1], config: podiumConfig[1] }, { entry: top3[0], config: podiumConfig[0] }, { entry: top3[2], config: podiumConfig[2] }]
    : top3.map((entry, i) => ({ entry, config: podiumConfig[i] }))

  return (
    <div className="space-y-6 max-w-3xl">
      {/* Context tabs */}
      <div className="flex gap-1 rounded-lg bg-muted p-1">
        {(['overall', 'city', 'place'] as HofContext[]).map(ctx => (
          <button
            key={ctx}
            onClick={() => setContext(ctx)}
            className={`flex-1 rounded-md px-3 py-1.5 text-sm font-medium transition-colors ${
              context === ctx
                ? 'bg-background shadow text-foreground'
                : 'text-muted-foreground hover:text-foreground'
            }`}
          >
            {t(`admin.hallOfFame.context${ctx.charAt(0).toUpperCase() + ctx.slice(1)}`)}
          </button>
        ))}
      </div>

      {/* City selector for city/place modes */}
      {(context === 'city' || context === 'place') && (
        <div className="flex gap-4 flex-wrap">
          <select
            value={cityId}
            onChange={e => setCityParam(e.target.value)}
            className="rounded-md border border-input bg-background px-3 py-2 text-sm w-64"
            aria-label={t('admin.hallOfFame.selectCity')}
          >
            <option value="">-- {t('admin.hallOfFame.selectCity')} --</option>
            {cities.map(c => <option key={c.id} value={c.id}>{c.name}</option>)}
          </select>

          {context === 'place' && cityId && (
            <select
              value={placeId}
              onChange={e => setPlaceParam(e.target.value)}
              className="rounded-md border border-input bg-background px-3 py-2 text-sm w-64"
              aria-label={t('admin.hallOfFame.selectPlace')}
            >
              <option value="">-- {t('admin.hallOfFame.selectPlace')} --</option>
              {pois.map(p => <option key={p.id} value={p.id}>{p.name?.cs || p.name?.en || p.id}</option>)}
            </select>
          )}
        </div>
      )}

      {error && <p className="text-sm text-destructive">{error}</p>}
      {loading && <p className="text-sm text-muted-foreground">{t('common.loading')}</p>}

      {!loading && top3.length > 0 && (
        <>
          <Card>
            <CardHeader>
              <CardTitle className="text-base flex items-center gap-2">
                <Trophy className="h-4 w-4 text-gold" />
                {t('admin.hallOfFame.topContributors')}
              </CardTitle>
            </CardHeader>
            <CardContent>
              <div className="flex items-end justify-center gap-6 py-4">
                {podiumOrder.map(({ entry, config }) => (
                  <PodiumCard key={entry.contributor_id} entry={entry} config={config} t={t} />
                ))}
              </div>
            </CardContent>
          </Card>

          {rest.length > 0 && (
            <Card>
              <CardContent className="pt-6">
                <div className="space-y-3">
                  {rest.map((entry, i) => (
                    <div key={entry.contributor_id} className="flex items-center gap-3 border-b pb-3 last:border-0">
                      <span className="text-sm font-medium text-muted-foreground w-8 text-center">#{i + 4}</span>
                      <div className="flex-1">
                        <div className="flex items-center gap-2">
                          <span className="font-medium text-sm">{entry.display_name}</span>
                          {entry.is_verified && <CheckCircle className="h-4 w-4 text-blue-500" />}
                        </div>
                        <div className="flex gap-4 text-xs text-muted-foreground mt-0.5">
                          <span>{entry.city_poi_count} {t('admin.hallOfFame.places')}</span>
                          <span className="flex items-center gap-0.5">
                            <Star className="h-3 w-3 fill-gold text-gold" />
                            {Number(entry.city_avg_rating).toFixed(2)} ({entry.city_total_ratings} {t('admin.hallOfFame.ratings')})
                          </span>
                        </div>
                      </div>
                      <Badge variant="secondary">{t('admin.hallOfFame.score')}: {Number(entry.hof_score).toFixed(2)}</Badge>
                    </div>
                  ))}
                </div>
              </CardContent>
            </Card>
          )}
        </>
      )}

      {!loading && entries.length === 0 && (context === 'overall' || cityId) && (
        <p className="text-sm text-muted-foreground">{t('admin.hallOfFame.noData')}</p>
      )}
    </div>
  )
}
