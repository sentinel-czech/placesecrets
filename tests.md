# PlaceSecrets / HeroDots — Comprehensive Test Plan

All tests are designed against actual business logic, specs, and use cases.
No false positives — every test verifies real behavior.

---

## 1. BACKEND: Database (SQL Integration Tests)

**Tool:** pgTAP or raw SQL assertions run against local Supabase.
**File:** `backend/supabase/tests/database_test.sql`

### 1.1 slugify() Function
- [x] Basic Latin: `'Hello World'` → `'hello-world'`
- [x] Czech diacritics: `'Karlův most'` → `'karluv-most'`
- [x] Multiple spaces: `'one   two'` → `'one-two'`
- [x] Special characters stripped: `'Café & Bar!'` → `'cafe--bar'` (or similar)
- [x] All-diacritics: `'ÁáČčĎďÉéŽž'` → `'aaccesseezz'`
- [x] Empty string: `''` → `''`
- [x] Already-slug: `'my-slug'` → `'my-slug'`

### 1.2 pois_auto_slug Trigger
- [x] INSERT with NULL slug → auto-generates from name->>'cs'
- [x] INSERT with empty string slug → auto-generates
- [x] INSERT with explicit slug → keeps provided slug
- [x] Collision: 2 POIs same city same name → slugs differ (`test`, `test-1`)
- [x] Collision: 3 POIs → `test`, `test-1`, `test-2`
- [x] Different cities, same name → same slug allowed (scoped by city_id)
- [x] Fallback: no 'cs' key, uses 'en' key
- [x] Fallback: no name keys → slug = 'poi'
- [x] UPDATE with slug set to NULL → re-generates

### 1.3 cities_auto_slug Trigger
- [x] INSERT with NULL slug → auto-generates from name (TEXT)
- [x] Collision: 2 cities same name → `prague`, `prague-1`
- [x] Global uniqueness (not scoped by any parent)

### 1.4 get_poi_access(p_poi_id) RPC
- [x] Anonymous user (no JWT) → `'public'`
- [x] Admin user → `'full'`
- [x] User with user_poi_purchases for POI → `'premium_poi'`
- [x] User with user_city_premium_purchases for city → `'premium_poi'`
- [x] User with user_access for city → `'city_access'`
- [x] POI is registered_sample_poi_id for city → `'registered'`
- [x] Authenticated user, no purchases → `'registered_limited'`
- [x] Priority: admin > poi_purchase > city_bundle > city_access > sample > limited
- [x] Non-existent POI → `'registered_limited'` (v_city_id is NULL)

### 1.5 get_poi_by_slug(p_city_slug, p_poi_slug) RPC
- [x] Valid city+poi slug pair → returns full row (poi_id, name, perex, etc.)
- [x] Non-existent city slug → empty result set
- [x] Non-existent poi slug → empty result set
- [x] Returns city_name as TEXT (not JSONB)

### 1.6 user_all_purchases View
- [x] POI purchase appears with purchase_type='poi'
- [x] City premium purchase appears with purchase_type='city_premium'
- [x] City access (user_access) appears with purchase_type='city_access'
- [x] Uses amount_eur from user_access (not amount)
- [x] Uses transaction_id from user_access (not stripe_payment_id)
- [x] security_invoker = true (RLS enforced per calling user)

### 1.7 RLS Policies
- [x] poi_premium_content: POI purchaser can SELECT
- [x] poi_premium_content: city bundle purchaser can SELECT
- [x] poi_premium_content: admin can SELECT
- [x] poi_premium_content: unrelated user cannot SELECT
- [x] poi_premium_content: anonymous cannot SELECT
- [x] user_poi_purchases: user sees own records only
- [x] user_poi_purchases: user cannot see other user's records
- [x] user_city_premium_purchases: user sees own records only
- [x] premium-audio storage: purchaser can access files matching poi_id path
- [x] premium-audio storage: non-purchaser denied

