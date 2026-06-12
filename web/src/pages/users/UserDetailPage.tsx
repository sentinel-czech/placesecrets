import { useEffect, useState } from 'react'
import { useParams, useNavigate } from 'react-router-dom'
import { useTranslation } from 'react-i18next'
import { adminSelect, adminUpsert, adminAuthGetUser } from '@/lib/supabase/admin-api'
import { supabase } from '@/lib/supabase/client'
import type { AdminUserView, PaymentReceipt, UserAccess, UserPoiPurchase } from '@/lib/supabase/types'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Button } from '@/components/ui/button'
import { Badge } from '@/components/ui/badge'
import { StatusBadge } from '@/components/shared/StatusBadge'
import { ConfirmDialog } from '@/components/shared/ConfirmDialog'
import { AccessGrantModal } from '@/components/users/AccessGrantModal'
import { format } from 'date-fns'
import { Skeleton } from '@/components/ui/skeleton'
import { toast } from 'sonner'
import { Plus, Trash2, ArrowLeft, Download, ShieldAlert, CheckCircle, XCircle } from 'lucide-react'
import { useAuthStore } from '@/hooks/useAuth'
import JSZip from 'jszip'

export default function UserDetailPage() {
  const { id } = useParams<{ id: string }>()
  const navigate = useNavigate()
  const { t } = useTranslation()
  const { hasPermission } = useAuthStore()
  const [user, setUser] = useState<AdminUserView | null>(null)
  const [access, setAccess] = useState<(UserAccess & { city?: { name: string } })[]>([])
  const [receipts, setReceipts] = useState<(PaymentReceipt & { city?: { name: string } })[]>([])
  const [poiPurchases, setPoiPurchases] = useState<(UserPoiPurchase & { poi?: { name: Record<string, string> } })[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState('')
  const [grantOpen, setGrantOpen] = useState(false)
  const [deleting, setDeleting] = useState(false)
  const [gdprLoading, setGdprLoading] = useState(false)
  const [statusLoading, setStatusLoading] = useState(false)

  async function loadData() {
    if (!id) return
    try {
      const [userRes, accessRes, receiptsRes, poiPurchasesRes] = await Promise.all([
        adminSelect('admin_users_view', { filters: [{ column: 'id', op: 'eq', value: id }], single: true }),
        adminSelect('user_access', { select: '*, city:cities(name)', filters: [{ column: 'user_id', op: 'eq', value: id }] }),
        adminSelect('payment_receipts', {
          select: '*, city:cities(name)',
          filters: [{ column: 'user_id', op: 'eq', value: id }],
          order: { column: 'purchased_at', ascending: false },
        }),
        adminSelect('user_poi_purchases', {
          select: '*, poi:pois(name)',
          filters: [{ column: 'user_id', op: 'eq', value: id }],
          order: { column: 'purchased_at', ascending: false },
        }),
      ])
      if (userRes.data) setUser(userRes.data as AdminUserView)
      if (accessRes.data) setAccess(accessRes.data as typeof access)
      if (receiptsRes.data) setReceipts(receiptsRes.data as typeof receipts)
      if (poiPurchasesRes.data) setPoiPurchases(poiPurchasesRes.data as typeof poiPurchases)
    } catch (err) {
      setError(String(err))
    } finally {
      setLoading(false)
    }
  }

  useEffect(() => { loadData() }, [id])

  async function handleGdprExport() {
    if (!id) return
    setGdprLoading(true)
    try {
      const [authRes, profileRes] = await Promise.all([
        adminAuthGetUser(id),
        adminSelect('user_profiles', { filters: [{ column: 'user_id', op: 'eq', value: id }], single: true }),
      ])

      const authUser = (authRes.data as { user?: Record<string, unknown> })?.user
      const profile = profileRes.data as Record<string, unknown> | null

      const profileJson = JSON.stringify({
        id: authUser?.id,
        email: authUser?.email,
        display_name: profile?.display_name || null,
        user_number: profile?.user_number || null,
        backup_email: profile?.backup_email || null,
        created_at: authUser?.created_at,
        last_sign_in_at: authUser?.last_sign_in_at,
        language: profile?.language || 'en',
        status: profile?.status || 'active',
      }, null, 2)

      const settingsJson = JSON.stringify({
        language: profile?.language || 'en',
        status: profile?.status || 'active',
        backup_email: profile?.backup_email || null,
      }, null, 2)

      const zip = new JSZip()
      zip.file('profile.json', profileJson)
      zip.file('settings.json', settingsJson)

      const blob = await zip.generateAsync({ type: 'blob' })
      const url = URL.createObjectURL(blob)
      const a = document.createElement('a')
      a.href = url
      a.download = `gdpr_export_${id}_${format(new Date(), 'yyyyMMdd')}.zip`
      a.click()
      URL.revokeObjectURL(url)
    } catch {
      toast.error(t('common.error'))
    } finally {
      setGdprLoading(false)
    }
  }

  async function handleStatusToggle() {
    if (!id || !user) return
    if (!hasPermission('users', 'write')) return
    setStatusLoading(true)
    const newStatus = (user.status || 'active') === 'active' ? 'deactivated' : 'active'
    const { error } = await adminUpsert('user_profiles', {
      user_id: id,
      status: newStatus,
    }, 'user_id')
    setStatusLoading(false)
    if (error) {
      toast.error(t('common.error'))
    } else {
      toast.success(t('common.success'))
      setUser({ ...user, status: newStatus })
    }
  }

  function getPoiName(poi: { name: Record<string, string> } | undefined): string {
    if (!poi?.name) return '—'
    return poi.name.en || poi.name.cs || Object.values(poi.name)[0] || '—'
  }

  if (loading) return <Skeleton className="h-96" />
  if (error) return <p className="text-destructive">{error}</p>
  if (!user) return <p>{t('common.noData')}</p>

  const isActive = (user.status || 'active') === 'active'

  return (
    <div className="space-y-6 max-w-3xl">
      <Button variant="ghost" onClick={() => navigate('/admin/users')} className="gap-2">
        <ArrowLeft className="h-4 w-4" />
        {t('admin.users.backToList')}
      </Button>

      <Card>
        <CardHeader><CardTitle className="text-base">{t('admin.users.userInfo')}</CardTitle></CardHeader>
        <CardContent className="grid gap-2 text-sm">
          {user.user_number && (
            <div><span className="text-muted-foreground">{t('admin.users.userNumber')}:</span> <span className="font-mono">#{user.user_number}</span></div>
          )}
          {user.display_name && (
            <div><span className="text-muted-foreground">{t('handle.handle')}:</span> <span className="font-mono">@{user.display_name}</span></div>
          )}
          <div><span className="text-muted-foreground">{t('common.email')}:</span> {user.email || '(anonymous)'}</div>
          {user.backup_email && (
            <div><span className="text-muted-foreground">{t('user.profile.backupEmail')}:</span> {user.backup_email}</div>
          )}
          <div className="flex items-center gap-2">
            <span className="text-muted-foreground">{t('admin.users.emailVerification')}:</span>
            {user.is_anonymous ? (
              <span className="text-muted-foreground">—</span>
            ) : user.email_confirmed_at ? (
              <span className="inline-flex items-center gap-1 text-green-600">
                <CheckCircle className="h-3.5 w-3.5" />
                {t('admin.users.emailVerified')}
              </span>
            ) : (
              <span className="inline-flex items-center gap-1 text-amber-600">
                <XCircle className="h-3.5 w-3.5" />
                {t('admin.users.emailNotVerified')}
              </span>
            )}
          </div>
          <div><span className="text-muted-foreground">{t('admin.users.registered')}:</span> {format(new Date(user.created_at), 'dd.MM.yyyy HH:mm')}</div>
          <div><span className="text-muted-foreground">{t('admin.users.lastLogin')}:</span> {user.last_sign_in_at ? format(new Date(user.last_sign_in_at), 'dd.MM.yyyy HH:mm') : '\u2014'}</div>
          <div><span className="text-muted-foreground">{t('admin.users.totalSpent')}:</span> {Number(user.total_spent).toFixed(2)} EUR</div>
        </CardContent>
      </Card>

      {/* Status toggle — only for roles with users write permission */}
      {hasPermission('users', 'write') && <Card>
        <CardHeader><CardTitle className="text-base">{t('admin.users.statusToggle')}</CardTitle></CardHeader>
        <CardContent className="flex items-center gap-4">
          {isActive
            ? <Badge className="bg-green-600 text-white">{t('admin.users.statusActive')}</Badge>
            : <Badge className="bg-red-600 text-white">{t('admin.users.statusDeactivated')}</Badge>
          }
          <ConfirmDialog
            trigger={
              <Button variant={isActive ? 'destructive' : 'default'} size="sm" disabled={statusLoading}>
                <ShieldAlert className="h-4 w-4 mr-1" />
                {isActive ? t('admin.users.deactivate') : t('admin.users.activate')}
              </Button>
            }
            title={isActive ? t('admin.users.deactivate') : t('admin.users.activate')}
            description={isActive
              ? t('admin.users.deactivateConfirm', { email: user.email || 'anonymous' })
              : t('admin.users.activateConfirm', { email: user.email || 'anonymous' })
            }
            onConfirm={handleStatusToggle}
            confirmLabel={t('common.confirm')}
            destructive={isActive}
          />
        </CardContent>
      </Card>}

      {/* GDPR Export */}
      <Card>
        <CardHeader><CardTitle className="text-base">{t('admin.users.gdprExport')}</CardTitle></CardHeader>
        <CardContent>
          <p className="text-sm text-muted-foreground mb-4">{t('admin.users.gdprExportDesc')}</p>
          <Button variant="outline" onClick={handleGdprExport} disabled={gdprLoading}>
            <Download className="h-4 w-4 mr-1" />
            {gdprLoading ? t('common.loading') : t('admin.users.gdprExport')}
          </Button>
        </CardContent>
      </Card>

      <Card>
        <CardHeader className="flex flex-row items-center justify-between">
          <CardTitle className="text-base">{t('admin.users.cityAccess')}</CardTitle>
          {hasPermission('payments', 'write') && (
            <Button size="sm" onClick={() => setGrantOpen(true)}>
              <Plus className="h-4 w-4 mr-1" /> {t('admin.users.grantAccess')}
            </Button>
          )}
        </CardHeader>
        <CardContent>
          {access.length === 0 ? (
            <p className="text-sm text-muted-foreground">{t('admin.users.noAccess')}</p>
          ) : (
            <div className="space-y-2">
              {access.map(a => (
                <div key={a.id} className="flex items-center justify-between text-sm border-b pb-2">
                  <span>{a.city?.name || a.city_id}</span>
                  <span className="text-muted-foreground">{a.payment_method} — {format(new Date(a.purchased_at), 'dd.MM.yyyy')}</span>
                </div>
              ))}
            </div>
          )}
        </CardContent>
      </Card>

      {/* POI Purchases */}
      <Card>
        <CardHeader>
          <CardTitle className="text-base">{t('admin.users.poiPurchases')}</CardTitle>
        </CardHeader>
        <CardContent>
          {poiPurchases.length === 0 ? (
            <p className="text-sm text-muted-foreground">{t('admin.users.noPoiPurchases')}</p>
          ) : (
            <div className="space-y-2">
              {poiPurchases.map(p => (
                <div key={p.id} className="flex items-center justify-between text-sm border-b pb-2">
                  <span>{getPoiName(p.poi)}</span>
                  <div className="flex items-center gap-3 text-muted-foreground">
                    <span>{p.price_paid != null ? `${Number(p.price_paid).toFixed(2)} EUR` : '—'}</span>
                    <span>{format(new Date(p.purchased_at), 'dd.MM.yyyy')}</span>
                  </div>
                </div>
              ))}
            </div>
          )}
        </CardContent>
      </Card>

      <Card>
        <CardHeader><CardTitle className="text-base">{t('admin.users.paymentHistory')}</CardTitle></CardHeader>
        <CardContent>
          {receipts.length === 0 ? (
            <p className="text-sm text-muted-foreground">{t('admin.users.noPayments')}</p>
          ) : (
            <div className="space-y-2">
              {receipts.map(r => (
                <div key={r.id} className="flex items-center justify-between text-sm border-b pb-2">
                  <div>
                    <span className="font-mono text-xs">{r.receipt_number}</span>
                    <span className="ml-2">{r.city?.name}</span>
                  </div>
                  <div className="flex items-center gap-3">
                    <span>{Number(r.amount_eur).toFixed(2)} EUR</span>
                    <StatusBadge status={r.status} />
                  </div>
                </div>
              ))}
            </div>
          )}
        </CardContent>
      </Card>

      <AccessGrantModal
        open={grantOpen}
        onClose={() => setGrantOpen(false)}
        userId={id!}
        onGranted={loadData}
      />

      {hasPermission('users', 'delete') && (
        <Card className="border-destructive">
          <CardHeader><CardTitle className="text-base text-destructive">{t('admin.users.dangerZone')}</CardTitle></CardHeader>
          <CardContent>
            <p className="text-sm text-muted-foreground mb-4">{t('admin.users.deleteUserDesc')}</p>
            <ConfirmDialog
              trigger={
                <Button variant="destructive" disabled={deleting}>
                  <Trash2 className="h-4 w-4 mr-1" />
                  {deleting ? t('common.loading') : t('admin.users.deleteUserData')}
                </Button>
              }
              title={t('admin.users.deleteUserData')}
              description={t('admin.users.deleteConfirm', { email: user?.email || 'anonymous' })}
              onConfirm={async () => {
                if (!id) return
                setDeleting(true)
                const { error: fnError } = await supabase.functions.invoke('delete-user-data', {
                  body: { user_id: id },
                })
                setDeleting(false)
                if (fnError) {
                  toast.error(t('common.error'))
                } else {
                  toast.success(t('common.success'))
                  navigate('/admin/users')
                }
              }}
              confirmLabel={t('common.delete')}
              destructive
            />
          </CardContent>
        </Card>
      )}
    </div>
  )
}
