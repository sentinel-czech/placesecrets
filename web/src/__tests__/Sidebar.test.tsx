import { describe, it, expect, vi, beforeEach } from 'vitest'
import { render, screen } from '@testing-library/react'
import { MemoryRouter } from 'react-router-dom'
import { Sidebar } from '@/components/layout/Sidebar'

const mockUseAuthStore = vi.hoisted(() => vi.fn())

vi.mock('@/hooks/useAuth', () => ({
  useAuthStore: mockUseAuthStore,
}))

vi.mock('@/lib/supabase/client', () => ({
  supabase: {
    auth: { getSession: vi.fn().mockResolvedValue({ data: { session: null } }) },
    from: vi.fn(),
    rpc: vi.fn(),
  },
}))

vi.mock('react-i18next', () => ({
  useTranslation: () => ({
    t: (k: string, fallback?: string) => {
      const map: Record<string, string> = {
        'nav.dashboard': 'Dashboard',
        'nav.cities': 'Cities',
        'nav.placeTypes': 'Place Types',
        'nav.users': 'Users',
        'nav.payments': 'Payments',
        'nav.premiumPurchases': 'Premium Purchases',
        'nav.contributors': 'Contributors',
        'nav.hallOfFame': 'Hall of Fame',
        'nav.settings': 'Settings',
        'nav.contentManagement': 'Content Management',
        'nav.commerce': 'Commerce',
        'nav.community': 'Community',
        'nav.profile': 'Profile',
        'nav.myProfile': 'My Profile',
        'nav.myPlaces': 'My Places',
        'nav.leaveAdmin': 'Leave Admin',
        'nav.aclManagement': 'Access Control',
        'common.logout': 'Log out',
        'admin.users.roleSuperadmin': 'Superadmin',
        'admin.users.roleEditor': 'Editor',
        'admin.users.roleViewer': 'Viewer',
        'admin.users.roleContributor': 'Contributor',
      }
      return map[k] || fallback || k
    },
    i18n: { language: 'en', changeLanguage: vi.fn() },
  }),
}))

vi.mock('@/components/brand/Logo', () => ({
  Logo: () => <span>Logo</span>,
}))

function superadminHasPermission(_resource: string, _op: string) {
  return true
}

function editorHasPermission(resource: string, _op: string) {
  // Editor can see POIs, audio, cities, poi_types, dashboard
  const allowed = ['pois', 'audio', 'cities', 'poi_types', 'dashboard']
  return allowed.includes(resource)
}

function setupMock(overrides: Record<string, unknown>) {
  const base = {
    role: 'superadmin',
    user: { email: 'admin@test.com' },
    signOut: vi.fn(),
    hasPermission: superadminHasPermission,
    ...overrides,
  }
  mockUseAuthStore.mockReturnValue(base)
}

function renderSidebar(initialPath = '/admin/dashboard') {
  return render(
    <MemoryRouter initialEntries={[initialPath]}>
      <Sidebar />
    </MemoryRouter>
  )
}

describe('Sidebar', () => {
  beforeEach(() => {
    vi.clearAllMocks()
  })

  it('Premium Purchases link present', () => {
    setupMock({ role: 'superadmin' })
    renderSidebar()

    expect(screen.getByText('Premium Purchases')).toBeInTheDocument()
    const link = screen.getByText('Premium Purchases').closest('a')
    expect(link).toHaveAttribute('href', '/admin/purchases/premium')
  })

  it('Settings visible only for superadmin', () => {
    // As superadmin, Settings should be visible
    setupMock({ role: 'superadmin', hasPermission: superadminHasPermission })
    const { unmount } = renderSidebar()
    expect(screen.getByText('Settings')).toBeInTheDocument()
    unmount()

    // As editor, Settings should NOT be visible (no permission for settings resource)
    setupMock({
      role: 'editor',
      user: { email: 'editor@test.com' },
      hasPermission: editorHasPermission,
    })
    renderSidebar()
    expect(screen.queryByText('Settings')).not.toBeInTheDocument()
  })

  it('active NavLink styling', () => {
    setupMock({ role: 'superadmin' })
    renderSidebar('/admin/dashboard')

    const dashboardLink = screen.getByText('Dashboard').closest('a')
    // Active link should have aria-current="page" (set by NavLink)
    expect(dashboardLink).toHaveAttribute('aria-current', 'page')

    // Non-active link should not have aria-current
    const citiesLink = screen.getByText('Cities').closest('a')
    expect(citiesLink).not.toHaveAttribute('aria-current')
  })

  it('sign out button exists', () => {
    setupMock({ role: 'superadmin' })
    renderSidebar()

    expect(screen.getByText('Log out')).toBeInTheDocument()
  })
})