### 1.8 Constraints & Indexes
- [x] UNIQUE(user_id, poi_id) on user_poi_purchases → duplicate INSERT fails
- [x] UNIQUE(user_id, city_id) on user_city_premium_purchases → duplicate fails
- [x] UNIQUE(poi_id) on poi_premium_content → one content per POI
- [x] UNIQUE(slug, city_id) on pois → enforced at index level
- [x] UNIQUE(slug) on cities → enforced at index level
- [x] CHECK(access_level) → invalid value rejected
- [x] ON DELETE CASCADE: delete POI → deletes poi_premium_content, user_poi_purchases
- [x] ON DELETE CASCADE: delete city → deletes user_city_premium_purchases
- [x] registered_sample_poi_id ON DELETE SET NULL → deleting sample POI sets to NULL

### 1.9 Rating Triggers (from 008)
- [x] INSERT rating → pois.avg_rating recalculated
- [x] UPDATE rating → pois.avg_rating recalculated
- [x] Multiple ratings → AVG correctly computed (e.g. 3+5 = 4.0)
- [x] Rating cascade → contributor_profiles.avg_rating, total_ratings update

---

## 2. BACKEND: Edge Functions (Unit + Integration)

**Tool:** Deno test runner (`deno test`) or vitest with fetch mocks.
**Dir:** `backend/supabase/functions/__tests__/`

> **Legend:**
> - `[x]` = Validation function tested (imported from shared module)
> - `[~]` = Validation pattern tested (regex/constant only, not actual handler)
> - `[ ]` = Not tested (requires Deno runtime / Supabase / Stripe mock)

### 2.1 create-poi-checkout
- [ ] Valid 'poi' purchase → returns {url, session_id}
- [ ] Valid 'city_premium' purchase → returns {url, session_id}
- [~] Missing JWT → 401
- [x] Invalid purchase_type → 400 (validatePurchaseType)
- [x] Invalid UUID for poi_id → 400 (validateUUID)
- [ ] Non-existent POI → 404
- [~] POI with no premium_price → 400
- [ ] City with no premium_bundle_price → 400
- [~] Wrong Content-Type → 415
- [ ] OPTIONS request → CORS preflight 200
- [~] Metadata includes user_id, poi_id/city_id, purchase_type

### 2.2 confirm-poi-payment (Stripe webhook)
- [ ] Valid webhook with poi purchase → upserts user_poi_purchases
- [ ] Valid webhook with city_premium → upserts user_city_premium_purchases
- [ ] Invalid Stripe signature → 400
- [~] Missing metadata.user_id → 400
- [~] Missing metadata.purchase_type → 400
- [ ] Duplicate session_id (idempotent) → upsert succeeds, no duplicate
- [~] Non checkout.session.completed event → ignored (200)
- [x] Amount divided by 100 (cents → EUR) (parseAmountCents)

### 2.3 confirm-payment (city access)
- [ ] Valid payment → upserts user_access + creates receipt
- [~] Missing JWT → 401
- [~] User mismatch (confirming for different user) → 403
- [~] amount_eur not a number → 400
- [x] Invalid payment_method enum → 400 (VALID_PAYMENT_METHODS)
- [x] Invalid UUID → 400 (validateUUID)
- [ ] Non-existent city → 404
- [~] Wrong Content-Type → 415

### 2.4 verify-admin-pin
- [~] First time (no pin_hash): sets PIN, returns first_time=true
- [ ] Correct PIN → returns role, resets attempts
- [ ] Wrong PIN → increments attempts, returns 401
- [ ] 5 wrong attempts → 429 with lockout time
- [~] Locked out, correct PIN → still 429 until 15 min passes
- [x] PIN not 6 digits → 400 (PIN_RE)
- [ ] Non-admin user → 403
- [~] Missing JWT → 401

### 2.5 change-admin-pin
- [ ] First time (no existing hash): set new PIN → success
- [ ] Existing hash + correct current PIN + new PIN → changes
- [ ] Existing hash + wrong current PIN → 401
- [x] New PIN not 6 digits → 400 (PIN_RE)
- [ ] Non-admin → 403

