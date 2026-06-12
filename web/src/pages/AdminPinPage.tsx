import { useState, useRef, useEffect } from 'react'
import { useNavigate } from 'react-router-dom'
import { useAuthStore } from '@/hooks/useAuth'
import { supabase } from '@/lib/supabase/client'
import { adminRpc } from '@/lib/supabase/admin-api'
import type { AclPermission } from '@/hooks/useAuth'
import { Card, CardContent, CardHeader, CardDescription } from '@/components/ui/card'
import { Input } from '@/components/ui/input'
import { Info } from 'lucide-react'
import { Logo } from '@/components/brand/Logo'
import { useTranslation } from 'react-i18next'

export default function AdminPinPage() {
  const [digits, setDigits] = useState(['', '', '', '', '', ''])
  const [error, setError] = useState('')
  const [loading, setLoading] = useState(false)
  const inputRefs = useRef<(HTMLInputElement | null)[]>([])
  const navigate = useNavigate()
  const { role, setAdminVerified, setMustChangePin, setPermissions } = useAuthStore()
  const { t } = useTranslation()

  useEffect(() => {
    if (role && !['superadmin', 'editor', 'viewer', 'contributor'].includes(role)) {
      navigate('/account/explore')
    }
  }, [role, navigate])

  useEffect(() => {
    inputRefs.current[0]?.focus()
  }, [])

  async function loadPermissions() {
    if (role === 'superadmin') return
    try {
      const { data } = await adminRpc('get_role_permissions', { target_role: role })
      if (data) {
        setPermissions(data as AclPermission[])
      }
    } catch {
      // Non-critical — permissions will be checked server-side
    }
  }

  async function verifyPin(pin: string) {
    setLoading(true)
    setError('')
    try {
      const { data: { session } } = await supabase.auth.getSession()
      const res = await supabase.functions.invoke('verify-admin-pin', {
        body: { pin },
        headers: { Authorization: `Bearer ${session?.access_token}` },
      })

      if (res.error) throw new Error(res.error.message)
      if (res.data?.success) {
        setAdminVerified(true)

        if (res.data.must_change_pin) {
          setMustChangePin(true)
          navigate('/admin/force-change-pin')
        } else {
          await loadPermissions()
          navigate('/admin/dashboard')
        }
      } else {
        throw new Error(t('admin.forceChangePin.invalidPin', 'Invalid PIN'))
      }
    } catch (err: unknown) {
      setError(err instanceof Error ? err.message : t('common.error'))
      setDigits(['', '', '', '', '', ''])
      inputRefs.current[0]?.focus()
    } finally {
      setLoading(false)
    }
  }

  function handleChange(index: number, value: string) {
    if (!/^\d?$/.test(value)) return
    const newDigits = [...digits]
    newDigits[index] = value
    setDigits(newDigits)

    if (value && index < 5) {
      inputRefs.current[index + 1]?.focus()
    }

    if (value && index === 5) {
      const pin = newDigits.join('')
      if (pin.length === 6) verifyPin(pin)
    }
  }

  function handleKeyDown(index: number, e: React.KeyboardEvent) {
    if (e.key === 'Backspace' && !digits[index] && index > 0) {
      inputRefs.current[index - 1]?.focus()
    }
  }

  return (
    <div className="flex flex-1 items-center justify-center">
      <Card className="w-full max-w-sm">
        <CardHeader className="text-center">
          <div className="flex justify-center mb-2">
            <Logo variant="full" theme="light" className="w-64" />
          </div>
          <CardDescription>{t('admin.forceChangePin.adminPin', 'Admin PIN')}</CardDescription>
          <p className="text-sm text-muted-foreground mt-1">{t('admin.forceChangePin.enterPin', 'Enter your 6-digit PIN to continue')}</p>
        </CardHeader>
        <CardContent>
          <div className="flex justify-center gap-2 mb-4">
            {digits.map((digit, i) => (
              <Input
                key={i}
                ref={el => { inputRefs.current[i] = el }}
                type="text"
                inputMode="numeric"
                maxLength={1}
                value={digit}
                onChange={e => handleChange(i, e.target.value)}
                onKeyDown={e => handleKeyDown(i, e)}
                className="w-12 h-12 text-center text-xl font-mono"
                disabled={loading}
                aria-label={`PIN digit ${i + 1}`}
              />
            ))}
          </div>
          {error && <p className="text-sm text-destructive text-center">{error}</p>}
          {loading && <p className="text-sm text-muted-foreground text-center">{t('common.loading')}</p>}

          <div className="mt-4 flex items-start gap-2 rounded-lg bg-muted/50 p-3 text-xs text-muted-foreground">
            <Info className="h-4 w-4 shrink-0 mt-0.5" />
            <span>{t('admin.forceChangePin.pinSecure', 'Your PIN is stored securely and cannot be recovered.')}</span>
          </div>
        </CardContent>
      </Card>
    </div>
  )
}
