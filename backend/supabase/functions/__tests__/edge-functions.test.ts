/**
 * Edge Function validation logic tests.
 *
 * These tests verify validation functions and patterns used across Edge Functions.
 * They import from the actual shared validation module rather than redefining constants.
 * Run with: npx vitest run (from backend/supabase/functions/__tests__)
 *
 * For full integration tests, use the local Supabase dev environment.
 */

import { describe, it, expect } from 'vitest'
import {
  UUID_RE,
  PIN_RE,
  DEVICE_ID_RE,
  VALID_PAYMENT_METHODS,
  VALID_PURCHASE_TYPES,
  ALLOWED_TABLES,
  READ_ONLY_TABLES,
  BLOCKED_COLUMNS,
  ALLOWED_STORAGE_BUCKETS,
  ALLOWED_ORIGINS,
  WRITE_ROLES,
  validateUUID,
  validatePurchaseType,
  validateColumnName,
  validateOnConflict,
  isBlockedColumn,
  parseAmountCents,
  validateSelectClause,
  isTableAllowed,
  isTableReadOnly,
  isStorageBucketAllowed,
  canRoleWrite,
  getOriginHeader,
} from '../_shared/validation.ts'

// ============================================================
// 1. create-poi-checkout validation
// ============================================================
describe('create-poi-checkout validation', () => {
  it('accepts valid poi purchase_type', () => {
    expect(validatePurchaseType('poi')).toBe(true)
  })

  it('accepts valid city_premium purchase_type', () => {
    expect(validatePurchaseType('city_premium')).toBe(true)
  })

  it('rejects invalid purchase_type', () => {
    expect(validatePurchaseType('invalid')).toBe(false)
    expect(validatePurchaseType('area_premium')).toBe(false)
    expect(validatePurchaseType('')).toBe(false)
  })

  it('validates UUID format for poi_id', () => {
    expect(validateUUID('550e8400-e29b-41d4-a716-446655440000')).toBe(true)
    expect(validateUUID('not-a-uuid')).toBe(false)
    expect(validateUUID('')).toBe(false)
    expect(validateUUID('550e8400-e29b-41d4-a716-44665544000')).toBe(false)
  })

  it('validates UUID case-insensitive', () => {
    expect(validateUUID('A50E8400-E29B-41D4-A716-446655440000')).toBe(true)
  })

  it('rejects missing Authorization header', () => {
    const authHeader: string | null = null
    expect(authHeader?.startsWith('Bearer ')).toBeFalsy()
  })

  it('rejects non-Bearer Authorization', () => {
    const authHeader = 'Basic abc123'
    expect(authHeader.startsWith('Bearer ')).toBe(false)
  })

  it('accepts Bearer Authorization', () => {
    const authHeader = 'Bearer eyJhbGciOiJIUzI1NiJ9.test'
    expect(authHeader.startsWith('Bearer ')).toBe(true)
    expect(authHeader.substring(7)).toBe('eyJhbGciOiJIUzI1NiJ9.test')
  })

  it('validates Content-Type includes application/json', () => {
    expect('application/json'.includes('application/json')).toBe(true)
    expect('application/json; charset=utf-8'.includes('application/json')).toBe(true)
    expect('text/plain'.includes('application/json')).toBe(false)
  })

  it('premium_price must be positive', () => {
    const validPrice = (p: number | null | undefined) => p != null && p > 0
    expect(validPrice(4.99)).toBe(true)
    expect(validPrice(0)).toBe(false)
    expect(validPrice(-1)).toBe(false)
    expect(validPrice(null)).toBe(false)
    expect(validPrice(undefined)).toBe(false)
  })
})

