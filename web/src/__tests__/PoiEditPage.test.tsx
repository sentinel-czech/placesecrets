import { describe, it, expect, vi, beforeEach } from 'vitest'
import { render, screen, waitFor, fireEvent } from '@testing-library/react'
import { MemoryRouter, Route, Routes } from 'react-router-dom'
import PoiEditPage from '@/pages/pois/PoiEditPage'

const mockAdminSelect = vi.hoisted(() => vi.fn())
const mockAdminUpdate = vi.hoisted(() => vi.fn())
const mockNavigate = vi.hoisted(() => vi.fn())
const mockToastSuccess = vi.hoisted(() => vi.fn())
const mockToastError = vi.hoisted(() => vi.fn())

vi.mock('@/lib/supabase/admin-api', () => ({
  adminSelect: mockAdminSelect,
  adminUpdate: mockAdminUpdate,
}))

vi.mock('@/lib/supabase/client', () => ({
  supabase: {
    auth: { getSession: vi.fn().mockResolvedValue({ data: { session: null } }) },
    from: vi.fn(),
    rpc: vi.fn(),
  },
}))

vi.mock('sonner', () => ({
  toast: {
    success: mockToastSuccess,
    error: mockToastError,
  },
}))

vi.mock('react-router-dom', async () => {
  const actual = await vi.importActual<typeof import('react-router-dom')>('react-router-dom')
  return {
    ...actual,
    useNavigate: () => mockNavigate,
  }
})

// Mock MapPicker (uses leaflet which is not available in jsdom)
vi.mock('@/components/shared/MapPicker', () => ({
  MapPicker: () => <div data-testid="map-picker">MapPicker</div>,
}))

// Mock PhotoUploader and AudioUploader
vi.mock('@/components/pois/PhotoUploader', () => ({
  PhotoUploader: () => <div data-testid="photo-uploader">PhotoUploader</div>,
}))

vi.mock('@/components/pois/AudioUploader', () => ({
  AudioUploader: () => <div data-testid="audio-uploader">AudioUploader</div>,
}))

// Mock PremiumContentTab to avoid its internal fetch logic
vi.mock('@/components/pois/PremiumContentTab', () => ({
  PremiumContentTab: ({ poiId, cityId }: { poiId: string; cityId: string }) => (
    <div data-testid="premium-content-tab">PremiumContentTab poiId={poiId} cityId={cityId}</div>
  ),
}))

const mockPoi = {
  id: 'poi-1',
  city_id: 'city-1',
  type_id: null,
  name: { cs: 'Karlův most', en: 'Charles Bridge' },
  description: { cs: 'Popis', en: 'Description' },
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
  slug: 'karluv-most',
  access_level: 'city_access',
  perex: null,
  premium_price: null,
  created_at: '2024-01-01',
  updated_at: '2024-01-01',
}

const mockPremiumPoi = {
  ...mockPoi,
  id: 'poi-2',
  name: { cs: 'Premium místo', en: 'Premium Place' },
  access_level: 'premium_poi',
  premium_price: 4.99,
}

function setupMocks(poi: typeof mockPoi | typeof mockPremiumPoi | null = mockPoi, fetchError?: string) {
  mockAdminSelect.mockImplementation((table: string) => {
    if (table === 'pois') {
      if (fetchError) return Promise.resolve({ data: null, error: fetchError })
      return Promise.resolve({ data: poi, error: null })
    }
    if (table === 'poi_ratings') {
      return Promise.resolve({ data: [], error: null })
    }
    // PoiForm fetches poi_types and cities
    if (table === 'poi_types') {
      return Promise.resolve({
        data: [{ id: 'type-1', name: { cs: 'Hrad', en: 'Castle' }, sort_order: 1, is_active: true }],
        error: null,
      })
    }
    if (table === 'cities') {
      return Promise.resolve({ data: { slug: 'prague', country_code: 'CZ' }, error: null })
    }
    return Promise.resolve({ data: null, error: null })
  })
}

function renderPage(cityId = 'city-1', poiId = 'poi-1') {
  return render(
    <MemoryRouter initialEntries={[`/admin/cities/${cityId}/pois/${poiId}/edit`]}>
      <Routes>
        <Route path="/admin/cities/:cityId/pois/:poiId/edit" element={<PoiEditPage />} />
      </Routes>
    </MemoryRouter>
  )
}

