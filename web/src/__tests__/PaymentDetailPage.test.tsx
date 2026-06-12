import { describe, it, expect, vi, beforeEach } from 'vitest'
import { render, screen, waitFor, fireEvent } from '@testing-library/react'
import { MemoryRouter, Route, Routes } from 'react-router-dom'
import PaymentDetailPage from '@/pages/payments/PaymentDetailPage'

const mockAdminSelect = vi.hoisted(() => vi.fn())
const mockAdminUpdate = vi.hoisted(() => vi.fn())
const mockInvoke = vi.hoisted(() => vi.fn())
const mockToast = vi.hoisted(() => ({ success: vi.fn(), error: vi.fn() }))
const mockHasPermission = vi.hoisted(() => vi.fn(() => true))

vi.mock('@/lib/supabase/admin-api', () => ({
  adminSelect: mockAdminSelect,
  adminUpdate: mockAdminUpdate,
  adminRpc: vi.fn(),
}))

vi.mock('@/lib/supabase/client', () => ({
  supabase: {
    auth: { getSession: vi.fn().mockResolvedValue({ data: { session: null } }) },
    functions: { invoke: mockInvoke },
  },
}))

vi.mock('@/hooks/useAuth', () => ({
  useAuthStore: vi.fn(() => ({
    hasPermission: mockHasPermission,
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

vi.mock('sonner', () => ({ toast: mockToast }))

function makeReceipt(overrides: Record<string, unknown> = {}) {
  return {
    id: 'receipt-42',
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
    receipt_number: 'PS-2024-0042',
    receipt_pdf_url: null,
    receipt_sent_at: null,
    city: { name: 'Prague' },
    ...overrides,
  }
}

function renderPage(id = 'receipt-42') {
  return render(
    <MemoryRouter initialEntries={[`/admin/payments/${id}`]}>
      <Routes>
        <Route path="/admin/payments/:id" element={<PaymentDetailPage />} />
        <Route path="/admin/payments" element={<div>Payments List</div>} />
      </Routes>
    </MemoryRouter>,
  )
}

describe('PaymentDetailPage', () => {
  beforeEach(() => {
    vi.clearAllMocks()
  })

  it('loads receipt by ID', async () => {
    mockAdminSelect.mockResolvedValue({ data: makeReceipt(), error: null })
    renderPage()

    await waitFor(() => {
      expect(mockAdminSelect).toHaveBeenCalledWith('payment_receipts', {
        select: '*, city:cities(name)',
        filters: [{ column: 'id', op: 'eq', value: 'receipt-42' }],
        single: true,
      })
    })
  })

  it('displays receipt info (number, amount, method, status badge)', async () => {
    mockAdminSelect.mockResolvedValue({ data: makeReceipt(), error: null })
    renderPage()

    await waitFor(() => {
      expect(screen.getByText('PS-2024-0042')).toBeInTheDocument()
    })

    expect(screen.getByText(/9\.99/)).toBeInTheDocument()
    expect(screen.getByText(/stripe/)).toBeInTheDocument()
    expect(screen.getByText('completed')).toBeInTheDocument()
    expect(screen.getByText('Prague')).toBeInTheDocument()
  })

  it('shows Confirm payment button only if status is pending', async () => {
    mockAdminSelect.mockResolvedValue({
      data: makeReceipt({ status: 'pending' }),
      error: null,
    })
    renderPage()

    await waitFor(() => {
      expect(screen.getByText('paymentsPage.confirmPayment')).toBeInTheDocument()
    })

    // Refund button should NOT appear for pending status
    expect(screen.queryByText('paymentsPage.refundPayment')).not.toBeInTheDocument()
  })

  it('does not show Confirm button when status is completed', async () => {
    mockAdminSelect.mockResolvedValue({
      data: makeReceipt({ status: 'completed' }),
      error: null,
    })
    renderPage()

    await waitFor(() => {
      expect(screen.getByText('PS-2024-0042')).toBeInTheDocument()
    })

    expect(screen.queryByText('paymentsPage.confirmPayment')).not.toBeInTheDocument()
  })

  it('Refund button with ConfirmDialog calls stripe-refund', async () => {
    mockAdminSelect.mockResolvedValue({
      data: makeReceipt({ status: 'completed' }),
      error: null,
    })
    mockInvoke.mockResolvedValue({ error: null })
    mockAdminUpdate.mockResolvedValue({ error: null })
    renderPage()

    await waitFor(() => {
      expect(screen.getByText('paymentsPage.refundPayment')).toBeInTheDocument()
    })

    // Click the refund trigger button to open the dialog
    fireEvent.click(screen.getByText('paymentsPage.refundPayment'))

    // The ConfirmDialog should show with the confirm action button
    await waitFor(() => {
      expect(screen.getByText('Refund')).toBeInTheDocument()
    })

    // Click confirm in the dialog
    fireEvent.click(screen.getByText('Refund'))

    await waitFor(() => {
      expect(mockInvoke).toHaveBeenCalledWith('stripe-refund', {
        body: { payment_id: 'receipt-42' },
      })
    })

    await waitFor(() => {
      expect(mockAdminUpdate).toHaveBeenCalledWith(
        'payment_receipts',
        { status: 'refunded' },
        [{ column: 'id', op: 'eq', value: 'receipt-42' }],
      )
    })
  })

  it('Email receipt button calls generate-receipt with send_email', async () => {
    mockAdminSelect.mockResolvedValue({
      data: makeReceipt({ status: 'completed' }),
      error: null,
    })
    mockInvoke.mockResolvedValue({ error: null })
    renderPage()

    await waitFor(() => {
      expect(screen.getByText('paymentsPage.emailReceipt')).toBeInTheDocument()
    })

    fireEvent.click(screen.getByText('paymentsPage.emailReceipt'))

    await waitFor(() => {
      expect(mockInvoke).toHaveBeenCalledWith('generate-receipt', {
        body: { payment_id: 'receipt-42', send_email: true },
      })
    })

    await waitFor(() => {
      expect(mockToast.success).toHaveBeenCalledWith('paymentsPage.receiptEmailed')
    })
  })

  it('shows error state', async () => {
    mockAdminSelect.mockResolvedValue({ data: null, error: 'Receipt not found' })
    renderPage()

    await waitFor(() => {
      expect(screen.getByText('Receipt not found')).toBeInTheDocument()
    })
  })
})
