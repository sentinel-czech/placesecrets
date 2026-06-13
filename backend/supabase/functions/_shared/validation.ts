export const UUID_RE = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i
export const PIN_RE = /^\d{6}$/
export const DEVICE_ID_RE = /^[a-zA-Z0-9_-]{1,128}$/
export const VALID_COLUMN_NAME = /^[a-zA-Z_][a-zA-Z0-9_]*$/
export const VALID_ON_CONFLICT = /^[a-zA-Z_][a-zA-Z0-9_]*(,[a-zA-Z_][a-zA-Z0-9_]*)*$/

export const VALID_PAYMENT_METHODS = ['stripe', 'google_pay', 'apple_pay', 'revolut', 'admin_grant'] as const
export const VALID_PURCHASE_TYPES = ['poi', 'city_premium'] as const

export const ALLOWED_TABLES = [
  'cities', 'pois', 'poi_types', 'admin_users', 'admin_users_view', 'admin_stats',
  'payment_receipts', 'user_access', 'contributor_profiles', 'payment_config',
  'free_visit_log', 'poi_premium_content', 'user_poi_purchases',
  'user_city_premium_purchases', 'user_country_purchases', 'user_all_purchases',
  'landing_config',
] as const

export const READ_ONLY_TABLES = ['admin_users_view', 'admin_stats', 'user_all_purchases'] as const

export const BLOCKED_COLUMNS: Record<string, string[]> = {
  admin_users: ['pin_hash', 'pin_attempts', 'pin_locked_until'],
  payment_config: ['stripe_secret_key'],
}

export const ALLOWED_STORAGE_BUCKETS = ['poi-photos', 'audio-guides', 'payment-receipts', 'premium-audio'] as const

export const ALLOWED_ORIGINS = [
  'https://admin.placesecrets.app',
  'http://localhost:5173',
  'http://localhost:4173',
] as const

export const WRITE_ROLES = ['superadmin', 'editor'] as const
export const ADMIN_ROLES = ['superadmin', 'editor', 'viewer'] as const

export function validateUUID(id: string): boolean {
  return UUID_RE.test(id)
}

export function validatePurchaseType(type: string): boolean {
  return (VALID_PURCHASE_TYPES as readonly string[]).includes(type)
}

export function validateColumnName(name: string): boolean {
  return VALID_COLUMN_NAME.test(name)
}

export function validateOnConflict(value: string): boolean {
  return VALID_ON_CONFLICT.test(value)
}

export function isBlockedColumn(table: string, column: string): boolean {
  const blocked = BLOCKED_COLUMNS[table]
  return blocked ? blocked.includes(column) : false
}

export function parseAmountCents(amountTotal: number | null): number | null {
  if (amountTotal == null) return null
  return amountTotal / 100
}

export function validateSelectClause(select: string, table: string): string | null {
  const blocked = BLOCKED_COLUMNS[table]
  if (!blocked) return null
  const columns = select.split(',').map(c => c.trim().split('(')[0].trim())
  for (const col of columns) {
    if (col === '*') return `Wildcard select not allowed on ${table}`
    if (blocked.includes(col)) return `Column '${col}' not accessible`
  }
  return null
}

export function isTableAllowed(table: string): boolean {
  return (ALLOWED_TABLES as readonly string[]).includes(table)
}

export function isTableReadOnly(table: string): boolean {
  return (READ_ONLY_TABLES as readonly string[]).includes(table)
}

export function isStorageBucketAllowed(bucket: string): boolean {
  return (ALLOWED_STORAGE_BUCKETS as readonly string[]).includes(bucket)
}

export function canRoleWrite(role: string): boolean {
  return (WRITE_ROLES as readonly string[]).includes(role)
}

export function getOriginHeader(origin: string | null): string {
  if (origin && (ALLOWED_ORIGINS as readonly string[]).includes(origin)) return origin
  return ALLOWED_ORIGINS[0]
}
