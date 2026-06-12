import { create } from 'zustand'
import type { User, Provider } from '@supabase/supabase-js'
import { supabase } from '@/lib/supabase/client'
import i18n from '@/lib/i18n'

export type AppRole = 'superadmin' | 'editor' | 'viewer' | 'contributor' | 'user' | null

interface AuthState {
  user: User | null
  role: AppRole
  contributorId: string | null
  displayName: string | null
  isVerified: boolean
  userNumber: number | null
  needsHandle: boolean
  loading: boolean
  adminVerified: boolean
  mustChangePin: boolean
  permissions: AclPermission[]
  initialize: () => Promise<void>
  signIn: (email: string, password: string) => Promise<{ role: AppRole }>
  signInWithOAuth: (provider: Provider) => Promise<void>
  signOut: () => Promise<void>
  setAdminVerified: (v: boolean) => void
  setMustChangePin: (v: boolean) => void
  setPermissions: (p: AclPermission[]) => void
  setDisplayName: (name: string) => void
  hasPermission: (resource: string, op: 'read' | 'write' | 'delete') => boolean
}

export interface AclPermission {
  resource: string
  can_read: boolean
  can_write: boolean
  can_delete: boolean
}

export const useAuthStore = create<AuthState>((set) => ({
  user: null,
  role: null,
  contributorId: null,
  displayName: null,
  isVerified: false,
  userNumber: null,
  needsHandle: false,
  loading: true,
  adminVerified: false,
  mustChangePin: false,
  permissions: [],

  initialize: async () => {
    const { data: { session } } = await supabase.auth.getSession()
    if (!session?.user) {
      set({ user: null, role: null, loading: false })
      return
    }

    const { role, contributorId, displayName, isVerified } = await resolveUserInfo(session.user.id)
    const { userNumber, profileDisplayName } = await applyUserProfile(session.user.id)
    const resolvedDisplayName = profileDisplayName || displayName
    const needsHandle = !resolvedDisplayName && !session.user.is_anonymous

    set({
      user: session.user,
      role,
      contributorId,
      displayName: resolvedDisplayName,
      isVerified,
      userNumber,
      needsHandle,
      loading: false,
    })

    // Unsubscribe previous listener before setting up a new one
    const store = useAuthStore as unknown as { _authSubscription?: { unsubscribe: () => void } }
    store._authSubscription?.unsubscribe()

    const { data: { subscription } } = supabase.auth.onAuthStateChange((_event, session) => {
      if (!session) {
        set({ user: null, role: null, adminVerified: false, contributorId: null, displayName: null })
      }
    })

    store._authSubscription = subscription
  },

  signIn: async (email: string, password: string) => {
    const { data, error } = await supabase.auth.signInWithPassword({ email, password })
    if (error) throw error

    const { role, contributorId, displayName, isVerified } = await resolveUserInfo(data.user.id)
    const { userNumber, profileDisplayName } = await applyUserProfile(data.user.id)
    const resolvedDisplayName = profileDisplayName || displayName
    const needsHandle = !resolvedDisplayName && !data.user.is_anonymous

    set({ user: data.user, role, contributorId, displayName: resolvedDisplayName, isVerified, userNumber, needsHandle })
    return { role }
  },

  signInWithOAuth: async (provider: Provider) => {
    const { error } = await supabase.auth.signInWithOAuth({
      provider,
      options: { redirectTo: `${window.location.origin}/account/explore` },
    })
    if (error) throw error
  },

  signOut: async () => {
    await supabase.auth.signOut()
    set({ user: null, role: null, adminVerified: false, mustChangePin: false, permissions: [], contributorId: null, displayName: null, isVerified: false, userNumber: null, needsHandle: false })
  },

  setAdminVerified: (v: boolean) => set({ adminVerified: v }),
  setMustChangePin: (v: boolean) => set({ mustChangePin: v }),
  setPermissions: (p: AclPermission[]) => set({ permissions: p }),
  setDisplayName: (name: string) => set({ displayName: name, needsHandle: false }),
  hasPermission: (resource: string, op: 'read' | 'write' | 'delete') => {
    const { role: currentRole, permissions: perms } = useAuthStore.getState() as { role: AppRole; permissions: AclPermission[] }
    if (currentRole === 'superadmin') return true
    const perm = perms.find((p: AclPermission) => p.resource === resource)
    if (!perm) return false
    if (op === 'read') return perm.can_read
    if (op === 'write') return perm.can_write
    if (op === 'delete') return perm.can_delete
    return false
  },
}))

async function applyUserProfile(userId: string): Promise<{ userNumber: number | null; profileDisplayName: string | null }> {
  try {
    const { data } = await supabase
      .from('user_profiles')
      .select('language, user_number, display_name')
      .eq('user_id', userId)
      .maybeSingle()

    if (data?.language) {
      i18n.changeLanguage(data.language)
    }
    return {
      userNumber: data?.user_number ?? null,
      profileDisplayName: data?.display_name ?? null,
    }
  } catch {
    // Ignore — user_profiles might not exist yet
    return { userNumber: null, profileDisplayName: null }
  }
}

async function resolveUserInfo(userId: string): Promise<{
  role: AppRole
  contributorId: string | null
  displayName: string | null
  isVerified: boolean
}> {
  // Use the RLS-accessible web_user_roles view instead of service_role
  const { data: roleRow } = await supabase
    .from('web_user_roles')
    .select('effective_role')
    .eq('user_id', userId)
    .maybeSingle()

  const role = (roleRow?.effective_role as AppRole) || 'user'

  let contributorId: string | null = null
  let displayName: string | null = null
  let isVerified = false

  if (role === 'contributor') {
    const { data: cp } = await supabase
      .from('contributor_profiles')
      .select('id, display_name, is_verified')
      .eq('user_id', userId)
      .single()
    if (cp) {
      contributorId = cp.id
      displayName = cp.display_name
      isVerified = cp.is_verified
    }
  }

  return { role, contributorId, displayName, isVerified }
}
