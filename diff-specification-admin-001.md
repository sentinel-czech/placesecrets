# HeroDots – Diferenciální specifikace administrace / web
# Diff č.: admin-001
# Datum: 2026-03-07 09:25:36
# Téma: Webové role (admin / přispěvatel / uživatel), správa přispěvatelů, Hall of Fame admin
# Soubor: spec-prompts-admin.md
# Navazuje na: sekce 20 (POI typy), diff-specification-001.md (mobilní app)

---

## Přehled změn

| #     | Oblast | Typ změny |
|-------|--------|-----------|
| DA-001 | Architektura – ze SPA adminu na multi-role web | ZMĚNA KONCEPTU |
| DA-002 | DB – rozšíření `admin_users` o roli `contributor` | ZMĚNA |
| DA-003 | DB – pohled `web_user_roles` – unified role lookup | NOVÉ |
| DA-004 | DB migrace `009_web_roles.sql` | NOVÉ |
| DA-005 | Supabase klient – dva klienty (anon + service_role) | ZMĚNA |
| DA-006 | AuthGuard – rozlišení rolí, protected routes | ZMĚNA |
| DA-007 | `useAuth` hook – role-aware session | NOVÉ |
| DA-008 | `RoleGuard` komponenta – inline ochrana sekcí | NOVÉ |
| DA-009 | App.tsx routing – tři skupiny routes | ZMĚNA |
| DA-010 | Sidebar – dynamická navigace dle role | ZMĚNA |
| DA-011 | Přispěvatelský portál – `/contributor/*` sekce | NOVÉ |
| DA-012 | `ContributorDashboard` – přehled přispěvatele | NOVÉ |
| DA-013 | `ContributorPoiListPage` – moje POI s hodnoceními | NOVÉ |
| DA-014 | `ContributorPoiEditorPage` – editor textu POI | NOVÉ |
| DA-015 | `ContributorProfilePage` – editace veřejného profilu | NOVÉ |
| DA-016 | Admin – `ContributorsPage` – správa přispěvatelů | NOVÉ |
| DA-017 | Admin – `ContributorDetailPage` – detail + schválení | NOVÉ |
| DA-018 | Admin – `HallOfFamePage` – přehled žebříčků | NOVÉ |
| DA-019 | Admin – rozšíření `admin_stats` o contributor metriky | ZMĚNA |
| DA-020 | Veřejná registrace přispěvatele (`/register/contributor`) | NOVÉ |
| DA-021 | Email pozvánka přispěvateli (Edge Function) | NOVÉ |
| DA-022 | Aktualizace roadmapy | ZMĚNA |

---

## DA-001 – Architektura – ze SPA adminu na multi-role web

### Původní stav
```
admin.herodots.app → jen interní admin panel
Jedna role: admin (superadmin / editor / viewer)
Jeden Supabase klient: service_role
```

### Nový stav
```
herodots.app/admin        → admin panel (beze změny funkcionality)
herodots.app/contributor  → portál přispěvatelů
herodots.app/account      → uživatelský self-service (platby, přístupy)

┌─────────────────────────────────────────────────────┐
│  Vite + React SPA (stejný build, různé route skupiny)│
│                                                      │
│  /login          → přihlášení pro všechny role       │
│  /register/*     → registrace přispěvatele           │
│                                                      │
│  /admin/*        → role: superadmin, editor, viewer  │
│  /contributor/*  → role: contributor                 │
│  /account/*      → role: authenticated user          │
└──────────────┬──────────────────────────────────────┘
               │
        ┌──────┴──────┐
        │  Supabase   │
        │  anon key   │  ← pro contributor + user portál
        │  +          │
        │ service_role │  ← jen pro /admin/* routes
        └─────────────┘
```

### Klíčový bezpečnostní princip
- `/admin/*` nadále používá `service_role` klient – plný přístup
- `/contributor/*` a `/account/*` používají `anon` klient – RLS chrání data
- Contributor vidí **jen svá vlastní POI** díky RLS policy na `pois`
- Admin vidí vše přes service_role (obejde RLS)

---

## DA-002 – DB – rozšíření `admin_users`

```sql
-- Stávající role: superadmin | editor | viewer
-- Přidat: contributor

ALTER TABLE public.admin_users
  DROP CONSTRAINT admin_users_role_check;

ALTER TABLE public.admin_users
  ADD CONSTRAINT admin_users_role_check
  CHECK (role IN ('superadmin', 'editor', 'viewer', 'contributor'));

-- Contributor má omezená práva:
-- - Čte/edituje jen svá vlastní POI (přes contributor_id)
-- - Nemůže mazat POI (jen deaktivovat)
-- - Nemůže vidět platby ani osobní data uživatelů
-- - Nemůže měnit nastavení ani spravovat jiné uživatele
```

---

## DA-003 – DB pohled `web_user_roles`

```sql
-- supabase/migrations/009_web_roles.sql

-- Unified lookup: jakou roli má přihlášený uživatel?
-- Zahrnuje: admin role + contributor_profile status

CREATE OR REPLACE VIEW public.web_user_roles AS
SELECT
  u.id                    AS user_id,
  u.email,
  au.role                 AS admin_role,      -- NULL pokud není admin
  cp.id                   AS contributor_id,  -- NULL pokud není contributor
  cp.display_name,
  cp.is_verified          AS contributor_verified,
  cp.avg_rating,
  cp.total_pois,
  CASE
    WHEN au.role IN ('superadmin', 'editor', 'viewer') THEN au.role
    WHEN au.role = 'contributor'                        THEN 'contributor'
    WHEN cp.id IS NOT NULL                              THEN 'contributor'
    ELSE                                                     'user'
  END                     AS effective_role
FROM auth.users u
LEFT JOIN public.admin_users au ON au.user_id = u.id
LEFT JOIN public.contributor_profiles cp ON cp.user_id = u.id;

-- RLS: každý vidí jen svůj vlastní řádek
ALTER VIEW public.web_user_roles OWNER TO postgres;
GRANT SELECT ON public.web_user_roles TO authenticated;

-- RLS policy pro contributor na pois tabulce:
-- Contributor může editovat jen POI kde je contributor_id = auth.uid()
CREATE POLICY "pois_contributor_write" ON public.pois
  FOR ALL USING (
    contributor_id = auth.uid()
    OR auth.role() = 'service_role'
  );
```

---

## DA-004 – DB migrace `009_web_roles.sql`

```sql
-- supabase/migrations/009_web_roles.sql (kompletní)

-- 1. Rozšíření role v admin_users
ALTER TABLE public.admin_users
  DROP CONSTRAINT IF EXISTS admin_users_role_check;
ALTER TABLE public.admin_users
  ADD CONSTRAINT admin_users_role_check
  CHECK (role IN ('superadmin', 'editor', 'viewer', 'contributor'));

-- 2. Pohled web_user_roles (viz DA-003)
-- ... (kód výše) ...

-- 3. RLS pro contributor přístup k pois
-- (contributor_profiles a poi_ratings již mají RLS z migrace 008)

-- Contributor může INSERT nové POI (přiřadit si contributor_id)
CREATE POLICY "pois_contributor_insert" ON public.pois
  FOR INSERT WITH CHECK (
    contributor_id = auth.uid()
    AND EXISTS (
      SELECT 1 FROM public.contributor_profiles
      WHERE user_id = auth.uid() AND is_active = TRUE
    )
  );

-- 4. Přidat anon key proměnnou do .env.local
-- VITE_SUPABASE_ANON_KEY=eyJ...  (pro contributor + user portál)
```

---

## DA-005 – Dva Supabase klienti

```typescript
// src/lib/supabase/client.ts – aktualizovat

import { createClient } from '@supabase/supabase-js'
import type { Database } from './types'

// Service role – POUZE pro admin routes (/admin/*)
// Obchází RLS – plný přístup k databázi
export const supabaseAdmin = createClient<Database>(
  import.meta.env.VITE_SUPABASE_URL,
  import.meta.env.VITE_SUPABASE_SERVICE_ROLE_KEY,
  { auth: { persistSession: false } }   // admin nemá vlastní session stav
)

// Anon klient – pro contributor portál a user portál
// Respektuje RLS – uživatel vidí jen svá data
export const supabase = createClient<Database>(
  import.meta.env.VITE_SUPABASE_URL,
  import.meta.env.VITE_SUPABASE_ANON_KEY,
  { auth: { persistSession: true, autoRefreshToken: true } }
)

// Zpětná kompatibilita – admin pages stále importují 'supabase'
// ale interně by měly přejít na supabaseAdmin
// Přechodné řešení: exportovat alias
export { supabaseAdmin as supabaseService }
```

```
// .env.local – přidat:
VITE_SUPABASE_ANON_KEY=eyJ...
// VITE_SUPABASE_SERVICE_ROLE_KEY zůstává (pro admin)
```

---

## DA-006 – AuthGuard – role-aware

