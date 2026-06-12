import { describe, it, expect, vi, beforeEach } from 'vitest'
import { render, screen, waitFor } from '@testing-library/react'
import { MemoryRouter } from 'react-router-dom'
import AccountProfilePage from '@/pages/account/AccountProfilePage'

const mockUseAuthStore = vi.hoisted(() => vi.fn())
const mockSupabase = vi.hoisted(() => ({
  auth: {
    getSession: vi.fn().mockResolvedValue({ data: { session: null } }),
    updateUser: vi.fn(),
  },
  from: vi.fn().mockReturnValue({
    select: vi.fn().mockReturnValue({
      eq: vi.fn().mockReturnValue({
        maybeSingle: vi.fn().mockResolvedValue({
          data: { language: 'en', backup_email: 'backup@test.com', display_name: 'testuser' },
        }),
      }),
    }),
    upsert: vi.fn().mockResolvedValue({ error: null }),
  }),
  functions: { invoke: vi.fn().mockResolvedValue({ error: null }) },
  rpc: vi.fn().mockResolvedValue({ data: true }),
  storage: { from: vi.fn() },
}))

vi.mock('@/hooks/useAuth', () => ({
  useAuthStore: mockUseAuthStore,
}))

vi.mock('@/lib/supabase/client', () => ({
  supabase: mockSupabase,
}))

vi.mock('react-i18next', () => ({
  useTranslation: () => ({
    t: (k: string, opts?: Record<string, unknown>) => {
      const map: Record<string, string> = {
        'user.profile.settingsTab': 'Settings',
        'user.profile.purchasesTab': 'Purchases',
        'user.profile.adminTab': 'Admin',
        'user.profile.deleteMyAccount': 'Delete my account',
        'user.profile.confirmDeletion': 'Confirm deletion',
        'user.profile.deleteAccount': 'Delete account',
        'user.profile.deleteAccountDesc': 'Permanently delete your account',
        'user.profile.backupEmail': 'Backup email',
        'user.profile.backupEmailDesc': 'A secondary email for recovery',
        'user.profile.backupEmailPlaceholder': 'backup@example.com',
        'user.profile.languageSettings': 'Language',
        'user.profile.selectLanguage': 'Select language',
        'user.profile.memberSince': `Member since ${opts?.date || ''}`,
        'user.profile.currentEmail': `Current: ${opts?.email || ''}`,
        'handle.handle': 'Handle',
        'handle.desc': 'Choose a unique handle',
        'handle.placeholder': 'your_handle',
        'handle.setHandle': 'Set handle',
        'common.save': 'Save',
        'common.cancel': 'Cancel',
        'common.loading': 'Loading...',
        'roles.user': 'User',
        'user.profile.verified': 'Verified',
        'user.receipts.loading': 'Loading receipts...',
        'user.receipts.noReceipts': 'No receipts',
        'user.receipts.noReceiptsDesc': 'You have no receipts yet.',
        'user.profile.emailAddress': 'Email address',
        'user.profile.newEmail': 'New email',
        'user.profile.updateEmail': 'Update email',
        'user.profile.changePassword': 'Change password',
        'user.profile.newPassword': 'New password',
        'user.profile.confirmPassword': 'Confirm password',
        'handle.invalid': 'Invalid handle',
        'handle.taken': 'Handle taken',
        'nav.adminPanel': 'Admin Panel',
        'user.profile.adminPanelDesc': 'Go to admin panel',
        'user.profile.goToAdmin': 'Go to admin',
        'user.profile.backupEmailSaved': 'Backup email saved',
        'user.profile.languageSaved': 'Language saved',
      }
      return map[k] || k
    },
    i18n: { language: 'en', changeLanguage: vi.fn() },
  }),
}))

vi.mock('sonner', () => ({ toast: { success: vi.fn(), error: vi.fn() } }))

function defaultAuthStore(overrides: Record<string, unknown> = {}) {
  return {
    user: { id: 'u-1', email: 'test@example.com', created_at: '2024-01-01' },
    role: 'user',
    displayName: 'testuser',
    isVerified: false,
    userNumber: 100042,
    needsHandle: false,
    signOut: vi.fn(),
    setDisplayName: vi.fn(),
    ...overrides,
  }
}

function renderPage() {
  return render(
    <MemoryRouter initialEntries={['/account/profile']}>
      <AccountProfilePage />
    </MemoryRouter>
  )
}

describe('AccountProfilePage', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    mockUseAuthStore.mockReturnValue(defaultAuthStore())
  })

  it('renders tab navigation (Settings, Purchases)', () => {
    renderPage()
    expect(screen.getByText('Settings')).toBeInTheDocument()
    expect(screen.getByText('Purchases')).toBeInTheDocument()
  })

  it('Settings tab shows handle field', () => {
    renderPage()
    expect(screen.getByText('Handle')).toBeInTheDocument()
    expect(screen.getByPlaceholderText('your_handle')).toBeInTheDocument()
  })

  it('Settings tab shows language selector', () => {
    renderPage()
    expect(screen.getByText('Language')).toBeInTheDocument()
    const select = screen.getByRole('combobox') as HTMLSelectElement
    expect(select).toBeInTheDocument()
    expect(select.value).toBe('en')
  })

  it('Settings tab shows backup email field', () => {
    renderPage()
    expect(screen.getByText('Backup email')).toBeInTheDocument()
    expect(screen.getByPlaceholderText('backup@example.com')).toBeInTheDocument()
  })

  it('Settings tab has delete account button with confirmation', async () => {
    renderPage()
    const deleteBtn = screen.getByText('Delete my account')
    expect(deleteBtn).toBeInTheDocument()
    deleteBtn.click()
    await waitFor(() => {
      expect(screen.getByText('Confirm deletion')).toBeInTheDocument()
    })
    expect(screen.getByText('Cancel')).toBeInTheDocument()
  })

  it('header shows user number', () => {
    renderPage()
    expect(screen.getByText('#100042')).toBeInTheDocument()
  })
})
