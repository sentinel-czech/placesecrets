import { useEffect, useState } from 'react'
import { Link, useParams } from 'react-router-dom'
import { useTranslation } from 'react-i18next'
import { supabase } from '@/lib/supabase/client'
import { PoiCard, type PoiPreview } from '@/components/places/PoiCard'
import { ChevronLeft } from 'lucide-react'

export default function CityPlacesPage() {
  const { t } = useTranslation()
  const { countryCode, citySlug } = useParams<{ countryCode: string; citySlug: string }>()
  const [cityName, setCityName] = useState('')
  const [places, setPlaces] = useState<PoiPreview[]>([])
  const [loading, setLoading] = useState(true)
  const [notFound, setNotFound] = useState(false)

  useEffect(() => {
    async function load() {
      setLoading(true)
      const { data: city } = await supabase
        .from('cities')
        .select('id, name')
        .eq('slug', citySlug ?? '')
        .eq('country_code', (countryCode ?? '').toUpperCase())
        .eq('is_active', true)
        .maybeSingle()

      if (!city) {
        setNotFound(true)
        setLoading(false)
        return
      }
      setCityName((city as { name: string }).name)

      const { data: pois } = await supabase
        .from('pois')
        .select('id, name, slug, perex, access_level, avg_rating, total_ratings, photo_urls')
        .eq('city_id', (city as { id: string }).id)
        .eq('is_active', true)
        .order('sort_order')

      setPlaces(
        ((pois as Record<string, unknown>[]) || []).map(p => ({
          id: p.id as string,
          name: p.name as Record<string, string>,
          slug: p.slug as string | null,
          perex: p.perex as Record<string, string> | null,
          access_level: p.access_level as string,
          avg_rating: p.avg_rating as number | null,
          total_ratings: p.total_ratings as number,
          photo_urls: (p.photo_urls as string[]) || [],
          city_slug: citySlug ?? null,
          country_code: countryCode ?? null,
        }))
      )
      setLoading(false)
    }
    load()
  }, [countryCode, citySlug])

  return (
    <div className="space-y-6">
      <Link to="/account/cities" className="inline-flex items-center gap-1 text-sm text-muted-foreground hover:text-foreground">
        <ChevronLeft className="h-4 w-4" />
        {t('places.catalog', 'Browse cities')}
      </Link>

      {loading && <p className="text-muted-foreground">{t('common.loading')}</p>}

      {!loading && notFound && (
        <p className="text-muted-foreground">{t('places.cityNotFound', 'City not found.')}</p>
      )}

      {!loading && !notFound && (
        <>
          <h1 className="text-2xl font-bold">{cityName}</h1>
          {places.length === 0 ? (
            <p className="text-muted-foreground">{t('places.noPlacesInCity', 'No places in this city yet.')}</p>
          ) : (
            <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4">
              {places.map(p => (
                <PoiCard key={p.id} poi={p} />
              ))}
            </div>
          )}
        </>
      )}
    </div>
  )
}
