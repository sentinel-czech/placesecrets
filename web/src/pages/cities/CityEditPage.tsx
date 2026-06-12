import { useEffect, useState } from 'react'
import { useParams, useNavigate } from 'react-router-dom'
import { useTranslation } from 'react-i18next'
import { adminSelect, adminUpdate } from '@/lib/supabase/admin-api'
import { CityForm } from '@/components/cities/CityForm'
import type { City, Country } from '@/lib/supabase/types'
import { toast } from 'sonner'
import { Skeleton } from '@/components/ui/skeleton'

export default function CityEditPage() {
  const { t } = useTranslation()
  const { id } = useParams<{ id: string }>()
  const navigate = useNavigate()
  const [city, setCity] = useState<City | null>(null)
  const [countries, setCountries] = useState<Country[]>([])
  const [loading, setLoading] = useState(true)
  const [saving, setSaving] = useState(false)
  const [error, setError] = useState('')

  useEffect(() => {
    if (!id) return
    let cancelled = false
    Promise.all([
      adminSelect('cities', {
        filters: [{ column: 'id', op: 'eq', value: id }],
        single: true,
      }),
      adminSelect('countries', { order: { column: 'name' } }),
    ]).then(([cityRes, countriesRes]) => {
      if (cancelled) return
      if (cityRes.error) setError(cityRes.error)
      else setCity(cityRes.data as City)
      if (countriesRes.data) setCountries(countriesRes.data as Country[])
      setLoading(false)
    })
    return () => { cancelled = true }
  }, [id])

  async function handleSubmit(data: Record<string, unknown>) {
    if (!id) return
    setSaving(true)
    const { error } = await adminUpdate('cities', data, [{ column: 'id', op: 'eq', value: id }])
    setSaving(false)
    if (error) {
      toast.error(error)
    } else {
      toast.success(t('cityPages.cityUpdated'))
      navigate('/admin/cities')
    }
  }

  if (loading) return <Skeleton className="h-96 max-w-2xl" />
  if (error) return <p className="text-destructive">{error}</p>
  if (!city) return <p>{t('cityPages.cityNotFound')}</p>

  return (
    <div className="max-w-2xl">
      <h2 className="text-lg font-semibold mb-4">{t('cityPages.editCity', { name: city.name })}</h2>
      <CityForm initial={city} countries={countries} onSubmit={handleSubmit} loading={saving} />
    </div>
  )
}