### 2.6 admin-api
- [~] POST-only enforcement → GET returns 405
- [~] Content-Type check → wrong type returns 415
- [x] Table whitelist → unknown table returns 400 (isTableAllowed)
- [x] Read-only table enforcement → INSERT on user_all_purchases → 403 (isTableReadOnly)
- [x] Column blocking → SELECT * on admin_users strips pin_hash (validateSelectClause)
- [x] Column name validation → SQL injection in column name → 400 (validateColumnName)
- [x] Storage bucket whitelist → unknown bucket → 403 (isStorageBucketAllowed)
- [x] Role: viewer cannot INSERT → 403 (canRoleWrite)
- [x] Role: editor can INSERT pois → success (canRoleWrite)
- [x] Role: superadmin can DELETE → success (canRoleWrite)
- [ ] Audit logging → action logged to audit_logs
- [ ] RPC whitelist → allowed RPCs pass, unknown RPCs → 400
- [x] onConflict validation → only safe strings accepted (validateOnConflict)
- [x] New tables in whitelist: poi_premium_content, user_poi_purchases, user_city_premium_purchases
- [ ] New RPCs: get_poi_access, get_poi_by_slug
- [x] New storage bucket: premium-audio (isStorageBucketAllowed)

### 2.7 generate-receipt
- [ ] Valid receipt → generates PDF, uploads to storage
- [ ] send_email === true → sends email
- [ ] send_email === 'true' (string) → does NOT send email (strict ===)
- [ ] Non-owner, non-admin → 403
- [ ] Non-existent receipt → 404

### 2.8 stripe-refund
- [ ] Valid admin + payment_intent_id → creates Stripe refund
- [ ] Non-admin → 403
- [ ] Invalid payment_intent_id format → 400
- [ ] Idempotency: same receipt_id → no duplicate refund

### 2.9 payment-webhook
- [ ] Valid webhook secret → upserts user_access
- [ ] Invalid webhook secret (timing-safe comparison) → 400
- [ ] Missing required fields → 400
- [~] amount_eur not a number → 400

### 2.10 delete-user-data
- [ ] Authenticated user → deletes all data + auth user
- [~] Unauthenticated → 401

### 2.11 migrate-anonymous-data
- [x] Valid device_id format → calls RPC (DEVICE_ID_RE)
- [x] Invalid device_id format → 400 (DEVICE_ID_RE)
- [~] Missing JWT → 401

### 2.12 invite-contributor
- [ ] Admin (editor+) → sends invitation email
- [ ] Viewer role → 403
- [ ] Invalid email format → 400
- [ ] Missing fields → 400

### 2.13 create-payment-intent
- [~] Valid amount + cityId → returns client_secret
- [~] Amount <= 0 → 400
- [~] Amount > 10000 → 400
- [x] Invalid UUID → 400 (validateUUID)
- [ ] Non-existent city → 404

### 2.14 CORS (shared)
- [~] Public endpoints: `Access-Control-Allow-Origin: *`
- [x] Admin endpoints: only whitelisted origins (getOriginHeader)
- [ ] OPTIONS → returns correct headers

---

## 3. WEB: Admin Panel (Vitest + React Testing Library)

**Tool:** Vitest + @testing-library/react + msw (Mock Service Worker)
**Dir:** `web/src/__tests__/`

### 3.1 PoiForm Component
- [x] Renders with default values (city_access access level)
- [x] access_level='premium_poi' → shows premium_price field
- [x] access_level='city_access' → hides premium_price field
- [x] access_level change premium→city_access → clears premium_price
- [x] Perex max 300 chars: submit with 301 chars → validation error
- [x] Latitude validation: -91 → error, 90 → ok
- [x] Longitude validation: -181 → error, 180 → ok
- [x] Smart URI preview: shows https://placesecrets.app/place/{citySlug}/{poiSlug}
- [x] Copy button: calls navigator.clipboard.writeText
- [x] Name CS required: empty → validation error
- [x] Form submission: calls onSubmit with transformed data

### 3.2 PremiumContentTab Component (web/src/__tests__/PremiumContentTab.test.tsx — 20 tests)
- [x] Loads existing content on mount (via adminSelect)
- [x] Audio upload: file input → adminStorageUploadUpsert
- [x] Text content: textarea change → state update
- [x] Extra photos: add/remove URL list
- [x] Related POIs: add/remove from dropdown (excludes self)
- [x] Save: calls adminUpsert with poi_id conflict key
- [x] Loading state shown while fetching

