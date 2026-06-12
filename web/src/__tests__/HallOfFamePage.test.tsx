import { describe, it, expect, vi, beforeEach } from 'vitest'
import { render, screen, waitFor, fireEvent } from '@testing-library/react'
import { MemoryRouter } from 'react-router-dom'
import HallOfFamePage from '@/pages/hall-of-fame/HallOfFamePage'

const mockAdminSelect = vi.hoisted(() => vi.fn())
const mockAdminRpc = vi.hoisted(() => vi.fn())

vi.mock('@/lib/supabase/admin-api', () => ({
  adminSelect: mockAdminSelect,
  adminUpdate: vi.fn(),
  adminRpc: mockAdminRpc,
}))

vi.mock('@/lib/supabase/client', () => ({
  supabase: {
    auth: { getSession: vi.fn().mockResolvedValue({ data: { session: null } }) },
    functions: { invoke: vi.fn() },
  },
}))

vi.mock('@/hooks/useAuth', () => ({
  useAuthStore: vi.fn(() => ({
    hasPermission: () => true,
    role: 'superadmin',
    permissions: [],
  })),
}))

vi.mock('react-i18next', () => ({
  useTranslation: () => ({
    t: (k: string, d?: string) => d || k,
    i18n: { language: 'en', changeLanguage: vi.fn() },
  }),
}))

vi.mock('sonner', () => ({ toast: { success: vi.fn(), error: vi.fn() } }))

function makeEntry(rank: number, overrides: Record<string, unknown> = {}) {
  return {
    rank,
    contributor_id: `contrib-${rank}`,
    display_name: `Contributor ${rank}`,
    avatar_url: null,
    is_verified: rank <= 2,
    city_poi_count: 10 - rank,
    city_avg_rating: 4.5 - rank * 0.1,
    city_total_ratings: 50 - rank * 5,
    hof_score: 100 - rank * 10,
    sample_poi_names: [],
    ...overrides,
  }
}

function renderPage(initialEntries = ['/admin/hall-of-fame']) {
  return render(
    <MemoryRouter initialEntries={initialEntries}>
      <HallOfFamePage />
    </MemoryRouter>,
  )
}

describe('HallOfFamePage', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    // Default: cities load returns empty, RPC returns empty
    mockAdminSelect.mockResolvedValue({ data: [], error: null })
    mockAdminRpc.mockResolvedValue({ data: [], error: null })
  })

  it('renders context tabs (Overall, By City, By Place)', async () => {
    renderPage()

    await waitFor(() => {
      expect(screen.getByText('admin.hallOfFame.contextOverall')).toBeInTheDocument()
    })
    expect(screen.getByText('admin.hallOfFame.contextCity')).toBeInTheDocument()
    expect(screen.getByText('admin.hallOfFame.contextPlace')).toBeInTheDocument()
  })

  it('Overall tab loads poi_hall_of_fame_overall RPC', async () => {
    mockAdminRpc.mockResolvedValue({ data: [], error: null })
    renderPage()

    await waitFor(() => {
      expect(mockAdminRpc).toHaveBeenCalledWith('poi_hall_of_fame_overall', { p_limit: 10 })
    })
  })

  it('By City tab shows city selector', async () => {
    const cities = [
      { id: 'city-1', name: 'Prague' },
      { id: 'city-2', name: 'Brno' },
    ]
    mockAdminSelect.mockResolvedValue({ data: cities, error: null })
    mockAdminRpc.mockResolvedValue({ data: [], error: null })
    renderPage()

    // Click "By City" tab
    await waitFor(() => {
      expect(screen.getByText('admin.hallOfFame.contextCity')).toBeInTheDocument()
    })
    fireEvent.click(screen.getByText('admin.hallOfFame.contextCity'))

    // City selector should appear
    await waitFor(() => {
      const citySelect = screen.getByLabelText('admin.hallOfFame.selectCity')
      expect(citySelect).toBeInTheDocument()
    })

    // Cities should be listed as options
    expect(screen.getByText('Prague')).toBeInTheDocument()
    expect(screen.getByText('Brno')).toBeInTheDocument()
  })

  it('podium renders top 3 with medal styling', async () => {
    const entries = [makeEntry(1), makeEntry(2), makeEntry(3)]
    mockAdminRpc.mockResolvedValue({ data: entries, error: null })
    renderPage()

    await waitFor(() => {
      expect(screen.getByText('Contributor 1')).toBeInTheDocument()
    })

    expect(screen.getByText('Contributor 2')).toBeInTheDocument()
    expect(screen.getByText('Contributor 3')).toBeInTheDocument()

    // Top contributors card heading should appear
    expect(screen.getByText('admin.hallOfFame.topContributors')).toBeInTheDocument()

    // Score badges
    expect(screen.getByText('admin.hallOfFame.score: 90.00')).toBeInTheDocument()
    expect(screen.getByText('admin.hallOfFame.score: 80.00')).toBeInTheDocument()
    expect(screen.getByText('admin.hallOfFame.score: 70.00')).toBeInTheDocument()
  })

  it('rankings list for #4+ entries', async () => {
    const entries = [
      makeEntry(1),
      makeEntry(2),
      makeEntry(3),
      makeEntry(4, { display_name: 'Fourth Place', hof_score: 55 }),
      makeEntry(5, { display_name: 'Fifth Place', hof_score: 40 }),
    ]
    mockAdminRpc.mockResolvedValue({ data: entries, error: null })
    renderPage()

    await waitFor(() => {
      expect(screen.getByText('Fourth Place')).toBeInTheDocument()
    })

    expect(screen.getByText('Fifth Place')).toBeInTheDocument()
    // Rank numbers for 4th and 5th
    expect(screen.getByText('#4')).toBeInTheDocument()
    expect(screen.getByText('#5')).toBeInTheDocument()
    // Scores
    expect(screen.getByText('admin.hallOfFame.score: 55.00')).toBeInTheDocument()
    expect(screen.getByText('admin.hallOfFame.score: 40.00')).toBeInTheDocument()
  })

  it('empty state when no contributors', async () => {
    mockAdminRpc.mockResolvedValue({ data: [], error: null })
    renderPage()

    await waitFor(() => {
      expect(screen.getByText('admin.hallOfFame.noData')).toBeInTheDocument()
    })
  })
})
