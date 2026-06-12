# HeroDots / PlaceSecrets — GUI Test Audit

> **Purpose:** Exhaustive inventory of all GUI-level tests for the Web (React) and Mobile (Flutter) apps.  
> **Legend:** `OK` = test exists and passes | `N/A` = awaiting implementation  
> **Generated:** 2026-04-03  
> **Baseline:** Web ~130 tests (14 files) | Flutter ~93 tests (18 files)  
> **Stack:** Web: Vitest + React Testing Library + jsdom | Flutter: flutter_test + Riverpod

---

# PART 1: WEB (React — Vitest + Testing Library)

---

## Chapter 1: Authentication & Authorization

### 1.1 Existing Tests

| Status | Test |
|--------|------|
| OK | `LoginPage.test.tsx` — renders email and password inputs |
| OK | `LoginPage.test.tsx` — renders sign in button |
| OK | `LoginPage.test.tsx` — renders social login buttons (Google, Facebook, Apple) |
| OK | `LoginPage.test.tsx` — renders register link |
| OK | `LoginPage.test.tsx` — shows error on invalid credentials |
| OK | `LoginPage.test.tsx` — navigates to /account/dashboard for admin role |
| OK | `LoginPage.test.tsx` — navigates to /contributor/dashboard for contributor role |
| OK | `LoginPage.test.tsx` — navigates to /account/dashboard for regular user |
| OK | `LoginPage.test.tsx` — button is disabled while loading |
| OK | `auth-store.test.ts` — sets loading false and user null when no session |
| OK | `auth-store.test.ts` — resolves role from web_user_roles view |
| OK | `auth-store.test.ts` — contributor role fetches contributor_profiles |
| OK | `auth-store.test.ts` — sets up auth state change listener |
| OK | `auth-store.test.ts` — missing role row defaults to 'user' |
| OK | `auth-store.test.ts` — signIn sets user and resolves role |
| OK | `auth-store.test.ts` — signIn throws on auth error |
| OK | `auth-store.test.ts` — signOut resets all state |
| OK | `auth-store.test.ts` — setAdminVerified sets true |
| OK | `auth-store.test.ts` — setAdminVerified sets false |
| OK | `auth-store.test.ts` — contributor without profile still sets role |
| OK | `router-guards.test.tsx` — AdminGuard: unauthenticated redirects to /login |
| OK | `router-guards.test.tsx` — AdminGuard: unverified admin redirects to /admin-pin |
| OK | `router-guards.test.tsx` — AdminGuard: verified admin can access protected route |
| OK | `router-guards.test.tsx` — AccountGuard: authenticated user allowed |
| OK | `router-guards.test.tsx` — AccountGuard: unauthenticated redirects to /login |
| OK | `router-guards.test.tsx` — Public routes accessible without auth |

### 1.2 Missing Tests

| Status | Test |
|--------|------|
| N/A | RegisterPage — renders email, handle, password, confirm-password fields |
| N/A | RegisterPage — handle regex rejects invalid formats |
| N/A | RegisterPage — handle availability check (debounced RPC) |
| N/A | RegisterPage — handle taken shows error indicator |
| N/A | RegisterPage — password mismatch shows error |
| N/A | RegisterPage — password too short shows error |
| N/A | RegisterPage — successful signup shows confirmation screen |
| N/A | RegisterPage — submit calls supabase.auth.signUp with metadata |
| N/A | RegisterPage — link to login page works |
| N/A | ContributorRegisterPage — renders handle, email, password fields |
| N/A | ContributorRegisterPage — shows default PIN info (123456) on success |
| N/A | ContributorRegisterPage — successful registration shows success screen with login link |
| N/A | AdminPinPage — renders 6 separate digit inputs |
| N/A | AdminPinPage — typing digit auto-advances to next input |
| N/A | AdminPinPage — backspace moves focus to previous input |
| N/A | AdminPinPage — completing 6 digits auto-submits |
| N/A | AdminPinPage — error response shows error and clears digits |
| N/A | AdminPinPage — must_change_pin navigates to /admin/force-change-pin |
| N/A | ForceChangePinPage — renders new PIN input |
| N/A | ForceChangePinPage — successful change navigates to /admin/dashboard |
| N/A | ForceChangePinPage — redirects if not in mustChangePin state |

### 1.3 Implementation Prompts

#### RegisterPage — renders email, handle, password, confirm-password fields

**File:** `web/src/__tests__/RegisterPage.test.tsx`  
**What:** Verify all form fields render on mount.  
**Setup:** Render `<RegisterPage />` inside `<MemoryRouter>`. Mock `@/lib/supabase/client` and `@/hooks/useAuth`.  
**Steps:**  
1. Render the page  
**Expect:**  
- `screen.getByLabelText(/email/i)` exists  
- `screen.getByLabelText(/handle/i)` or input with `@` prefix exists  
- `screen.getByLabelText(/password/i)` exists (at least 2 password fields)  
- Submit button exists  
**Ref:** `web/src/pages/RegisterPage.tsx`

#### RegisterPage — handle regex rejects invalid formats

**File:** `web/src/__tests__/RegisterPage.test.tsx`  
**What:** Handle field rejects uppercase, special chars, and <3 char values.  
**Setup:** Same as above.  
**Steps:**  
1. Type "AB" into handle field (too short + uppercase)  
2. Check for validation error  
3. Type "valid_user" — no error  
**Expect:**  
- Error indicator visible for invalid handle  
- No error for valid handle (`^[a-z0-9_]{3,50}$`)  
**Ref:** `web/src/pages/RegisterPage.tsx` — handle regex validation

#### RegisterPage — handle availability check (debounced RPC)

**File:** `web/src/__tests__/RegisterPage.test.tsx`  
**What:** After typing a valid handle, the app checks availability via Supabase RPC.  
**Setup:** Mock `supabase.rpc('check_handle_available')` to return `{ available: true }`. Use `vi.useFakeTimers()` for debounce.  
**Steps:**  
1. Type "testhandle" into handle field  
2. Advance timers by 400ms (debounce)  
3. Wait for RPC call  
**Expect:**  
- `supabase.rpc` called with handle param  
- No error shown when available=true  
**Ref:** `web/src/pages/RegisterPage.tsx` — debounced availability check

#### RegisterPage — handle taken shows error indicator

**File:** `web/src/__tests__/RegisterPage.test.tsx`  
**What:** When handle is taken, show error.  
**Setup:** Mock `supabase.rpc('check_handle_available')` to return `{ available: false }`.  
**Steps:**  
1. Type "taken_name" into handle field  
2. Advance timers by 400ms  
**Expect:**  
- Error text/icon visible near handle field  
- Submit button disabled or handle field shows error state  
**Ref:** `web/src/pages/RegisterPage.tsx`

#### RegisterPage — password mismatch shows error

**File:** `web/src/__tests__/RegisterPage.test.tsx`  
**What:** When password !== confirmPassword and user submits, show error and don't call signUp.  
**Setup:** Mock `supabase.auth.signUp` as spy.  
**Steps:**  
1. Fill email: `test@example.com`, handle: `testuser`  
2. Fill password: `Secret123`, confirm: `Different456`  
3. Click submit  
**Expect:**  
- Error message about password mismatch visible  
- `supabase.auth.signUp` NOT called  
**Ref:** `web/src/pages/RegisterPage.tsx`

#### RegisterPage — password too short shows error

**File:** `web/src/__tests__/RegisterPage.test.tsx`  
**What:** Password under minimum length triggers validation error.  
**Setup:** Same mock setup.  
**Steps:**  
1. Fill all fields, password + confirm both = "abc"  
2. Click submit  
**Expect:**  
- Validation error about minimum password length  
- signUp NOT called  
**Ref:** `web/src/pages/RegisterPage.tsx`

#### RegisterPage — successful signup shows confirmation screen

**File:** `web/src/__tests__/RegisterPage.test.tsx`  
**What:** After successful signUp, the page shows a success/confirmation message.  
**Setup:** Mock `supabase.auth.signUp` to resolve successfully.  
**Steps:**  
1. Fill all valid fields  
2. Submit form  
3. Wait for async  
**Expect:**  
- Success confirmation text visible (e.g., "check your email")  
- Link back to login visible  
**Ref:** `web/src/pages/RegisterPage.tsx`

#### RegisterPage — submit calls supabase.auth.signUp with metadata

**File:** `web/src/__tests__/RegisterPage.test.tsx`  
**What:** Form submission passes correct data to Supabase auth.  
**Setup:** Mock `supabase.auth.signUp` as spy.  
**Steps:**  
1. Fill email: `test@example.com`, handle: `myhandle`, password: `Secret123`, confirm: `Secret123`  
2. Submit form  
**Expect:**  
- `supabase.auth.signUp` called with `{ email: 'test@example.com', password: 'Secret123', options: { data: { handle: 'myhandle' } } }`  
**Ref:** `web/src/pages/RegisterPage.tsx`

#### RegisterPage — link to login page works

**File:** `web/src/__tests__/RegisterPage.test.tsx`  
**What:** Login link navigates to /login.  
**Setup:** MemoryRouter.  
**Steps:**  
1. Find link with text matching "sign in" or "login"  
**Expect:**  
- Link has `href="/login"` or equivalent  
**Ref:** `web/src/pages/RegisterPage.tsx`

#### ContributorRegisterPage — renders handle, email, password fields

**File:** `web/src/__tests__/ContributorRegisterPage.test.tsx`  
**What:** Contributor registration form renders all required fields.  
**Setup:** Render `<ContributorRegisterPage />` inside `<MemoryRouter>`. Mock supabase client.  
**Steps:**  
1. Render the page  
**Expect:**  
- Handle input with `@` prefix  
- Email input  
- Password input  
- Submit button  
**Ref:** `web/src/pages/register/ContributorRegisterPage.tsx`

#### ContributorRegisterPage — shows default PIN info on success

**File:** `web/src/__tests__/ContributorRegisterPage.test.tsx`  
**What:** After successful registration, show default PIN info (123456).  
**Setup:** Mock `supabase.auth.signUp` to succeed.  
**Steps:**  
1. Fill all fields with valid data  
2. Submit  
3. Wait for async  
**Expect:**  
- Text containing "123456" visible (default PIN notification)  
- Text about first login / changing PIN  
**Ref:** `web/src/pages/register/ContributorRegisterPage.tsx`

