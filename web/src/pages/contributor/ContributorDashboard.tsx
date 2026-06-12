import { useEffect, useState } from 'react'
import { useAuthStore } from '@/hooks/useAuth'
import { supabase } from '@/lib/supabase/client'
import type { ContributorProfile } from '@/lib/supabase/types'
import { MetricCard } from '@/components/dashboard/MetricCard'
import { FileText, Star, Eye, CheckCircle } from 'lucide-react'
import { Skeleton } from '@/components/ui/skeleton'

export default function ContributorDashboard() {
  const { user } = useAuthStore()
  const [profile, setProfile] = useState<ContributorProfile | null>(null)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState('')

  useEffect(() => {
    if (!user) return
    let cancelled = false
    supabase.from('contributor_profiles').select('*').eq('user_id', user.id).single().then(({ data, error: err }) => {
      if (cancelled) return
      if (err) setError(err.message)
      else if (data) setProfile(data)
      setLoading(false)
    })
    return () => { cancelled = true }
  }, [user])

  if (loading) {
    return (
      <div className="grid gap-4 md:grid-cols-4">
        {Array.from({ length: 4 }).map((_, i) => <Skeleton key={i} className="h-24" />)}
      </div>
    )
  }

  if (error) return <p className="text-destructive">Failed to load profile: {error}</p>
  if (!profile) return <p>Profile not found</p>

  return (
    <div className="space-y-6">
      <h2 className="text-lg font-semibold">Welcome, {profile.display_name}!</h2>
      <div className="grid gap-4 md:grid-cols-4">
        <MetricCard title="My POIs" value={profile.total_pois} icon={FileText} />
        <MetricCard
          title="Average Rating"
          value={profile.avg_rating ? Number(profile.avg_rating).toFixed(2) : 'N/A'}
          icon={Star}
        />
        <MetricCard title="Total Ratings" value={profile.total_ratings} icon={Eye} />
        <MetricCard
          title="Verification"
          value={profile.is_verified ? 'Verified' : 'Pending'}
          icon={CheckCircle}
        />
      </div>
    </div>
  )
}