### 3.3 PoiEditPage (web/src/__tests__/PoiEditPage.test.tsx — 11 tests)
- [x] Fetches POI data on mount
- [x] Single tab for non-premium POIs
- [x] Two tabs (Basic + Premium) for premium_poi access level
- [x] Save success → toast + navigate to POI list
- [x] Save error → toast, stays on page
- [x] Loading state
- [x] POI not found → error display

### 3.4 CityPricingPage
- [x] Loads city + POIs in parallel
- [x] price_eur shown as read-only
- [x] premium_bundle_price editable
- [x] registered_sample_poi_id dropdown populated with city POIs
- [x] Save: sends adminUpdate with both fields
- [x] Premium POIs table: filtered by access_level='premium_poi'
- [x] Empty bundlePrice → saves as null (not 0)

### 3.5 PurchasesOverviewPage
- [x] Fetches from user_all_purchases view
- [x] Aggregates: total revenue, counts by type
- [x] Null price_paid displayed as '—'
- [x] Date formatted correctly (dd.MM.yyyy HH:mm)
- [x] Badge variants: poi→default, city_premium→secondary, city_access→outline
- [x] Empty list → zero aggregates

### 3.6 PlaceDetailPage (Public Smart URI)
- [x] Calls get_poi_by_slug RPC with route params
- [x] Renders POI name, city name, perex
- [x] Sets og:title, og:description meta tags (Helmet)
- [x] Deep link button: href = placesecrets://place/{citySlug}/{poiSlug}
- [x] Premium price shown when present
- [x] Place not found → error message
- [x] No auth required (public route)

### 3.7 PoisPage (List + Filter)
- [x] Loads POIs with poi_type relation
- [x] Access level filter: all|public|registered|city_access|premium_poi
- [x] Filter toggle updates displayed list
- [x] Access level badge in table
- [x] Rating display: avg (count) or empty
- [x] Edit link navigates to /admin/pois/:id/edit

### 3.8 Auth Store (Zustand)
- [x] initialize(): resolves role from web_user_roles view
- [x] initialize(): contributor role → fetches contributor_profiles
- [x] signIn(): sets user + resolves role
- [x] signOut(): resets all state including adminVerified
- [x] onAuthStateChange: cleans up previous subscription
- [x] Missing contributor profile → still sets role=contributor

### 3.9 Admin-API Client (admin-api.ts)
- [x] adminSelect: builds correct request body with filters
- [x] adminInsert: includes table + data
- [x] adminUpdate: includes table + data + filters
- [x] adminDelete: includes table + filters
- [x] adminUpsert: includes onConflict option
- [x] adminRpc: includes rpcName + rpcParams
- [x] getAuthHeaders: extracts JWT from session
- [x] Error response propagation: {error: string}
- [x] Storage upload: FormData with correct bucket + path

### 3.10 Router Guards
- [x] AdminGuard: unauthenticated → redirect to /login
- [x] AdminGuard: viewer role → allowed (read-only)
- [x] AdminGuard: user role → redirect to /unauthorized
- [x] AccountGuard: authenticated user → allowed
- [x] AccountGuard: unauthenticated → redirect to /login
- [x] Public routes (/place/...) → no auth required

### 3.11 Sidebar Navigation
- [x] Premium Purchases link present
- [x] Settings visible only for superadmin
- [x] Contributors visible for editor+superadmin
- [x] Active NavLink styling
- [x] Sign out clears auth state

---

## 4. FLUTTER: Unit Tests

**Tool:** flutter_test + mockito
**Dir:** `app/test/`