```tsx
// src/components/layout/AuthGuard.tsx – kompletní přepis

import { useEffect, useState } from 'react'
import { Navigate, Outlet, useLocation } from 'react-router-dom'
import { supabase } from '@/lib/supabase/client'
import { useAuthStore } from '@/hooks/useAuth'

type RequiredRole = 'admin' | 'contributor' | 'user' | 'any'

interface AuthGuardProps {
  requiredRole?: RequiredRole
}

export function AuthGuard({ requiredRole = 'any' }: AuthGuardProps) {
  const location = useLocation()
  const { user, role, loading, initialize } = useAuthStore()

  useEffect(() => { initialize() }, [])

  if (loading) return <FullscreenSpinner />

  // Nepřihlášen → login
  if (!user) return <Navigate to="/login" state={{ from: location }} replace />

  // Kontrola role
  if (requiredRole === 'admin' && !['superadmin', 'editor', 'viewer'].includes(role ?? '')) {
    return <Navigate to="/unauthorized" replace />
  }
  if (requiredRole === 'contributor' && role !== 'contributor' && !['superadmin', 'editor'].includes(role ?? '')) {
    return <Navigate to="/unauthorized" replace />
  }

  return <Outlet />
}

function FullscreenSpinner() {
  return (
    <div className="h-screen flex items-center justify-center">
      <div className="animate-spin w-8 h-8 border-4 border-primary border-t-transparent rounded-full" />
    </div>
  )
}
```

---

## DA-007 – `useAuth` hook

```typescript
// src/hooks/useAuth.ts
import { create } from 'zustand'
import { supabase } from '@/lib/supabase/client'

export type AppRole = 'superadmin' | 'editor' | 'viewer' | 'contributor' | 'user' | null

interface AuthState {
  user: any | null
  role: AppRole
  contributorId: string | null
  displayName: string | null
  isVerified: boolean
  loading: boolean
  initialize: () => Promise<void>
  signOut: () => Promise<void>
}

export const useAuthStore = create<AuthState>((set) => ({
  user: null,
  role: null,
  contributorId: null,
  displayName: null,
  isVerified: false,
  loading: true,

  initialize: async () => {
    set({ loading: true })

    const { data: { session } } = await supabase.auth.getSession()

    if (!session) {
      set({ user: null, role: null, loading: false })
      return
    }

    // Načíst roli z pohledu web_user_roles
    const { data: roleData } = await supabase
      .from('web_user_roles')
      .select('effective_role, contributor_id, display_name, contributor_verified')
      .eq('user_id', session.user.id)
      .single()

    set({
      user: session.user,
      role: (roleData?.effective_role as AppRole) ?? 'user',
      contributorId: roleData?.contributor_id ?? null,
      displayName: roleData?.display_name ?? session.user.email,
      isVerified: roleData?.contributor_verified ?? false,
      loading: false,
    })

    // Sledovat změny session
    supabase.auth.onAuthStateChange(async (event, newSession) => {
      if (event === 'SIGNED_OUT' || !newSession) {
        set({ user: null, role: null, contributorId: null, loading: false })
      }
    })
  },

  signOut: async () => {
    await supabase.auth.signOut()
    set({ user: null, role: null, contributorId: null })
  },
}))

// Helper hooks
export const useIsAdmin = () => {
  const role = useAuthStore(s => s.role)
  return ['superadmin', 'editor', 'viewer'].includes(role ?? '')
}

export const useIsContributor = () => {
  const role = useAuthStore(s => s.role)
  return role === 'contributor' || role === 'superadmin' || role === 'editor'
}

export const useCanEdit = () => {
  const role = useAuthStore(s => s.role)
  return ['superadmin', 'editor'].includes(role ?? '')
}

export const useIsSuperAdmin = () => {
  const role = useAuthStore(s => s.role)
  return role === 'superadmin'
}
```

---

## DA-008 – `RoleGuard` komponenta

```tsx
// src/components/layout/RoleGuard.tsx
// Inline ochrana – skryje obsah pokud uživatel nemá požadovanou roli

import { useAuthStore } from '@/hooks/useAuth'
import type { AppRole } from '@/hooks/useAuth'

interface RoleGuardProps {
  roles: AppRole[]
  fallback?: React.ReactNode  // co zobrazit pokud nemá roli (výchozí: nic)
  children: React.ReactNode
}

export function RoleGuard({ roles, fallback = null, children }: RoleGuardProps) {
  const role = useAuthStore(s => s.role)
  if (!role || !roles.includes(role)) return <>{fallback}</>
  return <>{children}</>
}

// Příklady použití:
//
// Tlačítko "Smazat" jen pro superadmin:
// <RoleGuard roles={['superadmin']}>
//   <button>Smazat</button>
// </RoleGuard>
//
// Celá sekce jen pro adminy:
// <RoleGuard roles={['superadmin', 'editor', 'viewer']}
//   fallback={<UnauthorizedBanner />}>
//   <AdminOnlySection />
// </RoleGuard>
```

---

## DA-009 – App.tsx – tři skupiny routes

```tsx
// src/App.tsx – kompletní přepis routingu

import { BrowserRouter, Routes, Route, Navigate } from 'react-router-dom'
import { AuthGuard } from '@/components/layout/AuthGuard'
import { AppShell } from '@/components/layout/AppShell'
import { ContributorShell } from '@/components/layout/ContributorShell'

// ── Admin pages (beze změny) ──────────────────────────────
import { LoginPage } from '@/pages/LoginPage'
import { DashboardPage } from '@/pages/DashboardPage'
import { CitiesPage } from '@/pages/cities/CitiesPage'
import { CityNewPage } from '@/pages/cities/CityNewPage'
import { CityEditPage } from '@/pages/cities/CityEditPage'
import { PoisPage } from '@/pages/pois/PoisPage'
import { PoiNewPage } from '@/pages/pois/PoiNewPage'
import { PoiEditPage } from '@/pages/pois/PoiEditPage'
import { UsersPage } from '@/pages/users/UsersPage'
import { UserDetailPage } from '@/pages/users/UserDetailPage'
import { PaymentsPage } from '@/pages/payments/PaymentsPage'
import { PaymentDetailPage } from '@/pages/payments/PaymentDetailPage'
import { SettingsPage } from '@/pages/SettingsPage'
import { PoiTypesPage } from '@/pages/poi-types/PoiTypesPage'
// ── Nové admin pages ──────────────────────────────────────
import { ContributorsPage } from '@/pages/contributors/ContributorsPage'
import { ContributorDetailPage } from '@/pages/contributors/ContributorDetailPage'
import { HallOfFamePage } from '@/pages/hall-of-fame/HallOfFamePage'
// ── Contributor portál ────────────────────────────────────
import { ContributorDashboard } from '@/pages/contributor/ContributorDashboard'
import { ContributorPoiListPage } from '@/pages/contributor/ContributorPoiListPage'
import { ContributorPoiEditorPage } from '@/pages/contributor/ContributorPoiEditorPage'
import { ContributorProfilePage } from '@/pages/contributor/ContributorProfilePage'
// ── Registrace ────────────────────────────────────────────
import { ContributorRegisterPage } from '@/pages/register/ContributorRegisterPage'
import { UnauthorizedPage } from '@/pages/UnauthorizedPage'

export default function App() {
  return (
    <BrowserRouter>
      <Routes>
        {/* Veřejné routes */}
        <Route path="/login" element={<LoginPage />} />
        <Route path="/register/contributor" element={<ContributorRegisterPage />} />
        <Route path="/unauthorized" element={<UnauthorizedPage />} />

        {/* ── ADMIN routes (/admin/*) ── */}
        <Route path="/admin" element={<AuthGuard requiredRole="admin" />}>
          <Route element={<AppShell />}>
            <Route index element={<Navigate to="/admin/dashboard" replace />} />
            <Route path="dashboard" element={<DashboardPage />} />
            <Route path="cities" element={<CitiesPage />} />
            <Route path="cities/new" element={<CityNewPage />} />
            <Route path="cities/:id" element={<CityEditPage />} />
            <Route path="cities/:cityId/pois" element={<PoisPage />} />
            <Route path="cities/:cityId/pois/new" element={<PoiNewPage />} />
            <Route path="cities/:cityId/pois/:poiId" element={<PoiEditPage />} />
            <Route path="poi-types" element={<PoiTypesPage />} />
            <Route path="users" element={<UsersPage />} />
            <Route path="users/:id" element={<UserDetailPage />} />
            <Route path="payments" element={<PaymentsPage />} />
            <Route path="payments/:id" element={<PaymentDetailPage />} />
            {/* NOVÉ */}
            <Route path="contributors" element={<ContributorsPage />} />
            <Route path="contributors/:id" element={<ContributorDetailPage />} />
            <Route path="hall-of-fame" element={<HallOfFamePage />} />
            <Route path="settings" element={<SettingsPage />} />
          </Route>
        </Route>

        {/* ── CONTRIBUTOR portál (/contributor/*) ── */}
        <Route path="/contributor" element={<AuthGuard requiredRole="contributor" />}>
          <Route element={<ContributorShell />}>
            <Route index element={<Navigate to="/contributor/dashboard" replace />} />
            <Route path="dashboard" element={<ContributorDashboard />} />
            <Route path="pois" element={<ContributorPoiListPage />} />
            <Route path="pois/new" element={<ContributorPoiEditorPage />} />
            <Route path="pois/:poiId" element={<ContributorPoiEditorPage />} />
            <Route path="profile" element={<ContributorProfilePage />} />
          </Route>
        </Route>

        {/* Přesměrování ze starých URL na nové */}
        <Route path="/dashboard" element={<Navigate to="/admin/dashboard" replace />} />
        <Route path="/cities/*" element={<Navigate to="/admin/cities" replace />} />
        <Route path="/users/*" element={<Navigate to="/admin/users" replace />} />
        <Route path="/payments/*" element={<Navigate to="/admin/payments" replace />} />
        <Route path="/settings" element={<Navigate to="/admin/settings" replace />} />

        <Route path="/" element={<Navigate to="/admin/dashboard" replace />} />
        <Route path="*" element={<Navigate to="/admin/dashboard" replace />} />
      </Routes>
    </BrowserRouter>
  )
}
```

