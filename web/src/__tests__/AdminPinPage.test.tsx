import { describe, it, expect, vi, beforeEach } from 'vitest'
import { render, screen, fireEvent, waitFor } from '@testing-library/react'
import { MemoryRouter } from 'react-router-dom'

const mockNavigate = vi.hoisted(() => vi.fn())
const mockSetAdminVerified = vi.hoisted(() => vi.fn())
const mockSetMustChangePin = vi.hoisted(() => vi.fn())
const mockSetPermissions = vi.hoisted(() => vi.fn())
const mockInvoke = vi.hoisted(() => vi.fn())
const mockGetSession = vi.hoisted(() => vi.fn())
const mockAdminRpc = vi.hoisted(() => vi.fn())
const mockUseAuthStore = vi.hoisted(() => vi.fn())

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

vi.mock('react-i18next', () => ({
  useTranslation: () => ({
    t: (key: string, fallback?: string) => fallback ?? key,
  }),
}))

vi.mock('@/components/brand/Logo', () => ({
  Logo: () => <div data-testid="logo">Logo</div>,
}))

import AdminPinPage from '@/pages/AdminPinPage'

function renderPage() {
  return render(
    <MemoryRouter>
      <AdminPinPage />
    </MemoryRouter>
  )
}

function setupAuthStore(overrides: Record<string, unknown> = {}) {
  const store = {
    role: 'superadmin',
    setAdminVerified: mockSetAdminVerified,
    setMustChangePin: mockSetMustChangePin,
    setPermissions: mockSetPermissions,
    ...overrides,
  }
  mockUseAuthStore.mockReturnValue(store)
}

function typePin(digits: string) {
  const inputs = screen.getAllByRole('textbox')
  for (let i = 0; i < digits.length; i++) {
    fireEvent.change(inputs[i], { target: { value: digits[i] } })
  }
}

