import { describe, it, expect, vi, beforeEach } from 'vitest'
import { render, screen } from '@testing-library/react'
import { MemoryRouter, Route, Routes } from 'react-router-dom'
import { AdminGuard } from '@/components/layout/AdminGuard'
import { AccountGuard } from '@/components/layout/AccountGuard'

const mockUseAuthStore = vi.hoisted(() => vi.fn())

vi.mock('@/hooks/useAuth', () => ({
  useAuthStore: mockUseAuthStore,
}))

vi.mock('@/lib/supabase/client', () => ({
  supabase: {
    auth: { getSession: vi.fn().mockResolvedValue({ data: { session: null } }) },
    from: vi.fn(),
    rpc: vi.fn(),
  },
}))

describe('AdminGuard', () => {
  beforeEach(() => {
    vi.clearAllMocks()
  })

  it('unauthenticated redirects to /login', () => {
    mockUseAuthStore.mockReturnValue({
      user: null,
      role: null,
      loading: false,
      adminVerified: false,
    })

    render(
      <MemoryRouter initialEntries={['/admin/dashboard']}>
        <Routes>
          <Route element={<AdminGuard />}>
            <Route path="/admin/dashboard" element={<div>Dashboard</div>} />
          </Route>
          <Route path="/login" element={<div>Login Page</div>} />
        </Routes>
      </MemoryRouter>
    )

    expect(screen.getByText('Login Page')).toBeInTheDocument()
    expect(screen.queryByText('Dashboard')).not.toBeInTheDocument()
  })

  it('unverified admin redirects to /admin-pin', () => {
    mockUseAuthStore.mockReturnValue({
      user: { id: 'user-1', email: 'admin@test.com' },
      role: 'superadmin',
      loading: false,
      adminVerified: false,
    })

    render(
      <MemoryRouter initialEntries={['/admin/dashboard']}>
        <Routes>
          <Route element={<AdminGuard />}>
            <Route path="/admin/dashboard" element={<div>Dashboard</div>} />
          </Route>
          <Route path="/admin-pin" element={<div>PIN Page</div>} />
        </Routes>
      </MemoryRouter>
    )

    expect(screen.getByText('PIN Page')).toBeInTheDocument()
    expect(screen.queryByText('Dashboard')).not.toBeInTheDocument()
  })

  it('verified admin can access protected route', () => {
    mockUseAuthStore.mockReturnValue({
      user: { id: 'user-1', email: 'admin@test.com' },
      role: 'superadmin',
      loading: false,
      adminVerified: true,
    })

    render(
      <MemoryRouter initialEntries={['/admin/dashboard']}>
        <Routes>
          <Route element={<AdminGuard />}>
            <Route path="/admin/dashboard" element={<div>Dashboard</div>} />
          </Route>
        </Routes>
      </MemoryRouter>
    )

    expect(screen.getByText('Dashboard')).toBeInTheDocument()
  })
})

describe('AccountGuard', () => {
  beforeEach(() => {
    vi.clearAllMocks()
  })

  it('authenticated user allowed', () => {
    mockUseAuthStore.mockReturnValue({
      user: { id: 'user-1', email: 'user@test.com' },
      role: 'user',
      loading: false,
    })

    render(
      <MemoryRouter initialEntries={['/account/dashboard']}>
        <Routes>
          <Route element={<AccountGuard />}>
            <Route path="/account/dashboard" element={<div>Account Dashboard</div>} />
          </Route>
        </Routes>
      </MemoryRouter>
    )

    expect(screen.getByText('Account Dashboard')).toBeInTheDocument()
  })

  it('unauthenticated redirects to /login', () => {
    mockUseAuthStore.mockReturnValue({
      user: null,
      role: null,
      loading: false,
    })

    render(
      <MemoryRouter initialEntries={['/account/dashboard']}>
        <Routes>
          <Route element={<AccountGuard />}>
            <Route path="/account/dashboard" element={<div>Account Dashboard</div>} />
          </Route>
          <Route path="/login" element={<div>Login Page</div>} />
        </Routes>
      </MemoryRouter>
    )

    expect(screen.getByText('Login Page')).toBeInTheDocument()
    expect(screen.queryByText('Account Dashboard')).not.toBeInTheDocument()
  })
})

describe('Public routes', () => {
  it('accessible without auth', () => {
    mockUseAuthStore.mockReturnValue({
      user: null,
      role: null,
      loading: false,
    })

    render(
      <MemoryRouter initialEntries={['/about']}>
        <Routes>
          <Route path="/about" element={<div>Public About Page</div>} />
        </Routes>
      </MemoryRouter>
    )

    expect(screen.getByText('Public About Page')).toBeInTheDocument()
  })
})
