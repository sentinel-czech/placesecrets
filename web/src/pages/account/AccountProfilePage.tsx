import { useState, useEffect, useRef } from 'react'
import { useSearchParams, Link } from 'react-router-dom'
import { useTranslation } from 'react-i18next'
import { useAuthStore } from '@/hooks/useAuth'
import { supabase } from '@/lib/supabase/client'
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from '@/components/ui/card'
import { Badge } from '@/components/ui/badge'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { Separator } from '@/components/ui/separator'
import { Avatar, AvatarFallback } from '@/components/ui/avatar'
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from '@/components/ui/table'
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs'
import { Shield, Mail, Calendar, Download, Receipt, Hash, AtSign, Loader2 } from 'lucide-react'
import { toast } from 'sonner'

const TAB_NAMES = ['settings', 'purchases', 'admin'] as const
type TabName = typeof TAB_NAMES[number]

function tabNameToIndex(name: string | null): number {
  const idx = TAB_NAMES.indexOf(name as TabName)
  return idx >= 0 ? idx : 0
}

function indexToTabName(index: number): TabName {
  return TAB_NAMES[index] ?? 'settings'
}

const LANGUAGES = [
  { code: 'en', flag: '\ud83c\uddec\ud83c\udde7', name: 'English' },
  { code: 'cs', flag: '\ud83c\udde8\ud83c\uddff', name: '\u010ce\u0161tina' },
  { code: 'sk', flag: '\ud83c\uddf8\ud83c\uddf0', name: 'Sloven\u010dina' },
  { code: 'de', flag: '\ud83c\udde9\ud83c\uddea', name: 'Deutsch' },
  { code: 'es', flag: '\ud83c\uddea\ud83c\uddf8', name: 'Espa\u00f1ol' },
  { code: 'fr', flag: '\ud83c\uddeb\ud83c\uddf7', name: 'Fran\u00e7ais' },
  { code: 'pt', flag: '\ud83c\uddf5\ud83c\uddf9', name: 'Portugu\u00eas' },
  { code: 'ru', flag: '\ud83c\uddf7\ud83c\uddfa', name: '\u0420\u0443\u0441\u0441\u043a\u0438\u0439' },
  { code: 'vi', flag: '\ud83c\uddfb\ud83c\uddf3', name: 'Ti\u1ebfng Vi\u1ec7t' },
  { code: 'zh', flag: '\ud83c\udde8\ud83c\uddf3', name: '\u4e2d\u6587' },
  { code: 'ko', flag: '\ud83c\uddf0\ud83c\uddf7', name: '\ud55c\uad6d\uc5b4' },
]

