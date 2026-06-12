import { describe, it, expect, vi, beforeEach } from 'vitest'
import { render, screen, waitFor, fireEvent } from '@testing-library/react'
import { MemoryRouter } from 'react-router-dom'
import { PhotoUploader } from '@/components/pois/PhotoUploader'
import PoiTypesPage from '@/pages/poi-types/PoiTypesPage'

const mockAdminSelect = vi.hoisted(() => vi.fn())
const mockAdminUpdate = vi.hoisted(() => vi.fn())
const mockAdminInsert = vi.hoisted(() => vi.fn())

vi.mock('@/lib/supabase/admin-api', () => ({
  adminSelect: mockAdminSelect,
  adminUpdate: mockAdminUpdate,
  adminInsert: mockAdminInsert,
  adminStorageUpload: vi.fn(),
  adminStorageGetPublicUrl: vi.fn(),
  adminRpc: vi.fn(),
}))

vi.mock('@/lib/supabase/client', () => ({
  supabase: {
    auth: { getSession: vi.fn().mockResolvedValue({ data: { session: null } }) },
    from: vi.fn(),
    rpc: vi.fn(),
    storage: { from: vi.fn() },
  },
}))

vi.mock('react-i18next', () => ({
  useTranslation: () => ({
    t: (k: string) => {
      const map: Record<string, string> = {
        'common.name': 'Name',
        'common.status': 'Status',
        'common.edit': 'Edit',
        'common.success': 'Success',
        'common.loading': 'Loading...',
        'admin.poiTypes.sortOrder': 'Sort Order',
        'admin.poiTypes.icon': 'Icon',
        'admin.poiTypes.slug': 'Slug',
        'admin.poiTypes.newType': 'New Type',
        'admin.poiTypes.deactivate': 'Deactivate',
        'admin.poiTypes.activate': 'Activate',
        'admin.poiTypes.languageFilter': 'Language',
        'admin.poiTypes.inlineEditHint': 'Click to edit',
      }
      return map[k] || k
    },
    i18n: { language: 'en', changeLanguage: vi.fn() },
  }),
}))

vi.mock('sonner', () => ({ toast: { success: vi.fn(), error: vi.fn() } }))

vi.mock('react-dropzone', () => ({
  useDropzone: ({ onDrop }: { onDrop: (files: File[]) => void }) => ({
    getRootProps: () => ({ onClick: () => {} }),
    getInputProps: () => ({ type: 'file', onChange: () => onDrop([]) }),
    isDragActive: false,
  }),
}))

vi.mock('@/components/shared/MaterialIcon', () => ({
  MaterialIcon: ({ name }: { name: string }) => <span data-testid="material-icon">{name}</span>,
}))

vi.mock('@/components/shared/StatusBadge', () => ({
  ActiveBadge: ({ active }: { active: boolean }) => <span>{active ? 'Active' : 'Inactive'}</span>,
}))

vi.mock('@/components/poi-types/PoiTypeModal', () => ({
  PoiTypeModal: () => null,
}))

const mockPoiTypes = [
  {
    id: 'pt-1',
    name: { en: 'Castle', cs: 'Hrad', de: '' },
    slug: 'castle',
    icon_name: 'castle',
    color_hex: '#2D6A4F',
    sort_order: 1,
    is_active: true,
    created_at: '2024-01-01',
    updated_at: '2024-01-01',
  },
  {
    id: 'pt-2',
    name: { en: 'Church' },
    slug: 'church',
    icon_name: 'church',
    color_hex: '#0000FF',
    sort_order: 2,
    is_active: false,
    created_at: '2024-01-01',
    updated_at: '2024-01-01',
  },
]

describe('PhotoUploader', () => {
  const onChange = vi.fn()

  beforeEach(() => {
    vi.clearAllMocks()
  })

  it('renders thumbnail grid', () => {
    const photos = [
      'https://example.com/photo1.jpg',
      'https://example.com/photo2.jpg',
    ]
    render(<PhotoUploader poiId="poi-1" photos={photos} onChange={onChange} />)
    // Images have alt="" so they get role="presentation", query by tag
    const images = document.querySelectorAll('img')
    expect(images).toHaveLength(2)
    expect(images[0]).toHaveAttribute('src', photos[0])
    expect(images[1]).toHaveAttribute('src', photos[1])
  })

  it('delete calls onChange without the removed photo', () => {
    const photos = [
      'https://example.com/photo1.jpg',
      'https://example.com/photo2.jpg',
    ]
    render(<PhotoUploader poiId="poi-1" photos={photos} onChange={onChange} />)
    // Each photo has a remove button (X)
    const removeButtons = screen.getAllByRole('button').filter(
      btn => btn.querySelector('svg')
    )
    // Click the first remove button (for photo1)
    fireEvent.click(removeButtons[0])
    expect(onChange).toHaveBeenCalledWith(['https://example.com/photo2.jpg'])
  })
})

describe('PoiTypesPage', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    localStorage.setItem('adminLangFilter', 'en')
  })

  function setupMocks() {
    mockAdminSelect.mockResolvedValue({ data: mockPoiTypes, error: null })
    mockAdminUpdate.mockResolvedValue({ error: null })
  }

  function renderPage() {
    return render(
      <MemoryRouter>
        <PoiTypesPage />
      </MemoryRouter>
    )
  }

  it('renders types with language pills', async () => {
    setupMocks()
    renderPage()

    await waitFor(() => {
      expect(screen.getByText('Castle')).toBeInTheDocument()
    })
    expect(screen.getByText('Church')).toBeInTheDocument()
    // Language pills should be rendered
    expect(screen.getByText('Language:')).toBeInTheDocument()
    expect(screen.getByText('EN')).toBeInTheDocument()
    expect(screen.getByText('CS')).toBeInTheDocument()
    expect(screen.getByText('DE')).toBeInTheDocument()
  })

  it('inline edit saves via adminUpdate', async () => {
    setupMocks()
    renderPage()

    await waitFor(() => {
      expect(screen.getByText('Castle')).toBeInTheDocument()
    })

    // Click the Castle name to start inline editing
    fireEvent.click(screen.getByText('Castle'))

    // An input should appear with the current value
    const input = await screen.findByDisplayValue('Castle')
    fireEvent.change(input, { target: { value: 'Fortress' } })
    fireEvent.blur(input)

    await waitFor(() => {
      expect(mockAdminUpdate).toHaveBeenCalledWith(
        'poi_types',
        { name: { en: 'Fortress', cs: 'Hrad', de: '' } },
        [{ column: 'id', op: 'eq', value: 'pt-1' }]
      )
    })
  })

  it('activate/deactivate toggle', async () => {
    setupMocks()
    renderPage()

    await waitFor(() => {
      expect(screen.getByText('Castle')).toBeInTheDocument()
    })

    // Castle is active, so it should have a "Deactivate" button
    // Church is inactive, so it should have an "Activate" button
    expect(screen.getByText('Deactivate')).toBeInTheDocument()
    expect(screen.getByText('Activate')).toBeInTheDocument()

    // Click Deactivate for Castle
    fireEvent.click(screen.getByText('Deactivate'))

    await waitFor(() => {
      expect(mockAdminUpdate).toHaveBeenCalledWith(
        'poi_types',
        { is_active: false },
        [{ column: 'id', op: 'eq', value: 'pt-1' }]
      )
    })
  })
})
