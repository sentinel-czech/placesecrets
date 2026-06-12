import { useState } from 'react'
import { adminAuthListUsers, adminAuthCreateUser, adminUpsert } from '@/lib/supabase/admin-api'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { Info } from 'lucide-react'
import { toast } from 'sonner'
import { useTranslation } from 'react-i18next'

interface AuthUser {
  id: string
  email?: string
}

interface ListUsersResponse {
  users?: AuthUser[]
}

interface CreateUserResponse {
  user?: AuthUser
}

interface InviteAdminFormProps {
  onInvited: () => void
}

export function InviteAdminForm({ onInvited }: InviteAdminFormProps) {
  const [email, setEmail] = useState('')
  const [role, setRole] = useState('editor')
  const [displayName, setDisplayName] = useState('')
  const [loading, setLoading] = useState(false)
  const { t } = useTranslation()

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault()
    if (!email) return
    setLoading(true)

    let userId: string | null = null
    const { data: usersData } = await adminAuthListUsers()
    const users = (usersData as ListUsersResponse)?.users
    const existing = users?.find(u => u.email === email)

    if (existing) {
      userId = existing.id
    } else {
      const { data: newUser, error } = await adminAuthCreateUser({
        email,
        email_confirm: true,
        password: crypto.randomUUID(),
      })
      const created = newUser as CreateUserResponse | null
      if (error || !created?.user) {
        toast.error(error || 'Failed to create user')
        setLoading(false)
        return
      }
      userId = created.user.id
    }

    const { error: insertError } = await adminUpsert('admin_users', {
      user_id: userId,
      role,
      must_change_pin: true,
    }, 'user_id')

    setLoading(false)
    if (insertError) {
      toast.error(insertError)
    } else {
      toast.success(t('admin.users.userCreated', { email, role }))
      setEmail('')
      setDisplayName('')
      onInvited()
    }
  }

  return (
    <div className="space-y-3">
      <form onSubmit={handleSubmit} className="flex items-end gap-3 flex-wrap">
        <div className="space-y-2 flex-1 min-w-[200px]">
          <Label>{t('common.email')}</Label>
          <Input type="email" value={email} onChange={e => setEmail(e.target.value)} placeholder="user@example.com" />
        </div>
        <div className="space-y-2 min-w-[120px]">
          <Label>{t('common.name', 'Name')}</Label>
          <Input value={displayName} onChange={e => setDisplayName(e.target.value)} placeholder={t('common.name', 'Name')} />
        </div>
        <div className="space-y-2">
          <Label>{t('admin.users.role')}</Label>
          <select value={role} onChange={e => setRole(e.target.value)} className="rounded-md border px-3 py-2 text-sm" aria-label="User role">
            <option value="editor">{t('admin.users.roleEditor', 'Editor')}</option>
            <option value="viewer">{t('admin.users.roleViewer', 'Viewer')}</option>
            <option value="contributor">{t('admin.users.roleContributor', 'Contributor')}</option>
          </select>
        </div>
        <Button type="submit" disabled={loading}>{loading ? t('common.loading') : t('admin.users.addUser', 'Add User')}</Button>
      </form>
      <div className="flex items-start gap-2 rounded-lg bg-muted/50 p-3 text-xs text-muted-foreground">
        <Info className="h-4 w-4 shrink-0 mt-0.5" />
        <span>{t('admin.users.defaultPinInfo')}</span>
      </div>
    </div>
  )
}