describe('PoiEditPage', () => {
  beforeEach(() => {
    vi.clearAllMocks()
  })

  it('shows loading skeleton initially', () => {
    // Never-resolving promise keeps loading state
    mockAdminSelect.mockReturnValue(new Promise(() => {}))
    renderPage()

    // Loading state: neither the POI name heading nor "not found" is shown
    expect(screen.queryByText(/Edit:/)).not.toBeInTheDocument()
    expect(screen.queryByText('POI not found')).not.toBeInTheDocument()
    // A skeleton/loading indicator should be rendered (animate-pulse div)
    const skeleton = document.querySelector('[class*="animate-pulse"], .h-96')
    expect(skeleton).toBeInTheDocument()
  })

  it('fetches POI data and ratings with correct filters', async () => {
    setupMocks()
    renderPage('city-1', 'poi-1')

    await waitFor(() => {
      expect(mockAdminSelect).toHaveBeenCalledWith('pois', {
        filters: [{ column: 'id', op: 'eq', value: 'poi-1' }],
        single: true,
      })
      expect(mockAdminSelect).toHaveBeenCalledWith('poi_ratings', {
        filters: [{ column: 'poi_id', op: 'eq', value: 'poi-1' }],
        order: { column: 'created_at', ascending: false },
      })
    })
  })

  it('renders POI name in heading after load', async () => {
    setupMocks()
    renderPage()

    await waitFor(() => {
      expect(screen.getByText(/Edit: Karlův most/)).toBeInTheDocument()
    })
  })

  it('renders PoiForm with Basic Info and Ratings tabs for non-premium POI', async () => {
    setupMocks(mockPoi)
    renderPage()

    await waitFor(() => {
      expect(screen.getByText(/Edit: Karlův most/)).toBeInTheDocument()
    })

    // Should show Basic Info and Ratings tabs, but not Premium Content
    expect(screen.getByRole('tab', { name: /Basic Info/i })).toBeInTheDocument()
    expect(screen.getByRole('tab', { name: /Ratings/i })).toBeInTheDocument()
    expect(screen.queryByRole('tab', { name: /Premium Content/i })).not.toBeInTheDocument()

    // PoiForm should be rendered (it has an Update POI button)
    expect(screen.getByRole('button', { name: /Update POI/i })).toBeInTheDocument()
  })

  it('renders two tabs for premium_poi access level', async () => {
    setupMocks(mockPremiumPoi)
    renderPage('city-1', 'poi-2')

    await waitFor(() => {
      expect(screen.getByText(/Edit: Premium místo/)).toBeInTheDocument()
    })

    // Should have all three tab triggers
    expect(screen.getByRole('tab', { name: 'Basic Info' })).toBeInTheDocument()
    expect(screen.getByRole('tab', { name: 'Premium Content' })).toBeInTheDocument()
    expect(screen.getByRole('tab', { name: /Ratings/ })).toBeInTheDocument()
  })

  it('premium tab renders PremiumContentTab component', async () => {
    setupMocks(mockPremiumPoi)
    renderPage('city-1', 'poi-2')

    await waitFor(() => {
      expect(screen.getByText(/Edit: Premium místo/)).toBeInTheDocument()
    })

    // Click on Premium Content tab
    const premiumTab = screen.getByText('Premium Content')
    fireEvent.click(premiumTab)

    await waitFor(() => {
      expect(screen.getByTestId('premium-content-tab')).toBeInTheDocument()
    })
  })

  it('save success calls adminUpdate and navigates to POI list', async () => {
    setupMocks(mockPoi)
    mockAdminUpdate.mockResolvedValue({ error: null })
    renderPage('city-1', 'poi-1')

    await waitFor(() => {
      expect(screen.getByText(/Edit: Karlův most/)).toBeInTheDocument()
    })

    // Fill required name_cs field (already has default value from initial)
    const submitBtn = screen.getByRole('button', { name: /Update POI/i })
    fireEvent.click(submitBtn)

    await waitFor(() => {
      expect(mockAdminUpdate).toHaveBeenCalledWith(
        'pois',
        expect.objectContaining({
          city_id: 'city-1',
          name: { cs: 'Karlův most' },
        }),
        [{ column: 'id', op: 'eq', value: 'poi-1' }]
      )
    })

    expect(mockToastSuccess).toHaveBeenCalledWith('POI updated')
    expect(mockNavigate).toHaveBeenCalledWith('/admin/cities/city-1/pois')
  })

  it('save error shows toast and stays on page', async () => {
    setupMocks(mockPoi)
    mockAdminUpdate.mockResolvedValue({ error: 'Update failed' })
    renderPage('city-1', 'poi-1')

    await waitFor(() => {
      expect(screen.getByText(/Edit: Karlův most/)).toBeInTheDocument()
    })

    const submitBtn = screen.getByRole('button', { name: /Update POI/i })
    fireEvent.click(submitBtn)

    await waitFor(() => {
      expect(mockToastError).toHaveBeenCalledWith('Update failed')
    })

    // Should NOT navigate away
    expect(mockNavigate).not.toHaveBeenCalled()
  })

  it('shows POI not found when data is null', async () => {
    setupMocks(null)
    renderPage()

    await waitFor(() => {
      expect(screen.getByText('POI not found')).toBeInTheDocument()
    })
  })

  it('shows error message when fetch fails', async () => {
    setupMocks(null, 'Database error')
    renderPage()

    await waitFor(() => {
      expect(screen.getByText('Database error')).toBeInTheDocument()
    })
  })

  it('falls back to en name when cs is missing', async () => {
    const enOnlyPoi = { ...mockPoi, name: { en: 'English Only' } }
    setupMocks(enOnlyPoi as typeof mockPoi)
    renderPage()

    await waitFor(() => {
      expect(screen.getByText(/Edit: English Only/)).toBeInTheDocument()
    })
  })
})
