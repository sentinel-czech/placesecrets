import { useEffect, useState } from 'react'
import { adminSelect, adminDelete, adminUpdate, adminAuthGetUser } from '@/lib/supabase/admin-api'
import type { AdminUser } from '@/lib/supabase/types'
import { Badge } from '@/components/ui/badge'
import { Button } from '@/components/ui/button'
import { ConfirmDialog } from '@/components/shared/ConfirmDialog'
import { toast } from 'sonner'

export function AdminUsersTable() {
  const [admins, setAdmins] = useState<(AdminUser & { email?: string })[]>([])

  async function loadAdmins() {
    const { data } = await adminSelect('admin_users')
    if (!data) return
    const adminRows = data as AdminUser[]
    const enriched = await Promise.all(adminRows.map(async (a) => {
      const { data: userData } = await adminAuthGetUser(a.user_id)
      const user = (userData as { user?: { email?: string } })?.user
      return { ...a, email: user?.email }
    }))
    setAdmins(enriched)
  }

  useEffect(() => { loadAdmins() }, [])

  async function removeAdmin(id: string) {
    const { error } = await adminDelete('admin_users', [{ column: 'id', op: 'eq', value: id }])
    if (error) toast.error(error)
    else { toast.success('Admin removed'); loadAdmins() }
  }

  async function changeRole(id: string, role: string) {
    const { error } = await adminUpdate('admin_users', { role }, [{ column: 'id', op: 'eq', value: id }])
    if (error) toast.error(error)
    else { toast.success('Role updated'); loadAdmins() }
  }

  return (
    <div className="space-y-2">
      {admins.map(a => (
        <div key={a.id} className="flex items-center justify-between border-b pb-2 text-sm">
          <div>
            <span>{a.email || a.user_id}</span>
            <Badge variant="secondary" className="ml-2 capitalize">{a.role}</Badge>
          </div>
          <div className="flex items-center gap-2">
            <select
              value={a.role}
              onChange={e => changeRole(a.id, e.target.value)}
              className="rounded border px-2 py-1 text-xs"
              aria-label="Change role"
            >
              <option value="superadmin">Superadmin</option>
              <option value="editor">Editor</option>
              <option value="viewer">Viewer</option>
            </select>
            <ConfirmDialog
              trigger={<Button variant="ghost" size="sm" className="text-destructive">Remove</Button>}
              title="Remove Admin"
              description={`Remove ${a.email || 'this user'} from admin access?`}
              onConfirm={() => removeAdmin(a.id)}
              confirmLabel="Remove"
              destructive
            />
          </div>
        </div>
      ))}
    </div>
  )
}