### 4.1 Poi Model (test/domain/models/poi_test.dart)
- [x] PoiAccessLevel.fromString('public') → .public
- [x] PoiAccessLevel.fromString('registered_limited') → .registeredLimited
- [x] PoiAccessLevel.fromString('city_access') → .cityAccess
- [x] PoiAccessLevel.fromString('premium_poi') → .premiumPoi
- [x] PoiAccessLevel.fromString(null) → .cityAccess (default)
- [x] PoiAccessLevel.fromString('invalid') → .cityAccess (default)
- [x] PoiAccessLevel.toDbString() round-trip for all 4 values
- [x] localizedName('cs') → returns cs name
- [x] localizedName('de') → falls back to 'en'
- [x] localizedName('xx') with no 'en' → falls back to first value
- [x] localizedName on empty map → throws (verifies behavior)
- [x] localizedDescription('cs') → returns cs description
- [x] localizedDescription('missing') → returns '' (empty string)
- [x] audioUrlForLang('cs') → returns cs audio URL
- [x] audioUrlForLang('de') → falls back to 'en'
- [x] audioUrlForLang('xx') with no 'en' → returns null
- [x] hasAudioFile('cs') → true when audio exists
- [x] hasAudioFile('xx') → false when no audio
- [x] availableLanguages() → union of audio + description keys
- [x] ratingBadge: avgRating=4.5, totalRatings=10 → '4.5★'
- [x] ratingBadge: totalRatings=4 → null (below threshold)
- [x] ratingBadge: avgRating=null → null
- [x] qualifiesForHoF: totalRatings=10 → true
- [x] qualifiesForHoF: totalRatings=9 → false
- [x] smartUri: slug='bridge', citySlug='prague' → '/place/prague/bridge'
- [x] smartUri: slug=null → null
- [x] smartUri: citySlug=null → null
- [x] accessLevelEnum getter matches accessLevel string
- [x] fromJson: nested cities.slug → extracted to city_slug

### 4.2 PoiRating Model (test/domain/models/poi_rating_test.dart)
- [x] ratingReasonToString(RatingReason.inaccurate) → 'inaccurate'
- [x] ratingReasonToString(RatingReason.tooShort) → 'too_short'
- [x] ratingReasonToString(RatingReason.boring) → 'boring'
- [x] ratingReasonToString(RatingReason.wrongLang) → 'wrong_lang'
- [x] ratingReasonToString(RatingReason.other) → 'other'
- [x] ratingReasonToString(null) → null
- [x] ratingReasonFromString('inaccurate') → RatingReason.inaccurate
- [x] ratingReasonFromString('invalid') → null
- [x] ratingReasonFromString(null) → null
- [x] Round-trip: toStr → fromStr for all enum values

### 4.3 ContributorProfile Model (test/domain/models/contributor_profile_test.dart)
- [x] ratingLabel: avgRating=4.5, totalRatings=10 → '4.5 ★ (10 ratings)'
- [x] ratingLabel: avgRating=null → 'No ratings'
- [x] ratingLabel: totalRatings=0 → 'No ratings'

### 4.4 City Model (test/domain/models/city_test.dart)
- [x] fromJson with all fields including slug, premiumBundlePrice
- [x] fromJson with nullable fields (slug=null, registeredSamplePoiId=null)
- [x] Default priceEur = 1.0

### 4.5 PoiPremiumContent Model (test/domain/models/poi_premium_content_test.dart)
- [x] fromJson with all fields
- [x] fromJson with defaults (empty extraPhotos, relatedPoiIds)
- [x] fromJson with nullable audioUrl, textContent

### 4.6 AccessRepository (test/data/repositories/access_repository_free_visit_test.dart)
- [ ] hasCityAccess: purchase exists, no expiry → true *(requires Supabase mock)*
- [ ] hasCityAccess: purchase exists, validUntil in future → true *(requires Supabase mock)*
- [ ] hasCityAccess: purchase exists, validUntil in past → false *(requires Supabase mock)*
- [ ] hasCityAccess: no purchase → false *(requires Supabase mock)*
- [ ] hasCityAccess: null user → false *(requires Supabase mock)*
- [x] canUseFreeVisit: 0 visits this month → true
- [x] canUseFreeVisit: 1 visit this month → false
- [x] yearMonth format: '2026-03' for March 2026

