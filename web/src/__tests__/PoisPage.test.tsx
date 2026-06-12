import { describe, it, expect, vi, beforeEach } from 'vitest'
import { render, screen, waitFor, fireEvent } from '@testing-library/react'
import { MemoryRouter, Route, Routes } from 'react-router-dom'
import PoisPage from '@/pages/pois/PoisPage'

const mockAdminSelect = vi.hoisted(() => vi.fn())
const mockHasPermission = vi.hoisted(() => vi.fn().mockReturnValue(true))

vi.mock('@/lib/supabase/admin-api', () => ({
  adminSelect: mockAdminSelect,
}))

vi.mock('@/lib/supabase/client', () => ({
  supabase: {
    auth: { getSession: vi.fn().mockResolvedValue({ data: { session: null } }) },
    from: vi.fn(),
    rpc: vi.fn(),
  },
}))

vi.mock('@/hooks/useAuth', () => ({
  useAuthStore: Object.assign(
    (selector?: (s: Record<string, unknown>) => unknown) => {
      const state = {
        hasPermission: mockHasPermission,
      }
      return selector ? selector(state) : state
    },
    { getState: () => ({ hasPermission: mockHasPermission }) },
  ),
}))

vi.mock('react-i18next', () => ({
  useTranslation: () => ({
    t: (k: string, opts?: Record<string, string>) => {
      const map: Record<string, string> = {
        'common.loading': 'Loading...',
        'common.edit': 'Edit',
        'poisPage.title': `POIs — ${opts?.city ?? ''}`,
        'poisPage.all': 'All',
        'poisPage.accessPublic': 'Public',
        'poisPage.accessRegistered': 'Registered',
        'poisPage.accessCityAccess': 'City Access',
        'poisPage.accessPremium': 'Premium',
        'poisPage.colName': 'Name',
        'poisPage.colType': 'Type',
        'poisPage.colRating': 'Rating',
        'poisPage.colAccess': 'Access',
        'poisPage.colStatus': 'Status',
        'poisPage.pricing': 'Pricing',
        'poisPage.newPoi': 'New POI',
        'poisPage.searchPlaceholder': 'Search POIs...',
      }
      return map[k] || k
    },
    i18n: { language: 'en', changeLanguage: vi.fn() },
  }),
}))

const mockCity = {
  id: 'city-1',
  name: 'Prague',
  slug: 'prague',
}

function makePoi(overrides: Record<string, unknown> = {}) {
  return {
    id: 'poi-1',
    city_id: 'city-1',
    type_id: null,
    name: { cs: 'Karlův most', en: 'Charles Bridge' },
    description: {},
    latitude: 50.08,
    longitude: 14.41,
    geofence_radius: 100,
    photo_urls: [],
    audio_urls: {},
    is_premium: false,
    sort_order: 1,
    is_active: true,
    contributor_id: null,
    contributor_note: null,
    avg_rating: null,
    total_ratings: 0,
    slug: 'charles-bridge',
    access_level: 'city_access',
    perex: null,
    premium_price: null,
    created_at: '2024-01-01',
    updated_at: '2024-01-01',
    poi_type: null,
    ...overrides,
  }
}

function setupMocks(pois: ReturnType<typeof makePoi>[] = [makePoi()]) {
  mockAdminSelect.mockImplementation((table: string) => {
    if (table === 'cities') {
      return Promise.resolve({ data: mockCity, error: null })
    }
    if (table === 'pois') {
      return Promise.resolve({ data: pois, error: null })
    }
    return Promise.resolve({ data: null, error: 'Unknown table' })
  })
}

function renderPage(cityId = 'city-1') {
  return render(
    <MemoryRouter initialEntries={[`/admin/cities/${cityId}/pois`]}>
      <Routes>
        <Route path="/admin/cities/:cityId/pois" element={<PoisPage />} />
        <Route path="/admin/cities/:cityId/pois/:poiId" element={<div>Edit page</div>} />
      </Routes>
    </MemoryRouter>
  )
}

