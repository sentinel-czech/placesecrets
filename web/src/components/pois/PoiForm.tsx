import { useEffect, useState } from 'react'
import { useForm, type Resolver } from 'react-hook-form'
import { zodResolver } from '@hookform/resolvers/zod'
import { z } from 'zod'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Textarea } from '@/components/ui/textarea'
import { MapPicker } from '@/components/shared/MapPicker'
import { PhotoUploader } from './PhotoUploader'
import { AudioUploader } from './AudioUploader'
import { TagInput } from '@/components/shared/TagInput'
import { adminSelect } from '@/lib/supabase/admin-api'
import type { Poi, PoiType, PoiAccessLevel } from '@/lib/supabase/types'
import { Copy, Check } from 'lucide-react'
import { toast } from 'sonner'
import { useTranslation } from 'react-i18next'
import { LANG_CODES, LANG_LABELS } from '@/lib/constants'

// Build schema dynamically for all languages (description + perex only)
const langFields: Record<string, z.ZodTypeAny> = {}
for (const code of LANG_CODES) {
  langFields[`description_${code}`] = z.string()
  langFields[`perex_${code}`] = z.string().max(300).optional()
}

const poiSchema = z.object({
  name: z.string().min(1),
  ...langFields,
  latitude: z.coerce.number().min(-90).max(90),
  longitude: z.coerce.number().min(-180).max(180),
  geofence_radius: z.coerce.number().positive(),
  is_premium: z.boolean(),
  is_active: z.boolean(),
  sort_order: z.coerce.number().int(),
  type_id: z.string().optional(),
  contributor_id: z.string().optional(),
  access_level: z.enum(['public', 'registered', 'city_access', 'premium_poi']),
  premium_price: z.coerce.number().min(0).optional(),
  slug: z.string().optional(),
})

type PoiFormData = z.infer<typeof poiSchema>

interface PoiFormProps {
  cityId: string
  initial?: Poi
  onSubmit: (data: Record<string, unknown>) => Promise<void>
  loading?: boolean
}

