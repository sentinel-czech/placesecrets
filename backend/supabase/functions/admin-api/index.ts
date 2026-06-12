import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
import { handleAdminCors, getAdminCorsHeaders } from '../_shared/cors.ts'

const ALLOWED_TABLES = [
  'cities', 'pois', 'poi_types', 'admin_users', 'admin_users_view', 'admin_stats',
  'payment_receipts', 'user_access', 'contributor_profiles', 'payment_config',
  'free_visit_log', 'poi_premium_content', 'user_poi_purchases',
  'user_city_premium_purchases', 'user_all_purchases', 'user_profiles',
  'acl_permissions',
  'countries',
  'poi_audio_guides',
  'poi_audio_guide_ratings',
  'poi_ratings',
]

// Sensitive columns that must never be returned via select or written via insert/update/upsert
const BLOCKED_COLUMNS: Record<string, string[]> = {
  admin_users: ['pin_hash', 'pin_attempts', 'pin_locked_until'],
  payment_config: ['stripe_secret_key'],
  user_profiles: ['user_id', 'user_number'],
}

// Tables that only allow read operations (views, stats)
const READ_ONLY_TABLES = ['admin_users_view', 'admin_stats', 'user_all_purchases']

const ALLOWED_FILTER_OPS = ['eq', 'gte', 'lte', 'neq', 'in']

const ALLOWED_STORAGE_BUCKETS = ['poi-photos', 'audio-guides', 'payment-receipts', 'premium-audio']

const VALID_COLUMN_NAME = /^[a-zA-Z_][a-zA-Z0-9_]*$/
const VALID_ON_CONFLICT_COLUMNS = /^[a-zA-Z_][a-zA-Z0-9_]*(,[a-zA-Z_][a-zA-Z0-9_]*)*$/

// Map DB tables to ACL resource names
const TABLE_TO_RESOURCE: Record<string, string> = {
  cities: 'cities',
  pois: 'pois',
  poi_types: 'poi_types',
  admin_users: 'users',
  admin_users_view: 'users',
  user_profiles: 'users',
  payment_receipts: 'payments',
  payment_config: 'payments',
  user_access: 'payments',
  free_visit_log: 'payments',
  contributor_profiles: 'contributors',
  poi_premium_content: 'pois',
  poi_audio_guides: 'audio',
  user_poi_purchases: 'payments',
  user_city_premium_purchases: 'payments',
  user_all_purchases: 'payments',
  acl_permissions: 'acl',
  admin_stats: 'dashboard',
  countries: 'cities',
  poi_audio_guide_ratings: 'audio',
  poi_ratings: 'pois',
}

type Action = 'select' | 'insert' | 'update' | 'delete' | 'upsert' | 'rpc'
  | 'admin.listUsers' | 'admin.getUserById' | 'admin.createUser' | 'admin.deleteUser'
  | 'storage.upload' | 'storage.getPublicUrl'

interface AclPermission {
  resource: string
  can_read: boolean
  can_write: boolean
  can_delete: boolean
}

function json(body: Record<string, unknown>, req: Request, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...getAdminCorsHeaders(req), 'Content-Type': 'application/json' },
  })
}

function err(message: string, req: Request, status = 400): Response {
  return json({ error: message }, req, status)
}

function validateColumnName(name: string): boolean {
  return VALID_COLUMN_NAME.test(name)
}

function validateWriteData(data: Record<string, unknown>, table: string): string | null {
  const blocked = BLOCKED_COLUMNS[table]
  if (!blocked) return null
  for (const key of Object.keys(data)) {
    if (blocked.includes(key)) {
      return `Column '${key}' cannot be written`
    }
  }
  return null
}

function validateSelectClause(select: string, table: string): string | null {
  const blocked = BLOCKED_COLUMNS[table]
  if (!blocked) return null
  const columns = select.split(',').map(c => c.trim().split('(')[0].trim())
  for (const col of columns) {
    if (col === '*') {
      return `Wildcard select not allowed on ${table}; specify columns explicitly`
    }
    if (blocked.includes(col)) {
      return `Column '${col}' not accessible`
    }
  }
  return null
}

