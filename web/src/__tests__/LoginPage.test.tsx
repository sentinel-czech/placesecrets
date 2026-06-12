import { describe, it, expect, vi, beforeEach } from 'vitest'
import { render, screen, fireEvent, waitFor } from '@testing-library/react'
import { MemoryRouter } from 'react-router-dom'

const mockNavigate = vi.hoisted(() => vi.fn())
const mockSignIn = vi.hoisted(() => vi.fn())
const mockSignInWithOAuth = vi.hoisted(() => vi.fn())
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
    auth: { getSession: vi.fn().mockResolvedValue({ data: { session: null } }) },
    from: vi.fn(),
  },
}))

vi.mock('react-i18next', () => ({
  useTranslation: () => ({
    t: (k: string) => {
      const map: Record<string, string> = {
        'auth.signIn': 'Sign in',
        'auth.signingIn': 'Signing in...',
        'auth.signInToAccount': 'Sign in to your account',
        'auth.orSignInWithEmail': 'or sign in with email',
        'auth.invalidCredentials': 'Invalid email or password',
        'auth.noAccount': "Don't have an account?",
        'auth.createOne': 'Create one',
        'common.email': 'Email',
        'common.password': 'Password',
      }
      return map[k] || k
    },
    i18n: { language: 'en', changeLanguage: vi.fn() },
  }),
}))

vi.mock('@/components/auth/SocialAuthButtons', () => ({
  SocialAuthButtons: () => (
    <div>
      <button>Continue with Google</button>
      <button>Continue with Facebook</button>
      <button>Continue with Apple</button>
    </div>
  ),
}))

vi.mock('@/components/brand/Logo', () => ({
  Logo: () => <span>Logo</span>,
}))

import LoginPage from '@/pages/LoginPage'

function renderLoginPage() {
  return render(
    <MemoryRouter>
      <LoginPage />
    </MemoryRouter>
  )
}

describe('LoginPage', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    mockUseAuthStore.mockImplementation((selector: (s: Record<string, unknown>) => unknown) =>
      selector({ signIn: mockSignIn, signInWithOAuth: mockSignInWithOAuth })
    )
  })

  it('renders email and password inputs', () => {
    renderLoginPage()

    expect(screen.getByLabelText(/email/i)).toBeInTheDocument()
    expect(screen.getByLabelText(/password/i)).toBeInTheDocument()
  })

  it('renders sign in button', () => {
    renderLoginPage()

    expect(screen.getByRole('button', { name: /sign in/i })).toBeInTheDocument()
  })

  it('renders social login buttons', () => {
    renderLoginPage()

    expect(screen.getByText(/Continue with Google/i)).toBeInTheDocument()
    expect(screen.getByText(/Continue with Facebook/i)).toBeInTheDocument()
    expect(screen.getByText(/Continue with Apple/i)).toBeInTheDocument()
  })

  it('renders register link', () => {
    renderLoginPage()

    expect(screen.getByText(/Create one/i)).toBeInTheDocument()
  })

  it('shows error on invalid credentials', async () => {
    mockSignIn.mockRejectedValueOnce(new Error('Invalid credentials'))

    renderLoginPage()

    fireEvent.change(screen.getByLabelText(/email/i), {
      target: { value: 'bad@test.com' },
    })
    fireEvent.change(screen.getByLabelText(/password/i), {
      target: { value: 'wrong' },
    })
    fireEvent.click(screen.getByRole('button', { name: /sign in/i }))

    await waitFor(() => {
      expect(screen.getByText('Invalid email or password')).toBeInTheDocument()
    })
  })

  it('navigates to /account/explore for admin role', async () => {
    mockSignIn.mockResolvedValueOnce({ role: 'superadmin' })

    renderLoginPage()

    fireEvent.change(screen.getByLabelText(/email/i), {
      target: { value: 'admin@test.com' },
    })
    fireEvent.change(screen.getByLabelText(/password/i), {
      target: { value: 'password' },
    })
    fireEvent.click(screen.getByRole('button', { name: /sign in/i }))

    await waitFor(() => {
      expect(mockNavigate).toHaveBeenCalledWith('/account/explore')
    })
  })

  it('navigates to /contributor/dashboard for contributor role', async () => {
    mockSignIn.mockResolvedValueOnce({ role: 'contributor' })

    renderLoginPage()

    fireEvent.change(screen.getByLabelText(/email/i), {
      target: { value: 'contrib@test.com' },
    })
    fireEvent.change(screen.getByLabelText(/password/i), {
      target: { value: 'password' },
    })
    fireEvent.click(screen.getByRole('button', { name: /sign in/i }))

    await waitFor(() => {
      expect(mockNavigate).toHaveBeenCalledWith('/contributor/dashboard')
    })
  })

  it('navigates to /account/explore for regular user role', async () => {
    mockSignIn.mockResolvedValueOnce({ role: 'user' })

    renderLoginPage()

    fireEvent.change(screen.getByLabelText(/email/i), {
      target: { value: 'user@test.com' },
    })
    fireEvent.change(screen.getByLabelText(/password/i), {
      target: { value: 'password' },
    })
    fireEvent.click(screen.getByRole('button', { name: /sign in/i }))

    await waitFor(() => {
      expect(mockNavigate).toHaveBeenCalledWith('/account/explore')
    })
  })

  it('button is disabled while loading', async () => {
    mockSignIn.mockImplementation(() => new Promise(() => {}))

    renderLoginPage()

    fireEvent.change(screen.getByLabelText(/email/i), {
      target: { value: 'test@test.com' },
    })
    fireEvent.change(screen.getByLabelText(/password/i), {
      target: { value: 'password' },
    })

    const button = screen.getByRole('button', { name: /sign in/i })
    expect(button).not.toBeDisabled()

    fireEvent.click(button)

    await waitFor(() => {
      expect(screen.getByRole('button', { name: /signing in/i })).toBeDisabled()
    })
  })
})