---

## DA-010 – Sidebar – dynamická navigace dle role

```tsx
// src/components/layout/Sidebar.tsx – aktualizovat NAV

import { useAuthStore, useIsAdmin, useIsSuperAdmin } from '@/hooks/useAuth'

// Admin navigace (beze změny struktury, přidat contributors + HoF)
const ADMIN_NAV = [
  { to: '/admin/dashboard',    icon: LayoutDashboard, label: 'Dashboard',        roles: ['superadmin','editor','viewer'] },
  { to: '/admin/cities',       icon: MapPin,           label: 'Oblasti & POI',    roles: ['superadmin','editor','viewer'] },
  { to: '/admin/poi-types',    icon: Tag,              label: 'Typy POI',         roles: ['superadmin','editor','viewer'] },
  { to: '/admin/users',        icon: Users,            label: 'Uživatelé',        roles: ['superadmin','editor','viewer'] },
  { to: '/admin/payments',     icon: CreditCard,       label: 'Platby',           roles: ['superadmin','editor','viewer'] },
  { to: '/admin/contributors', icon: PenLine,          label: 'Přispěvatelé',     roles: ['superadmin','editor'] },  // ← NOVÉ
  { to: '/admin/hall-of-fame', icon: Trophy,           label: 'Hall of Fame',     roles: ['superadmin','editor','viewer'] }, // ← NOVÉ
  { to: '/admin/settings',     icon: Settings,         label: 'Nastavení',        roles: ['superadmin'] },
]

// Contributor navigace (pro ContributorShell)
export const CONTRIBUTOR_NAV = [
  { to: '/contributor/dashboard', icon: LayoutDashboard, label: 'Přehled' },
  { to: '/contributor/pois',      icon: MapPin,           label: 'Moje průvodci' },
  { to: '/contributor/profile',   icon: UserCircle,       label: 'Můj profil' },
]

// V Sidebar komponentě – filtrovat dle role:
export function Sidebar() {
  const role = useAuthStore(s => s.role)

  return (
    <nav>
      {ADMIN_NAV
        .filter(item => item.roles.includes(role ?? ''))
        .map(item => <NavItem key={item.to} {...item} />)
      }
    </nav>
  )
}
```

---

## DA-011 – ContributorShell

```tsx
// src/components/layout/ContributorShell.tsx
// Jednodušší shell pro contributor portál – bez admin komplexity

import { Outlet, NavLink, useNavigate } from 'react-router-dom'
import { useAuthStore } from '@/hooks/useAuth'
import { CONTRIBUTOR_NAV } from './Sidebar'
import { LogOut, ExternalLink } from 'lucide-react'

export function ContributorShell() {
  const { user, displayName, isVerified, signOut } = useAuthStore()
  const navigate = useNavigate()

  return (
    <div className="min-h-screen flex bg-background">
      {/* Sidebar */}
      <aside className="w-56 border-r bg-card flex flex-col shrink-0">
        {/* Logo */}
        <div className="p-4 border-b">
          <div className="flex items-center gap-2">
            <div className="w-7 h-7 bg-primary rounded flex items-center justify-center">
              <span className="text-white text-xs font-bold">HD</span>
            </div>
            <div>
              <p className="text-sm font-semibold leading-none">HeroDots</p>
              <p className="text-xs text-muted-foreground">Průvodci</p>
            </div>
          </div>
        </div>

        {/* Nav */}
        <nav className="flex-1 p-3 space-y-1">
          {CONTRIBUTOR_NAV.map(item => (
            <NavLink
              key={item.to}
              to={item.to}
              className={({ isActive }) =>
                `flex items-center gap-2.5 px-3 py-2 rounded text-sm transition-colors ${
                  isActive
                    ? 'bg-primary/10 text-primary font-medium'
                    : 'text-muted-foreground hover:bg-muted hover:text-foreground'
                }`
              }
            >
              <item.icon className="w-4 h-4 shrink-0" />
              {item.label}
            </NavLink>
          ))}
        </nav>

        {/* Profil + odhlášení */}
        <div className="p-3 border-t space-y-2">
          {/* Verified badge */}
          {isVerified && (
            <div className="flex items-center gap-1.5 px-3 py-1.5 bg-blue-50 rounded text-blue-700 text-xs">
              <span>✓</span>
              <span>Ověřený průvodce</span>
            </div>
          )}
          {!isVerified && (
            <div className="flex items-center gap-1.5 px-3 py-1.5 bg-orange-50 rounded text-orange-700 text-xs">
              <span>⏳</span>
              <span>Čeká na ověření</span>
            </div>
          )}
          <p className="text-xs text-muted-foreground px-3 truncate">{displayName}</p>
          <button
            onClick={() => { signOut(); navigate('/login') }}
            className="w-full flex items-center gap-2 px-3 py-1.5 text-sm text-muted-foreground hover:text-foreground rounded hover:bg-muted"
          >
            <LogOut className="w-3.5 h-3.5" />
            Odhlásit se
          </button>
        </div>
      </aside>

      {/* Obsah */}
      <main className="flex-1 overflow-auto">
        <div className="p-6 max-w-4xl mx-auto">
          <Outlet />
        </div>
      </main>
    </div>
  )
}
```

---

## DA-012 – `ContributorDashboard`

```tsx
// src/pages/contributor/ContributorDashboard.tsx

export function ContributorDashboard() {
  const { displayName, contributorId } = useAuthStore()
  const [stats, setStats] = useState<any>(null)

  useEffect(() => {
    if (!contributorId) return
    supabase
      .from('contributor_profiles')
      .select('total_pois, avg_rating, total_ratings')
      .eq('id', contributorId)
      .single()
      .then(({ data }) => setStats(data))
  }, [contributorId])

  return (
    <div className="space-y-6">
      {/* Uvítání */}
      <div>
        <h1 className="text-2xl font-bold">Vítej, {displayName} 👋</h1>
        <p className="text-muted-foreground text-sm mt-1">
          Průvodcovský portál HeroDots
        </p>
      </div>

      {/* Statistiky */}
      <div className="grid grid-cols-3 gap-4">
        <StatCard
          label="Moje průvodci"
          value={stats?.total_pois ?? '—'}
          icon="📍"
        />
        <StatCard
          label="Průměrné hodnocení"
          value={stats?.avg_rating ? `${stats.avg_rating.toFixed(1)} ★` : '—'}
          icon="⭐"
        />
        <StatCard
          label="Celkem hodnocení"
          value={stats?.total_ratings ?? '—'}
          icon="🗳️"
        />
      </div>

      {/* Rychlé akce */}
      <div className="border rounded-lg p-5 space-y-3">
        <h2 className="font-semibold">Rychlé akce</h2>
        <div className="flex flex-wrap gap-3">
          <Link to="/contributor/pois/new">
            <button className="flex items-center gap-2 px-4 py-2 bg-primary text-white rounded text-sm">
              <Plus className="w-4 h-4" />
              Napsat nového průvodce
            </button>
          </Link>
          <Link to="/contributor/pois">
            <button className="flex items-center gap-2 px-4 py-2 border rounded text-sm hover:bg-muted">
              <MapPin className="w-4 h-4" />
              Zobrazit moje průvodce
            </button>
          </Link>
          <Link to="/contributor/profile">
            <button className="flex items-center gap-2 px-4 py-2 border rounded text-sm hover:bg-muted">
              <UserCircle className="w-4 h-4" />
              Upravit profil
            </button>
          </Link>
        </div>
      </div>

      {/* Informace o systému hodnocení */}
      <div className="border rounded-lg p-5 bg-muted/30 space-y-2">
        <h2 className="font-semibold text-sm flex items-center gap-2">
          <Trophy className="w-4 h-4 text-yellow-600" />
          Jak funguje Hall of Fame?
        </h2>
        <p className="text-sm text-muted-foreground">
          Tvoje průvodci hodnotí návštěvníci v mobilní aplikaci.
          Průvodce s průměrem alespoň 4★ od 10+ hodnotitelů vstoupí
          do žebříčku. Top 10 průvodců v každém městě tvoří Hall of Fame.
        </p>
        <div className="flex items-center gap-4 pt-1 text-sm">
          <span className="text-muted-foreground">Práh pro žebříček:</span>
          <span className="font-medium">10 hodnocení · průměr ≥ 4.0★</span>
        </div>
      </div>
    </div>
  )
}

function StatCard({ label, value, icon }: { label: string; value: any; icon: string }) {
  return (
    <div className="border rounded-lg p-4 space-y-1">
      <p className="text-2xl">{icon}</p>
      <p className="text-2xl font-bold">{value}</p>
      <p className="text-sm text-muted-foreground">{label}</p>
    </div>
  )
}
```

