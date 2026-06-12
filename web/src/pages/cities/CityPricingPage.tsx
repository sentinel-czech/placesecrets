import { useEffect, useState } from 'react'
import { useParams } from 'react-router-dom'
import { useTranslation } from 'react-i18next'
import { adminSelect, adminUpdate } from '@/lib/supabase/admin-api'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Skeleton } from '@/components/ui/skeleton'
import type { City, Poi } from '@/lib/supabase/types'
import { toast } from 'sonner'

export default function CityPricingPage() {
  const { t } = useTranslation()
  const { cityId } = useParams<{ cityId: string }>()
  const [city, setCity] = useState<City | null>(null)
  const [pois, setPois] = useState<Poi[]>([])
  const [loading, setLoading] = useState(true)
  const [saving, setSaving] = useState(false)
  const [bundlePrice, setBundlePrice] = useState('')
  const [samplePoiId, setSamplePoiId] = useState('')

  useEffect(() => {
    if (!cityId) return
    let cancelled = false
    Promise.all([
      adminSelect('cities', { filters: [{ column: 'id', op: 'eq', value: cityId }], single: true }),
      adminSelect('pois', {
        select: 'id, name, access_level, premium_price',
        filters: [{ column: 'city_id', op: 'eq', value: cityId }],
        order: { column: 'sort_order' },
      }),
    ]).then(([cityRes, poisRes]) => {
      if (cancelled) return
      if (cityRes.data) {
        const c = cityRes.data as City
        setCity(c)
        setBundlePrice(c.premium_bundle_price?.toString() || '')
        setSamplePoiId(c.registered_sample_poi_id || '')
      }
      if (poisRes.data) setPois(poisRes.data as Poi[])
      setLoading(false)
    })
    return () => { cancelled = true }
  }, [cityId])

  async function handleSave() {
    if (!cityId) return
    setSaving(true)
    const { error } = await adminUpdate('cities', {
      premium_bundle_price: bundlePrice ? parseFloat(bundlePrice) : null,
      registered_sample_poi_id: samplePoiId || null,
    }, [{ column: 'id', op: 'eq', value: cityId }])
    setSaving(false)
    if (error) toast.error(error)
    else toast.success(t('cityPages.pricingUpdated'))
  }

  if (loading) return <Skeleton className="h-64 max-w-2xl" />
  if (!city) return <p>{t('cityPages.cityNotFound')}</p>

  const premiumPois = pois.filter(p => p.access_level === 'premium_poi')

  return (
    <div className="max-w-2xl space-y-6">
      <h2 className="text-lg font-semibold">{t('cityPages.pricingTitle', { name: city.name })}</h2>

      <Card>
        <CardHeader><CardTitle className="text-base">{t('cityPages.cityAccessPrice')}</CardTitle></CardHeader>
        <CardContent>
          <div className="space-y-2">
            <Label>{t('cityPages.priceEurLabel')}</Label>
            <Input type="number" value={city.price_eur} disabled className="max-w-[200px]" />
            <p className="text-xs text-muted-foreground">{t('cityPages.editViaCity')}</p>
          </div>
        </CardContent>
      </Card>

      <Card>
        <CardHeader><CardTitle className="text-base">{t('cityPages.premiumBundle')}</CardTitle></CardHeader>
        <CardContent className="space-y-4">
          <div className="space-y-2">
            <Label>{t('cityPages.premiumBundlePrice')}</Label>
            <Input
              type="number"
              step="0.01"
              min="0"
              value={bundlePrice}
              onChange={e => setBundlePrice(e.target.value)}
              className="max-w-[200px]"
              placeholder="e.g. 4.99"
            />
            <p className="text-xs text-muted-foreground">{t('cityPages.premiumBundleDesc')}</p>
          </div>

          <div className="space-y-2">
            <Label>{t('cityPages.freeSamplePoi')}</Label>
            <select
              value={samplePoiId}
              onChange={e => setSamplePoiId(e.target.value)}
              className="w-full max-w-md rounded-md border px-3 py-2 text-sm"
              aria-label="Sample POI"
            >
              <option value="">{t('cityPages.nonePoi')}</option>
              {pois.map(p => (
                <option key={p.id} value={p.id}>{p.name?.cs || p.name?.en}</option>
              ))}
            </select>
          </div>
        </CardContent>
      </Card>

      {premiumPois.length > 0 && (
        <Card>
          <CardHeader><CardTitle className="text-base">{t('cityPages.premiumPois', { count: premiumPois.length })}</CardTitle></CardHeader>
          <CardContent>
            <table className="w-full text-sm">
              <thead>
                <tr className="border-b">
                  <th className="text-left py-2">{t('common.name')}</th>
                  <th className="text-right py-2">{t('cityForm.price')}</th>
                </tr>
              </thead>
              <tbody>
                {premiumPois.map(p => (
                  <tr key={p.id} className="border-b last:border-0">
                    <td className="py-2">{p.name?.cs || p.name?.en}</td>
                    <td className="text-right py-2">{p.premium_price?.toFixed(2) ?? '—'}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </CardContent>
        </Card>
      )}

      <Button onClick={handleSave} disabled={saving}>
        {saving ? t('cityForm.saving') : t('cityPages.savePricing')}
      </Button>
    </div>
  )
}
