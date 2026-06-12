import { describe, it, expect, vi, beforeEach } from 'vitest'
import { render, screen, waitFor, fireEvent } from '@testing-library/react'
import { MemoryRouter } from 'react-router-dom'
import CitiesPage from '@/pages/cities/CitiesPage'

const mockAdminSelect = vi.hoisted(() => vi.fn())
const mockAdminInsert = vi.hoisted(() => vi.fn())
const mockToastSuccess = vi.hoisted(() => vi.fn())
const mockToastError = vi.hoisted(() => vi.fn())
const mockHasPermission = vi.hoisted(() => vi.fn())

vi.mock('@/lib/supabase/admin-api', () => ({
  adminSelect: mockAdminSelect,
  adminInsert: mockAdminInsert,
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
    t: (k: string, d?: string | Record<string, unknown>) => (typeof d === 'string' ? d : k),
    i18n: { language: 'en', changeLanguage: vi.fn() },
  }),
}))

vi.mock('sonner', () => ({
  toast: {
    success: mockToastSuccess,
    error: mockToastError,
  },
}))

vi.mock('@/components/cities/CitiesMap', () => ({
  CitiesMap: ({ cities }: { cities: unknown[] }) => (
    <div data-testid="cities-map">Map ({cities.length} cities)</div>
  ),
}))

vi.mock('@/components/shared/CityPoiTree', () => ({
  __esModule: true,
  default: ({ cities, search }: { cities: unknown[]; search: string }) => (
    <div data-testid="city-poi-tree">
      Tree: {(cities as Array<{ name: string }>).map(c => c.name).join(', ')}
      {search && <span data-testid="tree-search">{search}</span>}
    </div>
  ),
}))

vi.mock('@/components/shared/TagInput', () => ({
  TagInput: () => <div data-testid="tag-input" />,
}))

const mockCities = [
  {
    id: 'city-1', name: 'Prague', country_code: 'CZ', latitude: 50.08, longitude: 14.42,
    bounding_box_radius_km: 10, price_eur: 3.99, is_active: true, slug: 'prague',
    registered_sample_poi_id: null, premium_bundle_price: null, aliases: [],
    created_at: '2024-01-01', updated_at: '2024-01-01',
  },
  {
    id: 'city-2', name: 'Brno', country_code: 'CZ', latitude: 49.19, longitude: 16.61,
    bounding_box_radius_km: 8, price_eur: 2.99, is_active: false, slug: 'brno',
    registered_sample_poi_id: null, premium_bundle_price: null, aliases: [],
    created_at: '2024-01-01', updated_at: '2024-01-01',
  },
]

const mockCountries = [
  { code: 'CZ', name: 'Czech Republic', aliases: [], created_at: '', updated_at: '' },
]

const mockPois = [
  { id: 'poi-1', name: { cs: 'Karlův most' }, city_id: 'city-1', is_active: true, access_level: 'city_access', type_id: null, sort_order: 1, aliases: [] },
]

function setupMocks() {
  mockAdminSelect.mockImplementation((table: string) => {
    if (table === 'cities') return Promise.resolve({ data: mockCities, error: null })
    if (table === 'countries') return Promise.resolve({ data: mockCountries, error: null })
    if (table === 'pois') return Promise.resolve({ data: mockPois, error: null })
    return Promise.resolve({ data: null, error: null })
  })
}

function renderPage() {
  return render(
    <MemoryRouter initialEntries={['/admin/cities']}>
      <CitiesPage />
    </MemoryRouter>,
  )
}

