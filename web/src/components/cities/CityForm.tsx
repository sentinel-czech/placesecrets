import { useState } from 'react'
import { useForm, type Resolver } from 'react-hook-form'
import { zodResolver } from '@hookform/resolvers/zod'
import { z } from 'zod'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { Card, CardContent } from '@/components/ui/card'
import { MapPicker } from '@/components/shared/MapPicker'
import { TagInput } from '@/components/shared/TagInput'
import type { City, Country } from '@/lib/supabase/types'
import { useTranslation } from 'react-i18next'

const citySchema = z.object({
  name: z.string().min(1, 'Name is required'),
  country_code: z.string().length(2, 'Must be 2-letter code'),
  latitude: z.coerce.number().min(-90).max(90),
  longitude: z.coerce.number().min(-180).max(180),
  bounding_box_radius_km: z.coerce.number().positive(),
  price_eur: z.coerce.number().min(0),
  is_active: z.boolean(),
})

type CityFormData = z.infer<typeof citySchema>

interface CityFormProps {
  initial?: City
  countries: Country[]
  onSubmit: (data: Record<string, unknown>) => Promise<void>
  loading?: boolean
}

export function CityForm({ initial, countries, onSubmit, loading }: CityFormProps) {
  const { t } = useTranslation()
  const [aliases, setAliases] = useState<string[]>(initial?.aliases || [])

  const { register, handleSubmit, setValue, watch, formState: { errors } } = useForm<CityFormData>({
    resolver: zodResolver(citySchema) as Resolver<CityFormData>,
    defaultValues: {
      name: initial?.name || '',
      country_code: initial?.country_code || 'CZ',
      latitude: initial?.latitude || 50.08,
      longitude: initial?.longitude || 14.42,
      bounding_box_radius_km: initial?.bounding_box_radius_km || 10,
      price_eur: initial?.price_eur || 1,
      is_active: initial?.is_active ?? true,
    },
  })

  const lat = watch('latitude')
  const lng = watch('longitude')

  async function handleFormSubmit(data: CityFormData) {
    await onSubmit({ ...data, aliases })
  }

  return (
    <form onSubmit={handleSubmit(handleFormSubmit)} className="space-y-6">
      <Card>
        <CardContent className="pt-6 space-y-4">
          <div className="grid gap-4 md:grid-cols-2">
            <div className="space-y-2">
              <Label>{t('cityForm.name')}</Label>
              <Input {...register('name')} />
              {errors.name && <p className="text-xs text-destructive">{errors.name.message}</p>}
            </div>
            <div className="space-y-2">
              <Label>{t('cityForm.country')}</Label>
              <select
                {...register('country_code')}
                className="w-full rounded-md border border-input bg-background px-3 py-2 text-sm ring-offset-background focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring"
              >
                {countries.map(c => (
                  <option key={c.code} value={c.code}>{c.name} ({c.code})</option>
                ))}
              </select>
              {errors.country_code && <p className="text-xs text-destructive">{errors.country_code.message}</p>}
            </div>
          </div>
          <div className="space-y-2">
            <Label>{t('cityForm.aliases', 'City Aliases')}</Label>
            <TagInput value={aliases} onChange={setAliases} placeholder={t('cityForm.aliasPlaceholder', 'Type and press Enter...')} />
            <p className="text-xs text-muted-foreground">{t('cityForm.aliasesHelp', 'Alternative names (e.g., Pilsen, Pilsner)')}</p>
          </div>
          <div className="grid gap-4 md:grid-cols-3">
            <div className="space-y-2">
              <Label>{t('cityForm.radius')}</Label>
              <Input type="number" step="0.1" {...register('bounding_box_radius_km')} />
            </div>
            <div className="space-y-2">
              <Label>{t('cityForm.price')}</Label>
              <Input type="number" step="0.01" {...register('price_eur')} />
            </div>
          </div>
          <div className="grid gap-4 md:grid-cols-2">
            <div className="space-y-2">
              <Label>{t('cityForm.latitude')}</Label>
              <Input type="number" step="any" {...register('latitude')} />
            </div>
            <div className="space-y-2">
              <Label>{t('cityForm.longitude')}</Label>
              <Input type="number" step="any" {...register('longitude')} />
            </div>
          </div>
          <div className="flex items-center gap-2">
            <input type="checkbox" id="is_active" {...register('is_active')} className="rounded" />
            <Label htmlFor="is_active">{t('cityForm.active')}</Label>
          </div>
        </CardContent>
      </Card>

      <Card>
        <CardContent className="pt-6">
          <Label className="mb-2 block">{t('cityForm.locationClick')}</Label>
          <MapPicker
            latitude={lat}
            longitude={lng}
            onChange={(newLat, newLng) => {
              setValue('latitude', newLat)
              setValue('longitude', newLng)
            }}
          />
        </CardContent>
      </Card>

      <Button type="submit" disabled={loading}>
        {loading ? t('cityForm.saving') : initial ? t('cityForm.updateCity') : t('cityForm.createCity')}
      </Button>
    </form>
  )
}
