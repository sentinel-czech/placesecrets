import { describe, it, expect, vi, beforeEach } from 'vitest'
import { render, screen } from '@testing-library/react'
import { MemoryRouter } from 'react-router-dom'

const mockAuthState = {
  user: null,
  role: null,
  loading: false,
  signInWithOAuth: vi.fn(),
  signIn: vi.fn(),
  signOut: vi.fn(),
  setAdminVerified: vi.fn(),
  initialize: vi.fn(),
  contributorId: null,
  displayName: null,
  isVerified: false,
  adminVerified: false,
}

vi.mock('@/hooks/useAuth', () => ({
  useAuthStore: vi.fn((selector?: (s: typeof mockAuthState) => unknown) =>
    selector ? selector(mockAuthState) : mockAuthState
  ),
}))

vi.mock('react-i18next', () => ({
  useTranslation: () => ({
    t: (k: string, d?: string) => {
      const map: Record<string, string> = {
        'landing.tagline': 'Audio-guided discovery',
        'landing.heroTitle1': 'Discover the',
        'landing.heroTitle2': 'Hidden Stories',
        'landing.heroTitle3': 'Behind Every Place',
        'landing.heroSubtitle': 'Explore cities through immersive audio guides.',
        'landing.explorePlaces': 'Explore Places',
        'landing.getStartedFree': 'Get Started Free',
        'landing.cities': 'Cities',
        'landing.places': 'Places',
        'landing.audioGuides': 'Audio Guides',
        'landing.exploreAround': 'Explore Places Around You',
        'landing.exploreAroundDesc': 'Browse the interactive map to find interesting places near you.',
        'landing.loadingMap': 'Loading map...',
        'landing.signInToExplore': 'Sign in to unlock all features',
        'landing.or': 'or',
        'landing.registerWithEmail': 'Register with Email',
        'landing.featuredPlaces': 'Featured Places',
        'landing.featuredPlacesDesc': 'Hand-picked places with the best audio guides.',
        'landing.free': 'Free',
        'landing.cityPass': 'City Pass',
        'landing.premium': 'Premium',
        'landing.reviews': 'reviews',
        'landing.listenToGuide': 'Listen to Guide',
        'landing.howItWorks': 'How It Works',
        'landing.howItWorksDesc': 'Three simple steps to start exploring.',
        'landing.step1Title': 'Discover Places',
        'landing.step1Desc': 'Find interesting places on the map or browse by city.',
        'landing.step2Title': 'Listen to Stories',
        'landing.step2Desc': 'Play audio guides created by local experts.',
        'landing.step3Title': 'Rate & Contribute',
        'landing.step3Desc': 'Share your experience and help others discover hidden gems.',
        'landing.whatPeopleSay': 'What People Say',
        'landing.readyToExplore': 'Ready to Explore?',
        'landing.readyToExploreDesc': 'Join thousands discovering hidden stories.',
        'landing.goToDashboard': 'Go to Dashboard',
        'landing.registerWithEmailCta': 'Register with Email',
        'landing.downloadDesc': 'Download the mobile app for the best experience.',
        'landing.getItOn': 'GET IT ON',
        'landing.googlePlay': 'Google Play',
        'landing.downloadOnThe': 'Download on the',
        'landing.appStore': 'App Store',
        'landing.comingSoon': 'Coming soon',
      }
      return map[k] || d || k
    },
    i18n: { language: 'en' },
  }),
}))

const mockChainable = {
  select: vi.fn().mockReturnThis(),
  eq: vi.fn().mockReturnThis(),
  order: vi.fn().mockReturnThis(),
  maybeSingle: vi.fn().mockResolvedValue({ data: null }),
  single: vi.fn().mockResolvedValue({ data: null, count: 0 }),
  then: vi.fn((cb: (v: { data: null; count: 0 }) => void) => { cb({ data: null, count: 0 }); return Promise.resolve({ data: null, count: 0 }); }),
}

vi.mock('@/lib/supabase/client', () => ({
  supabase: {
    auth: { getSession: vi.fn().mockResolvedValue({ data: { session: null } }) },
    from: vi.fn(() => mockChainable),
    rpc: vi.fn().mockResolvedValue({
      data: [{
        id: 'p1',
        name: { en: 'Test Place', cs: 'Test Place' },
        slug: 'test-place',
        perex: { en: 'A nice place' },
        access_level: 'public',
        avg_rating: 4.5,
        total_ratings: 10,
        photo_urls: [],
        city_slug: 'prague',
        country_code: 'CZ',
      }],
      error: null,
    }),
  },
}))

// Mock the lazy-loaded map component since leaflet doesn't work in jsdom
vi.mock('@/components/landing/LandingMapSection', () => ({
  default: () => <div data-testid="landing-map">Map Section</div>,
}))

import LandingPage from '@/pages/LandingPage'

function renderPage() {
  return render(
    <MemoryRouter>
      <LandingPage />
    </MemoryRouter>
  )
}

describe('LandingPage', () => {
  beforeEach(() => {
    vi.clearAllMocks()
  })

  it('renders hero heading', () => {
    renderPage()

    expect(screen.getAllByText(/Hidden Stories/i).length).toBeGreaterThanOrEqual(1)
    expect(screen.getAllByText(/Behind Every Place/i).length).toBeGreaterThanOrEqual(1)
  })

  it('has sign in link', () => {
    renderPage()

    const signInButtons = screen.getAllByText(/sign in/i)
    expect(signInButtons.length).toBeGreaterThan(0)
  })

  it('has register link', () => {
    renderPage()

    const registerLinks = screen.getAllByText(/register/i)
    expect(registerLinks.length).toBeGreaterThan(0)
  })

  it('renders how-it-works section with 3 features', () => {
    renderPage()

    expect(screen.getAllByText('How It Works').length).toBeGreaterThanOrEqual(1)
    expect(screen.getByText('Discover Places')).toBeInTheDocument()
    expect(screen.getByText('Listen to Stories')).toBeInTheDocument()
    expect(screen.getByText('Rate & Contribute')).toBeInTheDocument()
  })

  it('renders explore section', () => {
    renderPage()

    expect(screen.getByText(/Explore Places Around You/i)).toBeInTheDocument()
  })

  it('renders download section', () => {
    renderPage()

    // "Take Place<span>Secrets</span> With You" is split by a span element,
    // so use a function matcher to check the h2 text content
    expect(screen.getByText((_content, element) =>
      element?.tagName === 'H2' && /Take Place.*Secrets.*With You/i.test(element.textContent || '')
    )).toBeInTheDocument()
    expect(screen.getByText(/Google Play/i)).toBeInTheDocument()
    expect(screen.getByText(/App Store/i)).toBeInTheDocument()
  })

  it('renders featured places section with places from search_pois', async () => {
    renderPage()

    expect(screen.getByText(/Featured Places/i)).toBeInTheDocument()
    expect(await screen.findByText('Test Place')).toBeInTheDocument()
  })

  it('renders social auth buttons', () => {
    renderPage()

    // Social auth buttons should appear (Google, Facebook, Apple)
    expect(screen.getAllByText(/Google/i).length).toBeGreaterThanOrEqual(1)
  })

  it('renders testimonials section', () => {
    renderPage()

    expect(screen.getByText(/What People Say/i)).toBeInTheDocument()
  })

  it('renders footer', () => {
    renderPage()

    expect(screen.getByText(/All rights reserved/i)).toBeInTheDocument()
  })
})
