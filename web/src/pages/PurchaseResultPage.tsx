import { Link } from 'react-router-dom'
import { useTranslation } from 'react-i18next'
import { PublicHeader } from '@/components/layout/PublicHeader'
import { PublicFooter } from '@/components/layout/PublicFooter'
import { Button } from '@/components/ui/button'
import { CheckCircle, XCircle } from 'lucide-react'

export function PurchaseResultPage({ ok }: { ok: boolean }) {
  const { t } = useTranslation()
  return (
    <div className="flex min-h-screen flex-col">
      <PublicHeader showNav={false} />
      <main className="mx-auto flex w-full max-w-md flex-1 flex-col items-center justify-center gap-4 px-4 py-16 text-center">
        {ok ? (
          <>
            <CheckCircle className="h-12 w-12 text-primary" />
            <h1 className="text-2xl font-bold">{t('purchase.successTitle', 'Payment received')}</h1>
            <p className="text-muted-foreground">{t('purchase.successDesc', 'Your access has been unlocked. It may take a moment to appear.')}</p>
            <Link to="/account/explore"><Button>{t('purchase.goToAccount', 'Go to my account')}</Button></Link>
          </>
        ) : (
          <>
            <XCircle className="h-12 w-12 text-muted-foreground" />
            <h1 className="text-2xl font-bold">{t('purchase.cancelTitle', 'Payment cancelled')}</h1>
            <p className="text-muted-foreground">{t('purchase.cancelDesc', 'No payment was taken. You can try again anytime.')}</p>
            <Link to="/account/explore"><Button variant="outline">{t('purchase.goToAccount', 'Go to my account')}</Button></Link>
          </>
        )}
      </main>
      <PublicFooter />
    </div>
  )
}

export function PurchaseSuccessPage() { return <PurchaseResultPage ok={true} /> }
export function PurchaseCancelPage() { return <PurchaseResultPage ok={false} /> }
