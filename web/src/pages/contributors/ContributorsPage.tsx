import { useEffect, useState } from 'react'
import { Link } from 'react-router-dom'
import { useTranslation } from 'react-i18next'
import { adminSelect } from '@/lib/supabase/admin-api'
import type { ContributorProfile } from '@/lib/supabase/types'
import { DataTable } from '@/components/shared/DataTable'
import { VerifiedBadge } from '@/components/shared/StatusBadge'
import { Button } from '@/components/ui/button'
import { Star } from 'lucide-react'
import { format } from 'date-fns'
import type { ColumnDef } from '@tanstack/react-table'

export default function ContributorsPage() {
  const { t } = useTranslation()

  const columns: ColumnDef<ContributorProfile>[] = [
    { accessorKey: 'display_name', header: t('contributorsPage.colName') },
    { accessorKey: 'total_pois', header: t('contributorsPage.colPois') },
    {
      accessorKey: 'avg_rating',
      header: t('contributorsPage.colAvgRating'),
      cell: ({ row }) => row.original.avg_rating ? (
        <span className="flex items-center gap-1">
          <Star className="h-3 w-3 fill-gold text-gold" />
          {Number(row.original.avg_rating).toFixed(2)}
        </span>
      ) : '—',
    },
    { accessorKey: 'total_ratings', header: t('contributorsPage.colRatings') },
    {
      accessorKey: 'is_verified',
      header: t('contributorsPage.colStatus'),
      cell: ({ row }) => <VerifiedBadge verified={row.original.is_verified} />,
    },
    {
      accessorKey: 'created_at',
      header: t('contributorsPage.colRegistered'),
      cell: ({ row }) => format(new Date(row.original.created_at), 'dd.MM.yyyy'),
    },
    {
      id: 'actions',
      cell: ({ row }) => (
        <Link to={`/admin/contributors/${row.original.id}`}>
          <Button variant="outline" size="sm">{t('admin.users.detail')}</Button>
        </Link>
      ),
    },
  ]
  const [contributors, setContributors] = useState<ContributorProfile[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState('')

  useEffect(() => {
    let cancelled = false
    adminSelect('contributor_profiles', {
      order: { column: 'created_at', ascending: false },
    }).then(({ data, error: err }) => {
      if (cancelled) return
      if (err) setError(err)
      else if (data) setContributors(data as ContributorProfile[])
      setLoading(false)
    })
    return () => { cancelled = true }
  }, [])

  if (loading) return <p>{t('common.loading')}</p>
  if (error) return <p className="text-destructive">{error}</p>

  return (
    <DataTable
      columns={columns}
      data={contributors}
      searchColumn="display_name"
      searchPlaceholder={t('contributorsPage.searchPlaceholder')}
    />
  )
}