function parseCoordinates(input: string): { lat: number; lng: number } | null {
  const s = input.trim()
    .replace(/\u2032/g, "'")   // ′ → '
    .replace(/\u2033/g, '"')   // ″ → "
    .replace(/\u00B0/g, '°')   // normalize degree sign

  // DMS: 50°04'35.1"N 14°25'47.0"E
  const dmsRe = /(\d+)\s*°\s*(\d+)\s*['']\s*([\d.]+)\s*["]\s*([NSEW])/gi
  const dmsMatches = [...s.matchAll(dmsRe)]
  if (dmsMatches.length >= 2) {
    const parts = dmsMatches.map(m => {
      const deg = parseFloat(m[1]) + parseFloat(m[2]) / 60 + parseFloat(m[3]) / 3600
      return /[SW]/i.test(m[4]) ? -deg : deg
    })
    const lat = /[NS]/i.test(dmsMatches[0][4]) ? parts[0] : parts[1]
    const lng = /[EW]/i.test(dmsMatches[0][4]) ? parts[0] : parts[1]
    if (lat >= -90 && lat <= 90 && lng >= -180 && lng <= 180) return { lat, lng }
  }

  // DDM: N 50° 4.5848' E 14° 25.4700'
  const ddmRe = /([NSEW])\s*(\d+)\s*°\s*([\d.]+)\s*['']/gi
  const ddmMatches = [...s.matchAll(ddmRe)]
  if (ddmMatches.length >= 2) {
    const parts = ddmMatches.map(m => {
      const deg = parseFloat(m[2]) + parseFloat(m[3]) / 60
      return /[SW]/i.test(m[1]) ? -deg : deg
    })
    const lat = /[NS]/i.test(ddmMatches[0][1]) ? parts[0] : parts[1]
    const lng = /[EW]/i.test(ddmMatches[0][1]) ? parts[0] : parts[1]
    if (lat >= -90 && lat <= 90 && lng >= -180 && lng <= 180) return { lat, lng }
  }

  // DD: 50.0764133, 14.2536789  or  50.0764133N, 14.2536789E
  const ddRe = /([-+]?\d+\.?\d*)\s*([NSEW])?/gi
  const ddMatches = [...s.matchAll(ddRe)].filter(m => m[0].trim().length > 0)
  if (ddMatches.length >= 2) {
    const parts = ddMatches.slice(0, 2).map(m => {
      const val = parseFloat(m[1])
      return m[2] && /[SW]/i.test(m[2]) ? -val : val
    })
    const [a, b] = parts
    if (a >= -90 && a <= 90 && b >= -180 && b <= 180) return { lat: a, lng: b }
  }

  return null
}

export function PoiForm({ cityId, initial, onSubmit, loading }: PoiFormProps) {
  const { t } = useTranslation()

  const ACCESS_LEVELS: { value: PoiAccessLevel; label: string }[] = [
    { value: 'public', label: t('poiForm.accessPublic', 'Public (anyone)') },
    { value: 'registered', label: t('poiForm.accessRegistered', 'Registered (free sample)') },
    { value: 'city_access', label: t('poiForm.accessCityAccess', 'City Access (paid area)') },
    { value: 'premium_poi', label: t('poiForm.accessPremiumPoi', 'Premium POI (individual purchase)') },
  ]

  const [coordInput, setCoordInput] = useState('')
  const [aliases, setAliases] = useState<string[]>(initial?.aliases || [])
  const [poiTypes, setPoiTypes] = useState<(PoiType & { _deactivated?: boolean })[]>([])
  const [photoUrls, setPhotoUrls] = useState<string[]>(initial?.photo_urls || [])
  const [slugCopied, setSlugCopied] = useState(false)
  const [citySlug, setCitySlug] = useState<string | null>(null)
  const [cityCountryCode, setCityCountryCode] = useState<string | null>(null)
  const [activeLang, setActiveLang] = useState('cs')

  // Build default values for all language fields
  const defaultValues: Record<string, unknown> = {
    name: initial?.name?.cs || initial?.name?.en || '',
    latitude: initial?.latitude || 50.08,
    longitude: initial?.longitude || 14.42,
    geofence_radius: initial?.geofence_radius || 100,
    is_premium: initial?.is_premium ?? true,
    is_active: initial?.is_active ?? true,
    sort_order: initial?.sort_order || 0,
    type_id: initial?.type_id || '',
    contributor_id: initial?.contributor_id || '',
    access_level: initial?.access_level || 'city_access',
    premium_price: initial?.premium_price || 0,
    slug: initial?.slug || '',
  }
  for (const code of LANG_CODES) {
    defaultValues[`description_${code}`] = initial?.description?.[code] || ''
    defaultValues[`perex_${code}`] = initial?.perex?.[code] || ''
  }

  const { register, handleSubmit, setValue, watch, formState: { errors } } = useForm<PoiFormData>({
    resolver: zodResolver(poiSchema) as Resolver<PoiFormData>,
    defaultValues: defaultValues as PoiFormData,
  })

  const lat = watch('latitude') as number
  const lng = watch('longitude') as number
  const geofence = watch('geofence_radius') as number

  useEffect(() => {
    adminSelect('poi_types', {
      filters: [{ column: 'is_active', op: 'eq', value: true }],
      order: { column: 'sort_order' },
    }).then(async ({ data }) => {
      if (!data) return
      const activeTypes = data as PoiType[]
      if (initial?.type_id && !activeTypes.find(t => t.id === initial.type_id)) {
        const { data: inactiveType } = await adminSelect('poi_types', {
          filters: [{ column: 'id', op: 'eq', value: initial.type_id }],
          single: true,
        })
        if (inactiveType) {
          setPoiTypes([...activeTypes, { ...(inactiveType as PoiType), _deactivated: true } as PoiType & { _deactivated?: boolean }])
          return
        }
      }
      setPoiTypes(activeTypes)
    })
    adminSelect('cities', {
      select: 'slug, country_code',
      filters: [{ column: 'id', op: 'eq', value: cityId }],
      single: true,
    }).then(({ data }) => {
      if (data) {
        const city = data as { slug: string | null; country_code: string | null }
        setCitySlug(city.slug)
        setCityCountryCode(city.country_code)
      }
    })
  }, [cityId])

  const accessLevel = watch('access_level') as string
  const poiSlug = watch('slug') as string

  const smartUriPath = cityCountryCode && citySlug && poiSlug
    ? `/${cityCountryCode.toLowerCase()}/${citySlug}/${poiSlug}`
    : null

  function copySmartUri() {
    if (!smartUriPath) return
    navigator.clipboard.writeText(`https://placesecrets.app${smartUriPath}`)
    setSlugCopied(true)
    setTimeout(() => setSlugCopied(false), 2000)
  }

  async function handleFormSubmit(data: PoiFormData) {
    const description: Record<string, string> = {}
    const perex: Record<string, string> = {}
    const raw = data as unknown as Record<string, string>
    for (const code of LANG_CODES) {
      const d = raw[`description_${code}`]
      const p = raw[`perex_${code}`]
      if (d) description[code] = d
      if (p) perex[code] = p
    }

    await onSubmit({
      city_id: cityId,
      name: { cs: data.name },
      description,
      latitude: data.latitude,
      longitude: data.longitude,
      geofence_radius: data.geofence_radius,
      is_premium: data.is_premium,
      is_active: data.is_active,
      sort_order: data.sort_order,
      type_id: data.type_id || null,
      contributor_id: data.contributor_id || null,
      photo_urls: photoUrls,
      access_level: data.access_level,
      perex: Object.keys(perex).length > 0 ? perex : null,
      premium_price: data.access_level === 'premium_poi' ? (data.premium_price || null) : null,
      slug: data.slug || null,
      aliases,
    })
  }

  const poiId = initial?.id || 'new'

  return (
    <form onSubmit={handleSubmit(handleFormSubmit)} className="space-y-6">
      <Card>
        <CardHeader><CardTitle className="text-base">{t('poiForm.basicInfo', 'Basic Info')}</CardTitle></CardHeader>
        <CardContent className="space-y-4">
          {/* Name — single canonical field */}
          <div className="space-y-2">
            <Label>{t('poiForm.name', 'Name')}</Label>
            <Input {...register('name')} />
            {errors.name && (
              <p className="text-xs text-destructive mt-1">{errors.name.message}</p>
            )}
          </div>

          {/* Language pill switcher (for Description & Perex) */}
          <div className="flex items-center gap-2 flex-wrap">
            <span className="text-sm text-muted-foreground">{t('poiForm.language', 'Language')}:</span>
            {LANG_CODES.map(code => (
              <button
                key={code}
                type="button"
                onClick={() => setActiveLang(code)}
                className={`px-2.5 py-1 rounded-full text-xs font-medium transition-colors ${
                  activeLang === code
                    ? 'bg-primary text-white'
                    : 'bg-muted text-muted-foreground hover:bg-muted/80'
                }`}
              >
                {code.toUpperCase()}
              </button>
            ))}
          </div>

          {/* Aliases */}
          <div className="space-y-2">
            <Label>{t('poiForm.aliases', 'Aliases / Alternative Names')}</Label>
            <TagInput value={aliases} onChange={setAliases} placeholder={t('poiForm.aliasPlaceholder', 'Type and press Enter...')} />
            <p className="text-xs text-muted-foreground">{t('poiForm.aliasesHelp', 'Alternative names for this place')}</p>
          </div>

          {/* Type, Sort Order, Geofence */}
          <div className="grid gap-4 md:grid-cols-3">
            <div className="space-y-2">
              <Label>{t('poiForm.type', 'Type')}</Label>
              <select {...register('type_id')} className="w-full rounded-md border px-3 py-2 text-sm" aria-label="POI type">
                <option value="">-- {t('poiForm.none', 'None')} --</option>
                {poiTypes.map(pt => (
                  <option key={pt.id} value={pt.id}>
                    {pt.name.cs || pt.name.en}{pt._deactivated ? ` (${t('poiForm.deactivated', 'deactivated')})` : ''}
                  </option>
                ))}
              </select>
            </div>
            <div className="space-y-2">
              <Label>{t('poiForm.sortOrder', 'Sort Order')}</Label>
              <Input type="number" {...register('sort_order')} />
            </div>
            <div className="space-y-2">
              <Label>{t('poiForm.geofence', 'Geofence (m)')}</Label>
              <Input type="number" {...register('geofence_radius')} />
            </div>
          </div>

          {/* Access Level */}
          <div className="grid gap-4 md:grid-cols-2">
            <div className="space-y-2">
              <Label>{t('poiForm.accessLevel', 'Access Level')}</Label>
              <select {...register('access_level')} className="w-full rounded-md border px-3 py-2 text-sm" aria-label="Access level">
                {ACCESS_LEVELS.map(al => (
                  <option key={al.value} value={al.value}>{al.label}</option>
                ))}
              </select>
            </div>
            {accessLevel === 'premium_poi' && (
              <div className="space-y-2">
                <Label>{t('poiForm.premiumPrice', 'Premium Price (EUR)')}</Label>
                <Input type="number" step="0.01" min="0" {...register('premium_price')} />
              </div>
            )}
          </div>

          {/* Slug */}
          <div className="space-y-2">
            <Label>{t('poiForm.slug', 'Slug')}</Label>
            <Input {...register('slug')} placeholder={t('poiForm.slugPlaceholder', 'Auto-generated if empty')} />
            {smartUriPath && (
              <div className="flex items-center gap-2 text-xs text-muted-foreground">
                <span>{smartUriPath}</span>
                <button type="button" onClick={copySmartUri} className="p-1 hover:text-foreground transition-colors">
                  {slugCopied ? <Check className="h-3 w-3 text-green-600" /> : <Copy className="h-3 w-3" />}
                </button>
              </div>
            )}
          </div>

          {/* Coordinate Parser */}
          <div className="space-y-2">
            <Label>{t('poiForm.coordParser', 'Lat.-Lon. Parser')}</Label>
            <div className="flex gap-2">
              <Input
                value={coordInput}
                onChange={e => setCoordInput(e.target.value)}
                placeholder={t('poiForm.coordParserPlaceholder', 'e.g. 50.0764, 14.2536')}
                onKeyDown={e => {
                  if (e.key === 'Enter') {
                    e.preventDefault()
                    const result = parseCoordinates(coordInput)
                    if (result) {
                      setValue('latitude', result.lat)
                      setValue('longitude', result.lng)
                    } else {
                      toast.error(t('poiForm.parseError', 'Could not parse coordinates'))
                    }
                  }
                }}
              />
              <Button
                type="button"
                variant="outline"
                onClick={() => {
                  const result = parseCoordinates(coordInput)
                  if (result) {
                    setValue('latitude', result.lat)
                    setValue('longitude', result.lng)
                  } else {
                    toast.error(t('poiForm.parseError', 'Could not parse coordinates'))
                  }
                }}
              >
                {t('poiForm.parse', 'Parse')}
              </Button>
            </div>
            <p className="text-xs text-muted-foreground">
              {t('poiForm.coordExamples', "DD: 50.0764, 14.2536 · DMS: 50°04'35.1\"N 14°25'47.0\"E · DDM: N 50° 4.5848' E 14° 25.4700'")}
            </p>
          </div>

          {/* Location */}
          <div className="grid gap-4 md:grid-cols-2">
            <div className="space-y-2">
              <Label>{t('poiForm.latitude', 'Latitude')}</Label>
              <Input type="number" step="any" {...register('latitude')} />
            </div>
            <div className="space-y-2">
              <Label>{t('poiForm.longitude', 'Longitude')}</Label>
              <Input type="number" step="any" {...register('longitude')} />
            </div>
          </div>
          <MapPicker
            latitude={lat}
            longitude={lng}
            radius={geofence}
            onChange={(newLat, newLng) => {
              setValue('latitude', newLat)
              setValue('longitude', newLng)
            }}
          />

          {/* Perex — multilingual, above description */}
          <div className="space-y-2">
            <Label>{t('poiForm.perex', 'Perex')} ({LANG_LABELS[activeLang]}, max 300)</Label>
            {LANG_CODES.map(code => (
              <div key={code} className={code === activeLang ? '' : 'hidden'}>
                <Textarea
                  {...register(`perex_${code}` as keyof PoiFormData)}
                  rows={3}
                  maxLength={300}
                  placeholder={t('poiForm.perexPlaceholder', 'Short preview text shown to all visitors...')}
                />
              </div>
            ))}
            <p className="text-xs text-muted-foreground">{t('poiForm.perexHelp', 'Displayed e.g. as POI preview on the map')}</p>
          </div>

          {/* Description — multilingual */}
          <div className="space-y-2">
            <Label>{t('poiForm.description', 'Description')} ({LANG_LABELS[activeLang]})</Label>
            {LANG_CODES.map(code => (
              <div key={code} className={code === activeLang ? '' : 'hidden'}>
                <textarea
                  {...register(`description_${code}` as keyof PoiFormData)}
                  rows={4}
                  className="w-full rounded-md border px-3 py-2 text-sm"
                />
              </div>
            ))}
          </div>

          {/* Checkboxes */}
          <div className="flex gap-6">
            <div className="flex items-center gap-2">
              <input type="checkbox" id="is_premium" {...register('is_premium')} className="rounded" />
              <Label htmlFor="is_premium">{t('poiForm.premiumLegacy', 'Premium (legacy)')}</Label>
            </div>
            <div className="flex items-center gap-2">
              <input type="checkbox" id="is_active" {...register('is_active')} className="rounded" />
              <Label htmlFor="is_active">{t('poiForm.active', 'Active')}</Label>
            </div>
          </div>
        </CardContent>
      </Card>

      <Card>
        <CardHeader><CardTitle className="text-base">{t('poiForm.photos', 'Photos')}</CardTitle></CardHeader>
        <CardContent>
          <PhotoUploader poiId={poiId} photos={photoUrls} onChange={setPhotoUrls} />
        </CardContent>
      </Card>

      <Card>
        <CardHeader><CardTitle className="text-base">{t('poiForm.audioGuides', 'Audio Guides')}</CardTitle></CardHeader>
        <CardContent>
          <AudioUploader poiId={poiId} contributorId={initial?.contributor_id} />
        </CardContent>
      </Card>

      <Button type="submit" disabled={loading}>
        {loading ? t('poiForm.saving', 'Saving...') : initial ? t('poiForm.updatePoi', 'Update POI') : t('poiForm.createPoi', 'Create POI')}
      </Button>
    </form>
  )
}
