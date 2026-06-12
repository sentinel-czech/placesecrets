import { describe, it, expect, vi, beforeEach } from 'vitest'
import { render, screen, waitFor } from '@testing-library/react'
import { MemoryRouter } from 'react-router-dom'
import AccountHistoryPage from '@/pages/account/AccountHistoryPage'
import AccountExplorePage from '@/pages/account/AccountExplorePage'

const mockUseAuthStore = vi.hoisted(() => vi.fn())

const mockPoiTypes = [
  { id: 'pt-1', name: { en: 'Castle', cs: 'Hrad' }, slug: 'castle', icon_name: 'castle', color_hex: '#FF0000', sort_order: 1, is_active: true, created_at: '2024-01-01', updated_at: '2024-01-01' },
  { id: 'pt-2', name: { en: 'Church', cs: 'Kostel' }, slug: 'church', icon_name: 'church', color_hex: '#0000FF', sort_order: 2, is_active: true, created_at: '2024-01-01', updated_at: '2024-01-01' },
]

const mockVisits = [
  {
    id: 'v-1',
    poi_id: 'poi-1',
    visited_at: '2024-06-15T10:00:00Z',
    pois: {
      name: { cs: 'Karlstejn', en: 'Karlstejn' },
      latitude: 49.94,
      longitude: 14.19,
      slug: 'karlstejn',
      type_id: 'pt-1',
      cities: { slug: 'beroun', country_code: 'CZ' },
      poi_types: { color_hex: '#FF0000', name: { en: 'Castle' } },
    },
  },
]

const mockCityPasses = [
  {
    id: 'ua-1',
    city_id: 'city-1',
    purchased_at: '2024-05-01T00:00:00Z',
    valid_until: null,
    cities: { name: 'Prague' },
  },
  {
    id: 'ua-2',
    city_id: 'city-2',
    purchased_at: '2024-04-01T00:00:00Z',
    valid_until: '2025-04-01T00:00:00Z',
    cities: { name: 'Brno' },
  },
]

function mockSupabaseFrom(table: string) {
  if (table === 'poi_types') {
    return {
      select: vi.fn().mockReturnValue({
        eq: vi.fn().mockReturnValue({
          order: vi.fn().mockResolvedValue({ data: mockPoiTypes }),
        }),
      }),
    }
  }
  if (table === 'free_visit_log') {
    return {
      select: vi.fn().mockReturnValue({
        eq: vi.fn().mockReturnValue({
          order: vi.fn().mockReturnValue({
            then: vi.fn().mockImplementation((cb: (res: { data: typeof mockVisits }) => void) => {
              cb({ data: mockVisits })
              return { catch: vi.fn() }
            }),
            gte: vi.fn().mockReturnValue({
              then: vi.fn().mockImplementation((cb: (res: { data: typeof mockVisits }) => void) => {
                cb({ data: mockVisits })
                return { catch: vi.fn() }
              }),
            }),
          }),
        }),
      }),
    }
  }
  if (table === 'user_access') {
    return {
      select: vi.fn().mockReturnValue({
        eq: vi.fn().mockReturnValue({
          order: vi.fn().mockResolvedValue({ data: mockCityPasses }),
        }),
      }),
    }
  }
  return {
    select: vi.fn().mockReturnValue({
      eq: vi.fn().mockReturnValue({
        order: vi.fn().mockResolvedValue({ data: [] }),
      }),
    }),
  }
}

vi.mock('@/hooks/useAuth', () => ({
  useAuthStore: mockUseAuthStore,
}))

vi.mock('@/lib/supabase/client', () => ({
  supabase: {
    auth: { getSession: vi.fn().mockResolvedValue({ data: { session: null } }) },
    from: vi.fn().mockImplementation(mockSupabaseFrom),
    rpc: vi.fn(),
    storage: { from: vi.fn() },
  },
}))

vi.mock('react-i18next', () => ({
  useTranslation: () => ({
    t: (k: string) => {
      const map: Record<string, string> = {
        'user.history.title': 'Visit History',
        'user.dashboard.stats.allTime': 'All Time',
        'user.dashboard.stats.last30d': 'Last 30 days',
        'user.dashboard.stats.last7d': 'Last 7 days',
        'user.history.customRange': 'Custom',
        'user.dashboard.stats.noVisits': 'No visits yet',
        'user.dashboard.myCityPasses': 'My City Passes',
        'user.dashboard.expired': 'Expired',
        'user.dashboard.purchased': 'Purchased',
        'user.dashboard.validUntil': 'Valid until',
        'common.active': 'Active',
        'common.loading': 'Loading...',
      }
      return map[k] || k
    },
    i18n: { language: 'en', changeLanguage: vi.fn() },
  }),
}))

vi.mock('sonner', () => ({ toast: { success: vi.fn(), error: vi.fn() } }))
vi.mock('@/components/account/StatsMap', () => ({
  StatsMap: () => <div data-testid="stats-map" />,
}))
vi.mock('@/components/account/PoiTypeFilter', () => ({
  PoiTypeFilter: ({ types }: { types: unknown[] }) => (
    <div data-testid="poi-type-filter">
      {types.map((t: unknown, i: number) => (
        <span key={i}>{((t as Record<string, unknown>).name as Record<string, string>)?.en}</span>
      ))}
    </div>
  ),
}))
vi.mock('@/components/account/VisitExport', () => ({
  VisitExport: () => <div data-testid="visit-export" />,
}))
vi.mock('@/components/account/ExploreMap', () => ({
  ExploreMap: () => <div data-testid="explore-map" />,
}))

function defaultAuthStore() {
  return {
    user: { id: 'u-1', email: 'test@example.com' },
    role: 'user',
    displayName: null,
    isVerified: false,
    userNumber: null,
    needsHandle: false,
  }
}

describe('AccountHistoryPage', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    mockUseAuthStore.mockReturnValue(defaultAuthStore())
  })

  it('loads visit history and renders title', async () => {
    render(
      <MemoryRouter>
        <AccountHistoryPage />
      </MemoryRouter>
    )
    expect(screen.getByText('Visit History')).toBeInTheDocument()
    await waitFor(() => {
      expect(screen.getByTestId('poi-type-filter')).toBeInTheDocument()
    })
  })

  it('renders time period filter buttons', () => {
    render(
      <MemoryRouter>
        <AccountHistoryPage />
      </MemoryRouter>
    )
    expect(screen.getByText('All Time')).toBeInTheDocument()
    expect(screen.getByText('Last 30 days')).toBeInTheDocument()
    expect(screen.getByText('Last 7 days')).toBeInTheDocument()
    expect(screen.getByText('Custom')).toBeInTheDocument()
  })
})

describe('AccountExplorePage', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    mockUseAuthStore.mockReturnValue(defaultAuthStore())
  })

  it('renders with purchased cities', async () => {
    render(
      <MemoryRouter>
        <AccountExplorePage />
      </MemoryRouter>
    )
    await waitFor(() => {
      expect(screen.getByText('Prague')).toBeInTheDocument()
    })
    expect(screen.getByText('Brno')).toBeInTheDocument()
    expect(screen.getByText('My City Passes')).toBeInTheDocument()
  })

  it('shows POI type filter via ExploreMap', async () => {
    render(
      <MemoryRouter>
        <AccountExplorePage />
      </MemoryRouter>
    )
    await waitFor(() => {
      expect(screen.getByTestId('explore-map')).toBeInTheDocument()
    })
  })
})