---

## DA-013 – `ContributorPoiListPage`

```tsx
// src/pages/contributor/ContributorPoiListPage.tsx
// Contributor vidí jen SVÁ POI – RLS zajistí filtraci na DB úrovni

export function ContributorPoiListPage() {
  const { user } = useAuthStore()
  const [pois, setPois] = useState<any[]>([])
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    // anon klient – RLS vrátí jen contributor_id = auth.uid()
    supabase
      .from('pois')
      .select(`
        id, name, city_id, is_active, avg_rating, total_ratings, sort_order,
        cities(name),
        poi_types(name, icon_name, color_hex)
      `)
      .eq('contributor_id', user?.id)
      .order('created_at', { ascending: false })
      .then(({ data }) => { setPois(data ?? []); setLoading(false) })
  }, [user?.id])

  return (
    <div className="space-y-4">
      <div className="flex items-center justify-between">
        <h1 className="text-xl font-bold">Moje průvodci</h1>
        <Link to="/contributor/pois/new">
          <button className="flex items-center gap-2 px-4 py-2 bg-primary text-white rounded text-sm">
            <Plus className="w-4 h-4" />Přidat průvodce
          </button>
        </Link>
      </div>

      {loading ? (
        <div className="text-center py-12 text-muted-foreground">Načítám...</div>
      ) : pois.length === 0 ? (
        <EmptyState
          title="Zatím žádné průvodce"
          description="Napište svůj první průvodce pro zajímavé místo ve vašem okolí."
          action={<Link to="/contributor/pois/new"><button className="px-4 py-2 bg-primary text-white rounded text-sm">Napsat průvodce</button></Link>}
        />
      ) : (
        <div className="space-y-3">
          {pois.map(poi => (
            <ContributorPoiCard key={poi.id} poi={poi} />
          ))}
        </div>
      )}
    </div>
  )
}

function ContributorPoiCard({ poi }: { poi: any }) {
  const cityName = poi.cities?.name ?? '—'
  const typeName = poi.poi_types?.name?.cs ?? '—'
  const hasRatings = (poi.total_ratings ?? 0) >= 10
  const qualifiesHoF = hasRatings && (poi.avg_rating ?? 0) >= 4.0

  return (
    <div className="border rounded-lg p-4 hover:bg-muted/20 transition-colors">
      <div className="flex items-start justify-between gap-4">
        <div className="flex-1 min-w-0">
          <div className="flex items-center gap-2 mb-1">
            <h3 className="font-medium truncate">{poi.name?.cs ?? '—'}</h3>
            {qualifiesHoF && (
              <span className="shrink-0 text-xs bg-yellow-100 text-yellow-800 px-2 py-0.5 rounded-full flex items-center gap-1">
                🏆 Hall of Fame
              </span>
            )}
          </div>
          <p className="text-sm text-muted-foreground">
            {cityName} · {typeName}
          </p>
          {/* Hodnocení */}
          <div className="flex items-center gap-3 mt-2">
            {poi.total_ratings > 0 ? (
              <>
                <span className="text-sm font-medium text-yellow-600">
                  {(poi.avg_rating ?? 0).toFixed(1)}★
                </span>
                <span className="text-xs text-muted-foreground">
                  {poi.total_ratings} hodnocení
                </span>
                {!hasRatings && (
                  <span className="text-xs text-muted-foreground">
                    (potřeba {10 - poi.total_ratings} pro žebříček)
                  </span>
                )}
              </>
            ) : (
              <span className="text-xs text-muted-foreground">Zatím bez hodnocení</span>
            )}
          </div>
        </div>
        <div className="flex items-center gap-2 shrink-0">
          <span className={`text-xs px-2 py-0.5 rounded-full ${poi.is_active ? 'bg-green-100 text-green-700' : 'bg-gray-100 text-gray-600'}`}>
            {poi.is_active ? 'Aktivní' : 'Neaktivní'}
          </span>
          <Link to={`/contributor/pois/${poi.id}`}>
            <button className="p-1.5 hover:bg-muted rounded">
              <Pencil className="w-4 h-4" />
            </button>
          </Link>
        </div>
      </div>
    </div>
  )
}
```

---

## DA-014 – `ContributorPoiEditorPage`