### 4.7 PoiRepository (test/data/repositories/poi_repository_offline_test.dart)
- [ ] fetchPoisForCity: success → returns POIs + caches in Drift *(requires Supabase mock)*
- [ ] fetchPoisForCity: network error → returns cached POIs *(requires Supabase mock)*
- [ ] fetchPoisForCity: includes cities join for slug *(requires Supabase mock)*
- [ ] getPoiAccess: calls RPC, returns string result *(requires Supabase mock)*
- [ ] getPoiAccess: null response → returns 'none' *(requires Supabase mock)*
- [ ] getPremiumContent: found → returns PoiPremiumContent *(requires Supabase mock)*
- [ ] getPremiumContent: not found → returns null *(requires Supabase mock)*
- [ ] getPoiBySlug: valid → returns map with poi_id *(requires Supabase mock)*
- [ ] getPoiBySlug: not found → returns null *(requires Supabase mock)*
- [ ] getUserPurchasedPoiIds: returns Set<String> of poi_ids *(requires Supabase mock)*
- [ ] getUserPurchasedPoiIds: null user → empty set *(requires Supabase mock)*
- [ ] getUserPurchasedCityBundleIds: returns Set<String> of city_ids *(requires Supabase mock)*
- [x] getPoiAccessOffline: accessLevel='public' → 'full'
- [x] getPoiAccessOffline: accessLevel='registered_limited' → 'registered'
- [x] getPoiAccessOffline: accessLevel='premium_poi', poi purchased → 'full'
- [x] getPoiAccessOffline: accessLevel='premium_poi', bundle purchased → 'full'
- [x] getPoiAccessOffline: accessLevel='premium_poi', nothing purchased → 'city_access'
- [x] getPoiAccessOffline: accessLevel='city_access' → 'city_access'
- [ ] syncPurchasesToLocal: calls Drift upsert for each purchase *(requires Supabase mock)*

### 4.8 PaymentRepository *(requires Supabase mock — not implemented)*
- [ ] createPoiCheckout type='poi': includes poi_id in body
- [ ] createPoiCheckout type='city_premium': includes city_id in body
- [ ] createPoiCheckout: null url in response → throws
- [ ] createPoiCheckout: empty url → throws
- [ ] createPoiCheckout: error message extracted from response

### 4.9 Visit Queries (test/data/local/visit_queries_test.dart)
- [x] searchVisits: escapes '%' in query
- [x] searchVisits: escapes '_' in query
- [x] searchVisits: escapes '\\' in query *(NOTE: LIKE escape ineffective without ESCAPE clause)*
- [x] searchVisits: normal query → no change
- [x] getVisitsInRange: returns visits between dates
- [x] getVisitByPoiId: finds matching visit
- [x] updateNote: persists note text
- [x] searchVisits by name (case insensitive)
- [x] searchVisits by note content
- [x] watchAllVisits: ordered by visitedAt DESC

### 4.10 AppDatabase (test/data/local/app_database_test.dart)
- [x] Schema version = 4
- [x] upsertPurchasedPoi → isPoiPurchased returns true
- [x] isPoiPurchased for non-existent → false
- [x] upsertPurchasedCityBundle → isCityBundlePurchased returns true
- [x] isCityBundlePurchased for non-existent → false
- [x] countFreeVisitsThisMonth: correct month filtering
- [x] Migration v3→v4: creates purchase tables

### 4.10b Drift Migration (test/data/local/drift_migration_test.dart)
- [x] Schema version is 4
- [x] All tables created on fresh database
- [x] purchased_pois table has expected columns
- [x] purchased_city_bundles table has expected columns
- [x] rated_pois table has langCode column (v3 migration)

### 4.11 DeepLinkHandler (test/app/deep_link_handler_test.dart)
- [x] placesecrets://purchase/success → invalidates providers, returns true
- [x] placesecrets://purchase/cancel → returns true (no-op)
- [x] placesecrets://place/prague/bridge → navigates to /place/prague/bridge
- [x] https://placesecrets.app/place/prague/bridge → navigates
- [x] Unknown scheme/path → returns false
- [x] Malformed URI (< 3 segments) → returns false

