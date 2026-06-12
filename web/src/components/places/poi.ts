/** Shared preview shape used by catalog, search results and the landing page. */
export interface PoiPreview {
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

/** Build the public place-detail href, or null if the slug parts are incomplete. */
export function poiHref(p: Pick<PoiPreview, 'country_code' | 'city_slug' | 'slug'>): string | null {
  if (!p.country_code || !p.city_slug || !p.slug) return null
  return `/${p.country_code.toLowerCase()}/${p.city_slug}/${p.slug}`
}