#### ContributorRegisterPage — successful registration shows success screen with login link

**File:** `web/src/__tests__/ContributorRegisterPage.test.tsx`  
**What:** Success state renders login link.  
**Setup:** Same as above.  
**Steps:**  
1. Complete registration successfully  
**Expect:**  
- Link to /login visible  
- Registration form hidden  
**Ref:** `web/src/pages/register/ContributorRegisterPage.tsx`

#### AdminPinPage — renders 6 separate digit inputs

**File:** `web/src/__tests__/AdminPinPage.test.tsx`  
**What:** PIN entry renders 6 individual input fields.  
**Setup:** Render `<AdminPinPage />` in MemoryRouter. Mock useAuth with `{ user: mockUser, role: 'editor', adminVerified: false }`.  
**Steps:**  
1. Render the page  
**Expect:**  
- 6 input elements with maxLength=1 or type="tel"/"text"  
- First input is auto-focused  
**Ref:** `web/src/pages/AdminPinPage.tsx`

#### AdminPinPage — typing digit auto-advances to next input

**File:** `web/src/__tests__/AdminPinPage.test.tsx`  
**What:** Entering a digit in one field auto-focuses the next.  
**Setup:** Same as above.  
**Steps:**  
1. Type "1" in first input  
**Expect:**  
- Second input is now focused  
- First input contains "1"  
**Ref:** `web/src/pages/AdminPinPage.tsx`

#### AdminPinPage — backspace moves focus to previous input

**File:** `web/src/__tests__/AdminPinPage.test.tsx`  
**What:** Pressing backspace on empty input moves focus back.  
**Setup:** Same.  
**Steps:**  
1. Type "12" to advance to third input  
2. Press Backspace  
**Expect:**  
- Focus returns to second input  
- Second input value cleared  
**Ref:** `web/src/pages/AdminPinPage.tsx`

#### AdminPinPage — completing 6 digits auto-submits

**File:** `web/src/__tests__/AdminPinPage.test.tsx`  
**What:** When 6th digit entered, form auto-submits calling verify-admin-pin.  
**Setup:** Mock global `fetch` to return `{ ok: true, json: () => ({ verified: true }) }`. Mock useAuth `setAdminVerified`.  
**Steps:**  
1. Type digits "1", "2", "3", "4", "5", "6" sequentially  
2. Wait for fetch  
**Expect:**  
- `fetch` called with verify-admin-pin endpoint  
- Request body contains pin "123456"  
- `setAdminVerified(true)` called  
**Ref:** `web/src/pages/AdminPinPage.tsx`

#### AdminPinPage — error response shows error and clears digits

**File:** `web/src/__tests__/AdminPinPage.test.tsx`  
**What:** Invalid PIN shows error and resets inputs.  
**Setup:** Mock `fetch` to return `{ ok: false, json: () => ({ error: 'Invalid PIN' }) }`.  
**Steps:**  
1. Enter 6 digits  
2. Wait for response  
**Expect:**  
- Error message visible  
- All 6 inputs cleared  
- First input re-focused  
**Ref:** `web/src/pages/AdminPinPage.tsx`

#### AdminPinPage — must_change_pin navigates to /admin/force-change-pin

**File:** `web/src/__tests__/AdminPinPage.test.tsx`  
**What:** When response includes must_change_pin=true, navigate to force change page.  
**Setup:** Mock `fetch` to return `{ ok: true, json: () => ({ verified: true, must_change_pin: true }) }`. Mock `useNavigate`.  
**Steps:**  
1. Enter valid 6-digit PIN  
2. Wait for response  
**Expect:**  
- `navigate('/admin/force-change-pin')` called  
- `setMustChangePin(true)` called  
**Ref:** `web/src/pages/AdminPinPage.tsx`

#### ForceChangePinPage — renders new PIN input

**File:** `web/src/__tests__/ForceChangePinPage.test.tsx`  
**What:** Page renders PIN change form when mustChangePin is true.  
**Setup:** Mock useAuth with `{ mustChangePin: true, user: mockUser }`. MemoryRouter.  
**Steps:**  
1. Render the page  
**Expect:**  
- New PIN input field exists  
- Submit button exists  
- Informational text about changing PIN  
**Ref:** `web/src/pages/ForceChangePinPage.tsx`

#### ForceChangePinPage — successful change navigates to /admin/dashboard

**File:** `web/src/__tests__/ForceChangePinPage.test.tsx`  
**What:** After successfully changing PIN, navigate to dashboard.  
**Setup:** Mock `fetch` (change-admin-pin endpoint) to succeed. Mock `useNavigate`.  
**Steps:**  
1. Enter new PIN  
2. Submit  
3. Wait for async  
**Expect:**  
- `navigate('/admin/dashboard')` called  
- `setMustChangePin(false)` called  
**Ref:** `web/src/pages/ForceChangePinPage.tsx`

#### ForceChangePinPage — redirects if not in mustChangePin state

**File:** `web/src/__tests__/ForceChangePinPage.test.tsx`  
**What:** If user doesn't need PIN change, redirect away.  
**Setup:** Mock useAuth with `{ mustChangePin: false }`.  
**Steps:**  
1. Render the page  
**Expect:**  
- Navigate called (to dashboard or login)  
- Form NOT rendered  
**Ref:** `web/src/pages/ForceChangePinPage.tsx`

---

## Chapter 2: Landing & Public Pages

### 2.1 Existing Tests

| Status | Test |
|--------|------|
| OK | `LandingPage.test.tsx` — renders hero heading |
| OK | `LandingPage.test.tsx` — has sign in link |
| OK | `LandingPage.test.tsx` — has register link |
| OK | `LandingPage.test.tsx` — renders how-it-works section with 3 features |
| OK | `LandingPage.test.tsx` — renders explore section |
| OK | `LandingPage.test.tsx` — renders download section |
| OK | `LandingPage.test.tsx` — renders featured places section |
| OK | `LandingPage.test.tsx` — renders social auth buttons |
| OK | `LandingPage.test.tsx` — renders testimonials section |
| OK | `LandingPage.test.tsx` — renders footer |
| OK | `PlaceDetailPage.test.tsx` — shows loading state initially |
| OK | `PlaceDetailPage.test.tsx` — renders POI name and city name when found |
| OK | `PlaceDetailPage.test.tsx` — shows premium price when access_level is premium_poi |
| OK | `PlaceDetailPage.test.tsx` — shows Place Not Found when RPC returns empty |
| OK | `PlaceDetailPage.test.tsx` — shows Place Not Found when RPC returns error |
| OK | `PlaceDetailPage.test.tsx` — calls RPC with correct params |
| OK | `PlaceDetailPage.test.tsx` — deep link button uses correct placesecrets:// URL |
| OK | `PlaceDetailPage.test.tsx` — falls back to en name when cs is missing |
| OK | `PlaceDetailPage.test.tsx` — does not show premium price for non-premium POIs |
| OK | `PlaceDetailPage.test.tsx` — only renders languages that have audio guides |
| OK | `PlaceDetailPage.test.tsx` — shows audio guide ratings |
| OK | `PlaceDetailPage.test.tsx` — shows Rate button when logged in |
| OK | `PlaceDetailPage.test.tsx` — does not show Rate button when not logged in |
| OK | `PlaceDetailPage.test.tsx` — sorts preferred language first |

### 2.2 Missing Tests

| Status | Test |
|--------|------|
| N/A | PublicHeader — renders logo and navigation links |
| N/A | PublicHeader — authenticated user sees profile/logout links |
| N/A | PublicHeader — unauthenticated user sees sign-in/register links |
| N/A | PublicFooter — renders footer links and copyright text |
| N/A | Header — renders admin navigation links |
| N/A | Header — user dropdown menu with sign out button |

### 2.3 Implementation Prompts

#### PublicHeader — renders logo and navigation links

**File:** `web/src/__tests__/PublicHeader.test.tsx`  
**What:** Public header shows logo and main navigation.  
**Setup:** Render `<PublicHeader />` in MemoryRouter. Mock `@/hooks/useAuth` with user=null.  
**Steps:** Render component.  
**Expect:**  
- Logo/brand element visible  
- Navigation links present  
**Ref:** `web/src/components/layout/PublicHeader.tsx`

#### PublicHeader — authenticated user sees profile/logout links

**File:** `web/src/__tests__/PublicHeader.test.tsx`  
**What:** When user is logged in, show profile and sign out options.  
**Setup:** Mock useAuth with `{ user: mockUser, role: 'user' }`.  
**Steps:** Render component.  
**Expect:**  
- Profile link or avatar visible  
- Sign out option available  
- Sign-in/register links NOT visible  
**Ref:** `web/src/components/layout/PublicHeader.tsx`

#### PublicHeader — unauthenticated user sees sign-in/register links

**File:** `web/src/__tests__/PublicHeader.test.tsx`  
**What:** When no user, show auth links.  
**Setup:** Mock useAuth with `{ user: null }`.  
**Steps:** Render component.  
**Expect:**  
- Sign in link visible (href="/login")  
- Register link visible (href="/register")  
**Ref:** `web/src/components/layout/PublicHeader.tsx`

#### PublicFooter — renders footer links and copyright text

**File:** `web/src/__tests__/PublicFooter.test.tsx`  
**What:** Footer renders legal links and copyright.  
**Setup:** Render `<PublicFooter />`.  
**Steps:** Render component.  
**Expect:**  
- Copyright text with current year  
- Terms/Privacy links if present  
**Ref:** `web/src/components/layout/PublicFooter.tsx`

#### Header — renders admin navigation links

**File:** `web/src/__tests__/Header.test.tsx`  
**What:** Admin header shows navigation and user info.  
**Setup:** Render `<Header />` in MemoryRouter. Mock useAuth with admin user.  
**Steps:** Render component.  
**Expect:**  
- Navigation elements present  
- User display name or email visible  
**Ref:** `web/src/components/layout/Header.tsx`

#### Header — user dropdown menu with sign out button

**File:** `web/src/__tests__/Header.test.tsx`  
**What:** Clicking user menu shows sign out option.  
**Setup:** Same. Mock useAuth `signOut`.  
**Steps:**  
1. Click user menu trigger  
2. Find sign out button  
**Expect:**  
- Sign out button/link visible in dropdown  
**Ref:** `web/src/components/layout/Header.tsx`

