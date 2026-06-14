import { useEffect, useState } from 'react'
import { Link } from 'react-router-dom'
import { useTranslation } from 'react-i18next'
import { PublicHeader } from '@/components/layout/PublicHeader'
import { PublicFooter } from '@/components/layout/PublicFooter'
import { Button } from '@/components/ui/button'
import { CheckCircle, XCircle, Loader2 } from 'lucide-react'
import { supabase } from '@/lib/supabase/client'

type EntitlementCounts = {
  pois?: unknown[]
  cities?: unknown[]
  city_bundles?: unknown[]
  countries?: unknown[]
}

function ownsSomething(e: EntitlementCounts | null): boolean {
  if (!e) return false
  return (e.pois?.length ?? 0) + (e.cities?.length ?? 0) +
    (e.city_bundles?.length ?? 0) + (e.countries?.length ?? 0) > 0
}

export function PurchaseResultPage({ ok }: { ok: boolean }) {
  const { t } = useTranslation()
  // 'confirming' while we poll for the webhook-granted entitlement; 'unlocked'
  // once it lands; 'slow' if it hasn't arrived within the timeout window.
  const [status, setStatus] = useState<'confirming' | 'unlocked' | 'slow'>('confirming')

  useEffect(() => {
    if (!ok) return
    let cancelled = false
    const MAX_ATTEMPTS = 15 // ~30s at 2s intervals

    const tick = async (attempt: number) => {
      if (cancelled) return
      const { data } = await supabase.rpc('get_my_entitlements')
      if (cancelled) return
      if (ownsSomething(data as EntitlementCounts | null)) {
        setStatus('unlocked')
        return
      }
      if (attempt >= MAX_ATTEMPTS) {
        setStatus('slow')
        return
      }
      setTimeout(() => tick(attempt + 1), 2000)
    }
    tick(0)
    return () => { cancelled = true }
  }, [ok])

  return (
    <div className="flex min-h-screen flex-col">
      <PublicHeader showNav={false} />
      <main className="mx-auto flex w-full max-w-md flex-1 flex-col items-center justify-center gap-4 px-4 py-16 text-center">
        {ok ? (
          <>
            {status === 'confirming' ? (
              <>
                <Loader2 className="h-12 w-12 animate-spin text-primary" />
                <h1 className="text-2xl font-bold">{t('purchase.confirmingTitle', 'Confirming your payment…')}</h1>
                <p className="text-muted-foreground">{t('purchase.confirmingDesc', 'This usually takes a few seconds.')}</p>
              </>
            ) : (
              <>
                <CheckCircle className="h-12 w-12 text-primary" />
                <h1 className="text-2xl font-bold">{t('purchase.successTitle', 'Payment received')}</h1>
                <p className="text-muted-foreground">
                  {status === 'unlocked'
                    ? t('purchase.unlockedDesc', 'Your access has been unlocked.')
                    : t('purchase.successDesc', 'Your access has been unlocked. It may take a moment to appear.')}
                </p>
              </>
            )}
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
