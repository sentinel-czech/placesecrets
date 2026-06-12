import { describe, it, expect, vi, beforeEach } from 'vitest'
import { render, screen, waitFor } from '@testing-library/react'
import { AudioUploader } from '@/components/pois/AudioUploader'

const mockAdminSelect = vi.hoisted(() => vi.fn())

vi.mock('@/lib/supabase/admin-api', () => ({
  adminSelect: mockAdminSelect,
  adminInsert: vi.fn(),
  adminUpdate: vi.fn(),
  adminDelete: vi.fn(),
  adminStorageUploadUpsert: vi.fn(),
  adminStorageGetPublicUrl: vi.fn(),
}))

vi.mock('@/lib/supabase/client', () => ({
  supabase: {
    auth: { getSession: vi.fn().mockResolvedValue({ data: { session: null } }) },
  },
}))

vi.mock('react-i18next', () => ({
  useTranslation: () => ({
    t: (_k: string, d?: string) => d || _k,
    i18n: { language: 'en', changeLanguage: vi.fn() },
  }),
}))

function makeGuide(overrides: Record<string, unknown> = {}) {
  return {
    id: 'guide-1',
    poi_id: 'poi-1',
    lang_code: 'en',
    title: 'Test Guide',
    url: 'https://example.com/audio.mp3',
    duration_sec: 90,
    sort_order: 0,
    uploaded_by: null,
    created_at: '2024-01-01',
    updated_at: '2024-01-01',
    ...overrides,
  }
}

describe('AudioUploader', () => {
  beforeEach(() => {
    vi.clearAllMocks()
  })

  it('shows @handle when uploaded_by is set', async () => {
    const guide = makeGuide({ uploaded_by: 'user-1' })

    mockAdminSelect.mockImplementation((table: string) => {
      if (table === 'poi_audio_guides') {
        return Promise.resolve({ data: [guide], error: null })
      }
      if (table === 'admin_users_view') {
        return Promise.resolve({
          data: [{ id: 'user-1', email: 'alice@example.com', display_name: 'alice_handle' }],
          error: null,
        })
      }
      if (table === 'contributor_profiles') {
        return Promise.resolve({ data: [], error: null })
      }
      if (table === 'payment_config') {
        return Promise.resolve({ data: { max_audio_size_mb: 50 }, error: null })
      }
      return Promise.resolve({ data: null, error: null })
    })

    render(<AudioUploader poiId="poi-1" />)

    await waitFor(() => {
      expect(screen.getByText('@alice_handle')).toBeInTheDocument()
    })
  })

  it('shows @email_prefix when no display_name', async () => {
    const guide = makeGuide({ uploaded_by: 'user-2' })

    mockAdminSelect.mockImplementation((table: string) => {
      if (table === 'poi_audio_guides') {
        return Promise.resolve({ data: [guide], error: null })
      }
      if (table === 'admin_users_view') {
        return Promise.resolve({
          data: [{ id: 'user-2', email: 'bob@example.com', display_name: null }],
          error: null,
        })
      }
      if (table === 'contributor_profiles') {
        return Promise.resolve({ data: [], error: null })
      }
      if (table === 'payment_config') {
        return Promise.resolve({ data: { max_audio_size_mb: 50 }, error: null })
      }
      return Promise.resolve({ data: null, error: null })
    })

    render(<AudioUploader poiId="poi-1" />)

    await waitFor(() => {
      expect(screen.getByText('@bob')).toBeInTheDocument()
    })
  })

  it('falls back to contributorId when uploaded_by is null', async () => {
    const guide = makeGuide({ uploaded_by: null })

    mockAdminSelect.mockImplementation((table: string) => {
      if (table === 'poi_audio_guides') {
        return Promise.resolve({ data: [guide], error: null })
      }
      if (table === 'admin_users_view') {
        return Promise.resolve({
          data: [{ id: 'contrib-1', email: 'contrib@example.com', display_name: 'contrib_handle' }],
          error: null,
        })
      }
      if (table === 'contributor_profiles') {
        return Promise.resolve({ data: [], error: null })
      }
      if (table === 'payment_config') {
        return Promise.resolve({ data: { max_audio_size_mb: 50 }, error: null })
      }
      return Promise.resolve({ data: null, error: null })
    })

    render(<AudioUploader poiId="poi-1" contributorId="contrib-1" />)

    await waitFor(() => {
      expect(screen.getByText('@contrib_handle')).toBeInTheDocument()
    })
  })

  it('shows nothing when both uploaded_by and contributorId are null', async () => {
    const guide = makeGuide({ uploaded_by: null })

    mockAdminSelect.mockImplementation((table: string) => {
      if (table === 'poi_audio_guides') {
        return Promise.resolve({ data: [guide], error: null })
      }
      if (table === 'payment_config') {
        return Promise.resolve({ data: { max_audio_size_mb: 50 }, error: null })
      }
      return Promise.resolve({ data: null, error: null })
    })

    render(<AudioUploader poiId="poi-1" />)

    await waitFor(() => {
      expect(screen.getByText('Test Guide')).toBeInTheDocument()
    })

    // No @handle should be rendered
    const handleElements = screen.queryAllByText(/@\w+/)
    expect(handleElements).toHaveLength(0)
  })
})
