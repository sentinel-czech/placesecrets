import { describe, it, expect, vi } from 'vitest'
import { render, screen } from '@testing-library/react'
import { MemoryRouter } from 'react-router-dom'
import { PoiCard, poiHref, type PoiPreview } from '@/components/places/PoiCard'

vi.mock('react-i18next', () => ({
  useTranslation: () => ({
    t: (k: string, d?: string) => d || k,
    i18n: { language: 'en' },
  }),
}))

const poi: PoiPreview = {
  id: '1',
  name: { en: 'Charles Bridge', cs: 'Karlův most' },
  slug: 'charles-bridge',
  perex: { en: 'A famous medieval bridge.' },
  access_level: 'public',
  avg_rating: 4.8,
  total_ratings: 200,
  photo_urls: ['http://example.com/photo.jpg'],
  city_slug: 'prague',
  country_code: 'CZ',
}

function renderCard(p: PoiPreview) {
  return render(
    <MemoryRouter>
      <PoiCard poi={p} />
    </MemoryRouter>
  )
}

describe('PoiCard', () => {
  it('renders the localized name, perex and rating', () => {
    renderCard(poi)
    expect(screen.getByText('Charles Bridge')).toBeInTheDocument()
    expect(screen.getByText('A famous medieval bridge.')).toBeInTheDocument()
    expect(screen.getByText('4.8')).toBeInTheDocument()
  })

  it('links to the public place-detail route (lowercased country)', () => {
    renderCard(poi)
    const link = screen.getByRole('link')
    expect(link).toHaveAttribute('href', '/cz/prague/charles-bridge')
  })

  it('renders the photo when present', () => {
    renderCard(poi)
    const img = screen.getByRole('img') as HTMLImageElement
    expect(img.src).toContain('http://example.com/photo.jpg')
  })

  it('does not render a rating when there are no ratings', () => {
    renderCard({ ...poi, avg_rating: null, total_ratings: 0 })
    expect(screen.queryByText('4.8')).not.toBeInTheDocument()
  })

  it('poiHref returns null when slug parts are missing', () => {
    expect(poiHref({ country_code: 'CZ', city_slug: 'prague', slug: 'x' })).toBe('/cz/prague/x')
    expect(poiHref({ country_code: null, city_slug: 'prague', slug: 'x' })).toBeNull()
    expect(poiHref({ country_code: 'CZ', city_slug: 'prague', slug: null })).toBeNull()
  })
})