describe('PoisPage', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    mockHasPermission.mockReturnValue(true)
  })

  it('shows loading state initially', () => {
    mockAdminSelect.mockReturnValue(new Promise(() => {}))
    renderPage()
    expect(screen.getByText('Loading...')).toBeInTheDocument()
  })

  it('renders page and loads POIs list', async () => {
    setupMocks()
    renderPage()

    await waitFor(() => {
      expect(screen.getByText('Karlův most')).toBeInTheDocument()
    })
    expect(screen.getByText(/POIs — Prague/)).toBeInTheDocument()
  })

  it('displays access level filter buttons', async () => {
    setupMocks()
    renderPage()

    await waitFor(() => {
      expect(screen.getByText('All')).toBeInTheDocument()
    })
    expect(screen.getByText('Public')).toBeInTheDocument()
    expect(screen.getByText('Registered')).toBeInTheDocument()
    // "City Access" appears as filter button and badge in the table row (exactly 2)
    expect(screen.getAllByText('City Access')).toHaveLength(2)
    // "Premium" appears as filter button only (no premium POI in default mock)
    expect(screen.getAllByText('Premium')).toHaveLength(1)
  })

  it('filter toggle updates displayed list', async () => {
    const pois = [
      makePoi({ id: 'poi-1', name: { cs: 'Public POI' }, access_level: 'public', sort_order: 1 }),
      makePoi({ id: 'poi-2', name: { cs: 'Premium POI' }, access_level: 'premium_poi', sort_order: 2 }),
      makePoi({ id: 'poi-3', name: { cs: 'City POI' }, access_level: 'city_access', sort_order: 3 }),
    ]
    setupMocks(pois)
    renderPage()

    // Wait for data to load - all POIs visible initially
    await waitFor(() => {
      expect(screen.getByText('Public POI')).toBeInTheDocument()
    })
    expect(screen.getByText('Premium POI')).toBeInTheDocument()
    expect(screen.getByText('City POI')).toBeInTheDocument()

    // Click "Public" filter - only public POI should be visible
    const filterButtons = screen.getAllByRole('button')
    const publicButton = filterButtons.find(b => b.textContent === 'Public')!
    fireEvent.click(publicButton)

    await waitFor(() => {
      expect(screen.getByText('Public POI')).toBeInTheDocument()
    })
    expect(screen.queryByText('Premium POI')).not.toBeInTheDocument()
    expect(screen.queryByText('City POI')).not.toBeInTheDocument()

    // Click "All" to show everything again
    const allButton = filterButtons.find(b => b.textContent === 'All')!
    fireEvent.click(allButton)

    await waitFor(() => {
      expect(screen.getByText('Public POI')).toBeInTheDocument()
      expect(screen.getByText('Premium POI')).toBeInTheDocument()
      expect(screen.getByText('City POI')).toBeInTheDocument()
    })
  })

  it('shows access level badge in table', async () => {
    const pois = [
      makePoi({ id: 'poi-1', name: { cs: 'Test POI' }, access_level: 'premium_poi', sort_order: 1 }),
    ]
    setupMocks(pois)
    renderPage()

    await waitFor(() => {
      expect(screen.getByText('Test POI')).toBeInTheDocument()
    })

    // The Access column header should exist
    expect(screen.getByText('Access')).toBeInTheDocument()
    // The badge with "Premium" label should be in the table row (not the filter button)
    // Filter button text is "Premium", and so is the badge in the table.
    // The badge inside the table uses the Badge component
    const premiumElements = screen.getAllByText('Premium')
    // Exactly 2: one filter button + one badge in the table
    expect(premiumElements).toHaveLength(2)
  })

  it('has an Edit link/button for each POI', async () => {
    setupMocks()
    renderPage()

    await waitFor(() => {
      expect(screen.getByText('Edit')).toBeInTheDocument()
    })

    const editButton = screen.getByText('Edit')
    const editLink = editButton.closest('a')
    expect(editLink).toHaveAttribute('href', '/admin/cities/city-1/pois/poi-1')
  })

  it('shows error message when data fetch fails', async () => {
    mockAdminSelect.mockImplementation((table: string) => {
      if (table === 'cities') {
        return Promise.resolve({ data: null, error: 'City not found' })
      }
      return Promise.resolve({ data: [], error: null })
    })
    renderPage()

    await waitFor(() => {
      expect(screen.getByText('City not found')).toBeInTheDocument()
    })
  })
})
