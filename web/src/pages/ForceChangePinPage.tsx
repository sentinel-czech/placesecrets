import { useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { useAuthStore } from '@/hooks/useAuth'
import { supabase } from '@/lib/supabase/client'
import { adminRpc } from '@/lib/supabase/admin-api'
import type { AclPermission } from '@/hooks/useAuth'
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from '@/components/ui/card'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { Button } from '@/components/ui/button'
import { Shield } from 'lucide-react'
import { toast } from 'sonner'
import { useTranslation } from 'react-i18next'

export default function ForceChangePinPage() {
  const [newPin, setNewPin] = useState('')
  const [loading, setLoading] = useState(false)
  const [errors, setErrors] = useState<string[]>([])
  const navigate = useNavigate()
  const { mustChangePin, setMustChangePin, role, setPermissions } = useAuthStore()
  const { t } = useTranslation()

  // Redirect away if not in force-change mode
  if (!mustChangePin) {
    navigate('/admin/dashboard', { replace: true })
    return null
  }

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault()
    if (!newPin) {
      setErrors([t('admin.forceChangePin.newPin')])
      return
    }
    setErrors([])
    setLoading(true)

    try {
      const { data: { session } } = await supabase.auth.getSession()
      const res = await supabase.functions.invoke('change-admin-pin', {
        body: { new_pin: newPin },
        headers: { Authorization: `Bearer ${session?.access_token}` },
      })

      if (res.data?.error) throw new Error(res.data.error)
      if (res.error) {
        let message = res.error.message
        try {
          const body = await (res.error.context as Response).json()
          if (body?.error) message = body.error
        } catch { /* ignore */ }
        throw new Error(message)
      }

      setMustChangePin(false)
      toast.success(t('admin.forceChangePin.success'))

      // Load ACL permissions
      if (role !== 'superadmin') {
        try {
          const { data } = await adminRpc('get_role_permissions', { target_role: role })
          if (data) setPermissions(data as AclPermission[])
        } catch { /* non-critical */ }
      }

      navigate('/admin/dashboard', { replace: true })
    } catch (err: unknown) {
      setErrors([err instanceof Error ? err.message : t('common.error')])
    } finally {
      setLoading(false)
    }
  }

  return (
    <div className="flex min-h-screen items-center justify-center bg-muted/30 p-4">
      <Card className="w-full max-w-md">
        <CardHeader className="text-center">
          <div className="flex justify-center mb-2">
            <div className="rounded-xl bg-primary/10 p-3">
              <Shield className="h-8 w-8 text-primary" />
            </div>
          </div>
          <CardTitle>{t('admin.forceChangePin.title')}</CardTitle>
          <CardDescription>{t('admin.forceChangePin.description')}</CardDescription>
        </CardHeader>
        <CardContent>
          <form onSubmit={handleSubmit} className="space-y-4">
            <div className="space-y-2">
              <Label>{t('admin.forceChangePin.newPin')}</Label>
              <Input
                type="password"
                inputMode="numeric"
                value={newPin}
                onChange={e => setNewPin(e.target.value)}
                placeholder="******"
                autoFocus
              />
            </div>
            {errors.length > 0 && (
              <div className="space-y-1">
                {errors.map((err, i) => (
                  <p key={i} className="text-sm text-destructive">{err}</p>
                ))}
              </div>
            )}
            <Button type="submit" className="w-full" disabled={loading}>
              {loading ? t('common.loading') : t('admin.forceChangePin.submit')}
            </Button>
          </form>
        </CardContent>
      </Card>
    </div>
  )
}
