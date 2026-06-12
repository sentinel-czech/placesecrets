import { describe, it, expect, vi, beforeEach } from 'vitest'
import { render, screen, waitFor, fireEvent } from '@testing-library/react'
import { ChangePinForm } from '@/components/settings/ChangePinForm'

const mockInvoke = vi.hoisted(() => vi.fn())
const mockGetSession = vi.hoisted(() => vi.fn())
const mockToastSuccess = vi.hoisted(() => vi.fn())
const mockToastError = vi.hoisted(() => vi.fn())

vi.mock('@/lib/supabase/client', () => ({
  supabase: {
    auth: { getSession: mockGetSession },
    functions: { invoke: mockInvoke },
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

describe('ChangePinForm', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    mockGetSession.mockResolvedValue({
      data: { session: { access_token: 'test-token' } },
    })
  })

  it('renders current PIN and new PIN inputs', () => {
    render(<ChangePinForm />)

    expect(screen.getByText('settings.currentPin')).toBeInTheDocument()
    expect(screen.getByText('settings.newPin')).toBeInTheDocument()

    const passwordInputs = screen.getAllByDisplayValue('')
    expect(passwordInputs.length).toBeGreaterThanOrEqual(2)
  })

  it('submit calls change-admin-pin edge function', async () => {
    mockInvoke.mockResolvedValue({ data: { success: true }, error: null })
    render(<ChangePinForm />)

    const passwordInputs = document.querySelectorAll('input[type="password"]')
    fireEvent.change(passwordInputs[0], { target: { value: '1234' } })
    fireEvent.change(passwordInputs[1], { target: { value: '5678' } })

    const submitButton = screen.getByRole('button', { name: /settings\.changePin/i })
    fireEvent.click(submitButton)

    await waitFor(() => {
      expect(mockInvoke).toHaveBeenCalledWith('change-admin-pin', {
        body: { current_pin: '1234', new_pin: '5678' },
        headers: { Authorization: 'Bearer test-token' },
      })
    })
  })

  it('empty new PIN shows error toast', async () => {
    render(<ChangePinForm />)

    // Leave new PIN empty, submit the form
    const submitButton = screen.getByRole('button', { name: /settings\.changePin/i })
    fireEvent.click(submitButton)

    await waitFor(() => {
      expect(mockToastError).toHaveBeenCalledWith('settings.newPinRequired')
    })

    // Edge function should not be called
    expect(mockInvoke).not.toHaveBeenCalled()
  })

  it('success shows toast and clears inputs', async () => {
    mockInvoke.mockResolvedValue({ data: { success: true }, error: null })
    render(<ChangePinForm />)

    const passwordInputs = document.querySelectorAll('input[type="password"]')
    fireEvent.change(passwordInputs[0], { target: { value: '1234' } })
    fireEvent.change(passwordInputs[1], { target: { value: '5678' } })

    const submitButton = screen.getByRole('button', { name: /settings\.changePin/i })
    fireEvent.click(submitButton)

    await waitFor(() => {
      expect(mockToastSuccess).toHaveBeenCalledWith('settings.pinChanged')
    })

    // Inputs should be cleared
    expect((passwordInputs[0] as HTMLInputElement).value).toBe('')
    expect((passwordInputs[1] as HTMLInputElement).value).toBe('')
  })
})