---

## Chapter 3: Cities Management

### 3.1 Existing Tests

| Status | Test |
|--------|------|
| OK | `CityPricingPage.test.tsx` — loads city and POIs in parallel |
| OK | `CityPricingPage.test.tsx` — price_eur shown as read-only |
| OK | `CityPricingPage.test.tsx` — premium_bundle_price editable |
| OK | `CityPricingPage.test.tsx` — save sends adminUpdate |
| OK | `CityPricingPage.test.tsx` — empty bundlePrice saves as null |

### 3.2 Missing Tests

| Status | Test |
|--------|------|
| N/A | CitiesPage — loads cities, countries, and POIs on mount |
| N/A | CitiesPage — search input filters tree by name |
| N/A | CitiesPage — toggle map visibility button |
| N/A | CitiesPage — Add Country inline form renders and submits |
| N/A | CitiesPage — Add Country validation (2-letter code) |
| N/A | CitiesPage — Add City button links to /admin/cities/new |
| N/A | CitiesPage — CityPoiTree renders country > city > POI hierarchy |
| N/A | CitiesPage — city row shows price and active badge |
| N/A | CitiesPage — error state displays error message |
| N/A | CityNewPage — renders CityForm with empty defaults |
| N/A | CityNewPage — submit creates city via adminInsert and navigates |
| N/A | CityNewPage — error shows toast notification |
| N/A | CityEditPage — loads city by ID and populates CityForm |
| N/A | CityEditPage — save calls adminUpdate with correct filters |
| N/A | CityEditPage — not found shows error message |
| N/A | CityForm — renders all fields (name, country, lat, lng, radius, price, active) |
| N/A | CityForm — MapPicker interaction updates coordinates |
| N/A | CityForm — aliases TagInput adds/removes tags |
| N/A | CityForm — validation: name is required |
| N/A | CityForm — submit collects all field values |

### 3.3 Implementation Prompts

#### CitiesPage — loads cities, countries, and POIs on mount

**File:** `web/src/__tests__/CitiesPage.test.tsx`  
**What:** On mount, page fetches cities, countries, and all POIs via adminSelect.  
**Setup:** Mock `adminSelect` with implementation returning data by table name. Mock useAuth admin + hasPermission. MemoryRouter.  
**Steps:** Render page, wait for data.  
**Expect:**  
- `adminSelect` called with table='cities'  
- `adminSelect` called with table='countries'  
- `adminSelect` called with table='pois'  
- City names rendered in tree  
**Ref:** `web/src/pages/cities/CitiesPage.tsx`

#### CitiesPage — search input filters tree by name

**File:** `web/src/__tests__/CitiesPage.test.tsx`  
**What:** Typing in search filters the city/POI tree.  
**Setup:** Same with multiple cities.  
**Steps:**  
1. Wait for data to load  
2. Type "Prague" into search input  
**Expect:**  
- Only matching cities/POIs visible  
- Non-matching items hidden  
**Ref:** `web/src/pages/cities/CitiesPage.tsx`

#### CitiesPage — Add Country inline form renders and submits

**File:** `web/src/__tests__/CitiesPage.test.tsx`  
**What:** Clicking Add Country shows inline form; submitting creates country.  
**Setup:** Mock `adminInsert` to succeed. Mock `sonner.toast.success`.  
**Steps:**  
1. Click "Add Country" button  
2. Fill code: "US", name: "United States"  
3. Click Create  
**Expect:**  
- `adminInsert` called with table='countries', data containing code and name  
- Success toast shown  
**Ref:** `web/src/pages/cities/CitiesPage.tsx`

#### CityNewPage — submit creates city via adminInsert and navigates

**File:** `web/src/__tests__/CityNewPage.test.tsx`  
**What:** Submitting form calls adminInsert and navigates back.  
**Setup:** Mock `adminInsert` to succeed. Mock `useNavigate`. Mock `sonner.toast.success`.  
**Steps:**  
1. Fill required fields (name, coordinates)  
2. Submit form  
**Expect:**  
- `adminInsert` called with table='cities'  
- `navigate('/admin/cities')` called  
**Ref:** `web/src/pages/cities/CityNewPage.tsx`

#### CityEditPage — loads city by ID and populates CityForm

**File:** `web/src/__tests__/CityEditPage.test.tsx`  
**What:** Edit page fetches city data and pre-fills form.  
**Setup:** Mock `adminSelect` to return city data. MemoryRouter with param `:id`.  
**Steps:** Render page, wait for load.  
**Expect:**  
- `adminSelect` called with filters for city ID  
- Form fields populated with city data  
**Ref:** `web/src/pages/cities/CityEditPage.tsx`

#### CityEditPage — save calls adminUpdate with correct filters

**File:** `web/src/__tests__/CityEditPage.test.tsx`  
**What:** Saving calls adminUpdate with city ID filter.  
**Setup:** Same. Mock `adminUpdate`.  
**Steps:**  
1. Wait for data  
2. Change name field  
3. Submit  
**Expect:**  
- `adminUpdate` called with table='cities', filters containing city ID  
**Ref:** `web/src/pages/cities/CityEditPage.tsx`

#### CityForm — renders all fields

**File:** `web/src/__tests__/CityForm.test.tsx`  
**What:** All form fields render correctly.  
**Setup:** Render `<CityForm countries={mockCountries} onSubmit={vi.fn()} />`. Mock MapPicker.  
**Steps:** Render component.  
**Expect:**  
- Name, Country dropdown, Lat, Lng, Radius, Price, Active, Submit button all present  
**Ref:** `web/src/components/cities/CityForm.tsx`

#### CityForm — validation: name is required

**File:** `web/src/__tests__/CityForm.test.tsx`  
**What:** Submitting without name shows validation error.  
**Steps:** Leave name empty, click submit.  
**Expect:** Validation error visible, `onSubmit` NOT called.  
**Ref:** `web/src/components/cities/CityForm.tsx`

---

## Chapter 4: POIs & Content

### 4.1 Existing Tests

| Status | Test |
|--------|------|
| OK | `PoisPage.test.tsx` — shows loading state (7 tests total) |
| OK | `PoisPage.test.tsx` — renders page and loads POIs list |
| OK | `PoisPage.test.tsx` — displays access level filter buttons |
| OK | `PoisPage.test.tsx` — filter toggle updates displayed list |
| OK | `PoisPage.test.tsx` — shows access level badge in table |
| OK | `PoisPage.test.tsx` — has Edit link for each POI |
| OK | `PoisPage.test.tsx` — shows error message when fetch fails |
| OK | `PoiEditPage.test.tsx` — shows loading skeleton (11 tests) |
| OK | `PoiEditPage.test.tsx` — fetches POI data and ratings |
| OK | `PoiEditPage.test.tsx` — renders POI name in heading |
| OK | `PoiEditPage.test.tsx` — renders Basic Info and Ratings tabs |
| OK | `PoiEditPage.test.tsx` — renders Premium Content tab for premium_poi |
| OK | `PoiEditPage.test.tsx` — save success calls adminUpdate |
| OK | `PoiEditPage.test.tsx` — save error shows toast |
| OK | `PoiEditPage.test.tsx` — shows POI not found |
| OK | `PoiEditPage.test.tsx` — shows error on fetch fail |
| OK | `PoiEditPage.test.tsx` — falls back to en name |
| OK | `PoiForm.test.tsx` — renders with default city_access (8 tests) |
| OK | `PoiForm.test.tsx` — premium_poi shows premium_price field |
| OK | `PoiForm.test.tsx` — city_access hides premium_price |
| OK | `PoiForm.test.tsx` — perex textarea max 1500 chars |
| OK | `PoiForm.test.tsx` — smart URI preview |
| OK | `PoiForm.test.tsx` — name_cs required validation |
| OK | `PoiForm.test.tsx` — premium to city_access clears price |
| OK | `PoiForm.test.tsx` — form submission calls onSubmit |
| OK | `PremiumContentTab.test.tsx` — 20 tests (CRUD, upload, save, error) |
| OK | `AudioUploader.test.tsx` — 4 tests (attribution display only) |

### 4.2 Missing Tests

| Status | Test |
|--------|------|
| N/A | AudioUploader — renders language dropdown for new guide |
| N/A | AudioUploader — file input accepts audio formats |
| N/A | AudioUploader — upload calls adminStorageUploadUpsert + adminInsert |
| N/A | AudioUploader — delete guide shows confirm, calls adminDelete |
| N/A | AudioUploader — inline edit title saves via adminUpdate |
| N/A | AudioUploader — rating display shows stars and count |
| N/A | PhotoUploader — renders thumbnail grid from photo_urls |
| N/A | PhotoUploader — drag-drop triggers upload to poi-photos bucket |
| N/A | PhotoUploader — delete photo (X button) calls onChange |
| N/A | PhotoUploader — lightbox opens on thumbnail click |
| N/A | PhotoUploader — rejects files larger than 5MB |
| N/A | PhotoUploader — accepts only image file types |
| N/A | PoiNewPage — renders PoiForm with empty defaults and cityId |
| N/A | PoiNewPage — submit calls adminInsert and navigates to POI list |
| N/A | PoiTypesPage — renders types with language pill switcher |
| N/A | PoiTypesPage — switching language shows names in that language |
| N/A | PoiTypesPage — inline edit: click name, type, Enter saves |
| N/A | PoiTypesPage — Add Type opens PoiTypeModal |
| N/A | PoiTypesPage — activate/deactivate toggle calls adminUpdate |
| N/A | PoiTypeModal — renders form fields (slug, icon, color, names) |
| N/A | PoiTypeModal — submit calls onSave with form data |
| N/A | PoiTypeModal — cancel closes modal without saving |

### 4.3 Implementation Prompts

#### AudioUploader — upload calls adminStorageUploadUpsert + adminInsert

**File:** `web/src/__tests__/AudioUploader.test.tsx`  
**What:** Uploading audio file stores it and creates DB row.  
**Setup:** Mock `adminStorageUploadUpsert` returns path. Mock `adminStorageGetPublicUrl` returns URL. Mock `adminInsert` succeeds.  
**Steps:**  
1. Select language "en"  
2. Fill title  
3. Select audio file (.mp3)  
4. Click upload  
**Expect:**  
- `adminStorageUploadUpsert` called with bucket='audio-guides'  
- `adminInsert` called with table='poi_audio_guides', data with lang_code, url, title  
**Ref:** `web/src/components/pois/AudioUploader.tsx`