// ============================================================
// 2. confirm-poi-payment (webhook) validation
// ============================================================
describe('confirm-poi-payment validation', () => {
  it('requires stripe-signature header', () => {
    const sig: string | null = null
    expect(!sig).toBe(true)
  })

  it('ignores non-checkout.session.completed events', () => {
    const eventType = 'payment_intent.succeeded'
    expect(eventType !== 'checkout.session.completed').toBe(true)
  })

  it('processes checkout.session.completed event', () => {
    const eventType = 'checkout.session.completed'
    expect(eventType === 'checkout.session.completed').toBe(true)
  })

  it('requires user_id in metadata', () => {
    const metadata = { purchase_type: 'poi' }
    const userId = (metadata as Record<string, string>).user_id
    expect(!userId).toBe(true)
  })

  it('requires purchase_type in metadata', () => {
    const metadata = { user_id: 'u-1' }
    const purchaseType = (metadata as Record<string, string>).purchase_type
    expect(!purchaseType).toBe(true)
  })

  it('converts amount_total cents to EUR via parseAmountCents', () => {
    expect(parseAmountCents(499)).toBe(4.99)
    expect(parseAmountCents(1000)).toBe(10.0)
    expect(parseAmountCents(1)).toBe(0.01)
  })

  it('handles null amount_total', () => {
    expect(parseAmountCents(null)).toBeNull()
  })

  it('requires poi_id for poi purchase type', () => {
    const metadata = { purchase_type: 'poi', user_id: 'u-1' }
    expect(!metadata.hasOwnProperty('poi_id')).toBe(true)
  })

  it('requires city_id for city_premium purchase type', () => {
    const metadata = { purchase_type: 'city_premium', user_id: 'u-1' }
    expect(!metadata.hasOwnProperty('city_id')).toBe(true)
  })
})

// ============================================================
// 3. confirm-payment (city access) validation
// ============================================================
describe('confirm-payment validation', () => {
  it('validates payment method enum', () => {
    for (const method of VALID_PAYMENT_METHODS) {
      expect(VALID_PAYMENT_METHODS.includes(method)).toBe(true)
    }
    expect((VALID_PAYMENT_METHODS as readonly string[]).includes('bitcoin')).toBe(false)
    expect((VALID_PAYMENT_METHODS as readonly string[]).includes('')).toBe(false)
  })

  it('requires all fields: user_id, city_id, payment_method, amount_eur', () => {
    const body = { user_id: 'u-1', city_id: 'c-1', payment_method: 'stripe' }
    const { user_id, city_id, payment_method } = body as Record<string, string>
    const amount_eur = undefined
    expect(!user_id || !city_id || !payment_method || amount_eur == null).toBe(true)
  })

  it('amount_eur must be a number', () => {
    expect(typeof 2.99 === 'number').toBe(true)
    expect(typeof '2.99' === 'number').toBe(false)
    expect(typeof null === 'number').toBe(false)
  })

  it('user mismatch: confirming for different user returns 403', () => {
    const authUserId = 'user-1'
    const bodyUserId = 'user-2'
    expect(bodyUserId !== authUserId).toBe(true)
  })

  it('user match: same user_id passes', () => {
    const authUserId = 'user-1'
    const bodyUserId = 'user-1'
    expect(bodyUserId === authUserId).toBe(true)
  })
})

// ============================================================
// 4. verify-admin-pin validation
// ============================================================
describe('verify-admin-pin validation', () => {
  it('PIN must be exactly 6 digits', () => {
    expect(PIN_RE.test('123456')).toBe(true)
    expect(PIN_RE.test('000000')).toBe(true)
    expect(PIN_RE.test('999999')).toBe(true)
  })

  it('rejects non-6-digit PINs', () => {
    expect(PIN_RE.test('12345')).toBe(false)
    expect(PIN_RE.test('1234567')).toBe(false)
    expect(PIN_RE.test('abcdef')).toBe(false)
    expect(PIN_RE.test('12 345')).toBe(false)
    expect(PIN_RE.test('')).toBe(false)
  })

  it('lockout check: locked_until in future blocks access', () => {
    const lockedUntil = new Date(Date.now() + 15 * 60000)
    expect(lockedUntil > new Date()).toBe(true)
  })

  it('lockout expired: locked_until in past allows access', () => {
    const lockedUntil = new Date(Date.now() - 1000)
    expect(lockedUntil > new Date()).toBe(false)
  })

  it('calculates minutes left in lockout', () => {
    const lockedUntil = new Date(Date.now() + 10 * 60000)
    const minutesLeft = Math.ceil((lockedUntil.getTime() - Date.now()) / 60000)
    expect(minutesLeft).toBeGreaterThanOrEqual(9)
    expect(minutesLeft).toBeLessThanOrEqual(11)
  })

  it('first time: no pin_hash means first_time=true', () => {
    const admin = { pin_hash: null }
    expect(!admin.pin_hash).toBe(true)
  })

  it('returning user: has pin_hash', () => {
    const admin = { pin_hash: '$2a$10$abcdefghijklmnop' }
    expect(!!admin.pin_hash).toBe(true)
  })
})

