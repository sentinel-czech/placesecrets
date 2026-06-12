import { describe, it, expect, vi, beforeEach } from 'vitest'
import { render, screen, waitFor, fireEvent } from '@testing-library/react'
import { PremiumContentTab } from '@/components/pois/PremiumContentTab'

const mockAdminSelect = vi.hoisted(() => vi.fn())
const mockAdminUpsert = vi.hoisted(() => vi.fn())
const mockAdminStorageUploadUpsert = vi.hoisted(() => vi.fn())
const mockAdminStorageGetPublicUrl = vi.hoisted(() => vi.fn())
const mockToastSuccess = vi.hoisted(() => vi.fn())
const mockToastError = vi.hoisted(() => vi.fn())

vi.mock('@/lib/supabase/admin-api', () => ({
  adminSelect: mockAdminSelect,
  adminUpsert: mockAdminUpsert,
  adminStorageUploadUpsert: mockAdminStorageUploadUpsert,
  adminStorageGetPublicUrl: mockAdminStorageGetPublicUrl,
}))

vi.mock('@/lib/supabase/client', () => ({
  supabase: {
    auth: { getSession: vi.fn().mockResolvedValue({ data: { session: null } }) },
    from: vi.fn(),
    rpc: vi.fn(),
  },
}))

vi.mock('sonner', () => ({
  toast: {
    success: mockToastSuccess,
    error: mockToastError,
  },
}))

const mockPremiumContent = {
  id: 'pc-1',
  poi_id: 'poi-1',
  audio_url: 'https://example.com/audio.mp3',
  text_content: 'Premium description text',
  extra_photos: ['https://example.com/photo1.jpg', 'https://example.com/photo2.jpg'],
  related_poi_ids: ['poi-2'],
  created_at: '2024-01-01',
  updated_at: '2024-01-01',
}

const mockAvailablePois = [
  { id: 'poi-1', name: { cs: 'Hlavni bod', en: 'Main POI' } },
  { id: 'poi-2', name: { cs: 'Vedlejsi bod', en: 'Secondary POI' } },
  { id: 'poi-3', name: { cs: 'Treti bod', en: 'Third POI' } },
]

function setupMocks(
  content: typeof mockPremiumContent | null = mockPremiumContent,
  pois = mockAvailablePois
) {
  mockAdminSelect.mockImplementation((table: string) => {
    if (table === 'poi_premium_content') {
      return Promise.resolve({ data: content, error: null })
    }
    if (table === 'pois') {
      return Promise.resolve({ data: pois, error: null })
    }
    return Promise.resolve({ data: null, error: null })
  })
}

function renderComponent(poiId = 'poi-1', cityId = 'city-1') {
  return render(<PremiumContentTab poiId={poiId} cityId={cityId} />)
}