function checkAcl(
  permissions: AclPermission[],
  resource: string,
  action: 'read' | 'write' | 'delete'
): boolean {
  const perm = permissions.find(p => p.resource === resource)
  if (!perm) return false
  if (action === 'read') return perm.can_read
  if (action === 'write') return perm.can_write
  if (action === 'delete') return perm.can_delete
  return false
}

function actionToAclOp(action: Action): 'read' | 'write' | 'delete' {
  switch (action) {
    case 'select':
    case 'storage.getPublicUrl':
    case 'admin.listUsers':
    case 'admin.getUserById':
    case 'rpc':
      return 'read'
    case 'insert':
    case 'update':
    case 'upsert':
    case 'storage.upload':
    case 'admin.createUser':
      return 'write'
    case 'delete':
    case 'admin.deleteUser':
      return 'delete'
    default:
      return 'read'
  }
}

async function auditLog(
  supabaseAdmin: ReturnType<typeof createClient>,
  actorId: string,
  action: string,
  targetType: string,
  targetId?: string,
  metadata?: Record<string, unknown>
) {
  try {
    await supabaseAdmin.from('audit_logs').insert({
      actor_id: actorId,
      action,
      target_type: targetType,
      target_id: targetId || null,
      metadata: metadata || null,
    })
  } catch (e) {
    console.error('audit log error:', e)
  }
}

