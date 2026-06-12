import { describe, it, expect, vi, beforeEach } from 'vitest'
import { render, screen, waitFor, fireEvent } from '@testing-library/react'
import { MemoryRouter, Route, Routes } from 'react-router-dom'
import CityNewPage from '@/pages/cities/CityNewPage'
import CityEditPage from '@/pages/cities/CityEditPage'

const mockAdminSelect = vi.hoisted(() => vi.fn())
const mockAdminInsert = vi.hoisted(() => vi.fn())
const mockAdminUpdate = vi.hoisted(() => vi.fn())
const mockToastSuccess = vi.hoisted(() => vi.fn())
const mockToastError = vi.hoisted(() => vi.fn())
const mockNavigate = vi.hoisted(() => vi.fn())

vi.mock('@/lib/supabase/admin-api', () => ({
  adminSelect: mockAdminSelect,
  adminInsert: mockAdminInsert,
  adminUpdate: mockAdminUpdate,
}))

vi.mock('@/lib/supabase/client', () => ({
  supabase: {
    auth: { getSession: vi.fn().mockResolvedValue({ data: { session: null } }) },
    from: vi.fn(),
    rpc: vi.fn(),
  },
}))

vi.mock('react-router-dom', async () => {
  const actual = await vi.importActual('react-router-dom')
  return {
    ...actual,
    useNavigate: () => mockNavigate,
  }
})

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

vi.mock('@/components/shared/MapPicker', () => ({
  MapPicker: () => <div data-testid="map-picker" />,
}))

vi.mock('@/components/shared/TagInput', () => ({
  TagInput: () => <div data-testid="tag-input" />,
}))

const mockCountries = [
  { code: 'CZ', name: 'Czech Republic', aliases: [], created_at: '', updated_at: '' },
  { code: 'DE', name: 'Germany', aliases: [], created_at: '', updated_at: '' },
]

const mockCity = {
  id: 'city-1',
  name: 'Prague',
  country_code: 'CZ',
  latitude: 50.08,
  longitude: 14.42,
  bounding_box_radius_km: 10,
  price_eur: 3.99,
  is_active: true,
  slug: 'prague',
  registered_sample_poi_id: null,
  premium_bundle_price: null,
  aliases: [],
  created_at: '2024-01-01',
  updated_at: '2024-01-01',
}

function renderNewPage() {
  return render(
    <MemoryRouter initialEntries={['/admin/cities/new']}>
      <Routes>
        <Route path="/admin/cities/new" element={<CityNewPage />} />
      </Routes>
    </MemoryRouter>,
  )
}

function renderEditPage(cityId = 'city-1') {
  return render(
    <MemoryRouter initialEntries={[`/admin/cities/${cityId}`]}>
      <Routes>
        <Route path="/admin/cities/:id" element={<CityEditPage />} />
      </Routes>
    </MemoryRouter>,
  )
}