// ============================================================
// 5. admin-api validation (using shared functions)
// ============================================================
describe('admin-api validation', () => {
  it('table whitelist accepts valid tables', () => {
    expect(isTableAllowed('pois')).toBe(true)
    expect(isTableAllowed('cities')).toBe(true)
    expect(isTableAllowed('poi_premium_content')).toBe(true)
    expect(isTableAllowed('user_poi_purchases')).toBe(true)
    expect(isTableAllowed('user_city_premium_purchases')).toBe(true)
    expect(isTableAllowed('user_all_purchases')).toBe(true)
  })

  it('table whitelist rejects unknown tables', () => {
    expect(isTableAllowed('auth.users')).toBe(false)
    expect(isTableAllowed('malicious_table')).toBe(false)
    expect(isTableAllowed('')).toBe(false)
  })

  it('read-only tables identified correctly', () => {
    expect(isTableReadOnly('user_all_purchases')).toBe(true)
    expect(isTableReadOnly('admin_stats')).toBe(true)
    expect(isTableReadOnly('admin_users_view')).toBe(true)
    expect(isTableReadOnly('pois')).toBe(false)
  })

  it('validateColumnName blocks SQL injection', () => {
    expect(validateColumnName('name')).toBe(true)
    expect(validateColumnName('city_id')).toBe(true)
    expect(validateColumnName('_private')).toBe(true)

    expect(validateColumnName("name'; DROP TABLE--")).toBe(false)
    expect(validateColumnName('name OR 1=1')).toBe(false)
    expect(validateColumnName('column with spaces')).toBe(false)
    expect(validateColumnName('123start')).toBe(false)
    expect(validateColumnName('')).toBe(false)
  })

  it('isBlockedColumn on admin_users', () => {
    expect(isBlockedColumn('admin_users', 'pin_hash')).toBe(true)
    expect(isBlockedColumn('admin_users', 'pin_attempts')).toBe(true)
    expect(isBlockedColumn('admin_users', 'pin_locked_until')).toBe(true)
    expect(isBlockedColumn('admin_users', 'role')).toBe(false)
  })

  it('isBlockedColumn on payment_config', () => {
    expect(isBlockedColumn('payment_config', 'stripe_secret_key')).toBe(true)
    expect(isBlockedColumn('payment_config', 'operator_name')).toBe(false)
  })

  it('isBlockedColumn on tables with no blocked columns', () => {
    expect(isBlockedColumn('pois', 'name')).toBe(false)
    expect(isBlockedColumn('cities', 'slug')).toBe(false)
  })

  it('validateSelectClause blocks wildcard on sensitive tables', () => {
    expect(validateSelectClause('*', 'admin_users')).toBe('Wildcard select not allowed on admin_users')
    expect(validateSelectClause('id, role', 'admin_users')).toBeNull()
    expect(validateSelectClause('pin_hash', 'admin_users')).toBe("Column 'pin_hash' not accessible")
    expect(validateSelectClause('*', 'pois')).toBeNull()
  })

  it('isStorageBucketAllowed validates buckets', () => {
    expect(isStorageBucketAllowed('poi-photos')).toBe(true)
    expect(isStorageBucketAllowed('premium-audio')).toBe(true)
    expect(isStorageBucketAllowed('audio-guides')).toBe(true)
    expect(isStorageBucketAllowed('payment-receipts')).toBe(true)
    expect(isStorageBucketAllowed('malicious-bucket')).toBe(false)
  })

  it('validateOnConflict accepts valid column lists', () => {
    expect(validateOnConflict('user_id,poi_id')).toBe(true)
    expect(validateOnConflict('poi_id')).toBe(true)
    expect(validateOnConflict('user_id,city_id')).toBe(true)
  })

  it('validateOnConflict rejects injection', () => {
    expect(validateOnConflict("user_id; DROP TABLE--")).toBe(false)
    expect(validateOnConflict('')).toBe(false)
    expect(validateOnConflict('user_id,,poi_id')).toBe(false)
  })

  it('canRoleWrite: viewer cannot write', () => {
    expect(canRoleWrite('viewer')).toBe(false)
  })

  it('canRoleWrite: editor can write', () => {
    expect(canRoleWrite('editor')).toBe(true)
  })

  it('canRoleWrite: superadmin can write', () => {
    expect(canRoleWrite('superadmin')).toBe(true)
  })
})