#### AudioUploader — delete guide shows confirm, calls adminDelete

**File:** `web/src/__tests__/AudioUploader.test.tsx`  
**What:** Delete triggers confirmation, then removes guide.  
**Setup:** Render with existing guides. Mock `adminDelete`.  
**Steps:** Click delete on a guide, confirm.  
**Expect:**  
- Confirmation shown  
- `adminDelete` called with table='poi_audio_guides' and guide ID  
**Ref:** `web/src/components/pois/AudioUploader.tsx`

#### PhotoUploader — renders thumbnail grid from photo_urls

**File:** `web/src/__tests__/PhotoUploader.test.tsx`  
**What:** Photos render as thumbnail images with delete buttons.  
**Setup:** Render `<PhotoUploader photos={['url1.jpg','url2.jpg']} onChange={vi.fn()} poiId="test" />`.  
**Steps:** Render.  
**Expect:**  
- 2 img elements with correct src  
- Delete (X) button on each  
**Ref:** `web/src/components/pois/PhotoUploader.tsx`

#### PhotoUploader — delete photo calls onChange

**File:** `web/src/__tests__/PhotoUploader.test.tsx`  
**What:** Clicking X removes photo from array.  
**Setup:** `const onChange = vi.fn()`. Render with photos=['a.jpg','b.jpg'].  
**Steps:** Click X on first photo.  
**Expect:** `onChange` called with `['b.jpg']`.  
**Ref:** `web/src/components/pois/PhotoUploader.tsx`

#### PhotoUploader — rejects files larger than 5MB

**File:** `web/src/__tests__/PhotoUploader.test.tsx`  
**What:** Oversized files rejected.  
**Setup:** Create mock File with size > 5MB.  
**Steps:** Simulate file drop with oversized file.  
**Expect:** Error shown, upload NOT triggered.  
**Ref:** `web/src/components/pois/PhotoUploader.tsx`

#### PoiTypesPage — renders types with language pill switcher

**File:** `web/src/__tests__/PoiTypesPage.test.tsx`  
**What:** Page loads types and shows language pills.  
**Setup:** Mock `adminSelect('poi_types')`. Mock useAuth admin.  
**Steps:** Render, wait for data.  
**Expect:**  
- Language pills visible  
- Type names in current language  
- DataTable with rows  
**Ref:** `web/src/pages/poi-types/PoiTypesPage.tsx`

#### PoiTypesPage — inline edit: click name, type, Enter saves

**File:** `web/src/__tests__/PoiTypesPage.test.tsx`  
**What:** Clicking name enables edit; Enter saves via adminUpdate.  
**Setup:** Mock `adminUpdate`.  
**Steps:**  
1. Click type name cell  
2. Type new name  
3. Press Enter  
**Expect:**  
- Input appears  
- `adminUpdate` called with updated name  
**Ref:** `web/src/pages/poi-types/PoiTypesPage.tsx`

#### PoiTypeModal — renders form fields and submits

**File:** `web/src/__tests__/PoiTypeModal.test.tsx`  
**What:** Modal form fields render and submission works.  
**Setup:** Render `<PoiTypeModal open={true} onClose={vi.fn()} onSave={vi.fn()} />`.  
**Steps:**  
1. Fill slug, icon, English name  
2. Click submit  
**Expect:**  
- All fields present (slug, icon, color, sort_order, active, names)  
- `onSave` called with form data  
**Ref:** `web/src/components/poi-types/PoiTypeModal.tsx`

---

## Chapter 5: Users & Contributors

### 5.1 Existing Tests

_No existing tests for this domain._

### 5.2 Missing Tests

| Status | Test |
|--------|------|
| N/A | UsersPage — loads users via adminSelect on mount |
| N/A | UsersPage — DataTable renders user_number, handle, email, type, status columns |
| N/A | UsersPage — type badges (anonymous/registered) display correctly |
| N/A | UsersPage — status badges (active/deactivated) display correctly |
| N/A | UsersPage — Add User button opens dialog |
| N/A | UsersPage — Add User dialog: email + role fields, submit creates user |
| N/A | UsersPage — detail link navigates to /admin/users/:id |
| N/A | UsersPage — permission gating: canWrite=false hides Add button |
| N/A | UserDetailPage — loads user by ID on mount |
| N/A | UserDetailPage — displays user info card (number, email, handle, status) |
| N/A | UserDetailPage — access grants section lists city access |
| N/A | UserDetailPage — Grant Access button opens AccessGrantModal |
| N/A | UserDetailPage — AccessGrantModal: city dropdown + submit grants access |
| N/A | UserDetailPage — GDPR export downloads ZIP file |
| N/A | UserDetailPage — status toggle with ConfirmDialog |
| N/A | UserDetailPage — delete user with ConfirmDialog |
| N/A | UserDetailPage — back button navigates to users list |
| N/A | ContributorsPage — loads contributor_profiles via adminSelect |
| N/A | ContributorsPage — DataTable renders name, pois, rating, verified columns |
| N/A | ContributorsPage — detail link navigates to /admin/contributors/:id |
| N/A | ContributorDetailPage — loads contributor profile by ID |
| N/A | ContributorDetailPage — displays profile card (bio, website, specializations) |
| N/A | ContributorDetailPage — verification toggle calls adminUpdate |
| N/A | ContributorDetailPage — lists contributor's POIs |

### 5.3 Implementation Prompts

#### UsersPage — loads users and renders table

**File:** `web/src/__tests__/UsersPage.test.tsx`  
**What:** Page fetches users and displays in DataTable.  
**Setup:** Mock `adminSelect` returning users. Mock useAuth admin + hasPermission('users','read').  
**Steps:** Render, wait for data.  
**Expect:**  
- `adminSelect` called  
- User numbers, emails, handles, badges rendered  
**Ref:** `web/src/pages/users/UsersPage.tsx`

#### UsersPage — Add User dialog

**File:** `web/src/__tests__/UsersPage.test.tsx`  
**What:** Dialog opens, form submits, creates user.  
**Setup:** Mock API calls. hasPermission('users','write')=true.  
**Steps:** Click Add User, fill email + role, submit.  
**Expect:** Dialog visible, API called, dialog closes on success.  
**Ref:** `web/src/pages/users/UsersPage.tsx`

#### UserDetailPage — loads user and shows info

**File:** `web/src/__tests__/UserDetailPage.test.tsx`  
**What:** Page loads user profile by route param ID.  
**Setup:** Mock `adminSelect`. MemoryRouter with `{ id: 'test-id' }`.  
**Steps:** Render, wait for load.  
**Expect:** User info displayed (number, email, handle, status, access list).  
**Ref:** `web/src/pages/users/UserDetailPage.tsx`

#### UserDetailPage — GDPR export downloads ZIP

**File:** `web/src/__tests__/UserDetailPage.test.tsx`  
**What:** GDPR button generates and downloads ZIP.  
**Setup:** Mock JSZip, URL.createObjectURL.  
**Steps:** Click GDPR Export.  
**Expect:** ZIP creation triggered with user data.  
**Ref:** `web/src/pages/users/UserDetailPage.tsx`

#### UserDetailPage — status toggle with ConfirmDialog

**File:** `web/src/__tests__/UserDetailPage.test.tsx`  
**What:** Toggle shows confirmation, then updates status.  
**Setup:** Mock `adminUpdate`.  
**Steps:** Click toggle, confirm.  
**Expect:** `adminUpdate` called with updated status.  
**Ref:** `web/src/pages/users/UserDetailPage.tsx`

#### ContributorsPage — loads and renders list

**File:** `web/src/__tests__/ContributorsPage.test.tsx`  
**What:** Page loads contributors and shows table.  
**Setup:** Mock `adminSelect('contributor_profiles')`.  
**Steps:** Render, wait.  
**Expect:** Table with display_name, total_pois, avg_rating, verified.  
**Ref:** `web/src/pages/contributors/ContributorsPage.tsx`

#### ContributorDetailPage — profile and verification toggle

**File:** `web/src/__tests__/ContributorDetailPage.test.tsx`  
**What:** Detail page shows profile, toggle updates verification.  
**Setup:** Mock `adminSelect` + `adminUpdate`.  
**Steps:** Render, click verify toggle.  
**Expect:** Profile card displayed. `adminUpdate` called with `{ is_verified: true }`.  
**Ref:** `web/src/pages/contributors/ContributorDetailPage.tsx`

---

## Chapter 6: Payments

### 6.1 Existing Tests

| Status | Test |
|--------|------|
| OK | `PurchasesOverviewPage.test.tsx` — shows loading state (7 tests total) |
| OK | `PurchasesOverviewPage.test.tsx` — fetches from user_all_purchases |
| OK | `PurchasesOverviewPage.test.tsx` — renders revenue stats cards |
| OK | `PurchasesOverviewPage.test.tsx` — null price_paid as dash |
| OK | `PurchasesOverviewPage.test.tsx` — badge variants for purchase types |
| OK | `PurchasesOverviewPage.test.tsx` — empty state zero revenue |
| OK | `PurchasesOverviewPage.test.tsx` — error message on fetch fail |

### 6.2 Missing Tests

| Status | Test |
|--------|------|
| N/A | PaymentsPage — loads payment_receipts on mount |
| N/A | PaymentsPage — filter by status dropdown |
| N/A | PaymentsPage — filter by payment method dropdown |
| N/A | PaymentsPage — filter by date range (from/to) |
| N/A | PaymentsPage — DataTable renders receipt columns |
| N/A | PaymentsPage — CSV export generates download |
| N/A | PaymentsPage — detail link to /admin/payments/:id |
| N/A | PaymentsPage — error state displays message |
| N/A | PaymentDetailPage — loads receipt by ID |
| N/A | PaymentDetailPage — displays receipt info |
| N/A | PaymentDetailPage — Confirm payment calls edge function |
| N/A | PaymentDetailPage — Refund with ConfirmDialog calls stripe-refund |
| N/A | PaymentDetailPage — Regenerate receipt calls generate-receipt |
| N/A | PaymentDetailPage — Email receipt sends email |
| N/A | PaymentDetailPage — back button navigates to list |

