import { describe, it, expect, vi, beforeEach } from 'vitest'
import { render, screen, waitFor, fireEvent } from '@testing-library/react'
import { MemoryRouter, Route, Routes } from 'react-router-dom'
import ContributorsPage from '@/pages/contributors/ContributorsPage'
import ContributorDetailPage from '@/pages/contributors/ContributorDetailPage'

const mockAdminSelect = vi.hoisted(() => vi.fn())
const mockAdminUpdate = vi.hoisted(() => vi.fn())
const mockToastSuccess = vi.hoisted(() => vi.fn())
const mockToastError = vi.hoisted(() => vi.fn())

vi.mock('@/lib/supabase/admin-api', () => ({
  adminSelect: mockAdminSelect,
  adminUpdate: mockAdminUpdate,
  adminInsert: vi.fn(),
  adminDelete: vi.fn(),
  adminUpsert: vi.fn(),
  adminRpc: vi.fn(),
  adminAuthCreateUser: vi.fn(),
  adminAuthGetUser: vi.fn(),
  adminAuthListUsers: vi.fn(),
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
  })),
}))

vi.mock('react-i18next', () => ({
  useTranslation: () => ({
    t: (k: string, d?: string) => d || k,
    i18n: { language: 'en', changeLanguage: vi.fn() },
  }),
}))

vi.mock('sonner', () => ({
  toast: {
    success: mockToastSuccess,
    error: mockToastError,
  },
}))

function makeContributor(overrides: Record<string, unknown> = {}) {
  return {
    id: 'contrib-1',
    user_id: 'user-1',
    display_name: 'John Guide',
    bio: 'Expert local guide',
    avatar_url: null,
    website_url: 'https://johnguide.com',
    specializations: ['history', 'architecture'],
    total_pois: 12,
    avg_rating: 4.75,
    total_ratings: 48,
    is_verified: true,
    is_active: true,
    created_at: '2024-03-10T08:00:00Z',
    updated_at: '2024-11-20T16:00:00Z',
    ...overrides,
  }
}

function makePoi(overrides: Record<string, unknown> = {}) {
  return {
    id: 'poi-1',
    city_id: 'city-1',
    name: { cs: 'Karlstejn', en: 'Karlstejn Castle' },
    is_active: true,
    avg_rating: 4.5,
    sort_order: 1,
    contributor_id: 'contrib-1',
    ...overrides,
  }
}

// ---- ContributorsPage tests ----

describe('ContributorsPage', () => {
  beforeEach(() => {
    vi.clearAllMocks()
  })

  it('loads contributors via adminSelect on mount', async () => {
    mockAdminSelect.mockResolvedValue({ data: [makeContributor()], error: null })

    render(
      <MemoryRouter initialEntries={['/admin/contributors']}>
        <Routes>
          <Route path="/admin/contributors" element={<ContributorsPage />} />
        </Routes>
      </MemoryRouter>
    )

    await waitFor(() => {
      expect(mockAdminSelect).toHaveBeenCalledWith('contributor_profiles', {
        order: { column: 'created_at', ascending: false },
      })
    })
  })

  it('DataTable renders contributor data with detail links', async () => {
    mockAdminSelect.mockResolvedValue({
      data: [
        makeContributor({ id: 'contrib-1', display_name: 'John Guide' }),
        makeContributor({ id: 'contrib-2', display_name: 'Jane Explorer', is_verified: false }),
      ],
      error: null,
    })

    render(
      <MemoryRouter initialEntries={['/admin/contributors']}>
        <Routes>
          <Route path="/admin/contributors" element={<ContributorsPage />} />
          <Route path="/admin/contributors/:id" element={<div>Detail Page</div>} />
        </Routes>
      </MemoryRouter>
    )

    await waitFor(() => {
      expect(screen.getByText('John Guide')).toBeInTheDocument()
    })
    expect(screen.getByText('Jane Explorer')).toBeInTheDocument()

    // Detail links should be present
    const detailButtons = screen.getAllByText('admin.users.detail')
    expect(detailButtons).toHaveLength(2)

    const firstLink = detailButtons[0].closest('a')
    expect(firstLink).toHaveAttribute('href', '/admin/contributors/contrib-1')

    const secondLink = detailButtons[1].closest('a')
    expect(secondLink).toHaveAttribute('href', '/admin/contributors/contrib-2')
  })

  it('shows error when fetch fails', async () => {
    mockAdminSelect.mockResolvedValue({ data: null, error: 'Database error' })

    render(
      <MemoryRouter initialEntries={['/admin/contributors']}>
        <Routes>
          <Route path="/admin/contributors" element={<ContributorsPage />} />
        </Routes>
      </MemoryRouter>
    )

    await waitFor(() => {
      expect(screen.getByText('Database error')).toBeInTheDocument()
    })
  })
})

