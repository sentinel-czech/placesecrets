import { describe, it, expect, vi, beforeEach } from 'vitest'
import { render, screen, fireEvent, waitFor, act } from '@testing-library/react'
import { MemoryRouter } from 'react-router-dom'

const mockNavigate = vi.hoisted(() => vi.fn())
const mockSignUp = vi.hoisted(() => vi.fn())
const mockRpc = vi.hoisted(() => vi.fn())
const mockUpsert = vi.hoisted(() => vi.fn())
const mockFrom = vi.hoisted(() => vi.fn())
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
    auth: {
      signUp: mockSignUp,
      getSession: vi.fn().mockResolvedValue({ data: { session: null } }),
    },
    rpc: mockRpc,
    from: mockFrom,
  },
}))

vi.mock('react-i18next', () => ({
  useTranslation: () => ({
    t: (key: string, opts?: Record<string, string>) => {
      if (opts) return `${key} ${JSON.stringify(opts)}`
      return key
    },
    i18n: { changeLanguage: vi.fn() },
  }),
}))

import RegisterPage from '@/pages/RegisterPage'

function renderRegisterPage() {
  return render(
    <MemoryRouter>
      <RegisterPage />
    </MemoryRouter>
  )
}

function fillForm(overrides: { email?: string; password?: string; confirm?: string } = {}) {
  const { email = 'test@example.com', password = 'password123', confirm } = overrides
  fireEvent.change(screen.getByLabelText(/email/i), { target: { value: email } })
  fireEvent.change(screen.getByLabelText('common.password'), { target: { value: password } })
  fireEvent.change(screen.getByLabelText('user.profile.confirmPassword'), {
    target: { value: confirm ?? password },
  })
  // Required consent checkbox (Terms + Privacy)
  fireEvent.click(screen.getByRole('checkbox'))
}