### 6.3 Implementation Prompts

#### PaymentsPage — loads and filters receipts

**File:** `web/src/__tests__/PaymentsPage.test.tsx`  
**What:** Page loads receipts; filters narrow results.  
**Setup:** Mock `adminSelect('payment_receipts')` with varied data.  
**Steps:** Render, wait, select "refunded" status filter.  
**Expect:** Only matching receipts shown.  
**Ref:** `web/src/pages/payments/PaymentsPage.tsx`

#### PaymentsPage — CSV export

**File:** `web/src/__tests__/PaymentsPage.test.tsx`  
**What:** Export button creates CSV download.  
**Setup:** Mock URL.createObjectURL.  
**Steps:** Click CSV export.  
**Expect:** Download triggered with CSV data.  
**Ref:** `web/src/pages/payments/PaymentsPage.tsx`

#### PaymentDetailPage — loads receipt and shows actions

**File:** `web/src/__tests__/PaymentDetailPage.test.tsx`  
**What:** Detail page loads receipt; action buttons work.  
**Setup:** Mock `adminSelect` + global `fetch`.  
**Steps:** Render, click Refund, confirm.  
**Expect:** `fetch` called with stripe-refund endpoint.  
**Ref:** `web/src/pages/payments/PaymentDetailPage.tsx`

#### PaymentDetailPage — Email receipt

**File:** `web/src/__tests__/PaymentDetailPage.test.tsx`  
**What:** Email button calls generate-receipt with send_email flag.  
**Setup:** Mock `fetch`.  
**Steps:** Click Email Receipt.  
**Expect:** `fetch` called with `{ send_email: true }`.  
**Ref:** `web/src/pages/payments/PaymentDetailPage.tsx`

---

## Chapter 7: Hall of Fame

### 7.1 Existing Tests

_No existing tests._

### 7.2 Missing Tests

| Status | Test |
|--------|------|
| N/A | HallOfFamePage — renders context tabs (Overall / By City / By Place) |
| N/A | HallOfFamePage — Overall tab loads poi_hall_of_fame_overall RPC |
| N/A | HallOfFamePage — By City tab shows city selector dropdown |
| N/A | HallOfFamePage — By Place tab shows city + place selectors |
| N/A | HallOfFamePage — podium renders top 3 with medal icons |
| N/A | HallOfFamePage — rankings list renders #4+ contributors |
| N/A | HallOfFamePage — empty state when no contributors |
| N/A | HallOfFamePage — URL query params persist tab and city selection |

### 7.3 Implementation Prompts

#### HallOfFamePage — context tabs and data loading

**File:** `web/src/__tests__/HallOfFamePage.test.tsx`  
**What:** Page renders tab switcher; selecting tabs loads correct data.  
**Setup:** Mock `adminRpc` for poi_hall_of_fame_overall and poi_hall_of_fame. Mock `adminSelect('cities')` for dropdown. Mock useAuth admin. MemoryRouter.  
**Steps:**  
1. Render, verify "Overall" tab active  
2. Verify `adminRpc('poi_hall_of_fame_overall')` called  
3. Click "By City" tab  
4. Verify city dropdown appears  
5. Select a city  
**Expect:** Correct RPC called per tab. Podium shows top 3.  
**Ref:** `web/src/pages/hall-of-fame/HallOfFamePage.tsx`

---

## Chapter 8: ACL & Settings

### 8.1 Existing Tests

_No existing tests._

### 8.2 Missing Tests

| Status | Test |
|--------|------|
| N/A | AclManagementPage — loads permissions matrix on mount |
| N/A | AclManagementPage — renders roles x resources grid with checkboxes |
| N/A | AclManagementPage — superadmin row is read-only |
| N/A | AclManagementPage — toggling write auto-enables read |
| N/A | AclManagementPage — toggling delete auto-enables write+read |
| N/A | AclManagementPage — unchecking read auto-disables write+delete |
| N/A | AclManagementPage — save calls adminUpdate for changed permissions |
| N/A | SettingsPage — loads payment_config on mount |
| N/A | SettingsPage — renders system limits section |
| N/A | SettingsPage — renders payment config section |
| N/A | SettingsPage — save calls adminUpdate('payment_config') |
| N/A | SettingsPage — permission gating disables save without payments:write |
| N/A | SettingsPage — renders ChangePinForm subsection |
| N/A | SettingsPage — renders InviteAdminForm subsection |
| N/A | SettingsPage — renders AdminUsersTable subsection |
| N/A | ChangePinForm — renders current PIN and new PIN inputs |
| N/A | ChangePinForm — submit calls change-admin-pin edge function |
| N/A | ChangePinForm — error response shows error message |
| N/A | ChangePinForm — success shows toast |
| N/A | InviteAdminForm — renders email and role fields |
| N/A | InviteAdminForm — submit calls invite-contributor edge function |
| N/A | InviteAdminForm — shows default PIN info after invite |
| N/A | AdminUsersTable — renders list of admin users with roles |
| N/A | AdminUsersTable — remove button with confirmation |

### 8.3 Implementation Prompts

#### AclManagementPage — loads and renders permission matrix

**File:** `web/src/__tests__/AclManagementPage.test.tsx`  
**What:** Page loads ACL permissions and renders editable grid.  
**Setup:** Mock `adminSelect('acl_permissions')` or `adminRpc('get_all_permissions')`. Mock useAuth superadmin.  
**Steps:** Render, wait for data.  
**Expect:** Grid with R/W/D checkboxes. Superadmin row disabled.  
**Ref:** `web/src/pages/AclManagementPage.tsx`

#### AclManagementPage — checkbox cascade logic

**File:** `web/src/__tests__/AclManagementPage.test.tsx`  
**What:** Write auto-enables read; delete auto-enables write+read; uncheck read disables all.  
**Steps:** Toggle checkboxes, verify cascade.  
**Expect:** Dependent checkboxes auto-toggle.  
**Ref:** `web/src/pages/AclManagementPage.tsx`

#### SettingsPage — loads config and renders

**File:** `web/src/__tests__/SettingsPage.test.tsx`  
**What:** Loads payment_config and renders all sections.  
**Setup:** Mock `adminSelect('payment_config')`. Mock useAuth superadmin.  
**Steps:** Render, wait.  
**Expect:** System limits, payment config, PIN form, invite form, admin table visible.  
**Ref:** `web/src/pages/SettingsPage.tsx`

#### ChangePinForm — submit calls edge function

**File:** `web/src/__tests__/ChangePinForm.test.tsx`  
**What:** Form submits PIN change.  
**Setup:** Mock `fetch` for change-admin-pin.  
**Steps:** Fill current + new PIN, submit.  
**Expect:** `fetch` called with PIN data. Success toast.  
**Ref:** `web/src/components/settings/ChangePinForm.tsx`

#### InviteAdminForm — invite admin user

**File:** `web/src/__tests__/InviteAdminForm.test.tsx`  
**What:** Invite form creates admin.  
**Setup:** Mock `fetch` for invite-contributor.  
**Steps:** Fill email, select role, submit.  
**Expect:** `fetch` called. Default PIN info shown.  
**Ref:** `web/src/components/settings/InviteAdminForm.tsx`

#### AdminUsersTable — renders admin list

**File:** `web/src/__tests__/AdminUsersTable.test.tsx`  
**What:** Table shows admin users and roles.  
**Setup:** Render with mock admin data.  
**Steps:** Render.  
**Expect:** Emails and roles displayed. Remove button per admin.  
**Ref:** `web/src/components/settings/AdminUsersTable.tsx`

---

## Chapter 9: Account Pages (End-User)

### 9.1 Existing Tests

_No existing tests._

### 9.2 Missing Tests

| Status | Test |
|--------|------|
| N/A | AccountProfilePage — renders tab navigation (Settings, Purchases) |
| N/A | AccountProfilePage — Settings tab: handle field with availability check |
| N/A | AccountProfilePage — Settings tab: backup email saves |
| N/A | AccountProfilePage — Settings tab: password change form |
| N/A | AccountProfilePage — Settings tab: language selector (11 languages) |
| N/A | AccountProfilePage — Settings tab: delete account with ConfirmDialog |
| N/A | AccountProfilePage — Purchases tab: lists receipts and city access |
| N/A | AccountProfilePage — header shows user number and handle |
| N/A | AccountHistoryPage — loads visit history data |
| N/A | AccountHistoryPage — time period filter (all/30d/7d/custom) |
| N/A | AccountHistoryPage — POI type filter chips |
| N/A | AccountHistoryPage — CSV export button |
| N/A | AccountHistoryPage — stats map visualization |
| N/A | AccountExplorePage — renders ExploreMap |
| N/A | AccountExplorePage — purchased cities highlighted on map |
| N/A | AccountExplorePage — POI type filter chips toggle markers |

### 9.3 Implementation Prompts

#### AccountProfilePage — renders tabs and settings

**File:** `web/src/__tests__/AccountProfilePage.test.tsx`  
**What:** Profile page renders tab navigation with settings form.  
**Setup:** Mock useAuth with user + userNumber + displayName. Mock supabase client. MemoryRouter.  
**Steps:** Render, verify Settings tab active.  
**Expect:** Handle input, backup email, language dropdown, delete button visible.  
**Ref:** `web/src/pages/account/AccountProfilePage.tsx`

#### AccountProfilePage — delete account

**File:** `web/src/__tests__/AccountProfilePage.test.tsx`  
**What:** Delete shows confirmation, calls delete-user-data.  
**Setup:** Mock `fetch`.  
**Steps:** Click Delete Account, confirm.  
**Expect:** `fetch` called. Sign out triggered.  
**Ref:** `web/src/pages/account/AccountProfilePage.tsx`

#### AccountHistoryPage — loads and filters

**File:** `web/src/__tests__/AccountHistoryPage.test.tsx`  
**What:** History page loads visits and allows filtering.  
**Setup:** Mock supabase queries. Mock map components.  
**Steps:** Render, select time filter.  
**Expect:** Filtered visits rendered. CSV export button works.  
**Ref:** `web/src/pages/account/AccountHistoryPage.tsx`

#### AccountExplorePage — renders map with filters