// ---- ContributorDetailPage tests ----

describe('ContributorDetailPage', () => {
  beforeEach(() => {
    vi.clearAllMocks()
  })

  function setupDetailMock(
    contributor: ReturnType<typeof makeContributor> | null = makeContributor(),
    pois: ReturnType<typeof makePoi>[] = [makePoi()],
  ) {
    mockAdminSelect.mockImplementation((table: string) => {
      if (table === 'contributor_profiles') {
        return Promise.resolve({ data: contributor, error: null })
      }
      if (table === 'pois') {
        return Promise.resolve({ data: pois, error: null })
      }
      return Promise.resolve({ data: null, error: null })
    })
  }

  function renderDetailPage(contributorId = 'contrib-1') {
    return render(
      <MemoryRouter initialEntries={[`/admin/contributors/${contributorId}`]}>
        <Routes>
          <Route path="/admin/contributors/:id" element={<ContributorDetailPage />} />
        </Routes>
      </MemoryRouter>
    )
  }

  it('loads profile and lists POIs', async () => {
    setupDetailMock(makeContributor(), [
      makePoi({ id: 'poi-1', name: { cs: 'Karlstejn', en: 'Karlstejn Castle' } }),
      makePoi({ id: 'poi-2', name: { cs: 'Krivoklat', en: 'Krivoklat Castle' } }),
    ])

    renderDetailPage()

    await waitFor(() => {
      expect(screen.getByText('John Guide')).toBeInTheDocument()
    })

    // Contributor info should be displayed
    expect(screen.getByText('Expert local guide')).toBeInTheDocument()
    expect(screen.getByText('https://johnguide.com')).toBeInTheDocument()
    expect(screen.getByText('history, architecture')).toBeInTheDocument()

    // POIs should be listed
    expect(screen.getByText('Karlstejn')).toBeInTheDocument()
    expect(screen.getByText('Krivoklat')).toBeInTheDocument()

    // adminSelect should have been called for both tables
    expect(mockAdminSelect).toHaveBeenCalledWith('contributor_profiles', {
      filters: [{ column: 'id', op: 'eq', value: 'contrib-1' }],
      single: true,
    })
    expect(mockAdminSelect).toHaveBeenCalledWith('pois', {
      filters: [{ column: 'contributor_id', op: 'eq', value: 'contrib-1' }],
      order: { column: 'sort_order' },
    })
  })

  it('verification toggle calls adminUpdate', async () => {
    setupDetailMock(makeContributor({ is_verified: true }))
    mockAdminUpdate.mockResolvedValue({ error: null })
    // After toggle, loadData is called again
    const updatedContributor = makeContributor({ is_verified: false })

    renderDetailPage()

    await waitFor(() => {
      expect(screen.getByText('John Guide')).toBeInTheDocument()
    })

    // Click remove verification button
    const removeVerifyButton = screen.getByText('contributorsPage.removeVerification')
    fireEvent.click(removeVerifyButton)

    await waitFor(() => {
      expect(mockAdminUpdate).toHaveBeenCalledWith(
        'contributor_profiles',
        { is_verified: false },
        [{ column: 'id', op: 'eq', value: 'contrib-1' }]
      )
    })

    expect(mockToastSuccess).toHaveBeenCalled()
  })

  it('shows error state when fetch rejects', async () => {
    mockAdminSelect.mockRejectedValue(new Error('Connection refused'))

    renderDetailPage()

    await waitFor(() => {
      expect(screen.getByText(/Connection refused/)).toBeInTheDocument()
    })
  })

  it('shows not found when contributor is null', async () => {
    setupDetailMock(null, [])

    renderDetailPage()

    await waitFor(() => {
      expect(screen.getByText('contributorsPage.contributorNotFound')).toBeInTheDocument()
    })
  })
})
