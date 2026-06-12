import { useEffect, useState } from 'react'
import { Link } from 'react-router-dom'
import { useTranslation } from 'react-i18next'
import { supabase } from '@/lib/supabase/client'
import { Card, CardContent } from '@/components/ui/card'
import { MapPin } from 'lucide-react'

interface CatalogCity {
  id: string
  name: string
  country_code: string
  slug: string | null
}

export default function CitiesCatalogPage() {
  const { t } = useTranslation()
  const [cities, setCities] = useState<CatalogCity[]>([])
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    supabase
      .from('cities')
      .select('id, name, country_code, slug')
      .eq('is_active', true)
      .order('name')
      .then(({ data }) => {
        setCities((data as CatalogCity[]) || [])
        setLoading(false)
      })
  }, [])

  return (
    <div className="space-y-6">
      <h1 className="text-2xl font-bold">{t('places.catalog', 'Browse cities')}</h1>

      {loading && <p className="text-muted-foreground">{t('common.loading')}</p>}

      {!loading && cities.length === 0 && (
        <p className="text-muted-foreground">{t('places.noCities', 'No cities available yet.')}</p>
      )}

      <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4">
        {cities.map(city => (
          <Link
            key={city.id}
            to={city.slug ? `/account/cities/${city.country_code.toLowerCase()}/${city.slug}` : '#'}
            className="block"
          >
            <Card className="transition-shadow hover:shadow-md">
              <CardContent className="flex items-center gap-3 p-4">
                <div className="flex h-10 w-10 shrink-0 items-center justify-center rounded-lg bg-primary/10">
                  <MapPin className="h-5 w-5 text-primary" />
                </div>
                <div className="min-w-0">
                  <p className="truncate font-medium">{city.name}</p>
                  <p className="text-xs uppercase text-muted-foreground">{city.country_code}</p>
                </div>
              </CardContent>
            </Card>
          </Link>
        ))}
      </div>
    </div>
  )
}