**File:** `web/src/__tests__/AccountExplorePage.test.tsx`  
**What:** Explore page shows map and filters.  
**Setup:** Mock supabase queries for user_access + cities + pois. Mock ExploreMap.  
**Steps:** Render, wait.  
**Expect:** Purchased cities displayed. POI type filter chips visible.  
**Ref:** `web/src/pages/account/AccountExplorePage.tsx`

---

## Chapter 10: Contributor Pages

### 10.1 Existing Tests

_No existing tests._

### 10.2 Missing Tests

| Status | Test |
|--------|------|
| N/A | MyPoisPage — loads contributor's POIs in CityPoiTree |
| N/A | MyPoisPage — search filters POI tree |
| N/A | MyPoisPage — edit link navigates to /admin/my-pois/:id |
| N/A | MyPoisPage — Add POI link navigates to /admin/my-pois/new |
| N/A | MyPoiEditorPage — loads PoiForm for contributor POI |
| N/A | MyPoiEditorPage — submit saves POI with contributor_id |
| N/A | AdminProfilePage — renders contributor profile form |
| N/A | AdminProfilePage — saves bio, website, specializations |

### 10.3 Implementation Prompts

#### MyPoisPage — loads contributor's POIs

**File:** `web/src/__tests__/MyPoisPage.test.tsx`  
**What:** Page loads POIs filtered by contributor_id.  
**Setup:** Mock `adminSelect` with contributor filter. Mock useAuth contributor.  
**Steps:** Render, wait.  
**Expect:** CityPoiTree rendered. Add POI button visible.  
**Ref:** `web/src/pages/my-pois/MyPoisPage.tsx`

#### AdminProfilePage — contributor profile edit

**File:** `web/src/__tests__/AdminProfilePage.test.tsx`  
**What:** Profile page loads and saves contributor data.  
**Setup:** Mock `adminSelect('contributor_profiles')` + `adminUpdate`. Mock useAuth contributor.  
**Steps:** Change bio, save.  
**Expect:** `adminUpdate` called with updated bio.  
**Ref:** `web/src/pages/AdminProfilePage.tsx`

---

## Chapter 11: Dashboard

### 11.1 Existing Tests

_No existing tests._

### 11.2 Missing Tests

| Status | Test |
|--------|------|
| N/A | DashboardPage — loads admin_stats RPC on mount |
| N/A | DashboardPage — renders MetricCards (cities, POIs, users, revenue) |
| N/A | DashboardPage — renders ActivityChart component |
| N/A | DashboardPage — renders RevenueChart component |
| N/A | DashboardPage — loading state shows skeletons |
| N/A | DashboardPage — error state shows message |

### 11.3 Implementation Prompts

#### DashboardPage — loads stats and renders

**File:** `web/src/__tests__/DashboardPage.test.tsx`  
**What:** Dashboard loads stats and shows metrics + charts.  
**Setup:** Mock `adminRpc('admin_stats')`. Mock chart components. Mock useAuth admin.  
**Steps:** Render, wait.  
**Expect:** MetricCards with counts. Charts rendered.  
**Ref:** `web/src/pages/DashboardPage.tsx`

---

## Chapter 12: Shared Components

### 12.1 Existing Tests

| Status | Test |
|--------|------|
| OK | `Sidebar.test.tsx` — Premium Purchases link present |
| OK | `Sidebar.test.tsx` — Settings visible only for superadmin |
| OK | `Sidebar.test.tsx` — active NavLink styling |
| OK | `Sidebar.test.tsx` — sign out button exists |

### 12.2 Missing Tests

| Status | Test |
|--------|------|
| N/A | UnauthorizedPage — renders error message and back-to-login button |
| N/A | Sidebar — all navigation links render with correct hrefs |
| N/A | Sidebar — contributor role sees only allowed links |
| N/A | Sidebar — "Leave Admin" link renders for admin users |
| N/A | DataTable — renders columns and rows from data prop |
| N/A | DataTable — clicking column header toggles sort |
| N/A | DataTable — search input filters rows |
| N/A | DataTable — pagination buttons work |
| N/A | DataTable — empty state message |
| N/A | ConfirmDialog — renders title, description, buttons |
| N/A | ConfirmDialog — clicking confirm calls onConfirm |
| N/A | ConfirmDialog — clicking cancel calls onCancel |
| N/A | TagInput — renders existing tags as badges |
| N/A | TagInput — Enter adds new tag |
| N/A | TagInput — clicking X removes tag |
| N/A | TagInput — Backspace on empty removes last tag |
| N/A | TagInput — blur adds current text as tag |
| N/A | MapPicker — renders at given coordinates |
| N/A | MapPicker — click updates lat/lng via onChange |

### 12.3 Implementation Prompts

#### DataTable — renders, sorts, filters, paginates

**File:** `web/src/__tests__/DataTable.test.tsx`  
**What:** Table renders data with sorting, filtering, pagination.  
**Setup:** Render `<DataTable columns={mockColumns} data={mockData} />`.  
**Steps:** Verify rows, click header to sort, type in search, click next page.  
**Expect:** Data renders. Sort order toggles. Search filters. Pagination works.  
**Ref:** `web/src/components/shared/DataTable.tsx`

#### ConfirmDialog — confirm and cancel

**File:** `web/src/__tests__/ConfirmDialog.test.tsx`  
**What:** Dialog has title and action buttons.  
**Setup:** Render with open=true, onConfirm=vi.fn(), onCancel=vi.fn().  
**Steps:** Click Confirm, then Cancel in separate renders.  
**Expect:** Correct callbacks called.  
**Ref:** `web/src/components/shared/ConfirmDialog.tsx`

#### TagInput — add/remove tags

**File:** `web/src/__tests__/TagInput.test.tsx`  
**What:** Tags added via Enter, removed via X and Backspace.  
**Setup:** Render with value=['tag1'], onChange=vi.fn().  
**Steps:** Type "newtag" + Enter. Click X on tag1. Backspace on empty.  
**Expect:** onChange called with correct arrays.  
**Ref:** `web/src/components/shared/TagInput.tsx`

#### MapPicker — coordinate selection

**File:** `web/src/__tests__/MapPicker.test.tsx`  
**What:** Map click fires onChange with new coordinates.  
**Setup:** Mock leaflet internals. Render with lat/lng/onChange.  
**Note:** Leaflet doesn't work in jsdom. Mock MapPickerInner or test the callback interface.  
**Ref:** `web/src/components/shared/MapPicker.tsx`

---
---

# PART 2: FLUTTER (flutter_test + Riverpod)

---

## Chapter 13: Authentication

### 13.1 Existing Tests

_No existing screen-level tests. Auth providers tested indirectly via other tests._

### 13.2 Missing Tests

| Status | Test |
|--------|------|
| N/A | AuthScreen — renders email and password fields |
| N/A | AuthScreen — toggle between Sign In and Create Account modes |
| N/A | AuthScreen — Create Account mode shows handle field |
| N/A | AuthScreen — validation: empty email shows error |
| N/A | AuthScreen — validation: short password (<8 chars) shows error |
| N/A | AuthScreen — password visibility toggle (obscure/visible) |
| N/A | AuthScreen — successful sign-in navigates to map |
| N/A | AuthScreen — error response shows error SnackBar |
| N/A | AuthScreen — anonymous user sees migration info banner |
| N/A | AuthScreen — forgot password link sends reset email |

### 13.3 Implementation Prompts

#### AuthScreen — renders fields and toggles mode

**File:** `app/test/features/auth/auth_screen_test.dart`  
**What:** Screen renders auth form with mode toggle.  
**Setup:** Wrap in `ProviderScope` + `MaterialApp`. Override auth providers with mocks.  
**Steps:**  
1. `pumpWidget`, `pumpAndSettle`  
2. Find email `TextFormField`  
3. Find password `TextFormField`  
4. Tap mode toggle button  
5. Verify handle field appears  
**Expect:**  
- Email/password fields in both modes  
- Handle field only in Create Account mode  
- Submit button text changes per mode  
**Ref:** `app/lib/features/auth/auth_screen.dart`

#### AuthScreen — validation errors

**File:** `app/test/features/auth/auth_screen_test.dart`  
**What:** Empty/invalid input triggers validation.  
**Steps:**  
1. Leave email empty, tap submit  
2. Verify error text  
3. Enter email, set short password  
4. Tap submit, verify password error  
**Expect:** Validation messages shown per field.  
**Ref:** `app/lib/features/auth/auth_screen.dart`

#### AuthScreen — successful sign-in

**File:** `app/test/features/auth/auth_screen_test.dart`  
**What:** Valid credentials navigate to map.  
**Setup:** Override auth provider to return success. Mock GoRouter.  
**Steps:** Enter valid email + password, submit.  
**Expect:** Navigation to '/' (map) triggered.  
**Ref:** `app/lib/features/auth/auth_screen.dart`

---

## Chapter 14: Onboarding & Splash

### 14.1 Existing Tests

_No existing tests._

### 14.2 Missing Tests

| Status | Test |
|--------|------|
| N/A | OnboardingScreen — renders 3-page carousel |
| N/A | OnboardingScreen — swipe advances to next page |
| N/A | OnboardingScreen — Skip button navigates to map |
| N/A | OnboardingScreen — completing last page triggers completion |
| N/A | OnboardingScreen — page indicators update on swipe |
| N/A | SplashScreen — shows app logo |
| N/A | SplashScreen — navigates to onboarding or map based on first-launch flag |

### 14.3 Implementation Prompts

#### OnboardingScreen — carousel and navigation

**File:** `app/test/features/onboarding/onboarding_screen_test.dart`  
**What:** Screen renders carousel with skip/next navigation.  
**Setup:** Wrap in MaterialApp. Mock SharedPreferences for completion flag.  
**Steps:**  
1. Verify 3 pages exist (page indicators)  
2. Swipe left to advance  
3. Verify page 2 content  
4. Tap Skip button  
**Expect:** Skip navigates to map. Completion flag persisted.  
**Ref:** `app/lib/features/onboarding/onboarding_screen.dart`

#### SplashScreen — initialization and routing

**File:** `app/test/features/splash/splash_screen_test.dart`  
**What:** Splash shows logo and routes based on state.  
**Setup:** Mock SharedPreferences (first_launch flag). Mock GoRouter.  
**Steps:** Pump widget, wait.  
**Expect:** Logo visible. Navigation to onboarding (first launch) or map (returning).  
**Ref:** `app/lib/features/splash/splash_screen.dart`