```tsx
// src/pages/contributor/ContributorPoiEditorPage.tsx
// Contributor píše/edituje text průvodce pro existující POI
// NEMŮŽE: měnit souřadnice, geofence, přiřazovat foto/audio (to dělá admin)
// MŮŽE: název, popis (text pro TTS), přiřadit se jako autor

export function ContributorPoiEditorPage() {
  const { id: poiId } = useParams<{ id?: string }>()
  const { user } = useAuthStore()
  const navigate = useNavigate()
  const toast = useToast()
  const isNew = !poiId

  // Pro nové POI: musí si vybrat z existujících POI bez autora
  const [availablePois, setAvailablePois] = useState<any[]>([])
  const [selectedPoiId, setSelectedPoiId] = useState<string>('')
  const [poi, setPoi] = useState<any>(null)
  const [names, setNames] = useState<Record<string, string>>({ cs: '', en: '', de: '' })
  const [descriptions, setDescriptions] = useState<Record<string, string>>({ cs: '', en: '', de: '' })
  const [activeLang, setActiveLang] = useState<'cs' | 'en' | 'de'>('cs')
  const [saving, setSaving] = useState(false)

  // Načíst POI bez autora pro výběr (pokud nové)
  useEffect(() => {
    if (isNew) {
      supabase
        .from('pois')
        .select('id, name, cities(name)')
        .is('contributor_id', null)
        .eq('is_active', true)
        .order('sort_order')
        .then(({ data }) => setAvailablePois(data ?? []))
    }
  }, [isNew])

  // Načíst existující POI
  useEffect(() => {
    const id = isNew ? selectedPoiId : poiId
    if (!id) return
    supabase
      .from('pois')
      .select('*, cities(name), poi_types(name)')
      .eq('id', id)
      .single()
      .then(({ data }) => {
        if (data) {
          setPoi(data)
          setNames(data.name ?? { cs: '', en: '', de: '' })
          setDescriptions(data.description ?? { cs: '', en: '', de: '' })
        }
      })
  }, [poiId, selectedPoiId])

  async function save() {
    const id = isNew ? selectedPoiId : poiId
    if (!id || !names.cs) return
    setSaving(true)

    await supabase
      .from('pois')
      .update({
        name: names,
        description: descriptions,
        contributor_id: user?.id,   // přiřadit sebe jako autora
        updated_at: new Date().toISOString(),
      })
      .eq('id', id)

    toast.success('Průvodce uložen')
    setSaving(false)
    navigate('/contributor/pois')
  }

  return (
    <div className="space-y-6 max-w-2xl">
      <div className="flex items-center gap-3">
        <button onClick={() => navigate('/contributor/pois')} className="p-2 hover:bg-muted rounded">
          <ArrowLeft className="w-4 h-4" />
        </button>
        <h1 className="text-xl font-bold">
          {isNew ? 'Napsat průvodce' : `Editovat: ${poi?.name?.cs ?? '...'}`}
        </h1>
      </div>

      {/* Výběr POI (jen pro nové) */}
      {isNew && (
        <div className="border rounded-lg p-5 space-y-3">
          <h2 className="font-medium">Vyberte místo</h2>
          <p className="text-sm text-muted-foreground">
            Tato místa zatím nemají průvodce. Vyberte jedno a napište text.
          </p>
          <select
            value={selectedPoiId}
            onChange={e => setSelectedPoiId(e.target.value)}
            className="input w-full"
          >
            <option value="">— Vyberte místo —</option>
            {availablePois.map(p => (
              <option key={p.id} value={p.id}>
                {p.name?.cs} – {p.cities?.name}
              </option>
            ))}
          </select>
        </div>
      )}

      {/* Editor textu */}
      {(poi || selectedPoiId) && (
        <>
          {/* Info o místě (read-only) */}
          {poi && (
            <div className="border rounded-lg p-4 bg-muted/30 text-sm space-y-1">
              <p className="font-medium">{poi.cities?.name}</p>
              <p className="text-muted-foreground">
                {poi.poi_types?.name?.cs ?? 'Typ neurčen'} ·
                GPS: {poi.latitude?.toFixed(5)}, {poi.longitude?.toFixed(5)}
              </p>
              <p className="text-xs text-muted-foreground mt-1">
                Souřadnice, fotografie a audio nahrávky upravuje pouze admin.
              </p>
            </div>
          )}

          {/* Jazykové záložky */}
          <div className="border rounded-lg p-5 space-y-4">
            <div className="flex border-b -mx-5 px-5">
              {(['cs', 'en', 'de'] as const).map(l => (
                <button
                  key={l}
                  onClick={() => setActiveLang(l)}
                  className={`px-4 py-2 text-sm font-medium border-b-2 transition-colors ${
                    activeLang === l
                      ? 'border-primary text-primary'
                      : 'border-transparent text-muted-foreground hover:text-foreground'
                  }`}
                >
                  {l === 'cs' ? '🇨🇿 CS' : l === 'en' ? '🇬🇧 EN' : '🇩🇪 DE'}
                  {!descriptions[l] && l !== 'cs' && (
                    <span className="ml-1 text-orange-400 text-xs">!</span>
                  )}
                </button>
              ))}
            </div>

            {/* Název */}
            <div>
              <label className="block text-sm font-medium mb-1">
                Název místa ({activeLang.toUpperCase()})
              </label>
              <input
                value={names[activeLang] ?? ''}
                onChange={e => setNames(n => ({ ...n, [activeLang]: e.target.value }))}
                placeholder="Název místa"
                className="input w-full"
              />
            </div>

            {/* Text průvodce */}
            <div>
              <label className="block text-sm font-medium mb-1">
                Text průvodce ({activeLang.toUpperCase()})
              </label>
              <textarea
                value={descriptions[activeLang] ?? ''}
                onChange={e => setDescriptions(d => ({ ...d, [activeLang]: e.target.value }))}
                placeholder="Napište zajímavý a přesný průvodní text. Tento text bude přečten jako audio průvodce pokud není nahráno audio."
                className="input w-full h-48 resize-none font-normal leading-relaxed"
              />
              <div className="flex justify-between mt-1">
                <p className="text-xs text-muted-foreground">
                  Doporučená délka: 200–500 slov. Text musí být fakticky správný.
                </p>
                <p className="text-xs text-muted-foreground">
                  {(descriptions[activeLang] ?? '').length} znaků
                </p>
              </div>
            </div>
          </div>

          {/* Tipy pro kvalitní průvodce */}
          <div className="border rounded-lg p-4 bg-blue-50/50 text-sm space-y-1">
            <p className="font-medium text-blue-800">💡 Tipy pro kvalitní průvodce</p>
            <ul className="text-blue-700 space-y-0.5 text-xs list-disc list-inside">
              <li>Začněte zajímavou historickou nebo poutavou informací</li>
              <li>Uveďte přibližný rok vzniku nebo historický kontext</li>
              <li>Zmiňte co je na místě unikátního nebo zajímavého pro turisty</li>
              <li>Vyhněte se příliš technickým detailům – text je pro turisty, ne odborníky</li>
              <li>Každé hodnocení od návštěvníků pomáhá vylepšit váš ranking v Hall of Fame</li>
            </ul>
          </div>

          {/* Uložit */}
          <div className="flex gap-3">
            <button
              onClick={save}
              disabled={!names.cs || saving}
              className="px-4 py-2 bg-primary text-white rounded text-sm disabled:opacity-50"
            >
              {saving ? 'Ukládám...' : 'Uložit průvodce'}
            </button>
            <button
              onClick={() => navigate('/contributor/pois')}
              className="px-4 py-2 border rounded text-sm hover:bg-muted"
            >
              Zrušit
            </button>
          </div>
        </>
      )}
    </div>
  )
}
```

---

## DA-015 – `ContributorProfilePage`

```tsx
// src/pages/contributor/ContributorProfilePage.tsx

export function ContributorProfilePage() {
  const { user, contributorId } = useAuthStore()
  const toast = useToast()
  const [profile, setProfile] = useState<any>(null)
  const [form, setForm] = useState({
    display_name: '',
    bio: '',
    website_url: '',
    specializations: [] as string[],
  })
  const [saving, setSaving] = useState(false)

  useEffect(() => {
    if (!contributorId) return
    supabase
      .from('contributor_profiles')
      .select('*')
      .eq('id', contributorId)
      .single()
      .then(({ data }) => {
        if (data) {
          setProfile(data)
          setForm({
            display_name: data.display_name,
            bio: data.bio ?? '',
            website_url: data.website_url ?? '',
            specializations: data.specializations ?? [],
          })
        }
      })
  }, [contributorId])

  async function save() {
    if (!contributorId || !form.display_name) return
    setSaving(true)
    await supabase
      .from('contributor_profiles')
      .update({ ...form, updated_at: new Date().toISOString() })
      .eq('id', contributorId)
    toast.success('Profil uložen')
    setSaving(false)
  }

  return (
    <div className="space-y-6 max-w-xl">
      <h1 className="text-xl font-bold">Můj průvodcovský profil</h1>

      {/* Veřejný profil */}
      <div className="border rounded-lg p-5 space-y-4">
        <h2 className="font-medium">Veřejné informace</h2>
        <p className="text-sm text-muted-foreground">
          Tyto informace uvidí uživatelé mobilní aplikace u vašich průvodců.
        </p>

        <div>
          <label className="block text-sm font-medium mb-1">Zobrazované jméno *</label>
          <input
            value={form.display_name}
            onChange={e => setForm(f => ({ ...f, display_name: e.target.value }))}
            className="input w-full"
            placeholder="Jan Novák"
          />
        </div>

        <div>
          <label className="block text-sm font-medium mb-1">Bio (max 300 znaků)</label>
          <textarea
            value={form.bio}
            onChange={e => setForm(f => ({ ...f, bio: e.target.value.slice(0, 300) }))}
            className="input w-full h-20 resize-none"
            placeholder="Místní průvodce a historik se zaměřením na..."
          />
          <p className="text-xs text-muted-foreground mt-1">{form.bio.length}/300</p>
        </div>

        <div>
          <label className="block text-sm font-medium mb-1">Web / LinkedIn (volitelné)</label>
          <input
            value={form.website_url}
            onChange={e => setForm(f => ({ ...f, website_url: e.target.value }))}
            className="input w-full"
            placeholder="https://linkedin.com/in/..."
          />
        </div>
      </div>

      {/* Stav ověření */}
      <div className={`border rounded-lg p-4 ${profile?.is_verified ? 'bg-blue-50 border-blue-200' : 'bg-orange-50 border-orange-200'}`}>
        <div className="flex items-center gap-2 mb-1">
          {profile?.is_verified
            ? <><span className="text-blue-600">✓</span><span className="font-medium text-blue-800">Ověřený průvodce</span></>
            : <><span className="text-orange-600">⏳</span><span className="font-medium text-orange-800">Čeká na ověření</span></>
          }
        </div>
        <p className="text-sm text-muted-foreground">
          {profile?.is_verified
            ? 'Váš profil byl ověřen administrátorem. Zobrazuje se modrá fajfka u vašich průvodců.'
            : 'Admin profil brzy přezkoumá. Po ověření se u vašich průvodců zobrazí modrá fajfka důvěryhodnosti.'
          }
        </p>
      </div>

      {/* Statistiky (read-only) */}
      <div className="border rounded-lg p-4 space-y-2">
        <h2 className="font-medium text-sm">Statistiky</h2>
        <div className="grid grid-cols-3 gap-3 text-center">
          <div>
            <p className="text-lg font-bold">{profile?.total_pois ?? 0}</p>
            <p className="text-xs text-muted-foreground">Průvodců</p>
          </div>
          <div>
            <p className="text-lg font-bold">
              {profile?.avg_rating ? `${Number(profile.avg_rating).toFixed(1)}★` : '—'}
            </p>
            <p className="text-xs text-muted-foreground">Průměr</p>
          </div>
          <div>
            <p className="text-lg font-bold">{profile?.total_ratings ?? 0}</p>
            <p className="text-xs text-muted-foreground">Hodnocení</p>
          </div>
        </div>
      </div>

      <button
        onClick={save}
        disabled={!form.display_name || saving}
        className="px-4 py-2 bg-primary text-white rounded text-sm disabled:opacity-50"
      >
        {saving ? 'Ukládám...' : 'Uložit profil'}
      </button>
    </div>
  )
}
```

---

## DA-016 – Admin – `ContributorsPage`