describe('CitiesPage', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    mockHasPermission.mockReturnValue(true)
  })

  it('loads cities, countries, and POIs on mount (3 adminSelect calls)', async () => {
    setupMocks()
    renderPage()

    await waitFor(() => {
      expect(screen.getByTestId('city-poi-tree')).toBeInTheDocument()
    })

    expect(mockAdminSelect).toHaveBeenCalledWith('cities', expect.any(Object))
    expect(mockAdminSelect).toHaveBeenCalledWith('countries', expect.any(Object))
    expect(mockAdminSelect).toHaveBeenCalledWith('pois', expect.any(Object))
    expect(mockAdminSelect).toHaveBeenCalledTimes(3)
  })

  it('search input filters display (debounced)', async () => {
    setupMocks()
    renderPage()

    await waitFor(() => {
      expect(screen.getByTestId('city-poi-tree')).toBeInTheDocument()
    })

    const searchInput = screen.getByPlaceholderText('Search countries, cities, places...')
    fireEvent.change(searchInput, { target: { value: 'Prague' } })

    // Before debounce fires, search should not have propagated
    expect(screen.queryByTestId('tree-search')).not.toBeInTheDocument()

    // Wait for the 200ms debounce to fire
    await waitFor(() => {
      expect(screen.getByTestId('tree-search')).toHaveTextContent('Prague')
    }, { timeout: 1000 })
  })

  it('toggle map visibility', async () => {
    setupMocks()
    renderPage()

    await waitFor(() => {
      expect(screen.getByTestId('cities-map')).toBeInTheDocument()
    })

    // Map is visible by default; click the toggle button to hide it
    const buttons = screen.getAllByRole('button')
    // Simpler approach: click the outline button that isn't Add Country or Add City
    // The map toggle has variant="outline" and size="sm"
    fireEvent.click(buttons[0]) // First button is the map toggle

    await waitFor(() => {
      expect(screen.queryByTestId('cities-map')).not.toBeInTheDocument()
    })

    // Click again to show map
    fireEvent.click(buttons[0])

    await waitFor(() => {
      expect(screen.getByTestId('cities-map')).toBeInTheDocument()
    })
  })

  it('Add Country button shows inline form (only if canWrite)', async () => {
    setupMocks()
    renderPage()

    await waitFor(() => {
      expect(screen.getByTestId('city-poi-tree')).toBeInTheDocument()
    })

    const addCountryBtn = screen.getByText('+ New Country')
    fireEvent.click(addCountryBtn)

    await waitFor(() => {
      expect(screen.getByText('admin.cities.countryCode')).toBeInTheDocument()
      expect(screen.getByText('admin.cities.countryName')).toBeInTheDocument()
    })
  })

  it('Add Country form submit calls adminInsert and shows success toast', async () => {
    setupMocks()
    mockAdminInsert.mockResolvedValue({ error: null })
    renderPage()

    await waitFor(() => {
      expect(screen.getByTestId('city-poi-tree')).toBeInTheDocument()
    })

    // Open the form
    fireEvent.click(screen.getByText('+ New Country'))

    await waitFor(() => {
      expect(screen.getByPlaceholderText('admin.cities.countryCodePlaceholder')).toBeInTheDocument()
    })

    const codeInput = screen.getByPlaceholderText('admin.cities.countryCodePlaceholder')
    const nameInput = screen.getByPlaceholderText('admin.cities.countryNamePlaceholder')

    fireEvent.change(codeInput, { target: { value: 'DE' } })
    fireEvent.change(nameInput, { target: { value: 'Germany' } })

    // Click Create button
    const createBtn = screen.getByText('Create')
    fireEvent.click(createBtn)

    await waitFor(() => {
      expect(mockAdminInsert).toHaveBeenCalledWith('countries', {
        code: 'DE',
        name: 'Germany',
        aliases: [],
      })
    })

    expect(mockToastSuccess).toHaveBeenCalledWith('admin.cities.countryCreated')
  })

  it('Add Country validation rejects code !== 2 chars', async () => {
    setupMocks()
    renderPage()

    await waitFor(() => {
      expect(screen.getByTestId('city-poi-tree')).toBeInTheDocument()
    })

    fireEvent.click(screen.getByText('+ New Country'))

    await waitFor(() => {
      expect(screen.getByPlaceholderText('admin.cities.countryCodePlaceholder')).toBeInTheDocument()
    })

    const codeInput = screen.getByPlaceholderText('admin.cities.countryCodePlaceholder')
    const nameInput = screen.getByPlaceholderText('admin.cities.countryNamePlaceholder')

    // Only 1 char code
    fireEvent.change(codeInput, { target: { value: 'D' } })
    fireEvent.change(nameInput, { target: { value: 'Germany' } })

    const createBtn = screen.getByText('Create')
    // Button should be disabled because code is not 2 chars
    expect(createBtn.closest('button')).toBeDisabled()

    // Also, clicking should not call adminInsert
    fireEvent.click(createBtn)
    expect(mockAdminInsert).not.toHaveBeenCalled()
  })

  it('Add City button links to /admin/cities/new', async () => {
    setupMocks()
    renderPage()

    await waitFor(() => {
      expect(screen.getByTestId('city-poi-tree')).toBeInTheDocument()
    })

    const addCityLink = screen.getByText('admin.cities.addCity').closest('a')
    expect(addCityLink).toHaveAttribute('href', '/admin/cities/new')
  })

  it('error state shows error message', async () => {
    mockAdminSelect.mockImplementation((table: string) => {
      if (table === 'cities') return Promise.resolve({ data: null, error: 'Failed to load cities' })
      if (table === 'countries') return Promise.resolve({ data: [], error: null })
      if (table === 'pois') return Promise.resolve({ data: [], error: null })
      return Promise.resolve({ data: null, error: null })
    })
    renderPage()

    await waitFor(() => {
      expect(screen.getByText('Failed to load cities')).toBeInTheDocument()
    })
  })

  it('permission gating: canWrite=false hides Add buttons', async () => {
    mockHasPermission.mockReturnValue(false)
    setupMocks()
    renderPage()

    await waitFor(() => {
      expect(screen.getByTestId('city-poi-tree')).toBeInTheDocument()
    })

    expect(screen.queryByText('+ New Country')).not.toBeInTheDocument()
    expect(screen.queryByText('admin.cities.addCity')).not.toBeInTheDocument()
  })
})
