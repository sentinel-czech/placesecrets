import { NavLink, Link } from 'react-router-dom'
import { useAuthStore } from '@/hooks/useAuth'
import { useTranslation } from 'react-i18next'
import {
  LayoutDashboard, Building2, Users, CreditCard,
  Award, Settings, Tag, UserCheck, LogOut, Crown, ExternalLink,
  FileText, Shield, User, Layout
} from 'lucide-react'
import { Logo } from '@/components/brand/Logo'
import { cn } from '@/lib/utils'

interface NavItem {
  to: string
  icon: React.ComponentType<{ className?: string }>
  label: string
  resource?: string
  op?: 'read' | 'write' | 'delete'
}

function NavSection({ title, items }: {
  title: string
  items: NavItem[]
}) {
  const { hasPermission } = useAuthStore()

  const filtered = items.filter(item => {
    if (!item.resource) return true
    return hasPermission(item.resource, item.op || 'read')
  })
  if (filtered.length === 0) return null

  return (
    <div className="mt-4">
      <p className="px-4 mb-1 text-[11px] font-semibold uppercase tracking-wider text-sidebar-foreground/40">
        {title}
      </p>
      {filtered.map(item => (
        <NavLink
          key={item.to}
          to={item.to}
          className={({ isActive }) => cn(
            'mx-2 flex items-center gap-3 rounded-lg px-3 py-2 text-sm transition-colors',
            isActive
              ? 'bg-sidebar-primary text-white font-medium'
              : 'text-sidebar-foreground/70 hover:bg-sidebar-accent/50'
          )}
        >
          <item.icon className="h-4 w-4" />
          {item.label}
        </NavLink>
      ))}
    </div>
  )
}

export function Sidebar() {
  const { role, user, signOut } = useAuthStore()
  const { t } = useTranslation()

  const isContributor = role === 'contributor'

  const contentNav: NavItem[] = isContributor
    ? [
        { to: '/admin/dashboard', icon: LayoutDashboard, label: t('nav.dashboard'), resource: 'dashboard' },
        { to: '/admin/my-pois', icon: FileText, label: t('nav.myPlaces', 'My Places'), resource: 'own_pois' },
        { to: '/admin/cities', icon: Building2, label: t('nav.cities'), resource: 'cities' },
        { to: '/admin/poi-types', icon: Tag, label: t('nav.placeTypes'), resource: 'poi_types' },
      ]
    : [
        { to: '/admin/dashboard', icon: LayoutDashboard, label: t('nav.dashboard'), resource: 'dashboard' },
        { to: '/admin/cities', icon: Building2, label: t('nav.cities'), resource: 'cities' },
        { to: '/admin/poi-types', icon: Tag, label: t('nav.placeTypes'), resource: 'poi_types' },
      ]

  const commerceNav: NavItem[] = [
    { to: '/admin/users', icon: Users, label: t('nav.users'), resource: 'users' },
    { to: '/admin/payments', icon: CreditCard, label: t('nav.payments'), resource: 'payments' },
    { to: '/admin/purchases/premium', icon: Crown, label: t('nav.premiumPurchases'), resource: 'payments' },
  ]

  const communityNav: NavItem[] = [
    { to: '/admin/contributors', icon: UserCheck, label: t('nav.contributors'), resource: 'contributors' },
    { to: '/admin/hall-of-fame', icon: Award, label: t('nav.hallOfFame'), resource: 'hall_of_fame' },
    { to: '/admin/moderation', icon: Shield, label: t('nav.moderation', 'Moderation'), resource: 'pois' },
    { to: '/admin/acl', icon: Shield, label: t('nav.aclManagement', 'Access Control'), resource: 'acl' },
    { to: '/admin/settings', icon: Settings, label: t('nav.settings'), resource: 'settings' },
    { to: '/admin/landing', icon: Layout, label: t('nav.landing', 'Landing page'), resource: 'settings' },
  ]

  const profileNav: NavItem[] = [
    { to: '/admin/profile', icon: User, label: t('nav.myProfile') },
  ]

  const roleLabelMap: Record<string, string> = {
    superadmin: t('admin.users.roleSuperadmin', 'Superadmin'),
    editor: t('admin.users.roleEditor', 'Editor'),
    viewer: t('admin.users.roleViewer', 'Viewer'),
    contributor: t('admin.users.roleContributor', 'Contributor'),
  }

  return (
    <aside className="flex h-screen w-[220px] flex-col bg-sidebar text-sidebar-foreground">
      <div className="flex h-[60px] items-center px-4">
        <Logo variant="full" theme="dark" className="w-44" />
      </div>

      <nav className="flex-1 overflow-y-auto py-1">
        <NavSection title={t('nav.contentManagement')} items={contentNav} />
        {!isContributor && <NavSection title={t('nav.commerce')} items={commerceNav} />}
        <NavSection title={t('nav.community')} items={communityNav} />
        {isContributor && <NavSection title={t('nav.profile')} items={profileNav} />}
      </nav>

      <div className="border-t border-sidebar-border">
        <Link
          to="/account/explore"
          className="mx-2 mt-2 flex items-center gap-2 rounded-lg px-3 py-2 text-sm text-sidebar-foreground/50 hover:text-sidebar-foreground hover:bg-sidebar-accent/30 transition-colors"
        >
          <ExternalLink className="h-4 w-4" />
          {t('nav.leaveAdmin')}
        </Link>

        <div className="p-4 pt-2">
          <p className="text-xs text-sidebar-foreground/50 truncate">
            {user?.email}
          </p>
          {role && roleLabelMap[role] && (
            <span className="mt-1 inline-block rounded-full bg-gold/20 px-2 py-0.5 text-[10px] font-semibold text-gold">
              {roleLabelMap[role]}
            </span>
          )}
          <button
            onClick={signOut}
            className="mt-2 flex items-center gap-2 text-sm text-sidebar-foreground/70 hover:text-sidebar-foreground transition-colors"
          >
            <LogOut className="h-4 w-4" />
            {t('common.logout')}
          </button>
        </div>
      </div>
    </aside>
  )
}