export default function AccountProfilePage() {
  const { t } = useTranslation()
  const { user, role, displayName, isVerified, userNumber, needsHandle } = useAuthStore()
  const [searchParams, setSearchParams] = useSearchParams()

  const isAdmin = role && ['superadmin', 'editor', 'viewer'].includes(role)
  const isContributor = role === 'contributor'
  const initials = user?.email
    ? user.email.substring(0, 2).toUpperCase()
    : '??'

  const currentTab = tabNameToIndex(searchParams.get('tab'))

  function handleTabChange(value: number) {
    const name = indexToTabName(value)
    setSearchParams(name === 'settings' ? {} : { tab: name }, { replace: true })
  }

  const roleBadge = () => {
    if (!role || role === 'user') return <Badge variant="secondary">{t('roles.user')}</Badge>
    if (role === 'superadmin') return <Badge className="bg-primary">{t('roles.superAdmin')}</Badge>
    if (role === 'editor') return <Badge className="bg-blue-600 text-white">{t('roles.editor')}</Badge>
    if (role === 'viewer') return <Badge className="bg-gray-600 text-white">{t('roles.viewer')}</Badge>
    if (role === 'contributor') return <Badge className="bg-amber-600 text-white">{t('roles.contributor')}</Badge>
    return <Badge variant="secondary">{role}</Badge>
  }

  return (
    <div className="space-y-6 max-w-3xl">
      {/* Profile card header */}
      <Card>
        <CardContent className="pt-6">
          <div className="flex items-start gap-4">
            <Avatar size="lg">
              <AvatarFallback className="text-lg">{initials}</AvatarFallback>
            </Avatar>
            <div className="flex-1 space-y-1">
              <div className="flex items-center gap-2">
                <h2 className="text-lg font-semibold">
                  {displayName ? `@${displayName}` : user?.email?.split('@')[0] || 'User'}
                </h2>
                {roleBadge()}
                {isContributor && isVerified && (
                  <Badge variant="outline" className="text-primary border-primary">{t('user.profile.verified')}</Badge>
                )}
              </div>
              <div className="flex items-center gap-2 text-sm text-muted-foreground">
                <Mail className="h-3.5 w-3.5" />
                {user?.email}
              </div>
              {userNumber && (
                <div className="flex items-center gap-2 text-sm text-muted-foreground">
                  <Hash className="h-3.5 w-3.5" />
                  <span className="font-mono">#{userNumber}</span>
                </div>
              )}
              {user?.created_at && (
                <div className="flex items-center gap-2 text-sm text-muted-foreground">
                  <Calendar className="h-3.5 w-3.5" />
                  {t('user.profile.memberSince', { date: new Date(user.created_at).toLocaleDateString() })}
                </div>
              )}
            </div>
          </div>
        </CardContent>
      </Card>

      {needsHandle && (
        <Card className="border-amber-300 bg-amber-50 dark:bg-amber-950/20">
          <CardContent className="py-4">
            <div className="flex items-center gap-3">
              <AtSign className="h-5 w-5 text-amber-600 flex-shrink-0" />
              <div className="flex-1">
                <p className="text-sm font-medium text-amber-800 dark:text-amber-200">{t('handle.setHandle')}</p>
                <p className="text-xs text-amber-700 dark:text-amber-300">{t('handle.desc')}</p>
              </div>
              <Button size="sm" variant="outline" onClick={() => setSearchParams({ tab: 'settings' }, { replace: true })}>
                {t('handle.setHandle')}
              </Button>
            </div>
          </CardContent>
        </Card>
      )}

      {/* Tabs */}
      <Tabs value={currentTab} onValueChange={handleTabChange}>
        <TabsList>
          <TabsTrigger value={0}>{t('user.profile.settingsTab')}</TabsTrigger>
          <TabsTrigger value={1}>{t('user.profile.purchasesTab')}</TabsTrigger>
          {isAdmin && <TabsTrigger value={2}>{t('user.profile.adminTab')}</TabsTrigger>}
        </TabsList>

        <TabsContent value={0} className="mt-4">
          <SettingsTab />
        </TabsContent>

        <TabsContent value={1} className="mt-4">
          <PurchasesTab />
        </TabsContent>

        {isAdmin && (
          <TabsContent value={2} className="mt-4">
            <Card className="border-primary/20 bg-primary/5">
              <CardHeader>
                <CardTitle className="flex items-center gap-2">
                  <Shield className="h-5 w-5 text-primary" />
                  {t('nav.adminPanel')}
                </CardTitle>
                <CardDescription>{t('user.profile.adminPanelDesc')}</CardDescription>
              </CardHeader>
              <CardContent>
                <Link to="/admin-pin">
                  <Button>{t('user.profile.goToAdmin')}</Button>
                </Link>
              </CardContent>
            </Card>
          </TabsContent>
        )}
      </Tabs>
    </div>
  )
}

const HANDLE_REGEX = /^[a-z0-9_]{3,50}$/

