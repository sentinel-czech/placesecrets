import { describe, it, expect, vi, beforeEach } from 'vitest'
import { render, screen, waitFor, fireEvent } from '@testing-library/react'
import { InviteAdminForm } from '@/components/settings/InviteAdminForm'

const mockAdminAuthListUsers = vi.hoisted(() => vi.fn())
const mockAdminAuthCreateUser = vi.hoisted(() => vi.fn())
const mockAdminUpsert = vi.hoisted(() => vi.fn())
const mockToastSuccess = vi.hoisted(() => vi.fn())
const mockToastError = vi.hoisted(() => vi.fn())

vi.mock('@/lib/supabase/admin-api', () => ({
  adminSelect: vi.fn(),
  adminUpdate: vi.fn(),
  adminRpc: vi.fn(),
  adminUpsert: mockAdminUpsert,
  adminDelete: vi.fn(),
  adminAuthCreateUser: mockAdminAuthCreateUser,
  adminAuthGetUser: vi.fn(),
  adminAuthListUsers: mockAdminAuthListUsers,
}))

vi.mock('@/lib/supabase/client', () => ({
  supabase: {
    auth: { getSession: vi.fn().mockResolvedValue({ data: { session: { access_token: 'test' } } }) },
    functions: { invoke: vi.fn() },
  },
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
    info: vi.fn(),
  },
}))

describe('InviteAdminForm', () => {
  const mockOnInvited = vi.fn()

  beforeEach(() => {
    vi.clearAllMocks()
  })

  it('renders email and role fields', () => {
    render(<InviteAdminForm onInvited={mockOnInvited} />)

    expect(screen.getByPlaceholderText('user@example.com')).toBeInTheDocument()
    expect(screen.getByLabelText('User role')).toBeInTheDocument()

    // Verify role options
    const roleSelect = screen.getByLabelText('User role') as HTMLSelectElement
    const options = Array.from(roleSelect.options).map(o => o.value)
    expect(options).toContain('editor')
    expect(options).toContain('viewer')
    expect(options).toContain('contributor')
  })

  it('submit creates user via adminAuthCreateUser + adminUpsert', async () => {
    // No existing user found
    mockAdminAuthListUsers.mockResolvedValue({
      data: { users: [] },
      error: null,
    })
    // Create new user
    mockAdminAuthCreateUser.mockResolvedValue({
      data: { user: { id: 'new-user-id', email: 'test@example.com' } },
      error: null,
    })
    // Upsert admin record
    mockAdminUpsert.mockResolvedValue({ error: null })

    render(<InviteAdminForm onInvited={mockOnInvited} />)

    const emailInput = screen.getByPlaceholderText('user@example.com')
    fireEvent.change(emailInput, { target: { value: 'test@example.com' } })

    const submitButton = screen.getByRole('button', { name: /Add User/i })
    fireEvent.click(submitButton)

    await waitFor(() => {
      expect(mockAdminAuthListUsers).toHaveBeenCalled()
    })

    await waitFor(() => {
      expect(mockAdminAuthCreateUser).toHaveBeenCalledWith({
        email: 'test@example.com',
        email_confirm: true,
        password: expect.any(String),
      })
    })

    await waitFor(() => {
      expect(mockAdminUpsert).toHaveBeenCalledWith(
        'admin_users',
        { user_id: 'new-user-id', role: 'editor', must_change_pin: true },
        'user_id'
      )
    })
  })

  it('success calls onInvited callback', async () => {
    mockAdminAuthListUsers.mockResolvedValue({
      data: { users: [] },
      error: null,
    })
    mockAdminAuthCreateUser.mockResolvedValue({
      data: { user: { id: 'new-user-id', email: 'test@example.com' } },
      error: null,
    })
    mockAdminUpsert.mockResolvedValue({ error: null })

    render(<InviteAdminForm onInvited={mockOnInvited} />)

    const emailInput = screen.getByPlaceholderText('user@example.com')
    fireEvent.change(emailInput, { target: { value: 'test@example.com' } })

    const submitButton = screen.getByRole('button', { name: /Add User/i })
    fireEvent.click(submitButton)

    await waitFor(() => {
      expect(mockOnInvited).toHaveBeenCalled()
    })

    expect(mockToastSuccess).toHaveBeenCalled()

    // Email field should be cleared
    expect((emailInput as HTMLInputElement).value).toBe('')
  })
})
