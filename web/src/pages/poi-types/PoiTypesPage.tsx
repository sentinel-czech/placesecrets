import { useEffect, useState, useRef } from 'react'
import { useTranslation } from 'react-i18next'
import { adminSelect, adminInsert, adminUpdate } from '@/lib/supabase/admin-api'
import type { PoiType } from '@/lib/supabase/types'
import { DataTable } from '@/components/shared/DataTable'
import { ActiveBadge } from '@/components/shared/StatusBadge'
import { MaterialIcon } from '@/components/shared/MaterialIcon'
import { PoiTypeModal } from '@/components/poi-types/PoiTypeModal'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Plus, AlertTriangle, Pencil } from 'lucide-react'
import { toast } from 'sonner'
import type { ColumnDef } from '@tanstack/react-table'
import { LANG_CODES } from '@/lib/constants'

function InlineNameCell({ type, langCode, onSave }: {
  type: PoiType
  langCode: string
  onSave: (id: string, name: Record<string, string>) => void
}) {
  const { t } = useTranslation()
  const [editing, setEditing] = useState(false)
  const [value, setValue] = useState('')
  const inputRef = useRef<HTMLInputElement>(null)
  const translation = type.name?.[langCode]
  const fallback = type.name?.en
  const isMissing = !translation

  function startEdit() {
    setValue(translation || '')
    setEditing(true)
    setTimeout(() => inputRef.current?.focus(), 0)
  }

  function save() {
    setEditing(false)
    if (value !== (translation || '')) {
      const updated = { ...type.name, [langCode]: value }
      onSave(type.id, updated)
    }
  }

  function handleKeyDown(e: React.KeyboardEvent) {
    if (e.key === 'Enter') save()
    if (e.key === 'Escape') setEditing(false)
  }

  if (editing) {
    return (
      <Input
        ref={inputRef}
        value={value}
        onChange={e => setValue(e.target.value)}
        onBlur={save}
        onKeyDown={handleKeyDown}
        className="h-7 text-sm"
      />
    )
  }

  return (
    <button
      onClick={startEdit}
      className="group flex items-center gap-1.5 text-left cursor-pointer hover:text-primary"
      title={t('admin.poiTypes.inlineEditHint')}
    >
      {isMissing ? (
        <>
          <span className="text-muted-foreground italic">{fallback || '—'}</span>
          <AlertTriangle className="h-3.5 w-3.5 text-amber-500" />
        </>
      ) : (
        <span>{translation}</span>
      )}
      <Pencil className="h-3 w-3 text-muted-foreground opacity-0 group-hover:opacity-100 transition-opacity" />
    </button>
  )
}

export default function PoiTypesPage() {
  const { t } = useTranslation()
  const [types, setTypes] = useState<PoiType[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState('')
  const [modalOpen, setModalOpen] = useState(false)
  const [editing, setEditing] = useState<PoiType | undefined>()
  const [activeLang, setActiveLang] = useState(() =>
    localStorage.getItem('adminLangFilter') || 'en'
  )

  function changeLang(code: string) {
    setActiveLang(code)
    localStorage.setItem('adminLangFilter', code)
  }

  async function loadTypes(signal?: { cancelled: boolean }) {
    const { data, error: err } = await adminSelect('poi_types', { order: { column: 'sort_order' } })
    if (signal?.cancelled) return
    if (err) setError(err)
    else if (data) setTypes(data as PoiType[])
    setLoading(false)
  }

  useEffect(() => {
    const signal = { cancelled: false }
    loadTypes(signal)
    return () => { signal.cancelled = true }
  }, [])

  async function handleSave(data: Record<string, unknown>) {
    if (editing) {
      const { error } = await adminUpdate('poi_types', data, [{ column: 'id', op: 'eq', value: editing.id }])
      if (error) toast.error(error)
      else toast.success(t('common.success'))
    } else {
      const { error } = await adminInsert('poi_types', data)
      if (error) toast.error(error)
      else toast.success(t('common.success'))
    }
    setEditing(undefined)
    loadTypes()
  }

  async function handleInlineNameSave(id: string, name: Record<string, string>) {
    const { error } = await adminUpdate('poi_types', { name }, [{ column: 'id', op: 'eq', value: id }])
    if (error) toast.error(error)
    else {
      toast.success(t('common.success'))
      loadTypes()
    }
  }

  async function toggleActive(type: PoiType) {
    await adminUpdate('poi_types', { is_active: !type.is_active }, [{ column: 'id', op: 'eq', value: type.id }])
    loadTypes()
  }

  const columns: ColumnDef<PoiType>[] = [
    { accessorKey: 'sort_order', header: t('admin.poiTypes.sortOrder') },
    {
      id: 'icon',
      header: t('admin.poiTypes.icon'),
      cell: ({ row }) => (
        <MaterialIcon name={row.original.icon_name} style={{ color: row.original.color_hex }} />
      ),
    },
    {
      accessorKey: 'name',
      header: t('common.name'),
      cell: ({ row }) => (
        <InlineNameCell
          type={row.original}
          langCode={activeLang}
          onSave={handleInlineNameSave}
        />
      ),
    },
    { accessorKey: 'slug', header: t('admin.poiTypes.slug') },
    {
      accessorKey: 'is_active',
      header: t('common.status'),
      cell: ({ row }) => <ActiveBadge active={row.original.is_active} />,
    },
    {
      id: 'actions',
      cell: ({ row }) => (
        <div className="flex gap-2">
          <Button variant="outline" size="sm" onClick={() => { setEditing(row.original); setModalOpen(true) }}>
            {t('common.edit')}
          </Button>
          <Button variant="ghost" size="sm" onClick={() => toggleActive(row.original)}>
            {row.original.is_active ? t('admin.poiTypes.deactivate') : t('admin.poiTypes.activate')}
          </Button>
        </div>
      ),
    },
  ]

  if (loading) return <p>{t('common.loading')}</p>
  if (error) return <p className="text-destructive">{error}</p>

  return (
    <div className="space-y-4">
      {/* Language pill switcher */}
      <div className="flex items-center gap-2 flex-wrap">
        <span className="text-sm text-muted-foreground">{t('admin.poiTypes.languageFilter')}:</span>
        {LANG_CODES.map(code => (
          <button
            key={code}
            onClick={() => changeLang(code)}
            className={`px-2.5 py-1 rounded-full text-xs font-medium transition-colors ${
              activeLang === code
                ? 'bg-primary text-white'
                : 'bg-muted text-muted-foreground hover:bg-muted/80'
            }`}
          >
            {code.toUpperCase()}
          </button>
        ))}
      </div>

      <div className="flex justify-end">
        <Button onClick={() => { setEditing(undefined); setModalOpen(true) }}>
          <Plus className="h-4 w-4 mr-1" /> {t('admin.poiTypes.newType')}
        </Button>
      </div>
      <DataTable columns={columns} data={types} />
      <PoiTypeModal
        open={modalOpen}
        onClose={() => { setModalOpen(false); setEditing(undefined) }}
        onSave={handleSave}
        initial={editing}
      />
    </div>
  )
}