---

## Chapter 15: Map

### 15.1 Existing Tests

| Status | Test |
|--------|------|
| OK | `poi_bottom_sheet_test.dart` — POI name display (12 tests total) |
| OK | `poi_bottom_sheet_test.dart` — description display |
| OK | `poi_bottom_sheet_test.dart` — close/open button callbacks |
| OK | `poi_bottom_sheet_test.dart` — rating badge (totalRatings >= 5) |
| OK | `poi_bottom_sheet_test.dart` — audio icon visibility |
| OK | `poi_bottom_sheet_test.dart` — premium lock icon |
| OK | `poi_bottom_sheet_test.dart` — navigate callback |

### 15.2 Missing Tests

| Status | Test |
|--------|------|
| N/A | MapScreen — renders FlutterMap with TileLayer |
| N/A | MapScreen — 4 filter chips for access levels |
| N/A | MapScreen — unchecking filter hides markers of that type |
| N/A | MapScreen — marker colors match access level |
| N/A | MapScreen — tapping marker opens PoiBottomSheet |
| N/A | MapScreen — Hall of Fame button visible when city detected |
| N/A | MapScreen — AppBar shows nearest city name or 'PlaceSecrets' |
| N/A | MapScreen — FAB centers map on user location |

### 15.3 Implementation Prompts

#### MapScreen — renders map with filter chips

**File:** `app/test/features/map/map_screen_test.dart`  
**What:** Map screen renders with filter chips and markers.  
**Setup:** Override map providers: `activeCitiesProvider` returns mock cities, `cityPoisProvider` returns mock POIs with different access levels. Mock location provider. Override `FlutterMap` or use a custom test wrapper.  
**Steps:**  
1. Pump widget  
2. Find 4 FilterChip widgets (Public, Registered, City Access, Premium)  
3. Verify chips are all selected by default  
4. Tap "Premium" chip to deselect  
**Expect:**  
- All 4 chips render  
- After deselecting Premium, premium POI markers hidden  
**Note:** FlutterMap may need mocking in test environment.  
**Ref:** `app/lib/features/map/map_screen.dart`

#### MapScreen — AppBar shows city name

**File:** `app/test/features/map/map_screen_test.dart`  
**What:** AppBar title shows nearest city or default.  
**Setup:** Override `nearestCityProvider` to return a city or null.  
**Steps:**  
1. With city: verify city name in AppBar  
2. Without city: verify 'PlaceSecrets' in AppBar  
**Expect:** Dynamic title based on detected city.  
**Ref:** `app/lib/features/map/map_screen.dart`

---

## Chapter 16: POI Detail

### 16.1 Existing Tests

| Status | Test |
|--------|------|
| OK | `rating_widget_test.dart` — star selection 1-5 (10 tests) |
| OK | `rating_widget_test.dart` — submit calls repository |
| OK | `rating_widget_test.dart` — reason chips for low ratings |
| OK | `rating_widget_test.dart` — existing rating display |
| OK | `share_poi_button_test.dart` — renders when slug present (6 tests) |
| OK | `share_poi_button_test.dart` — hidden when slug null |
| OK | `premium_poi_content_test.dart` — premium badge (8 tests) |
| OK | `premium_poi_content_test.dart` — text content display |
| OK | `premium_poi_content_test.dart` — extra photos section |

### 16.2 Missing Tests

| Status | Test |
|--------|------|
| N/A | PoiDetailScreen — renders photo gallery carousel |
| N/A | PoiDetailScreen — displays POI name and description |
| N/A | PoiDetailScreen — audio player section shown for registered+ access |
| N/A | PoiDetailScreen — premium upgrade CTA for non-premium users |
| N/A | PoiDetailScreen — share button in AppBar |
| N/A | PoiDetailScreen — rating widget appears (after delay or scroll) |
| N/A | PoiDetailScreen — access level badge displayed |
| N/A | PoiDetailScreen — loading state shows CircularProgressIndicator |
| N/A | PoiBySlugScreen — resolves slug and navigates to detail |
| N/A | PoiBySlugScreen — invalid slug shows error |
| N/A | AudioPlayerWidget — renders play/pause button |
| N/A | AudioPlayerWidget — progress bar updates |
| N/A | AudioPlayerWidget — language selection dropdown |
| N/A | AudioPlayerWidget — displays guide duration |

### 16.3 Implementation Prompts

#### PoiDetailScreen — renders content based on access

**File:** `app/test/features/poi_detail/poi_detail_screen_test.dart`  
**What:** Screen renders POI content with access-based sections.  
**Setup:** Override poi repository provider with mock returning POI data. Override access provider. Wrap in ProviderScope + MaterialApp with GoRouter.  
**Steps:**  
1. Render with public access POI  
2. Verify name, description, photo carousel  
3. Verify no premium CTA  
4. Re-render with premium POI + no access  
5. Verify premium upgrade CTA visible  
**Expect:** Content adapts to access level.  
**Ref:** `app/lib/features/poi_detail/poi_detail_screen.dart`

#### PoiBySlugScreen — resolves slug

**File:** `app/test/features/poi_detail/poi_by_slug_screen_test.dart`  
**What:** Screen calls get_poi_by_slug RPC and navigates.  
**Setup:** Override poi repository to return POI for slug. Mock GoRouter.  
**Steps:** Pump with route params (countryCode, citySlug, poiSlug).  
**Expect:** Loading shown, then navigation to `/poi/:id`.  
**Ref:** `app/lib/features/poi_detail/poi_by_slug_screen.dart`

#### AudioPlayerWidget — play/pause and language

**File:** `app/test/features/poi_detail/widgets/audio_player_widget_test.dart`  
**What:** Widget renders player controls with language selection.  
**Setup:** Override audio providers with mock data (multiple guides in different languages).  
**Steps:**  
1. Verify play button  
2. Tap play → verify pause button  
3. Find language dropdown  
4. Verify guide duration displayed  
**Expect:** Controls toggle. Language selection available.  
**Ref:** `app/lib/features/poi_detail/widgets/audio_player_widget.dart`

---

## Chapter 17: Purchase & Payment

### 17.1 Existing Tests

| Status | Test |
|--------|------|
| OK | `my_purchases_screen_test.dart` — app bar title (8 tests) |
| OK | `my_purchases_screen_test.dart` — empty states |
| OK | `my_purchases_screen_test.dart` — loading states |
| OK | `my_purchases_screen_test.dart` — purchased items display |

### 17.2 Missing Tests

| Status | Test |
|--------|------|
| N/A | PaywallScreen — renders city name and price |
| N/A | PaywallScreen — shows payment method buttons from config |
| N/A | PaywallScreen — processing state disables buttons |
| N/A | PaywallScreen — Revolut button opens deep link |
| N/A | PurchasePoiScreen — shows per-POI and bundle options |
| N/A | PurchasePoiScreen — per-POI purchase triggers Stripe checkout |
| N/A | PurchasePoiScreen — bundle option shows "best value" label |
| N/A | PurchasePoiScreen — "Maybe later" button pops navigation |

### 17.3 Implementation Prompts

#### PaywallScreen — renders pricing and payment methods

**File:** `app/test/features/payment/paywall_screen_test.dart`  
**What:** Paywall shows city info and available payment methods.  
**Setup:** Override `paymentConfigProvider` with mock config (GPay + Apple Pay + Revolut). Override `selectedCityProvider`. ProviderScope + MaterialApp.  
**Steps:**  
1. Verify city name displayed  
2. Verify price in EUR  
3. Verify payment method buttons based on platform  
**Expect:** City and price from config. Payment buttons match config availability.  
**Ref:** `app/lib/features/payment/paywall_screen.dart`

#### PurchasePoiScreen — POI and bundle options

**File:** `app/test/features/purchase/purchase_poi_screen_test.dart`  
**What:** Screen shows individual POI and city bundle purchase options.  
**Setup:** Override poi provider with premium POI (premiumPrice=4.99). Override city provider (premiumBundlePrice=14.99).  
**Steps:**  
1. Verify POI option with price  
2. Verify bundle option with "best value" label  
3. Tap "Maybe later"  
**Expect:** Both options shown. Maybe later pops navigation.  
**Ref:** `app/lib/features/purchase/purchase_poi_screen.dart`

---

## Chapter 18: History, Hall of Fame & Export

### 18.1 Existing Tests

_No existing screen-level tests._

### 18.2 Missing Tests

| Status | Test |
|--------|------|
| N/A | HistoryScreen — renders visit list from local DB |
| N/A | HistoryScreen — stats badges (total visits, unique cities, notes, photos) |
| N/A | HistoryScreen — empty state when no visits |
| N/A | HistoryScreen — PDF export icon navigates to ExportScreen |
| N/A | HallOfFameScreen — renders podium with top 3 contributors |
| N/A | HallOfFameScreen — ranking list below podium |
| N/A | HallOfFameScreen — city name in AppBar |
| N/A | ExportScreen — date range picker (from/to) |
| N/A | ExportScreen — Export All button |
| N/A | ExportScreen — generates PDF and shows share sheet |

### 18.3 Implementation Prompts

#### HistoryScreen — renders visits and stats

**File:** `app/test/features/history/history_screen_test.dart`  
**What:** Screen shows visit history list and stats badges.  
**Setup:** Override `visitHistoryProvider` with mock visits. Override `travelStatsProvider` with mock stats.  
**Steps:**  
1. Verify stats badges (visits count, cities count)  
2. Verify visit list items with POI names and dates  
3. Verify PDF icon in AppBar  
**Expect:** Stats and list render from providers.  
**Ref:** `app/lib/features/history/history_screen.dart`

#### HallOfFameScreen — podium and rankings

**File:** `app/test/features/hall_of_fame/hall_of_fame_screen_test.dart`  
**What:** Screen shows podium for top 3 and ranking list.  
**Setup:** Override `hallOfFameProvider` with mock contributors (5 items).  
**Steps:**  
1. Verify top 3 in podium layout  
2. Verify #4, #5 in list  
3. Verify city name in AppBar  
**Expect:** Podium + list render from provider.  
**Ref:** `app/lib/features/hall_of_fame/hall_of_fame_screen.dart`

