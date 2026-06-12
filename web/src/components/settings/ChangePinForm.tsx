import { useState } from 'react'
import { useTranslation } from 'react-i18next'
import { supabase } from '@/lib/supabase/client'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { toast } from 'sonner'

export function ChangePinForm() {
  const { t } = useTranslation()
  const [currentPin, setCurrentPin] = useState('')
  const [newPin, setNewPin] = useState('')
  const [loading, setLoading] = useState(false)

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault()
    if (!newPin) { toast.error(t('settings.newPinRequired')); return }

    setLoading(true)
    const { data: { session } } = await supabase.auth.getSession()
    const { data, error } = await supabase.functions.invoke('change-admin-pin', {
      body: { current_pin: currentPin, new_pin: newPin },
      headers: { Authorization: `Bearer ${session?.access_token}` },
    })
    setLoading(false)

    if (error || !data?.success) {
      let message = t('settings.pinChangeFailed')
      // Extract actual error message from Edge Function response
      if (data?.error) {
        message = data.error
      } else if (error?.context) {
        try {
          const body = await (error.context as Response).json()
          if (body?.error) message = body.error
        } catch { /* ignore parse errors */ }
      }
      toast.error(message)
    } else {
      toast.success(t('settings.pinChanged'))
      setCurrentPin('')
      setNewPin('')
    }
  }

  return (
    <form onSubmit={handleSubmit} className="space-y-4 max-w-sm">
      <div className="space-y-2">
        <Label>{t('settings.currentPin')}</Label>
        <Input type="password" value={currentPin} onChange={e => setCurrentPin(e.target.value)} />
      </div>
      <div className="space-y-2">
        <Label>{t('settings.newPin')}</Label>
        <Input type="password" value={newPin} onChange={e => setNewPin(e.target.value)} />
      </div>
      <Button type="submit" disabled={loading}>
        {loading ? t('settings.changingPin') : t('settings.changePin')}
      </Button>
    </form>
  )
}
