import { useEffect, useState } from 'react'
import { useTranslation } from 'react-i18next'
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogFooter } from '@/components/ui/dialog'
import { Tabs, TabsList, TabsTrigger, TabsContent } from '@/components/ui/tabs'
import { Button } from '@/components/ui/button'
import { Label } from '@/components/ui/label'
import { adminSelect, adminUpsert, adminInsert } from '@/lib/supabase/admin-api'
import type { City, Poi } from '@/lib/supabase/types'
import { toast } from 'sonner'

interface AccessGrantModalProps {
  open: boolean
  onClose: () => void
  userId: string
  onGranted: () => void
}

export function AccessGrantModal({ open, onClose, userId, onGranted }: AccessGrantModalProps) {
  const { t } = useTranslation()
  const [cities, setCities] = useState<City[]>([])
  const [cityId, setCityId] = useState('')
  const [loading, setLoading] = useState(false)
  const [validUntil, setValidUntil] = useState('')
  const [countryCode, setCountryCode] = useState('')

  // POI access state
  const [poiCityId, setPoiCityId] = useState('')
  const [pois, setPois] = useState<Poi[]>([])
  const [poiId, setPoiId] = useState('')
  const [poisLoading, setPoisLoading] = useState(false)

  useEffect(() => {
    if (open) {
      adminSelect('cities', {
        select: 'id, name, country_code',
        order: { column: 'name' },
      }).then(({ data }) => {
        if (data) setCities(data as City[])
      })
    }
  }, [open])

  // Load POIs when city is selected in POI tab
  useEffect(() => {
    if (!poiCityId) {
      setPois([])
      setPoiId('')
      return
    }
    setPoisLoading(true)
    adminSelect('pois', {
      select: 'id, name',
      filters: [{ column: 'city_id', op: 'eq', value: poiCityId }],
      order: { column: 'name' },
    }).then(({ data }) => {
      if (data) setPois(data as Poi[])
      setPoisLoading(false)
    })
  }, [poiCityId])

  async function handleGrantCity() {
    if (!cityId) return
    setLoading(true)

    const { error: uaError } = await adminUpsert('user_access', {
      user_id: userId,
      city_id: cityId,
      payment_method: 'admin_grant',
      amount_eur: 0,
      valid_until: validUntil || null,
    }, 'user_id,city_id')

    if (uaError) {
      toast.error(uaError)
      setLoading(false)
      return
    }

    await adminInsert('payment_receipts', {
      user_id: userId,
      city_id: cityId,
      payment_method: 'admin_grant',
      amount_eur: 0,
      status: 'completed',
    })

    setLoading(false)
    toast.success(t('admin.users.accessGranted'))
    onGranted()
    onClose()
  }

  async function handleGrantPoi() {
    if (!poiId) return
    setLoading(true)

    const { error: insertErr } = await adminInsert('user_poi_purchases', {
      user_id: userId,
      poi_id: poiId,
      price_paid: 0,
    })

    if (insertErr) {
      toast.error(insertErr)
      setLoading(false)
      return
    }

    setLoading(false)
    toast.success(t('admin.users.poiAccessGranted'))
    onGranted()
    onClose()
  }

  async function handleGrantCountry() {
    if (!countryCode) return
    setLoading(true)
    const { error } = await adminUpsert('user_country_purchases', {
      user_id: userId,
      country_code: countryCode,
      payment_method: 'admin_grant',
      price_paid: 0,
      valid_until: validUntil || null,
    }, 'user_id,country_code')
    if (error) { toast.error(error); setLoading(false); return }
    setLoading(false)
    toast.success(t('admin.users.accessGranted'))
    onGranted()
    onClose()
  }

  const countries = Array.from(new Set(cities.map(c => c.country_code).filter(Boolean)))

  // Get a display name for a POI (prefer English, fallback to first available)
  function getPoiName(poi: Poi): string {
    if (!poi.name) return poi.id
    if (typeof poi.name === 'string') return poi.name
    return poi.name.en || poi.name.cs || Object.values(poi.name)[0] || poi.id
  }

  return (
    <Dialog open={open} onOpenChange={v => { if (!v) onClose() }}>
      <DialogContent className="max-w-sm">
        <DialogHeader>
          <DialogTitle>{t('admin.users.grantAccess')}</DialogTitle>
        </DialogHeader>
        <Tabs defaultValue="city">
          <TabsList className="w-full">
            <TabsTrigger value="city">{t('admin.users.cityAccess')}</TabsTrigger>
            <TabsTrigger value="country">{t('admin.users.countryAccess', 'Country')}</TabsTrigger>
            <TabsTrigger value="poi">{t('admin.users.poiAccess')}</TabsTrigger>
          </TabsList>

          <TabsContent value="city" className="mt-4">
            <div className="space-y-4">
              <div className="space-y-2">
                <Label>{t('admin.cities.title')}</Label>
                <select
                  value={cityId}
                  onChange={e => setCityId(e.target.value)}
                  className="w-full rounded-md border px-3 py-2 text-sm"
                  aria-label={t('admin.users.selectCity')}
                >
                  <option value="">{t('admin.users.selectCity')}</option>
                  {cities.map(c => <option key={c.id} value={c.id}>{c.name}</option>)}
                </select>
              </div>
              <div className="space-y-2">
                <Label>{t('admin.users.validUntil', 'Valid until (optional)')}</Label>
                <input type="date" value={validUntil} onChange={e => setValidUntil(e.target.value)}
                  className="w-full rounded-md border px-3 py-2 text-sm" />
              </div>
            </div>
            <DialogFooter className="mt-4">
              <Button variant="outline" onClick={onClose}>{t('common.cancel')}</Button>
              <Button onClick={handleGrantCity} disabled={!cityId || loading}>
                {loading ? t('common.loading') : t('admin.users.grantAccess')}
              </Button>
            </DialogFooter>
          </TabsContent>

          <TabsContent value="country" className="mt-4">
            <div className="space-y-4">
              <div className="space-y-2">
                <Label>{t('admin.users.countryAccess', 'Country')}</Label>
                <select value={countryCode} onChange={e => setCountryCode(e.target.value)}
                  className="w-full rounded-md border px-3 py-2 text-sm" aria-label={t('admin.users.countryAccess', 'Country')}>
                  <option value="">—</option>
                  {countries.map(cc => <option key={cc} value={cc}>{cc}</option>)}
                </select>
              </div>
              <div className="space-y-2">
                <Label>{t('admin.users.validUntil', 'Valid until (optional)')}</Label>
                <input type="date" value={validUntil} onChange={e => setValidUntil(e.target.value)}
                  className="w-full rounded-md border px-3 py-2 text-sm" />
              </div>
            </div>
            <DialogFooter className="mt-4">
              <Button variant="outline" onClick={onClose}>{t('common.cancel')}</Button>
              <Button onClick={handleGrantCountry} disabled={!countryCode || loading}>
                {loading ? t('common.loading') : t('admin.users.grantAccess')}
              </Button>
            </DialogFooter>
          </TabsContent>

          <TabsContent value="poi" className="mt-4">
            <div className="space-y-4">
              <div className="space-y-2">
                <Label>{t('admin.cities.title')}</Label>
                <select
                  value={poiCityId}
                  onChange={e => { setPoiCityId(e.target.value); setPoiId('') }}
                  className="w-full rounded-md border px-3 py-2 text-sm"
                  aria-label={t('admin.users.selectCity')}
                >
                  <option value="">{t('admin.users.selectCity')}</option>
                  {cities.map(c => <option key={c.id} value={c.id}>{c.name}</option>)}
                </select>
              </div>
              {poiCityId && (
                <div className="space-y-2">
                  <Label>{t('admin.users.selectPoi')}</Label>
                  {poisLoading ? (
                    <p className="text-sm text-muted-foreground">{t('common.loading')}</p>
                  ) : (
                    <select
                      value={poiId}
                      onChange={e => setPoiId(e.target.value)}
                      className="w-full rounded-md border px-3 py-2 text-sm"
                      aria-label={t('admin.users.selectPoi')}
                    >
                      <option value="">{t('admin.users.selectPoi')}</option>
                      {pois.map(p => <option key={p.id} value={p.id}>{getPoiName(p)}</option>)}
                    </select>
                  )}
                </div>
              )}
            </div>
            <DialogFooter className="mt-4">
              <Button variant="outline" onClick={onClose}>{t('common.cancel')}</Button>
              <Button onClick={handleGrantPoi} disabled={!poiId || loading}>
                {loading ? t('common.loading') : t('admin.users.grantAccess')}
              </Button>
            </DialogFooter>
          </TabsContent>
        </Tabs>
      </DialogContent>
    </Dialog>
  )
}
