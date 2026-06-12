import { Navigate, Outlet } from 'react-router-dom'
import { useAuthStore } from '@/hooks/useAuth'

export function AccountGuard() {
  const { user, loading } = useAuthStore()

  if (loading) return <div className="flex h-screen items-center justify-center">Loading...</div>
  if (!user) return <Navigate to="/login" replace />

  return <Outlet />
}