```tsx
// src/pages/contributors/ContributorsPage.tsx

export function ContributorsPage() {
  const [contributors, setContributors] = useState<any[]>([])
  const [search, setSearch] = useState('')
  const [filterVerified, setFilterVerified] = useState<'all' | 'verified' | 'pending'>('all')
  const toast = useToast()

  useEffect(() => { load() }, [])

  async function load() {
    const { data } = await supabaseAdmin
      .from('contributor_profiles')
      .select(`
        *,
        auth_user:user_id(email, created_at, last_sign_in_at)
      `)
      .order('created_at', { ascending: false })
    setContributors(data ?? [])
  }

  async function toggleVerified(cp: any) {
    await supabaseAdmin
      .from('contributor_profiles')
      .update({ is_verified: !cp.is_verified })
      .eq('id', cp.id)
    setContributors(cs => cs.map(c => c.id === cp.id ? { ...c, is_verified: !c.is_verified } : c))
    toast.success(cp.is_verified ? 'Ověření odebráno' : 'Přispěvatel ověřen')
  }

  const filtered = contributors.filter(c => {
    const matchSearch = !search
      || c.display_name?.toLowerCase().includes(search.toLowerCase())
      || c.auth_user?.email?.toLowerCase().includes(search.toLowerCase())
    const matchVerified = filterVerified === 'all'
      || (filterVerified === 'verified' && c.is_verified)
      || (filterVerified === 'pending' && !c.is_verified)
    return matchSearch && matchVerified
  })

  return (
    <div className="space-y-4">
      <div className="flex items-center justify-between">
        <div>
          <h2 className="text-xl font-bold">Přispěvatelé</h2>
          <p className="text-sm text-muted-foreground">
            Průvodci kteří přispívají texty pro POI
          </p>
        </div>
        <button
          onClick={() => {/* Invite modal */}}
          className="flex items-center gap-2 px-4 py-2 bg-primary text-white rounded text-sm"
        >
          <Mail className="w-4 h-4" />Pozvat přispěvatele
        </button>
      </div>

      {/* Filtry */}
      <div className="flex gap-3">
        <input
          value={search}
          onChange={e => setSearch(e.target.value)}
          placeholder="Hledat jméno nebo email..."
          className="input flex-1"
        />
        <select
          value={filterVerified}
          onChange={e => setFilterVerified(e.target.value as any)}
          className="input w-44"
        >
          <option value="all">Všichni</option>
          <option value="verified">Ověření</option>
          <option value="pending">Čekají na ověření</option>
        </select>
      </div>

      {/* Tabulka */}
      <div className="border rounded-lg overflow-hidden">
        <table className="w-full text-sm">
          <thead className="bg-muted/50 border-b">
            <tr>
              <th className="px-4 py-3 text-left font-medium text-muted-foreground">Přispěvatel</th>
              <th className="px-4 py-3 text-left font-medium text-muted-foreground">Email</th>
              <th className="px-4 py-3 text-left font-medium text-muted-foreground">Průvodci</th>
              <th className="px-4 py-3 text-left font-medium text-muted-foreground">Hodnocení</th>
              <th className="px-4 py-3 text-left font-medium text-muted-foreground">Ověřen</th>
              <th className="px-4 py-3 text-left font-medium text-muted-foreground">Registrace</th>
              <th className="px-4 py-3 text-right font-medium text-muted-foreground">Akce</th>
            </tr>
          </thead>
          <tbody>
            {filtered.map(c => (
              <tr key={c.id} className="border-t hover:bg-muted/20">
                <td className="px-4 py-3">
                  <div className="flex items-center gap-2">
                    <div className="w-8 h-8 rounded-full bg-primary/10 flex items-center justify-center text-sm font-medium text-primary">
                      {c.display_name?.[0] ?? '?'}
                    </div>
                    <div>
                      <p className="font-medium">{c.display_name}</p>
                      {c.bio && <p className="text-xs text-muted-foreground truncate max-w-[160px]">{c.bio}</p>}
                    </div>
                  </div>
                </td>
                <td className="px-4 py-3 text-muted-foreground">{c.auth_user?.email}</td>
                <td className="px-4 py-3 font-medium">{c.total_pois}</td>
                <td className="px-4 py-3">
                  {c.avg_rating
                    ? <span className="text-yellow-600 font-medium">{Number(c.avg_rating).toFixed(1)}★ <span className="text-xs text-muted-foreground">({c.total_ratings})</span></span>
                    : <span className="text-muted-foreground text-xs">—</span>
                  }
                </td>
                <td className="px-4 py-3">
                  <button onClick={() => toggleVerified(c)}>
                    {c.is_verified
                      ? <span className="text-xs bg-blue-100 text-blue-700 px-2 py-0.5 rounded-full">✓ Ověřen</span>
                      : <span className="text-xs bg-orange-100 text-orange-700 px-2 py-0.5 rounded-full">⏳ Čeká</span>
                    }
                  </button>
                </td>
                <td className="px-4 py-3 text-muted-foreground text-xs">
                  {new Date(c.created_at).toLocaleDateString('cs-CZ')}
                </td>
                <td className="px-4 py-3">
                  <div className="flex justify-end gap-1">
                    <Link to={`/admin/contributors/${c.id}`}>
                      <button className="p-1.5 hover:bg-muted rounded" title="Detail">
                        <Eye className="w-4 h-4" />
                      </button>
                    </Link>
                  </div>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
      <p className="text-xs text-muted-foreground">{filtered.length} přispěvatelů</p>
    </div>
  )
}
```

---

## DA-017 – Admin – `ContributorDetailPage`

```tsx
// src/pages/contributors/ContributorDetailPage.tsx
// Admin vidí vše: profil, všechna POI, hodnocení, může ověřit/odebrat

export function ContributorDetailPage() {
  const { id } = useParams<{ id: string }>()
  const toast = useToast()
  const [profile, setProfile] = useState<any>(null)
  const [pois, setPois] = useState<any[]>([])

  useEffect(() => {
    // Načíst profil
    supabaseAdmin
      .from('contributor_profiles')
      .select('*, auth.users!user_id(email, created_at)')
      .eq('id', id!)
      .single()
      .then(({ data }) => setProfile(data))

    // Načíst jeho POI s hodnoceními
    supabaseAdmin
      .from('pois')
      .select('*, cities(name), poi_types(name, icon_name, color_hex)')
      .eq('contributor_id', /* user_id z profilu */'')
      .order('sort_order')
      .then(({ data }) => setPois(data ?? []))
  }, [id])

  async function verify() {
    await supabaseAdmin
      .from('contributor_profiles')
      .update({ is_verified: true })
      .eq('id', id!)
    setProfile((p: any) => ({ ...p, is_verified: true }))
    toast.success('Přispěvatel ověřen')
  }

  async function removeVerification() {
    await supabaseAdmin
      .from('contributor_profiles')
      .update({ is_verified: false })
      .eq('id', id!)
    setProfile((p: any) => ({ ...p, is_verified: false }))
    toast.info('Ověření odebráno')
  }

  if (!profile) return <div className="p-6">Načítám...</div>

  return (
    <div className="space-y-6 max-w-3xl">
      {/* Hlavička */}
      <div className="flex items-start justify-between">
        <div className="flex items-center gap-4">
          <div className="w-14 h-14 rounded-full bg-primary/10 flex items-center justify-center text-2xl font-bold text-primary">
            {profile.display_name?.[0]}
          </div>
          <div>
            <div className="flex items-center gap-2">
              <h2 className="text-xl font-bold">{profile.display_name}</h2>
              {profile.is_verified && <span className="text-blue-500 text-sm">✓ Ověřen</span>}
            </div>
            <p className="text-sm text-muted-foreground">{profile.bio}</p>
          </div>
        </div>

        {/* Akce */}
        <div className="flex gap-2">
          {!profile.is_verified
            ? <button onClick={verify} className="px-3 py-1.5 bg-blue-600 text-white rounded text-sm">
                ✓ Ověřit
              </button>
            : <button onClick={removeVerification} className="px-3 py-1.5 border rounded text-sm hover:bg-muted">
                Odebrat ověření
              </button>
          }
        </div>
      </div>

      {/* Statistiky */}
      <div className="grid grid-cols-3 gap-4">
        <div className="border rounded-lg p-4 text-center">
          <p className="text-2xl font-bold">{profile.total_pois}</p>
          <p className="text-xs text-muted-foreground">Průvodců</p>
        </div>
        <div className="border rounded-lg p-4 text-center">
          <p className="text-2xl font-bold text-yellow-600">
            {profile.avg_rating ? `${Number(profile.avg_rating).toFixed(1)}★` : '—'}
          </p>
          <p className="text-xs text-muted-foreground">Průměr</p>
        </div>
        <div className="border rounded-lg p-4 text-center">
          <p className="text-2xl font-bold">{profile.total_ratings}</p>
          <p className="text-xs text-muted-foreground">Hodnocení celkem</p>
        </div>
      </div>

      {/* Seznam POI */}
      <div>
        <h3 className="font-semibold mb-3">Průvodci ({pois.length})</h3>
        <div className="border rounded-lg overflow-hidden">
          <table className="w-full text-sm">
            <thead className="bg-muted/50 border-b">
              <tr>
                <th className="px-4 py-2 text-left text-muted-foreground">POI</th>
                <th className="px-4 py-2 text-left text-muted-foreground">Město</th>
                <th className="px-4 py-2 text-left text-muted-foreground">Hodnocení</th>
                <th className="px-4 py-2 text-left text-muted-foreground">HoF</th>
                <th className="px-4 py-2 text-right text-muted-foreground">Akce</th>
              </tr>
            </thead>
            <tbody>
              {pois.map(p => (
                <tr key={p.id} className="border-t">
                  <td className="px-4 py-2 font-medium">{p.name?.cs}</td>
                  <td className="px-4 py-2 text-muted-foreground">{p.cities?.name}</td>
                  <td className="px-4 py-2">
                    {p.total_ratings > 0
                      ? <span className="text-yellow-600">{Number(p.avg_rating).toFixed(1)}★ ({p.total_ratings})</span>
                      : <span className="text-muted-foreground text-xs">—</span>
                    }
                  </td>
                  <td className="px-4 py-2">
                    {p.total_ratings >= 10 && p.avg_rating >= 4.0
                      ? <span className="text-xs">🏆</span>
                      : <span className="text-xs text-muted-foreground">—</span>
                    }
                  </td>
                  <td className="px-4 py-2">
                    <div className="flex justify-end">
                      <Link to={`/admin/cities/${p.city_id}/pois/${p.id}`}>
                        <button className="p-1 hover:bg-muted rounded" title="Editovat v adminu">
                          <ExternalLink className="w-3.5 h-3.5" />
                        </button>
                      </Link>
                    </div>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  )
}
```

