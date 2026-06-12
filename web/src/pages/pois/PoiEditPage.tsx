import { useEffect, useState } from 'react'
import { useParams, useNavigate } from 'react-router-dom'
import { adminSelect, adminUpdate, adminDelete } from '@/lib/supabase/admin-api'
import { PoiForm } from '@/components/pois/PoiForm'
import { PremiumContentTab } from '@/components/pois/PremiumContentTab'
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Skeleton } from '@/components/ui/skeleton'
import { Button } from '@/components/ui/button'
import { Star, Eye, EyeOff, Trash2 } from 'lucide-react'
import type { Poi, PoiRating } from '@/lib/supabase/types'
import { toast } from 'sonner'
import { format } from 'date-fns'
import { useTranslation } from 'react-i18next'

export default function PoiEditPage() {
  const { cityId, poiId } = useParams<{ cityId: string; poiId: string }>()
  const navigate = useNavigate()
  const { t } = useTranslation()
  const [poi, setPoi] = useState<Poi | null>(null)
  const [ratings, setRatings] = useState<PoiRating[]>([])
  const [loading, setLoading] = useState(true)
  const [saving, setSaving] = useState(false)
  const [error, setError] = useState('')
  const [confirmDeleteId, setConfirmDeleteId] = useState<string | null>(null)

  function fetchRatings() {
    if (!poiId) return
    adminSelect('poi_ratings', {
      filters: [{ column: 'poi_id', op: 'eq', value: poiId }],
      order: { column: 'created_at', ascending: false },
    }).then(res => {
      if (res.data) setRatings(res.data as PoiRating[])
    })
  }

  useEffect(() => {
    if (!poiId) return
    let cancelled = false
    Promise.all([
      adminSelect('pois', {
        filters: [{ column: 'id', op: 'eq', value: poiId }],
        single: true,
      }),
      adminSelect('poi_ratings', {
        filters: [{ column: 'poi_id', op: 'eq', value: poiId }],
        order: { column: 'created_at', ascending: false },
      }),
    ]).then(([poiRes, ratingsRes]) => {
      if (cancelled) return
      if (poiRes.error) setError(poiRes.error)
      else setPoi(poiRes.data as Poi | null)
      if (ratingsRes.data) setRatings(ratingsRes.data as PoiRating[])
      setLoading(false)
    })
    return () => { cancelled = true }
  }, [poiId])

  async function handleSubmit(data: Record<string, unknown>) {
    if (!poiId) return
    setSaving(true)
    const { error } = await adminUpdate('pois', data, [{ column: 'id', op: 'eq', value: poiId }])
    setSaving(false)
    if (error) {
      toast.error(error)
    } else {
      toast.success('POI updated')
      navigate(`/admin/cities/${cityId}/pois`)
    }
  }

  async function handleToggleHidden(rating: PoiRating) {
    const { error } = await adminUpdate(
      'poi_ratings',
      { is_hidden: !rating.is_hidden },
      [{ column: 'id', op: 'eq', value: rating.id }]
    )
    if (error) {
      toast.error(error)
    } else {
      toast.success(rating.is_hidden ? t('poiEditPage.ratingUnhidden', 'Rating unhidden') : t('poiEditPage.ratingHidden', 'Rating hidden'))
      fetchRatings()
    }
  }

  async function handleDeleteRating(ratingId: string) {
    if (confirmDeleteId !== ratingId) {
      setConfirmDeleteId(ratingId)
      return
    }
    const { error } = await adminDelete('poi_ratings', [{ column: 'id', op: 'eq', value: ratingId }])
    if (error) {
      toast.error(error)
    } else {
      toast.success(t('poiEditPage.ratingDeleted', 'Rating deleted'))
      setConfirmDeleteId(null)
      fetchRatings()
    }
  }

  if (loading) return <Skeleton className="h-96" />
  if (error) return <p className="text-destructive">{error}</p>
  if (!poi) return <p>POI not found</p>

  const showPremiumTab = poi.access_level === 'premium_poi'

  return (
    <div>
      <h2 className="text-lg font-semibold mb-4">Edit: {poi.name?.cs || poi.name?.en}</h2>
      <Tabs defaultValue="basic">
        <TabsList>
          <TabsTrigger value="basic">Basic Info</TabsTrigger>
          {showPremiumTab && <TabsTrigger value="premium">Premium Content</TabsTrigger>}
          <TabsTrigger value="ratings">Ratings ({ratings.length})</TabsTrigger>
        </TabsList>
        <TabsContent value="basic" className="mt-4">
          <PoiForm cityId={cityId!} initial={poi} onSubmit={handleSubmit} loading={saving} />
        </TabsContent>
        {showPremiumTab && (
          <TabsContent value="premium" className="mt-4">
            <PremiumContentTab poiId={poiId!} cityId={cityId!} />
          </TabsContent>
        )}
        <TabsContent value="ratings" className="mt-4">
          <Card>
            <CardHeader>
              <CardTitle className="text-base flex items-center gap-2">
                <Star className="h-4 w-4" />
                Ratings
                {poi.avg_rating != null && (
                  <span className="text-sm font-normal text-muted-foreground">
                    (avg: {Number(poi.avg_rating).toFixed(1)} from {poi.total_ratings} ratings)
                  </span>
                )}
              </CardTitle>
            </CardHeader>
            <CardContent>
              {ratings.length === 0 ? (
                <p className="text-sm text-muted-foreground">No ratings yet</p>
              ) : (
                <div className="space-y-3">
                  {ratings.map(r => (
                    <div
                      key={r.id}
                      className={`flex items-start justify-between border-b pb-3 last:border-0 ${r.is_hidden ? 'opacity-50' : ''}`}
                    >
                      <div className="space-y-1 flex-1">
                        <div className="flex items-center gap-2">
                          <div className="flex">
                            {Array.from({ length: 5 }).map((_, i) => (
                              <Star
                                key={i}
                                className={`h-3.5 w-3.5 ${i < r.rating ? 'text-yellow-500 fill-yellow-500' : 'text-muted-foreground/30'}`}
                              />
                            ))}
                          </div>
                          <span className="text-xs text-muted-foreground">{r.lang_code.toUpperCase()}</span>
                          {r.is_hidden && (
                            <span className="text-xs px-1.5 py-0.5 rounded bg-red-100 text-red-700">
                              {t('poiEditPage.hidden', 'Hidden')}
                            </span>
                          )}
                        </div>
                        {r.reason && <p className="text-sm">{r.reason}</p>}
                        {r.comment && (
                          <p className="text-sm text-muted-foreground italic">
                            {r.comment}
                          </p>
                        )}
                      </div>
                      <div className="flex items-center gap-1 ml-4 shrink-0">
                        <span className="text-xs text-muted-foreground whitespace-nowrap mr-2">
                          {format(new Date(r.created_at), 'dd.MM.yyyy')}
                        </span>
                        <Button
                          variant="ghost"
                          size="sm"
                          className="h-7 w-7 p-0"
                          onClick={() => handleToggleHidden(r)}
                          title={r.is_hidden ? t('poiEditPage.unhideRating', 'Unhide') : t('poiEditPage.hideRating', 'Hide')}
                        >
                          {r.is_hidden ? <Eye className="h-3.5 w-3.5" /> : <EyeOff className="h-3.5 w-3.5" />}
                        </Button>
                        <Button
                          variant="ghost"
                          size="sm"
                          className={`h-7 w-7 p-0 ${confirmDeleteId === r.id ? 'text-red-600' : ''}`}
                          onClick={() => handleDeleteRating(r.id)}
                          title={confirmDeleteId === r.id ? t('poiEditPage.confirmDeleteRating', 'Click again to confirm') : t('poiEditPage.deleteRating', 'Delete')}
                        >
                          <Trash2 className="h-3.5 w-3.5" />
                        </Button>
                      </div>
                    </div>
                  ))}
                </div>
              )}
            </CardContent>
          </Card>
        </TabsContent>
      </Tabs>
    </div>
  )
}
