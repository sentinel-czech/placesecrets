import { useState, useEffect, useRef } from 'react'
import { Link } from 'react-router-dom'
import { supabase } from '@/lib/supabase/client'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from '@/components/ui/card'
import { MapPin, CheckCircle, Info, Loader2 } from 'lucide-react'
import { useTranslation } from 'react-i18next'

const HANDLE_REGEX = /^[a-z0-9_]{3,50}$/

export default function ContributorRegisterPage() {
  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')
  const [handle, setHandle] = useState('')
  const [handleError, setHandleError] = useState('')
  const [handleChecking, setHandleChecking] = useState(false)
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState('')
  const [success, setSuccess] = useState(false)
  const { t } = useTranslation()
  const debounceRef = useRef<ReturnType<typeof setTimeout> | undefined>(undefined)

  useEffect(() => {
    if (!handle) { setHandleError(''); return }
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
  }, [handle, t])

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault()
    setError('')
    if (!email || !password || !handle) { setError(t('handle.allFieldsRequired')); return }
    if (!HANDLE_REGEX.test(handle)) { setError(t('handle.invalid')); return }
    if (handleError) return
    if (password.length < 8) { setError(t('user.profile.passwordTooShort')); return }

    setLoading(true)
    try {
      const { data, error: signUpError } = await supabase.auth.signUp({ email, password })
      if (signUpError) throw signUpError
      if (!data.user) throw new Error('Registration failed')

      // Write handle to user_profiles (trigger syncs to contributor_profiles)
      await supabase
        .from('user_profiles')
        .upsert({ user_id: data.user.id, display_name: handle }, { onConflict: 'user_id' })

      // Create contributor profile with same handle
      const { error: profileError } = await supabase.from('contributor_profiles').insert({
        user_id: data.user.id,
        display_name: handle,
      })
      if (profileError) throw profileError

      setSuccess(true)
    } catch (err: unknown) {
      setError(err instanceof Error ? err.message : t('common.error'))
    } finally {
      setLoading(false)
    }
  }

  if (success) {
    return (
      <div className="flex min-h-screen items-center justify-center bg-muted/30 p-4">
        <Card className="w-full max-w-md">
          <CardHeader className="text-center">
            <div className="flex justify-center mb-2">
              <CheckCircle className="h-10 w-10 text-primary" />
            </div>
            <CardTitle className="text-2xl">{t('common.success')}</CardTitle>
            <CardDescription>Your contributor account has been created.</CardDescription>
          </CardHeader>
          <CardContent className="space-y-4">
            <div className="flex items-start gap-2 rounded-lg bg-amber-50 dark:bg-amber-950/30 border border-amber-200 dark:border-amber-800 p-4 text-sm">
              <Info className="h-5 w-5 shrink-0 mt-0.5 text-amber-600" />
              <div>
                <p className="font-medium text-amber-800 dark:text-amber-200">
                  {t('admin.forceChangePin.defaultPinNotice', 'Your initial admin PIN is')} <code className="bg-amber-100 dark:bg-amber-900 px-1.5 py-0.5 rounded font-mono font-bold">123456</code>
                </p>
                <p className="text-amber-700 dark:text-amber-300 mt-1">
                  {t('admin.forceChangePin.defaultPinChangeNotice', 'You will be asked to change it on first login to the admin panel.')}
                </p>
              </div>
            </div>
            <Link to="/login" className="block">
              <Button className="w-full">{t('admin.forceChangePin.goToLogin', 'Sign in to Admin Panel')}</Button>
            </Link>
          </CardContent>
        </Card>
      </div>
    )
  }

  return (
    <div className="flex min-h-screen items-center justify-center bg-muted/30 p-4">
      <Card className="w-full max-w-md">
        <CardHeader className="text-center">
          <div className="flex justify-center mb-2">
            <MapPin className="h-10 w-10 text-primary" />
          </div>
          <CardTitle className="text-2xl">Become a Contributor</CardTitle>
          <CardDescription>Join PlaceSecrets and share your local knowledge</CardDescription>
        </CardHeader>
        <CardContent>
          <form onSubmit={handleSubmit} className="space-y-4">
            <div className="space-y-2">
              <Label>{t('handle.handle')}</Label>
              <div className="relative">
                <span className="absolute left-3 top-1/2 -translate-y-1/2 text-muted-foreground text-sm">@</span>
                <Input
                  value={handle}
                  onChange={e => setHandle(e.target.value.toLowerCase().replace(/[^a-z0-9_]/g, ''))}
                  placeholder={t('handle.placeholder')}
                  className="pl-7"
                  required
                  autoFocus
                />
                {handleChecking && (
                  <Loader2 className="absolute right-3 top-1/2 -translate-y-1/2 h-4 w-4 animate-spin text-muted-foreground" />
                )}
              </div>
              {handleError && <p className="text-xs text-destructive">{handleError}</p>}
              <p className="text-xs text-muted-foreground">{t('handle.desc')}</p>
            </div>
            <div className="space-y-2">
              <Label>{t('common.email')}</Label>
              <Input type="email" value={email} onChange={e => setEmail(e.target.value)} required />
            </div>
            <div className="space-y-2">
              <Label>{t('common.password')}</Label>
              <Input type="password" value={password} onChange={e => setPassword(e.target.value)} required minLength={8} />
            </div>
            {error && <p className="text-sm text-destructive">{error}</p>}
            <Button type="submit" className="w-full" disabled={loading || !!handleError}>
              {loading ? t('common.loading') : t('handle.register')}
            </Button>
          </form>
        </CardContent>
      </Card>
    </div>
  )
}
