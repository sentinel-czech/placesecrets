import { useEffect, useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { useTranslation } from 'react-i18next'
import { adminInsert, adminSelect } from '@/lib/supabase/admin-api'
import { CityForm } from '@/components/cities/CityForm'
import type { Country } from '@/lib/supabase/types'
import { toast } from 'sonner'

export default function CityNewPage() {
  const { t } = useTranslation()
  const navigate = useNavigate()
  const [countries, setCountries] = useState<Country[]>([])
  const [loading, setLoading] = useState(false)

  useEffect(() => {
    adminSelect('countries', { order: { column: 'name' } }).then(({ data }) => {
      if (data) setCountries(data as Country[])
    })
  }, [])

  async function handleSubmit(data: Record<string, unknown>) {
    setLoading(true)
    const { error } = await adminInsert('cities', data)
    setLoading(false)
    if (error) {
      toast.error(error)
    } else {
      toast.success(t('cityPages.cityCreated'))
      navigate('/admin/cities')
    }
  }

  return (
    <div className="max-w-2xl">
      <h2 className="text-lg font-semibold mb-4">{t('cityPages.newCity')}</h2>
      <CityForm countries={countries} onSubmit={handleSubmit} loading={loading} />
    </div>
  )
}
