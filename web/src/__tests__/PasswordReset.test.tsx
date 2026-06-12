import { describe, it, expect, vi, beforeEach } from 'vitest'
import { render, screen, fireEvent, waitFor } from '@testing-library/react'
import { MemoryRouter } from 'react-router-dom'

const mockReset = vi.hoisted(() => vi.fn())
const mockUpdateUser = vi.hoisted(() => vi.fn())
const mockGetSession = vi.hoisted(() => vi.fn())
const mockOnAuthStateChange = vi.hoisted(() => vi.fn())
const mockSignOut = vi.hoisted(() => vi.fn())
const mockNavigate = vi.hoisted(() => vi.fn())

vi.mock('@/lib/supabase/client', () => ({
  supabase: {
    auth: {
      resetPasswordForEmail: mockReset,
      updateUser: mockUpdateUser,
      getSession: mockGetSession,
      onAuthStateChange: mockOnAuthStateChange,
      signOut: mockSignOut,
    },
  },
}))
vi.mock('react-i18next', () => ({
  useTranslation: () => ({ t: (k: string, d?: string) => d || k, i18n: { language: 'en' } }),
}))
vi.mock('sonner', () => ({ toast: { success: vi.fn(), error: vi.fn() } }))
vi.mock('react-router-dom', async () => {
  const actual = await vi.importActual<typeof import('react-router-dom')>('react-router-dom')
  return { ...actual, useNavigate: () => mockNavigate }
})

import ForgotPasswordPage from '@/pages/ForgotPasswordPage'
import ResetPasswordPage from '@/pages/ResetPasswordPage'

beforeEach(() => {
  vi.clearAllMocks()
  mockOnAuthStateChange.mockReturnValue({ data: { subscription: { unsubscribe: vi.fn() } } })
  mockGetSession.mockResolvedValue({ data: { session: { access_token: 't' } } })
})

describe('ForgotPasswordPage', () => {
  it('sends a reset link and shows confirmation', async () => {
    mockReset.mockResolvedValue({ error: null })
    render(<MemoryRouter><ForgotPasswordPage /></MemoryRouter>)
    fireEvent.change(screen.getByRole('textbox'), { target: { value: 'me@test.com' } })
    fireEvent.click(screen.getByRole('button', { name: /Send reset link/i }))
    expect(await screen.findByText(/we sent a reset link/i)).toBeInTheDocument()
    expect(mockReset).toHaveBeenCalledWith(
      'me@test.com',
      expect.objectContaining({ redirectTo: expect.stringContaining('/reset-password') })
    )
  })
})

describe('ResetPasswordPage', () => {
  it('updates the password and redirects to login', async () => {
    mockUpdateUser.mockResolvedValue({ error: null })
    mockSignOut.mockResolvedValue({ error: null })
    render(<MemoryRouter><ResetPasswordPage /></MemoryRouter>)

    const pw = await screen.findByLabelText(/New password/i)
    const cf = screen.getByLabelText(/Confirm password/i)
    fireEvent.change(pw, { target: { value: 'newpass12' } })
    fireEvent.change(cf, { target: { value: 'newpass12' } })

    const btn = screen.getByRole('button', { name: /Update password/i })
    await waitFor(() => expect(btn).not.toBeDisabled())
    fireEvent.click(btn)

    await waitFor(() => expect(mockUpdateUser).toHaveBeenCalledWith({ password: 'newpass12' }))
    await waitFor(() => expect(mockNavigate).toHaveBeenCalledWith('/login', { replace: true }))
  })

  it('rejects mismatched passwords without calling updateUser', async () => {
    render(<MemoryRouter><ResetPasswordPage /></MemoryRouter>)
    const pw = await screen.findByLabelText(/New password/i)
    const cf = screen.getByLabelText(/Confirm password/i)
    fireEvent.change(pw, { target: { value: 'newpass12' } })
    fireEvent.change(cf, { target: { value: 'different1' } })

    const btn = screen.getByRole('button', { name: /Update password/i })
    await waitFor(() => expect(btn).not.toBeDisabled())
    fireEvent.click(btn)

    expect(await screen.findByText(/do not match/i)).toBeInTheDocument()
    expect(mockUpdateUser).not.toHaveBeenCalled()
  })
})