---

## DA-018 – Admin – `HallOfFamePage`

```tsx
// src/pages/hall-of-fame/HallOfFamePage.tsx
// Admin přehled Hall of Fame přes všechna města

export function HallOfFamePage() {
  const [cities, setCities] = useState<any[]>([])
  const [selectedCity, setSelectedCity] = useState<string>('')
  const [hofData, setHofData] = useState<any[]>([])
  const [loading, setLoading] = useState(false)

  useEffect(() => {
    supabaseAdmin
      .from('cities')
      .select('id, name')
      .eq('is_active', true)
      .order('name')
      .then(({ data }) => {
        const list = data ?? []
        setCities(list)
        if (list.length > 0) setSelectedCity(list[0].id)
      })
  }, [])

  useEffect(() => {
    if (!selectedCity) return
    setLoading(true)
    supabaseAdmin
      .rpc('poi_hall_of_fame', { p_city_id: selectedCity, p_limit: 10 })
      .then(({ data }) => { setHofData(data ?? []); setLoading(false) })
  }, [selectedCity])

  return (
    <div className="space-y-4">
      <div>
        <h2 className="text-xl font-bold">Hall of Fame</h2>
        <p className="text-sm text-muted-foreground">
          Žebříček nejlepších průvodců per město
        </p>
      </div>

      {/* Výběr města */}
      <div className="flex items-center gap-3">
        <label className="text-sm font-medium">Město:</label>
        <select
          value={selectedCity}
          onChange={e => setSelectedCity(e.target.value)}
          className="input w-52"
        >
          {cities.map(c => <option key={c.id} value={c.id}>{c.name}</option>)}
        </select>
      </div>

      {/* Tabulka HoF */}
      {loading ? (
        <div className="text-center py-12 text-muted-foreground">Načítám žebříček...</div>
      ) : hofData.length === 0 ? (
        <div className="border rounded-lg p-8 text-center text-muted-foreground">
          <p className="text-2xl mb-2">🏆</p>
          <p className="font-medium">Žebříček je prázdný</p>
          <p className="text-sm mt-1">Žádný průvodce zatím nesplňuje minimum (10+ hodnocení, ≥4.0★)</p>
        </div>
      ) : (
        <div className="border rounded-lg overflow-hidden">
          <table className="w-full text-sm">
            <thead className="bg-muted/50 border-b">
              <tr>
                <th className="px-4 py-3 text-left font-medium text-muted-foreground w-12">#</th>
                <th className="px-4 py-3 text-left font-medium text-muted-foreground">Průvodce</th>
                <th className="px-4 py-3 text-left font-medium text-muted-foreground">POI v městě</th>
                <th className="px-4 py-3 text-left font-medium text-muted-foreground">Průměr</th>
                <th className="px-4 py-3 text-left font-medium text-muted-foreground">Hodnocení</th>
                <th className="px-4 py-3 text-left font-medium text-muted-foreground">HoF skóre</th>
                <th className="px-4 py-3 text-right font-medium text-muted-foreground">Akce</th>
              </tr>
            </thead>
            <tbody>
              {hofData.map((entry: any) => (
                <tr key={entry.contributor_id} className="border-t hover:bg-muted/20">
                  <td className="px-4 py-3">
                    <span className="font-bold text-lg">
                      {entry.rank === 1 ? '🥇' : entry.rank === 2 ? '🥈' : entry.rank === 3 ? '🥉' : `#${entry.rank}`}
                    </span>
                  </td>
                  <td className="px-4 py-3">
                    <div className="flex items-center gap-2">
                      <span className="font-medium">{entry.display_name}</span>
                      {entry.is_verified && <span className="text-blue-500 text-xs">✓</span>}
                    </div>
                  </td>
                  <td className="px-4 py-3">{entry.city_poi_count}</td>
                  <td className="px-4 py-3">
                    <span className="text-yellow-600 font-medium">
                      {entry.city_avg_rating ? `${Number(entry.city_avg_rating).toFixed(1)}★` : '—'}
                    </span>
                  </td>
                  <td className="px-4 py-3">{entry.city_total_ratings}</td>
                  <td className="px-4 py-3 font-mono text-xs text-muted-foreground">
                    {entry.hof_score ? Number(entry.hof_score).toFixed(3) : '—'}
                  </td>
                  <td className="px-4 py-3">
                    <div className="flex justify-end">
                      <Link to={`/admin/contributors/${entry.contributor_id}`}>
                        <button className="p-1.5 hover:bg-muted rounded">
                          <Eye className="w-4 h-4" />
                        </button>
                      </Link>
                    </div>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}

      {/* Info o scoring */}
      <div className="text-xs text-muted-foreground bg-muted/40 rounded p-3 space-y-1">
        <p>• Skóre = průměrné hodnocení × log₁₀(počet hodnocení + 1)</p>
        <p>• Minimum pro vstup do žebříčku: 10 hodnocení v daném městě</p>
        <p>• Žebříček se aktualizuje v reálném čase (trigger po každém hodnocení)</p>
      </div>
    </div>
  )
}
```

---

## DA-019 – Admin stats – contributor metriky

```sql
-- Přidat do 005_dashboard_rpc.sql / aktualizovat admin_stats view:

CREATE OR REPLACE VIEW public.admin_stats AS SELECT
  -- stávající metriky (beze změny)
  (SELECT COUNT(*) FROM auth.users WHERE is_anonymous=FALSE)     AS registered_users,
  (SELECT COUNT(*) FROM auth.users WHERE is_anonymous=TRUE)      AS anonymous_users,
  (SELECT COUNT(*) FROM public.pois WHERE is_active=TRUE)        AS active_pois,
  (SELECT COUNT(*) FROM public.cities WHERE is_active=TRUE)      AS active_cities,
  (SELECT COUNT(*) FROM public.user_access)                      AS total_purchases,
  (SELECT COALESCE(SUM(amount_eur),0) FROM public.payment_receipts WHERE status='completed') AS total_revenue_eur,
  (SELECT COUNT(*) FROM public.free_visit_log WHERE year_month=TO_CHAR(NOW(),'YYYY-MM')) AS free_visits_this_month,
  (SELECT COUNT(*) FROM public.payment_receipts WHERE payment_method='revolut' AND status='pending') AS pending_revolut,
  -- NOVÉ contributor metriky
  (SELECT COUNT(*) FROM public.contributor_profiles WHERE is_active=TRUE)   AS total_contributors,
  (SELECT COUNT(*) FROM public.contributor_profiles WHERE is_verified=TRUE) AS verified_contributors,
  (SELECT COUNT(*) FROM public.poi_ratings)                                 AS total_poi_ratings,
  (SELECT ROUND(AVG(rating)::NUMERIC, 2) FROM public.poi_ratings)           AS global_avg_rating;
```

```tsx
// DashboardPage – přidat metriky karty:
// total_contributors | verified_contributors | total_poi_ratings | global_avg_rating
<MetricCard label="Přispěvatelé" value={stats.total_contributors} icon={PenLine} />
<MetricCard label="Ověřeni" value={stats.verified_contributors} icon={BadgeCheck} />
<MetricCard label="Hodnocení POI" value={stats.total_poi_ratings} icon={Star} />
<MetricCard label="Průměr POI" value={stats.global_avg_rating ? `${stats.global_avg_rating}★` : '—'} icon={Trophy} />
```

---

## DA-020 – Registrace přispěvatele

```tsx
// src/pages/register/ContributorRegisterPage.tsx
// Veřejná stránka – bez přihlášení nebo po přihlášení bez role

