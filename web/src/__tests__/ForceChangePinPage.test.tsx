import { describe, it, expect, vi, beforeEach } from 'vitest'
import { render, screen, fireEvent, waitFor } from '@testing-library/react'
import { MemoryRouter } from 'react-router-dom'

const mockNavigate = vi.hoisted(() => vi.fn())
const mockSetMustChangePin = vi.hoisted(() => vi.fn())
const mockSetPermissions = vi.hoisted(() => vi.fn())
const mockUseAuthStore = vi.hoisted(() => vi.fn())
const mockInvoke = vi.hoisted(() => vi.fn())
const mockAdminRpc = vi.hoisted(() => vi.fn())
const mockGetSession = vi.hoisted(() => vi.fn())

vi.mock('react-router-dom', async () => {
  const actual = await vi.importActual<typeof import('react-router-dom')>('react-router-dom')
  return { ...actual, useNavigate: () => mockNavigate }
})

vi.mock('@/hooks/useAuth', () => ({
  useAuthStore: mockUseAuthStore,
}))

vi.mock('@/lib/supabase/client', () => ({
  supabase: {
    auth: { getSession: mockGetSession },
    functions: { invoke: mockInvoke },
  },
}))

vi.mock('@/lib/supabase/admin-api', () => ({
  adminRpc: mockAdminRpc,
}))

vi.mock('sonner', () => ({
  toast: { success: vi.fn(), error: vi.fn() },
}))

vi.mock('react-i18next', () => ({
  useTranslation: () => ({
    t: (key: string) => key,
    i18n: { changeLanguage: vi.fn() },
  }),
}))

import ForceChangePinPage from '@/pages/ForceChangePinPage'

function renderPage() {
  return render(
    <MemoryRouter>
      <ForceChangePinPage />
    </MemoryRouter>
  )
}

function setupAuthStore(overrides: Record<string, unknown> = {}) {
  const defaults = {
    mustChangePin: true,
    setMustChangePin: mockSetMustChangePin,
    setPermissions: mockSetPermissions,
    role: 'contributor',
  }
  const state = { ...defaults, ...overrides }
  mockUseAuthStore.mockImplementation((selector?: (s: Record<string, unknown>) => unknown) => {
    if (typeof selector === 'function') return selector(state)
    return state
  })
}

describe('ForceChangePinPage', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    mockGetSession.mockResolvedValue({ data: { session: { access_token: 'test-token' } } })
  })

  it('renders new PIN input when mustChangePin is true', () => {
    setupAuthStore({ mustChangePin: true })
    renderPage()

    expect(screen.getByPlaceholderText('******')).toBeInTheDocument()
    expect(screen.getByText('admin.forceChangePin.title')).toBeInTheDocument()
    expect(screen.getByText('admin.forceChangePin.description')).toBeInTheDocument()
    expect(screen.getByRole('button', { name: 'admin.forceChangePin.submit' })).toBeInTheDocument()
  })

  it('successful PIN change navigates to /admin/dashboard', async () => {
    setupAuthStore({ mustChangePin: true, role: 'contributor' })
    mockInvoke.mockResolvedValueOnce({ data: { success: true }, error: null })
    mockAdminRpc.mockResolvedValueOnce({ data: [{ resource: 'pois', can_read: true, can_write: true, can_delete: false }] })

    renderPage()

    fireEvent.change(screen.getByPlaceholderText('******'), {
      target: { value: '654321' },
    })
    fireEvent.click(screen.getByRole('button', { name: 'admin.forceChangePin.submit' }))

    await waitFor(() => {
      expect(mockInvoke).toHaveBeenCalledWith('change-admin-pin', {
        body: { new_pin: '654321' },
        headers: { Authorization: 'Bearer test-token' },
      })
    })

    await waitFor(() => {
      expect(mockSetMustChangePin).toHaveBeenCalledWith(false)
      expect(mockAdminRpc).toHaveBeenCalledWith('get_role_permissions', { target_role: 'contributor' })
      expect(mockSetPermissions).toHaveBeenCalled()
      expect(mockNavigate).toHaveBeenCalledWith('/admin/dashboard', { replace: true })
    })
  })

  it('redirects to dashboard if not in mustChangePin state', () => {
    setupAuthStore({ mustChangePin: false })
    renderPage()

    expect(mockNavigate).toHaveBeenCalledWith('/admin/dashboard', { replace: true })
  })
})
