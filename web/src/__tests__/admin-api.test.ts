import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest'
import {
  adminSelect,
  adminInsert,
  adminUpdate,
  adminDelete,
  adminUpsert,
  adminRpc,
} from '@/lib/supabase/admin-api'

// Mock supabase client
vi.mock('@/lib/supabase/client', () => ({
  supabase: {
    auth: {
      getSession: vi.fn().mockResolvedValue({
        data: { session: { access_token: 'test-jwt-token' } },
      }),
    },
  },
}))

describe('admin-api client', () => {
  let fetchMock: ReturnType<typeof vi.fn>

  beforeEach(() => {
    fetchMock = vi.fn()
    globalThis.fetch = fetchMock as unknown as typeof fetch
  })

  afterEach(() => {
    vi.restoreAllMocks()
  })

  it('adminSelect builds correct request body', async () => {
    fetchMock.mockResolvedValueOnce({
      ok: true,
      json: () => Promise.resolve({ data: [{ id: '1' }] }),
    })

    await adminSelect('pois', {
      select: 'id, name',
      filters: [{ column: 'city_id', op: 'eq', value: 'city-1' }],
      order: { column: 'sort_order', ascending: true },
    })

    expect(fetchMock).toHaveBeenCalledOnce()
    const [url, opts] = fetchMock.mock.calls[0]
    expect(url).toContain('/functions/v1/admin-api')
    expect(opts.method).toBe('POST')

    const body = JSON.parse(opts.body)
    expect(body.action).toBe('select')
    expect(body.table).toBe('pois')
    expect(body.filters).toEqual([{ column: 'city_id', op: 'eq', value: 'city-1' }])
    expect(body.options.select).toBe('id, name')
    expect(body.options.order).toEqual({ column: 'sort_order', ascending: true })
  })

  it('adminSelect with defaults uses * select', async () => {
    fetchMock.mockResolvedValueOnce({
      ok: true,
      json: () => Promise.resolve({ data: [] }),
    })

    await adminSelect('pois')

    const body = JSON.parse(fetchMock.mock.calls[0][1].body)
    expect(body.options.select).toBe('*')
  })

  it('adminInsert includes table and data', async () => {
    fetchMock.mockResolvedValueOnce({
      ok: true,
      json: () => Promise.resolve({ data: { id: 'new-1' } }),
    })

    await adminInsert('pois', { name: { cs: 'Test' }, city_id: 'city-1' })

    const body = JSON.parse(fetchMock.mock.calls[0][1].body)
    expect(body.action).toBe('insert')
    expect(body.table).toBe('pois')
    expect(body.data).toEqual({ name: { cs: 'Test' }, city_id: 'city-1' })
  })

  it('adminUpdate includes table, data, and filters', async () => {
    fetchMock.mockResolvedValueOnce({
      ok: true,
      json: () => Promise.resolve({}),
    })

    await adminUpdate(
      'pois',
      { name: { cs: 'Updated' } },
      [{ column: 'id', op: 'eq', value: 'poi-1' }]
    )

    const body = JSON.parse(fetchMock.mock.calls[0][1].body)
    expect(body.action).toBe('update')
    expect(body.table).toBe('pois')
    expect(body.data).toEqual({ name: { cs: 'Updated' } })
    expect(body.filters).toEqual([{ column: 'id', op: 'eq', value: 'poi-1' }])
  })

  it('adminDelete includes table and filters', async () => {
    fetchMock.mockResolvedValueOnce({
      ok: true,
      json: () => Promise.resolve({}),
    })

    await adminDelete('pois', [{ column: 'id', op: 'eq', value: 'poi-1' }])

    const body = JSON.parse(fetchMock.mock.calls[0][1].body)
    expect(body.action).toBe('delete')
    expect(body.table).toBe('pois')
    expect(body.filters).toEqual([{ column: 'id', op: 'eq', value: 'poi-1' }])
  })

  it('adminUpsert includes onConflict option', async () => {
    fetchMock.mockResolvedValueOnce({
      ok: true,
      json: () => Promise.resolve({}),
    })

    await adminUpsert('poi_premium_content', { poi_id: 'poi-1', text_content: 'hello' }, 'poi_id')

    const body = JSON.parse(fetchMock.mock.calls[0][1].body)
    expect(body.action).toBe('upsert')
    expect(body.table).toBe('poi_premium_content')
    expect(body.data).toEqual({ poi_id: 'poi-1', text_content: 'hello' })
    expect(body.options).toEqual({ onConflict: 'poi_id' })
  })

  it('adminUpsert without onConflict omits options', async () => {
    fetchMock.mockResolvedValueOnce({
      ok: true,
      json: () => Promise.resolve({}),
    })

    await adminUpsert('poi_premium_content', { poi_id: 'poi-1' })

    const body = JSON.parse(fetchMock.mock.calls[0][1].body)
    expect(body.options).toBeUndefined()
  })

  it('adminRpc includes rpcName and rpcParams', async () => {
    fetchMock.mockResolvedValueOnce({
      ok: true,
      json: () => Promise.resolve({ data: 'city_access' }),
    })

    await adminRpc('get_poi_access', { p_poi_id: 'poi-1' })

    const body = JSON.parse(fetchMock.mock.calls[0][1].body)
    expect(body.action).toBe('rpc')
    expect(body.rpcName).toBe('get_poi_access')
    expect(body.rpcParams).toEqual({ p_poi_id: 'poi-1' })
  })

  it('getAuthHeaders extracts JWT from session', async () => {
    fetchMock.mockResolvedValueOnce({
      ok: true,
      json: () => Promise.resolve({ data: [] }),
    })

    await adminSelect('pois')

    const headers = fetchMock.mock.calls[0][1].headers
    expect(headers.Authorization).toBe('Bearer test-jwt-token')
    expect(headers['Content-Type']).toBe('application/json')
    expect(headers.apikey).toBe(import.meta.env.VITE_SUPABASE_ANON_KEY)
  })

  it('error response propagation', async () => {
    fetchMock.mockResolvedValueOnce({
      ok: false,
      status: 403,
      json: () => Promise.resolve({ error: 'Forbidden' }),
    })

    const result = await adminSelect('pois')
    expect(result.error).toBe('Forbidden')
    expect(result.data).toBeNull()
  })

  it('error without message uses status fallback', async () => {
    fetchMock.mockResolvedValueOnce({
      ok: false,
      status: 500,
      json: () => Promise.resolve({}),
    })

    const result = await adminSelect('pois')
    expect(result.error).toBe('Request failed with status 500')
  })
})