### 4.12 PaymentService *(requires Platform mocking — not implemented)*
- [ ] availableMethods on Android → includes googlePay, revolut
- [ ] availableMethods on iOS → includes applePay, revolut
- [ ] _confirmPayment: success response → PaymentResult(success: true)
- [ ] _confirmPayment: error response → PaymentResult(success: false, error: msg)
- [ ] Google Pay on iOS → error
- [ ] Apple Pay on Android → error

---

## 5. FLUTTER: Widget Tests

**Tool:** flutter_test + WidgetTester
**Dir:** `app/test/features/`

### 5.1 MapScreen *(requires complex Riverpod/FlutterMap setup — not implemented)*
- [ ] Filter chips: 4 chips displayed (Public, Registered, City Access, Premium)
- [ ] Filter chip toggle: unchecking 'Premium' hides premium POI markers
- [ ] Filter chip toggle: re-checking 'Premium' shows premium POI markers again
- [ ] Marker colors: public=green, registered=blue, cityAccess=orange, premium=amber
- [ ] Premium POI marker shows lock icon
- [ ] Rating badge shown on marker when ratingBadge != null
- [ ] Hall of Fame button shown when nearestCity != null
- [ ] No city → title shows 'PlaceSecrets'

### 5.2 PoiDetailScreen *(requires complex Riverpod/Supabase setup — not implemented)*
- [ ] Perex always shown when present
- [ ] Premium badge shown for premium_poi access level
- [ ] Register CTA shown for public access + none effective access
- [ ] Upgrade CTA shown for premium_poi + non-premium effective access
- [ ] Share button shown when smartUri available
- [ ] Share button hidden when slug missing
- [ ] Rating widget appears after 30 seconds
- [ ] Premium content rendered when available
- [ ] Photo gallery navigates to full-screen on tap

### 5.3 PurchasePoiScreen *(requires Riverpod/Supabase setup — not implemented)*
- [ ] Per-POI option shown when premiumPrice exists
- [ ] Per-POI option hidden when premiumPrice null
- [ ] Bundle option always shown
- [ ] Purchase disabled while _purchasing=true
- [ ] Error message displayed on failure
- [ ] 'Maybe later' button calls context.pop()

### 5.4 PoiBottomSheet Widget (test/features/map/widgets/poi_bottom_sheet_test.dart)
- [x] Displays POI name
- [x] Displays POI description
- [x] Tap triggers onTap callback
- [x] Rating badge shown when present
- [x] Rating badge hidden when null
- [x] Audio icon shown when audio available
- [x] Premium icon shown for premium_poi
- [x] Navigate button triggers onNavigate
- [x] Empty description shows fallback text

### 5.5 PremiumPoiContent Widget (test/features/poi_detail/widgets/premium_poi_content_test.dart)
- [x] Premium badge rendered
- [x] Text content displayed when present
- [x] Extra photos: horizontal list rendered
- [x] Related POIs: list tiles rendered with navigation
- [x] Empty content: only badge shown

### 5.6 SharePoiButton (test/features/poi_detail/widgets/share_poi_button_test.dart)
- [x] Renders IconButton when smartUri exists
- [x] Hidden (SizedBox.shrink) when smartUri is null
- [x] Tap calls Share.share with correct URL

### 5.7 MyPurchasesScreen (test/features/account/my_purchases_screen_test.dart)
- [x] Shows 'No individual purchases' when empty
- [x] Shows 'No city bundles purchased' when empty
- [x] Lists purchased POI IDs
- [x] Lists purchased city bundle IDs
- [x] Loading state renders CircularProgressIndicator

### 5.8 RatingWidget (test/features/poi_detail/widgets/rating_widget_test.dart)
- [x] Renders 5 outline star icons initially
- [x] Renders question text
- [x] Tapping star selects rating (fills stars up to tapped)
- [x] Submit button appears after selecting rating
- [x] Shows already-rated widget when existing rating exists
- [x] Shows reason chips for low rating (1-2 stars)
- [x] Does not show reason chips for high rating (4-5 stars)
- [x] Submit calls repository and shows thank you
- [x] Submit button disabled while submitting

---

## 6. FLUTTER: Integration Tests

**Tool:** integration_test package
**Dir:** `app/integration_test/`

