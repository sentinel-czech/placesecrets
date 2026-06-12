import { describe, it, expect, vi, beforeEach } from 'vitest'
import { render, screen, waitFor, fireEvent } from '@testing-library/react'
import { MemoryRouter, Route, Routes } from 'react-router-dom'
import UserDetailPage from '@/pages/users/UserDetailPage'

const mockAdminSelect = vi.hoisted(() => vi.fn())
const mockAdminUpsert = vi.hoisted(() => vi.fn())
const mockAdminAuthGetUser = vi.hoisted(() => vi.fn())
const mockNavigate = vi.hoisted(() => vi.fn())
const mockUseAuthStore = vi.hoisted(() => vi.fn())
const mockToastSuccess = vi.hoisted(() => vi.fn())
const mockToastError = vi.hoisted(() => vi.fn())

vi.mock('@/lib/supabase/admin-api', () => ({
  adminSelect: mockAdminSelect,
  adminUpsert: mockAdminUpsert,
  adminAuthGetUser: mockAdminAuthGetUser,
}))

vi.mock('@/lib/supabase/client', () => ({
  supabase: {
    auth: { getSession: vi.fn().mockResolvedValue({ data: { session: null } }) },
    functions: { invoke: vi.fn().mockResolvedValue({ error: null }) },
  },
}))

vi.mock('@/hooks/useAuth', () => ({
  useAuthStore: mockUseAuthStore,
}))

vi.mock('react-i18next', () => ({
  useTranslation: () => ({
    t: (k: string) => {
      // If opts is an object with interpolation values, just return the key
      // (avoids React "objects are not valid as child" error)
      return k
    },
    i18n: { language: 'en', changeLanguage: vi.fn() },
  }),
}))

vi.mock('sonner', () => ({
  toast: {
    success: mockToastSuccess,
    error: mockToastError,
  },
}))

vi.mock('react-router-dom', async () => {
  const actual = await vi.importActual<typeof import('react-router-dom')>('react-router-dom')
  return {
    ...actual,
    useNavigate: () => mockNavigate,
  }
})

// Mock JSZip to avoid real zip generation
const mockJSZipFile = vi.hoisted(() => vi.fn())
const mockJSZipGenerateAsync = vi.hoisted(() => vi.fn().mockResolvedValue(new Blob(['test'])))
vi.mock('jszip', () => ({
  default: class MockJSZip {
    file = mockJSZipFile
    generateAsync = mockJSZipGenerateAsync
  },
}))

// Mock AccessGrantModal to simplify tests
vi.mock('@/components/users/AccessGrantModal', () => ({
  AccessGrantModal: () => null,
}))

const mockUser = {
  id: 'user-1',
  email: 'alice@example.com',
  is_anonymous: false,
  created_at: '2024-06-15T10:00:00Z',
  last_sign_in_at: '2024-12-01T14:30:00Z',
  email_confirmed_at: '2024-06-15T10:05:00Z',
  access_count: 3,
  total_spent: 29.97,
  status: 'active' as const,
  language: 'en',
  user_number: 100042,
  backup_email: 'backup@example.com',
  display_name: 'alice',
}

function setupAuthMock(canWrite = true, canDelete = false) {
  mockUseAuthStore.mockReturnValue({
    hasPermission: (resource: string, op: string) => {
      if (resource === 'users' && op === 'write') return canWrite
      if (resource === 'users' && op === 'delete') return canDelete
      if (resource === 'payments' && op === 'write') return false
      return true
    },
  })
}

function setupSelectMock(user: typeof mockUser | null = mockUser, error?: string) {
  mockAdminSelect.mockImplementation((table: string) => {
    if (table === 'admin_users_view') {
      if (error) return Promise.resolve({ data: null, error })
      return Promise.resolve({ data: user, error: null })
    }
    if (table === 'user_access') return Promise.resolve({ data: [], error: null })
    if (table === 'payment_receipts') return Promise.resolve({ data: [], error: null })
    if (table === 'user_poi_purchases') return Promise.resolve({ data: [], error: null })
    if (table === 'user_profiles') return Promise.resolve({ data: { language: 'en', status: 'active' }, error: null })
    return Promise.resolve({ data: null, error: null })
  })
}

