import { useEffect, useState, useCallback } from 'react'
import { adminRpc, adminUpdate } from '@/lib/supabase/admin-api'
import { useAuthStore } from '@/hooks/useAuth'
import { Button } from '@/components/ui/button'
import { Card, CardContent } from '@/components/ui/card'
import { Section } from '@/components/shared/Section'
import { Skeleton } from '@/components/ui/skeleton'
import { toast } from 'sonner'
import { useTranslation } from 'react-i18next'
import { cn } from '@/lib/utils'

interface AclRow {
  id: string
  role: string
  resource: string
  can_read: boolean
  can_write: boolean
  can_delete: boolean
}

const RESOURCES = [
  'cities', 'pois', 'own_pois', 'poi_types', 'users', 'payments',
  'settings', 'acl', 'hall_of_fame', 'contributors', 'own_profile',
  'audio', 'dashboard',
]

const ROLES = ['superadmin', 'editor', 'viewer', 'contributor', 'user']

export default function AclManagementPage() {
  const [permissions, setPermissions] = useState<AclRow[]>([])
  const [original, setOriginal] = useState<AclRow[]>([])
  const [loading, setLoading] = useState(true)
  const [saving, setSaving] = useState(false)
  const { hasPermission } = useAuthStore()
  const { t } = useTranslation()
  const canWrite = hasPermission('acl', 'write')

  const load = useCallback(async () => {
    const { data, error } = await adminRpc('get_all_permissions', {})
    if (error) {
      toast.error(error)
    } else if (data) {
      const rows = data as AclRow[]
      setPermissions(rows)
      setOriginal(JSON.parse(JSON.stringify(rows)))
    }
    setLoading(false)
  }, [])

  useEffect(() => { load() }, [load])

  function getCell(r: string, res: string): AclRow | undefined {
    return permissions.find(p => p.role === r && p.resource === res)
  }

  function getOriginalCell(r: string, res: string): AclRow | undefined {
    return original.find(p => p.role === r && p.resource === res)
  }

  function isChanged(cell: AclRow | undefined): boolean {
    if (!cell) return false
    const orig = getOriginalCell(cell.role, cell.resource)
    if (!orig) return false
    return cell.can_read !== orig.can_read || cell.can_write !== orig.can_write || cell.can_delete !== orig.can_delete
  }

  function togglePermission(r: string, res: string, field: 'can_read' | 'can_write' | 'can_delete') {
    if (r === 'superadmin') return
    if (!canWrite) return

    setPermissions(prev => prev.map(p => {
      if (p.role !== r || p.resource !== res) return p
      const updated = { ...p }

      if (field === 'can_read') {
        updated.can_read = !updated.can_read
        if (!updated.can_read) {
          updated.can_write = false
          updated.can_delete = false
        }
      } else if (field === 'can_write') {
        updated.can_write = !updated.can_write
        if (updated.can_write) {
          updated.can_read = true
        } else {
          updated.can_delete = false
        }
      } else if (field === 'can_delete') {
        updated.can_delete = !updated.can_delete
        if (updated.can_delete) {
          updated.can_read = true
          updated.can_write = true
        }
      }

      return updated
    }))
  }

  function hasChanges(): boolean {
    return permissions.some(p => isChanged(p))
  }

  async function handleSave() {
    const changed = permissions.filter(p => isChanged(p) && p.role !== 'superadmin')
    if (changed.length === 0) {
      toast.info(t('admin.acl.noChanges'))
      return
    }

    setSaving(true)
    let failed = false
    for (const c of changed) {
      const { error } = await adminUpdate('acl_permissions', {
        can_read: c.can_read,
        can_write: c.can_write,
        can_delete: c.can_delete,
      }, [{ column: 'id', op: 'eq', value: c.id }])
      if (error) {
        toast.error(error)
        failed = true
        break
      }
    }
    setSaving(false)

    if (!failed) {
      toast.success(t('admin.acl.saved'))
      setOriginal(JSON.parse(JSON.stringify(permissions)))
    }
  }

  if (loading) {
    return (
      <div className="space-y-4">
        <Skeleton className="h-8 w-48" />
        <Skeleton className="h-96" />
      </div>
    )
  }

  return (
    <div className="space-y-4">
      <Section
        title={t('admin.acl.title')}
        description={t('admin.acl.desc', 'Manage what each role can read, write and delete.')}
        action={canWrite && (
          <Button onClick={handleSave} disabled={saving || !hasChanges()}>
            {saving ? t('common.loading') : t('admin.acl.saveChanges')}
          </Button>
        )}
      >
      <Card>
        <CardContent className="overflow-x-auto">
          <table className="w-full text-sm border-collapse">
            <thead>
              <tr className="border-b">
                <th className="text-left py-2 px-3 font-medium">{t('admin.acl.resource')}</th>
                {ROLES.map(r => (
                  <th key={r} className={cn(
                    'text-center py-2 px-2 font-medium',
                    r === 'superadmin' && 'bg-muted/50'
                  )}>
                    {r}
                  </th>
                ))}
              </tr>
            </thead>
            <tbody>
              {RESOURCES.map(res => (
                <tr key={res} className="border-b hover:bg-muted/20">
                  <td className="py-2 px-3 font-medium">{res}</td>
                  {ROLES.map(r => {
                    const cell = getCell(r, res)
                    const changed = isChanged(cell)
                    const disabled = r === 'superadmin' || !canWrite

                    return (
                      <td key={r} className={cn(
                        'text-center py-2 px-2',
                        r === 'superadmin' && 'bg-muted/50',
                        changed && 'bg-yellow-50 dark:bg-yellow-950/20'
                      )}>
                        <div className="flex items-center justify-center gap-1">
                          <label className="cursor-pointer" title="Read">
                            <input
                              type="checkbox"
                              checked={cell?.can_read ?? false}
                              onChange={() => togglePermission(r, res, 'can_read')}
                              disabled={disabled}
                              className="h-3.5 w-3.5 accent-primary"
                            />
                            <span className="sr-only">R</span>
                          </label>
                          <label className="cursor-pointer" title="Write">
                            <input
                              type="checkbox"
                              checked={cell?.can_write ?? false}
                              onChange={() => togglePermission(r, res, 'can_write')}
                              disabled={disabled}
                              className="h-3.5 w-3.5 accent-primary"
                            />
                            <span className="sr-only">W</span>
                          </label>
                          <label className="cursor-pointer" title="Delete">
                            <input
                              type="checkbox"
                              checked={cell?.can_delete ?? false}
                              onChange={() => togglePermission(r, res, 'can_delete')}
                              disabled={disabled}
                              className="h-3.5 w-3.5 accent-primary"
                            />
                            <span className="sr-only">D</span>
                          </label>
                        </div>
                      </td>
                    )
                  })}
                </tr>
              ))}
            </tbody>
          </table>
          <div className="mt-3 flex items-center gap-4 text-xs text-muted-foreground">
            <span>R = {t('admin.acl.read')}</span>
            <span>W = {t('admin.acl.write')}</span>
            <span>D = {t('admin.acl.delete')}</span>
          </div>
          {!canWrite && (
            <p className="mt-2 text-xs text-muted-foreground italic">
              {t('admin.acl.superadminLocked')}
            </p>
          )}
        </CardContent>
      </Card>
      </Section>
    </div>
  )
}