function SettingsTab() {
  const { user, signOut, displayName: storeDisplayName, setDisplayName: storeSetDisplayName } = useAuthStore()
  const { t, i18n } = useTranslation()
  const [newEmail, setNewEmail] = useState('')
  const [newPassword, setNewPassword] = useState('')
  const [confirmPassword, setConfirmPassword] = useState('')
  const [emailLoading, setEmailLoading] = useState(false)
  const [passwordLoading, setPasswordLoading] = useState(false)
  const [deleteLoading, setDeleteLoading] = useState(false)
  const [deleteConfirm, setDeleteConfirm] = useState(false)
  const [selectedLang, setSelectedLang] = useState(i18n.language?.substring(0, 2) || 'en')
  const [backupEmail, setBackupEmail] = useState('')
  const [backupEmailLoading, setBackupEmailLoading] = useState(false)
  const [handle, setHandle] = useState(storeDisplayName || '')
  const [handleError, setHandleError] = useState('')
  const [handleChecking, setHandleChecking] = useState(false)
  const [handleLoading, setHandleLoading] = useState(false)
  const [marketingOptIn, setMarketingOptIn] = useState(false)
  const [marketingLoading, setMarketingLoading] = useState(false)
  const [avatarUrl, setAvatarUrl] = useState<string | null>(null)
  const [avatarUploading, setAvatarUploading] = useState(false)
  const [resendLoading, setResendLoading] = useState(false)
  const [resent, setResent] = useState(false)
  const debounceRef = useRef<ReturnType<typeof setTimeout> | undefined>(undefined)
  const emailVerified = !!(user as { email_confirmed_at?: string } | null)?.email_confirmed_at

  useEffect(() => {
    if (!user) return
    supabase
      .from('user_profiles')
      .select('language, backup_email, display_name, marketing_consent_at, avatar_url')
      .eq('user_id', user.id)
      .maybeSingle()
      .then(({ data }) => {
        if (data?.language) setSelectedLang(data.language)
        if (data?.backup_email) setBackupEmail(data.backup_email)
        if (data?.display_name) setHandle(data.display_name)
        setMarketingOptIn(!!data?.marketing_consent_at)
        setAvatarUrl((data?.avatar_url as string | null) ?? null)
      })
  }, [user])

  async function handleResendVerification() {
    if (!user?.email) return
    setResendLoading(true)
    const { error } = await supabase.auth.resend({ type: 'signup', email: user.email })
    setResendLoading(false)
    if (error) { toast.error(error.message) } else { setResent(true); toast.success(t('user.profile.verificationSent', 'Verification email sent.')) }
  }

  async function handleMarketingToggle(checked: boolean) {
    if (!user) return
    setMarketingLoading(true)
    const { error } = await supabase
      .from('user_profiles')
      .upsert({ user_id: user.id, marketing_consent_at: checked ? new Date().toISOString() : null }, { onConflict: 'user_id' })
    setMarketingLoading(false)
    if (error) { toast.error(t('common.error')) } else { setMarketingOptIn(checked) }
  }

  async function handleExportData() {
    if (!user) return
    const tables = ['user_profiles', 'user_access', 'payment_receipts', 'poi_ratings', 'user_poi_purchases', 'user_city_premium_purchases']
    const out: Record<string, unknown> = { exported_at: new Date().toISOString(), user_id: user.id, email: user.email }
    for (const tbl of tables) {
      const { data } = await supabase.from(tbl).select('*').eq('user_id', user.id)
      out[tbl] = data ?? []
    }
    const blob = new Blob([JSON.stringify(out, null, 2)], { type: 'application/json' })
    const url = URL.createObjectURL(blob)
    const a = document.createElement('a')
    a.href = url
    a.download = `placesecrets-data-${user.id}.json`
    a.click()
    URL.revokeObjectURL(url)
  }

  async function handleAvatarUpload(file: File | undefined) {
    if (!user || !file) return
    setAvatarUploading(true)
    try {
      const ext = (file.name.split('.').pop() || 'jpg').toLowerCase()
      const path = `${user.id}/avatar.${ext}`
      const { error: upErr } = await supabase.storage.from('avatars').upload(path, file, { upsert: true })
      if (upErr) throw upErr
      const { data: pub } = supabase.storage.from('avatars').getPublicUrl(path)
      const publicUrl = `${pub.publicUrl}?t=${Date.now()}`
      const { error } = await supabase.from('user_profiles').upsert({ user_id: user.id, avatar_url: publicUrl }, { onConflict: 'user_id' })
      if (error) throw error
      setAvatarUrl(publicUrl)
      toast.success(t('user.profile.avatarUpdated', 'Profile photo updated'))
    } catch {
      toast.error(t('common.error'))
    } finally {
      setAvatarUploading(false)
    }
  }

  useEffect(() => {
    if (!handle || handle === storeDisplayName) { setHandleError(''); return }
    if (!HANDLE_REGEX.test(handle)) {
      setHandleError(t('handle.invalid'))
      return
    }
    setHandleChecking(true)
    clearTimeout(debounceRef.current)
    debounceRef.current = setTimeout(async () => {
      const { data } = await supabase.rpc('check_handle_available', { p_handle: handle })
      setHandleChecking(false)
      if (data === false) {
        setHandleError(t('handle.taken'))
      } else {
        setHandleError('')
      }
    }, 400)
    return () => clearTimeout(debounceRef.current)
  }, [handle, storeDisplayName, t])

  async function handleSaveHandle(e: React.FormEvent) {
    e.preventDefault()
    if (!user || !handle || handleError || !HANDLE_REGEX.test(handle)) return
    if (handle === storeDisplayName) return
    setHandleLoading(true)
    try {
      const { error } = await supabase
        .from('user_profiles')
        .upsert({ user_id: user.id, display_name: handle }, { onConflict: 'user_id' })
      if (error) throw error
      storeSetDisplayName(handle)
      toast.success(t('handle.saved'))
    } catch {
      toast.error(t('common.error'))
    } finally {
      setHandleLoading(false)
    }
  }

  async function handleLanguageChange(lang: string) {
    setSelectedLang(lang)
    await i18n.changeLanguage(lang)
    if (user) {
      const { error } = await supabase
        .from('user_profiles')
        .upsert({ user_id: user.id, language: lang }, { onConflict: 'user_id' })
      if (error) {
        toast.error(t('common.error'))
      } else {
        toast.success(t('user.profile.languageSaved'))
      }
    }
  }

  async function handleEmailChange(e: React.FormEvent) {
    e.preventDefault()
    if (!newEmail) return
    setEmailLoading(true)
    try {
      const { error } = await supabase.auth.updateUser({ email: newEmail })
      if (error) throw error
      toast.success(t('user.profile.emailUpdated'))
      setNewEmail('')
    } catch {
      toast.error(t('common.error'))
    } finally {
      setEmailLoading(false)
    }
  }

  async function handlePasswordChange(e: React.FormEvent) {
    e.preventDefault()
    if (!newPassword || newPassword !== confirmPassword) {
      toast.error(t('user.profile.passwordMismatch'))
      return
    }
    if (newPassword.length < 8) {
      toast.error(t('user.profile.passwordTooShort'))
      return
    }
    setPasswordLoading(true)
    try {
      const { error } = await supabase.auth.updateUser({ password: newPassword })
      if (error) throw error
      toast.success(t('user.profile.passwordUpdated'))
      setNewPassword('')
      setConfirmPassword('')
    } catch {
      toast.error(t('common.error'))
    } finally {
      setPasswordLoading(false)
    }
  }

  async function handleDeleteAccount() {
    if (!deleteConfirm) {
      setDeleteConfirm(true)
      return
    }
    setDeleteLoading(true)
    try {
      const { error } = await supabase.functions.invoke('delete-user-data', {
        body: { user_id: user?.id },
      })
      if (error) throw error
      toast.success(t('user.profile.accountDeleted'))
      await signOut()
    } catch {
      toast.error(t('common.error'))
    } finally {
      setDeleteLoading(false)
      setDeleteConfirm(false)
    }
  }

  return (
    <div className="space-y-6">
      <Card>
        <CardHeader>
          <CardTitle>{t('handle.handle')}</CardTitle>
          <CardDescription>{t('handle.desc')}</CardDescription>
        </CardHeader>
        <CardContent>
          <form onSubmit={handleSaveHandle} className="flex gap-3">
            <div className="relative flex-1">
              <span className="absolute left-3 top-1/2 -translate-y-1/2 text-muted-foreground text-sm">@</span>
              <Input
                value={handle}
                onChange={e => setHandle(e.target.value.toLowerCase().replace(/[^a-z0-9_]/g, ''))}
                placeholder={t('handle.placeholder')}
                className="pl-7"
              />
              {handleChecking && (
                <Loader2 className="absolute right-3 top-1/2 -translate-y-1/2 h-4 w-4 animate-spin text-muted-foreground" />
              )}
            </div>
            <Button type="submit" disabled={handleLoading || !!handleError || handle === storeDisplayName || !handle}>
              {handleLoading ? t('common.loading') : t('common.save')}
            </Button>
          </form>
          {handleError && <p className="text-xs text-destructive mt-1">{handleError}</p>}
        </CardContent>
      </Card>

      <Card>
        <CardHeader>
          <CardTitle>{t('user.profile.emailAddress')}</CardTitle>
          <CardDescription>{t('user.profile.currentEmail', { email: user?.email })}</CardDescription>
        </CardHeader>
        <CardContent>
          <form onSubmit={handleEmailChange} className="flex gap-3">
            <Input
              type="email"
              placeholder={t('user.profile.newEmail')}
              value={newEmail}
              onChange={e => setNewEmail(e.target.value)}
              className="flex-1"
            />
            <Button type="submit" disabled={emailLoading || !newEmail}>
              {emailLoading ? t('common.loading') : t('user.profile.updateEmail')}
            </Button>
          </form>
        </CardContent>
      </Card>

      <Card>
        <CardHeader>
          <CardTitle>{t('user.profile.backupEmail')}</CardTitle>
          <CardDescription>{t('user.profile.backupEmailDesc')}</CardDescription>
        </CardHeader>
        <CardContent>
          <form onSubmit={async (e) => {
            e.preventDefault()
            if (!user) return
            setBackupEmailLoading(true)
            try {
              const { error } = await supabase
                .from('user_profiles')
                .upsert({ user_id: user.id, backup_email: backupEmail || null }, { onConflict: 'user_id' })
              if (error) throw error
              toast.success(t('user.profile.backupEmailSaved'))
            } catch {
              toast.error(t('common.error'))
            } finally {
              setBackupEmailLoading(false)
            }
          }} className="flex gap-3">
            <Input
              type="email"
              placeholder={t('user.profile.backupEmailPlaceholder')}
              value={backupEmail}
              onChange={e => setBackupEmail(e.target.value)}
              className="flex-1"
            />
            <Button type="submit" disabled={backupEmailLoading}>
              {backupEmailLoading ? t('common.loading') : t('common.save')}
            </Button>
          </form>
        </CardContent>
      </Card>

      <Card>
        <CardHeader>
          <CardTitle>{t('user.profile.avatar', 'Profile photo')}</CardTitle>
          <CardDescription>{t('user.profile.avatarDesc', 'Shown on your profile.')}</CardDescription>
        </CardHeader>
        <CardContent>
          <div className="flex items-center gap-4">
            {avatarUrl ? (
              <img src={avatarUrl} alt="" className="h-16 w-16 rounded-full object-cover" />
            ) : (
              <div className="flex h-16 w-16 items-center justify-center rounded-full bg-muted text-lg font-medium">
                {user?.email?.substring(0, 2).toUpperCase() || '??'}
              </div>
            )}
            <label className="cursor-pointer">
              <input
                type="file"
                accept="image/*"
                className="hidden"
                disabled={avatarUploading}
                onChange={e => handleAvatarUpload(e.target.files?.[0])}
              />
              <span className="inline-flex items-center rounded-md border px-3 py-1.5 text-sm hover:bg-muted">
                {avatarUploading ? t('common.loading') : t('user.profile.uploadAvatar', 'Upload photo')}
              </span>
            </label>
          </div>
        </CardContent>
      </Card>

      <Card>
        <CardHeader>
          <CardTitle>{t('user.profile.emailVerification', 'Email verification')}</CardTitle>
        </CardHeader>
        <CardContent>
          {emailVerified ? (
            <p className="text-sm text-green-600">{t('user.profile.emailVerified', 'Your email is verified.')}</p>
          ) : (
            <div className="flex items-center justify-between gap-3">
              <p className="text-sm text-amber-600">{t('user.profile.emailNotVerified', 'Your email is not verified yet.')}</p>
              {resent ? (
                <span className="text-sm text-muted-foreground">{t('auth.confirmationResent', 'Confirmation email sent.')}</span>
              ) : (
                <Button variant="outline" size="sm" onClick={handleResendVerification} disabled={resendLoading}>
                  {resendLoading ? t('common.loading') : t('user.profile.resendVerification', 'Resend email')}
                </Button>
              )}
            </div>
          )}
        </CardContent>
      </Card>

      <Card>
        <CardHeader>
          <CardTitle>{t('user.profile.marketing', 'Email preferences')}</CardTitle>
        </CardHeader>
        <CardContent>
          <label className="flex items-center gap-2 text-sm">
            <input
              type="checkbox"
              checked={marketingOptIn}
              disabled={marketingLoading}
              onChange={e => handleMarketingToggle(e.target.checked)}
            />
            {t('user.profile.marketingOptIn', 'Send me product news and tips (you can opt out anytime).')}
          </label>
        </CardContent>
      </Card>

      <Card>
        <CardHeader>
          <CardTitle>{t('user.profile.dataExport', 'Export my data')}</CardTitle>
          <CardDescription>{t('user.profile.dataExportDesc', 'Download a copy of your account data (GDPR).')}</CardDescription>
        </CardHeader>
        <CardContent>
          <Button variant="outline" onClick={handleExportData}>
            <Download className="mr-2 h-4 w-4" />
            {t('user.profile.downloadData', 'Download JSON')}
          </Button>
        </CardContent>
      </Card>

      <Card>
        <CardHeader>
          <CardTitle>{t('user.profile.languageSettings')}</CardTitle>
          <CardDescription>{t('user.profile.selectLanguage')}</CardDescription>
        </CardHeader>
        <CardContent>
          <Label htmlFor="language-select" className="sr-only">{t('user.profile.selectLanguage')}</Label>
          <select
            id="language-select"
            value={selectedLang}
            onChange={e => handleLanguageChange(e.target.value)}
            className="w-full max-w-xs rounded-md border border-input bg-background px-3 py-2 text-sm"
          >
            {LANGUAGES.map(lang => (
              <option key={lang.code} value={lang.code}>
                {lang.flag} {lang.name}
              </option>
            ))}
          </select>
        </CardContent>
      </Card>

      <Card>
        <CardHeader>
          <CardTitle>{t('user.profile.changePassword')}</CardTitle>
        </CardHeader>
        <CardContent>
          <form onSubmit={handlePasswordChange} className="space-y-4">
            <div className="space-y-2">
              <Label htmlFor="new-password">{t('user.profile.newPassword')}</Label>
              <Input
                id="new-password"
                type="password"
                value={newPassword}
                onChange={e => setNewPassword(e.target.value)}
                minLength={8}
              />
            </div>
            <div className="space-y-2">
              <Label htmlFor="confirm-password">{t('user.profile.confirmPassword')}</Label>
              <Input
                id="confirm-password"
                type="password"
                value={confirmPassword}
                onChange={e => setConfirmPassword(e.target.value)}
                minLength={8}
              />
            </div>
            <Button type="submit" disabled={passwordLoading || !newPassword || !confirmPassword}>
              {passwordLoading ? t('common.loading') : t('user.profile.changePassword')}
            </Button>
          </form>
        </CardContent>
      </Card>

      <Separator />

      <Card className="border-destructive/50">
        <CardHeader>
          <CardTitle className="text-destructive">{t('user.profile.deleteAccount')}</CardTitle>
          <CardDescription>{t('user.profile.deleteAccountDesc')}</CardDescription>
        </CardHeader>
        <CardContent>
          <Button
            variant="destructive"
            onClick={handleDeleteAccount}
            disabled={deleteLoading}
          >
            {deleteLoading
              ? t('common.loading')
              : deleteConfirm
                ? t('user.profile.confirmDeletion')
                : t('user.profile.deleteMyAccount')}
          </Button>
          {deleteConfirm && (
            <Button
              variant="ghost"
              className="ml-2"
              onClick={() => setDeleteConfirm(false)}
            >
              {t('common.cancel')}
            </Button>
          )}
        </CardContent>
      </Card>
    </div>
  )
}

