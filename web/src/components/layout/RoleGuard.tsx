import type { ReactNode } from 'react'
import { useAuthStore, type AppRole } from '@/hooks/useAuth'

interface RoleGuardProps {
  allowed: AppRole[]
  children: ReactNode
  fallback?: ReactNode
}

export function RoleGuard({ allowed, children, fallback = null }: RoleGuardProps) {
  const { role } = useAuthStore()
  if (!role || !allowed.includes(role)) return <>{fallback}</>
  return <>{children}</>
}
