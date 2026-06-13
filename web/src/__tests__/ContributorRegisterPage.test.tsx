import { describe, it, expect, vi, beforeEach } from 'vitest'
import { render, screen, fireEvent, waitFor } from '@testing-library/react'
import { MemoryRouter } from 'react-router-dom'

const mockSignUp = vi.hoisted(() => vi.fn())
const mockUpsert = vi.hoisted(() => vi.fn())
const mockInsert = vi.hoisted(() => vi.fn())
const mockRpc = vi.hoisted(() => vi.fn())

vi.mock('@/lib/supabase/client', () => ({
  supabase: {
    auth: {
      signUp: mockSignUp,
      getSession: vi.fn().mockResolvedValue({ data: { session: null } }),
    },
    from: vi.fn((table: string) => {
      if (table === 'user_profiles') return { upsert: mockUpsert }
      if (table === 'contributor_profiles') return { insert: mockInsert }
      return { upsert: vi.fn(), insert: vi.fn() }
    }),
    rpc: mockRpc,
  },
}))

vi.mock('react-i18next', () => ({
  useTranslation: () => ({
    t: (key: string, fallback?: string) => fallback ?? key,
    i18n: { changeLanguage: vi.fn() },
  }),
}))

import ContributorRegisterPage from '@/pages/register/ContributorRegisterPage'

function renderPage() {
  return render(
    <MemoryRouter>
      <ContributorRegisterPage />
    </MemoryRouter>
  )
}

describe('ContributorRegisterPage', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    // Default: handle is available
    mockRpc.mockResolvedValue({ data: true })
    mockUpsert.mockResolvedValue({ error: null })
    mockInsert.mockResolvedValue({ error: null })
  })

  it('renders handle, email, and password fields', () => {
    renderPage()

    expect(screen.getByText('handle.handle')).toBeInTheDocument()
    expect(screen.getByText('common.email')).toBeInTheDocument()
    expect(screen.getByText('common.password')).toBeInTheDocument()
  })

  it('shows default PIN info (123456) on success screen', async () => {
    mockSignUp.mockResolvedValueOnce({
      data: { user: { id: 'user-123' } },
      error: null,
    })

    renderPage()

    fireEvent.change(screen.getByPlaceholderText('handle.placeholder'), {
      target: { value: 'testuser' },
    })

    // Wait for handle check debounce to settle
    await waitFor(() => {
      expect(mockRpc).toHaveBeenCalledWith('check_handle_available', { p_handle: 'testuser' })
    })

    const emailInput = document.querySelector('input[type="email"]') as HTMLInputElement
    fireEvent.change(emailInput, {
      target: { value: 'test@example.com' },
    })

    // Password inputs don't have a textbox role; select by type
    const passwordInput = document.querySelector('input[type="password"][minlength="8"]') as HTMLInputElement
    fireEvent.change(passwordInput, {
      target: { value: 'securepass123' },
    })
    fireEvent.click(screen.getByRole('checkbox'))
    fireEvent.click(screen.getByRole('button', { name: 'handle.register' }))

    await waitFor(() => {
      expect(screen.getByText('123456')).toBeInTheDocument()
    })
  })

  it('successful registration shows success screen with login link', async () => {
    mockSignUp.mockResolvedValueOnce({
      data: { user: { id: 'user-456' } },
      error: null,
    })

    renderPage()

    fireEvent.change(screen.getByPlaceholderText('handle.placeholder'), {
      target: { value: 'newcontrib' },
    })

    await waitFor(() => {
      expect(mockRpc).toHaveBeenCalledWith('check_handle_available', { p_handle: 'newcontrib' })
    })

    const emailInput = document.querySelector('input[type="email"]') as HTMLInputElement
    fireEvent.change(emailInput, {
      target: { value: 'contrib@example.com' },
    })

    const passwordInput = document.querySelector('input[type="password"][minlength="8"]') as HTMLInputElement
    fireEvent.change(passwordInput, {
      target: { value: 'password123' },
    })
    fireEvent.click(screen.getByRole('checkbox'))
    fireEvent.click(screen.getByRole('button', { name: 'handle.register' }))

    await waitFor(() => {
      expect(screen.getByText('common.success')).toBeInTheDocument()
    })

    // Verify signUp was called with correct credentials
    expect(mockSignUp).toHaveBeenCalledWith({
      email: 'contrib@example.com',
      password: 'password123',
    })

    // Verify login link exists
    const loginLink = screen.getByRole('link', { name: /sign in to admin panel/i })
    expect(loginLink).toHaveAttribute('href', '/login')
  })
})
