import { useEffect, useState } from 'react'
import { useParams } from 'react-router-dom'
import { useTranslation } from 'react-i18next'
import { adminSelect, adminUpdate } from '@/lib/supabase/admin-api'
import type { ContributorProfile, Poi } from '@/lib/supabase/types'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Button } from '@/components/ui/button'
import { VerifiedBadge, ActiveBadge } from '@/components/shared/StatusBadge'
import { Skeleton } from '@/components/ui/skeleton'
import { Star } from 'lucide-react'
import { toast } from 'sonner'
import { format } from 'date-fns'

export default function ContributorDetailPage() {
  const { t } = useTranslation()
  const { id } = useParams<{ id: string }>()
  const [contributor, setContributor] = useState<ContributorProfile | null>(null)
  const [pois, setPois] = useState<Poi[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState('')

  async function loadData() {
    if (!id) return
    try {
      const [cpRes, poisRes] = await Promise.all([
        adminSelect('contributor_profiles', { filters: [{ column: 'id', op: 'eq', value: id }], single: true }),
        adminSelect('pois', { filters: [{ column: 'contributor_id', op: 'eq', value: id }], order: { column: 'sort_order' } }),
      ])
      if (cpRes.data) setContributor(cpRes.data as ContributorProfile)
      if (poisRes.data) setPois(poisRes.data as Poi[])
    } catch (err) {
      setError(String(err))
    } finally {
      setLoading(false)
    }
  }

  useEffect(() => { loadData() }, [id])

  async function toggleVerified() {
    if (!contributor) return
    const { error } = await adminUpdate('contributor_profiles', {
      is_verified: !contributor.is_verified,
    }, [{ column: 'id', op: 'eq', value: contributor.id }])
    if (error) toast.error(error)
    else { toast.success(contributor.is_verified ? t('contributorsPage.unverified') : t('contributorsPage.verified')); loadData() }
  }

  async function toggleActive() {
    if (!contributor) return
    const { error } = await adminUpdate('contributor_profiles', {
      is_active: !contributor.is_active,
    }, [{ column: 'id', op: 'eq', value: contributor.id }])
    if (error) toast.error(error)
    else { toast.success(contributor.is_active ? t('contributorsPage.deactivated') : t('contributorsPage.activated')); loadData() }
  }

  if (loading) return <Skeleton className="h-64 max-w-2xl" />
  if (error) return <p className="text-destructive">{error}</p>
  if (!contributor) return <p>{t('contributorsPage.contributorNotFound')}</p>

  return (
    <div className="max-w-2xl space-y-6">
      <Card>
        <CardHeader>
          <div className="flex items-center justify-between">
            <CardTitle className="text-base">{contributor.display_name}</CardTitle>
            <div className="flex gap-2">
              <VerifiedBadge verified={contributor.is_verified} />
              <ActiveBadge active={contributor.is_active} />
            </div>
          </div>
        </CardHeader>
        <CardContent className="grid gap-2 text-sm">
          {contributor.bio && <div><span className="text-muted-foreground">{t('contributorsPage.bio')}:</span> {contributor.bio}</div>}
          {contributor.website_url && /^https?:\/\//.test(contributor.website_url) && (
            <div><span className="text-muted-foreground">{t('contributorsPage.website')}:</span> <a href={contributor.website_url} target="_blank" rel="noopener noreferrer" className="text-primary underline">{contributor.website_url}</a></div>
          )}
          {contributor.specializations.length > 0 && (
            <div><span className="text-muted-foreground">{t('contributorsPage.specializations')}:</span> {contributor.specializations.join(', ')}</div>
          )}
          <div className="flex gap-6 mt-2">
            <span><strong>{contributor.total_pois}</strong> {t('contributorsPage.pois')}</span>
            <span className="flex items-center gap-1">
              <Star className="h-3 w-3 fill-gold text-gold" />
              <strong>{contributor.avg_rating ? Number(contributor.avg_rating).toFixed(2) : 'N/A'}</strong>
              ({contributor.total_ratings} {t('contributorsPage.ratings')})
            </span>
          </div>
          <div className="text-muted-foreground text-xs mt-2">
            {t('contributorsPage.registered')}: {format(new Date(contributor.created_at), 'dd.MM.yyyy')}
          </div>
        </CardContent>
      </Card>

      <div className="flex gap-3">
        <Button onClick={toggleVerified}>
          {contributor.is_verified ? t('contributorsPage.removeVerification') : t('contributorsPage.verifyContributor')}
        </Button>
        <Button variant={contributor.is_active ? 'destructive' : 'outline'} onClick={toggleActive}>
          {contributor.is_active ? t('admin.users.deactivate') : t('admin.users.activate')}
        </Button>
      </div>

      <Card>
        <CardHeader><CardTitle className="text-base">{t('contributorsPage.pois')} ({pois.length})</CardTitle></CardHeader>
        <CardContent>
          {pois.length === 0 ? (
            <p className="text-sm text-muted-foreground">{t('contributorsPage.noPoisYet')}</p>
          ) : (
            <div className="space-y-2">
              {pois.map(p => (
                <div key={p.id} className="flex items-center justify-between text-sm border-b pb-2">
                  <span>{p.name?.cs || p.name?.en}</span>
                  <div className="flex items-center gap-3">
                    {p.avg_rating && (
                      <span className="flex items-center gap-1 text-xs">
                        <Star className="h-3 w-3 fill-gold text-gold" />
                        {Number(p.avg_rating).toFixed(1)}
                      </span>
                    )}
                    <ActiveBadge active={p.is_active} />
                  </div>
                </div>
              ))}
            </div>
          )}
        </CardContent>
      </Card>
    </div>
  )
}
