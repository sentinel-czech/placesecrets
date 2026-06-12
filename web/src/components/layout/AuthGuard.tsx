import { Navigate, Outlet } from 'react-router-dom'
import { useAuthStore, type AppRole } from '@/hooks/useAuth'

interface AuthGuardProps {
  allowedRoles: AppRole[]
}

export function AuthGuard({ allowedRoles }: AuthGuardProps) {
  const { user, role, loading } = useAuthStore()

  if (loading) return <div className="flex h-screen items-center justify-center">Loading...</div>
  if (!user) return <Navigate to="/login" replace />
  if (!role || !allowedRoles.includes(role)) {
    return <Navigate to="/unauthorized" replace />
  }

  return <Outlet />
}
