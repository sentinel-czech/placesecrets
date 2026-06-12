import { useTranslation } from 'react-i18next'
import type { PoiType } from '@/lib/supabase/types'
import { MaterialIcon } from '@/components/shared/MaterialIcon'

interface PoiTypeFilterProps {
  types: PoiType[]
  selected: Set<string>
  onChange: (selected: Set<string>) => void
}

export function PoiTypeFilter({ types, selected, onChange }: PoiTypeFilterProps) {
  const { t } = useTranslation()

  function toggle(id: string) {
    const next = new Set(selected)
    if (next.has(id)) next.delete(id)
    else next.add(id)
    onChange(next)
  }

  return (
    <div className="space-y-2">
      <p className="text-sm font-medium text-muted-foreground">{t('user.dashboard.stats.filterTypes')}</p>
      <div className="flex flex-wrap gap-2">
        {types.map(type => (
          <button
            key={type.id}
            onClick={() => toggle(type.id)}
            className={`flex items-center gap-1.5 rounded-full px-3 py-1 text-xs font-medium border transition-colors ${
              selected.has(type.id)
                ? 'border-primary bg-primary/10 text-primary'
                : 'border-muted bg-muted text-muted-foreground'
            }`}
          >
            <MaterialIcon name={type.icon_name} style={{ color: type.color_hex, fontSize: 14 }} />
            {type.name?.en || type.slug}
          </button>
        ))}
      </div>
    </div>
  )
}
