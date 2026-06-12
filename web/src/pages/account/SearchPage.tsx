import { useEffect, useState } from 'react'
import { useSearchParams } from 'react-router-dom'
import { useTranslation } from 'react-i18next'
import { supabase } from '@/lib/supabase/client'
import { Input } from '@/components/ui/input'
import { PoiCard, type PoiPreview } from '@/components/places/PoiCard'
import { Search } from 'lucide-react'

export default function SearchPage() {
  const { t } = useTranslation()
  const [params] = useSearchParams()
  const [query, setQuery] = useState(params.get('q') || '')
  const [results, setResults] = useState<PoiPreview[]>([])
  const [loading, setLoading] = useState(false)
  const [searched, setSearched] = useState(false)

  useEffect(() => {
    const handle = setTimeout(() => {
      const q = query.trim()
      setLoading(true)
      supabase
        .rpc('search_pois', { p_query: q || null, p_limit: 30 })
        .then(({ data }) => {
          setResults((data as PoiPreview[]) || [])
          setLoading(false)
          setSearched(true)
        })
    }, 300)
    return () => clearTimeout(handle)
  }, [query])

  return (
    <div className="space-y-6">
      <div>
        <h1 className="mb-4 text-2xl font-bold">{t('places.search', 'Search places')}</h1>
        <div className="relative max-w-xl">
          <Search className="absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-muted-foreground" />
          <Input
            value={query}
            onChange={e => setQuery(e.target.value)}
            placeholder={t('places.searchPlaceholder', 'Search places, cities…')}
            className="pl-9"
            autoFocus
          />
        </div>
      </div>

      {loading && <p className="text-muted-foreground">{t('common.loading')}</p>}

      {!loading && searched && results.length === 0 && (
        <p className="text-muted-foreground">{t('places.noResults', 'No places found.')}</p>
      )}

      {results.length > 0 && (
        <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4">
          {results.map(p => (
            <PoiCard key={p.id} poi={p} />
          ))}
        </div>
      )}
    </div>
  )
}
