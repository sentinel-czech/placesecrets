import { Link, useNavigate } from 'react-router-dom'
import { useTranslation } from 'react-i18next'
import { Button } from '@/components/ui/button'
import { Logo } from '@/components/brand/Logo'
import { SocialAuthButtons } from '@/components/auth/SocialAuthButtons'
import { LanguageSwitcher } from '@/components/layout/LanguageSwitcher'
import { useAuthStore } from '@/hooks/useAuth'

interface PublicHeaderProps {
  showNav?: boolean
}

export function PublicHeader({ showNav = true }: PublicHeaderProps) {
  const { user } = useAuthStore()
  const navigate = useNavigate()
  const { t } = useTranslation()

  return (
    <header className="sticky top-0 z-50 border-b border-border/50 bg-white/90 backdrop-blur-md">
      <div className="mx-auto flex h-16 max-w-7xl items-center justify-between px-4 sm:px-6 lg:px-8">
        <Link to="/" className="flex items-center">
          <Logo variant="full" theme="light" className="w-48" />
        </Link>

        {showNav && (
          <nav className="hidden items-center gap-6 lg:flex">
            <a href="/#explore" className="text-sm font-medium text-muted-foreground transition-colors hover:text-foreground">
              {t('nav.explore')}
            </a>
            <a href="/#how-it-works" className="text-sm font-medium text-muted-foreground transition-colors hover:text-foreground">
              {t('footer.howItWorks', 'How It Works')}
            </a>
            <a href="/#download" className="text-sm font-medium text-muted-foreground transition-colors hover:text-foreground">
              {t('footer.downloadApp', 'Download')}
            </a>
          </nav>
        )}

        <div className="flex items-center gap-3">
          <LanguageSwitcher />
          {user ? (
            <Button size="sm" onClick={() => navigate('/account/explore')}>
              {t('nav.myDashboard', 'My Dashboard')}
            </Button>
          ) : (
            <>
              <div className="hidden sm:block">
                <SocialAuthButtons compact />
              </div>
              <Link to="/login">
                <Button variant="ghost" size="sm">{t('auth.signIn')}</Button>
              </Link>
              <Link to="/register" className="hidden sm:inline-flex">
                <Button size="sm">{t('handle.register')}</Button>
              </Link>
            </>
          )}
        </div>
      </div>
    </header>
  )
}
