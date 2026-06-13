import { describe, it, expect, vi, beforeEach } from 'vitest'
import { render, screen, waitFor } from '@testing-library/react'
import { MemoryRouter, Route, Routes } from 'react-router-dom'
import { HelmetProvider } from 'react-helmet-async'
import PlaceDetailPage from '@/pages/PlaceDetailPage'

const mockRpc = vi.hoisted(() => vi.fn())
const mockFrom = vi.hoisted(() => vi.fn())
const mockUser = vi.hoisted(() => ({ value: null as { id: string; email: string } | null }))

vi.mock('@/lib/supabase/client', () => ({
  supabase: {
    rpc: mockRpc,
    from: mockFrom,
    auth: {
      getSession: vi.fn().mockResolvedValue({ data: { session: null } }),
    },
  },
}))

vi.mock('@/hooks/useAuth', () => ({
  useAuthStore: vi.fn((selector?: (s: Record<string, unknown>) => unknown) => {
    const state = { user: mockUser.value }
    return selector ? selector(state) : state
  }),
}))

// Mock MapPicker (uses leaflet which is not available in jsdom)
vi.mock('@/components/shared/MapPicker', () => ({
  MapPicker: () => <div data-testid="map-picker">MapPicker</div>,
}))

function mockFromChain(data: unknown[] | null = null) {
  const resolved = Promise.resolve({ data, error: null })
  const eqResult = {
    in: vi.fn().mockReturnValue(resolved),
    then: vi.fn().mockImplementation((cb: unknown) => resolved.then(cb as (v: unknown) => unknown)),
  }
  return {
    select: vi.fn().mockReturnValue({
      eq: vi.fn().mockReturnValue(eqResult),
      then: vi.fn().mockImplementation((cb: unknown) => resolved.then(cb as (v: unknown) => unknown)),
    }),
    upsert: vi.fn().mockResolvedValue({ error: null }),
  }
}

function renderPage(citySlug = 'prague', poiSlug = 'charles-bridge') {
  return render(
    <HelmetProvider>
      <MemoryRouter initialEntries={[`/cz/${citySlug}/${poiSlug}`]}>
        <Routes>
          <Route path="/:countryCode/:citySlug/:poiSlug" element={<PlaceDetailPage />} />
        </Routes>
      </MemoryRouter>
    </HelmetProvider>
  )
}

const BASE_POI = {
  poi_id: 'poi-1',
  poi_name: { cs: 'Karlův most', en: 'Charles Bridge' },
  poi_description: { cs: 'Popis mostu', en: 'Bridge description' },
  poi_perex: { cs: 'An iconic medieval bridge.', en: 'An iconic medieval bridge.' },
  poi_access_level: 'city_access',
  poi_premium_price: null,
  poi_lat: 50.08,
  poi_lng: 14.41,
  poi_photo_urls: null,
  poi_audio_urls: null,
  poi_avg_rating: null,
  poi_total_ratings: null,
  poi_aliases: null,
  audio_guides: [],
  poi_type_id: null,
  poi_type_name: null,
  poi_type_icon: null,
  poi_type_color: null,
  contributor_id: null,
  contributor_name: null,
  contributor_avatar: null,
  contributor_verified: null,
  city_id: 'city-1',
  city_name: 'Prague',
  city_slug: 'prague',
  country_code: 'cz',
}

