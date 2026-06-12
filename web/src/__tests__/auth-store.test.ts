import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest'

const mockGetSession = vi.hoisted(() => vi.fn())
const mockSignIn = vi.hoisted(() => vi.fn())
const mockSignOut = vi.hoisted(() => vi.fn())
const mockOnAuthStateChange = vi.hoisted(() => vi.fn())
const mockFrom = vi.hoisted(() => vi.fn())

vi.mock('@/lib/supabase/client', () => ({
  supabase: {
    auth: {
      getSession: mockGetSession,
      signInWithPassword: mockSignIn,
      signOut: mockSignOut,
      onAuthStateChange: mockOnAuthStateChange,
    },
    from: mockFrom,
  },
}))

// Must import after mock setup
const { useAuthStore } = await import('@/hooks/useAuth')

function setupQueryChain(returnValue: unknown) {
  const chain = {
    select: vi.fn().mockReturnThis(),
    eq: vi.fn().mockReturnThis(),
    maybeSingle: vi.fn().mockResolvedValue({ data: returnValue, error: null }),
    single: vi.fn().mockResolvedValue({ data: returnValue, error: null }),
  }
  mockFrom.mockReturnValue(chain)
  return chain
}

describe('useAuthStore', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    // Reset store state
    useAuthStore.setState({
      user: null,
      role: null,
      contributorId: null,
      displayName: null,
      isVerified: false,
      loading: true,
      adminVerified: false,
    })
    mockOnAuthStateChange.mockReturnValue({
      data: { subscription: { unsubscribe: vi.fn() } },
    })
  })

  afterEach(() => {
    vi.restoreAllMocks()
  })

  describe('initialize', () => {
    it('sets loading false and user null when no session', async () => {
      mockGetSession.mockResolvedValueOnce({ data: { session: null } })

      await useAuthStore.getState().initialize()

      expect(useAuthStore.getState().loading).toBe(false)
      expect(useAuthStore.getState().user).toBeNull()
      expect(useAuthStore.getState().role).toBeNull()
    })

    it('resolves role from web_user_roles view', async () => {
      const mockUser = { id: 'user-1', email: 'admin@test.com' }
      mockGetSession.mockResolvedValueOnce({
        data: { session: { user: mockUser, access_token: 'jwt' } },
      })
      setupQueryChain({ effective_role: 'editor' })

      await useAuthStore.getState().initialize()

      expect(useAuthStore.getState().user).toEqual(mockUser)
      expect(useAuthStore.getState().role).toBe('editor')
      expect(useAuthStore.getState().loading).toBe(false)
    })

    it('contributor role fetches contributor_profiles', async () => {
      const mockUser = { id: 'user-2', email: 'contrib@test.com' }
      mockGetSession.mockResolvedValueOnce({
        data: { session: { user: mockUser, access_token: 'jwt' } },
      })

      // First call: web_user_roles → contributor
      // Second call: contributor_profiles → profile data
      let callCount = 0
      mockFrom.mockImplementation(() => {
        callCount++
        if (callCount === 1) {
          return {
            select: vi.fn().mockReturnValue({
              eq: vi.fn().mockReturnValue({
                maybeSingle: vi.fn().mockResolvedValue({
                  data: { effective_role: 'contributor' },
                  error: null,
                }),
              }),
            }),
          }
        }
        return {
          select: vi.fn().mockReturnValue({
            eq: vi.fn().mockReturnValue({
              single: vi.fn().mockResolvedValue({
                data: { id: 'cp-1', display_name: 'John', is_verified: true },
                error: null,
              }),
            }),
          }),
        }
      })

      await useAuthStore.getState().initialize()

      expect(useAuthStore.getState().role).toBe('contributor')
      expect(useAuthStore.getState().contributorId).toBe('cp-1')
      expect(useAuthStore.getState().displayName).toBe('John')
      expect(useAuthStore.getState().isVerified).toBe(true)
    })

    it('sets up auth state change listener', async () => {
      mockGetSession.mockResolvedValueOnce({
        data: { session: { user: { id: 'u-1' }, access_token: 'jwt' } },
      })
      setupQueryChain({ effective_role: 'viewer' })

      await useAuthStore.getState().initialize()

      expect(mockOnAuthStateChange).toHaveBeenCalledOnce()
    })
  })

  describe('signIn', () => {
    it('sets user and resolves role', async () => {
      const mockUser = { id: 'user-3', email: 'test@test.com' }
      mockSignIn.mockResolvedValueOnce({
        data: { user: mockUser },
        error: null,
      })
      setupQueryChain({ effective_role: 'superadmin' })

      const { role } = await useAuthStore.getState().signIn('test@test.com', 'pass')

      expect(role).toBe('superadmin')
      expect(useAuthStore.getState().user).toEqual(mockUser)
      expect(useAuthStore.getState().role).toBe('superadmin')
    })

    it('throws on auth error', async () => {
      mockSignIn.mockResolvedValueOnce({
        data: { user: null },
        error: new Error('Invalid credentials'),
      })

      await expect(
        useAuthStore.getState().signIn('bad@test.com', 'wrong')
      ).rejects.toThrow('Invalid credentials')
    })
  })

  describe('signOut', () => {
    it('resets all state including adminVerified', async () => {
      // Set some state first
      useAuthStore.setState({
        user: { id: 'u-1' } as unknown as import('@supabase/supabase-js').User,
        role: 'superadmin',
        adminVerified: true,
        contributorId: 'cp-1',
        displayName: 'John',
      })
      mockSignOut.mockResolvedValueOnce({})

      await useAuthStore.getState().signOut()

      const state = useAuthStore.getState()
      expect(state.user).toBeNull()
      expect(state.role).toBeNull()
      expect(state.adminVerified).toBe(false)
      expect(state.contributorId).toBeNull()
      expect(state.displayName).toBeNull()
      expect(state.isVerified).toBe(false)
    })
  })

  describe('setAdminVerified', () => {
    it('sets adminVerified to true', () => {
      useAuthStore.getState().setAdminVerified(true)
      expect(useAuthStore.getState().adminVerified).toBe(true)
    })

    it('sets adminVerified to false', () => {
      useAuthStore.setState({ adminVerified: true })
      useAuthStore.getState().setAdminVerified(false)
      expect(useAuthStore.getState().adminVerified).toBe(false)
    })
  })

  describe('resolveUserInfo edge cases', () => {
    it('missing role row defaults to user', async () => {
      const mockUser = { id: 'user-4', email: 'regular@test.com' }
      mockGetSession.mockResolvedValueOnce({
        data: { session: { user: mockUser, access_token: 'jwt' } },
      })
      setupQueryChain(null) // no role row

      await useAuthStore.getState().initialize()

      expect(useAuthStore.getState().role).toBe('user')
    })

    it('contributor without profile still sets role', async () => {
      const mockUser = { id: 'user-5', email: 'orphan@test.com' }
      mockGetSession.mockResolvedValueOnce({
        data: { session: { user: mockUser, access_token: 'jwt' } },
      })

      let callCount = 0
      mockFrom.mockImplementation(() => {
        callCount++
        if (callCount === 1) {
          return {
            select: vi.fn().mockReturnValue({
              eq: vi.fn().mockReturnValue({
                maybeSingle: vi.fn().mockResolvedValue({
                  data: { effective_role: 'contributor' },
                  error: null,
                }),
              }),
            }),
          }
        }
        return {
          select: vi.fn().mockReturnValue({
            eq: vi.fn().mockReturnValue({
              single: vi.fn().mockResolvedValue({
                data: null,
                error: null,
              }),
            }),
          }),
        }
      })

      await useAuthStore.getState().initialize()

      expect(useAuthStore.getState().role).toBe('contributor')
      expect(useAuthStore.getState().contributorId).toBeNull()
    })
  })
})
