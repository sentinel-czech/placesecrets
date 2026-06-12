import { useEffect, useState } from 'react'
import { useAuthStore } from '@/hooks/useAuth'
import { supabase } from '@/lib/supabase/client'
import { useTranslation } from 'react-i18next'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Badge } from '@/components/ui/badge'
import { Calendar } from 'lucide-react'
import { ExploreMap } from '@/components/account/ExploreMap'
import type { PoiType } from '@/lib/supabase/types'

interface PurchasedCity {
  id: string
  city_id: string
  city_name: string
  purchased_at: string
  valid_until: string | null
}

export default function AccountExplorePage() {
  const { user } = useAuthStore()
  const { t } = useTranslation()
  const [cities, setCities] = useState<PurchasedCity[]>([])
  const [poiTypes, setPoiTypes] = useState<PoiType[]>([])
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    async function loadData() {
      setLoading(true)
      if (user) {
        const { data } = await supabase
          .from('user_access')
          .select('id, city_id, purchased_at, valid_until, cities(name)')
          .eq('user_id', user.id)
          .order('purchased_at', { ascending: false })
        if (data) {
          setCities(data.map((row: Record<string, unknown>) => ({
            id: row.id as string,
            city_id: row.city_id as string,
            city_name: (row.cities as Record<string, string>)?.name ?? 'Unknown',
            purchased_at: row.purchased_at as string,
            valid_until: row.valid_until as string | null,
          })))
        }
      }

      const { data: types } = await supabase
        .from('poi_types')
        .select('*')
        .eq('is_active', true)
        .order('sort_order')
      if (types) setPoiTypes(types as PoiType[])

      setLoading(false)
    }
    loadData()
  }, [user])

  const isExpired = (validUntil: string | null) => {
    if (!validUntil) return false
    return new Date(validUntil) < new Date()
  }

  if (loading) {
    return <p className="text-muted-foreground">{t('common.loading')}</p>
  }

  return (
    <div className="space-y-8">
      {cities.length > 0 && (
        <section>
          <h2 className="text-xl font-bold mb-4">{t('user.dashboard.myCityPasses')}</h2>
          <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
            {cities.map(city => (
              <Card key={city.id}>
                <CardHeader className="pb-2">
                  <div className="flex items-center justify-between">
                    <CardTitle className="text-lg">{city.city_name}</CardTitle>
                    {isExpired(city.valid_until) ? (
                      <Badge variant="secondary">{t('user.dashboard.expired')}</Badge>
                    ) : (
                      <Badge>{t('common.active')}</Badge>
                    )}
                  </div>
                </CardHeader>
                <CardContent>
                  <div className="flex items-center gap-2 text-sm text-muted-foreground">
                    <Calendar className="h-4 w-4" />
                    <span>{t('user.dashboard.purchased')} {new Date(city.purchased_at).toLocaleDateString()}</span>
                  </div>
                  {city.valid_until && (
                    <p className="text-xs text-muted-foreground mt-1">
                      {t('user.dashboard.validUntil')} {new Date(city.valid_until).toLocaleDateString()}
                    </p>
                  )}
                </CardContent>
              </Card>
            ))}
          </div>
        </section>
      )}

      <ExploreMap poiTypes={poiTypes} />
    </div>
  )
}