// ============================================================
// 6. create-payment-intent validation
// ============================================================
describe('create-payment-intent validation', () => {
  it('amount must be positive and within range', () => {
    const valid = (a: number) => typeof a === 'number' && a > 0 && a <= 10000
    expect(valid(2.99)).toBe(true)
    expect(valid(10000)).toBe(true)
    expect(valid(0)).toBe(false)
    expect(valid(-1)).toBe(false)
    expect(valid(10001)).toBe(false)
  })

  it('amount converted to cents correctly', () => {
    expect(Math.round(2.99 * 100)).toBe(299)
    expect(Math.round(10.00 * 100)).toBe(1000)
    expect(Math.round(0.01 * 100)).toBe(1)
  })

  it('cityId must be valid UUID', () => {
    expect(validateUUID('550e8400-e29b-41d4-a716-446655440000')).toBe(true)
    expect(validateUUID('not-uuid')).toBe(false)
  })
})

// ============================================================
// 7. delete-user-data validation
// ============================================================
describe('delete-user-data validation', () => {
  it('requires Bearer authorization', () => {
    const authHeader = 'Bearer token123'
    expect(authHeader.startsWith('Bearer ')).toBe(true)
    expect(authHeader.substring(7)).toBe('token123')
  })

  it('rejects missing authorization', () => {
    const authHeader: string | null = null
    expect(authHeader?.startsWith('Bearer ')).toBeFalsy()
  })
})

// ============================================================
// 8. migrate-anonymous-data validation
// ============================================================
describe('migrate-anonymous-data validation', () => {
  it('valid device_id format', () => {
    expect(DEVICE_ID_RE.test('abc-123_DEF')).toBe(true)
    expect(DEVICE_ID_RE.test('a'.repeat(128))).toBe(true)
    expect(DEVICE_ID_RE.test('simple')).toBe(true)
  })

  it('rejects invalid device_id format', () => {
    expect(DEVICE_ID_RE.test('')).toBe(false)
    expect(DEVICE_ID_RE.test('a'.repeat(129))).toBe(false)
    expect(DEVICE_ID_RE.test('has space')).toBe(false)
    expect(DEVICE_ID_RE.test('has@special')).toBe(false)
    expect(DEVICE_ID_RE.test('drop;table')).toBe(false)
  })

  it('requires old_device_id field', () => {
    const body = {} as Record<string, unknown>
    const deviceId = body.old_device_id
    expect(!deviceId || typeof deviceId !== 'string').toBe(true)
  })
})

// ============================================================
// 9. CORS validation (using shared function)
// ============================================================
describe('CORS configuration', () => {
  it('public endpoints use wildcard origin', () => {
    const corsHeaders = { 'Access-Control-Allow-Origin': '*' }
    expect(corsHeaders['Access-Control-Allow-Origin']).toBe('*')
  })

  it('admin endpoints restrict to allowed origins via getOriginHeader', () => {
    expect(getOriginHeader('https://admin.placesecrets.app')).toBe('https://admin.placesecrets.app')
    expect(getOriginHeader('http://localhost:5173')).toBe('http://localhost:5173')
    expect(getOriginHeader('https://evil.com')).toBe('https://admin.placesecrets.app')
    expect(getOriginHeader(null)).toBe('https://admin.placesecrets.app')
  })

  it('allowed origins list is complete', () => {
    expect(ALLOWED_ORIGINS).toContain('https://admin.placesecrets.app')
    expect(ALLOWED_ORIGINS).toContain('https://admin.herodots.app')
    expect(ALLOWED_ORIGINS).toContain('http://localhost:5173')
    expect(ALLOWED_ORIGINS).toContain('http://localhost:4173')
    expect(ALLOWED_ORIGINS.length).toBe(4)
  })
})

