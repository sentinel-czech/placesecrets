import { useEffect, useState } from 'react'
import { useTranslation } from 'react-i18next'
import { adminSelect, adminUpdate } from '@/lib/supabase/admin-api'
import type { PaymentConfig } from '@/lib/supabase/types'
import { Card, CardContent } from '@/components/ui/card'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { Button } from '@/components/ui/button'
import { Separator } from '@/components/ui/separator'
import { ChangePinForm } from '@/components/settings/ChangePinForm'
import { AdminUsersTable } from '@/components/settings/AdminUsersTable'
import { InviteAdminForm } from '@/components/settings/InviteAdminForm'
import { Section } from '@/components/shared/Section'
import { useAuthStore } from '@/hooks/useAuth'
import { toast } from 'sonner'

export default function SettingsPage() {
  const { t } = useTranslation()
  const { hasPermission } = useAuthStore()
  const canWritePayments = hasPermission('payments', 'write')
  const [config, setConfig] = useState<PaymentConfig | null>(null)
  const [refreshKey, setRefreshKey] = useState(0)
  const [error, setError] = useState('')

  useEffect(() => {
    let cancelled = false
    adminSelect('payment_config', {
      select: 'id, operator_name, revolut_username, revolut_iban, stripe_publishable_key, google_pay_merchant_id, apple_pay_merchant_id, free_pois_per_month, free_count, free_period, max_geofences, max_photo_size_mb, max_audio_size_mb, admin_pin_attempts, admin_pin_lockout_minutes, receipt_prefix',
      single: true,
    }).then(({ data, error: err }) => {
      if (cancelled) return
      if (err) setError(err)
      else if (data) setConfig(data as PaymentConfig)
    })
    return () => { cancelled = true }
  }, [])

  async function saveConfig() {
    if (!config) return
    const { error } = await adminUpdate('payment_config', {
      operator_name: config.operator_name,
      revolut_username: config.revolut_username,
      revolut_iban: config.revolut_iban,
      stripe_publishable_key: config.stripe_publishable_key,
      google_pay_merchant_id: config.google_pay_merchant_id,
      apple_pay_merchant_id: config.apple_pay_merchant_id,
      free_pois_per_month: config.free_pois_per_month,
      free_count: config.free_count,
      free_period: config.free_period,
      max_geofences: config.max_geofences,
      max_photo_size_mb: config.max_photo_size_mb,
      max_audio_size_mb: config.max_audio_size_mb,
      admin_pin_attempts: config.admin_pin_attempts,
      admin_pin_lockout_minutes: config.admin_pin_lockout_minutes,
      receipt_prefix: config.receipt_prefix,
    }, [{ column: 'id', op: 'eq', value: config.id }])
    if (error) toast.error(error)
    else toast.success(t('settings.configSaved'))
  }

  function updateField(field: keyof PaymentConfig, value: string) {
    if (!config) return
    const numericFields = ['free_pois_per_month', 'free_count', 'max_geofences', 'max_photo_size_mb', 'max_audio_size_mb', 'admin_pin_attempts', 'admin_pin_lockout_minutes']
    if (numericFields.includes(field)) {
      setConfig({ ...config, [field]: parseInt(value, 10) || 0 })
    } else {
      setConfig({ ...config, [field]: value })
    }
  }

  return (
    <div className="space-y-8 max-w-2xl">
      <Section title={t('settings.changePin')}>
        <ChangePinForm />
      </Section>

      <Separator />

      <Section title={t('settings.adminUsers')}>
        <InviteAdminForm onInvited={() => setRefreshKey(k => k + 1)} />
        <div className="mt-4" key={refreshKey}>
          <AdminUsersTable />
        </div>
      </Section>

      <Separator />

      <Section title={t('settings.systemLimits')} description={t('settings.systemLimitsDesc')}>
        <Card>
          <CardContent className="pt-6">
            <div className="grid gap-4 md:grid-cols-2">
              <div className="space-y-2">
                <Label>{t('settings.freePoisPerMonth')}</Label>
                <Input type="number" min="0" value={config?.free_pois_per_month ?? 1}
                  onChange={e => updateField('free_pois_per_month', e.target.value)} disabled={!canWritePayments} />
              </div>
              <div className="space-y-2">
                <Label>{t('settings.freeCount', 'Free audios')}</Label>
                <Input type="number" min="0" value={config?.free_count ?? 1}
                  onChange={e => updateField('free_count', e.target.value)} disabled={!canWritePayments} />
              </div>
              <div className="space-y-2">
                <Label>{t('settings.freePeriod', 'Free period')}</Label>
                <select value={config?.free_period ?? 'day'}
                  onChange={e => updateField('free_period', e.target.value)} disabled={!canWritePayments}
                  className="w-full rounded-md border px-3 py-2 text-sm">
                  <option value="day">{t('settings.perDay', 'per day')}</option>
                  <option value="month">{t('settings.perMonth', 'per month')}</option>
                </select>
              </div>
              <div className="space-y-2">
                <Label>{t('settings.maxGeofences')}</Label>
                <Input type="number" min="1" value={config?.max_geofences ?? 100}
                  onChange={e => updateField('max_geofences', e.target.value)} disabled={!canWritePayments} />
              </div>
              <div className="space-y-2">
                <Label>{t('settings.maxPhotoSizeMb')}</Label>
                <Input type="number" min="1" value={config?.max_photo_size_mb ?? 10}
                  onChange={e => updateField('max_photo_size_mb', e.target.value)} disabled={!canWritePayments} />
              </div>
              <div className="space-y-2">
                <Label>{t('settings.maxAudioSizeMb')}</Label>
                <Input type="number" min="1" value={config?.max_audio_size_mb ?? 50}
                  onChange={e => updateField('max_audio_size_mb', e.target.value)} disabled={!canWritePayments} />
              </div>
              <div className="space-y-2">
                <Label>{t('settings.adminPinAttempts')}</Label>
                <Input type="number" min="1" value={config?.admin_pin_attempts ?? 5}
                  onChange={e => updateField('admin_pin_attempts', e.target.value)} disabled={!canWritePayments} />
              </div>
              <div className="space-y-2">
                <Label>{t('settings.adminPinLockoutMinutes')}</Label>
                <Input type="number" min="1" value={config?.admin_pin_lockout_minutes ?? 15}
                  onChange={e => updateField('admin_pin_lockout_minutes', e.target.value)} disabled={!canWritePayments} />
              </div>
              <div className="space-y-2">
                <Label>{t('settings.receiptPrefix')}</Label>
                <Input value={config?.receipt_prefix ?? 'PS-'}
                  onChange={e => updateField('receipt_prefix', e.target.value)} disabled={!canWritePayments} />
              </div>
            </div>
            {canWritePayments && <Button onClick={saveConfig} className="mt-4">{t('common.save')}</Button>}
          </CardContent>
        </Card>
      </Section>

      <Separator />

      <Section title={t('settings.paymentConfig')}>
        {error ? (
          <p className="text-sm text-destructive">{t('settings.configLoadError', { error })}</p>
        ) : config ? (
          <Card>
            <CardContent className="pt-6 space-y-4">
              <div className="grid gap-4 md:grid-cols-2">
                <div className="space-y-2">
                  <Label>{t('settings.operatorName')}</Label>
                  <Input value={config.operator_name || ''} onChange={e => updateField('operator_name', e.target.value)} disabled={!canWritePayments} />
                </div>
                <div className="space-y-2">
                  <Label>{t('settings.revolutUsername')}</Label>
                  <Input value={config.revolut_username || ''} onChange={e => updateField('revolut_username', e.target.value)} disabled={!canWritePayments} />
                </div>
                <div className="space-y-2">
                  <Label>{t('settings.revolutIban')}</Label>
                  <Input value={config.revolut_iban || ''} onChange={e => updateField('revolut_iban', e.target.value)} disabled={!canWritePayments} />
                </div>
                <div className="space-y-2">
                  <Label>{t('settings.stripePublishableKey')}</Label>
                  <Input value={config.stripe_publishable_key || ''} onChange={e => updateField('stripe_publishable_key', e.target.value)} disabled={!canWritePayments} />
                </div>
                <div className="space-y-2">
                  <Label>{t('settings.stripeSecretKey')}</Label>
                  <Input disabled value="********" placeholder={t('settings.stripeSecretKeyManaged')} />
                  <p className="text-xs text-muted-foreground">{t('settings.stripeSecretKeyDesc')}</p>
                </div>
                <div className="space-y-2">
                  <Label>{t('settings.googlePayMerchantId')}</Label>
                  <Input value={config.google_pay_merchant_id || ''} onChange={e => updateField('google_pay_merchant_id', e.target.value)} disabled={!canWritePayments} />
                </div>
                <div className="space-y-2">
                  <Label>{t('settings.applePayMerchantId')}</Label>
                  <Input value={config.apple_pay_merchant_id || ''} onChange={e => updateField('apple_pay_merchant_id', e.target.value)} disabled={!canWritePayments} />
                </div>
              </div>
              {canWritePayments && <Button onClick={saveConfig}>{t('settings.saveConfig')}</Button>}
            </CardContent>
          </Card>
        ) : (
          <p className="text-sm text-muted-foreground">{t('common.loading')}</p>
        )}
      </Section>
    </div>
  )
}
