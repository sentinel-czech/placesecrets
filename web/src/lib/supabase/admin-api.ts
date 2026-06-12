import { supabase } from './client'

interface AdminApiOptions {
  action: string
  table?: string
  data?: Record<string, unknown>
  filters?: { column: string; op: string; value: unknown }[]
  rpcName?: string
  rpcParams?: Record<string, unknown>
  options?: Record<string, unknown>
}

async function getAuthHeaders(): Promise<Record<string, string>> {
  const { data: { session } } = await supabase.auth.getSession()
  if (!session?.access_token) throw new Error('Not authenticated')
  return {
    Authorization: `Bearer ${session.access_token}`,
    'Content-Type': 'application/json',
  }
}

async function callAdminApi(payload: AdminApiOptions): Promise<{ data?: unknown; error?: string }> {
  const headers = await getAuthHeaders()
  const supabaseUrl = import.meta.env.VITE_SUPABASE_URL

  const res = await fetch(`${supabaseUrl}/functions/v1/admin-api`, {
    method: 'POST',
    headers: {
      ...headers,
      apikey: import.meta.env.VITE_SUPABASE_ANON_KEY,
    },
    body: JSON.stringify(payload),
  })

  const json = await res.json()
  if (!res.ok) {
    return { error: json.error || `Request failed with status ${res.status}` }
  }
  return json
}

// Helper that mimics supabaseAdmin query patterns
export const adminApi = {
  from(table: string) {
    return new AdminQueryBuilder(table)
  },
  rpc(rpcName: string, params?: Record<string, unknown>) {
    return callAdminApi({ action: 'rpc', rpcName, rpcParams: params })
  },
  auth: {
    admin: {
      async listUsers() {
        return callAdminApi({ action: 'admin.listUsers' })
      },
      async getUserById(userId: string) {
        return callAdminApi({ action: 'admin.getUserById', data: { user_id: userId } })
      },
      async createUser(params: { email: string; email_confirm?: boolean; password: string }) {
        return callAdminApi({ action: 'admin.createUser', data: params })
      },
      async deleteUser(userId: string) {
        return callAdminApi({ action: 'admin.deleteUser', data: { user_id: userId } })
      },
    },
  },
  storage: {
    async upload(bucket: string, path: string, file: File) {
      const base64 = await fileToBase64(file)
      return callAdminApi({
        action: 'storage.upload',
        data: { bucket, path, base64, contentType: file.type },
      })
    },
    async uploadWithUpsert(bucket: string, path: string, file: File) {
      const base64 = await fileToBase64(file)
      return callAdminApi({
        action: 'storage.upload',
        data: { bucket, path, base64, contentType: file.type, upsert: true },
      })
    },
    getPublicUrl(bucket: string, path: string) {
      return callAdminApi({
        action: 'storage.getPublicUrl',
        data: { bucket, path },
      })
    },
  },
}

class AdminQueryBuilder {
  private _table: string
  private _filters: { column: string; op: string; value: unknown }[] = []
  private _options: Record<string, unknown> = {}
  private _selectStr = '*'

  constructor(table: string) {
    this._table = table
  }

  select(columns?: string) {
    if (columns) this._selectStr = columns
    this._options.select = this._selectStr
    return this
  }

  eq(column: string, value: unknown) {
    this._filters.push({ column, op: 'eq', value })
    return this
  }

  gte(column: string, value: unknown) {
    this._filters.push({ column, op: 'gte', value })
    return this
  }

  lte(column: string, value: unknown) {
    this._filters.push({ column, op: 'lte', value })
    return this
  }

  order(column: string, opts?: { ascending?: boolean }) {
    this._options.order = { column, ascending: opts?.ascending ?? true }
    return this
  }

  single() {
    this._options.single = true
    return this._execute('select')
  }

  async then(resolve: (value: { data: unknown; error: string | null }) => void) {
    const result = await this._execute('select')
    resolve(result)
  }

  private async _execute(action: string): Promise<{ data: unknown; error: string | null }> {
    const result = await callAdminApi({
      action,
      table: this._table,
      filters: this._filters.length > 0 ? this._filters : undefined,
      options: Object.keys(this._options).length > 0 ? this._options : undefined,
    })
    if (result.error) return { data: null, error: result.error }
    return { data: result.data, error: null }
  }
}