Deno.serve(async (req) => {
  const corsResponse = handleAdminCors(req)
  if (corsResponse) return corsResponse

  // Only accept POST requests
  if (req.method !== 'POST') {
    return err('Method Not Allowed', req, 405)
  }

  const ct = req.headers.get('content-type') ?? ''
  if (!ct.includes('application/json')) {
    return err('Content-Type must be application/json', req, 415)
  }

  try {
    const authHeader = req.headers.get('Authorization')
    if (!authHeader?.startsWith('Bearer ')) {
      return err('Invalid authorization', req, 401)
    }
    const token = authHeader.substring(7)

    const supabaseAdmin = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
      { auth: { persistSession: false } }
    )

    const { data: { user }, error: authError } = await supabaseAdmin.auth.getUser(token)
    if (authError || !user) return err('Invalid token', req, 401)

    // Resolve role from admin_users
    const { data: adminRow } = await supabaseAdmin
      .from('admin_users')
      .select('role')
      .eq('user_id', user.id)
      .maybeSingle()

    const role = adminRow?.role || null

    if (!role) {
      return err('Forbidden: admin access required', req, 403)
    }

    const body = await req.json()
    const { action, table, data, filters, rpcName, rpcParams, options } = body as {
      action: Action
      table?: string
      data?: Record<string, unknown>
      filters?: { column: string; op: string; value: unknown }[]
      rpcName?: string
      rpcParams?: Record<string, unknown>
      options?: Record<string, unknown>
    }

    // Load ACL permissions for this role (superadmin bypasses)
    let permissions: AclPermission[] = []
    let aclAvailable = true
    if (role !== 'superadmin') {
      try {
        const { data: perms, error: aclErr } = await supabaseAdmin.rpc('get_role_permissions', { target_role: role })
        if (aclErr) {
          // ACL RPCs not yet deployed — fall back to legacy hardcoded checks
          aclAvailable = false
        } else {
          permissions = (perms as AclPermission[]) || []
        }
      } catch {
        aclAvailable = false
      }
    }

    // Legacy hardcoded role checks (used when ACL tables not yet migrated)
    // Matches corrected role matrix:
    // editor: POIs R/W, own_pois R/W/D, audio R/W, rest read-only or none
    // contributor: own_pois R/W, audio R/W, own_profile R/W, cities/poi_types/hall_of_fame/dashboard R
    // user: cities/pois/poi_types/hall_of_fame/dashboard/audio R, own_profile R/W
    // viewer: cities/pois/poi_types/hall_of_fame/dashboard R only

    // ACL check helper — superadmin always passes
    function hasPermission(resource: string, op: 'read' | 'write' | 'delete'): boolean {
      if (role === 'superadmin') return true

      // If ACL tables not available, fall back to legacy checks
      if (!aclAvailable) {
        if (role === 'editor') {
          if (op === 'read' && ['cities', 'pois', 'own_pois', 'poi_types', 'hall_of_fame', 'own_profile', 'audio', 'dashboard'].includes(resource)) return true
          if (op === 'write' && ['pois', 'own_pois', 'own_profile', 'audio'].includes(resource)) return true
          if (op === 'delete' && resource === 'own_pois') return true
          return false
        }
        if (role === 'contributor') {
          if (op === 'read' && ['cities', 'own_pois', 'poi_types', 'hall_of_fame', 'own_profile', 'audio', 'dashboard'].includes(resource)) return true
          if (op === 'write' && ['own_pois', 'own_profile', 'audio', 'cities'].includes(resource)) return true
          return false
        }
        if (role === 'user') {
          if (op === 'read' && ['cities', 'pois', 'poi_types', 'hall_of_fame', 'own_profile', 'audio', 'dashboard'].includes(resource)) return true
          if (op === 'write' && resource === 'own_profile') return true
          return false
        }
        if (role === 'viewer') {
          if (op === 'read' && ['cities', 'pois', 'poi_types', 'hall_of_fame', 'dashboard'].includes(resource)) return true
          return false
        }
        return false
      }

      return checkAcl(permissions, resource, op)
    }

    // Determine the ACL operation type
    const aclOp = actionToAclOp(action)

    // Validate filter column names
    if (filters) {
      for (const f of filters) {
        if (!validateColumnName(f.column)) {
          return err('Invalid filter column name', req)
        }
        if (!ALLOWED_FILTER_OPS.includes(f.op)) {
          return err(`Invalid filter operation: ${f.op}`, req)
        }
      }
    }

    // Validate order column name
    if (options?.order) {
      const ord = options.order as { column: string; ascending?: boolean }
      if (!validateColumnName(ord.column)) {
        return err('Invalid order column name', req)
      }
    }

    // Handle auth admin operations
    if (action === 'admin.listUsers') {
      if (!hasPermission('users', 'read')) return err('Forbidden: insufficient permissions', req, 403)
      const { data: usersData, error } = await supabaseAdmin.auth.admin.listUsers()
      if (error) return err('Failed to list users', req, 500)
      return json({ data: usersData }, req)
    }

    if (action === 'admin.getUserById') {
      if (!hasPermission('users', 'read')) return err('Forbidden: insufficient permissions', req, 403)
      const userId = data?.user_id as string
      if (!userId) return err('user_id required', req)
      const { data: userData, error } = await supabaseAdmin.auth.admin.getUserById(userId)
      if (error) return err('Failed to get user', req, 500)
      return json({ data: userData }, req)
    }

    if (action === 'admin.createUser') {
      if (!hasPermission('users', 'write')) return err('Forbidden: insufficient permissions', req, 403)
      const { email, email_confirm, password } = data as {
        email: string; email_confirm?: boolean; password: string
      }
      if (!email || !password) return err('email and password required', req)
      const { data: newUser, error } = await supabaseAdmin.auth.admin.createUser({
        email, email_confirm: email_confirm ?? true, password,
      })
      if (error) {
        console.error('admin.createUser error:', error.message)
        return err('Failed to create user', req, 500)
      }
      await auditLog(supabaseAdmin, user.id, 'admin.createUser', 'auth.users', (newUser as { user?: { id: string } })?.user?.id, { email })
      return json({ data: newUser }, req)
    }

    if (action === 'admin.deleteUser') {
      if (!hasPermission('users', 'delete')) return err('Forbidden: insufficient permissions', req, 403)
      const userId = data?.user_id as string
      if (!userId) return err('user_id required', req)
      const { error } = await supabaseAdmin.auth.admin.deleteUser(userId)
      if (error) {
        console.error('admin.deleteUser error:', error.message)
        return err('Failed to delete user', req, 500)
      }
      await auditLog(supabaseAdmin, user.id, 'admin.deleteUser', 'auth.users', userId)
      return json({ success: true }, req)
    }

    // Handle storage operations
    if (action === 'storage.upload') {
      if (!hasPermission('audio', 'write') && !hasPermission('pois', 'write')) {
        return err('Forbidden: insufficient permissions', req, 403)
      }
      const { bucket, path: storagePath, base64, contentType, upsert } = data as {
        bucket: string; path: string; base64: string; contentType: string; upsert?: boolean
      }
      if (!bucket || !storagePath || !base64) return err('bucket, path, base64 required', req)
      if (!ALLOWED_STORAGE_BUCKETS.includes(bucket)) return err('Invalid storage bucket', req)
      let bytes: Uint8Array
      try {
        bytes = Uint8Array.from(atob(base64), c => c.charCodeAt(0))
      } catch {
        return err('Invalid base64 data', req)
      }
      const { error } = await supabaseAdmin.storage.from(bucket)
        .upload(storagePath, bytes, { contentType, upsert: upsert ?? false })
      if (error) {
        console.error('storage.upload error:', error.message)
        return err('Upload failed', req, 500)
      }
      await auditLog(supabaseAdmin, user.id, 'storage.upload', bucket, storagePath)
      return json({ success: true }, req)
    }

    if (action === 'storage.getPublicUrl') {
      const { bucket, path: storagePath } = data as { bucket: string; path: string }
      if (!bucket || !storagePath) return err('bucket and path required', req)
      if (!ALLOWED_STORAGE_BUCKETS.includes(bucket)) return err('Invalid storage bucket', req)
      const { data: urlData } = supabaseAdmin.storage.from(bucket).getPublicUrl(storagePath)
      return json({ publicUrl: urlData.publicUrl }, req)
    }

    // Handle RPC calls
    if (action === 'rpc') {
      if (!rpcName) return err('rpcName required for RPC action', req)
      const allowedRpcs = [
        'revenue_by_month', 'daily_activity', 'poi_hall_of_fame',
        'poi_hall_of_fame_overall', 'poi_types_stats', 'get_poi_access',
        'get_poi_by_slug', 'get_role_permissions', 'get_all_permissions',
        'check_handle_available',
      ]
      if (!allowedRpcs.includes(rpcName)) return err('RPC not allowed', req)

      // ACL check for ACL RPCs
      if (rpcName === 'get_all_permissions' || rpcName === 'get_role_permissions') {
        if (!hasPermission('acl', 'read')) return err('Forbidden: insufficient permissions', req, 403)
      }

      const { data: rpcData, error } = await supabaseAdmin.rpc(rpcName, rpcParams || {})
      if (error) {
        console.error('RPC error:', error.message)
        return err('RPC call failed', req, 500)
      }
      return json({ data: rpcData }, req)
    }

    // Handle table operations
    if (!table) return err('table is required', req)
    if (!ALLOWED_TABLES.includes(table)) return err('Table not allowed', req)

    // Prevent write operations on read-only tables
    if (READ_ONLY_TABLES.includes(table) && action !== 'select') {
      return err('Table is read-only', req)
    }

    // Resolve ACL resource for this table
    const resource = TABLE_TO_RESOURCE[table] || table

    // For contributor accessing own POIs, use 'own_pois' resource
    const effectiveResource = (role === 'contributor' && (table === 'pois' || table === 'poi_premium_content' || table === 'poi_audio_guides'))
      ? 'own_pois'
      : resource

    // ACL enforcement
    if (!hasPermission(effectiveResource, aclOp)) {
      return err('Forbidden: insufficient permissions', req, 403)
    }

    // Protect superadmin ACL rows from modification
    if (table === 'acl_permissions' && action !== 'select') {
      if (data && (data as Record<string, unknown>).role === 'superadmin') {
        return err('Superadmin permissions cannot be modified', req, 403)
      }
      // Check filters for role=superadmin on update/delete
      if (filters?.some(f => f.column === 'role' && f.value === 'superadmin')) {
        return err('Superadmin permissions cannot be modified', req, 403)
      }
    }

    if (action === 'select') {
      const selectStr = (options?.select as string) || '*'
      // Validate select clause against blocked columns
      const selectErr = validateSelectClause(selectStr, table)
      if (selectErr) return err(selectErr, req)

      let query = supabaseAdmin.from(table).select(selectStr)
      if (filters) {
        for (const f of filters) {
          if (f.op === 'eq') query = query.eq(f.column, f.value)
          else if (f.op === 'gte') query = query.gte(f.column, f.value)
          else if (f.op === 'lte') query = query.lte(f.column, f.value)
          else if (f.op === 'neq') query = query.neq(f.column, f.value)
          else if (f.op === 'in') query = query.in(f.column, f.value as unknown[])
        }
      }
      if (options?.order) {
        const ord = options.order as { column: string; ascending?: boolean }
        query = query.order(ord.column, { ascending: ord.ascending ?? true })
      }
      if (options?.single) {
        const { data: selectData, error } = await query.single()
        if (error) {
          console.error('select.single error:', error.message)
          return err('Record not found', req, error.code === 'PGRST116' ? 404 : 500)
        }
        return json({ data: selectData }, req)
      }
      const { data: selectData, error } = await query
      if (error) {
        console.error('select error:', error.message)
        return err('Query failed', req, 500)
      }
      return json({ data: selectData }, req)
    }

    if (action === 'insert') {
      if (!data) return err('data required for insert', req)

      // Contributor can only create inactive cities (pending admin approval)
      if (role === 'contributor' && table === 'cities') {
        data.is_active = false
      }

      // Auto-set uploaded_by on poi_audio_guides insert
      if (table === 'poi_audio_guides') {
        data.uploaded_by = user.id
      }

      const writeErr1 = validateWriteData(data, table)
      if (writeErr1) return err(writeErr1, req)
      let query = supabaseAdmin.from(table).insert(data)
      if (options?.select) query = query.select(options.select as string)
      if (options?.single) {
        const { data: insertData, error } = await query.single()
        if (error) {
          console.error('insert error:', error.message)
          return err(`Insert failed: ${error.message}`, req, 500)
        }
        await auditLog(supabaseAdmin, user.id, 'insert', table, (insertData as Record<string, unknown>)?.id as string, { data })
        return json({ data: insertData }, req)
      }
      const { data: insertData, error } = await query
      if (error) {
        console.error('insert error:', error.message)
        return err(`Insert failed: ${error.message}`, req, 500)
      }
      await auditLog(supabaseAdmin, user.id, 'insert', table, undefined, { data })
      return json({ data: insertData }, req)
    }

    if (action === 'update') {
      if (!data) return err('data required for update', req)
      const writeErr2 = validateWriteData(data, table)
      if (writeErr2) return err(writeErr2, req)
      let query = supabaseAdmin.from(table).update(data)
      if (filters) {
        for (const f of filters) {
          if (f.op === 'eq') query = query.eq(f.column, f.value)
        }
      }
      const { error } = await query
      if (error) {
        console.error('update error:', error.message)
        return err(`Update failed: ${error.message}`, req, 500)
      }
      await auditLog(supabaseAdmin, user.id, 'update', table, undefined, { filters, data })
      return json({ success: true }, req)
    }

    if (action === 'upsert') {
      if (!data) return err('data required for upsert', req)
      const writeErr3 = validateWriteData(data, table)
      if (writeErr3) return err(writeErr3, req)
      const onConflict = options?.onConflict as string | undefined
      if (onConflict && !VALID_ON_CONFLICT_COLUMNS.test(onConflict)) {
        return err('Invalid onConflict value', req)
      }
      const { error } = await supabaseAdmin.from(table).upsert(data, {
        onConflict: onConflict || undefined,
      })
      if (error) {
        console.error('upsert error:', error.message)
        return err(`Upsert failed: ${error.message}`, req, 500)
      }
      await auditLog(supabaseAdmin, user.id, 'upsert', table, undefined, { data, onConflict })
      return json({ success: true }, req)
    }

    if (action === 'delete') {
      let query = supabaseAdmin.from(table).delete()
      if (filters) {
        for (const f of filters) {
          if (f.op === 'eq') query = query.eq(f.column, f.value)
        }
      }
      const { error } = await query
      if (error) {
        console.error('delete error:', error.message)
        return err(`Delete failed: ${error.message}`, req, 500)
      }
      await auditLog(supabaseAdmin, user.id, 'delete', table, undefined, { filters })
      return json({ success: true }, req)
    }

    return err('Unknown action', req)
  } catch (e) {
    console.error('admin-api error:', e)
    return err('Internal error', req, 500)
  }
})