describe('RegisterPage', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    vi.useRealTimers()
    mockUseAuthStore.mockImplementation((selector: (s: Record<string, unknown>) => unknown) =>
      selector({})
    )
    mockFrom.mockReturnValue({ upsert: mockUpsert.mockResolvedValue({ error: null }) })
    mockRpc.mockResolvedValue({ data: true })
  })

  it('renders email, handle, password, and confirm-password fields', () => {
    renderRegisterPage()

    expect(screen.getByLabelText(/handle/i)).toBeInTheDocument()
    expect(screen.getByLabelText(/email/i)).toBeInTheDocument()
    expect(screen.getByLabelText('common.password')).toBeInTheDocument()
    expect(screen.getByLabelText('user.profile.confirmPassword')).toBeInTheDocument()
  })

  it('shows @ prefix on handle field', () => {
    renderRegisterPage()

    expect(screen.getByText('@')).toBeInTheDocument()
  })

  describe('handle validation', () => {
    it('rejects uppercase characters (input lowercases automatically)', () => {
      renderRegisterPage()

      const handleInput = screen.getByLabelText(/handle/i)
      fireEvent.change(handleInput, { target: { value: 'ABCdef' } })

      expect(handleInput).toHaveValue('abcdef')
    })

    it('rejects special characters (input strips them)', () => {
      renderRegisterPage()

      const handleInput = screen.getByLabelText(/handle/i)
      fireEvent.change(handleInput, { target: { value: 'he!!o@#' } })

      expect(handleInput).toHaveValue('heo')
    })

    it('shows error for handle shorter than 3 characters', async () => {
      renderRegisterPage()

      const handleInput = screen.getByLabelText(/handle/i)
      fireEvent.change(handleInput, { target: { value: 'ab' } })

      await waitFor(() => {
        expect(screen.getByText('handle.invalid')).toBeInTheDocument()
      })
    })
  })

  describe('handle availability check', () => {
    it('calls check_handle_available RPC after debounce', async () => {
      vi.useFakeTimers()
      mockRpc.mockResolvedValue({ data: true })

      renderRegisterPage()

      const handleInput = screen.getByLabelText(/handle/i)
      fireEvent.change(handleInput, { target: { value: 'validhandle' } })

      expect(mockRpc).not.toHaveBeenCalled()

      await vi.advanceTimersByTimeAsync(400)

      expect(mockRpc).toHaveBeenCalledWith('check_handle_available', { p_handle: 'validhandle' })

      vi.useRealTimers()
    })

    it('shows error when handle is taken', async () => {
      vi.useFakeTimers()
      mockRpc.mockResolvedValue({ data: false })

      renderRegisterPage()

      const handleInput = screen.getByLabelText(/handle/i)
      fireEvent.change(handleInput, { target: { value: 'takenhandle' } })

      // Advance past debounce and flush all pending microtasks
      await vi.advanceTimersByTimeAsync(500)

      vi.useRealTimers()

      await waitFor(() => {
        expect(screen.getByText('handle.taken')).toBeInTheDocument()
      })
    })

    it('clears error when handle becomes available', async () => {
      vi.useFakeTimers()
      mockRpc.mockResolvedValueOnce({ data: false }).mockResolvedValueOnce({ data: true })

      renderRegisterPage()

      const handleInput = screen.getByLabelText(/handle/i)
      fireEvent.change(handleInput, { target: { value: 'taken' } })

      await vi.advanceTimersByTimeAsync(500)

      vi.useRealTimers()

      await waitFor(() => {
        expect(screen.getByText('handle.taken')).toBeInTheDocument()
      })

      vi.useFakeTimers()

      fireEvent.change(handleInput, { target: { value: 'available' } })

      await vi.advanceTimersByTimeAsync(500)

      vi.useRealTimers()

      await waitFor(() => {
        expect(screen.queryByText('handle.taken')).not.toBeInTheDocument()
      })
    })
  })

  it('shows error when passwords do not match', async () => {
    renderRegisterPage()

    fillForm({ password: 'password123', confirm: 'different123' })
    fireEvent.click(screen.getByRole('button', { name: /register/i }))

    await waitFor(() => {
      expect(screen.getByText('user.profile.passwordMismatch')).toBeInTheDocument()
    })
  })

  it('shows error when password is too short', async () => {
    renderRegisterPage()

    fillForm({ password: '12345', confirm: '12345' })
    fireEvent.click(screen.getByRole('button', { name: /register/i }))

    await waitFor(() => {
      expect(screen.getByText('user.profile.passwordTooShort')).toBeInTheDocument()
    })
  })

  it('shows confirmation screen on successful signup', async () => {
    mockSignUp.mockResolvedValue({
      data: { user: { id: 'user-123' } },
      error: null,
    })

    renderRegisterPage()

    fillForm({ email: 'new@example.com' })
    fireEvent.click(screen.getByRole('button', { name: /register/i }))

    await waitFor(() => {
      expect(screen.getByText('handle.checkEmail')).toBeInTheDocument()
    })
  })

  it('calls supabase.auth.signUp with correct email and password', async () => {
    mockSignUp.mockResolvedValue({
      data: { user: { id: 'user-456' } },
      error: null,
    })

    renderRegisterPage()

    fillForm({ email: 'signup@example.com', password: 'secure123' })
    fireEvent.click(screen.getByRole('button', { name: /register/i }))

    await waitFor(() => {
      expect(mockSignUp).toHaveBeenCalledWith({
        email: 'signup@example.com',
        password: 'secure123',
      })
    })
  })

  it('upserts user_profiles with handle as display_name when handle is provided', async () => {
    vi.useFakeTimers()
    mockRpc.mockResolvedValue({ data: true })
    mockSignUp.mockResolvedValue({
      data: { user: { id: 'user-789' } },
      error: null,
    })

    renderRegisterPage()

    const handleInput = screen.getByLabelText(/handle/i)
    fireEvent.change(handleInput, { target: { value: 'myhandle' } })

    // Wait for debounce to resolve handle check
    await vi.advanceTimersByTimeAsync(500)

    fillForm({ email: 'handle@example.com' })

    // Submit and flush all async work
    await act(async () => {
      fireEvent.click(screen.getByRole('button', { name: /register/i }))
      await vi.advanceTimersByTimeAsync(100)
    })

    vi.useRealTimers()

    await waitFor(() => {
      expect(mockFrom).toHaveBeenCalledWith('user_profiles')
      expect(mockUpsert).toHaveBeenCalledWith(
        expect.objectContaining({
          user_id: 'user-789',
          display_name: 'myhandle',
          terms_accepted_at: expect.any(String),
          privacy_accepted_at: expect.any(String),
        }),
        { onConflict: 'user_id' }
      )
    })
  })

  it('renders link to login page', () => {
    renderRegisterPage()

    const loginLink = screen.getByText('handle.signIn')
    expect(loginLink).toBeInTheDocument()
    expect(loginLink.closest('a')).toHaveAttribute('href', '/login')
  })

  it('shows confirmation screen with back-to-login link after signup', async () => {
    mockSignUp.mockResolvedValue({
      data: { user: { id: 'user-abc' } },
      error: null,
    })

    renderRegisterPage()

    fillForm({ email: 'done@example.com' })
    fireEvent.click(screen.getByRole('button', { name: /register/i }))

    await waitFor(() => {
      expect(screen.getByText('handle.checkEmail')).toBeInTheDocument()
      expect(screen.getByText('handle.backToLogin')).toBeInTheDocument()
    })
  })

  it('shows error message when signUp fails', async () => {
    mockSignUp.mockResolvedValue({
      data: { user: null },
      error: new Error('Email already registered'),
    })

    renderRegisterPage()

    fillForm({ email: 'exists@example.com' })
    fireEvent.click(screen.getByRole('button', { name: /register/i }))

    await waitFor(() => {
      expect(screen.getByText('Email already registered')).toBeInTheDocument()
    })
  })

  it('disables submit button when handle has an error', async () => {
    vi.useFakeTimers()
    mockRpc.mockResolvedValue({ data: false })

    renderRegisterPage()

    fireEvent.change(screen.getByLabelText(/handle/i), { target: { value: 'takenone' } })

    await vi.advanceTimersByTimeAsync(500)

    vi.useRealTimers()

    await waitFor(() => {
      expect(screen.getByText('handle.taken')).toBeInTheDocument()
    })

    const button = screen.getByRole('button', { name: /register/i })
    expect(button).toBeDisabled()
  })
})
