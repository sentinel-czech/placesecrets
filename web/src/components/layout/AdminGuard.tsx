import { Navigate, Outlet } from 'react-router-dom'
import { useAuthStore } from '@/hooks/useAuth'

const ADMIN_ROLES = ['superadmin', 'editor', 'viewer', 'contributor']

export function AdminGuard() {
  const { user, role, loading, adminVerified, mustChangePin } = useAuthStore()

  if (loading) return <div className="flex h-screen items-center justify-center">Loading...</div>
  if (!user) return <Navigate to="/login" replace />
  if (!role || !ADMIN_ROLES.includes(role)) {
    return <Navigate to="/unauthorized" replace />
  }
  if (!adminVerified) return <Navigate to="/admin-pin" replace />
  if (mustChangePin) return <Navigate to="/admin/force-change-pin" replace />

  return <Outlet />
}
