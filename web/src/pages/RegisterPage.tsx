import { useState, useEffect, useRef } from 'react'
import { Link } from 'react-router-dom'
import { supabase } from '@/lib/supabase/client'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { Card, CardContent, CardHeader, CardDescription } from '@/components/ui/card'
import { Separator } from '@/components/ui/separator'
import { SocialAuthButtons } from '@/components/auth/SocialAuthButtons'
import { CheckCircle, Loader2 } from 'lucide-react'
import { Logo } from '@/components/brand/Logo'
import { useTranslation } from 'react-i18next'

const HANDLE_REGEX = /^[a-z0-9_]{3,50}$/

export default function RegisterPage() {
  const { t } = useTranslation()
  const [email, setEmail] = useState('')
  const [handle, setHandle] = useState('')
  const [handleError, setHandleError] = useState('')
  const [handleChecking, setHandleChecking] = useState(false)
  const [password, setPassword] = useState('')
  const [confirmPassword, setConfirmPassword] = useState('')
  const [error, setError] = useState('')
  const [loading, setLoading] = useState(false)
  const [success, setSuccess] = useState(false)
  const [resending, setResending] = useState(false)
  const [resent, setResent] = useState(false)
  const debounceRef = useRef<ReturnType<typeof setTimeout> | undefined>(undefined)

  async function handleResend() {
    setResending(true)
    await supabase.auth.resend({ type: 'signup', email })
    setResending(false)
    setResent(true)
  }

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

    if (password !== confirmPassword) {
      setError(t('user.profile.passwordMismatch'))
      return
    }

    if (password.length < 6) {
      setError(t('user.profile.passwordTooShort'))
      return
    }

    if (handle && !HANDLE_REGEX.test(handle)) {
      setError(t('handle.invalid'))
      return
    }

    if (handle && handleError) return

    setLoading(true)

    try {
      const { data, error: signUpError } = await supabase.auth.signUp({ email, password })
      if (signUpError) throw signUpError

      if (handle && data.user) {
        await supabase
          .from('user_profiles')
          .upsert({ user_id: data.user.id, display_name: handle }, { onConflict: 'user_id' })
      }

      setSuccess(true)
    } catch (err: unknown) {
      if (err instanceof Error) {
        setError(err.message)
      } else {
        setError(t('common.error'))
      }
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
            <h2 className="text-2xl font-semibold">{t('handle.checkEmail')}</h2>
            <CardDescription>
              {t('handle.confirmationSent', { email })}
            </CardDescription>
          </CardHeader>
          <CardContent className="text-center space-y-3">
            {resent ? (
              <p className="text-sm text-muted-foreground">{t('auth.confirmationResent', 'Confirmation email sent.')}</p>
            ) : (
              <Button variant="ghost" size="sm" onClick={handleResend} disabled={resending}>
                {resending ? t('common.loading') : t('auth.resendConfirmation', 'Resend confirmation email')}
              </Button>
            )}
            <div>
              <Link to="/login">
                <Button variant="outline" className="mt-2">{t('handle.backToLogin')}</Button>
              </Link>
            </div>
          </CardContent>
        </Card>
      </div>
    )
  }

  return (
    <div className="flex min-h-screen items-center justify-center bg-muted/30 p-4">
      <Card className="w-full max-w-md">
        <CardHeader className="text-center">
          <Link to="/" className="flex justify-center mb-2">
            <Logo variant="full" theme="light" className="w-64" />
          </Link>
          <CardDescription>{t('handle.createAccount')}</CardDescription>
        </CardHeader>
        <CardContent className="space-y-4">
          <SocialAuthButtons />

          <div className="relative">
            <Separator />
            <span className="absolute left-1/2 top-1/2 -translate-x-1/2 -translate-y-1/2 bg-card px-3 text-xs text-muted-foreground">
              {t('handle.orRegisterWithEmail')}
            </span>
          </div>

          <form onSubmit={handleSubmit} className="space-y-4">
            <div className="space-y-2">
              <Label htmlFor="handle">{t('handle.handle')}</Label>
              <div className="relative">
                <span className="absolute left-3 top-1/2 -translate-y-1/2 text-muted-foreground text-sm">@</span>
                <Input
                  id="handle"
                  value={handle}
                  onChange={e => setHandle(e.target.value.toLowerCase().replace(/[^a-z0-9_]/g, ''))}
                  placeholder={t('handle.placeholder')}
                  className="pl-7"
                />
                {handleChecking && (
                  <Loader2 className="absolute right-3 top-1/2 -translate-y-1/2 h-4 w-4 animate-spin text-muted-foreground" />
                )}
              </div>
              {handleError && <p className="text-xs text-destructive">{handleError}</p>}
              <p className="text-xs text-muted-foreground">{t('handle.desc')}</p>
            </div>
            <div className="space-y-2">
              <Label htmlFor="email">{t('common.email')}</Label>
              <Input
                id="email"
                type="email"
                value={email}
                onChange={e => setEmail(e.target.value)}
                required
              />
            </div>
            <div className="space-y-2">
              <Label htmlFor="password">{t('common.password')}</Label>
              <Input
                id="password"
                type="password"
                value={password}
                onChange={e => setPassword(e.target.value)}
                required
              />
            </div>
            <div className="space-y-2">
              <Label htmlFor="confirmPassword">{t('user.profile.confirmPassword')}</Label>
              <Input
                id="confirmPassword"
                type="password"
                value={confirmPassword}
                onChange={e => setConfirmPassword(e.target.value)}
                required
              />
            </div>
            {error && <p className="text-sm text-destructive">{error}</p>}
            <Button type="submit" className="w-full" disabled={loading || !!handleError}>
              {loading ? t('common.loading') : t('handle.register')}
            </Button>
          </form>

          <p className="text-center text-sm text-muted-foreground">
            {t('handle.haveAccount')}{' '}
            <Link to="/login" className="font-medium text-primary hover:underline">
              {t('handle.signIn')}
            </Link>
          </p>
        </CardContent>
      </Card>
    </div>
  )
}
