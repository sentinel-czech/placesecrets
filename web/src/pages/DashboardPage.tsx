import { useEffect, useState } from 'react'
import { useTranslation } from 'react-i18next'
import { adminSelect, adminRpc } from '@/lib/supabase/admin-api'
import type { AdminStats, RevenueByMonth, DailyActivity, PoiTypeStats } from '@/lib/supabase/types'
import { MetricCard } from '@/components/dashboard/MetricCard'
import { RevenueChart } from '@/components/dashboard/RevenueChart'
import { ActivityChart } from '@/components/dashboard/ActivityChart'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Users, MapPin, Building2, CreditCard, Star, UserCheck, Eye, Layers, TrendingUp } from 'lucide-react'
import { Skeleton } from '@/components/ui/skeleton'

interface TopVisitedPoi {
  poi_id: string
  poi_name: Record<string, string>
  city_name: string
  visit_count: number
}

export default function DashboardPage() {
  const { t } = useTranslation()
  const [stats, setStats] = useState<AdminStats | null>(null)
  const [revenue, setRevenue] = useState<RevenueByMonth[]>([])
  const [activity, setActivity] = useState<DailyActivity[]>([])
  const [poiTypeStats, setPoiTypeStats] = useState<PoiTypeStats[]>([])
  const [topPois, setTopPois] = useState<TopVisitedPoi[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState('')

  useEffect(() => {
    let cancelled = false
    async function load() {
      try {
        const [statsRes, revenueRes, activityRes, typesRes, topRes] = await Promise.all([
          adminSelect('admin_stats', { single: true }),
          adminRpc('revenue_by_month', { months_back: 12 }),
          adminRpc('daily_activity', { days_back: 30 }),
          adminRpc('poi_types_stats'),
          adminRpc('top_visited_pois', { limit_count: 10 }),
        ])
        if (cancelled) return
        if (statsRes.data) setStats(statsRes.data as AdminStats)
        if (revenueRes.data) setRevenue(revenueRes.data as RevenueByMonth[])
        if (activityRes.data) setActivity(activityRes.data as DailyActivity[])
        if (typesRes.data) setPoiTypeStats(typesRes.data as PoiTypeStats[])
        if (topRes.data) setTopPois(topRes.data as TopVisitedPoi[])
      } catch (err) {
        if (!cancelled) setError(String(err))
      } finally {
        if (!cancelled) setLoading(false)
      }
    }
    load()
    return () => { cancelled = true }
  }, [])

  if (loading) {
    return (
      <div className="space-y-6">
        <div className="grid gap-4 md:grid-cols-4">
          {Array.from({ length: 8 }).map((_, i) => <Skeleton key={i} className="h-24" />)}
        </div>
        <div className="grid gap-4 md:grid-cols-2">
          <Skeleton className="h-[300px]" />
          <Skeleton className="h-[300px]" />
        </div>
      </div>
    )
  }

  if (error) return <p className="text-destructive">Failed to load dashboard: {error}</p>
  if (!stats) return <p>Failed to load stats</p>

  return (
    <div className="space-y-6">
      {/* Users section */}
      <div>
        <h2 className="text-sm font-semibold text-muted-foreground uppercase tracking-wider mb-3">{t('admin.dashboard.sectionUsers')}</h2>
        <div className="grid gap-4 md:grid-cols-4">
          <MetricCard title={t('admin.dashboard.registeredUsers')} value={stats.registered_users} icon={Users} color="oklch(0.55 0.15 250)" />
          <MetricCard title={t('admin.dashboard.anonymousUsers')} value={stats.anonymous_users} icon={Users} color="oklch(0.6 0.1 280)" />
          <MetricCard
            title={t('admin.dashboard.contributors')}
            value={stats.total_contributors}
            icon={UserCheck}
            description={t('admin.dashboard.verifiedCount', { count: stats.verified_contributors })}
            color="oklch(0.55 0.15 170)"
          />
          <MetricCard
            title={t('admin.dashboard.avgRating')}
            value={stats.global_avg_rating ? Number(stats.global_avg_rating).toFixed(2) : 'N/A'}
            icon={Star}
            description={t('admin.dashboard.totalRatings', { count: stats.total_poi_ratings })}
            color="oklch(0.62 0.12 90)"
          />
        </div>
      </div>

      {/* Content section */}
      <div>
        <h2 className="text-sm font-semibold text-muted-foreground uppercase tracking-wider mb-3">{t('admin.dashboard.sectionContent')}</h2>
        <div className="grid gap-4 md:grid-cols-3">
          <MetricCard title={t('admin.dashboard.activeCities')} value={stats.active_cities} icon={Building2} color="oklch(0.44 0.1 160)" />
          <MetricCard title={t('admin.dashboard.activePlaces')} value={stats.active_pois} icon={MapPin} color="oklch(0.5 0.15 145)" />
          <MetricCard title={t('admin.dashboard.freeVisitsMonth')} value={stats.free_visits_this_month} icon={Eye} color="oklch(0.55 0.12 200)" />
        </div>
      </div>

      {/* Commerce section */}
      <div>
        <h2 className="text-sm font-semibold text-muted-foreground uppercase tracking-wider mb-3">{t('admin.dashboard.sectionCommerce')}</h2>
        <div className="grid gap-4 md:grid-cols-2">
          <MetricCard
            title={t('admin.dashboard.revenue')}
            value={`${Number(stats.total_revenue_eur).toFixed(2)} EUR`}
            icon={CreditCard}
            description={t('admin.dashboard.purchaseCount', { count: stats.total_purchases })}
            color="oklch(0.62 0.12 90)"
          />
          <MetricCard
            title={t('admin.dashboard.totalPurchases')}
            value={stats.total_purchases}
            icon={TrendingUp}
            color="oklch(0.55 0.18 30)"
          />
        </div>
      </div>

      <div className="grid gap-4 md:grid-cols-2">
        <RevenueChart data={revenue} />
        <ActivityChart data={activity} />
      </div>

      <div className="grid gap-4 md:grid-cols-2">
        <Card>
          <CardHeader>
            <CardTitle className="text-base flex items-center gap-2">
              <Layers className="h-4 w-4" />
              {t('admin.dashboard.poiTypes')}
            </CardTitle>
          </CardHeader>
          <CardContent>
            {poiTypeStats.length === 0 ? (
              <p className="text-sm text-muted-foreground">{t('admin.dashboard.noPoiTypeData')}</p>
            ) : (
              <div className="space-y-2">
                {poiTypeStats.map(pt => (
                  <div key={pt.type_id} className="flex items-center justify-between text-sm">
                    <div className="flex items-center gap-2">
                      <span
                        className="inline-block h-3 w-3 rounded-full"
                        style={{ backgroundColor: pt.color_hex }}
                      />
                      <span>{pt.type_name?.cs || pt.type_name?.en || pt.slug}</span>
                    </div>
                    <span className="font-medium">{pt.poi_count}</span>
                  </div>
                ))}
              </div>
            )}
          </CardContent>
        </Card>

        <Card>
          <CardHeader>
            <CardTitle className="text-base flex items-center gap-2">
              <TrendingUp className="h-4 w-4" />
              {t('admin.dashboard.topVisited')}
            </CardTitle>
          </CardHeader>
          <CardContent>
            {topPois.length === 0 ? (
              <p className="text-sm text-muted-foreground">{t('admin.dashboard.noVisitData')}</p>
            ) : (
              <div className="space-y-2">
                {topPois.map((p, i) => (
                  <div key={p.poi_id} className="flex items-center justify-between text-sm">
                    <div className="flex items-center gap-2">
                      <span className="text-muted-foreground w-5 text-right">{i + 1}.</span>
                      <div>
                        <span>{p.poi_name?.cs || p.poi_name?.en}</span>
                        <span className="text-xs text-muted-foreground ml-1">({p.city_name})</span>
                      </div>
                    </div>
                    <span className="font-medium">{p.visit_count}</span>
                  </div>
                ))}
              </div>
            )}
          </CardContent>
        </Card>
      </div>
    </div>
  )
}
