import { useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { useTranslation } from 'react-i18next'
import { useAuthStore } from '@/hooks/useAuth'
import { supabase } from '@/lib/supabase/client'
import { Button } from '@/components/ui/button'
import { ShoppingCart } from 'lucide-react'
import { toast } from 'sonner'

interface BuyButtonProps {
  purchaseType: 'poi' | 'city_premium' | 'country'
  poiId?: string
  cityId?: string
  countryCode?: string
  price: number
  label?: string
}

/** Starts a Comgate checkout for a place / city / country and redirects to the gateway. */
export function BuyButton({ purchaseType, poiId, cityId, countryCode, price, label }: BuyButtonProps) {
  const { t } = useTranslation()
  const { user } = useAuthStore()
  const navigate = useNavigate()
  const [loading, setLoading] = useState(false)

  async function buy() {
    if (!user) { navigate('/login'); return }
    setLoading(true)
    const body: Record<string, unknown> = { purchase_type: purchaseType }
    if (poiId) body.poi_id = poiId
    if (cityId) body.city_id = cityId
    if (countryCode) body.country_code = countryCode
    const { data, error } = await supabase.functions.invoke('comgate-create', { body })
    setLoading(false)
    const redirect = (data as { redirect?: string } | null)?.redirect
    if (error || !redirect) {
      toast.error(t('buy.unavailable', 'Payment is not available yet.'))
      return
    }
    window.location.href = redirect
  }

  return (
    <Button onClick={buy} disabled={loading} className="gap-2">
      <ShoppingCart className="h-4 w-4" />
      {label || t('buy.buyFor', 'Buy for')} €{price.toFixed(2)}
    </Button>
  )
}