#### ExportScreen — date range and PDF generation

**File:** `app/test/features/export/export_screen_test.dart`  
**What:** Screen allows date range selection and PDF export.  
**Setup:** Override visit repository. Mock PdfExportService.  
**Steps:**  
1. Verify date pickers  
2. Verify "Export All" button  
3. Tap export  
**Expect:** PdfExportService called with date range.  
**Ref:** `app/lib/features/export/export_screen.dart`

---

## Chapter 19: Settings

### 19.1 Existing Tests

_No existing tests._

### 19.2 Missing Tests

| Status | Test |
|--------|------|
| N/A | SettingsScreen — renders all settings tiles |
| N/A | SettingsScreen — Audio Language: tap opens dialog with 3 options |
| N/A | SettingsScreen — Geofence Radius: slider dialog (50-500m) |
| N/A | SettingsScreen — Notifications toggle persists to SharedPreferences |
| N/A | SettingsScreen — Handle field saves to user_profiles |
| N/A | SettingsScreen — Backup Email field saves to user_profiles |
| N/A | SettingsScreen — User Number displayed (read-only) |
| N/A | SettingsScreen — Sign Out clears state, creates anonymous session |
| N/A | SettingsScreen — About dialog shows app version |

### 19.3 Implementation Prompts

#### SettingsScreen — renders tiles and dialogs

**File:** `app/test/features/settings/settings_screen_test.dart`  
**What:** Settings renders all tiles and interactive dialogs.  
**Setup:** Override auth providers with registered user. Mock SharedPreferences. ProviderScope + MaterialApp.  
**Steps:**  
1. Verify section tiles: Audio Language, Geofence Radius, Notifications, Handle, Backup Email, User Number, Sign Out, About  
2. Tap Audio Language tile  
3. Verify dialog with en/cs/de options  
4. Tap Geofence Radius tile  
5. Verify slider dialog  
6. Toggle Notifications  
7. Verify SharedPreferences updated  
**Expect:** All tiles render. Dialogs open. Preferences persist.  
**Ref:** `app/lib/features/settings/settings_screen.dart`

#### SettingsScreen — Sign Out

**File:** `app/test/features/settings/settings_screen_test.dart`  
**What:** Sign out clears auth state.  
**Setup:** Override auth providers with signed-in user. Mock signOut.  
**Steps:** Tap Sign Out.  
**Expect:** signOut called. Navigation to auth screen.  
**Ref:** `app/lib/features/settings/settings_screen.dart`

---

## Chapter 20: Models & Data (Existing — All OK)

| Status | Test |
|--------|------|
| OK | `city_test.dart` — City model parsing/serialization |
| OK | `poi_test.dart` — POI model and access levels |
| OK | `contributor_profile_test.dart` — ContributorProfile model |
| OK | `poi_premium_content_test.dart` — PremiumContent model |
| OK | `user_access_test.dart` — UserAccess model |
| OK | `poi_rating_test.dart` — PoiRating model |
| OK | `app_database_test.dart` — Core database operations (17 tests) |
| OK | `drift_migration_test.dart` — Schema migrations (4 tests) |
| OK | `visit_queries_test.dart` — Visit queries (11 tests) |
| OK | `poi_repository_offline_test.dart` — Offline POI access (10 tests) |
| OK | `access_repository_free_visit_test.dart` — Free visit logic (5 tests) |
| OK | `deep_link_handler_test.dart` — Deep link parsing (9 tests) |

---
---

# APPENDIX A: Test Infrastructure & Mocking Patterns

## Web (Vitest + Testing Library)

### Standard Test Wrapper
```tsx
import { render } from '@testing-library/react';
import { MemoryRouter } from 'react-router-dom';

function renderPage(ui: React.ReactElement, route = '/') {
  return render(
    <MemoryRouter initialEntries={[route]}>
      {ui}
    </MemoryRouter>
  );
}
```

### Mock Supabase Client
```ts
vi.mock('@/lib/supabase/client', () => ({
  supabase: {
    auth: {
      getSession: vi.fn().mockResolvedValue({ data: { session: null } }),
      signInWithPassword: vi.fn(),
      signOut: vi.fn(),
      onAuthStateChange: vi.fn(() => ({ data: { subscription: { unsubscribe: vi.fn() } } })),
    },
    from: vi.fn(() => ({
      select: vi.fn().mockReturnThis(),
      eq: vi.fn().mockReturnThis(),
      in: vi.fn().mockReturnThis(),
      single: vi.fn().mockResolvedValue({ data: null, error: null }),
      maybeSingle: vi.fn().mockResolvedValue({ data: null, error: null }),
    })),
    rpc: vi.fn().mockResolvedValue({ data: null, error: null }),
  },
}));
```

### Mock Admin API
```ts
vi.mock('@/lib/supabase/admin-api', () => ({
  adminSelect: vi.fn().mockResolvedValue([]),
  adminInsert: vi.fn().mockResolvedValue({ id: 'new-id' }),
  adminUpdate: vi.fn().mockResolvedValue({}),
  adminDelete: vi.fn().mockResolvedValue({}),
  adminUpsert: vi.fn().mockResolvedValue({}),
  adminRpc: vi.fn().mockResolvedValue([]),
  adminStorageUploadUpsert: vi.fn().mockResolvedValue('path/to/file'),
  adminStorageGetPublicUrl: vi.fn().mockReturnValue('https://example.com/file'),
}));
```

### Mock useAuth
```ts
vi.mock('@/hooks/useAuth', () => ({
  useAuthStore: vi.fn((selector) => selector({
    user: { id: 'test-user', email: 'test@test.com' },
    role: 'superadmin',
    adminVerified: true,
    mustChangePin: false,
    permissions: [],
    hasPermission: vi.fn().mockReturnValue(true),
    signOut: vi.fn(),
  })),
}));
```

### Mock Toast (sonner)
```ts
const mockToastSuccess = vi.fn();
const mockToastError = vi.fn();
vi.mock('sonner', () => ({
  toast: { success: mockToastSuccess, error: mockToastError },
}));
```

### Mock Leaflet Components
```ts
vi.mock('@/components/shared/MapPicker', () => ({
  default: ({ onChange }: any) => <div data-testid="map-picker" onClick={() => onChange?.(50, 14)} />,
}));
```

## Flutter (flutter_test + Riverpod)

### Standard Widget Wrapper
```dart
Widget _wrap(Widget child, {List<Override>? overrides}) {
  return ProviderScope(
    overrides: overrides ?? [],
    child: MaterialApp(home: Scaffold(body: child)),
  );
}
```

### Provider Override Pattern
```dart
testWidgets('description', (tester) async {
  await tester.pumpWidget(_wrap(
    const MyScreen(),
    overrides: [
      myProvider.overrideWith((ref) => FakeMyRepository()),
    ],
  ));
  await tester.pumpAndSettle();
  expect(find.text('Expected'), findsOneWidget);
});
```

### Fake Repository Pattern
```dart
class FakeRatingsRepository extends RatingsRepository {
  @override
  Future<PoiRating?> getUserRating(String poiId) async => null;
  @override
  Future<void> submitRating(PoiRating rating) async {}
}
```

### In-Memory Database
```dart
late AppDatabase db;
setUp(() => db = AppDatabase.forTesting(NativeDatabase.memory()));
tearDown(() async => await db.close());
```

### Async State with Completers
```dart
final completer = Completer<List<Poi>>();
// Override provider to return completer.future
await tester.pump(); // Don't settle — verify loading state
completer.complete([mockPoi]);
await tester.pumpAndSettle(); // Now verify loaded state
```

---
---

# SUMMARY

## Coverage by Platform & Domain

| # | Platform | Domain | OK | N/A | Total |
|---|----------|--------|---:|----:|------:|
| 1 | Web | Authentication & Authorization | 26 | 21 | 47 |
| 2 | Web | Landing & Public Pages | 24 | 6 | 30 |
| 3 | Web | Cities Management | 5 | 20 | 25 |
| 4 | Web | POIs & Content | 27 | 22 | 49 |
| 5 | Web | Users & Contributors | 0 | 24 | 24 |
| 6 | Web | Payments | 7 | 15 | 22 |
| 7 | Web | Hall of Fame | 0 | 8 | 8 |
| 8 | Web | ACL & Settings | 0 | 24 | 24 |
| 9 | Web | Account Pages | 0 | 16 | 16 |
| 10 | Web | Contributor Pages | 0 | 8 | 8 |
| 11 | Web | Dashboard | 0 | 6 | 6 |
| 12 | Web | Shared Components | 4 | 19 | 23 |
| 13 | Flutter | Authentication | 0 | 10 | 10 |
| 14 | Flutter | Onboarding & Splash | 0 | 7 | 7 |
| 15 | Flutter | Map | 7 | 8 | 15 |
| 16 | Flutter | POI Detail | 9 | 14 | 23 |
| 17 | Flutter | Purchase & Payment | 4 | 8 | 12 |
| 18 | Flutter | History, HoF & Export | 0 | 10 | 10 |
| 19 | Flutter | Settings | 0 | 9 | 9 |
| 20 | Flutter | Models & Data | 13 | 1 | 14 |
| | **TOTAL** | | **126** | **256** | **382** |

## Coverage by Status

| Status | Count | Percentage |
|--------|------:|----------:|
| OK (implemented) | 126 | 33.0% |
| N/A (awaiting) | 256 | 67.0% |

## N/A Breakdown by Platform

| Platform | N/A Count | New Test Files Needed |
|----------|----------:|----------------------:|
| Web (React) | 190 | ~25 |
| Flutter | 66 | ~8 |

## Priority Order for Implementation

1. **Authentication** (Ch 1, 13) — security-critical  
2. **Users & Contributors** (Ch 5) — zero coverage, admin-critical  
3. **ACL & Settings** (Ch 8) — zero coverage, permission system  
4. **Cities Management** (Ch 3) — core CRUD  
5. **Payments** (Ch 6) — financial operations  
6. **Account Pages** (Ch 9) — user-facing  
7. **POI Detail & Content** (Ch 4, 16) — expand existing coverage  
8. **Dashboard** (Ch 11) — visibility  
9. **Shared Components** (Ch 12) — reusable, high impact  
10. **Flutter screens** (Ch 14, 15, 17, 18, 19) — mobile coverage
