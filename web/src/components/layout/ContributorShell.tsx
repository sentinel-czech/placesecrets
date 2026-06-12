import { NavLink, Outlet } from 'react-router-dom'
import { useTranslation } from 'react-i18next'
import { useAuthStore } from '@/hooks/useAuth'
import { LayoutDashboard, FileText, User, LogOut, CheckCircle, Clock } from 'lucide-react'
import { Logo } from '@/components/brand/Logo'
import { cn } from '@/lib/utils'

export function ContributorShell() {
  const { displayName, isVerified, user, signOut } = useAuthStore()
  const { t } = useTranslation()

  const contributorNav = [
    { to: '/contributor/dashboard', icon: LayoutDashboard, label: t('contributor.nav.dashboard') },
    { to: '/contributor/pois', icon: FileText, label: t('contributor.nav.myPois') },
    { to: '/contributor/profile', icon: User, label: t('contributor.nav.profile') },
  ]

  return (
    <div className="flex h-screen">
      <aside className="flex h-screen w-[200px] flex-col bg-sidebar text-sidebar-foreground">
        <div className="flex h-[60px] items-center px-4">
          <Logo variant="full" theme="dark" className="w-44" />
        </div>

        <nav className="flex-1 py-2">
          {contributorNav.map(item => (
            <NavLink
              key={item.to}
              to={item.to}
              className={({ isActive }) => cn(
                'flex items-center gap-3 px-4 py-2.5 text-sm transition-colors',
                isActive
                  ? 'bg-sidebar-accent text-sidebar-primary font-medium'
                  : 'text-sidebar-foreground/70 hover:bg-sidebar-accent/50'
              )}
            >
              <item.icon className="h-4 w-4" />
              {item.label}
            </NavLink>
          ))}
        </nav>

        <div className="border-t border-sidebar-border p-4">
          <p className="text-sm font-medium truncate">{displayName}</p>
          <div className="flex items-center gap-1 text-xs mt-0.5 mb-2">
            {isVerified ? (
              <><CheckCircle className="h-3 w-3 text-blue-400" /> {t('contributor.verified')}</>
            ) : (
              <><Clock className="h-3 w-3 text-orange-400" /> {t('contributor.pendingVerification')}</>
            )}
          </div>
          <p className="text-xs text-sidebar-foreground/50 truncate mb-2">{user?.email}</p>
          <button
            onClick={signOut}
            className="flex items-center gap-2 text-sm text-sidebar-foreground/70 hover:text-sidebar-foreground"
          >
            <LogOut className="h-4 w-4" />
            {t('nav.signOut')}
          </button>
        </div>
      </aside>

      <main className="flex-1 overflow-y-auto p-6">
        <Outlet />
      </main>
    </div>
  )
}
