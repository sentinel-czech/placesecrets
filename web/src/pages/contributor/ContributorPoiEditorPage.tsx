import { useEffect, useState } from 'react'
import { useParams, useNavigate } from 'react-router-dom'
import { useAuthStore } from '@/hooks/useAuth'
import { supabase } from '@/lib/supabase/client'
import { adminSelect } from '@/lib/supabase/admin-api'
import type { Poi, City } from '@/lib/supabase/types'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs'
import { Skeleton } from '@/components/ui/skeleton'
import { MapPicker } from '@/components/shared/MapPicker'
import { PhotoUploader } from '@/components/pois/PhotoUploader'
import { AudioUploader } from '@/components/pois/AudioUploader'
import { toast } from 'sonner'

export default function ContributorPoiEditorPage() {
  const { poiId } = useParams<{ poiId: string }>()
  const navigate = useNavigate()
  const { user } = useAuthStore()
  const isNew = !poiId

  const [poi, setPoi] = useState<Poi | null>(null)
  const [cities, setCities] = useState<City[]>([])
  const [loading, setLoading] = useState(!isNew)
  const [saving, setSaving] = useState(false)
  const [error, setError] = useState('')

  const [nameCs, setNameCs] = useState('')
  const [nameEn, setNameEn] = useState('')
  const [descCs, setDescCs] = useState('')
  const [descEn, setDescEn] = useState('')
  const [cityId, setCityId] = useState('')
  const [lat, setLat] = useState(50.08)
  const [lng, setLng] = useState(14.42)
  const [note, setNote] = useState('')
  const [photoUrls, setPhotoUrls] = useState<string[]>([])

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

    if (poiId) {
      supabase.from('pois').select('*').eq('id', poiId).single().then(({ data }) => {
        if (cancelled) return
        if (data) {
          const p = data as Poi
          setPoi(p)
          setNameCs(p.name?.cs || '')
          setNameEn(p.name?.en || '')
          setDescCs(p.description?.cs || '')
          setDescEn(p.description?.en || '')
          setCityId(p.city_id)
          setLat(p.latitude)
          setLng(p.longitude)
          setNote(p.contributor_note || '')
          setPhotoUrls(p.photo_urls || [])

        }
        setLoading(false)
      })
    }

    return () => { cancelled = true }
  }, [poiId])

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault()
    if (!cityId || !nameCs) { toast.error('City and Czech name are required'); return }
    if (!user) { toast.error('Not authenticated'); return }

    setSaving(true)
    const payload = {
      city_id: cityId,
      name: { cs: nameCs, en: nameEn },
      description: { cs: descCs, en: descEn },
      latitude: lat,
      longitude: lng,
      contributor_id: user.id,
      contributor_note: note,
      photo_urls: photoUrls,
      is_active: false,
    }

    if (isNew) {
      const { error } = await supabase.from('pois').insert(payload)
      if (error) toast.error(error.message)
      else { toast.success('POI submitted for review'); navigate('/contributor/pois') }
    } else {
      const { error } = await supabase.from('pois').update(payload).eq('id', poiId!)
      if (error) toast.error(error.message)
      else { toast.success('POI updated'); navigate('/contributor/pois') }
    }
    setSaving(false)
  }

  if (loading) return <Skeleton className="h-96 max-w-2xl" />
  if (error) return <p className="text-destructive">{error}</p>

  const effectivePoiId = poiId || 'new'

  return (
    <div className="max-w-2xl">
      <h2 className="text-lg font-semibold mb-4">{isNew ? 'New POI' : `Edit: ${poi?.name?.cs}`}</h2>
      <form onSubmit={handleSubmit} className="space-y-6">
        <Card>
          <CardHeader><CardTitle className="text-base">Content</CardTitle></CardHeader>
          <CardContent className="space-y-4">
            <div className="space-y-2">
              <Label>City</Label>
              <select value={cityId} onChange={e => setCityId(e.target.value)} className="w-full rounded-md border px-3 py-2 text-sm" required aria-label="Select city">
                <option value="">Select city...</option>
                {cities.map(c => <option key={c.id} value={c.id}>{c.name}</option>)}
              </select>
            </div>

            <Tabs defaultValue="cs">
              <TabsList>
                <TabsTrigger value="cs">Czech</TabsTrigger>
                <TabsTrigger value="en">English</TabsTrigger>
              </TabsList>
              <TabsContent value="cs" className="space-y-3 mt-3">
                <div className="space-y-2">
                  <Label>Name (CS)</Label>
                  <Input value={nameCs} onChange={e => setNameCs(e.target.value)} required />
                </div>
                <div className="space-y-2">
                  <Label>Description (CS)</Label>
                  <textarea value={descCs} onChange={e => setDescCs(e.target.value)} rows={6} className="w-full rounded-md border px-3 py-2 text-sm" />
                </div>
              </TabsContent>
              <TabsContent value="en" className="space-y-3 mt-3">
                <div className="space-y-2">
                  <Label>Name (EN)</Label>
                  <Input value={nameEn} onChange={e => setNameEn(e.target.value)} />
                </div>
                <div className="space-y-2">
                  <Label>Description (EN)</Label>
                  <textarea value={descEn} onChange={e => setDescEn(e.target.value)} rows={6} className="w-full rounded-md border px-3 py-2 text-sm" />
                </div>
              </TabsContent>
            </Tabs>

            <div className="space-y-2">
              <Label>Note for reviewer</Label>
              <textarea value={note} onChange={e => setNote(e.target.value)} rows={2} className="w-full rounded-md border px-3 py-2 text-sm" placeholder="Any notes for the admin reviewing this POI..." />
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardHeader><CardTitle className="text-base">Location</CardTitle></CardHeader>
          <CardContent className="space-y-4">
            <div className="grid gap-4 md:grid-cols-2">
              <div className="space-y-2">
                <Label>Latitude</Label>
                <Input type="number" step="any" value={lat} onChange={e => setLat(Number(e.target.value))} />
              </div>
              <div className="space-y-2">
                <Label>Longitude</Label>
                <Input type="number" step="any" value={lng} onChange={e => setLng(Number(e.target.value))} />
              </div>
            </div>
            <MapPicker
              latitude={lat}
              longitude={lng}
              onChange={(newLat, newLng) => { setLat(newLat); setLng(newLng) }}
            />
          </CardContent>
        </Card>

        <Card>
          <CardHeader><CardTitle className="text-base">Photos</CardTitle></CardHeader>
          <CardContent>
            <PhotoUploader poiId={effectivePoiId} photos={photoUrls} onChange={setPhotoUrls} />
          </CardContent>
        </Card>

        <Card>
          <CardHeader><CardTitle className="text-base">Audio Guides</CardTitle></CardHeader>
          <CardContent>
            <AudioUploader poiId={effectivePoiId} contributorId={user?.id} />
          </CardContent>
        </Card>

        <Button type="submit" disabled={saving}>
          {saving ? 'Saving...' : isNew ? 'Submit for Review' : 'Update POI'}
        </Button>
      </form>
    </div>
  )
}