describe('CityNewPage', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    mockAdminSelect.mockImplementation((table: string) => {
      if (table === 'countries') return Promise.resolve({ data: mockCountries, error: null })
      return Promise.resolve({ data: null, error: null })
    })
  })

  it('renders CityForm with heading', async () => {
    renderNewPage()

    await waitFor(() => {
      expect(screen.getByText('cityPages.newCity')).toBeInTheDocument()
    })

    // Form fields should be present
    expect(screen.getByText('cityForm.name')).toBeInTheDocument()
    expect(screen.getByText('cityForm.country')).toBeInTheDocument()
  })

  it('submit creates city via adminInsert and navigates to /admin/cities', async () => {
    mockAdminInsert.mockResolvedValue({ error: null })
    renderNewPage()

    await waitFor(() => {
      expect(screen.getByText('cityPages.newCity')).toBeInTheDocument()
    })

    // Fill in the name field (the form has default values for other fields)
    // The name input is the first text input inside the form
    const inputs = document.querySelectorAll('input[type="text"], input:not([type])')
    const nameField = inputs[0] as HTMLInputElement
    fireEvent.change(nameField, { target: { value: 'Brno' } })

    // Submit the form
    const submitBtn = screen.getByText('cityForm.createCity')
    fireEvent.click(submitBtn)

    await waitFor(() => {
      expect(mockAdminInsert).toHaveBeenCalledWith('cities', expect.objectContaining({
        name: 'Brno',
        country_code: 'CZ',
      }))
    })

    expect(mockToastSuccess).toHaveBeenCalledWith('cityPages.cityCreated')
    expect(mockNavigate).toHaveBeenCalledWith('/admin/cities')
  })

  it('error on submit shows toast error', async () => {
    mockAdminInsert.mockResolvedValue({ error: 'Duplicate city name' })
    renderNewPage()

    await waitFor(() => {
      expect(screen.getByText('cityPages.newCity')).toBeInTheDocument()
    })

    // Fill name so validation passes
    const inputs = document.querySelectorAll('input[type="text"], input:not([type])')
    fireEvent.change(inputs[0], { target: { value: 'Existing City' } })

    fireEvent.click(screen.getByText('cityForm.createCity'))

    await waitFor(() => {
      expect(mockToastError).toHaveBeenCalledWith('Duplicate city name')
    })

    expect(mockNavigate).not.toHaveBeenCalled()
  })
})

describe('CityEditPage', () => {
  beforeEach(() => {
    vi.clearAllMocks()
  })

  it('loads city by ID and populates form', async () => {
    mockAdminSelect.mockImplementation((table: string) => {
      if (table === 'cities') return Promise.resolve({ data: mockCity, error: null })
      if (table === 'countries') return Promise.resolve({ data: mockCountries, error: null })
      return Promise.resolve({ data: null, error: null })
    })
    renderEditPage()

    await waitFor(() => {
      expect(screen.getByText(/cityPages.editCity/)).toBeInTheDocument()
    })

    // Verify adminSelect was called with correct filter
    expect(mockAdminSelect).toHaveBeenCalledWith('cities', {
      filters: [{ column: 'id', op: 'eq', value: 'city-1' }],
      single: true,
    })

    // The form should be populated with the city's name
    const nameInput = document.querySelector('input[name="name"]') as HTMLInputElement
    expect(nameInput).toBeTruthy()
    expect(nameInput.value).toBe('Prague')
  })

  it('save calls adminUpdate with correct filters', async () => {
    mockAdminSelect.mockImplementation((table: string) => {
      if (table === 'cities') return Promise.resolve({ data: mockCity, error: null })
      if (table === 'countries') return Promise.resolve({ data: mockCountries, error: null })
      return Promise.resolve({ data: null, error: null })
    })
    mockAdminUpdate.mockResolvedValue({ error: null })
    renderEditPage()

    await waitFor(() => {
      expect(screen.getByText(/cityPages.editCity/)).toBeInTheDocument()
    })

    // Click the update button
    const submitBtn = screen.getByText('cityForm.updateCity')
    fireEvent.click(submitBtn)

    await waitFor(() => {
      expect(mockAdminUpdate).toHaveBeenCalledWith(
        'cities',
        expect.objectContaining({ name: 'Prague' }),
        [{ column: 'id', op: 'eq', value: 'city-1' }],
      )
    })

    expect(mockToastSuccess).toHaveBeenCalledWith('cityPages.cityUpdated')
    expect(mockNavigate).toHaveBeenCalledWith('/admin/cities')
  })

  it('not found shows message when city is null', async () => {
    mockAdminSelect.mockImplementation((table: string) => {
      if (table === 'cities') return Promise.resolve({ data: null, error: null })
      if (table === 'countries') return Promise.resolve({ data: mockCountries, error: null })
      return Promise.resolve({ data: null, error: null })
    })
    renderEditPage('nonexistent-id')

    await waitFor(() => {
      expect(screen.getByText('cityPages.cityNotFound')).toBeInTheDocument()
    })
  })
})
