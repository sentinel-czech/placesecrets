import { useEffect, useState, useCallback } from 'react'
import { useTranslation } from 'react-i18next'
import { adminSelect, adminUpdate, adminDelete } from '@/lib/supabase/admin-api'
import { Card, CardContent } from '@/components/ui/card'
import { Button } from '@/components/ui/button'
import { Badge } from '@/components/ui/badge'
import { Star, Eye, EyeOff, Trash2 } from 'lucide-react'
import { toast } from 'sonner'

interface Rating {
  id: string
  poi_id: string
  rating: number
  comment: string | null
  is_hidden: boolean
  created_at: string
}

export default function ModerationPage() {
  const { t } = useTranslation()
  const [rows, setRows] = useState<Rating[]>([])
  const [loading, setLoading] = useState(true)

  const load = useCallback(() => {
    setLoading(true)
    adminSelect('poi_ratings', {
      select: 'id, poi_id, rating, comment, is_hidden, created_at',
      order: { column: 'created_at', ascending: false },
    }).then(({ data }) => {
      setRows(((data as Rating[]) || []).filter(r => r.comment))
      setLoading(false)
    })
  }, [])

  useEffect(() => { load() }, [load])

  async function toggleHidden(r: Rating) {
    const { error } = await adminUpdate('poi_ratings', { is_hidden: !r.is_hidden }, [{ column: 'id', op: 'eq', value: r.id }])
    if (error) toast.error(error)
    else load()
  }

  async function remove(r: Rating) {
    const { error } = await adminDelete('poi_ratings', [{ column: 'id', op: 'eq', value: r.id }])
    if (error) toast.error(error)
    else load()
  }

  return (
    <div className="max-w-3xl space-y-4">
      <h1 className="text-2xl font-bold">{t('admin.moderation.title', 'Moderation')}</h1>
      <p className="text-sm text-muted-foreground">{t('admin.moderation.desc', 'Hide or remove inappropriate place reviews.')}</p>

      {loading && <p className="text-muted-foreground">{t('common.loading')}</p>}
      {!loading && rows.length === 0 && (
        <p className="text-muted-foreground">{t('admin.moderation.empty', 'No comments to moderate.')}</p>
      )}

      {rows.map(r => (
        <Card key={r.id}>
          <CardContent className="flex items-start justify-between gap-4 pt-6">
            <div className="min-w-0">
              <div className="flex items-center gap-2">
                <span className="flex items-center gap-0.5">
                  {Array.from({ length: 5 }).map((_, i) => (
                    <Star key={i} className={`h-3.5 w-3.5 ${i < r.rating ? 'fill-amber-400 text-amber-400' : 'text-muted-foreground/30'}`} />
                  ))}
                </span>
                {r.is_hidden && <Badge variant="secondary">{t('admin.moderation.hidden', 'Hidden')}</Badge>}
                <span className="text-xs text-muted-foreground">{new Date(r.created_at).toLocaleDateString()}</span>
              </div>
              <p className="mt-1 text-sm">{r.comment}</p>
            </div>
            <div className="flex shrink-0 gap-2">
              <Button variant="outline" size="sm" onClick={() => toggleHidden(r)} title={r.is_hidden ? t('admin.moderation.show', 'Show') : t('admin.moderation.hide', 'Hide')}>
                {r.is_hidden ? <Eye className="h-4 w-4" /> : <EyeOff className="h-4 w-4" />}
              </Button>
              <Button variant="outline" size="sm" onClick={() => remove(r)} title={t('common.delete', 'Delete')}>
                <Trash2 className="h-4 w-4" />
              </Button>
            </div>
          </CardContent>
        </Card>
      ))}
    </div>
  )
}