describe('PlaceDetailPage', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    mockUser.value = null
    mockFrom.mockReturnValue(mockFromChain())
  })

  it('shows loading state initially', () => {
    mockRpc.mockReturnValueOnce(new Promise(() => {})) // never resolves
    renderPage()
    expect(screen.getByText('Loading...')).toBeInTheDocument()
  })

  it('renders POI name and city name when found', async () => {
    mockRpc.mockResolvedValue({ data: [BASE_POI], error: null })
    renderPage()

    // i18n defaults to 'en' in test env (no i18next instance), so English name is shown
    await waitFor(() => {
      expect(screen.getByText('Charles Bridge')).toBeInTheDocument()
    })
    expect(screen.getByText('Prague')).toBeInTheDocument()
    expect(screen.getByText('An iconic medieval bridge.')).toBeInTheDocument()
  })

  it('shows premium price when access_level is premium_poi', async () => {
    mockRpc.mockResolvedValueOnce({
      data: [{ ...BASE_POI, poi_id: 'poi-2', poi_name: { cs: 'Premium POI' }, poi_access_level: 'premium_poi', poi_premium_price: 4.99 }],
      error: null,
    })
    renderPage('prague', 'premium-poi')

    await waitFor(() => {
      expect(screen.getAllByText(/€4\.99/).length).toBeGreaterThan(0)
    })
  })

  it('shows Place Not Found when RPC returns empty data', async () => {
    mockRpc.mockResolvedValueOnce({ data: [], error: null })
    renderPage('nonexistent', 'no-poi')

    await waitFor(() => {
      expect(screen.getByText('Place Not Found')).toBeInTheDocument()
    })
  })

  it('shows Place Not Found when RPC returns error', async () => {
    mockRpc.mockResolvedValueOnce({ data: null, error: { message: 'RPC error' } })
    renderPage('bad', 'slug')

    await waitFor(() => {
      expect(screen.getByText('Place Not Found')).toBeInTheDocument()
    })
  })

  it('calls RPC with correct params', async () => {
    mockRpc.mockResolvedValueOnce({ data: [], error: null })
    renderPage('prague', 'charles-bridge')

    await waitFor(() => {
      expect(mockRpc).toHaveBeenCalledWith('get_poi_by_slug', {
        p_country_code: 'cz',
        p_city_slug: 'prague',
        p_poi_slug: 'charles-bridge',
      })
    })
  })

  it('deep link button uses correct placesecrets:// URL', async () => {
    mockRpc.mockResolvedValueOnce({
      data: [{ ...BASE_POI, poi_name: { cs: 'Test Place' } }],
      error: null,
    })
    renderPage('prague', 'test-place')

    await waitFor(() => {
      const link = screen.getByText('Open in App').closest('a')
      expect(link).toHaveAttribute('href', 'placesecrets://cz/prague/test-place')
    })
  })

  it('falls back to en name when cs is missing', async () => {
    mockRpc.mockResolvedValueOnce({
      data: [{ ...BASE_POI, poi_name: { en: 'English Name' }, city_name: 'Brno', city_slug: 'brno' }],
      error: null,
    })
    renderPage('brno', 'en-only')

    await waitFor(() => {
      expect(screen.getByText('English Name')).toBeInTheDocument()
    })
  })

  it('does not show premium price for non-premium POIs', async () => {
    mockRpc.mockResolvedValueOnce({
      data: [{ ...BASE_POI, poi_name: { cs: 'Free POI' } }],
      error: null,
    })
    renderPage('prague', 'free-poi')

    await waitFor(() => {
      expect(screen.getByText('Free POI')).toBeInTheDocument()
    })
    expect(screen.queryByText(/€/)).not.toBeInTheDocument()
  })

  it('only renders languages that have audio guides', async () => {
    mockRpc.mockResolvedValueOnce({
      data: [{
        ...BASE_POI,
        audio_guides: [
          { id: 'ag-1', lang_code: 'en', title: 'English Guide', duration_sec: 120, sort_order: 0, uploaded_by: null, uploader_handle: null, avg_rating: 0, total_ratings: 0, created_at: '2026-01-01' },
          { id: 'ag-2', lang_code: 'cs', title: 'Czech Guide', duration_sec: 60, sort_order: 0, uploaded_by: null, uploader_handle: null, avg_rating: 0, total_ratings: 0, created_at: '2026-01-01' },
        ],
      }],
      error: null,
    })
    renderPage()

    await waitFor(() => {
      expect(screen.getByText('English Guide')).toBeInTheDocument()
    })
    expect(screen.getByText('Czech Guide')).toBeInTheDocument()
    // Should not render languages without guides (e.g., German)
    expect(screen.queryByText('German')).not.toBeInTheDocument()
    expect(screen.queryByText('Spanish')).not.toBeInTheDocument()
  })

  it('shows audio guide ratings', async () => {
    mockRpc.mockResolvedValueOnce({
      data: [{
        ...BASE_POI,
        audio_guides: [
          { id: 'ag-1', lang_code: 'en', title: 'Rated Guide', duration_sec: 120, sort_order: 0, uploaded_by: null, uploader_handle: null, avg_rating: 4.5, total_ratings: 12, created_at: '2026-01-01' },
        ],
      }],
      error: null,
    })
    renderPage()

    await waitFor(() => {
      expect(screen.getByText('Rated Guide')).toBeInTheDocument()
    })
    expect(screen.getByText('4.5 (12)')).toBeInTheDocument()
  })

  it('shows Rate button when logged in', async () => {
    mockUser.value = { id: 'user-1', email: 'test@example.com' }
    mockFrom.mockReturnValue(mockFromChain([]))
    mockRpc.mockResolvedValueOnce({
      data: [{
        ...BASE_POI,
        audio_guides: [
          { id: 'ag-1', lang_code: 'en', title: 'Guide One', duration_sec: 120, sort_order: 0, uploaded_by: 'u-1', uploader_handle: 'test_handle', avg_rating: 0, total_ratings: 0, created_at: '2026-01-01' },
        ],
      }],
      error: null,
    })
    // Mock get_poi_access
    mockRpc.mockResolvedValueOnce({ data: 'city_access' })

    renderPage('prague', 'audio-poi')

    await waitFor(() => {
      expect(screen.getByText('Guide One')).toBeInTheDocument()
    })
    expect(screen.getByText('Rate')).toBeInTheDocument()
    expect(screen.getByText('@test_handle')).toBeInTheDocument()
  })

  it('does not show Rate button when not logged in', async () => {
    mockUser.value = null
    mockRpc.mockResolvedValueOnce({
      data: [{
        ...BASE_POI,
        audio_guides: [
          { id: 'ag-1', lang_code: 'en', title: 'Guide One', duration_sec: 120, sort_order: 0, uploaded_by: 'u-1', uploader_handle: 'test_handle', avg_rating: 0, total_ratings: 0, created_at: '2026-01-01' },
        ],
      }],
      error: null,
    })
    renderPage('prague', 'audio-poi')

    await waitFor(() => {
      expect(screen.getByText('Guide One')).toBeInTheDocument()
    })
    expect(screen.queryByText('Rate')).not.toBeInTheDocument()
    // Uploader handle is shown to everyone (public info)
    expect(screen.getByText('@test_handle')).toBeInTheDocument()
  })

  it('sorts preferred language first', async () => {
    // i18n.language defaults to 'en' in test environment
    mockRpc.mockResolvedValueOnce({
      data: [{
        ...BASE_POI,
        audio_guides: [
          { id: 'ag-1', lang_code: 'cs', title: 'Czech First', duration_sec: 60, sort_order: 0, uploaded_by: null, uploader_handle: null, avg_rating: 0, total_ratings: 0, created_at: '2026-01-01' },
          { id: 'ag-2', lang_code: 'en', title: 'English First', duration_sec: 120, sort_order: 0, uploaded_by: null, uploader_handle: null, avg_rating: 0, total_ratings: 0, created_at: '2026-01-01' },
        ],
      }],
      error: null,
    })
    renderPage()

    await waitFor(() => {
      expect(screen.getByText('English First')).toBeInTheDocument()
    })
    // English section should appear before Czech — find audio guide lang sections
    // Use px-3 to distinguish from TabsTrigger elements which also have rounded-md border
    const allLangSections = document.querySelectorAll('.rounded-md.border.px-3')
    const langOrder = Array.from(allLangSections).map(el => el.querySelector('.font-medium')?.textContent || '')
    expect(langOrder[0]).toContain('English')
    expect(langOrder[1]).toContain('Czech')
  })
})
