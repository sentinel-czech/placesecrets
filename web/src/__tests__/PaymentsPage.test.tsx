import { describe, it, expect, vi, beforeEach } from 'vitest'
import { render, screen, waitFor, fireEvent } from '@testing-library/react'
import { MemoryRouter } from 'react-router-dom'
import PaymentsPage from '@/pages/payments/PaymentsPage'

const mockAdminSelect = vi.hoisted(() => vi.fn())

vi.mock('@/lib/supabase/admin-api', () => ({
  adminSelect: mockAdminSelect,
  adminUpdate: vi.fn(),
  adminRpc: vi.fn(),
}))

vi.mock('@/lib/supabase/client', () => ({
  supabase: {
    auth: { getSession: vi.fn().mockResolvedValue({ data: { session: null } }) },
    from: vi.fn(),
    rpc: vi.fn(),
  },
}))

vi.mock('@/hooks/useAuth', () => ({
  useAuthStore: vi.fn(() => ({
    hasPermission: () => true,
    role: 'superadmin',
    permissions: [],
  })),
}))

vi.mock('react-i18next', () => ({
  useTranslation: () => ({
    t: (k: string, d?: string) => d || k,
    i18n: { language: 'en', changeLanguage: vi.fn() },
  }),
}))

vi.mock('sonner', () => ({ toast: { success: vi.fn(), error: vi.fn() } }))

function makeReceipt(overrides: Record<string, unknown> = {}) {
  return {
    id: 'receipt-1',
    user_id: 'user-1',
    city_id: 'city-1',
    purchased_at: '2024-06-15T10:30:00Z',
    payment_method: 'stripe',
    transaction_id: 'txn-123',
    amount_eur: 9.99,
    currency: 'EUR',
    status: 'completed',
    revolut_note: null,
    confirmed_by: null,
    confirmed_at: null,
    receipt_number: 'PS-2024-0001',
    receipt_pdf_url: null,
    receipt_sent_at: null,
    city: { name: 'Prague' },
    ...overrides,
  }
}

function renderPage() {
  return render(
    <MemoryRouter>
      <PaymentsPage />
    </MemoryRouter>,
  )
}

describe('PaymentsPage', () => {
  beforeEach(() => {
    vi.clearAllMocks()
  })

  it('loads payment_receipts on mount', async () => {
    mockAdminSelect.mockResolvedValue({ data: [], error: null })
    renderPage()

    await waitFor(() => {
      expect(mockAdminSelect).toHaveBeenCalledWith('payment_receipts', expect.objectContaining({
        select: '*, city:cities(name)',
        order: { column: 'purchased_at', ascending: false },
      }))
    })
  })

  it('filter by status dropdown narrows results', async () => {
    mockAdminSelect.mockResolvedValue({ data: [], error: null })
    renderPage()

    await waitFor(() => {
      expect(mockAdminSelect).toHaveBeenCalled()
    })
    mockAdminSelect.mockClear()
    mockAdminSelect.mockResolvedValue({ data: [], error: null })

    const statusSelect = screen.getByLabelText('Filter by status')
    fireEvent.change(statusSelect, { target: { value: 'completed' } })

    await waitFor(() => {
      expect(mockAdminSelect).toHaveBeenCalledWith('payment_receipts', expect.objectContaining({
        filters: expect.arrayContaining([
          { column: 'status', op: 'eq', value: 'completed' },
        ]),
      }))
    })
  })

  it('filter by payment method dropdown', async () => {
    mockAdminSelect.mockResolvedValue({ data: [], error: null })
    renderPage()

    await waitFor(() => {
      expect(mockAdminSelect).toHaveBeenCalled()
    })
    mockAdminSelect.mockClear()
    mockAdminSelect.mockResolvedValue({ data: [], error: null })

    const methodSelect = screen.getByLabelText('Filter by method')
    fireEvent.change(methodSelect, { target: { value: 'revolut' } })

    await waitFor(() => {
      expect(mockAdminSelect).toHaveBeenCalledWith('payment_receipts', expect.objectContaining({
        filters: expect.arrayContaining([
          { column: 'payment_method', op: 'eq', value: 'revolut' },
        ]),
      }))
    })
  })

  it('DataTable renders receipt columns', async () => {
    const receipts = [
      makeReceipt(),
      makeReceipt({
        id: 'receipt-2',
        receipt_number: 'PS-2024-0002',
        amount_eur: 4.99,
        payment_method: 'revolut',
        status: 'pending',
        city: { name: 'Brno' },
        purchased_at: '2024-07-01T08:00:00Z',
      }),
    ]
    mockAdminSelect.mockResolvedValue({ data: receipts, error: null })
    renderPage()

    await waitFor(() => {
      expect(screen.getByText('PS-2024-0001')).toBeInTheDocument()
    })

    expect(screen.getByText('PS-2024-0002')).toBeInTheDocument()
    expect(screen.getByText('Prague')).toBeInTheDocument()
    expect(screen.getByText('Brno')).toBeInTheDocument()
    expect(screen.getByText('9.99 EUR')).toBeInTheDocument()
    expect(screen.getByText('4.99 EUR')).toBeInTheDocument()
    expect(screen.getByText('stripe')).toBeInTheDocument()
    expect(screen.getByText('revolut')).toBeInTheDocument()
    expect(screen.getByText('completed')).toBeInTheDocument()
    expect(screen.getByText('pending')).toBeInTheDocument()
  })

  it('CSV export generates download', async () => {
    const receipts = [makeReceipt()]
    mockAdminSelect.mockResolvedValue({ data: receipts, error: null })

    const createObjectURLSpy = vi.fn().mockReturnValue('blob:test')
    const revokeObjectURLSpy = vi.fn()
    globalThis.URL.createObjectURL = createObjectURLSpy
    globalThis.URL.revokeObjectURL = revokeObjectURLSpy

    // Track anchor element clicks without mocking createElement
    const clickSpy = vi.fn()
    HTMLAnchorElement.prototype.click = clickSpy

    renderPage()

    await waitFor(() => {
      expect(screen.getByText('PS-2024-0001')).toBeInTheDocument()
    })

    const csvButton = screen.getByText('CSV').closest('button')!
    fireEvent.click(csvButton)

    expect(createObjectURLSpy).toHaveBeenCalled()
    expect(clickSpy).toHaveBeenCalled()
    expect(revokeObjectURLSpy).toHaveBeenCalled()
  })

  it('detail link navigates to /admin/payments/:id', async () => {
    const receipts = [makeReceipt()]
    mockAdminSelect.mockResolvedValue({ data: receipts, error: null })
    renderPage()

    await waitFor(() => {
      expect(screen.getByText('PS-2024-0001')).toBeInTheDocument()
    })

    const detailLink = screen.getByText('admin.users.detail').closest('a')
    expect(detailLink).toHaveAttribute('href', '/admin/payments/receipt-1')
  })

  it('error state shows message', async () => {
    mockAdminSelect.mockResolvedValue({ data: null, error: 'Failed to load receipts' })
    renderPage()

    await waitFor(() => {
      expect(screen.getByText('Failed to load receipts')).toBeInTheDocument()
    })
  })
})
