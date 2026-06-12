import { useNavigate } from 'react-router-dom'
import { useTranslation } from 'react-i18next'
import { Button } from '@/components/ui/button'
import { ShieldAlert } from 'lucide-react'

export default function UnauthorizedPage() {
  const { t } = useTranslation()
  const navigate = useNavigate()
  return (
    <div className="flex min-h-screen flex-col items-center justify-center gap-4">
      <ShieldAlert className="h-16 w-16 text-destructive" />
      <h1 className="text-2xl font-bold">{t('unauthorized.title')}</h1>
      <p className="text-muted-foreground">{t('unauthorized.message')}</p>
      <Button onClick={() => navigate('/login')}>{t('unauthorized.backToLogin')}</Button>
    </div>
  )
}