describe('PremiumContentTab', () => {
  beforeEach(() => {
    vi.clearAllMocks()
  })

  it('shows loading state initially', () => {
    // Never resolve the promise so it stays in loading state
    mockAdminSelect.mockImplementation(() => new Promise(() => {}))
    renderComponent()

    expect(screen.getByText('Loading premium content...')).toBeInTheDocument()
  })

  it('loads premium content and available POIs', async () => {
    setupMocks()
    renderComponent()

    await waitFor(() => {
      expect(screen.getByText('Premium Audio')).toBeInTheDocument()
    })

    expect(mockAdminSelect).toHaveBeenCalledWith('poi_premium_content', {
      filters: [{ column: 'poi_id', op: 'eq', value: 'poi-1' }],
      single: true,
    })
    expect(mockAdminSelect).toHaveBeenCalledWith('pois', {
      select: 'id, name',
      filters: [{ column: 'city_id', op: 'eq', value: 'city-1' }],
      order: { column: 'sort_order' },
    })
  })

  it('displays existing premium text content', async () => {
    setupMocks()
    renderComponent()

    await waitFor(() => {
      expect(screen.getByDisplayValue('Premium description text')).toBeInTheDocument()
    })
  })

  it('displays audio player when audio URL exists', async () => {
    setupMocks()
    renderComponent()

    await waitFor(() => {
      expect(screen.getByText('Premium Audio')).toBeInTheDocument()
    })

    const audio = document.querySelector('audio')
    expect(audio).toBeInTheDocument()
    expect(audio).toHaveAttribute('src', 'https://example.com/audio.mp3')
  })

  it('displays extra photo URL inputs', async () => {
    setupMocks()
    renderComponent()

    await waitFor(() => {
      expect(screen.getByText('Extra Photos')).toBeInTheDocument()
    })

    expect(screen.getByDisplayValue('https://example.com/photo1.jpg')).toBeInTheDocument()
    expect(screen.getByDisplayValue('https://example.com/photo2.jpg')).toBeInTheDocument()
  })

  it('displays related POIs', async () => {
    setupMocks()
    renderComponent()

    await waitFor(() => {
      expect(screen.getByText('Related POIs')).toBeInTheDocument()
    })

    // poi-2 is in relatedPoiIds, should show its Czech name
    expect(screen.getByText('Vedlejsi bod')).toBeInTheDocument()
  })

  it('renders empty state when no premium content exists', async () => {
    setupMocks(null)
    renderComponent()

    await waitFor(() => {
      expect(screen.getByText('Premium Audio')).toBeInTheDocument()
    })

    // No audio player should be shown
    const audio = document.querySelector('audio')
    expect(audio).not.toBeInTheDocument()

    // Text area should be empty
    const textarea = screen.getByPlaceholderText('Extended description for premium users...')
    expect(textarea).toHaveValue('')

    // No extra photo inputs
    const photoInputs = screen.queryAllByPlaceholderText('Photo URL')
    expect(photoInputs).toHaveLength(0)
  })

  it('allows editing text content', async () => {
    setupMocks()
    renderComponent()

    await waitFor(() => {
      expect(screen.getByDisplayValue('Premium description text')).toBeInTheDocument()
    })

    const textarea = screen.getByDisplayValue('Premium description text')
    fireEvent.change(textarea, { target: { value: 'Updated premium text' } })
    expect(textarea).toHaveValue('Updated premium text')
  })

  it('saves premium content via adminUpsert', async () => {
    setupMocks()
    mockAdminUpsert.mockResolvedValue({ error: null })
    renderComponent()

    await waitFor(() => {
      expect(screen.getByText('Save Premium Content')).toBeInTheDocument()
    })

    const saveButton = screen.getByRole('button', { name: /Save Premium Content/i })
    fireEvent.click(saveButton)

    await waitFor(() => {
      expect(mockAdminUpsert).toHaveBeenCalledWith(
        'poi_premium_content',
        {
          poi_id: 'poi-1',
          text_content: 'Premium description text',
          audio_url: 'https://example.com/audio.mp3',
          extra_photos: ['https://example.com/photo1.jpg', 'https://example.com/photo2.jpg'],
          related_poi_ids: ['poi-2'],
        },
        'poi_id'
      )
    })
    expect(mockToastSuccess).toHaveBeenCalledWith('Premium content saved')
  })

  it('shows error toast when save fails', async () => {
    setupMocks()
    mockAdminUpsert.mockResolvedValue({ error: 'Database error' })
    renderComponent()

    await waitFor(() => {
      expect(screen.getByText('Save Premium Content')).toBeInTheDocument()
    })

    fireEvent.click(screen.getByRole('button', { name: /Save Premium Content/i }))

    await waitFor(() => {
      expect(mockToastError).toHaveBeenCalledWith('Database error')
    })
  })

  it('shows Saving... text while saving', async () => {
    setupMocks()
    // Make upsert hang to observe the saving state
    mockAdminUpsert.mockImplementation(() => new Promise(() => {}))
    renderComponent()

    await waitFor(() => {
      expect(screen.getByText('Save Premium Content')).toBeInTheDocument()
    })

    fireEvent.click(screen.getByRole('button', { name: /Save Premium Content/i }))

    await waitFor(() => {
      expect(screen.getByText('Saving...')).toBeInTheDocument()
    })
  })

  it('handles audio upload successfully', async () => {
    setupMocks(null)
    mockAdminStorageUploadUpsert.mockResolvedValue({ error: null })
    mockAdminStorageGetPublicUrl.mockResolvedValue({
      publicUrl: 'https://storage.example.com/premium-audio/poi-1/test.mp3',
      error: null,
    })
    renderComponent()

    await waitFor(() => {
      expect(screen.getByText('Upload Audio')).toBeInTheDocument()
    })

    const file = new File(['audio-data'], 'test.mp3', { type: 'audio/mpeg' })
    const fileInput = document.querySelector('input[type="file"]') as HTMLInputElement
    fireEvent.change(fileInput, { target: { files: [file] } })

    await waitFor(() => {
      expect(mockAdminStorageUploadUpsert).toHaveBeenCalledWith(
        'premium-audio',
        'poi-1/test.mp3',
        file
      )
    })

    await waitFor(() => {
      expect(mockAdminStorageGetPublicUrl).toHaveBeenCalledWith(
        'premium-audio',
        'poi-1/test.mp3'
      )
    })

    expect(mockToastSuccess).toHaveBeenCalledWith('Audio uploaded')

    // After upload, audio element should appear with the new URL
    await waitFor(() => {
      const audio = document.querySelector('audio')
      expect(audio).toBeInTheDocument()
      expect(audio).toHaveAttribute('src', 'https://storage.example.com/premium-audio/poi-1/test.mp3')
    })
  })

  it('shows error toast when audio upload fails', async () => {
    setupMocks(null)
    mockAdminStorageUploadUpsert.mockResolvedValue({ error: 'Upload failed' })
    renderComponent()

    await waitFor(() => {
      expect(screen.getByText('Upload Audio')).toBeInTheDocument()
    })

    const file = new File(['audio-data'], 'test.mp3', { type: 'audio/mpeg' })
    const fileInput = document.querySelector('input[type="file"]') as HTMLInputElement
    fireEvent.change(fileInput, { target: { files: [file] } })

    await waitFor(() => {
      expect(mockToastError).toHaveBeenCalledWith('Upload failed')
    })

    // Should not call getPublicUrl on failure
    expect(mockAdminStorageGetPublicUrl).not.toHaveBeenCalled()
  })

  it('removes audio URL when X button clicked', async () => {
    setupMocks()
    mockAdminUpsert.mockResolvedValue({ error: null })
    renderComponent()

    await waitFor(() => {
      expect(document.querySelector('audio')).toBeInTheDocument()
    })

    // Click the X button next to the audio player (first destructive button)
    const removeButtons = document.querySelectorAll('.text-destructive')
    // First destructive button is the audio remove
    fireEvent.click(removeButtons[0])

    // Audio element should disappear
    expect(document.querySelector('audio')).not.toBeInTheDocument()

    // Save should send null for audio_url
    fireEvent.click(screen.getByRole('button', { name: /Save Premium Content/i }))

    await waitFor(() => {
      expect(mockAdminUpsert).toHaveBeenCalledWith(
        'poi_premium_content',
        expect.objectContaining({ audio_url: null }),
        'poi_id'
      )
    })
  })

  it('adds a new photo URL input', async () => {
    setupMocks(null)
    renderComponent()

    await waitFor(() => {
      expect(screen.getByText('Extra Photos')).toBeInTheDocument()
    })

    fireEvent.click(screen.getByRole('button', { name: /Add Photo URL/i }))

    const photoInputs = screen.getAllByPlaceholderText('Photo URL')
    expect(photoInputs).toHaveLength(1)
  })

  it('removes an extra photo URL', async () => {
    setupMocks()
    renderComponent()

    await waitFor(() => {
      expect(screen.getByDisplayValue('https://example.com/photo1.jpg')).toBeInTheDocument()
    })

    // There are 2 photo inputs initially; find destructive buttons in the Extra Photos card
    const photo1Input = screen.getByDisplayValue('https://example.com/photo1.jpg')
    const removeButton = photo1Input.parentElement?.querySelector('.text-destructive')
    expect(removeButton).toBeInTheDocument()
    fireEvent.click(removeButton!)

    // photo1 should be gone
    expect(screen.queryByDisplayValue('https://example.com/photo1.jpg')).not.toBeInTheDocument()
    // photo2 should remain
    expect(screen.getByDisplayValue('https://example.com/photo2.jpg')).toBeInTheDocument()
  })

  it('adds a related POI via select dropdown', async () => {
    setupMocks()
    renderComponent()

    await waitFor(() => {
      expect(screen.getByText('Related POIs')).toBeInTheDocument()
    })

    // poi-3 should be available in the dropdown (not already related)
    const select = screen.getByLabelText('Add related POI')
    fireEvent.change(select, { target: { value: 'poi-3' } })

    // poi-3 name should now appear in the related list
    await waitFor(() => {
      expect(screen.getByText('Treti bod')).toBeInTheDocument()
    })
  })

  it('removes a related POI', async () => {
    setupMocks()
    mockAdminUpsert.mockResolvedValue({ error: null })
    renderComponent()

    await waitFor(() => {
      expect(screen.getByText('Vedlejsi bod')).toBeInTheDocument()
    })

    // Find the remove button next to the related POI name
    const relatedPoiRow = screen.getByText('Vedlejsi bod').closest('.flex')
    const removeButton = relatedPoiRow?.querySelector('.text-destructive')
    expect(removeButton).toBeInTheDocument()
    fireEvent.click(removeButton!)

    // After removal, save should not include poi-2 in related_poi_ids
    fireEvent.click(screen.getByRole('button', { name: /Save Premium Content/i }))

    await waitFor(() => {
      expect(mockAdminUpsert).toHaveBeenCalledWith(
        'poi_premium_content',
        expect.objectContaining({ related_poi_ids: [] }),
        'poi_id'
      )
    })
  })

  it('filters out current POI from available POIs list', async () => {
    setupMocks()
    renderComponent('poi-1', 'city-1')

    await waitFor(() => {
      expect(screen.getByText('Related POIs')).toBeInTheDocument()
    })

    // poi-1 (the current POI) should not appear in the dropdown options
    const select = screen.getByLabelText('Add related POI')
    const options = select.querySelectorAll('option')
    const optionValues = Array.from(options).map(o => o.getAttribute('value'))
    expect(optionValues).not.toContain('poi-1')
  })

  it('saves with empty text_content as null', async () => {
    setupMocks(null)
    mockAdminUpsert.mockResolvedValue({ error: null })
    renderComponent()

    await waitFor(() => {
      expect(screen.getByText('Save Premium Content')).toBeInTheDocument()
    })

    fireEvent.click(screen.getByRole('button', { name: /Save Premium Content/i }))

    await waitFor(() => {
      expect(mockAdminUpsert).toHaveBeenCalledWith(
        'poi_premium_content',
        {
          poi_id: 'poi-1',
          text_content: null,
          audio_url: null,
          extra_photos: [],
          related_poi_ids: [],
        },
        'poi_id'
      )
    })
  })
})