function renderPage(userId = 'user-1') {
  return render(
    <MemoryRouter initialEntries={[`/admin/users/${userId}`]}>
      <Routes>
        <Route path="/admin/users/:id" element={<UserDetailPage />} />
        <Route path="/admin/users" element={<div>Users List</div>} />
      </Routes>
    </MemoryRouter>
  )
}

describe('UserDetailPage', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    setupAuthMock(true)
    // Mock URL.createObjectURL / revokeObjectURL for GDPR export
    global.URL.createObjectURL = vi.fn().mockReturnValue('blob:test')
    global.URL.revokeObjectURL = vi.fn()
  })

  it('loads user by ID on mount', async () => {
    setupSelectMock()
    renderPage('user-1')

    await waitFor(() => {
      expect(mockAdminSelect).toHaveBeenCalledWith('admin_users_view', {
        filters: [{ column: 'id', op: 'eq', value: 'user-1' }],
        single: true,
      })
    })
  })

  it('displays user info card with number, email, and handle', async () => {
    setupSelectMock()
    renderPage()

    await waitFor(() => {
      expect(screen.getByText('#100042')).toBeInTheDocument()
    })
    expect(screen.getByText('alice@example.com')).toBeInTheDocument()
    expect(screen.getByText('@alice')).toBeInTheDocument()
    expect(screen.getByText('backup@example.com')).toBeInTheDocument()
  })

  it('status toggle with ConfirmDialog calls adminUpsert', async () => {
    setupSelectMock()
    mockAdminUpsert.mockResolvedValue({ error: null })
    renderPage()

    await waitFor(() => {
      expect(screen.getByText('#100042')).toBeInTheDocument()
    })

    // The status card should show Active badge and Deactivate button
    expect(screen.getByText('admin.users.statusActive')).toBeInTheDocument()

    // Click the deactivate button (it is inside a ConfirmDialog trigger)
    const deactivateButton = screen.getByText('admin.users.deactivate')
    fireEvent.click(deactivateButton)

    // ConfirmDialog should appear with confirm button
    await waitFor(() => {
      expect(screen.getByText('common.confirm')).toBeInTheDocument()
    })

    // Click confirm
    fireEvent.click(screen.getByText('common.confirm'))

    await waitFor(() => {
      expect(mockAdminUpsert).toHaveBeenCalledWith(
        'user_profiles',
        { user_id: 'user-1', status: 'deactivated' },
        'user_id'
      )
    })

    expect(mockToastSuccess).toHaveBeenCalled()
  })

  it('GDPR export triggers download', async () => {
    setupSelectMock()
    mockAdminAuthGetUser.mockResolvedValue({
      data: { user: { id: 'user-1', email: 'alice@example.com', created_at: '2024-06-15' } },
      error: null,
    })
    renderPage()

    await waitFor(() => {
      expect(screen.getByText('#100042')).toBeInTheDocument()
    })

    // Find GDPR export button (there are two elements with this text: heading and button)
    const exportButtons = screen.getAllByText('admin.users.gdprExport')
    const exportButton = exportButtons.find(el => el.closest('button'))!
    fireEvent.click(exportButton.closest('button')!)

    await waitFor(() => {
      expect(mockAdminAuthGetUser).toHaveBeenCalledWith('user-1')
    })

    // JSZip should have been used to create a zip with profile.json and settings.json
    await waitFor(() => {
      expect(mockJSZipFile).toHaveBeenCalledWith('profile.json', expect.any(String))
      expect(mockJSZipFile).toHaveBeenCalledWith('settings.json', expect.any(String))
    })
  })

  it('back button navigates to /admin/users', async () => {
    setupSelectMock()
    renderPage()

    await waitFor(() => {
      expect(screen.getByText('#100042')).toBeInTheDocument()
    })

    const backButton = screen.getByText('admin.users.backToList')
    fireEvent.click(backButton)

    expect(mockNavigate).toHaveBeenCalledWith('/admin/users')
  })

  it('error state shows message', async () => {
    setupSelectMock(null)
    // Make the Promise.all reject
    mockAdminSelect.mockRejectedValue(new Error('Network failure'))
    renderPage()

    await waitFor(() => {
      expect(screen.getByText(/Network failure/)).toBeInTheDocument()
    })
  })
})
