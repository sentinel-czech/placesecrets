import { useEffect, useState, useRef, useCallback, Fragment } from 'react'
import { useParams, Link } from 'react-router-dom'
import { Helmet } from 'react-helmet-async'
import { supabase } from '@/lib/supabase/client'
import { useAuthStore } from '@/hooks/useAuth'
import { Card, CardContent } from '@/components/ui/card'
import { Button } from '@/components/ui/button'
import { BuyButton } from '@/components/places/BuyButton'
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs'
import { MapPicker } from '@/components/shared/MapPicker'
import {
  MapPin, ExternalLink, Star, Share2, Check, Lock, Headphones, User, BadgeCheck, ChevronRight,
  Building2, PersonStanding, Castle, Church, Landmark, Trees, Mountain, UtensilsCrossed,
  Coffee, Wine, Store, Theater, X, Loader2,
} from 'lucide-react'
import { PublicHeader } from '@/components/layout/PublicHeader'
import { PublicFooter } from '@/components/layout/PublicFooter'
import { useTranslation } from 'react-i18next'
import { LANG_LABELS } from '@/lib/constants'
import type { LucideIcon } from 'lucide-react'

const ICON_MAP: Record<string, LucideIcon> = {
  apartment: Building2,
  emoji_people: PersonStanding,
  castle: Castle,
  church: Church,
  museum: Landmark,
  park: Trees,
  landscape: Mountain,
  restaurant: UtensilsCrossed,
  local_cafe: Coffee,
  local_bar: Wine,
  storefront: Store,
  theater_comedy: Theater,
}

const REVIEWS_PAGE_SIZE = 10

interface AudioGuideMeta {
  id: string
  lang_code: string
  title: string
  duration_sec: number | null
  sort_order: number
  uploaded_by: string | null
  uploader_handle: string | null
  avg_rating: number | null
  total_ratings: number | null
  created_at: string | null
}

interface PoiReview {
  review_id: string
  rating: number
  comment: string | null
  is_hidden: boolean
  created_at: string
  display_name: string
  total_count: number
  is_own: boolean
}

interface PoiSlugData {
  poi_id: string
  poi_name: Record<string, string>
  poi_description: Record<string, string>
  poi_perex: Record<string, string> | null
  poi_access_level: string
  poi_premium_price: number | null
  poi_lat: number
  poi_lng: number
  poi_photo_urls: string[] | null
  poi_audio_urls: Record<string, string> | null
  poi_avg_rating: number | null
  poi_total_ratings: number | null
  poi_aliases: string[] | null
  audio_guides: AudioGuideMeta[]
  poi_type_id: string | null
  poi_type_name: Record<string, string> | null
  poi_type_icon: string | null
  poi_type_color: string | null
  contributor_id: string | null
  contributor_name: string | null
  contributor_avatar: string | null
  contributor_verified: boolean | null
  city_id: string
  city_name: string
  city_slug: string
  country_code: string
}

function formatDuration(sec: number): string {
  const h = Math.floor(sec / 3600)
  const m = Math.floor((sec % 3600) / 60)
  const s = sec % 60
  return `${h.toString().padStart(2, '0')}:${m.toString().padStart(2, '0')}:${s.toString().padStart(2, '0')}`
}

function formatCoord(value: number, positive: string, negative: string): string {
  const dir = value >= 0 ? positive : negative
  return `${Math.abs(value).toFixed(4)}\u00B0 ${dir}`
}

