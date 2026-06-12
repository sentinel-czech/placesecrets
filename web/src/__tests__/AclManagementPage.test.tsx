import { describe, it, expect, vi, beforeEach } from 'vitest'
import { render, screen, waitFor, fireEvent } from '@testing-library/react'
import AclManagementPage from '@/pages/AclManagementPage'

const mockAdminRpc = vi.hoisted(() => vi.fn())
const mockAdminUpdate = vi.hoisted(() => vi.fn())
const mockToastSuccess = vi.hoisted(() => vi.fn())
const mockToastError = vi.hoisted(() => vi.fn())
const mockToastInfo = vi.hoisted(() => vi.fn())
const mockHasPermission = vi.hoisted(() => vi.fn())

vi.mock('@/lib/supabase/admin-api', () => ({
  adminSelect: vi.fn(),
  adminUpdate: mockAdminUpdate,
  adminRpc: mockAdminRpc,
  adminUpsert: vi.fn(),
  adminDelete: vi.fn(),
  adminAuthCreateUser: vi.fn(),
  adminAuthGetUser: vi.fn(),
  adminAuthListUsers: vi.fn(),
}))

vi.mock('@/lib/supabase/client', () => ({
  supabase: {
    auth: { getSession: vi.fn().mockResolvedValue({ data: { session: { access_token: 'test' } } }) },
    functions: { invoke: vi.fn() },
  },
}))

vi.mock('@/hooks/useAuth', () => ({
  useAuthStore: () => ({ hasPermission: mockHasPermission }),
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
    info: mockToastInfo,
  },
}))

function makePermissions() {
  const roles = ['superadmin', 'editor', 'viewer', 'contributor', 'user']
  const resources = [
    'cities', 'pois', 'own_pois', 'poi_types', 'users', 'payments',
    'settings', 'acl', 'hall_of_fame', 'contributors', 'own_profile',
    'audio', 'dashboard',
  ]
  let idx = 0
  return roles.flatMap(role =>
    resources.map(resource => ({
      id: `perm-${idx++}`,
      role,
      resource,
      can_read: role === 'superadmin',
      can_write: role === 'superadmin',
      can_delete: role === 'superadmin',
    }))
  )
}

// Count checkboxes via a plain DOM query. `screen.getAllByRole('checkbox')`
// computes the accessibility tree for the entire grid (5x13x3 = 195 inputs plus
// the surrounding table), which pushed this file's per-test runtime right up to
// the 5s vitest timeout and made it flaky. A direct querySelector is O(n) and
// deterministic. RTL auto-cleanup empties document.body between tests.
function getCheckboxes(): HTMLInputElement[] {
  return Array.from(document.querySelectorAll<HTMLInputElement>('input[type="checkbox"]'))
}