function PurchasesTab() {
  const { t } = useTranslation()
  const { user } = useAuthStore()
  const [receipts, setReceipts] = useState<PaymentReceipt[]>([])
  const [loading, setLoading] = useState(true)
  const [downloading, setDownloading] = useState<string | null>(null)

  useEffect(() => {
    if (!user) return

    async function loadReceipts() {
      setLoading(true)
      const { data } = await supabase
        .from('payment_receipts')
        .select('id, receipt_number, amount_eur, city_name, created_at, pdf_path')
        .eq('user_id', user!.id)
        .order('created_at', { ascending: false })

      if (data) {
        setReceipts(data)
      }
      setLoading(false)
    }

    loadReceipts()
  }, [user])

  async function handleDownload(receipt: PaymentReceipt) {
    if (!receipt.pdf_path) {
      toast.error(t('user.receipts.pdfUnavailable'))
      return
    }

    setDownloading(receipt.id)
    try {
      const { data, error } = await supabase.storage
        .from('payment-receipts')
        .download(receipt.pdf_path)

      if (error) throw error

      const url = URL.createObjectURL(data)
      const a = document.createElement('a')
      a.href = url
      a.download = `${receipt.receipt_number}.pdf`
      document.body.appendChild(a)
      a.click()
      document.body.removeChild(a)
      URL.revokeObjectURL(url)
    } catch {
      toast.error(t('user.receipts.downloadFailed'))
    } finally {
      setDownloading(null)
    }
  }

  if (loading) {
    return <p className="text-muted-foreground">{t('user.receipts.loading')}</p>
  }

  if (receipts.length === 0) {
    return (
      <Card>
        <CardContent className="py-12 text-center">
          <Receipt className="h-12 w-12 mx-auto mb-4 text-muted-foreground" />
          <p className="text-lg font-medium">{t('user.receipts.noReceipts')}</p>
          <p className="text-sm text-muted-foreground mt-1">
            {t('user.receipts.noReceiptsDesc')}
          </p>
        </CardContent>
      </Card>
    )
  }

  return (
    <Card>
      <Table>
        <TableHeader>
          <TableRow>
            <TableHead>{t('user.receipts.receiptNumber')}</TableHead>
            <TableHead>{t('user.receipts.city')}</TableHead>
            <TableHead>{t('user.receipts.amount')}</TableHead>
            <TableHead>{t('user.receipts.date')}</TableHead>
            <TableHead className="w-[100px]">{t('user.receipts.download')}</TableHead>
          </TableRow>
        </TableHeader>
        <TableBody>
          {receipts.map(receipt => (
            <TableRow key={receipt.id}>
              <TableCell className="font-mono text-sm">{receipt.receipt_number}</TableCell>
              <TableCell>{receipt.city_name}</TableCell>
              <TableCell>{receipt.amount_eur.toFixed(2)} EUR</TableCell>
              <TableCell>{new Date(receipt.created_at).toLocaleDateString()}</TableCell>
              <TableCell>
                <Button
                  variant="ghost"
                  size="sm"
                  disabled={!receipt.pdf_path || downloading === receipt.id}
                  onClick={() => handleDownload(receipt)}
                >
                  <Download className="h-4 w-4" />
                </Button>
              </TableCell>
            </TableRow>
          ))}
        </TableBody>
      </Table>
    </Card>
  )
}

interface PaymentReceipt {
  id: string
  receipt_number: string
  amount_eur: number
  city_name: string
  created_at: string
  pdf_path: string | null
}
