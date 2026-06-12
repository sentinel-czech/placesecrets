import { useEffect, useState } from 'react'
import { useParams, useNavigate } from 'react-router-dom'
import { useAuthStore } from '@/hooks/useAuth'
import { supabase } from '@/lib/supabase/client'
import { adminSelect, adminInsert } from '@/lib/supabase/admin-api'
import type { Poi, City, Country } from '@/lib/supabase/types'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs'
import { Skeleton } from '@/components/ui/skeleton'
import { MapPicker } from '@/components/shared/MapPicker'
import { PhotoUploader } from '@/components/pois/PhotoUploader'
import { AudioUploader } from '@/components/pois/AudioUploader'
import { TagInput } from '@/components/shared/TagInput'
import { toast } from 'sonner'
import { useTranslation } from 'react-i18next'

export default function MyPoiEditorPage() {
  const { poiId } = useParams<{ poiId: string }>()
  const navigate = useNavigate()
  const { user } = useAuthStore()
  const { t } = useTranslation()
  const isNew = !poiId

  const [poi, setPoi] = useState<Poi | null>(null)
  const [cities, setCities] = useState<City[]>([])
  const [countries, setCountries] = useState<Country[]>([])
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
  const [aliases, setAliases] = useState<string[]>([])
  const [photoUrls, setPhotoUrls] = useState<string[]>([])

  const [showCityForm, setShowCityForm] = useState(false)
  const [newCityName, setNewCityName] = useState('')
  const [newCityCountryCode, setNewCityCountryCode] = useState('')
  const [newCityLat, setNewCityLat] = useState(50.08)
  const [newCityLng, setNewCityLng] = useState(14.42)
  const [creatingCity, setCreatingCity] = useState(false)

  useEffect(() => {
    let cancelled = false
    Promise.all([
      adminSelect('cities', {
        select: 'id, name, country_code',
        order: { column: 'name' },
      }),
      adminSelect('countries', { order: { column: 'name' } }),
    ]).then(([citiesRes, countriesRes]) => {
      if (cancelled) return
      if (citiesRes.error) setError(citiesRes.error)
      else if (citiesRes.data) setCities(citiesRes.data as City[])
      if (countriesRes.data) setCountries(countriesRes.data as Country[])
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
          setAliases(p.aliases || [])
          setPhotoUrls(p.photo_urls || [])

        }
        setLoading(false)
      })
    }

    return () => { cancelled = true }
  }, [poiId])

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault()
    if (!cityId || !nameCs) { toast.error(t('admin.myPois.cityNameRequired', 'City and Czech name are required')); return }
    if (!user) { toast.error(t('admin.myPois.notAuthenticated', 'Not authenticated')); return }

    setSaving(true)
    const payload = {
      city_id: cityId,
      name: { cs: nameCs, en: nameEn },
      description: { cs: descCs, en: descEn },
      latitude: lat,
      longitude: lng,
      contributor_id: user.id,
      contributor_note: note,
      aliases,
      photo_urls: photoUrls,
      is_active: false,
    }

    if (isNew) {
      const { error } = await supabase.from('pois').insert(payload)
      if (error) toast.error(error.message)
      else { toast.success(t('admin.myPois.poiSubmitted', 'POI submitted for review')); navigate('/admin/my-pois') }
    } else {
      const { error } = await supabase.from('pois').update(payload).eq('id', poiId!)
      if (error) toast.error(error.message)
      else { toast.success(t('admin.myPois.poiUpdated', 'POI updated')); navigate('/admin/my-pois') }
    }
    setSaving(false)
  }

  if (loading) return <Skeleton className="h-96 max-w-2xl" />
  if (error) return <p className="text-destructive">{error}</p>

  const effectivePoiId = poiId || 'new'

  return (
    <div className="max-w-2xl">
      <h1 className="text-xl font-semibold mb-4">{isNew ? t('admin.myPois.addNew', 'New Place') : `${t('common.edit')}: ${poi?.name?.cs}`}</h1>
      <form onSubmit={handleSubmit} className="space-y-6">
        <Card>
          <CardHeader><CardTitle className="text-base">{t('admin.myPois.content', 'Content')}</CardTitle></CardHeader>
          <CardContent className="space-y-4">
            <div className="space-y-2">
              <Label>{t('admin.myPois.citySelect', 'City')}</Label>
              <select
                value={showCityForm ? '__create_new__' : cityId}
                onChange={e => {
                  if (e.target.value === '__create_new__') {
                    setShowCityForm(true)
                    setCityId('')
                  } else {
                    setShowCityForm(false)
                    setCityId(e.target.value)
                  }
                }}
                className="w-full rounded-md border px-3 py-2 text-sm"
                required={!showCityForm}
                aria-label="Select city"
              >
                <option value="">{t('admin.myPois.citySearchPlaceholder', 'Select city...')}</option>
                {(() => {
                  const countryMap = new Map<string, Country>()
                  countries.forEach(c => countryMap.set(c.code, c))
                  const grouped = new Map<string, City[]>()
                  cities.forEach(c => {
                    const list = grouped.get(c.country_code) || []
                    list.push(c)
                    grouped.set(c.country_code, list)
                  })
                  return Array.from(grouped.entries())
                    .sort((a, b) => {
                      const na = countryMap.get(a[0])?.name || a[0]
                      const nb = countryMap.get(b[0])?.name || b[0]
                      return na.localeCompare(nb)
                    })
                    .map(([code, cs]) => (
                      <optgroup key={code} label={countryMap.get(code)?.name || code}>
                        {cs.map(c => <option key={c.id} value={c.id}>{c.name} ({c.country_code})</option>)}
                      </optgroup>
                    ))
                })()}
                <option value="__create_new__">+ {t('admin.myPois.createNewCity', 'Create new city/area')}</option>
              </select>

              {showCityForm && (
                <div className="rounded-md border p-4 space-y-3 bg-muted/30">
                  <p className="text-sm font-medium">{t('admin.myPois.newCityDetails', 'New City Details')}</p>
                  <div className="grid gap-3 md:grid-cols-2">
                    <div className="space-y-1">
                      <Label className="text-xs">{t('common.name')}</Label>
                      <Input value={newCityName} onChange={e => setNewCityName(e.target.value)} placeholder={t('admin.myPois.cityNamePlaceholder', 'e.g. Prague')} />
                    </div>
                    <div className="space-y-1">
                      <Label className="text-xs">{t('admin.myPois.country', 'Country')}</Label>
                      <select
                        value={newCityCountryCode}
                        onChange={e => setNewCityCountryCode(e.target.value)}
                        className="w-full rounded-md border px-3 py-2 text-sm"
                      >
                        <option value="">{t('admin.myPois.selectCountry', 'Select country...')}</option>
                        {countries.map(c => (
                          <option key={c.code} value={c.code}>{c.name} ({c.code})</option>
                        ))}
                      </select>
                    </div>
                  </div>
                  <div className="grid gap-3 md:grid-cols-2">
                    <div className="space-y-1">
                      <Label className="text-xs">{t('admin.myPois.latitude', 'Latitude')}</Label>
                      <Input type="number" step="any" value={newCityLat} onChange={e => setNewCityLat(Number(e.target.value))} />
                    </div>
                    <div className="space-y-1">
                      <Label className="text-xs">{t('admin.myPois.longitude', 'Longitude')}</Label>
                      <Input type="number" step="any" value={newCityLng} onChange={e => setNewCityLng(Number(e.target.value))} />
                    </div>
                  </div>
                  <MapPicker latitude={newCityLat} longitude={newCityLng} onChange={(la, ln) => { setNewCityLat(la); setNewCityLng(ln) }} />
                  <p className="text-xs text-muted-foreground">{t('admin.myPois.newCityNote', 'New city will be inactive until approved by admin.')}</p>
                  <Button
                    type="button"
                    variant="outline"
                    size="sm"
                    disabled={creatingCity}
                    onClick={async () => {
                      if (!newCityName.trim() || !newCityCountryCode) {
                        toast.error(t('admin.myPois.cityFieldsRequired', 'City name and country are required'))
                        return
                      }
                      setCreatingCity(true)
                      const { data: created, error: createErr } = await adminInsert('cities', {
                        name: newCityName.trim(),
                        country_code: newCityCountryCode,
                        latitude: newCityLat,
                        longitude: newCityLng,
                        price_eur: 0,
                        is_active: false,
                      }, { select: 'id, name, country_code', single: true })
                      setCreatingCity(false)
                      if (createErr) {
                        toast.error(createErr)
                        return
                      }
                      const newCity = created as City
                      setCities(prev => [...prev, newCity].sort((a, b) => a.name.localeCompare(b.name)))
                      setCityId(newCity.id)
                      setShowCityForm(false)
                      setNewCityName('')
                      setNewCityCountryCode('')
                      toast.success(t('admin.myPois.cityCreated', 'City created successfully'))
                    }}
                  >
                    {creatingCity ? t('common.loading') : t('admin.myPois.createCity', 'Create City')}
                  </Button>
                </div>
              )}
            </div>

            <Tabs defaultValue="cs">
              <TabsList>
                <TabsTrigger value="cs">{t('admin.myPois.langCs', 'Czech')}</TabsTrigger>
                <TabsTrigger value="en">{t('admin.myPois.langEn', 'English')}</TabsTrigger>
              </TabsList>
              <TabsContent value="cs" className="space-y-3 mt-3">
                <div className="space-y-2">
                  <Label>{t('admin.myPois.nameCs', 'Name (CS)')}</Label>
                  <Input value={nameCs} onChange={e => setNameCs(e.target.value)} required />
                </div>
                <div className="space-y-2">
                  <Label>{t('admin.myPois.descCs', 'Description (CS)')}</Label>
                  <textarea value={descCs} onChange={e => setDescCs(e.target.value)} rows={6} className="w-full rounded-md border px-3 py-2 text-sm" />
                </div>
              </TabsContent>
              <TabsContent value="en" className="space-y-3 mt-3">
                <div className="space-y-2">
                  <Label>{t('admin.myPois.nameEn', 'Name (EN)')}</Label>
                  <Input value={nameEn} onChange={e => setNameEn(e.target.value)} />
                </div>
                <div className="space-y-2">
                  <Label>{t('admin.myPois.descEn', 'Description (EN)')}</Label>
                  <textarea value={descEn} onChange={e => setDescEn(e.target.value)} rows={6} className="w-full rounded-md border px-3 py-2 text-sm" />
                </div>
              </TabsContent>
            </Tabs>

            <div className="space-y-2">
              <Label>{t('poiForm.aliases', 'Aliases / Alternative Names')}</Label>
              <TagInput value={aliases} onChange={setAliases} placeholder={t('poiForm.aliasPlaceholder', 'Type and press Enter...')} />
              <p className="text-xs text-muted-foreground">{t('poiForm.aliasesHelp', 'Alternative names for this place')}</p>
            </div>

            <div className="space-y-2">
              <Label>{t('admin.myPois.noteForReviewer', 'Note for reviewer')}</Label>
              <textarea value={note} onChange={e => setNote(e.target.value)} rows={2} className="w-full rounded-md border px-3 py-2 text-sm" placeholder={t('admin.myPois.noteForReviewerPlaceholder', 'Any notes for the admin reviewing this POI...')} />
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardHeader><CardTitle className="text-base">{t('admin.myPois.location', 'Location')}</CardTitle></CardHeader>
          <CardContent className="space-y-4">
            <div className="grid gap-4 md:grid-cols-2">
              <div className="space-y-2">
                <Label>{t('admin.myPois.latitude', 'Latitude')}</Label>
                <Input type="number" step="any" value={lat} onChange={e => setLat(Number(e.target.value))} />
              </div>
              <div className="space-y-2">
                <Label>{t('admin.myPois.longitude', 'Longitude')}</Label>
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
          <CardHeader><CardTitle className="text-base">{t('admin.myPois.photos', 'Photos')}</CardTitle></CardHeader>
          <CardContent>
            <PhotoUploader poiId={effectivePoiId} photos={photoUrls} onChange={setPhotoUrls} />
          </CardContent>
        </Card>

        <Card>
          <CardHeader><CardTitle className="text-base">{t('admin.myPois.audioUpload', 'Audio Guides')}</CardTitle></CardHeader>
          <CardContent>
            <AudioUploader poiId={effectivePoiId} contributorId={user?.id} />
            <p className="text-xs text-muted-foreground mt-2">{t('admin.myPois.audioFormats')}</p>
          </CardContent>
        </Card>

        <Button type="submit" disabled={saving}>
          {saving ? t('common.loading') : isNew ? t('admin.myPois.addNew', 'Submit for Review') : t('common.save')}
        </Button>
      </form>
    </div>
  )
}