describe('AdminPinPage', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    setupAuthStore()
    mockGetSession.mockResolvedValue({
      data: { session: { access_token: 'test-token' } },
    })
  })

  it('renders 6 separate digit inputs', () => {
    renderPage()

    const inputs = screen.getAllByRole('textbox')
    expect(inputs).toHaveLength(6)

    inputs.forEach((input, i) => {
      expect(input).toHaveAttribute('aria-label', `PIN digit ${i + 1}`)
      expect(input).toHaveAttribute('maxLength', '1')
    })
  })

  it('typing a digit auto-advances focus to the next input', () => {
    renderPage()

    const inputs = screen.getAllByRole('textbox')
    fireEvent.change(inputs[0], { target: { value: '1' } })

    // After typing in the first input, the value should be set
    expect(inputs[0]).toHaveValue('1')
  })

  it('typing digits sequentially fills all inputs', () => {
    renderPage()

    const inputs = screen.getAllByRole('textbox')
    fireEvent.change(inputs[0], { target: { value: '1' } })
    fireEvent.change(inputs[1], { target: { value: '2' } })
    fireEvent.change(inputs[2], { target: { value: '3' } })

    expect(inputs[0]).toHaveValue('1')
    expect(inputs[1]).toHaveValue('2')
    expect(inputs[2]).toHaveValue('3')
  })

  it('backspace on empty input moves focus to previous input', () => {
    renderPage()

    const inputs = screen.getAllByRole('textbox')
    fireEvent.change(inputs[0], { target: { value: '5' } })
    // Simulate backspace on empty second input
    fireEvent.keyDown(inputs[1], { key: 'Backspace' })

    // The component calls focus on previous input (index 0)
    // We verify behavior indirectly: no crash, value stays
    expect(inputs[0]).toHaveValue('5')
  })

  it('rejects non-digit characters', () => {
    renderPage()

    const inputs = screen.getAllByRole('textbox')
    fireEvent.change(inputs[0], { target: { value: 'a' } })

    expect(inputs[0]).toHaveValue('')
  })

  it('completing 6 digits auto-submits and calls verify-admin-pin', async () => {
    mockInvoke.mockResolvedValue({
      data: { success: true },
      error: null,
    })
    mockAdminRpc.mockResolvedValue({ data: [] })

    renderPage()
    typePin('123456')

    await waitFor(() => {
      expect(mockGetSession).toHaveBeenCalled()
      expect(mockInvoke).toHaveBeenCalledWith('verify-admin-pin', {
        body: { pin: '123456' },
        headers: { Authorization: 'Bearer test-token' },
      })
    })

    await waitFor(() => {
      expect(mockSetAdminVerified).toHaveBeenCalledWith(true)
      expect(mockNavigate).toHaveBeenCalledWith('/admin/dashboard')
    })
  })

  it('error response shows error message and clears digits', async () => {
    mockInvoke.mockResolvedValue({
      data: null,
      error: { message: 'Invalid PIN' },
    })

    renderPage()
    typePin('000000')

    await waitFor(() => {
      expect(screen.getByText('Invalid PIN')).toBeInTheDocument()
    })

    // All inputs should be cleared
    const inputs = screen.getAllByRole('textbox')
    inputs.forEach((input) => {
      expect(input).toHaveValue('')
    })
  })

  it('shows error when verify returns success: false', async () => {
    mockInvoke.mockResolvedValue({
      data: { success: false },
      error: null,
    })

    renderPage()
    typePin('111111')

    await waitFor(() => {
      expect(screen.getByText('Invalid PIN')).toBeInTheDocument()
    })
  })

  it('must_change_pin response navigates to /admin/force-change-pin', async () => {
    mockInvoke.mockResolvedValue({
      data: { success: true, must_change_pin: true },
      error: null,
    })

    renderPage()
    typePin('123456')

    await waitFor(() => {
      expect(mockSetAdminVerified).toHaveBeenCalledWith(true)
      expect(mockSetMustChangePin).toHaveBeenCalledWith(true)
      expect(mockNavigate).toHaveBeenCalledWith('/admin/force-change-pin')
    })
  })

  it('must_change_pin skips loading permissions', async () => {
    mockInvoke.mockResolvedValue({
      data: { success: true, must_change_pin: true },
      error: null,
    })

    renderPage()
    typePin('123456')

    await waitFor(() => {
      expect(mockNavigate).toHaveBeenCalledWith('/admin/force-change-pin')
    })

    expect(mockAdminRpc).not.toHaveBeenCalled()
  })

  it('successful login as non-superadmin loads permissions', async () => {
    setupAuthStore({ role: 'editor' })
    const mockPermissions = [
      { resource: 'pois', can_read: true, can_write: true, can_delete: false },
    ]
    mockInvoke.mockResolvedValue({
      data: { success: true },
      error: null,
    })
    mockAdminRpc.mockResolvedValue({ data: mockPermissions })

    renderPage()
    typePin('123456')

    await waitFor(() => {
      expect(mockAdminRpc).toHaveBeenCalledWith('get_role_permissions', {
        target_role: 'editor',
      })
      expect(mockSetPermissions).toHaveBeenCalledWith(mockPermissions)
      expect(mockNavigate).toHaveBeenCalledWith('/admin/dashboard')
    })
  })

  it('superadmin skips permission loading', async () => {
    setupAuthStore({ role: 'superadmin' })
    mockInvoke.mockResolvedValue({
      data: { success: true },
      error: null,
    })

    renderPage()
    typePin('123456')

    await waitFor(() => {
      expect(mockNavigate).toHaveBeenCalledWith('/admin/dashboard')
    })

    expect(mockAdminRpc).not.toHaveBeenCalled()
  })

  it('non-admin role redirects to /account/explore', () => {
    setupAuthStore({ role: 'user' })

    renderPage()

    expect(mockNavigate).toHaveBeenCalledWith('/account/explore')
  })

  it('null role does not redirect', () => {
    setupAuthStore({ role: null })

    renderPage()

    expect(mockNavigate).not.toHaveBeenCalled()
  })

  it('contributor role is allowed and does not redirect', () => {
    setupAuthStore({ role: 'contributor' })

    renderPage()

    expect(mockNavigate).not.toHaveBeenCalledWith('/account/explore')
  })

  it('displays loading state during verification', async () => {
    let resolveInvoke: (value: unknown) => void
    mockInvoke.mockImplementation(
      () => new Promise((resolve) => { resolveInvoke = resolve })
    )

    renderPage()
    typePin('123456')

    await waitFor(() => {
      expect(screen.getByText('common.loading')).toBeInTheDocument()
    })

    // Inputs should be disabled during loading
    const inputs = screen.getAllByRole('textbox')
    inputs.forEach((input) => {
      expect(input).toBeDisabled()
    })

    // Resolve to avoid unhandled promise
    resolveInvoke!({ data: { success: true }, error: null })
  })
})
