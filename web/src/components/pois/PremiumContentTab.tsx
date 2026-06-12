import { useEffect, useState } from 'react'
import { adminSelect, adminUpsert, adminStorageUploadUpsert, adminStorageGetPublicUrl } from '@/lib/supabase/admin-api'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Textarea } from '@/components/ui/textarea'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import type { PoiPremiumContent, Poi } from '@/lib/supabase/types'
import { toast } from 'sonner'
import { Upload, X, Plus } from 'lucide-react'

interface PremiumContentTabProps {
  poiId: string
  cityId: string
}

export function PremiumContentTab({ poiId, cityId }: PremiumContentTabProps) {
  const [, setContent] = useState<PoiPremiumContent | null>(null)
  const [textContent, setTextContent] = useState('')
  const [audioUrl, setAudioUrl] = useState('')
  const [extraPhotos, setExtraPhotos] = useState<string[]>([])
  const [relatedPoiIds, setRelatedPoiIds] = useState<string[]>([])
  const [availablePois, setAvailablePois] = useState<Pick<Poi, 'id' | 'name'>[]>([])
  const [loading, setLoading] = useState(true)
  const [saving, setSaving] = useState(false)
  const [uploading, setUploading] = useState(false)

  useEffect(() => {
    let cancelled = false
    Promise.all([
      adminSelect('poi_premium_content', {
        filters: [{ column: 'poi_id', op: 'eq', value: poiId }],
        single: true,
      }),
      adminSelect('pois', {
        select: 'id, name',
        filters: [{ column: 'city_id', op: 'eq', value: cityId }],
        order: { column: 'sort_order' },
      }),
    ]).then(([contentRes, poisRes]) => {
      if (cancelled) return
      if (contentRes.data) {
        const c = contentRes.data as PoiPremiumContent
        setContent(c)
        setTextContent(c.text_content || '')
        setAudioUrl(c.audio_url || '')
        setExtraPhotos(c.extra_photos || [])
        setRelatedPoiIds(c.related_poi_ids || [])
      }
      if (poisRes.data) {
        setAvailablePois(
          (poisRes.data as Pick<Poi, 'id' | 'name'>[]).filter(p => p.id !== poiId)
        )
      }
      setLoading(false)
    })
    return () => { cancelled = true }
  }, [poiId, cityId])

  async function handleSave() {
    setSaving(true)
    const { error } = await adminUpsert('poi_premium_content', {
      poi_id: poiId,
      text_content: textContent || null,
      audio_url: audioUrl || null,
      extra_photos: extraPhotos,
      related_poi_ids: relatedPoiIds,
    }, 'poi_id')
    setSaving(false)
    if (error) toast.error(error)
    else toast.success('Premium content saved')
  }

  async function handleAudioUpload(e: React.ChangeEvent<HTMLInputElement>) {
    const file = e.target.files?.[0]
    if (!file) return
    setUploading(true)
    const path = `${poiId}/${file.name}`
    const { error } = await adminStorageUploadUpsert('premium-audio', path, file)
    if (error) {
      toast.error(error)
    } else {
      const { publicUrl } = await adminStorageGetPublicUrl('premium-audio', path)
      if (publicUrl) setAudioUrl(publicUrl)
      toast.success('Audio uploaded')
    }
    setUploading(false)
  }

  function addRelatedPoi(id: string) {
    if (!relatedPoiIds.includes(id)) {
      setRelatedPoiIds([...relatedPoiIds, id])
    }
  }

  function removeRelatedPoi(id: string) {
    setRelatedPoiIds(relatedPoiIds.filter(r => r !== id))
  }

  if (loading) return <p className="text-sm text-muted-foreground">Loading premium content...</p>

  return (
    <div className="space-y-6">
      <Card>
        <CardHeader><CardTitle className="text-base">Premium Audio</CardTitle></CardHeader>
        <CardContent className="space-y-3">
          {audioUrl && (
            <div className="flex items-center gap-2">
              <audio controls src={audioUrl} className="flex-1" />
              <button type="button" onClick={() => setAudioUrl('')} className="text-destructive">
                <X className="h-4 w-4" />
              </button>
            </div>
          )}
          <div className="flex items-center gap-2">
            <label className="cursor-pointer inline-flex items-center gap-2 px-3 py-2 text-sm border rounded-md hover:bg-accent transition-colors">
              <Upload className="h-4 w-4" />
              {uploading ? 'Uploading...' : 'Upload Audio'}
              <input type="file" accept="audio/*" onChange={handleAudioUpload} className="hidden" disabled={uploading} />
            </label>
          </div>
        </CardContent>
      </Card>

      <Card>
        <CardHeader><CardTitle className="text-base">Premium Text Content</CardTitle></CardHeader>
        <CardContent>
          <Textarea
            value={textContent}
            onChange={e => setTextContent(e.target.value)}
            rows={8}
            placeholder="Extended description for premium users..."
          />
        </CardContent>
      </Card>

      <Card>
        <CardHeader><CardTitle className="text-base">Extra Photos</CardTitle></CardHeader>
        <CardContent className="space-y-3">
          {extraPhotos.map((url, i) => (
            <div key={i} className="flex items-center gap-2">
              <Input
                value={url}
                onChange={e => {
                  const updated = [...extraPhotos]
                  updated[i] = e.target.value
                  setExtraPhotos(updated)
                }}
                placeholder="Photo URL"
              />
              <button type="button" onClick={() => setExtraPhotos(extraPhotos.filter((_, j) => j !== i))} className="text-destructive">
                <X className="h-4 w-4" />
              </button>
            </div>
          ))}
          <Button type="button" variant="outline" size="sm" onClick={() => setExtraPhotos([...extraPhotos, ''])}>
            <Plus className="h-4 w-4 mr-1" /> Add Photo URL
          </Button>
        </CardContent>
      </Card>

      <Card>
        <CardHeader><CardTitle className="text-base">Related POIs</CardTitle></CardHeader>
        <CardContent className="space-y-3">
          {relatedPoiIds.map(rid => {
            const p = availablePois.find(x => x.id === rid)
            return (
              <div key={rid} className="flex items-center justify-between py-1">
                <span className="text-sm">{p?.name?.cs || p?.name?.en || rid}</span>
                <button type="button" onClick={() => removeRelatedPoi(rid)} className="text-destructive">
                  <X className="h-4 w-4" />
                </button>
              </div>
            )
          })}
          <div className="flex gap-2">
            <select
              className="flex-1 rounded-md border px-3 py-2 text-sm"
              onChange={e => { if (e.target.value) addRelatedPoi(e.target.value); e.target.value = '' }}
              defaultValue=""
              aria-label="Add related POI"
            >
              <option value="">Add related POI...</option>
              {availablePois
                .filter(p => !relatedPoiIds.includes(p.id))
                .map(p => (
                  <option key={p.id} value={p.id}>{p.name?.cs || p.name?.en}</option>
                ))}
            </select>
          </div>
        </CardContent>
      </Card>

      <Button onClick={handleSave} disabled={saving}>
        {saving ? 'Saving...' : 'Save Premium Content'}
      </Button>
    </div>
  )
}
