import { describe, it, expect, vi, beforeEach } from 'vitest'
import { render, screen, waitFor, fireEvent } from '@testing-library/react'
import { MemoryRouter, Route, Routes } from 'react-router-dom'
import CityPricingPage from '@/pages/cities/CityPricingPage'

const mockAdminSelect = vi.hoisted(() => vi.fn())
const mockAdminUpdate = vi.hoisted(() => vi.fn())
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

vi.mock('react-i18next', () => ({
  useTranslation: () => ({
    t: (k: string, opts?: Record<string, string>) => {
      const map: Record<string, string> = {
        'cityPages.pricingTitle': `Pricing — ${opts?.name ?? ''}`,
        'cityPages.cityAccessPrice': 'City Access Price',
        'cityPages.priceEurLabel': 'Price (EUR)',
        'cityPages.editViaCity': 'Edit in city settings',
        'cityPages.premiumBundle': 'Premium Bundle',
        'cityPages.premiumBundlePrice': 'Premium Bundle Price',
        'cityPages.premiumBundleDesc': 'Bundle price description',
        'cityPages.freeSamplePoi': 'Free Sample POI',
        'cityPages.nonePoi': '-- None --',
        'cityPages.premiumPois': `Premium POIs (${opts?.count ?? 0})`,
        'cityPages.savePricing': 'Save Pricing',
        'cityPages.pricingUpdated': 'Pricing updated',
        'cityPages.cityNotFound': 'City not found',
        'cityForm.saving': 'Saving...',
        'cityForm.price': 'Price',
        'common.name': 'Name',
      }
      return map[k] || k
    },
    i18n: { language: 'en', changeLanguage: vi.fn() },
  }),
}))

const mockCity = {
  id: 'city-1',
  name: 'Prague',
  country: 'CZ',
  country_code: 'CZ',
  latitude: 50.08,
  longitude: 14.42,
  bounding_box_radius_km: 10,
  price_eur: 3.99,
  is_active: true,
  slug: 'prague',
  registered_sample_poi_id: null,
  premium_bundle_price: 9.99,
  created_at: '2024-01-01',
  updated_at: '2024-01-01',
}

const mockPois = [
  {
    id: 'poi-1',
    name: { cs: 'Karlův most', en: 'Charles Bridge' },
    access_level: 'premium_poi',
    premium_price: 2.99,
  },
  {
    id: 'poi-2',
    name: { cs: 'Staroměstské náměstí', en: 'Old Town Square' },
    access_level: 'city_access',
    premium_price: null,
  },
]

function setupMocks(city = mockCity, pois = mockPois) {
  mockAdminSelect.mockImplementation((table: string) => {
    if (table === 'cities') {
      return Promise.resolve({ data: city, error: null })
    }
    if (table === 'pois') {
      return Promise.resolve({ data: pois, error: null })
    }
    return Promise.resolve({ data: null, error: null })
  })
}

function renderPage(cityId = 'city-1') {
  return render(
    <MemoryRouter initialEntries={[`/admin/cities/${cityId}/pricing`]}>
      <Routes>
        <Route path="/admin/cities/:cityId/pricing" element={<CityPricingPage />} />
      </Routes>
    </MemoryRouter>
  )
}

describe('CityPricingPage', () => {
  beforeEach(() => {
    vi.clearAllMocks()
  })

  it('loads city and POIs in parallel', async () => {
    setupMocks()
    renderPage()

    await waitFor(() => {
      expect(screen.getByText(/Pricing — Prague/)).toBeInTheDocument()
    })

    // Both adminSelect calls should have been made
    expect(mockAdminSelect).toHaveBeenCalledWith('cities', expect.any(Object))
    expect(mockAdminSelect).toHaveBeenCalledWith('pois', expect.any(Object))
  })

  it('price_eur shown as read-only', async () => {
    setupMocks()
    renderPage()

    await waitFor(() => {
      expect(screen.getByText(/Pricing — Prague/)).toBeInTheDocument()
    })

    const priceInput = screen.getByDisplayValue('3.99')
    expect(priceInput).toBeDisabled()
  })

  it('premium_bundle_price editable', async () => {
    setupMocks()
    renderPage()

    await waitFor(() => {
      expect(screen.getByText(/Pricing — Prague/)).toBeInTheDocument()
    })

    const bundleInput = screen.getByDisplayValue('9.99')
    expect(bundleInput).not.toBeDisabled()

    fireEvent.change(bundleInput, { target: { value: '14.99' } })
    expect(bundleInput).toHaveValue(14.99)
  })

  it('save sends adminUpdate', async () => {
    setupMocks()
    mockAdminUpdate.mockResolvedValue({ error: null })
    renderPage()

    await waitFor(() => {
      expect(screen.getByText(/Pricing — Prague/)).toBeInTheDocument()
    })

    const saveButton = screen.getByRole('button', { name: /Save Pricing/i })
    fireEvent.click(saveButton)

    await waitFor(() => {
      expect(mockAdminUpdate).toHaveBeenCalledWith(
        'cities',
        { premium_bundle_price: 9.99, registered_sample_poi_id: null },
        [{ column: 'id', op: 'eq', value: 'city-1' }]
      )
    })
    expect(mockToastSuccess).toHaveBeenCalledWith('Pricing updated')
  })

  it('empty bundlePrice saves as null', async () => {
    setupMocks({ ...mockCity, premium_bundle_price: null as unknown as number })
    mockAdminUpdate.mockResolvedValue({ error: null })
    renderPage()

    await waitFor(() => {
      expect(screen.getByText(/Pricing — Prague/)).toBeInTheDocument()
    })

    const saveButton = screen.getByRole('button', { name: /Save Pricing/i })
    fireEvent.click(saveButton)

    await waitFor(() => {
      expect(mockAdminUpdate).toHaveBeenCalledWith(
        'cities',
        { premium_bundle_price: null, registered_sample_poi_id: null },
        [{ column: 'id', op: 'eq', value: 'city-1' }]
      )
    })
  })
})
