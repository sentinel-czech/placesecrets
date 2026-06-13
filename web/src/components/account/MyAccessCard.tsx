import { useEffect, useState } from 'react'
import { useTranslation } from 'react-i18next'
import { useAuthStore } from '@/hooks/useAuth'
import { supabase } from '@/lib/supabase/client'
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from '@/components/ui/card'
import { Badge } from '@/components/ui/badge'
import { MapPin, Globe, Star, Gift } from 'lucide-react'

interface Entitlements {
  free?: { used: number; limit: number; period: string }
  pois?: { poi_id: string; name: Record<string, string>; purchased_at: string }[]
  cities?: { city_id: string; name: string; valid_until: string | null }[]
  city_bundles?: { city_id: string; name: string }[]
  countries?: { country_code: string; valid_until: string | null }[]
}

/** Shows the signed-in user what they currently have access to (free + purchased). */
export function MyAccessCard() {
  const { user } = useAuthStore()
  const { t, i18n } = useTranslation()
  const [ent, setEnt] = useState<Entitlements | null>(null)
  const [loading, setLoading] = useState(true)
  const lang = i18n.language?.substring(0, 2) || 'en'

  useEffect(() => {
    if (!user) return
    supabase.rpc('get_my_entitlements').then(({ data }) => {
      setEnt((data as Entitlements) || {})
      setLoading(false)
    })
  }, [user])

  if (loading) return null

  const pois = ent?.pois ?? []
  const cities = ent?.cities ?? []
  const bundles = ent?.city_bundles ?? []
  const countries = ent?.countries ?? []
  const free = ent?.free

  return (
    <Card>
      <CardHeader>
        <CardTitle>{t('access.myAccess', 'My access')}</CardTitle>
        <CardDescription>{t('access.myAccessDesc', 'What you currently have access to.')}</CardDescription>
      </CardHeader>
      <CardContent className="space-y-3 text-sm">
        {free && (
          <div className="flex items-center gap-2">
            <Gift className="h-4 w-4 text-muted-foreground" />
            <span>
              {t('access.freeUsage', 'Free this {{period}}', { period: t(`access.period.${free.period}`, free.period) })}: {free.used}/{free.limit}
            </span>
          </div>
        )}

        {countries.length > 0 && (
          <div className="flex flex-wrap items-center gap-2">
            <Globe className="h-4 w-4 text-muted-foreground" />
            {countries.map(c => <Badge key={c.country_code} variant="secondary" className="uppercase">{c.country_code}</Badge>)}
          </div>
        )}

        {(cities.length > 0 || bundles.length > 0) && (
          <div className="flex flex-wrap items-center gap-2">
            <MapPin className="h-4 w-4 text-muted-foreground" />
            {cities.map(c => <Badge key={'c' + c.city_id} variant="secondary">{c.name}</Badge>)}
            {bundles.map(b => <Badge key={'b' + b.city_id} className="bg-amber-600 text-white">{b.name} ★</Badge>)}
          </div>
        )}

        {pois.length > 0 && (
          <div className="flex flex-wrap items-center gap-2">
            <Star className="h-4 w-4 text-muted-foreground" />
            {pois.map(p => (
              <Badge key={p.poi_id} variant="outline">{p.name?.[lang] || p.name?.cs || p.name?.en || '—'}</Badge>
            ))}
          </div>
        )}

        {countries.length === 0 && cities.length === 0 && bundles.length === 0 && pois.length === 0 && (
          <p className="text-muted-foreground">{t('access.nothingPurchased', 'You have no purchased places yet — free access applies.')}</p>
        )}
      </CardContent>
    </Card>
  )
}