export function ContributorRegisterPage() {
  const [step, setStep] = useState<'auth' | 'profile'>('auth')
  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')
  const [displayName, setDisplayName] = useState('')
  const [bio, setBio] = useState('')
  const [loading, setLoading] = useState(false)
  const navigate = useNavigate()
  const toast = useToast()

  async function registerAndCreateProfile() {
    setLoading(true)
    // 1. Registrace nebo přihlášení
    let userId: string
    const { data: existingSession } = await supabase.auth.getSession()

    if (existingSession.session) {
      userId = existingSession.session.user.id
    } else {
      const { data, error } = await supabase.auth.signUp({ email, password })
      if (error || !data.user) {
        toast.error('Chyba registrace: ' + error?.message)
        setLoading(false)
        return
      }
      userId = data.user.id
    }

    // 2. Vytvořit contributor_profile
    await supabase.from('contributor_profiles').insert({
      user_id: userId,
      display_name: displayName,
      bio,
      is_verified: false,
    })

    // 3. Přidat do admin_users jako contributor
    await supabase.from('admin_users').upsert({
      user_id: userId,
      role: 'contributor',
    }, { onConflict: 'user_id' })

    toast.success('Profil vytvořen! Čeká na ověření adminem.')
    setLoading(false)
    navigate('/contributor/dashboard')
  }

  return (
    <div className="min-h-screen flex items-center justify-center bg-muted/20 p-4">
      <div className="w-full max-w-md space-y-6">
        {/* Logo */}
        <div className="text-center">
          <div className="w-12 h-12 bg-primary rounded-xl flex items-center justify-center mx-auto mb-3">
            <span className="text-white font-bold text-lg">HD</span>
          </div>
          <h1 className="text-2xl font-bold">Staňte se průvodcem</h1>
          <p className="text-muted-foreground text-sm mt-1">
            Přispějte texty pro turistická místa a získejte uznání
          </p>
        </div>

        {/* Co dostanete */}
        <div className="border rounded-lg p-4 space-y-2 bg-card">
          <h2 className="font-medium text-sm">Co jako průvodce získáte:</h2>
          <ul className="text-sm text-muted-foreground space-y-1">
            <li className="flex items-center gap-2"><span className="text-green-500">✓</span> Vaše jméno u každého průvodce v aplikaci</li>
            <li className="flex items-center gap-2"><span className="text-green-500">✓</span> Hodnocení od tisíců turistů</li>
            <li className="flex items-center gap-2"><span className="text-green-500">✓</span> Místo v Hall of Fame nejlepších průvodců</li>
            <li className="flex items-center gap-2"><span className="text-green-500">✓</span> Přístup k oblasti zdarma (při dosažení prahu hodnocení)</li>
          </ul>
        </div>

        {/* Formulář */}
        <div className="border rounded-lg p-5 space-y-4 bg-card">
          <div>
            <label className="block text-sm font-medium mb-1">Email</label>
            <input value={email} onChange={e => setEmail(e.target.value)} type="email" className="input w-full" placeholder="vas@email.cz" />
          </div>
          <div>
            <label className="block text-sm font-medium mb-1">Heslo</label>
            <input value={password} onChange={e => setPassword(e.target.value)} type="password" className="input w-full" />
          </div>
          <div>
            <label className="block text-sm font-medium mb-1">Zobrazované jméno *</label>
            <input value={displayName} onChange={e => setDisplayName(e.target.value)} className="input w-full" placeholder="Jan Novák" />
          </div>
          <div>
            <label className="block text-sm font-medium mb-1">Bio (volitelné)</label>
            <textarea value={bio} onChange={e => setBio(e.target.value)} className="input w-full h-20 resize-none" placeholder="Místní průvodce, historik..." />
          </div>

          <button
            onClick={registerAndCreateProfile}
            disabled={!email || !password || !displayName || loading}
            className="w-full py-2.5 bg-primary text-white rounded font-medium disabled:opacity-50"
          >
            {loading ? 'Registruji...' : 'Registrovat se jako průvodce'}
          </button>
        </div>

        <p className="text-center text-xs text-muted-foreground">
          Již máte účet?{' '}
          <a href="/login" className="text-primary hover:underline">Přihlaste se</a>
        </p>
      </div>
    </div>
  )
}
```

---

## DA-021 – Edge Function `invite-contributor`

```typescript
// supabase/functions/invite-contributor/index.ts
// Posílá email pozvánku potenciálnímu přispěvateli

import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

serve(async (req) => {
  const { email, personalMessage } = await req.json()

  const supabase = createClient(
    Deno.env.get('SUPABASE_URL')!,
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
  )

  // Odeslat email přes Resend
  const res = await fetch('https://api.resend.com/emails', {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${Deno.env.get('RESEND_API_KEY')}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      from: 'HeroDots <pruvodci@herodots.app>',
      to: email,
      subject: 'Pozvánka: Staňte se průvodcem HeroDots',
      html: `
        <h2>Dobrý den,</h2>
        <p>Zveme vás k přispívání do HeroDots – aplikace pro turistické audioprůvodce.</p>
        ${personalMessage ? `<p><em>${personalMessage}</em></p>` : ''}
        <p>Jako průvodce můžete psát texty pro zajímavá místa, která pak uslyší turisté z celého světa.</p>
        <a href="https://herodots.app/register/contributor"
           style="display:inline-block;background:#2D6A4F;color:white;padding:12px 24px;border-radius:6px;text-decoration:none;margin-top:16px">
          Registrovat se jako průvodce
        </a>
        <p style="margin-top:24px;font-size:12px;color:#666">
          HeroDots · herodots.app
        </p>
      `,
    }),
  })

  return new Response(JSON.stringify({ ok: res.ok }), {
    headers: { 'Content-Type': 'application/json' },
  })
})
```

---

## DA-022 – Aktualizace roadmapy

```
Přidat za krok 4 (Supabase klient):
4a  | DA-005 – dva Supabase klienti (anon + service_role)  | Build projde, oba klienti funkční

Přidat za krok 5 (Routing + AuthGuard):
5a  | DA-007 – useAuth hook (Zustand store)                | Role se načítají po přihlášení
5b  | DA-006 – AuthGuard s requiredRole prop               | Ochrana routes funguje
5c  | DA-008 – RoleGuard inline komponenta                 | Skrývání UI dle role funguje
5d  | DA-009 – tři skupiny routes v App.tsx                | /admin/*, /contributor/* funguje
5e  | DA-010 – Sidebar filtrování dle role                 | Správné položky per role
5f  | DA-011 – ContributorShell layout                     | Contributor portál se zobrazuje
5g  | DA-004 – DB migrace 009_web_roles.sql                | Pohled + RLS pro contributors

Po kroku 18 (PaywallScreen) přidat:
18a | DA-020 – ContributorRegisterPage (/register/contributor)  | Registrace funguje
18b | DA-012 – ContributorDashboard                             | Dashboard průvodce
18c | DA-013 – ContributorPoiListPage (RLS filtr)               | Vidí jen svá POI
18d | DA-014 – ContributorPoiEditorPage (text editor)           | Může editovat text
18e | DA-015 – ContributorProfilePage                           | Editace profilu
18f | DA-016 – Admin ContributorsPage                           | Správa přispěvatelů
18g | DA-017 – Admin ContributorDetailPage                      | Detail + ověření
18h | DA-018 – Admin HallOfFamePage                            | Žebříček v adminu
18i | DA-019 – admin_stats contributor metriky                  | Dashboard čísla
18j | DA-021 – invite-contributor Edge Function                 | Emaily fungují
```

---

## Nové soubory k vytvoření

```
src/hooks/
└── useAuth.ts                              (Zustand store)

src/components/layout/
├── AuthGuard.tsx                           (přepis)
├── ContributorShell.tsx                    (nový)
└── RoleGuard.tsx                           (nový)

src/pages/
├── UnauthorizedPage.tsx                    (jednoduchá 403 stránka)
├── register/
│   └── ContributorRegisterPage.tsx
├── contributor/
│   ├── ContributorDashboard.tsx
│   ├── ContributorPoiListPage.tsx
│   ├── ContributorPoiEditorPage.tsx
│   └── ContributorProfilePage.tsx
├── contributors/
│   ├── ContributorsPage.tsx
│   └── ContributorDetailPage.tsx
└── hall-of-fame/
    └── HallOfFamePage.tsx

supabase/migrations/
└── 009_web_roles.sql

supabase/functions/
└── invite-contributor/index.ts
```

---

*Konec diff-specification-admin-001.md*
*Doporučené pořadí aplikace: DA-004 → DA-005 → DA-007 → DA-006 → DA-008 → DA-009 → zbytek*
