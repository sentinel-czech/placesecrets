import { describe, it, expect, vi, beforeEach } from 'vitest'
import { render, screen, fireEvent, waitFor } from '@testing-library/react'
import { MemoryRouter } from 'react-router-dom'

const mockRpc = vi.hoisted(() => vi.fn())

vi.mock('@/lib/supabase/client', () => ({
  supabase: { rpc: mockRpc },
}))

vi.mock('react-i18next', () => ({
  useTranslation: () => ({ t: (k: string, d?: string) => d || k, i18n: { language: 'en' } }),
}))

import SearchPage from '@/pages/account/SearchPage'

function renderPage(initial = '/account/search') {
  return render(
    <MemoryRouter initialEntries={[initial]}>
      <SearchPage />
    </MemoryRouter>
  )
}

const sampleResult = {
  id: '1',
  name: { en: 'Charles Bridge' },
  slug: 'charles-bridge',
  perex: null,
  access_level: 'public',
  avg_rating: 4.5,
  total_ratings: 5,
  photo_urls: [],
  city_slug: 'prague',
  country_code: 'CZ',
}

describe('SearchPage', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    mockRpc.mockResolvedValue({ data: [sampleResult], error: null })
  })

  it('loads featured results via search_pois on mount', async () => {
    renderPage()
    expect(await screen.findByText('Charles Bridge')).toBeInTheDocument()
    expect(mockRpc).toHaveBeenCalledWith('search_pois', expect.objectContaining({ p_limit: 30 }))
  })

  it('re-searches with the typed query', async () => {
    renderPage()
    await screen.findByText('Charles Bridge')
    fireEvent.change(screen.getByPlaceholderText(/Search places/i), { target: { value: 'bridge' } })
    await waitFor(() =>
      expect(mockRpc).toHaveBeenCalledWith('search_pois', { p_query: 'bridge', p_limit: 30 })
    )
  })

  it('seeds the input from the ?q query param', async () => {
    renderPage('/account/search?q=castle')
    const input = screen.getByPlaceholderText(/Search places/i) as HTMLInputElement
    expect(input.value).toBe('castle')
    await screen.findByText('Charles Bridge')
    expect(mockRpc).toHaveBeenCalledWith('search_pois', { p_query: 'castle', p_limit: 30 })
  })
})