export async function adminSelect(
  table: string,
  opts?: {
    select?: string
    filters?: { column: string; op: string; value: unknown }[]
    order?: { column: string; ascending?: boolean }
    single?: boolean
  }
): Promise<{ data: unknown; error: string | null }> {
  const result = await callAdminApi({
    action: 'select',
    table,
    filters: opts?.filters,
    options: {
      select: opts?.select || '*',
      order: opts?.order,
      single: opts?.single,
    },
  })
  if (result.error) return { data: null, error: result.error }
  return { data: result.data, error: null }
}

export async function adminInsert(
  table: string,
  data: Record<string, unknown>,
  opts?: { select?: string; single?: boolean }
): Promise<{ data: unknown; error: string | null }> {
  const result = await callAdminApi({
    action: 'insert',
    table,
    data,
    options: opts,
  })
  if (result.error) return { data: null, error: result.error }
  return { data: result.data, error: null }
}

export async function adminUpdate(
  table: string,
  data: Record<string, unknown>,
  filters: { column: string; op: string; value: unknown }[]
): Promise<{ error: string | null }> {
  const result = await callAdminApi({
    action: 'update',
    table,
    data,
    filters,
  })
  return { error: result.error || null }
}

export async function adminDelete(
  table: string,
  filters: { column: string; op: string; value: unknown }[]
): Promise<{ error: string | null }> {
  const result = await callAdminApi({
    action: 'delete',
    table,
    filters,
  })
  return { error: result.error || null }
}

export async function adminUpsert(
  table: string,
  data: Record<string, unknown>,
  onConflict?: string
): Promise<{ error: string | null }> {
  const result = await callAdminApi({
    action: 'upsert',
    table,
    data,
    options: onConflict ? { onConflict } : undefined,
  })
  return { error: result.error || null }
}

export async function adminRpc(
  rpcName: string,
  params?: Record<string, unknown>
): Promise<{ data: unknown; error: string | null }> {
  const result = await callAdminApi({
    action: 'rpc',
    rpcName,
    rpcParams: params,
  })
  if (result.error) return { data: null, error: result.error }
  return { data: result.data, error: null }
}

export async function adminAuthListUsers(): Promise<{ data: unknown; error: string | null }> {
  const result = await callAdminApi({ action: 'admin.listUsers' })
  if (result.error) return { data: null, error: result.error }
  return { data: result.data, error: null }
}

export async function adminAuthGetUser(userId: string): Promise<{ data: unknown; error: string | null }> {
  const result = await callAdminApi({ action: 'admin.getUserById', data: { user_id: userId } })
  if (result.error) return { data: null, error: result.error }
  return { data: result.data, error: null }
}

export async function adminAuthCreateUser(
  params: { email: string; email_confirm?: boolean; password: string }
): Promise<{ data: unknown; error: string | null }> {
  const result = await callAdminApi({ action: 'admin.createUser', data: params })
  if (result.error) return { data: null, error: result.error }
  return { data: result.data, error: null }
}

export async function adminStorageUpload(
  bucket: string,
  path: string,
  file: File
): Promise<{ error: string | null }> {
  const base64 = await fileToBase64(file)
  const result = await callAdminApi({
    action: 'storage.upload',
    data: { bucket, path, base64, contentType: file.type },
  })
  return { error: result.error || null }
}

export async function adminStorageUploadUpsert(
  bucket: string,
  path: string,
  file: File
): Promise<{ error: string | null }> {
  const base64 = await fileToBase64(file)
  const result = await callAdminApi({
    action: 'storage.upload',
    data: { bucket, path, base64, contentType: file.type, upsert: true },
  })
  return { error: result.error || null }
}

export async function adminStorageGetPublicUrl(
  bucket: string,
  path: string
): Promise<{ publicUrl: string | null; error: string | null }> {
  const result = await callAdminApi({
    action: 'storage.getPublicUrl',
    data: { bucket, path },
  })
  if (result.error) return { publicUrl: null, error: result.error }
  return { publicUrl: (result as { publicUrl: string }).publicUrl, error: null }
}

async function fileToBase64(file: File): Promise<string> {
  return new Promise((resolve, reject) => {
    const reader = new FileReader()
    reader.onload = () => {
      const result = reader.result as string
      resolve(result.split(',')[1])
    }
    reader.onerror = reject
    reader.readAsDataURL(file)
  })
}