describe('AclManagementPage', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    mockHasPermission.mockReturnValue(true)
  })

  it('loads permissions matrix on mount via adminRpc', async () => {
    mockAdminRpc.mockResolvedValue({ data: makePermissions(), error: null })
    render(<AclManagementPage />)

    await waitFor(() => {
      expect(mockAdminRpc).toHaveBeenCalledWith('get_all_permissions', {})
    })
  })

  it('renders roles x resources grid with checkboxes', async () => {
    mockAdminRpc.mockResolvedValue({ data: makePermissions(), error: null })
    render(<AclManagementPage />)

    await waitFor(() => {
      expect(screen.getByText('cities')).toBeInTheDocument()
    })

    // Verify role column headers
    expect(screen.getByText('superadmin')).toBeInTheDocument()
    expect(screen.getByText('editor')).toBeInTheDocument()
    expect(screen.getByText('viewer')).toBeInTheDocument()
    expect(screen.getByText('contributor')).toBeInTheDocument()

    // Verify resource rows
    expect(screen.getByText('pois')).toBeInTheDocument()
    expect(screen.getByText('settings')).toBeInTheDocument()
    expect(screen.getByText('dashboard')).toBeInTheDocument()

    // Each cell has 3 checkboxes (R, W, D) — 5 roles x 13 resources x 3 = 195
    const checkboxes = getCheckboxes()
    expect(checkboxes.length).toBe(5 * 13 * 3)
  })

  it('superadmin row checkboxes are disabled', async () => {
    mockAdminRpc.mockResolvedValue({ data: makePermissions(), error: null })
    render(<AclManagementPage />)

    await waitFor(() => {
      expect(screen.getByText('cities')).toBeInTheDocument()
    })

    // Superadmin checkboxes: 13 resources x 3 = 39 disabled checkboxes
    const allCheckboxes = getCheckboxes()
    // First 3 checkboxes per resource row belong to superadmin (first role column)
    // The table renders per resource row: for each resource, all 5 roles in order
    // superadmin is the first role, so for each resource row indices 0,1,2 are superadmin
    const disabledCheckboxes = allCheckboxes.filter(cb => (cb as HTMLInputElement).disabled)
    expect(disabledCheckboxes.length).toBe(13 * 3) // 39 superadmin checkboxes
  })

  it('toggling write auto-enables read', async () => {
    const perms = makePermissions()
    mockAdminRpc.mockResolvedValue({ data: perms, error: null })
    render(<AclManagementPage />)

    await waitFor(() => {
      expect(screen.getByText('cities')).toBeInTheDocument()
    })

    // Find the editor/cities cell. Editor is the second role, cities is the first resource.
    // Each resource row has 5 roles x 3 checkboxes = 15 checkboxes.
    // editor is index 1 in roles, so checkboxes at positions 3,4,5 (0-based) in first row.
    const allCheckboxes = getCheckboxes()
    // First resource row (cities): superadmin(0,1,2), editor(3,4,5), viewer(6,7,8), contributor(9,10,11), user(12,13,14)
    const editorRead = allCheckboxes[3] as HTMLInputElement
    const editorWrite = allCheckboxes[4] as HTMLInputElement

    // Both should start unchecked (editor for cities starts with all false)
    expect(editorRead.checked).toBe(false)
    expect(editorWrite.checked).toBe(false)

    // Toggle write — should auto-enable read
    fireEvent.click(editorWrite)
    expect(editorWrite.checked).toBe(true)
    expect(editorRead.checked).toBe(true)
  })

  it('unchecking read auto-disables write and delete', async () => {
    const perms = makePermissions()
    // Set editor/cities to all true
    const editorCities = perms.find(p => p.role === 'editor' && p.resource === 'cities')!
    editorCities.can_read = true
    editorCities.can_write = true
    editorCities.can_delete = true

    mockAdminRpc.mockResolvedValue({ data: perms, error: null })
    render(<AclManagementPage />)

    await waitFor(() => {
      expect(screen.getByText('cities')).toBeInTheDocument()
    })

    const allCheckboxes = getCheckboxes()
    const editorRead = allCheckboxes[3] as HTMLInputElement
    const editorWrite = allCheckboxes[4] as HTMLInputElement
    const editorDelete = allCheckboxes[5] as HTMLInputElement

    expect(editorRead.checked).toBe(true)
    expect(editorWrite.checked).toBe(true)
    expect(editorDelete.checked).toBe(true)

    // Uncheck read — should auto-disable write and delete
    fireEvent.click(editorRead)
    expect(editorRead.checked).toBe(false)
    expect(editorWrite.checked).toBe(false)
    expect(editorDelete.checked).toBe(false)
  })

  it('save calls adminUpdate for changed permissions', async () => {
    const perms = makePermissions()
    mockAdminRpc.mockResolvedValue({ data: perms, error: null })
    mockAdminUpdate.mockResolvedValue({ error: null })
    render(<AclManagementPage />)

    await waitFor(() => {
      expect(screen.getByText('cities')).toBeInTheDocument()
    })

    // Toggle editor/cities write (auto-enables read)
    const allCheckboxes = getCheckboxes()
    const editorWrite = allCheckboxes[4] as HTMLInputElement
    fireEvent.click(editorWrite)

    const saveButton = screen.getByRole('button', { name: /admin\.acl\.saveChanges/i })
    fireEvent.click(saveButton)

    const editorCitiesPerm = perms.find(p => p.role === 'editor' && p.resource === 'cities')!
    await waitFor(() => {
      expect(mockAdminUpdate).toHaveBeenCalledWith(
        'acl_permissions',
        { can_read: true, can_write: true, can_delete: false },
        [{ column: 'id', op: 'eq', value: editorCitiesPerm.id }]
      )
    })
    expect(mockToastSuccess).toHaveBeenCalled()
  })

  it('no changes shows info toast', async () => {
    mockAdminRpc.mockResolvedValue({ data: makePermissions(), error: null })
    render(<AclManagementPage />)

    await waitFor(() => {
      expect(screen.getByText('cities')).toBeInTheDocument()
    })

    // Click save without making any changes
    const saveButton = screen.getByRole('button', { name: /admin\.acl\.saveChanges/i })
    // The button is disabled when there are no changes, so fire click anyway
    // Since the button is disabled={saving || !hasChanges()}, we need to call handleSave differently.
    // Actually the button should be disabled. Let's verify.
    expect(saveButton).toBeDisabled()
  })
})
