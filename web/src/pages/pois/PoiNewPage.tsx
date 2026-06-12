import { useState } from 'react'
import { useNavigate, useParams } from 'react-router-dom'
import { useTranslation } from 'react-i18next'
import { adminInsert } from '@/lib/supabase/admin-api'
import { PoiForm } from '@/components/pois/PoiForm'
import { toast } from 'sonner'

export default function PoiNewPage() {
  const { t } = useTranslation()
  const { cityId } = useParams<{ cityId: string }>()
  const navigate = useNavigate()
  const [loading, setLoading] = useState(false)

  async function handleSubmit(data: Record<string, unknown>) {
    setLoading(true)
    const { error } = await adminInsert('pois', data)
    setLoading(false)
    if (error) {
      toast.error(error)
    } else {
      toast.success(t('poisPage.poiCreated'))
      navigate(`/admin/cities/${cityId}/pois`)
    }
  }

  return (
    <div className="max-w-3xl">
      <h2 className="text-lg font-semibold mb-4">{t('poisPage.newPoiTitle')}</h2>
      <PoiForm cityId={cityId!} onSubmit={handleSubmit} loading={loading} />
    </div>
  )
}