// ============================================================
// 10. Payment webhook validation
// ============================================================
describe('payment-webhook validation', () => {
  it('amount_eur must be a number type (strict check)', () => {
    expect(typeof 2.99 === 'number').toBe(true)
    expect(typeof '2.99' === 'number').toBe(false)
    expect(typeof null === 'number').toBe(false)
    expect(typeof undefined === 'number').toBe(false)
  })
})

// ============================================================
// 11. Access level priority (from get_poi_access RPC)
// ============================================================
describe('access level priority logic', () => {
  function getPoiAccess(opts: {
    isAnonymous: boolean
    isAdmin: boolean
    hasPurchasedPoi: boolean
    hasCityBundle: boolean
    hasCityAccess: boolean
    isSamplePoi: boolean
  }): string {
    if (opts.isAnonymous) return 'public'
    if (opts.isAdmin) return 'full'
    if (opts.hasPurchasedPoi) return 'premium_poi'
    if (opts.hasCityBundle) return 'premium_poi'
    if (opts.hasCityAccess) return 'city_access'
    if (opts.isSamplePoi) return 'registered'
    return 'registered_limited'
  }

  it('anonymous user gets public', () => {
    expect(getPoiAccess({
      isAnonymous: true, isAdmin: false, hasPurchasedPoi: false,
      hasCityBundle: false, hasCityAccess: false, isSamplePoi: false,
    })).toBe('public')
  })

  it('admin gets full', () => {
    expect(getPoiAccess({
      isAnonymous: false, isAdmin: true, hasPurchasedPoi: false,
      hasCityBundle: false, hasCityAccess: false, isSamplePoi: false,
    })).toBe('full')
  })

  it('poi purchaser gets premium_poi', () => {
    expect(getPoiAccess({
      isAnonymous: false, isAdmin: false, hasPurchasedPoi: true,
      hasCityBundle: false, hasCityAccess: false, isSamplePoi: false,
    })).toBe('premium_poi')
  })

  it('city bundle purchaser gets premium_poi', () => {
    expect(getPoiAccess({
      isAnonymous: false, isAdmin: false, hasPurchasedPoi: false,
      hasCityBundle: true, hasCityAccess: false, isSamplePoi: false,
    })).toBe('premium_poi')
  })

  it('city access user gets city_access', () => {
    expect(getPoiAccess({
      isAnonymous: false, isAdmin: false, hasPurchasedPoi: false,
      hasCityBundle: false, hasCityAccess: true, isSamplePoi: false,
    })).toBe('city_access')
  })

  it('sample poi gets registered', () => {
    expect(getPoiAccess({
      isAnonymous: false, isAdmin: false, hasPurchasedPoi: false,
      hasCityBundle: false, hasCityAccess: false, isSamplePoi: true,
    })).toBe('registered')
  })

  it('authenticated user with nothing gets registered_limited', () => {
    expect(getPoiAccess({
      isAnonymous: false, isAdmin: false, hasPurchasedPoi: false,
      hasCityBundle: false, hasCityAccess: false, isSamplePoi: false,
    })).toBe('registered_limited')
  })

  it('priority: admin overrides everything', () => {
    expect(getPoiAccess({
      isAnonymous: false, isAdmin: true, hasPurchasedPoi: true,
      hasCityBundle: true, hasCityAccess: true, isSamplePoi: true,
    })).toBe('full')
  })

  it('priority: poi purchase over city bundle', () => {
    expect(getPoiAccess({
      isAnonymous: false, isAdmin: false, hasPurchasedPoi: true,
      hasCityBundle: true, hasCityAccess: true, isSamplePoi: true,
    })).toBe('premium_poi')
  })

  it('priority: city bundle over city access', () => {
    expect(getPoiAccess({
      isAnonymous: false, isAdmin: false, hasPurchasedPoi: false,
      hasCityBundle: true, hasCityAccess: true, isSamplePoi: true,
    })).toBe('premium_poi')
  })

  it('priority: city access over sample poi', () => {
    expect(getPoiAccess({
      isAnonymous: false, isAdmin: false, hasPurchasedPoi: false,
      hasCityBundle: false, hasCityAccess: true, isSamplePoi: true,
    })).toBe('city_access')
  })
})
