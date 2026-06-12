import { useLocation } from 'react-router-dom'
import { useTranslation } from 'react-i18next'
import { Badge } from '@/components/ui/badge'
import { useAuthStore } from '@/hooks/useAuth'
import { Bell } from 'lucide-react'

export function Header() {
  const location = useLocation()
  const { role } = useAuthStore()
  const { t } = useTranslation()

  const pageTitles: Record<string, string> = {
    '/admin/dashboard': t('admin.header.overview'),
    '/admin/cities': t('admin.header.cities'),
    '/admin/cities/new': t('admin.header.newCity'),
    '/admin/poi-types': t('admin.header.poiTypes'),
    '/admin/users': t('admin.header.users'),
    '/admin/payments': t('admin.header.payments'),
    '/admin/purchases/premium': t('admin.header.premiumPurchases'),
    '/admin/contributors': t('admin.header.contributors'),
    '/admin/hall-of-fame': t('admin.header.hallOfFame'),
    '/admin/settings': t('admin.header.settings'),
  }

  const title = pageTitles[location.pathname] || 'PlaceSecrets Admin'

  return (
    <header className="flex h-[60px] items-center justify-between border-b px-6">
      <h1 className="text-xl font-bold">{title}</h1>
      <div className="flex items-center gap-3">
        <button className="relative rounded-lg p-2 text-muted-foreground hover:bg-muted transition-colors">
          <Bell className="h-5 w-5" />
        </button>
        <Badge variant="secondary" className="capitalize">
          {role || ''}
        </Badge>
      </div>
    </header>
  )
}
