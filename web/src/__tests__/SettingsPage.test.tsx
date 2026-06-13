import { describe, it, expect, vi, beforeEach } from 'vitest'
import { render, screen, waitFor, fireEvent } from '@testing-library/react'
import SettingsPage from '@/pages/SettingsPage'

const mockAdminSelect = vi.hoisted(() => vi.fn())
const mockAdminUpdate = vi.hoisted(() => vi.fn())
const mockToastSuccess = vi.hoisted(() => vi.fn())
const mockToastError = vi.hoisted(() => vi.fn())
const mockHasPermission = vi.hoisted(() => vi.fn())

vi.mock('@/lib/supabase/admin-api', () => ({
  adminSelect: mockAdminSelect,
  adminUpdate: mockAdminUpdate,
  adminRpc: vi.fn(),
  adminUpsert: vi.fn(),
  adminDelete: vi.fn(),
  adminAuthCreateUser: vi.fn(),
  adminAuthGetUser: vi.fn().mockResolvedValue({ data: null, error: null }),
  adminAuthListUsers: vi.fn(),
}))

vi.mock('@/lib/supabase/client', () => ({
  supabase: {
    auth: { getSession: vi.fn().mockResolvedValue({ data: { session: { access_token: 'test' } } }) },
    functions: { invoke: vi.fn() },
  },
}))

vi.mock('@/hooks/useAuth', () => ({
  useAuthStore: () => ({ hasPermission: mockHasPermission }),
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

const mockConfig = {
  id: 'cfg-1',
  operator_name: 'PlaceSecrets s.r.o.',
  revolut_username: 'placesecrets',
  revolut_iban: 'CZ123456',
  stripe_publishable_key: 'pk_test_xxx',
  google_pay_merchant_id: 'gp-123',
  apple_pay_merchant_id: 'ap-123',
  free_pois_per_month: 3,
  max_geofences: 50,
  max_photo_size_mb: 10,
  max_audio_size_mb: 50,
  admin_pin_attempts: 5,
  admin_pin_lockout_minutes: 15,
  receipt_prefix: 'PS-',
  updated_at: '2024-01-01',
}

describe('SettingsPage', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    mockHasPermission.mockReturnValue(true)
    mockAdminSelect.mockImplementation((table: string) => {
      if (table === 'payment_config') {
        return Promise.resolve({ data: mockConfig, error: null })
      }
      // AdminUsersTable loads admin_users
      if (table === 'admin_users') {
        return Promise.resolve({ data: [], error: null })
      }
      return Promise.resolve({ data: null, error: null })
    })
  })

  it('loads payment_config on mount', async () => {
    render(<SettingsPage />)

    await waitFor(() => {
      expect(mockAdminSelect).toHaveBeenCalledWith('payment_config', expect.objectContaining({
        single: true,
      }))
    })
  })

  it('renders system limits section fields', async () => {
    render(<SettingsPage />)

    await waitFor(() => {
      expect(screen.getByDisplayValue('3')).toBeInTheDocument() // free_pois_per_month
    })

    // max_geofences=50 and max_audio_size_mb=50 both render as '50'
    const fiftyInputs = screen.getAllByDisplayValue('50')
    expect(fiftyInputs.length).toBeGreaterThanOrEqual(2)
    expect(screen.getByDisplayValue('10')).toBeInTheDocument() // max_photo_size_mb
    expect(screen.getByDisplayValue('5')).toBeInTheDocument() // admin_pin_attempts
    expect(screen.getByDisplayValue('15')).toBeInTheDocument() // admin_pin_lockout_minutes
    expect(screen.getByDisplayValue('PS-')).toBeInTheDocument() // receipt_prefix
  })

  it('renders payment config section fields', async () => {
    render(<SettingsPage />)

    await waitFor(() => {
      expect(screen.getByDisplayValue('PlaceSecrets s.r.o.')).toBeInTheDocument()
    })

    expect(screen.getByDisplayValue('placesecrets')).toBeInTheDocument()
    expect(screen.getByDisplayValue('CZ123456')).toBeInTheDocument()
    expect(screen.getByDisplayValue('pk_test_xxx')).toBeInTheDocument()
    expect(screen.getByDisplayValue('gp-123')).toBeInTheDocument()
    expect(screen.getByDisplayValue('ap-123')).toBeInTheDocument()
    // Stripe + Comgate secrets should be masked
    expect(screen.getAllByDisplayValue('********').length).toBeGreaterThan(0)
  })

  it('save calls adminUpdate for payment_config', async () => {
    mockAdminUpdate.mockResolvedValue({ error: null })
    render(<SettingsPage />)

    await waitFor(() => {
      expect(screen.getByDisplayValue('PlaceSecrets s.r.o.')).toBeInTheDocument()
    })

    // There are two save buttons (system limits + payment config). Click the first one.
    const saveButtons = screen.getAllByRole('button', { name: /common\.save|settings\.saveConfig/i })
    fireEvent.click(saveButtons[0])

    await waitFor(() => {
      expect(mockAdminUpdate).toHaveBeenCalledWith(
        'payment_config',
        expect.objectContaining({
          operator_name: 'PlaceSecrets s.r.o.',
          free_pois_per_month: 3,
          receipt_prefix: 'PS-',
        }),
        [{ column: 'id', op: 'eq', value: 'cfg-1' }]
      )
    })
    expect(mockToastSuccess).toHaveBeenCalled()
  })

  it('permission gating: canWritePayments=false disables save buttons', async () => {
    mockHasPermission.mockReturnValue(false)
    render(<SettingsPage />)

    await waitFor(() => {
      expect(screen.getByDisplayValue('PlaceSecrets s.r.o.')).toBeInTheDocument()
    })

    // Save buttons should not be rendered when canWritePayments is false
    const saveButtons = screen.queryAllByRole('button', { name: /common\.save|settings\.saveConfig/i })
    expect(saveButtons.length).toBe(0)

    // Inputs should be disabled
    const operatorInput = screen.getByDisplayValue('PlaceSecrets s.r.o.')
    expect(operatorInput).toBeDisabled()
  })

  it('renders ChangePinForm, InviteAdminForm, AdminUsersTable subsections', async () => {
    render(<SettingsPage />)

    await waitFor(() => {
      // ChangePinForm renders current/new PIN labels
      expect(screen.getByText('settings.currentPin')).toBeInTheDocument()
    })

    expect(screen.getByText('settings.newPin')).toBeInTheDocument()

    // InviteAdminForm renders email input and role select
    expect(screen.getByPlaceholderText('user@example.com')).toBeInTheDocument()
    expect(screen.getByLabelText('User role')).toBeInTheDocument()

    // Section titles — settings.changePin appears both as section title and button text
    const changePinTexts = screen.getAllByText('settings.changePin')
    expect(changePinTexts.length).toBeGreaterThanOrEqual(2) // section title + button
    expect(screen.getByText('settings.adminUsers')).toBeInTheDocument()
    expect(screen.getByText('settings.systemLimits')).toBeInTheDocument()
    expect(screen.getByText('settings.paymentConfig')).toBeInTheDocument()
  })
})
