import { useTranslation } from 'react-i18next'
import { Sheet, SheetContent, SheetHeader, SheetTitle } from '@/components/ui/sheet'
import { Badge } from '@/components/ui/badge'
import { Star } from 'lucide-react'

interface PlaceInfo {
  id: string
  name: Record<string, string>
  slug: string | null
  perex: Record<string, string> | null
  access_level: string
  avg_rating: number | null
  total_ratings: number
  photo_urls: string[]
  city_slug: string | null
  country_code: string | null
}

interface PlaceDetailSheetProps {
  place: PlaceInfo | null
  open: boolean
  onClose: () => void
}

export function PlaceDetailSheet({ place, open, onClose }: PlaceDetailSheetProps) {
  const { t, i18n } = useTranslation()

  if (!place) return null

  const lang = i18n.language?.substring(0, 2) || 'en'
  const perexText = place.perex?.[lang] || place.perex?.cs || place.perex?.en || null

  return (
    <Sheet open={open} onOpenChange={v => { if (!v) onClose() }}>
      <SheetContent>
        <SheetHeader>
          <SheetTitle>{place.name?.cs || place.name?.en || t('user.dashboard.explore.placeDetail')}</SheetTitle>
        </SheetHeader>
        <div className="mt-4 space-y-4">
          {place.photo_urls?.length > 0 && (
            <img
              src={place.photo_urls[0]}
              alt={place.name?.en || ''}
              className="w-full h-48 object-cover rounded-lg"
            />
          )}

          <div className="flex items-center gap-2">
            <Badge variant="secondary">{place.access_level}</Badge>
            {place.avg_rating && (
              <span className="flex items-center gap-1 text-sm">
                <Star className="h-4 w-4 fill-amber-400 text-amber-400" />
                {place.avg_rating.toFixed(1)} ({place.total_ratings})
              </span>
            )}
          </div>

          {place.name?.en && place.name?.cs && (
            <p className="text-sm text-muted-foreground">{place.name.en}</p>
          )}

          {perexText && (
            <p className="text-sm">{perexText}</p>
          )}

          {place.country_code && place.city_slug && place.slug && (
            <a
              href={`/${place.country_code.toLowerCase()}/${place.city_slug}/${place.slug}`}
              className="text-sm text-primary hover:underline"
            >
              {t('user.dashboard.explore.placeDetail')} &rarr;
            </a>
          )}
        </div>
      </SheetContent>
    </Sheet>
  )
}
