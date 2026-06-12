import { Link } from 'react-router-dom'
import { useTranslation } from 'react-i18next'
import { Badge } from '@/components/ui/badge'
import { Star, MapPin } from 'lucide-react'
import { poiHref, type PoiPreview } from './poi'

export type { PoiPreview }

export function PoiCard({ poi }: { poi: PoiPreview }) {
  const { t, i18n } = useTranslation()
  const lang = i18n.language?.substring(0, 2) || 'en'
  const name = poi.name?.[lang] || poi.name?.cs || poi.name?.en || ''
  const perex = poi.perex?.[lang] || poi.perex?.cs || poi.perex?.en || null
  const href = poiHref(poi)
  const photo = poi.photo_urls?.[0]

  const inner = (
    <article className="group h-full overflow-hidden rounded-xl border bg-card transition-shadow hover:shadow-md">
      <div className="relative h-40 w-full overflow-hidden bg-muted">
        {photo ? (
          <img
            src={photo}
            alt={name}
            loading="lazy"
            className="h-full w-full object-cover transition-transform duration-200 group-hover:scale-105"
          />
        ) : (
          <div className="flex h-full items-center justify-center">
            <MapPin className="h-10 w-10 text-muted-foreground/40" />
          </div>
        )}
        <Badge variant="secondary" className="absolute left-2 top-2 capitalize">
          {t(`places.access.${poi.access_level}`, poi.access_level.replace('_', ' '))}
        </Badge>
      </div>
      <div className="space-y-1 p-3">
        <div className="flex items-start justify-between gap-2">
          <h3 className="line-clamp-1 font-medium leading-tight">{name}</h3>
          {poi.avg_rating != null && poi.total_ratings > 0 && (
            <span className="flex shrink-0 items-center gap-1 text-sm text-muted-foreground">
              <Star className="h-3.5 w-3.5 fill-amber-400 text-amber-400" />
              {poi.avg_rating.toFixed(1)}
            </span>
          )}
        </div>
        {perex && <p className="line-clamp-2 text-sm text-muted-foreground">{perex}</p>}
      </div>
    </article>
  )

  return href ? (
    <Link to={href} className="block h-full">
      {inner}
    </Link>
  ) : (
    inner
  )
}
