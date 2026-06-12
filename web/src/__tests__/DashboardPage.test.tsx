import { describe, it, expect, vi, beforeEach } from 'vitest'
import { render, screen, waitFor } from '@testing-library/react'
import { MemoryRouter } from 'react-router-dom'
import DashboardPage from '@/pages/DashboardPage'

const mockAdminSelect = vi.hoisted(() => vi.fn())
const mockAdminRpc = vi.hoisted(() => vi.fn())

vi.mock('@/lib/supabase/admin-api', () => ({
  adminSelect: mockAdminSelect,
  adminRpc: mockAdminRpc,
}))

vi.mock('react-i18next', () => ({
  useTranslation: () => ({
    t: (k: string) => {
      const map: Record<string, string> = {
        'admin.dashboard.registeredUsers': 'Registered Users',
        'admin.dashboard.anonymousUsers': 'Anonymous Users',
        'admin.dashboard.activeCities': 'Active Cities',
        'admin.dashboard.activePlaces': 'Active Places',
        'admin.dashboard.revenue': 'Revenue',
        'admin.dashboard.totalPurchases': 'Total Purchases',
        'admin.dashboard.freeVisitsMonth': 'Free Visits (Month)',
        'admin.dashboard.contributors': 'Contributors',
        'admin.dashboard.avgRating': 'Avg. Rating',
        'admin.dashboard.sectionUsers': 'Users',
        'admin.dashboard.sectionContent': 'Content',
        'admin.dashboard.sectionCommerce': 'Commerce',
        'admin.dashboard.poiTypes': 'POI Types',
        'admin.dashboard.topVisited': 'Top Visited',
        'admin.dashboard.noPoiTypeData': 'No POI type data',
        'admin.dashboard.noVisitData': 'No visit data',
        'admin.dashboard.verifiedCount': 'Verified: {{count}}',
        'admin.dashboard.totalRatings': 'Total: {{count}}',
        'admin.dashboard.purchaseCount': 'Purchases: {{count}}',
      }
      return map[k] || k
    },
    i18n: { language: 'en', changeLanguage: vi.fn() },
  }),
}))

vi.mock('sonner', () => ({ toast: { success: vi.fn(), error: vi.fn() } }))
vi.mock('@/components/dashboard/RevenueChart', () => ({
  RevenueChart: () => <div data-testid="revenue-chart" />,
}))
vi.mock('@/components/dashboard/ActivityChart', () => ({
  ActivityChart: () => <div data-testid="activity-chart" />,
}))

const mockStats = {
  registered_users: 120,
  anonymous_users: 45,
  active_pois: 80,
  active_cities: 12,
  total_purchases: 300,
  total_revenue_eur: 4500,
  free_visits_this_month: 1500,
  pending_revolut: 2,
  total_contributors: 15,
  verified_contributors: 8,
  total_poi_ratings: 250,
  global_avg_rating: 4.35,
}

function setupMocks() {
  mockAdminSelect.mockResolvedValue({ data: mockStats, error: null })
  mockAdminRpc.mockResolvedValue({ data: [], error: null })
}

function renderPage() {
  return render(
    <MemoryRouter>
      <DashboardPage />
    </MemoryRouter>
  )
}

describe('DashboardPage', () => {
  beforeEach(() => {
    vi.clearAllMocks()
  })

  it('loads admin_stats on mount and renders MetricCards with counts', async () => {
    setupMocks()
    renderPage()

    await waitFor(() => {
      expect(screen.getByText('120')).toBeInTheDocument()
    })
    expect(screen.getByText('45')).toBeInTheDocument()
    expect(screen.getByText('12')).toBeInTheDocument()
    expect(screen.getByText('80')).toBeInTheDocument()
    expect(screen.getByText('Registered Users')).toBeInTheDocument()
    expect(screen.getByText('Active Cities')).toBeInTheDocument()
    expect(screen.getByText('Active Places')).toBeInTheDocument()
    expect(mockAdminSelect).toHaveBeenCalledWith('admin_stats', { single: true })
  })

  it('loading state shows skeletons', () => {
    mockAdminSelect.mockReturnValue(new Promise(() => {}))
    mockAdminRpc.mockReturnValue(new Promise(() => {}))
    renderPage()

    // Skeletons are rendered as divs with h-24 class (8 of them)
    const skeletons = document.querySelectorAll('.h-24')
    expect(skeletons.length).toBeGreaterThanOrEqual(8)
  })

  it('error state shows message', async () => {
    mockAdminSelect.mockRejectedValue(new Error('Network error'))
    mockAdminRpc.mockRejectedValue(new Error('Network error'))
    renderPage()

    await waitFor(() => {
      expect(screen.getByText(/Failed to load dashboard/)).toBeInTheDocument()
    })
  })
})
