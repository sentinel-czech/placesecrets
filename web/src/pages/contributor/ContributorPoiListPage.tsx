import { useEffect, useState } from 'react'
import { Link } from 'react-router-dom'
import { useAuthStore } from '@/hooks/useAuth'
import { supabase } from '@/lib/supabase/client'
import type { Poi } from '@/lib/supabase/types'
import { Button } from '@/components/ui/button'
import { ActiveBadge } from '@/components/shared/StatusBadge'
import { Card, CardContent } from '@/components/ui/card'
import { Plus, Star } from 'lucide-react'

export default function ContributorPoiListPage() {
  const { user } = useAuthStore()
  const [pois, setPois] = useState<(Poi & { city?: { name: string } })[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState('')

  useEffect(() => {
    if (!user) return
    let cancelled = false
    supabase
      .from('pois')
      .select('*, city:cities(name)')
      .eq('contributor_id', user.id)
      .order('created_at', { ascending: false })
      .then(({ data, error: err }) => {
        if (cancelled) return
        if (err) setError(err.message)
        else if (data) setPois(data as typeof pois)
        setLoading(false)
      })
    return () => { cancelled = true }
  }, [user])

  if (loading) return <p>Loading...</p>
  if (error) return <p className="text-destructive">{error}</p>

  return (
    <div className="space-y-4">
      <div className="flex items-center justify-between">
        <h2 className="text-lg font-semibold">My POIs</h2>
        <Link to="/contributor/pois/new">
          <Button><Plus className="h-4 w-4 mr-1" /> New POI</Button>
        </Link>
      </div>

      {pois.length === 0 ? (
        <p className="text-sm text-muted-foreground">You haven't created any POIs yet.</p>
      ) : (
        <div className="space-y-2">
          {pois.map(poi => (
            <Card key={poi.id}>
              <CardContent className="pt-4 flex items-center justify-between">
                <div>
                  <p className="font-medium">{poi.name?.cs || poi.name?.en}</p>
                  <p className="text-sm text-muted-foreground">{poi.city?.name}</p>
                  {poi.avg_rating && (
                    <span className="flex items-center gap-1 text-xs mt-1">
                      <Star className="h-3 w-3 fill-gold text-gold" />
                      {Number(poi.avg_rating).toFixed(1)} ({poi.total_ratings})
                    </span>
                  )}
                </div>
                <div className="flex items-center gap-3">
                  <ActiveBadge active={poi.is_active} />
                  <Link to={`/contributor/pois/${poi.id}`}>
                    <Button variant="outline" size="sm">Edit</Button>
                  </Link>
                </div>
              </CardContent>
            </Card>
          ))}
        </div>
      )}
    </div>
  )
}
