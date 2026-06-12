import { describe, it, expect, vi, beforeEach } from 'vitest'
import { render, screen } from '@testing-library/react'
import { MemoryRouter, Routes, Route } from 'react-router-dom'

const mockFrom = vi.hoisted(() => vi.fn())

vi.mock('@/lib/supabase/client', () => ({ supabase: { from: mockFrom } }))
vi.mock('react-i18next', () => ({
  useTranslation: () => ({ t: (k: string, d?: string) => d || k, i18n: { language: 'en' } }),
}))

import CitiesCatalogPage from '@/pages/account/CitiesCatalogPage'
import CityPlacesPage from '@/pages/account/CityPlacesPage'

// A query-builder stub that is both chainable and thenable, and resolves
// maybeSingle() to the first row. Works for `.order().then()` and `await ...order()`.
function makeThenable(rows: unknown[]) {
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  const chain: any = {
    select: () => chain,
    eq: () => chain,
    order: () => chain,
    maybeSingle: () => Promise.resolve({ data: rows[0] ?? null }),
    then: (cb: (v: { data: unknown[] }) => void) => {
      cb({ data: rows })
      return Promise.resolve({ data: rows })
    },
  }
  return chain
}

describe('CitiesCatalogPage', () => {
  beforeEach(() => vi.clearAllMocks())

  it('renders active cities', async () => {
    mockFrom.mockReturnValue(makeThenable([{ id: 'c1', name: 'Prague', country_code: 'CZ', slug: 'prague' }]))
    render(<MemoryRouter><CitiesCatalogPage /></MemoryRouter>)
    expect(await screen.findByText('Prague')).toBeInTheDocument()
    expect(screen.getByText('CZ')).toBeInTheDocument()
  })
})

describe('CityPlacesPage', () => {
  beforeEach(() => vi.clearAllMocks())

  it('renders the city name and its places', async () => {
    mockFrom.mockImplementation((table: string) =>
      table === 'cities'
        ? makeThenable([{ id: 'c1', name: 'Prague' }])
        : makeThenable([{
            id: 'p1',
            name: { en: 'Charles Bridge' },
            slug: 'charles-bridge',
            perex: null,
            access_level: 'public',
            avg_rating: 4.5,
            total_ratings: 3,
            photo_urls: [],
          }])
    )
    render(
      <MemoryRouter initialEntries={['/account/cities/cz/prague']}>
        <Routes>
          <Route path="/account/cities/:countryCode/:citySlug" element={<CityPlacesPage />} />
        </Routes>
      </MemoryRouter>
    )
    expect(await screen.findByText('Prague')).toBeInTheDocument()
    expect(await screen.findByText('Charles Bridge')).toBeInTheDocument()
  })
})
