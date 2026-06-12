import { useState } from 'react'
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogFooter } from '@/components/ui/dialog'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { MaterialIcon } from '@/components/shared/MaterialIcon'
import { AVAILABLE_ICONS } from '@/lib/poi-type-icons'
import type { PoiType } from '@/lib/supabase/types'

interface PoiTypeModalProps {
  open: boolean
  onClose: () => void
  onSave: (data: Record<string, unknown>) => void
  initial?: PoiType
}

export function PoiTypeModal({ open, onClose, onSave, initial }: PoiTypeModalProps) {
  const [nameCs, setNameCs] = useState(initial?.name?.cs || '')
  const [nameEn, setNameEn] = useState(initial?.name?.en || '')
  const [slug, setSlug] = useState(initial?.slug || '')
  const [iconName, setIconName] = useState(initial?.icon_name || 'place')
  const [colorHex, setColorHex] = useState(initial?.color_hex || '#2D6A4F')
  const [sortOrder, setSortOrder] = useState(initial?.sort_order || 0)

  function handleSave() {
    onSave({
      name: { cs: nameCs, en: nameEn },
      slug: slug || nameEn.toLowerCase().replace(/\s+/g, '-'),
      icon_name: iconName,
      color_hex: colorHex,
      sort_order: sortOrder,
    })
    onClose()
  }

  return (
    <Dialog open={open} onOpenChange={v => { if (!v) onClose() }}>
      <DialogContent className="max-w-md">
        <DialogHeader>
          <DialogTitle>{initial ? 'Edit POI Type' : 'New POI Type'}</DialogTitle>
        </DialogHeader>
        <div className="space-y-4">
          <div className="grid gap-3 grid-cols-2">
            <div className="space-y-2">
              <Label>Name (CS)</Label>
              <Input value={nameCs} onChange={e => setNameCs(e.target.value)} />
            </div>
            <div className="space-y-2">
              <Label>Name (EN)</Label>
              <Input value={nameEn} onChange={e => setNameEn(e.target.value)} />
            </div>
          </div>
          <div className="space-y-2">
            <Label>Slug</Label>
            <Input value={slug} onChange={e => setSlug(e.target.value)} />
          </div>
          <div className="grid gap-3 grid-cols-2">
            <div className="space-y-2">
              <Label>Color</Label>
              <div className="flex gap-2">
                <input type="color" value={colorHex} onChange={e => setColorHex(e.target.value)} className="w-10 h-10 rounded cursor-pointer" />
                <Input value={colorHex} onChange={e => setColorHex(e.target.value)} />
              </div>
            </div>
            <div className="space-y-2">
              <Label>Sort Order</Label>
              <Input type="number" value={sortOrder} onChange={e => setSortOrder(Number(e.target.value))} />
            </div>
          </div>
          <div className="space-y-2">
            <Label>Icon</Label>
            <div className="flex flex-wrap gap-1 max-h-32 overflow-y-auto border rounded-md p-2">
              {AVAILABLE_ICONS.map(icon => (
                <button
                  key={icon}
                  type="button"
                  onClick={() => setIconName(icon)}
                  className={`p-1.5 rounded ${iconName === icon ? 'bg-primary text-primary-foreground' : 'hover:bg-muted'}`}
                >
                  <MaterialIcon name={icon} className="text-base" />
                </button>
              ))}
            </div>
          </div>
        </div>
        <DialogFooter>
          <Button variant="outline" onClick={onClose}>Cancel</Button>
          <Button onClick={handleSave}>Save</Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  )
}
