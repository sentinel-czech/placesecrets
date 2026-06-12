import { describe, it, expect, vi, beforeEach } from 'vitest'
import { render, screen, waitFor, fireEvent } from '@testing-library/react'
import { MemoryRouter, Route, Routes } from 'react-router-dom'
import UsersPage from '@/pages/users/UsersPage'

const mockAdminSelect = vi.hoisted(() => vi.fn())
const mockAdminInsert = vi.hoisted(() => vi.fn())
const mockAdminAuthCreateUser = vi.hoisted(() => vi.fn())
const mockUseAuthStore = vi.hoisted(() => vi.fn())
const mockToastSuccess = vi.hoisted(() => vi.fn())
const mockToastError = vi.hoisted(() => vi.fn())

vi.mock('@/lib/supabase/admin-api', () => ({
  adminSelect: mockAdminSelect,
  adminInsert: mockAdminInsert,
  adminAuthCreateUser: mockAdminAuthCreateUser,
}))

vi.mock('@/lib/supabase/client', () => ({
  supabase: {
    auth: { getSession: vi.fn().mockResolvedValue({ data: { session: null } }) },
    from: vi.fn(),
    rpc: vi.fn(),
  },
}))

vi.mock('@/hooks/useAuth', () => ({
  useAuthStore: mockUseAuthStore,
}))

vi.mock('react-i18next', () => ({
  useTranslation: () => ({
    t: (k: string, d?: string) => d || k,
    i18n: { language: 'en', changeLanguage: vi.fn() },
  }),
}))

vi.mock('sonner', () => ({
  toast: {
    success: mockToastSuccess,
    error: mockToastError,
  },
}))

function makeUser(overrides: Record<string, unknown> = {}) {
  return {
    id: 'user-1',
    email: 'alice@example.com',
    is_anonymous: false,
    created_at: '2024-06-15T10:00:00Z',
    last_sign_in_at: '2024-12-01T14:30:00Z',
    email_confirmed_at: '2024-06-15T10:05:00Z',
    access_count: 3,
    total_spent: 29.97,
    status: 'active',
    language: 'en',
    user_number: 100042,
    backup_email: null,
    display_name: 'alice',
    ...overrides,
  }
}

function setupAuthMock(canWrite = true) {
  mockUseAuthStore.mockReturnValue({
    hasPermission: (resource: string, op: string) => {
      if (resource === 'users' && op === 'write') return canWrite
      return true
    },
  })
}

function setupSelectMock(users = [makeUser()]) {
  mockAdminSelect.mockResolvedValue({ data: users, error: null })
}

function renderPage() {
  return render(
    <MemoryRouter initialEntries={['/admin/users']}>
      <Routes>
        <Route path="/admin/users" element={<UsersPage />} />
        <Route path="/admin/users/:id" element={<div>User Detail</div>} />
      </Routes>
    </MemoryRouter>
  )
}

describe('UsersPage', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    setupAuthMock(true)
  })

  it('loads users via adminSelect on mount', async () => {
    setupSelectMock()
    renderPage()

    await waitFor(() => {
      expect(mockAdminSelect).toHaveBeenCalledWith('admin_users_view', {
        order: { column: 'created_at', ascending: false },
      })
    })
  })

  it('DataTable renders user_number, handle, email, type, status columns', async () => {
    setupSelectMock([
      makeUser({ user_number: 100042, display_name: 'alice', email: 'alice@example.com' }),
    ])
    renderPage()

    await waitFor(() => {
      expect(screen.getByText('#100042')).toBeInTheDocument()
    })
    expect(screen.getByText('@alice')).toBeInTheDocument()
    expect(screen.getByText('alice@example.com')).toBeInTheDocument()
    // Type column shows Registered badge (via translation key)
    expect(screen.getByText('admin.users.registeredType')).toBeInTheDocument()
    // Status column shows Active badge
    expect(screen.getByText('admin.users.statusActive')).toBeInTheDocument()
  })

  it('Add User button opens dialog when hasPermission is true', async () => {
    setupSelectMock()
    renderPage()

    await waitFor(() => {
      expect(screen.getByText('alice@example.com')).toBeInTheDocument()
    })

    const addButton = screen.getByText('admin.users.addUser')
    fireEvent.click(addButton)

    await waitFor(() => {
      // Dialog should show email input placeholder
      expect(screen.getByPlaceholderText('user@example.com')).toBeInTheDocument()
    })
  })

  it('Add User dialog submit creates user via adminAuthCreateUser', async () => {
    setupSelectMock()
    mockAdminAuthCreateUser.mockResolvedValue({
      data: { user: { id: 'new-user-id' } },
      error: null,
    })
    mockAdminInsert.mockResolvedValue({ error: null })
    // After creation, loadUsers is called again
    mockAdminSelect.mockResolvedValue({ data: [makeUser()], error: null })

    renderPage()

    await waitFor(() => {
      expect(screen.getByText('alice@example.com')).toBeInTheDocument()
    })

    // Open dialog
    fireEvent.click(screen.getByText('admin.users.addUser'))

    await waitFor(() => {
      expect(screen.getByPlaceholderText('user@example.com')).toBeInTheDocument()
    })

    // Fill email
    fireEvent.change(screen.getByPlaceholderText('user@example.com'), {
      target: { value: 'newuser@example.com' },
    })

    // Select editor role
    fireEvent.change(screen.getByLabelText('Select role'), {
      target: { value: 'editor' },
    })

    // Submit - click the "common.add" button (last button in footer)
    const addButtons = screen.getAllByText('common.add')
    fireEvent.click(addButtons[addButtons.length - 1])

    await waitFor(() => {
      expect(mockAdminAuthCreateUser).toHaveBeenCalledWith(
        expect.objectContaining({
          email: 'newuser@example.com',
          email_confirm: true,
        })
      )
    })

    // For non-user role, adminInsert should be called for admin_users
    await waitFor(() => {
      expect(mockAdminInsert).toHaveBeenCalledWith('admin_users', {
        user_id: 'new-user-id',
        role: 'editor',
        must_change_pin: true,
      })
    })

    expect(mockToastSuccess).toHaveBeenCalled()
  })

  it('detail link navigates to /admin/users/:id', async () => {
    setupSelectMock([makeUser({ id: 'user-abc' })])
    renderPage()

    await waitFor(() => {
      expect(screen.getByText('alice@example.com')).toBeInTheDocument()
    })

    const detailButton = screen.getByText('admin.users.detail')
    const detailLink = detailButton.closest('a')
    expect(detailLink).toHaveAttribute('href', '/admin/users/user-abc')
  })

  it('permission gating: canWrite=false hides Add button', async () => {
    setupAuthMock(false)
    setupSelectMock()
    renderPage()

    await waitFor(() => {
      expect(screen.getByText('alice@example.com')).toBeInTheDocument()
    })

    expect(screen.queryByText('admin.users.addUser')).not.toBeInTheDocument()
  })
})
