import { describe, it, expect, vi, beforeEach } from 'vitest'
import { render, screen, waitFor, fireEvent } from '@testing-library/react'
import { CityForm } from '@/components/cities/CityForm'
import type { City, Country } from '@/lib/supabase/types'

vi.mock('react-i18next', () => ({
  useTranslation: () => ({
    t: (k: string, d?: string | Record<string, unknown>) => (typeof d === 'string' ? d : k),
    i18n: { language: 'en', changeLanguage: vi.fn() },
  }),
}))

vi.mock('@/components/shared/MapPicker', () => ({
  MapPicker: () => <div data-testid="map-picker" />,
}))

vi.mock('@/components/shared/TagInput', () => ({
  TagInput: ({ value, onChange }: { value: string[]; onChange: (v: string[]) => void }) => (
    <div data-testid="tag-input">{(value || []).join(',')}</div>
  ),
}))

const mockCountries: Country[] = [
  { code: 'CZ', name: 'Czech Republic', aliases: [], created_at: '', updated_at: '' },
  { code: 'DE', name: 'Germany', aliases: [], created_at: '', updated_at: '' },
]

const mockCity: City = {
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
  aliases: ['Praha', 'Prag'],
  created_at: '2024-01-01',
  updated_at: '2024-01-01',
} as City

describe('CityForm', () => {
  let mockOnSubmit: ReturnType<typeof vi.fn>

  beforeEach(() => {
    vi.clearAllMocks()
    mockOnSubmit = vi.fn().mockResolvedValue(undefined)
  })

  it('renders all fields (name, country, lat, lng, radius, price, active)', () => {
    render(<CityForm countries={mockCountries} onSubmit={mockOnSubmit} />)

    expect(screen.getByText('cityForm.name')).toBeInTheDocument()
    expect(screen.getByText('cityForm.country')).toBeInTheDocument()
    expect(screen.getByText('cityForm.latitude')).toBeInTheDocument()
    expect(screen.getByText('cityForm.longitude')).toBeInTheDocument()
    expect(screen.getByText('cityForm.radius')).toBeInTheDocument()
    expect(screen.getByText('cityForm.price')).toBeInTheDocument()
    expect(screen.getByText('cityForm.active')).toBeInTheDocument()
    expect(screen.getByTestId('map-picker')).toBeInTheDocument()

    // Country dropdown should have both options
    const select = document.querySelector('select') as HTMLSelectElement
    expect(select.options).toHaveLength(2)
    expect(select.options[0].textContent).toContain('Czech Republic')
    expect(select.options[1].textContent).toContain('Germany')
  })

  it('validation: empty name shows error', async () => {
    render(<CityForm countries={mockCountries} onSubmit={mockOnSubmit} />)

    // Clear the name field (it defaults to empty for new form)
    const nameInput = document.querySelector('input[name="name"]') as HTMLInputElement
    fireEvent.change(nameInput, { target: { value: '' } })

    // Submit the form
    const submitBtn = screen.getByText('cityForm.createCity')
    fireEvent.click(submitBtn)

    await waitFor(() => {
      expect(screen.getByText('Name is required')).toBeInTheDocument()
    })

    expect(mockOnSubmit).not.toHaveBeenCalled()
  })

  it('submit calls onSubmit with all form data', async () => {
    render(<CityForm countries={mockCountries} onSubmit={mockOnSubmit} />)

    // Fill in the name
    const nameInput = document.querySelector('input[name="name"]') as HTMLInputElement
    fireEvent.change(nameInput, { target: { value: 'Brno' } })

    // Submit the form
    const submitBtn = screen.getByText('cityForm.createCity')
    fireEvent.click(submitBtn)

    await waitFor(() => {
      expect(mockOnSubmit).toHaveBeenCalledTimes(1)
    })

    const submittedData = mockOnSubmit.mock.calls[0][0]
    expect(submittedData).toEqual(expect.objectContaining({
      name: 'Brno',
      country_code: 'CZ',
      latitude: expect.any(Number),
      longitude: expect.any(Number),
      bounding_box_radius_km: expect.any(Number),
      price_eur: expect.any(Number),
      is_active: true,
      aliases: [],
    }))
  })

  it('initial values populate correctly (edit mode)', () => {
    render(
      <CityForm initial={mockCity} countries={mockCountries} onSubmit={mockOnSubmit} />,
    )

    const nameInput = document.querySelector('input[name="name"]') as HTMLInputElement
    expect(nameInput.value).toBe('Prague')

    const countrySelect = document.querySelector('select') as HTMLSelectElement
    expect(countrySelect.value).toBe('CZ')

    const latInput = document.querySelector('input[name="latitude"]') as HTMLInputElement
    expect(Number(latInput.value)).toBe(50.08)

    const lngInput = document.querySelector('input[name="longitude"]') as HTMLInputElement
    expect(Number(lngInput.value)).toBe(14.42)

    const radiusInput = document.querySelector('input[name="bounding_box_radius_km"]') as HTMLInputElement
    expect(Number(radiusInput.value)).toBe(10)

    const priceInput = document.querySelector('input[name="price_eur"]') as HTMLInputElement
    expect(Number(priceInput.value)).toBe(3.99)

    const activeCheckbox = document.getElementById('is_active') as HTMLInputElement
    expect(activeCheckbox.checked).toBe(true)

    // Aliases from initial should be passed to TagInput
    expect(screen.getByTestId('tag-input')).toHaveTextContent('Praha,Prag')
  })

  it('submit button text changes for create vs update', () => {
    const { rerender } = render(
      <CityForm countries={mockCountries} onSubmit={mockOnSubmit} />,
    )

    // Create mode
    expect(screen.getByText('cityForm.createCity')).toBeInTheDocument()
    expect(screen.queryByText('cityForm.updateCity')).not.toBeInTheDocument()

    // Edit mode
    rerender(
      <CityForm initial={mockCity} countries={mockCountries} onSubmit={mockOnSubmit} />,
    )

    expect(screen.getByText('cityForm.updateCity')).toBeInTheDocument()
    expect(screen.queryByText('cityForm.createCity')).not.toBeInTheDocument()
  })
})
