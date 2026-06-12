import { useEffect, useState } from 'react'
import { Link } from 'react-router-dom'
import { useTranslation } from 'react-i18next'
import { adminSelect, adminInsert, adminAuthCreateUser } from '@/lib/supabase/admin-api'
import type { AdminUserView } from '@/lib/supabase/types'
import { DataTable } from '@/components/shared/DataTable'
import { Badge } from '@/components/ui/badge'
import { Button } from '@/components/ui/button'
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogFooter } from '@/components/ui/dialog'
import { Label } from '@/components/ui/label'
import { format } from 'date-fns'
import { toast } from 'sonner'
import { Plus } from 'lucide-react'
import { useAuthStore } from '@/hooks/useAuth'
import type { ColumnDef } from '@tanstack/react-table'

export default function UsersPage() {
  const { t } = useTranslation()
  const { hasPermission } = useAuthStore()
  const [users, setUsers] = useState<AdminUserView[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState('')
  const [addOpen, setAddOpen] = useState(false)
  const [addEmail, setAddEmail] = useState('')
  const [addPassword, setAddPassword] = useState('')
  const [addRole, setAddRole] = useState<'superadmin' | 'editor' | 'viewer' | 'contributor' | 'user'>('user')
  const [addLoading, setAddLoading] = useState(false)

  const columns: ColumnDef<AdminUserView>[] = [
    {
      accessorKey: 'user_number',
      header: t('admin.users.userNumber'),
      cell: ({ row }) => row.original.user_number
        ? <span className="font-mono text-xs text-muted-foreground">#{row.original.user_number}</span>
        : <span className="text-muted-foreground">&mdash;</span>,
    },
    {
      accessorKey: 'display_name',
      header: t('handle.handle'),
      cell: ({ row }) => row.original.display_name
        ? <span className="text-sm font-mono">@{row.original.display_name}</span>
        : <span className="text-muted-foreground text-xs">&mdash;</span>,
    },
    { accessorKey: 'email', header: t('common.email') },
    {
      accessorKey: 'is_anonymous',
      header: t('admin.users.type'),
      cell: ({ row }) => (
        <Badge variant="secondary">
          {row.original.is_anonymous ? t('admin.users.anonymous') : t('admin.users.registeredType')}
        </Badge>
      ),
    },
    {
      accessorKey: 'status',
      header: t('common.status'),
      cell: ({ row }) => {
        const status = row.original.status || 'active'
        return status === 'active'
          ? <Badge className="bg-green-600 text-white text-[10px]">{t('admin.users.statusActive')}</Badge>
          : <Badge className="bg-red-600 text-white text-[10px]">{t('admin.users.statusDeactivated')}</Badge>
      },
    },
    { accessorKey: 'access_count', header: t('admin.users.purchases') },
    {
      accessorKey: 'total_spent',
      header: t('admin.users.totalSpent'),
      cell: ({ row }) => `${Number(row.original.total_spent).toFixed(2)} EUR`,
    },
    {
      accessorKey: 'created_at',
      header: t('admin.users.registered'),
      cell: ({ row }) => format(new Date(row.original.created_at), 'dd.MM.yyyy'),
    },
    {
      accessorKey: 'last_sign_in_at',
      header: t('admin.users.lastLogin'),
      cell: ({ row }) => row.original.last_sign_in_at
        ? format(new Date(row.original.last_sign_in_at), 'dd.MM.yyyy HH:mm')
        : '\u2014',
    },
    {
      id: 'actions',
      cell: ({ row }) => (
        <Link to={`/admin/users/${row.original.id}`}>
          <Button variant="outline" size="sm">{t('admin.users.detail')}</Button>
        </Link>
      ),
    },
  ]

  function loadUsers() {
    setLoading(true)
    let cancelled = false
    adminSelect('admin_users_view', {
      order: { column: 'created_at', ascending: false },
    }).then(({ data, error: err }) => {
      if (cancelled) return
      if (err) setError(err)
      else if (data) setUsers(data as AdminUserView[])
      setLoading(false)
    })
    return () => { cancelled = true }
  }

  useEffect(() => {
    return loadUsers()
  }, [])

  async function handleAddUser() {
    if (!addEmail.trim()) return
    setAddLoading(true)
    try {
      const password = addPassword.trim() || Array.from(crypto.getRandomValues(new Uint8Array(16)), b => b.toString(36).padStart(2, '0')).join('').slice(0, 20)

      const { data, error: createErr } = await adminAuthCreateUser({
        email: addEmail.trim(),
        password,
        email_confirm: true,
      })

      if (createErr) {
        toast.error(createErr)
        setAddLoading(false)
        return
      }

      const newUser = data as { user?: { id: string } }
      const newUserId = newUser?.user?.id

      if (newUserId && addRole !== 'user') {
        const { error: adminErr } = await adminInsert('admin_users', {
          user_id: newUserId,
          role: addRole,
          must_change_pin: true,
        })
        if (adminErr) {
          toast.error(adminErr)
          setAddLoading(false)
          return
        }
      }

      toast.success(t('admin.users.userCreated', { email: addEmail.trim(), role: addRole }))
      setAddOpen(false)
      setAddEmail('')
      setAddPassword('')
      setAddRole('user')
      loadUsers()
    } catch {
      toast.error(t('common.error'))
    } finally {
      setAddLoading(false)
    }
  }

  if (loading) return <p>{t('common.loading')}</p>
  if (error) return <p className="text-destructive">{error}</p>

  return (
    <div className="space-y-4">
      {hasPermission('users', 'write') && (
        <div className="flex justify-end">
          <Button onClick={() => setAddOpen(true)} size="sm">
            <Plus className="h-4 w-4 mr-1" />
            {t('admin.users.addUser')}
          </Button>
        </div>
      )}

      <DataTable
        columns={columns}
        data={users}
        searchColumn="email"
        searchPlaceholder={t('common.search') + '...'}
      />

      <Dialog open={addOpen} onOpenChange={v => { if (!v) setAddOpen(false) }}>
        <DialogContent className="max-w-sm">
          <DialogHeader>
            <DialogTitle>{t('admin.users.addUser')}</DialogTitle>
          </DialogHeader>
          <div className="space-y-4">
            <div className="space-y-2">
              <Label>{t('common.email')} *</Label>
              <input
                type="email"
                value={addEmail}
                onChange={e => setAddEmail(e.target.value)}
                className="w-full rounded-md border px-3 py-2 text-sm"
                placeholder="user@example.com"
                required
              />
            </div>
            <div className="space-y-2">
              <Label>{t('common.password')}</Label>
              <input
                type="text"
                value={addPassword}
                onChange={e => setAddPassword(e.target.value)}
                className="w-full rounded-md border px-3 py-2 text-sm"
                placeholder={t('admin.users.passwordPlaceholder')}
              />
            </div>
            <div className="space-y-2">
              <Label>{t('admin.users.role')}</Label>
              <select
                value={addRole}
                onChange={e => setAddRole(e.target.value as typeof addRole)}
                className="w-full rounded-md border px-3 py-2 text-sm"
                aria-label="Select role"
              >
                <option value="user">{t('admin.users.roleUser')}</option>
                <option value="superadmin">{t('admin.users.roleSuperadmin')}</option>
                <option value="editor">{t('admin.users.roleEditor')}</option>
                <option value="viewer">{t('admin.users.roleViewer')}</option>
                <option value="contributor">{t('admin.users.roleContributor')}</option>
              </select>
            </div>
            {addRole !== 'user' && (
              <p className="text-xs text-muted-foreground">
                {t('admin.users.defaultPinInfo')}
              </p>
            )}
          </div>
          <DialogFooter>
            <Button variant="outline" onClick={() => setAddOpen(false)}>{t('common.cancel')}</Button>
            <Button onClick={handleAddUser} disabled={!addEmail.trim() || addLoading}>
              {addLoading ? t('common.loading') : t('common.add')}
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </div>
  )
}
