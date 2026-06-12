import { describe, it, expect, vi, beforeEach } from 'vitest'
import { render, screen, waitFor, fireEvent } from '@testing-library/react'
import { MemoryRouter, Route, Routes } from 'react-router-dom'

// ── Mocks ──
const mockAdminSelect = vi.fn()
const mockAdminUpdate = vi.fn()

vi.mock('@/lib/supabase/admin-api', () => ({
  adminSelect: (...args: unknown[]) => mockAdminSelect(...args),
  adminInsert: vi.fn(),
  adminUpdate: (...args: unknown[]) => mockAdminUpdate(...args),
  adminDelete: vi.fn(),
}))

const mockFrom = vi.fn()
vi.mock('@/lib/supabase/client', () => ({
  supabase: {
    auth: { getSession: vi.fn().mockResolvedValue({ data: { session: null } }) },
    from: (...args: unknown[]) => mockFrom(...args),
  },
}))

vi.mock('@/hooks/useAuth', () => ({
  useAuthStore: vi.fn((selector?: (s: Record<string, unknown>) => unknown) => {
    const state = {
      user: { id: 'user-1', email: 'contrib@test.com' },
      role: 'contributor',
      contributorId: 'contrib-1',
      hasPermission: () => true,
    }
    return selector ? selector(state) : state
  }),
}))

vi.mock('react-i18next', () => ({
  useTranslation: () => ({
    t: (k: string, d?: string) => d || k,
    i18n: { language: 'en', changeLanguage: vi.fn() },
  }),
}))

vi.mock('sonner', () => ({
  toast: { success: vi.fn(), error: vi.fn() },
}))

vi.mock('@/components/shared/CityPoiTree', () => ({
  default: ({ cities }: { cities: unknown[] }) => (
    <div data-testid="city-poi-tree">Tree: {cities.length} cities</div>
  ),
}))

vi.mock('@/components/shared/MapPicker', () => ({
  MapPicker: () => <div data-testid="map-picker" />,
}))

import MyPoisPage from '@/pages/my-pois/MyPoisPage'
import AdminProfilePage from '@/pages/AdminProfilePage'

function renderPage(ui: React.ReactElement, route = '/admin/my-pois') {
  return render(
    <MemoryRouter initialEntries={[route]}>
      <Routes>
        <Route path="*" element={ui} />
      </Routes>
    </MemoryRouter>
  )
}

describe('MyPoisPage', () => {
  beforeEach(() => {
    vi.clearAllMocks()

    // supabase.from('pois')
    mockFrom.mockReturnValue({
      select: vi.fn().mockReturnValue({
        eq: vi.fn().mockReturnValue({
          order: vi.fn().mockResolvedValue({
            data: [
              {
                id: 'poi-1',
                name: { cs: 'Místo 1', en: 'Place 1' },
                city_id: 'city-1',
                is_active: true,
                avg_rating: 4.5,
                contributor_id: 'user-1',
                city: { id: 'city-1', name: 'Prague', country_code: 'CZ', price_eur: 1, is_active: true, latitude: 50, longitude: 14, aliases: [] },
              },
            ],
            error: null,
          }),
        }),
      }),
    })

    // adminSelect('countries')
    mockAdminSelect.mockResolvedValue({
      data: [{ code: 'CZ', name: 'Czech Republic', aliases: [] }],
      error: null,
    })
  })

  it('loads contributor POIs and renders tree', async () => {
    renderPage(<MyPoisPage />)
    await waitFor(() => {
      expect(screen.getByTestId('city-poi-tree')).toBeInTheDocument()
    })
    expect(screen.getByText(/Tree: 1 cities/)).toBeInTheDocument()
  })

  it('shows Add POI button with link', async () => {
    renderPage(<MyPoisPage />)
    await waitFor(() => {
      expect(screen.getByTestId('city-poi-tree')).toBeInTheDocument()
    })
    const addLink = screen.getByRole('link', { name: /New Place|addNew/i })
    expect(addLink).toHaveAttribute('href', '/admin/my-pois/new')
  })

  it('shows search input', async () => {
    renderPage(<MyPoisPage />)
    await waitFor(() => {
      expect(screen.getByTestId('city-poi-tree')).toBeInTheDocument()
    })
    expect(screen.getByPlaceholderText(/search/i)).toBeInTheDocument()
  })

  it('shows empty state when no POIs', async () => {
    mockFrom.mockReturnValue({
      select: vi.fn().mockReturnValue({
        eq: vi.fn().mockReturnValue({
          order: vi.fn().mockResolvedValue({ data: [], error: null }),
        }),
      }),
    })
    renderPage(<MyPoisPage />)
    await waitFor(() => {
      expect(screen.getByText(/admin.myPois.noPois/)).toBeInTheDocument()
    })
  })
})