export default function PlaceDetailPage() {
  const { countryCode, citySlug, poiSlug } = useParams<{ countryCode: string; citySlug: string; poiSlug: string }>()
  const { t, i18n } = useTranslation()
  const user = useAuthStore(s => s.user)
  const isLoggedIn = !!user
  const [poi, setPoi] = useState<PoiSlugData | null>(null)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState('')
  const [photoIndex, setPhotoIndex] = useState(0)
  const [shared, setShared] = useState(false)
  const [accessLevel, setAccessLevel] = useState<string | null>(null)
  const [audioUrls, setAudioUrls] = useState<Map<string, string>>(new Map())
  const [userRatings, setUserRatings] = useState<Map<string, number>>(new Map())
  const [ratingDialogGuide, setRatingDialogGuide] = useState<AudioGuideMeta | null>(null)
  const [pendingRating, setPendingRating] = useState(0)
  const [ratingSubmitting, setRatingSubmitting] = useState(false)
  const [ratingError, setRatingError] = useState('')

  // POI-level rating (separate from per-audio-guide rating)
  const [poiRating, setPoiRating] = useState(0)
  const [poiComment, setPoiComment] = useState('')
  const [poiRatingSubmitting, setPoiRatingSubmitting] = useState(false)
  const [poiRatingError, setPoiRatingError] = useState('')
  const [poiRated, setPoiRated] = useState(false)

  // Reviews state (lazy-loaded on Rating tab activation)
  const [reviews, setReviews] = useState<PoiReview[]>([])
  const [reviewsTotalCount, setReviewsTotalCount] = useState(0)
  const [reviewsLoading, setReviewsLoading] = useState(false)
  const hasLoadedReviews = useRef(false)
  const prevUserIdRef = useRef<string | undefined>(undefined)
  const sentinelRef = useRef<HTMLDivElement | null>(null)

  const paramsRef = useRef({ countryCode, citySlug, poiSlug })
  paramsRef.current = { countryCode, citySlug, poiSlug }

  function refetchPoi() {
    const { countryCode: cc2, citySlug: cs2, poiSlug: ps2 } = paramsRef.current
    if (!cc2 || !cs2 || !ps2) return
    supabase.rpc('get_poi_by_slug', {
      p_country_code: cc2,
      p_city_slug: cs2,
      p_poi_slug: ps2,
    }).then(({ data, error: err }) => {
      if (err) {
        setError(t('placeDetail.notFound', 'Place not found'))
      } else if (data && Array.isArray(data) && data.length > 0) {
        setPoi(data[0] as PoiSlugData)
      } else {
        setError(t('placeDetail.notFound', 'Place not found'))
      }
      setLoading(false)
    })
  }

  useEffect(() => {
    if (!countryCode || !citySlug || !poiSlug) return
    supabase.rpc('get_poi_by_slug', {
      p_country_code: countryCode,
      p_city_slug: citySlug,
      p_poi_slug: poiSlug,
    }).then(({ data, error: err }) => {
      if (err) {
        setError(t('placeDetail.notFound', 'Place not found'))
      } else if (data && Array.isArray(data) && data.length > 0) {
        setPoi(data[0] as PoiSlugData)
      } else {
        setError(t('placeDetail.notFound', 'Place not found'))
      }
      setLoading(false)
    })
  // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [countryCode, citySlug, poiSlug])

  useEffect(() => {
    if (!poi || !user) return
    supabase.rpc('get_poi_access', { p_poi_id: poi.poi_id })
      .then(({ data }) => { if (data) setAccessLevel(data as string) })
  }, [poi, user])

  const ACCESS_HIERARCHY: Record<string, number> = {
    public: 0, registered: 1, registered_limited: 1,
    city_access: 2, premium_poi: 3, full: 4,
  }
  const poiRequired = poi ? (ACCESS_HIERARCHY[poi.poi_access_level] ?? 2) : 2
  const userLevel = ACCESS_HIERARCHY[accessLevel ?? ''] ?? -1
  const hasAudioAccess = userLevel >= poiRequired

  useEffect(() => {
    if (!poi || !hasAudioAccess) return
    supabase.from('poi_audio_guides').select('id, url').eq('poi_id', poi.poi_id)
      .then(({ data }) => {
        if (data) setAudioUrls(new Map(data.map((r: { id: string; url: string }) => [r.id, r.url])))
      })
  }, [poi, hasAudioAccess])

  // Fetch user's existing ratings for audio guides
  useEffect(() => {
    if (!poi || !user) return
    const guideIds = (poi.audio_guides || []).map(g => g.id)
    if (guideIds.length === 0) return
    supabase.from('poi_audio_guide_ratings')
      .select('audio_guide_id, rating')
      .eq('user_id', user.id)
      .in('audio_guide_id', guideIds)
      .then(({ data }) => {
        if (data) {
          setUserRatings(new Map(data.map((r: { audio_guide_id: string; rating: number }) => [r.audio_guide_id, r.rating])))
        }
      })
  }, [poi, user])

  // Fetch reviews page
  const fetchReviews = useCallback(async (offset: number) => {
    if (!poi) return
    setReviewsLoading(true)
    const { data, error: err } = await supabase.rpc('get_poi_reviews', {
      p_poi_id: poi.poi_id,
      p_limit: REVIEWS_PAGE_SIZE,
      p_offset: offset,
      p_user_id: user?.id ?? null,
    })
    setReviewsLoading(false)
    if (err || !data) return
    const rows = data as PoiReview[]
    if (rows.length > 0) {
      setReviewsTotalCount(rows[0].total_count)
    }
    setReviews(prev => offset === 0 ? rows : [...prev, ...rows])
  }, [poi, user])

  // Reset reviews when user changes (login/logout) so own review priority updates
  useEffect(() => {
    if (prevUserIdRef.current !== user?.id) {
      prevUserIdRef.current = user?.id
      if (hasLoadedReviews.current) {
        hasLoadedReviews.current = false
        setReviews([])
        setReviewsTotalCount(0)
      }
    }
  }, [user])

  // Lazy-load reviews when Rating tab is first activated
  const handleTabChange = useCallback((value: string | number | null) => {
    if (value === 'rating' && !hasLoadedReviews.current && poi) {
      hasLoadedReviews.current = true
      fetchReviews(0)
    }
  }, [poi, fetchReviews])

  // IntersectionObserver for infinite scroll
  useEffect(() => {
    const sentinel = sentinelRef.current
    if (!sentinel) return
    const observer = new IntersectionObserver(
      (entries) => {
        if (entries[0].isIntersecting && !reviewsLoading && reviews.length < reviewsTotalCount) {
          fetchReviews(reviews.length)
        }
      },
      { threshold: 0.1 }
    )
    observer.observe(sentinel)
    return () => observer.disconnect()
  }, [reviews.length, reviewsTotalCount, reviewsLoading, fetchReviews])

  if (loading) {
    return (
      <div className="min-h-screen flex flex-col">
        <PublicHeader showNav={false} />
        <div className="flex-1 flex items-center justify-center bg-gray-50">
          <p className="text-muted-foreground">{t('common.loading', 'Loading...')}</p>
        </div>
        <PublicFooter />
      </div>
    )
  }

  if (error || !poi) {
    return (
      <div className="min-h-screen flex flex-col">
        <PublicHeader showNav={false} />
        <div className="flex-1 flex items-center justify-center bg-gray-50">
          <Card className="max-w-md w-full mx-4">
            <CardContent className="p-8 text-center">
              <MapPin className="h-12 w-12 mx-auto mb-4 text-muted-foreground" />
              <h1 className="text-xl font-semibold mb-2">{t('placeDetail.notFoundTitle', 'Place Not Found')}</h1>
              <p className="text-muted-foreground">{t('placeDetail.notFoundDesc', 'The place you are looking for does not exist or has been removed.')}</p>
            </CardContent>
          </Card>
        </div>
        <PublicFooter />
      </div>
    )
  }

  const lang = i18n.language?.substring(0, 2) || 'en'
  const name = poi.poi_name?.[lang] || poi.poi_name?.cs || poi.poi_name?.en || 'Unknown Place'
  const description = poi.poi_description?.[lang] || poi.poi_description?.cs || poi.poi_description?.en || ''
  const perex = poi.poi_perex?.[lang] || poi.poi_perex?.cs || poi.poi_perex?.en || null
  const metaDesc = perex || `Discover ${name} in ${poi.city_name}`
  const cc = poi.country_code?.toLowerCase() || countryCode
  const appDeepLink = `placesecrets://${cc}/${citySlug}/${poiSlug}`
  const shareUrl = `https://placesecrets.app/${cc}/${citySlug}/${poiSlug}`
  const photos = poi.poi_photo_urls ?? []

  // Group audio guides by language — only languages that have guides
  const audioGuides = poi.audio_guides || []
  const guidesByLang: Record<string, AudioGuideMeta[]> = {}
  for (const g of audioGuides) {
    if (!guidesByLang[g.lang_code]) {
      guidesByLang[g.lang_code] = []
    }
    guidesByLang[g.lang_code].push(g)
  }
  const hasAudioGuides = audioGuides.length > 0

  // Sort languages: preferred language first, then alphabetically by label
  const populatedLangs = Object.keys(guidesByLang).sort((a, b) => {
    if (a === lang && b !== lang) return -1
    if (b === lang && a !== lang) return 1
    return (LANG_LABELS[a] || a).localeCompare(LANG_LABELS[b] || b)
  })

  // Sort guides within each language: avg_rating desc → total_ratings desc → title asc → created_at asc
  for (const lc of populatedLangs) {
    guidesByLang[lc].sort((a, b) => {
      const rA = Number(a.avg_rating) || 0
      const rB = Number(b.avg_rating) || 0
      if (rB !== rA) return rB - rA
      const tA = a.total_ratings || 0
      const tB = b.total_ratings || 0
      if (tB !== tA) return tB - tA
      const titleCmp = (a.title || '').localeCompare(b.title || '')
      if (titleCmp !== 0) return titleCmp
      return (a.created_at || '').localeCompare(b.created_at || '')
    })
  }

  const typeName = poi.poi_type_name?.[lang] || poi.poi_type_name?.cs || poi.poi_type_name?.en || null
  const TypeIcon = poi.poi_type_icon ? (ICON_MAP[poi.poi_type_icon] || MapPin) : MapPin

  async function handleShare() {
    if (navigator.share) {
      try {
        await navigator.share({ title: `${name} — PlaceSecrets`, url: shareUrl })
      } catch { /* user cancelled */ }
    } else {
      await navigator.clipboard.writeText(shareUrl)
      setShared(true)
      setTimeout(() => setShared(false), 2000)
    }
  }

  function openRatingDialog(guide: AudioGuideMeta) {
    setRatingDialogGuide(guide)
    setPendingRating(userRatings.get(guide.id) || 0)
    setRatingError('')
  }

  async function submitRating() {
    if (!ratingDialogGuide || !user || pendingRating < 1) return
    setRatingSubmitting(true)
    setRatingError('')
    const { error: upsertErr } = await supabase.from('poi_audio_guide_ratings').upsert(
      { audio_guide_id: ratingDialogGuide.id, user_id: user.id, rating: pendingRating },
      { onConflict: 'audio_guide_id,user_id' }
    )
    setRatingSubmitting(false)
    if (upsertErr) {
      console.error('Audio guide rating upsert failed:', upsertErr)
      setRatingError(upsertErr.message || t('common.error', 'An error occurred'))
      return
    }
    setUserRatings(prev => new Map(prev).set(ratingDialogGuide!.id, pendingRating))
    setRatingDialogGuide(null)
    refetchPoi()
  }

  async function submitPoiRating() {
    if (!user || !poi || poiRating < 1) return
    setPoiRatingSubmitting(true)
    setPoiRatingError('')
    const { error: upsertErr } = await supabase.from('poi_ratings').upsert(
      { poi_id: poi.poi_id, user_id: user.id, rating: poiRating, comment: poiComment.trim() || null, lang_code: lang },
      { onConflict: 'poi_id,user_id' }
    )
    setPoiRatingSubmitting(false)
    if (upsertErr) {
      setPoiRatingError(upsertErr.message || t('common.error', 'An error occurred'))
      return
    }
    setPoiRated(true)
    setPoiComment('')
    refetchPoi()
    hasLoadedReviews.current = true
    fetchReviews(0)
  }

  return (
    <>
      <Helmet>
        <title>{name} — PlaceSecrets</title>
        <meta name="description" content={metaDesc} />
        <meta property="og:title" content={`${name} — PlaceSecrets`} />
        <meta property="og:description" content={metaDesc} />
        <meta property="og:type" content="website" />
        <meta property="og:url" content={shareUrl} />
        {photos[0] && <meta property="og:image" content={photos[0]} />}
        <meta name="twitter:card" content={photos[0] ? 'summary_large_image' : 'summary'} />
        <meta name="twitter:title" content={`${name} — PlaceSecrets`} />
        <meta name="twitter:description" content={metaDesc} />
        {photos[0] && <meta name="twitter:image" content={photos[0]} />}
      </Helmet>

      <div className="min-h-screen flex flex-col">
        <PublicHeader showNav={false} />
        <div className="flex-1 bg-gray-50">
          {/* Breadcrumb */}
          <div className="max-w-7xl mx-auto px-4 pt-6 pb-2">
            <nav className="flex items-center gap-1.5 text-sm text-muted-foreground">
              <Link to="/" className="hover:text-foreground transition">PlaceSecrets</Link>
              <ChevronRight className="h-3.5 w-3.5" />
              <span>{poi.city_name}</span>
            </nav>
          </div>

          <div className="max-w-7xl mx-auto px-4 pb-12">
            {/* Photo carousel */}
            {photos.length > 0 && (
              <div className="mb-6 rounded-lg overflow-hidden">
                <img
                  src={photos[photoIndex]}
                  alt={name}
                  className="w-full h-64 object-cover"
                />
                {photos.length > 1 && (
                  <div className="flex justify-center gap-1.5 py-2 bg-white">
                    {photos.map((_, i) => (
                      <button
                        key={i}
                        onClick={() => setPhotoIndex(i)}
                        className={`h-2 w-2 rounded-full transition ${i === photoIndex ? 'bg-primary' : 'bg-muted-foreground/30'}`}
                        aria-label={`Photo ${i + 1}`}
                      />
                    ))}
                  </div>
                )}
              </div>
            )}

            <Card>
              <CardContent className="p-6 space-y-5">
                {/* Type badge + share */}
                <div className="flex items-center justify-between">
                  <div className="flex items-center gap-2">
                    {typeName && (
                      <span
                        className="inline-flex items-center gap-1 px-2 py-0.5 rounded-full text-xs font-medium"
                        style={{
                          backgroundColor: poi.poi_type_color ? `${poi.poi_type_color}20` : undefined,
                          color: poi.poi_type_color || undefined,
                        }}
                      >
                        <TypeIcon className="h-3.5 w-3.5" />
                        {typeName}
                      </span>
                    )}
                  </div>
                  <button
                    onClick={handleShare}
                    className="p-2 rounded-md hover:bg-muted transition"
                    aria-label="Share"
                  >
                    {shared ? <Check className="h-5 w-5 text-green-600" /> : <Share2 className="h-5 w-5 text-muted-foreground" />}
                  </button>
                </div>

                {/* Name + aliases + location */}
                <div>
                  <h1 className="text-2xl font-bold">{name}</h1>
                  {poi.poi_aliases && poi.poi_aliases.length > 0 && (
                    <p className="text-sm text-muted-foreground mt-0.5 italic">
                      {poi.poi_aliases.join(' · ')}
                    </p>
                  )}
                  <p className="text-sm text-muted-foreground mt-0.5">
                    {poi.city_name} &middot; {poi.country_code}
                  </p>
                </div>

                {/* Rating stars summary — always visible above tabs */}
                {poi.poi_avg_rating != null && poi.poi_total_ratings != null && poi.poi_total_ratings > 0 && (
                  <div className="flex items-center gap-1.5">
                    <div className="flex">
                      {Array.from({ length: 5 }).map((_, i) => (
                        <Star
                          key={i}
                          className={`h-4 w-4 ${i < Math.round(poi.poi_avg_rating!) ? 'text-yellow-500 fill-yellow-500' : 'text-muted-foreground/30'}`}
                        />
                      ))}
                    </div>
                    <span className="text-sm text-muted-foreground">
                      {Number(poi.poi_avg_rating).toFixed(1)} ({poi.poi_total_ratings})
                    </span>
                  </div>
                )}

                {/* Tabs: Detail | Rating */}
                <Tabs defaultValue="detail" onValueChange={handleTabChange}>
                  <TabsList>
                    <TabsTrigger value="detail">{t('placeDetail.detail', 'Detail')}</TabsTrigger>
                    <TabsTrigger value="rating">{t('placeDetail.rating', 'Rating')}</TabsTrigger>
                  </TabsList>

                  {/* === Detail Tab === */}
                  <TabsContent value="detail" className="space-y-5 mt-4">
                    {/* Perex — always visible */}
                    {perex && (
                      <p className="text-muted-foreground leading-relaxed">{perex}</p>
                    )}

                    {/* Description — auth-gated */}
                    {description && (
                      <div className="space-y-2">
                        <h2 className="text-sm font-semibold uppercase tracking-wide text-muted-foreground">
                          {t('placeDetail.description', 'Description')}
                        </h2>
                        {isLoggedIn ? (
                          <p className="text-foreground leading-relaxed whitespace-pre-line">{description}</p>
                        ) : (
                          <div className="relative">
                            <p className="text-foreground leading-relaxed whitespace-pre-line line-clamp-3 blur-sm select-none" aria-hidden>
                              {description}
                            </p>
                            <div className="absolute inset-0 flex flex-col items-center justify-center bg-gray-50/80 rounded-md">
                              <Lock className="h-5 w-5 text-muted-foreground mb-1.5" />
                              <p className="text-sm font-medium text-muted-foreground">
                                {t('placeDetail.signInToRead', 'Sign in to read more')}
                              </p>
                            </div>
                          </div>
                        )}
                      </div>
                    )}

                    {/* Audio guides section — only populated languages */}
                    {hasAudioGuides && (
                      <div className="space-y-2">
                        <h2 className="text-sm font-semibold uppercase tracking-wide text-muted-foreground flex items-center gap-1.5">
                          <Headphones className="h-4 w-4" />
                          {t('placeDetail.availableAudioGuides', 'Available Audio Guides')}
                        </h2>
                        <div className="space-y-1.5">
                          {populatedLangs.map(langCode => {
                            const guides = guidesByLang[langCode]
                            return (
                              <div key={langCode} className="rounded-md border px-3 py-2">
                                <div className="flex items-center">
                                  <span className="text-sm font-medium">
                                    {LANG_LABELS[langCode] || langCode.toUpperCase()}
                                    <span className="text-muted-foreground font-normal ml-1.5">
                                      {guides.length}&times;
                                    </span>
                                  </span>
                                </div>
                                <div
                                  className="mt-1.5 grid items-center gap-x-2 gap-y-1.5 text-sm"
                                  style={{ gridTemplateColumns: 'minmax(0,12rem) minmax(0,24rem) auto auto auto 1fr' }}
                                >
                                  {guides.map(g => (
                                    <Fragment key={g.id}>
                                      {/* Col 1: Handle */}
                                      <span className="truncate text-xs text-muted-foreground/60">
                                        {g.uploader_handle ? `@${g.uploader_handle}`
                                          : g.uploaded_by ? `@${g.uploaded_by.slice(0, 8)}…` : ''}
                                      </span>
                                      {/* Col 2: Title */}
                                      <span className="truncate text-muted-foreground">
                                        {g.title || t('placeDetail.untitled', 'Untitled')}
                                      </span>
                                      {/* Col 3: Rating */}
                                      <span className="flex items-center gap-0.5 text-xs text-muted-foreground">
                                        {g.total_ratings != null && g.total_ratings > 0 ? (<>
                                          <Star className="h-3 w-3 text-yellow-500 fill-yellow-500" />
                                          {Number(g.avg_rating).toFixed(1)} ({g.total_ratings})
                                        </>) : null}
                                      </span>
                                      {/* Col 4: Rate button */}
                                      <span>
                                        {isLoggedIn ? (
                                          <button
                                            onClick={() => openRatingDialog(g)}
                                            className="text-xs px-1.5 py-0.5 rounded border border-muted-foreground/20 hover:bg-muted transition text-muted-foreground whitespace-nowrap"
                                          >
                                            {userRatings.has(g.id)
                                              ? `${t('placeDetail.yourRating', 'Your rating')}: ${userRatings.get(g.id)}`
                                              : t('placeDetail.rate', 'Rate')}
                                          </button>
                                        ) : null}
                                      </span>
                                      {/* Col 5: Duration */}
                                      <span className="text-xs text-muted-foreground tabular-nums whitespace-nowrap">
                                        {g.duration_sec != null ? formatDuration(g.duration_sec) : ''}
                                      </span>
                                      {/* Col 6: Audio player */}
                                      <div className="min-w-0">
                                        {audioUrls.has(g.id) ? (
                                          <div className="bg-gray-900 rounded px-1 py-0.5">
                                            <audio src={audioUrls.get(g.id)} controls className="h-7 w-full" />
                                          </div>
                                        ) : null}
                                      </div>
                                    </Fragment>
                                  ))}
                                </div>
                              </div>
                            )
                          })}
                        </div>
                        {!hasAudioAccess && (
                          <p className="text-xs text-muted-foreground">
                            {isLoggedIn
                              ? t('placeDetail.purchaseToListen', 'Purchase to listen')
                              : t('placeDetail.signInToListen', 'Sign in to listen')}
                          </p>
                        )}
                      </div>
                    )}

                    {/* Contributor card */}
                    {poi.contributor_name && (
                      <div className="flex items-center gap-3 p-3 rounded-md bg-muted/50">
                        {poi.contributor_avatar ? (
                          <img src={poi.contributor_avatar} alt="" className="h-10 w-10 rounded-full object-cover" />
                        ) : (
                          <div className="h-10 w-10 rounded-full bg-muted flex items-center justify-center">
                            <User className="h-5 w-5 text-muted-foreground" />
                          </div>
                        )}
                        <div className="flex-1">
                          <p className="text-sm font-medium flex items-center gap-1">
                            <span className="text-muted-foreground">@</span>{poi.contributor_name}
                            {poi.contributor_verified && <BadgeCheck className="h-4 w-4 text-primary" />}
                          </p>
                          <p className="text-xs text-muted-foreground">
                            {t('placeDetail.contributedBy', 'Contributor')}
                          </p>
                        </div>
                      </div>
                    )}

                    {/* Premium price notice + buy */}
                    {poi.poi_access_level === 'premium_poi' && poi.poi_premium_price && (
                      <div className="space-y-2">
                        <p className="text-sm font-medium text-primary">
                          {t('placeDetail.premiumContent', 'Premium content available')} &mdash; &euro;{poi.poi_premium_price.toFixed(2)}
                        </p>
                        {!hasAudioAccess && (
                          <BuyButton purchaseType="poi" poiId={poi.poi_id} price={poi.poi_premium_price} />
                        )}
                      </div>
                    )}

                    {/* Map + GPS coordinates */}
                    {poi.poi_lat && poi.poi_lng && (
                      <div className="space-y-2">
                        <div className="rounded-md overflow-hidden">
                          <MapPicker
                            latitude={poi.poi_lat}
                            longitude={poi.poi_lng}
                            onChange={() => {}}
                          />
                        </div>
                        <p className="text-xs text-muted-foreground text-center">
                          {formatCoord(poi.poi_lat, 'N', 'S')}, {formatCoord(poi.poi_lng, 'E', 'W')}
                        </p>
                      </div>
                    )}

                    {/* Open in App CTA */}
                    <div className="pt-2 space-y-3">
                      <a href={appDeepLink}>
                        <Button className="w-full">
                          <ExternalLink className="h-4 w-4 mr-2" />
                          {t('placeDetail.openInApp', 'Open in App')}
                        </Button>
                      </a>
                      <p className="text-xs text-center text-muted-foreground">
                        {t('placeDetail.downloadPrompt', "Don't have the app? Download PlaceSecrets for")}
                        {' '}
                        <span className="font-medium">Android</span> or{' '}
                        <span className="font-medium">iOS</span>.
                      </p>
                    </div>
                  </TabsContent>

                  {/* === Rating Tab === */}
                  <TabsContent value="rating" className="space-y-5 mt-4">
                    {/* Star summary */}
                    {poi.poi_avg_rating != null && poi.poi_total_ratings != null && poi.poi_total_ratings > 0 ? (
                      <div className="flex items-center gap-3">
                        <span className="text-3xl font-bold">{Number(poi.poi_avg_rating).toFixed(1)}</span>
                        <div>
                          <div className="flex">
                            {Array.from({ length: 5 }).map((_, i) => (
                              <Star
                                key={i}
                                className={`h-5 w-5 ${i < Math.round(poi.poi_avg_rating!) ? 'text-yellow-500 fill-yellow-500' : 'text-muted-foreground/30'}`}
                              />
                            ))}
                          </div>
                          <p className="text-sm text-muted-foreground">
                            {poi.poi_total_ratings} {t('placeDetail.reviews', 'Reviews').toLowerCase()}
                          </p>
                        </div>
                      </div>
                    ) : (
                      <p className="text-sm text-muted-foreground">{t('placeDetail.noReviews', 'No reviews yet')}</p>
                    )}

                    {/* Rate this place (logged-in users) */}
                    {user && (
                      <div className="space-y-3 rounded-lg border p-4">
                        {poiRated ? (
                          <p className="text-sm text-primary">{t('places.ratingThanks', 'Thanks for your rating!')}</p>
                        ) : (
                          <>
                            <p className="text-sm font-medium">{t('places.rateThisPlace', 'Rate this place')}</p>
                            <div className="flex gap-1">
                              {Array.from({ length: 5 }).map((_, i) => (
                                <button
                                  key={i}
                                  type="button"
                                  onClick={() => setPoiRating(i + 1)}
                                  className="p-0.5 transition-transform hover:scale-110"
                                  aria-label={`${i + 1}`}
                                >
                                  <Star className={`h-7 w-7 ${i < poiRating ? 'text-yellow-500 fill-yellow-500' : 'text-muted-foreground/30'}`} />
                                </button>
                              ))}
                            </div>
                            <textarea
                              value={poiComment}
                              onChange={e => setPoiComment(e.target.value)}
                              maxLength={1000}
                              rows={2}
                              placeholder={t('places.commentPlaceholder', 'Add a comment (optional)')}
                              className="w-full rounded-md border border-input bg-background px-3 py-2 text-sm"
                            />
                            {poiRatingError && <p className="text-sm text-destructive">{poiRatingError}</p>}
                            <Button size="sm" onClick={submitPoiRating} disabled={poiRating < 1 || poiRatingSubmitting}>
                              {t('places.submitRating', 'Submit rating')}
                            </Button>
                          </>
                        )}
                      </div>
                    )}

                    {/* Reviews list */}
                    {reviews.length > 0 && (
                      <div className="space-y-3">
                        {reviews.map((review) => (
                          <div key={review.review_id} className="border-b pb-3 last:border-0">
                            <div className="flex items-center justify-between">
                              <div className="flex items-center gap-1.5">
                                <div className="flex">
                                  {Array.from({ length: 5 }).map((_, i) => (
                                    <Star
                                      key={i}
                                      className={`h-3.5 w-3.5 ${i < review.rating ? 'text-yellow-500 fill-yellow-500' : 'text-muted-foreground/30'}`}
                                    />
                                  ))}
                                </div>
                                <span className={`text-xs font-medium ${review.is_own ? 'text-primary' : 'text-muted-foreground'}`}>
                                  {review.is_own
                                    ? t('placeDetail.myRating', 'My rating')
                                    : (review.display_name || t('placeDetail.anonymous', 'Anonymous'))}
                                </span>
                              </div>
                              <span className="text-xs text-muted-foreground">
                                {new Date(review.created_at).toLocaleDateString()}
                              </span>
                            </div>
                            {review.is_hidden ? (
                              <p className="text-sm text-muted-foreground/60 italic mt-1">
                                {t('placeDetail.hiddenByAdmin', 'Hidden by administrator')}
                              </p>
                            ) : review.comment ? (
                              <p className="text-sm text-foreground mt-1">{review.comment}</p>
                            ) : null}
                          </div>
                        ))}
                      </div>
                    )}

                    {/* Loading spinner */}
                    {reviewsLoading && (
                      <div className="flex items-center justify-center py-4 gap-2 text-muted-foreground">
                        <Loader2 className="h-4 w-4 animate-spin" />
                        <span className="text-sm">{t('placeDetail.loadingReviews', 'Loading reviews...')}</span>
                      </div>
                    )}

                    {/* Sentinel for IntersectionObserver */}
                    {reviews.length < reviewsTotalCount && !reviewsLoading && (
                      <div ref={sentinelRef} className="h-4" />
                    )}
                  </TabsContent>
                </Tabs>
              </CardContent>
            </Card>
          </div>
        </div>
        <PublicFooter />
      </div>

      {/* Rating dialog */}
      {ratingDialogGuide && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50" onClick={() => setRatingDialogGuide(null)}>
          <div className="bg-white rounded-lg shadow-lg p-6 max-w-sm w-full mx-4" onClick={e => e.stopPropagation()}>
            <div className="flex items-center justify-between mb-4">
              <h3 className="text-lg font-semibold">{t('placeDetail.rateGuide', 'Rate Audio Guide')}</h3>
              <button onClick={() => setRatingDialogGuide(null)} className="p-1 hover:bg-muted rounded">
                <X className="h-4 w-4" />
              </button>
            </div>
            <p className="text-sm text-muted-foreground mb-4">{ratingDialogGuide.title || t('placeDetail.untitled', 'Untitled')}</p>
            <div className="flex justify-center gap-1 mb-6">
              {Array.from({ length: 5 }).map((_, i) => (
                <button
                  key={i}
                  onClick={() => setPendingRating(i + 1)}
                  className="p-1 hover:scale-110 transition-transform"
                >
                  <Star
                    className={`h-8 w-8 ${i < pendingRating ? 'text-yellow-500 fill-yellow-500' : 'text-muted-foreground/30'}`}
                  />
                </button>
              ))}
            </div>
            {ratingError && (
              <p className="text-sm text-red-600 text-center mb-2">{ratingError}</p>
            )}
            <div className="flex gap-2 justify-end">
              <Button variant="outline" onClick={() => setRatingDialogGuide(null)}>
                {t('common.cancel', 'Cancel')}
              </Button>
              <Button onClick={submitRating} disabled={pendingRating < 1 || ratingSubmitting}>
                {t('common.confirm', 'Confirm')}
              </Button>
            </div>
          </div>
        </div>
      )}
    </>
  )
}
