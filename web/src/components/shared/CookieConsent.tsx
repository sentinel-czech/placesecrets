import { useEffect, useState } from 'react'
import { Link } from 'react-router-dom'
import { useTranslation } from 'react-i18next'
import { Button } from '@/components/ui/button'

const STORAGE_KEY = 'cookie_consent_ack'

/**
 * Informational cookie notice. PlaceSecrets uses only necessary technical
 * storage (login, language) and no advertising/tracking cookies, so a single
 * dismissible acknowledgement with a link to the Privacy Policy is sufficient —
 * no granular consent manager is required. The acknowledgement is remembered in
 * localStorage so it is shown only once.
 */
export function CookieConsent() {
  const { t } = useTranslation()
  const [visible, setVisible] = useState(false)

  useEffect(() => {
    try {
      if (!localStorage.getItem(STORAGE_KEY)) setVisible(true)
    } catch {
      // localStorage unavailable (private mode) — don't block the UI.
    }
  }, [])

  function acknowledge() {
    try {
      localStorage.setItem(STORAGE_KEY, new Date().toISOString())
    } catch {
      /* ignore */
    }
    setVisible(false)
  }

  if (!visible) return null

  return (
    <div
      role="dialog"
      aria-live="polite"
      aria-label={t('cookies.title', 'Cookie notice')}
      className="fixed inset-x-0 bottom-0 z-50 border-t bg-background/95 backdrop-blur px-4 py-3 shadow-lg"
    >
      <div className="mx-auto flex max-w-4xl flex-col gap-3 sm:flex-row sm:items-center sm:justify-between">
        <p className="text-sm text-muted-foreground">
          {t(
            'cookies.message',
            'We use only necessary technical storage (e.g. login and language). We do not use advertising or tracking cookies.',
          )}{' '}
          <Link to="/privacy" className="text-primary underline underline-offset-2">
            {t('cookies.learnMore', 'Privacy Policy')}
          </Link>
        </p>
        <Button onClick={acknowledge} className="shrink-0">
          {t('cookies.accept', 'Got it')}
        </Button>
      </div>
    </div>
  )
}