describe('AdminProfilePage', () => {
  beforeEach(() => {
    vi.clearAllMocks()
  })

  it('renders contributor profile form when contributor', async () => {
    mockFrom.mockReturnValue({
      select: vi.fn().mockReturnValue({
        eq: vi.fn().mockReturnValue({
          single: vi.fn().mockResolvedValue({
            data: {
              id: 'cp-1',
              user_id: 'user-1',
              display_name: 'testuser',
              bio: 'My bio',
              website_url: 'https://example.com',
              specializations: ['history', 'art'],
            },
          }),
        }),
      }),
    })

    renderPage(<AdminProfilePage />, '/admin/profile')
    await waitFor(() => {
      expect(screen.getByDisplayValue('testuser')).toBeInTheDocument()
    })
    expect(screen.getByDisplayValue('My bio')).toBeInTheDocument()
    expect(screen.getByDisplayValue('https://example.com')).toBeInTheDocument()
    expect(screen.getByDisplayValue('history, art')).toBeInTheDocument()
  })

  it('shows non-contributor card for non-contributor role', async () => {
    const { useAuthStore } = await import('@/hooks/useAuth')
    vi.mocked(useAuthStore).mockImplementation((selector?: (s: Record<string, unknown>) => unknown) => {
      const state = {
        user: { id: 'user-1', email: 'admin@test.com' },
        role: 'editor',
        hasPermission: () => true,
      }
      return selector ? selector(state) : state
    })

    renderPage(<AdminProfilePage />, '/admin/profile')
    await waitFor(() => {
      expect(screen.getByText('admin@test.com')).toBeInTheDocument()
    })
    expect(screen.getByText('editor')).toBeInTheDocument()
  })

  it('saves profile on submit', async () => {
    // Reset useAuth to contributor role (prev test changed it to editor)
    const { useAuthStore } = await import('@/hooks/useAuth')
    vi.mocked(useAuthStore).mockImplementation((selector?: (s: Record<string, unknown>) => unknown) => {
      const state = {
        user: { id: 'user-1', email: 'contrib@test.com' },
        role: 'contributor',
        contributorId: 'contrib-1',
        hasPermission: () => true,
      }
      return selector ? selector(state) : state
    })

    const mockUpdate = vi.fn().mockReturnValue({
      eq: vi.fn().mockResolvedValue({ error: null }),
    })

    mockFrom.mockImplementation((table: string) => {
      if (table === 'contributor_profiles') {
        return {
          select: vi.fn().mockReturnValue({
            eq: vi.fn().mockReturnValue({
              single: vi.fn().mockResolvedValue({
                data: {
                  id: 'cp-1',
                  user_id: 'user-1',
                  display_name: 'testuser',
                  bio: '',
                  website_url: null,
                  specializations: [],
                },
              }),
            }),
          }),
          update: mockUpdate,
        }
      }
      return { select: vi.fn() }
    })

    renderPage(<AdminProfilePage />, '/admin/profile')
    await waitFor(() => {
      expect(screen.getByDisplayValue('testuser')).toBeInTheDocument()
    })

    const bioInput = screen.getByPlaceholderText(/bioPlaceholder/i)
    fireEvent.change(bioInput, { target: { value: 'New bio text' } })
    fireEvent.submit(screen.getByRole('button', { name: /save|common.save/i }))

    await waitFor(() => {
      expect(mockUpdate).toHaveBeenCalled()
    })
  })
})
