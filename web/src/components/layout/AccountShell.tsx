import { NavLink, Outlet, useNavigate } from 'react-router-dom'
import { useTranslation } from 'react-i18next'
import { useAuthStore } from '@/hooks/useAuth'
import { Compass, History, LogOut, Settings, Shield, Receipt, Menu, MapPin, LayoutGrid, Search } from 'lucide-react'
import { Logo } from '@/components/brand/Logo'
import { cn } from '@/lib/utils'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { LanguageSwitcher } from '@/components/layout/LanguageSwitcher'
import { Avatar, AvatarFallback } from '@/components/ui/avatar'
import {
  DropdownMenu,
  DropdownMenuTrigger,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuSeparator,
} from '@/components/ui/dropdown-menu'
import { useState } from 'react'

export function AccountShell() {
  const { user, role, signOut } = useAuthStore()
  const navigate = useNavigate()
  const { t } = useTranslation()
  const [mobileOpen, setMobileOpen] = useState(false)

  const [search, setSearch] = useState('')

  const accountNav = [
    { to: '/account/explore', icon: Compass, label: t('nav.explore') },
    { to: '/account/cities', icon: LayoutGrid, label: t('nav.catalog', 'Browse') },
    { to: '/account/search', icon: Search, label: t('nav.search', 'Search') },
    { to: '/account/history', icon: History, label: t('nav.myHistory') },
  ]

  function submitSearch(e: React.FormEvent) {
    e.preventDefault()
    const q = search.trim()
    navigate(q ? `/account/search?q=${encodeURIComponent(q)}` : '/account/search')
  }
  const isAdmin = role && ['superadmin', 'editor', 'viewer'].includes(role)
  const isContributor = role === 'contributor'

  const initials = user?.email
    ? user.email.substring(0, 2).toUpperCase()
    : '??'

  return (
    <div className="flex h-screen">
      {/* Sidebar - desktop */}
      <aside className="hidden md:flex h-screen w-[220px] flex-col bg-sidebar text-sidebar-foreground">
        <NavLink to="/" className="flex h-[60px] items-center px-4">
          <Logo variant="full" theme="dark" className="w-44" />
        </NavLink>

        <nav className="flex-1 py-2">
          {accountNav.map(item => (
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

          {isAdmin && (
            <>
              <div className="mx-4 my-2 h-px bg-sidebar-border" />
              <NavLink
                to="/admin-pin"
                className="flex items-center gap-3 px-4 py-2.5 text-sm text-sidebar-foreground/70 hover:bg-sidebar-accent/50"
              >
                <Shield className="h-4 w-4" />
                {t('nav.adminPanel')}
              </NavLink>
            </>
          )}

          {isContributor && (
            <>
              <div className="mx-4 my-2 h-px bg-sidebar-border" />
              <NavLink
                to="/contributor/dashboard"
                className="flex items-center gap-3 px-4 py-2.5 text-sm text-sidebar-foreground/70 hover:bg-sidebar-accent/50"
              >
                <MapPin className="h-4 w-4" />
                {t('nav.contributorPortal')}
              </NavLink>
            </>
          )}
        </nav>

      </aside>

      {/* Mobile sidebar overlay */}
      {mobileOpen && (
        <div className="fixed inset-0 z-40 md:hidden" onClick={() => setMobileOpen(false)}>
          <div className="absolute inset-0 bg-black/30" />
          <aside
            className="absolute left-0 top-0 h-full w-[260px] bg-sidebar text-sidebar-foreground shadow-xl"
            onClick={e => e.stopPropagation()}
          >
            <div className="flex h-[60px] items-center px-4">
              <Logo variant="full" theme="dark" className="w-44" />
            </div>
            <nav className="py-2">
              {accountNav.map(item => (
                <NavLink
                  key={item.to}
                  to={item.to}
                  onClick={() => setMobileOpen(false)}
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
              {isAdmin && (
                <>
                  <div className="mx-4 my-2 h-px bg-sidebar-border" />
                  <NavLink
                    to="/admin-pin"
                    onClick={() => setMobileOpen(false)}
                    className="flex items-center gap-3 px-4 py-2.5 text-sm text-sidebar-foreground/70 hover:bg-sidebar-accent/50"
                  >
                    <Shield className="h-4 w-4" />
                    {t('nav.adminPanel')}
                  </NavLink>
                </>
              )}
              {isContributor && (
                <>
                  <div className="mx-4 my-2 h-px bg-sidebar-border" />
                  <NavLink
                    to="/contributor/dashboard"
                    onClick={() => setMobileOpen(false)}
                    className="flex items-center gap-3 px-4 py-2.5 text-sm text-sidebar-foreground/70 hover:bg-sidebar-accent/50"
                  >
                    <MapPin className="h-4 w-4" />
                    {t('nav.contributorPortal')}
                  </NavLink>
                </>
              )}
            </nav>
          </aside>
        </div>
      )}

      {/* Main content area */}
      <div className="flex flex-1 flex-col overflow-hidden">
        {/* Top header bar */}
        <header className="flex h-14 items-center justify-between border-b bg-white px-4 sm:px-6">
          <Button
            variant="ghost"
            size="sm"
            className="md:hidden"
            onClick={() => setMobileOpen(true)}
          >
            <Menu className="h-5 w-5" />
          </Button>

          <form onSubmit={submitSearch} className="hidden md:block relative w-full max-w-xs">
            <Search className="absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-muted-foreground" />
            <Input
              value={search}
              onChange={e => setSearch(e.target.value)}
              placeholder={t('places.searchPlaceholder', 'Search places, cities…')}
              className="pl-9 h-9"
            />
          </form>

          <div className="flex items-center gap-3">
            <LanguageSwitcher />
            <span className="hidden md:block max-w-[200px] truncate text-sm text-muted-foreground">
              {user?.email}
            </span>
            <DropdownMenu>
              <DropdownMenuTrigger
                className="flex items-center gap-2 rounded-full outline-none focus:ring-2 focus:ring-ring focus:ring-offset-2"
              >
                <Avatar size="sm">
                  <AvatarFallback>{initials}</AvatarFallback>
                </Avatar>
              </DropdownMenuTrigger>
              <DropdownMenuContent align="end" sideOffset={8}>
                <p className="px-1.5 py-1 text-xs font-medium text-muted-foreground truncate max-w-[200px]">
                  {user?.email}
                </p>
                <DropdownMenuSeparator />
                <DropdownMenuItem onClick={() => navigate('/account/profile?tab=settings')}>
                  <Settings className="h-4 w-4" />
                  {t('nav.accountSettings')}
                </DropdownMenuItem>
                <DropdownMenuItem onClick={() => navigate('/account/profile?tab=purchases')}>
                  <Receipt className="h-4 w-4" />
                  {t('user.profile.myPurchases')}
                </DropdownMenuItem>
                {isAdmin && (
                  <>
                    <DropdownMenuSeparator />
                    <DropdownMenuItem onClick={() => navigate('/admin-pin')}>
                      <Shield className="h-4 w-4" />
                      {t('nav.adminPanel')}
                    </DropdownMenuItem>
                  </>
                )}
                <DropdownMenuSeparator />
                <DropdownMenuItem variant="destructive" onClick={() => signOut()}>
                  <LogOut className="h-4 w-4" />
                  {t('nav.signOut')}
                </DropdownMenuItem>
              </DropdownMenuContent>
            </DropdownMenu>
          </div>
        </header>

        <main className="relative z-0 flex-1 overflow-y-auto p-4 sm:p-6">
          <Outlet />
        </main>
      </div>
    </div>
  )
}
