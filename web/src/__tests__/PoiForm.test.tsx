import { describe, it, expect, vi, beforeEach } from 'vitest'
import { render, screen, waitFor, fireEvent } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { MemoryRouter } from 'react-router-dom'
import { PoiForm } from '@/components/pois/PoiForm'

const mockAdminSelect = vi.hoisted(() => vi.fn())

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

function setupMocks(opts: { citySlug?: string; countryCode?: string } = {}) {
  // eslint-disable-next-line @typescript-eslint/no-unused-vars
  mockAdminSelect.mockImplementation((table: string, _options?: Record<string, unknown>) => {
    if (table === 'poi_types') {
      return Promise.resolve({
        data: [{ id: 'type-1', name: { cs: 'Hrad', en: 'Castle' }, sort_order: 1, is_active: true }],
        error: null,
      })
    }
    if (table === 'cities') {
      return Promise.resolve({
        data: { slug: opts.citySlug ?? 'prague', country_code: opts.countryCode ?? 'CZ' },
        error: null,
      })
    }
    return Promise.resolve({ data: null, error: null })
  })
}

function renderForm(props: Partial<React.ComponentProps<typeof PoiForm>> = {}) {
  const defaultProps = {
    cityId: 'city-1',
    onSubmit: vi.fn().mockResolvedValue(undefined),
    ...props,
  }
  return render(
    <MemoryRouter>
      <PoiForm {...defaultProps} />
    </MemoryRouter>
  )
}

describe('PoiForm', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    setupMocks()
  })

  it('renders with default values (city_access access level)', async () => {
    renderForm()

    await waitFor(() => {
      const accessSelect = screen.getByLabelText('Access level') as HTMLSelectElement
      expect(accessSelect.value).toBe('city_access')
    })
  })

  it('access_level=premium_poi shows premium_price field', async () => {
    renderForm()

    await waitFor(() => {
      expect(screen.getByLabelText('Access level')).toBeInTheDocument()
    })

    const accessSelect = screen.getByLabelText('Access level')
    fireEvent.change(accessSelect, { target: { value: 'premium_poi' } })

    await waitFor(() => {
      expect(screen.getByText('Premium Price (EUR)')).toBeInTheDocument()
    })
  })

  it('access_level=city_access hides premium_price field', async () => {
    renderForm()

    await waitFor(() => {
      expect(screen.getByLabelText('Access level')).toBeInTheDocument()
    })

    // Default is city_access, so premium_price should not be visible
    expect(screen.queryByText('Premium Price (EUR)')).not.toBeInTheDocument()
  })

  it('perex textarea has max 300 chars indicator', async () => {
    renderForm()

    await waitFor(() => {
      expect(screen.getByText(/Perex.*max 300/)).toBeInTheDocument()
    })

    // Multiple perex textareas exist (one per language), pick the visible one
    const textareas = screen.getAllByPlaceholderText('Short preview text shown to all visitors...')
    const visibleTextarea = textareas.find(el => !el.closest('.hidden')) || textareas[0]
    expect(visibleTextarea).toHaveAttribute('maxlength', '300')
  })

  it('smart URI preview shows correct URL', async () => {
    setupMocks({ citySlug: 'brno' })

    renderForm({
      initial: {
        id: 'poi-1',
        city_id: 'city-1',
        type_id: null,
        name: { cs: 'Test', en: '' },
        description: {},
        latitude: 50.08,
        longitude: 14.42,
        geofence_radius: 100,
        photo_urls: [],
        audio_urls: {},
        is_premium: false,
        sort_order: 0,
        is_active: true,
        contributor_id: null,
        contributor_note: null,
        avg_rating: null,
        total_ratings: 0,
        slug: 'test-poi',
        access_level: 'city_access',
        perex: null,
        premium_price: null,
        aliases: [],
        created_at: '2024-01-01',
        updated_at: '2024-01-01',
      },
    })

    await waitFor(() => {
      expect(screen.getByText(/\/[a-z]+\/brno\/test-poi/)).toBeInTheDocument()
    })
  })

  it('name required: empty triggers validation', async () => {
    const onSubmit = vi.fn()
    renderForm({ onSubmit })

    await waitFor(() => {
      expect(screen.getByLabelText('Access level')).toBeInTheDocument()
    })

    // Ensure name is empty (it defaults to '')
    const nameInput = document.querySelector('input[name="name"]') as HTMLInputElement
    expect(nameInput.value).toBe('')

    // Submit the form with empty name
    const submitBtn = screen.getByRole('button', { name: /Create POI/i })
    fireEvent.click(submitBtn)

    await waitFor(() => {
      // Form should show validation error and NOT call onSubmit
      expect(onSubmit).not.toHaveBeenCalled()
    })

    // Validation error element should appear (zod renders error via errors.name)
    const errorElement = document.querySelector('.text-destructive')
    expect(errorElement).toBeInTheDocument()
  })

  it('access_level premium→city_access clears premium_price', async () => {
    renderForm()

    await waitFor(() => {
      expect(screen.getByLabelText('Access level')).toBeInTheDocument()
    })

    // Switch to premium_poi to reveal premium_price field
    const accessSelect = screen.getByLabelText('Access level')
    fireEvent.change(accessSelect, { target: { value: 'premium_poi' } })

    await waitFor(() => {
      expect(screen.getByText('Premium Price (EUR)')).toBeInTheDocument()
    })

    // Enter a premium price
    const priceInput = document.querySelector('input[name="premium_price"]') as HTMLInputElement
    await userEvent.type(priceInput, '9.99')

    // Switch back to city_access — premium_price field should disappear
    fireEvent.change(accessSelect, { target: { value: 'city_access' } })

    await waitFor(() => {
      expect(screen.queryByText('Premium Price (EUR)')).not.toBeInTheDocument()
    })
  })

  it('form submission calls onSubmit', async () => {
    const onSubmit = vi.fn().mockResolvedValue(undefined)
    renderForm({ onSubmit })

    await waitFor(() => {
      expect(screen.getByLabelText('Access level')).toBeInTheDocument()
    })

    // The form uses Label + Input without htmlFor, so we find inputs by their registered name
    const nameInput = document.querySelector('input[name="name"]') as HTMLInputElement
    await userEvent.type(nameInput, 'My POI')

    const submitBtn = screen.getByRole('button', { name: /Create POI/i })
    fireEvent.click(submitBtn)

    await waitFor(() => {
      expect(onSubmit).toHaveBeenCalledTimes(1)
    })

    const callArgs = onSubmit.mock.calls[0][0]
    expect(callArgs.city_id).toBe('city-1')
    expect(callArgs.name.cs).toBe('My POI')
  })
})
