import { Link } from 'react-router-dom'
import { useTranslation } from 'react-i18next'
import { Logo } from '@/components/brand/Logo'

export function PublicFooter() {
  const { t } = useTranslation()
  return (
    <footer className="border-t border-border bg-[#1A1A2E] py-12 text-white">
      <div className="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
        <div className="grid gap-8 sm:grid-cols-3">
          <div>
            <div className="mb-3">
              <Logo variant="full" theme="dark" className="w-40" />
            </div>
            <p className="text-sm text-white/50">
              {t('footer.tagline', 'Your personal audio guide to hidden stories behind every place.')}
            </p>
          </div>

          <div>
            <h4 className="mb-3 text-sm font-semibold">{t('footer.explore', 'Explore')}</h4>
            <nav className="flex flex-col gap-2 text-sm text-white/50">
              <a href="/#explore" className="transition-colors hover:text-white">{t('footer.map', 'Map')}</a>
              <a href="/#how-it-works" className="transition-colors hover:text-white">{t('footer.howItWorks', 'How It Works')}</a>
              <a href="/#download" className="transition-colors hover:text-white">{t('footer.downloadApp', 'Download App')}</a>
              <Link to="/register/contributor" className="transition-colors hover:text-white">{t('footer.becomeContributor', 'Become a Contributor')}</Link>
            </nav>
          </div>

          <div>
            <h4 className="mb-3 text-sm font-semibold">{t('footer.legal', 'Legal')}</h4>
            <nav className="flex flex-col gap-2 text-sm text-white/50">
              <Link to="/about" className="transition-colors hover:text-white">{t('footer.about', 'About')}</Link>
              <Link to="/faq" className="transition-colors hover:text-white">{t('footer.faq', 'FAQ')}</Link>
              <Link to="/privacy" className="transition-colors hover:text-white">{t('footer.privacy', 'Privacy Policy')}</Link>
              <Link to="/terms" className="transition-colors hover:text-white">{t('footer.terms', 'Terms of Service')}</Link>
              <Link to="/contact" className="transition-colors hover:text-white">{t('footer.contact', 'Contact')}</Link>
            </nav>
          </div>
        </div>

        <div className="mt-8 border-t border-white/10 pt-8 text-center text-sm text-white/30">
          &copy; {new Date().getFullYear()} Place<span className="text-gold">Secrets</span>. {t('footer.rights', 'All rights reserved.')}
        </div>
      </div>
    </footer>
  )
}