### 6.1 Offline→Online Access Flow *(requires integration_test package + running app — not implemented)*
- [ ] User with purchased POI goes offline → still sees premium content via Drift
- [ ] User comes online → provider re-fetches from server
- [ ] syncPurchasesToLocal populates Drift after Stripe purchase

### 6.2 Smart URI Flow *(requires integration_test package — not implemented)*
- [ ] Deep link placesecrets://place/prague/bridge → resolves → navigates to PoiDetailScreen

### 6.3 Rating Flow *(requires integration_test package — not implemented)*
- [ ] Submit 5-star rating → local cache updated → syncs to Supabase

---

## Implementation Priority

### Phase A: Unit tests (pure logic, no mocking needed)
1. `app/test/domain/models/poi_test.dart` — 4.1
2. `app/test/domain/models/poi_rating_test.dart` — 4.2
3. `app/test/domain/models/contributor_profile_test.dart` — 4.3
4. `app/test/domain/models/city_test.dart` — 4.4
5. `app/test/domain/models/poi_premium_content_test.dart` — 4.5

### Phase B: Unit tests with mocks (repository + service layer)
6. `app/test/data/repositories/access_repository_test.dart` — 4.6
7. `app/test/data/repositories/poi_repository_test.dart` — 4.7
8. `app/test/data/repositories/payment_repository_test.dart` — 4.8
9. `app/test/data/repositories/visit_repository_test.dart` — 4.9
10. `app/test/data/local/app_database_test.dart` — 4.10
11. `app/test/app/deep_link_handler_test.dart` — 4.11

### Phase C: Web tests (vitest setup + component tests)
12. Web vitest config + msw setup
13. `web/src/__tests__/admin-api.test.ts` — 3.9
14. `web/src/__tests__/auth-store.test.ts` — 3.8
15. `web/src/__tests__/PlaceDetailPage.test.tsx` — 3.6
16. `web/src/__tests__/PoiForm.test.tsx` — 3.1
17. `web/src/__tests__/PremiumContentTab.test.tsx` — 3.2
18. `web/src/__tests__/PurchasesOverviewPage.test.tsx` — 3.5
19. `web/src/__tests__/CityPricingPage.test.tsx` — 3.4
20. `web/src/__tests__/PoisPage.test.tsx` — 3.7

### Phase D: Backend tests (requires local Supabase)
21. `backend/supabase/tests/database_test.sql` — 1.*
22. Edge Function mock tests — 2.*

### Phase E: Widget + integration tests
23. Flutter widget tests — 5.*
24. Flutter integration tests — 6.*

---

## Test Infrastructure Needed

### Web (new)
- `vitest` + `@testing-library/react` + `jsdom` — dev dependencies
- `msw` — mock Edge Function HTTP calls
- Setup file: mock Supabase client, mock navigator.clipboard

### Flutter (existing, extend)
- `mockito` already in devDependencies
- Add `@GenerateMocks` annotations for: SupabaseClient, AppDatabase, GoRouter
- Drift in-memory DB for database tests

### Backend (new)
- pgTAP extension or raw SQL assertion scripts
- Deno test runner for Edge Function unit tests
- Mock Stripe API responses

---

## Counts (Implemented / Planned)

| Layer | Implemented | Planned (needs mocking/infra) | Total |
|-------|-------------|-------------------------------|-------|
| Backend DB (SQL) | ~50 assertions | — | ~50 |
| Backend Edge Fn (vitest) | 69 ([x]=26 validated, [~]=17 pattern-only, 26 logic tests) | ~40 integration | ~109 |
| Web Admin (vitest) | 100 | — | 100 |
| Flutter Unit+Widget | 151 | ~34 (Supabase mock) | ~185 |
| Flutter Integration | — | 5 (integration_test) | 5 |
| **Total runnable** | **~321** | **~79** | **~400** |

### Run commands
```bash
cd app && flutter test                                          # 151 tests
cd web && npx vitest run                                        # 98 tests
cd backend/supabase/functions/__tests__ && npx vitest run       # 69 tests
# SQL tests: psql -f backend/supabase/tests/database_test.sql  # ~47 assertions (requires local Supabase)
```
