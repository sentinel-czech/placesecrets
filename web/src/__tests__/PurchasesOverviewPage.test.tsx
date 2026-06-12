import { describe, it, expect, vi, beforeEach } from 'vitest'
import { render, screen, waitFor } from '@testing-library/react'
import { MemoryRouter } from 'react-router-dom'
import PurchasesOverviewPage from '@/pages/purchases/PurchasesOverviewPage'

const mockAdminSelect = vi.hoisted(() => vi.fn())

vi.mock('@/lib/supabase/admin-api', () => ({
  adminSelect: mockAdminSelect,
}))

vi.mock('react-i18next', () => ({
  useTranslation: () => ({
    t: (k: string) => {
      const map: Record<string, string> = {
        'common.loading': 'Loading...',
        'purchasesPage.title': 'Purchases Overview',
        'purchasesPage.totalRevenue': 'Total Revenue',
        'purchasesPage.poiPurchases': 'POI Purchases',
        'purchasesPage.premiumBundles': 'Premium Bundles',
        'purchasesPage.cityAccess': 'City Access',
        'purchasesPage.colDate': 'Date',
        'purchasesPage.colType': 'Type',
        'purchasesPage.colItem': 'Item',
        'purchasesPage.colCity': 'City',
        'purchasesPage.colPrice': 'Price',
        'purchasesPage.typePoi': 'POI',
        'purchasesPage.typeCityPremium': 'City Premium',
        'purchasesPage.typeCityAccess': 'City Access',
        'purchasesPage.searchPlaceholder': 'Search items...',
      }
      return map[k] || k
    },
    i18n: { language: 'en' },
  }),
}))

vi.mock('@/lib/supabase/client', () => ({
  supabase: {
    auth: { getSession: vi.fn().mockResolvedValue({ data: { session: null } }) },
    from: vi.fn(),
    rpc: vi.fn(),
  },
}))

function makePurchase(overrides: Record<string, unknown> = {}) {
  return {
    purchase_type: 'poi',
    user_id: 'user-1',
    purchased_at: '2024-06-15T10:30:00Z',
    price_paid: 2.99,
    payment_id: 'pay-1',
    item_id: 'poi-1',
    item_name: 'Charles Bridge Audio',
    item_slug: 'charles-bridge',
    city_slug: 'prague',
    city_name: 'Prague',
    ...overrides,
  }
}

function renderPage() {
  return render(
    <MemoryRouter>
      <PurchasesOverviewPage />
    </MemoryRouter>
  )
}

describe('PurchasesOverviewPage', () => {
  beforeEach(() => {
    vi.clearAllMocks()
  })

  it('shows loading state initially', () => {
    mockAdminSelect.mockReturnValue(new Promise(() => {}))
    renderPage()
    expect(screen.getByText('Loading...')).toBeInTheDocument()
  })

  it('fetches from user_all_purchases view', async () => {
    mockAdminSelect.mockResolvedValue({ data: [], error: null })
    renderPage()

    await waitFor(() => {
      expect(mockAdminSelect).toHaveBeenCalledWith('user_all_purchases', {
        order: { column: 'purchased_at', ascending: false },
      })
    })
  })

  it('renders revenue stats cards', async () => {
    const purchases = [
      makePurchase({ price_paid: 2.99, purchase_type: 'poi' }),
      makePurchase({ price_paid: 9.99, purchase_type: 'city_premium', item_name: 'Prague Premium' }),
      makePurchase({ price_paid: 4.99, purchase_type: 'city_access', item_name: 'Prague Access' }),
    ]
    mockAdminSelect.mockResolvedValue({ data: purchases, error: null })
    renderPage()

    await waitFor(() => {
      expect(screen.getByText('Total Revenue')).toBeInTheDocument()
    })

    // Total = 2.99 + 9.99 + 4.99 = 17.97
    expect(screen.getByText('€17.97')).toBeInTheDocument()

    // Counts
    expect(screen.getByText('POI Purchases')).toBeInTheDocument()
    expect(screen.getByText('Premium Bundles')).toBeInTheDocument()
    // "City Access" appears both as a stats card title and a badge in the table
    expect(screen.getAllByText('City Access').length).toBeGreaterThanOrEqual(1)
  })

  it('displays null price_paid as dash', async () => {
    const purchases = [
      makePurchase({ price_paid: null, item_name: 'Free Item' }),
    ]
    mockAdminSelect.mockResolvedValue({ data: purchases, error: null })
    renderPage()

    await waitFor(() => {
      expect(screen.getByText('Free Item')).toBeInTheDocument()
    })
    // The cell for null price should show the em dash
    expect(screen.getByText('—')).toBeInTheDocument()
  })

  it('shows badge variants for purchase types', async () => {
    const purchases = [
      makePurchase({ purchase_type: 'poi', item_name: 'POI Item', purchased_at: '2024-06-15T10:00:00Z' }),
      makePurchase({ purchase_type: 'city_premium', item_name: 'Premium Item', purchased_at: '2024-06-15T11:00:00Z' }),
      makePurchase({ purchase_type: 'city_access', item_name: 'Access Item', purchased_at: '2024-06-15T12:00:00Z' }),
    ]
    mockAdminSelect.mockResolvedValue({ data: purchases, error: null })
    renderPage()

    await waitFor(() => {
      expect(screen.getByText('POI')).toBeInTheDocument()
    })
    expect(screen.getByText('City Premium')).toBeInTheDocument()
    // "City Access" appears in the stats card title and as a badge; check both exist
    const cityAccessElements = screen.getAllByText('City Access')
    expect(cityAccessElements.length).toBeGreaterThanOrEqual(2)
  })

  it('shows empty state with zero revenue when no purchases', async () => {
    mockAdminSelect.mockResolvedValue({ data: [], error: null })
    renderPage()

    await waitFor(() => {
      expect(screen.getByText('€0.00')).toBeInTheDocument()
    })

    // Counts should all be 0
    const zeros = screen.getAllByText('0')
    expect(zeros.length).toBe(3) // POI, Premium, City Access counts

    // DataTable empty state
    expect(screen.getByText('No results.')).toBeInTheDocument()
  })

  it('shows error message when fetch fails', async () => {
    mockAdminSelect.mockResolvedValue({ data: null, error: 'Network error' })
    renderPage()

    await waitFor(() => {
      expect(screen.getByText('Network error')).toBeInTheDocument()
    })
  })
})
