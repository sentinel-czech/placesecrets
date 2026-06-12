# Specifikace webového rozhraní – PlaceSecrets Web
> **Verze:** 3.0 – Komplexní merge (spec-prompts-admin + diff-admin-001 + revize názvů + admin PIN)
> **Název produktu:** PlaceSecrets (pracovní název HeroDots)
> **Web URL:** placesecrets.app (nebo admin.placesecrets.app)
> **Platforma:** Vite + React 18 + TypeScript + Tailwind CSS + shadcn/ui + Supabase
> **Sdílí:** stejnou Supabase DB jako mobilní app
> **Deploy:** Netlify / Vercel (statický build)
> **Backend:** Supabase + Edge Functions

---

## OBSAH

1. [Architektura](#1-architektura)
2. [Layout a design systém](#2-layout-a-design-systém)
3. [Auth flow – dvojité přihlášení pro admin](#3-auth-flow--dvojité-přihlášení-pro-admin)
4. [Instalace projektu](#4-instalace-projektu)
5. [Struktura projektu](#5-struktura-projektu)
6. [Databáze – migrace a SQL](#6-databáze--migrace-a-sql)
7. [Supabase klienti](#7-supabase-klienti)
8. [Auth a role systém](#8-auth-a-role-systém)
9. [Routing – tři skupiny routes](#9-routing--tři-skupiny-routes)
10. [Login a registrace](#10-login-a-registrace)
11. [Admin portál – layout a navigace](#11-admin-portál--layout-a-navigace)
12. [Dashboard](#12-dashboard)
13. [Správa měst a POI](#13-správa-měst-a-poi)
14. [Správa typů POI](#14-správa-typů-poi)
15. [Správa uživatelů](#15-správa-uživatelů)
16. [Správa plateb](#16-správa-plateb)
17. [Správa přispěvatelů](#17-správa-přispěvatelů)
18. [Hall of Fame – admin přehled](#18-hall-of-fame--admin-přehled)
19. [Nastavení](#19-nastavení)
20. [Contributor portál](#20-contributor-portál)
21. [Sdílené komponenty](#21-sdílené-komponenty)
22. [Edge Functions](#22-edge-functions)
23. [Roadmapa implementace](#23-roadmapa-implementace)

---

## 1. Architektura

### 1.1 Přehled

```
┌─────────────────────────────────────────────────────────────┐
│  placesecrets.app  – Vite + React SPA (jeden build)         │
│                                                             │
│  /login              → přihlášení pro všechny role         │
│  /register/*         → registrace přispěvatele             │
│                                                             │
│  /admin/*            → admin panel (superadmin/editor/viewer)│
│  /contributor/*      → portál průvodců (contributor)       │
│  /account/*          → self-service pro běžné uživatele    │
└──────────────┬──────────────────────────────────────────────┘
               │
        ┌──────┴──────┐
        │  Supabase   │
        │  anon key   │  ← contributor portál + account
        │  +          │
        │ service_role│  ← /admin/* routes (obchází RLS)
        └─────────────┘
```

### 1.2 Bezpečnostní model

| Route skupina | Supabase klient | Přístup k DB |
|---|---|---|
| `/admin/*` | `supabaseAdmin` (service_role) | Plný přístup, obchází RLS |
| `/contributor/*` | `supabase` (anon + auth) | RLS – vidí jen svá data |
| `/account/*` | `supabase` (anon + auth) | RLS – jen vlastní záznamy |

### 1.3 Dvojité zabezpečení admin sekce

Admin uživatel prochází **dvěma kroky přihlášení**:

1. **Krok 1 – Email + heslo** (Supabase Auth) – standardní přihlášení  
2. **Krok 2 – Admin PIN** – 6místný PIN uložený v `admin_users.pin_hash`  

Pokud admin PIN nezadá, je přesměrován na `/contributor/*` nebo `/account/*` dle role.  
PIN lze měnit v profilu přihlášeného admina (položka "Změnit admin PIN").

```
Přihlášení flow:
                          ┌──────────────┐
  Uživatel          →     │  /login       │
  zadá email+heslo        │  (krok 1)     │
                          └──────┬───────┘
                                 │ Auth OK
                     ┌───────────┴──────────────┐
                     │ Jaká je role uživatele?   │
                     └───┬───────────┬───────────┘
                         │           │
                   admin role    contributor/user role
                         │           │
              ┌──────────▼──┐   ┌────▼──────────────┐
              │ /admin-pin   │   │ /contributor/dash  │
              │ (krok 2)     │   │ nebo /account      │
              └──────┬──────┘   └───────────────────┘
                     │ PIN OK
              ┌──────▼──────┐
              │ /admin/dash  │
              └─────────────┘
```

### 1.4 Proč Vite (ne Next.js)

- Admin SPA nepotřebuje SSR ani SEO
- Vite je výrazně rychlejší při vývoji (HMR)
- Supabase Edge Functions pokrývají veškerou serverovou logiku
- Jednodušší deploy – `vite build` → statické soubory

---

## 2. Layout a design systém

### 2.1 Barevná paleta (PlaceSecrets brand)

```typescript
// tailwind.config.ts – PlaceSecrets barvy
colors: {
  primary:   { DEFAULT: '#2D6A4F', foreground: '#ffffff' },  // tmavě zelená
  gold:      '#B8960C',                                       // zlatá – akcent
  dark:      '#1A1A2E',                                       // tmavá modrá
  brand: {
    50:  '#f0fdf4',
    100: '#dcfce7',
    500: '#2D6A4F',
    600: '#1e4d38',
    700: '#155330',
  }
}
```

### 2.2 Layout – admin portál

```
┌─────────────────────────────────────────────────────────────────┐
│  HEADER (60px výška)                                            │
│  [≡ Logo PlaceSecrets]    [Breadcrumb]    [Search]  [User menu] │
├────────────┬────────────────────────────────────────────────────┤
│            │                                                    │
│  SIDEBAR   │   MAIN CONTENT AREA                               │
│  (220px)   │                                                    │
│            │   ┌──────────────────────────────────────────┐   │
│  Nav items │   │  Page header (title + actions)           │   │
│  per role  │   ├──────────────────────────────────────────┤   │
│            │   │                                          │   │
│  ─────────│   │  Content (cards, tables, forms)         │   │
│            │   │                                          │   │
│  Role badge│   │                                          │   │
│  User menu │   └──────────────────────────────────────────┘   │
│  Sign out  │                                                    │
└────────────┴────────────────────────────────────────────────────┘
```

### 2.3 Layout – contributor portál

```
┌─────────────────────────────────────────────────────────────────┐
│  HEADER (50px výška)                                            │
│  [Logo PlaceSecrets · Průvodci]         [Jméno] [Sign out]      │
├────────────┬────────────────────────────────────────────────────┤
│            │                                                    │
│  SIDEBAR   │   MAIN CONTENT AREA                               │
│  (200px)   │   max-width: 800px, centered                      │
│            │                                                    │
│  3 položky │                                                    │
│  ─────────│                                                    │
│  verified/ │                                                    │
│  pending   │                                                    │
│  badge     │                                                    │
└────────────┴────────────────────────────────────────────────────┘
```

### 2.4 Layout – Login / Register (veřejné stránky)

```
┌─────────────────────────────────────────────────────────────────┐
│                     PlaceSecrets                                │
│                       (logo + tagline)                          │
│                                                                 │
│              ┌─────────────────────────┐                       │
│              │   LOGIN / REGISTER CARD │                       │
│              │   (max-width: 400px)    │                       │
│              │                         │                       │
│              │   [form fields]         │                       │
│              └─────────────────────────┘                       │
└─────────────────────────────────────────────────────────────────┘
```

### 2.5 Typografická hierarchie

```
H1 – page title:    font-bold text-xl (nebo text-2xl)
H2 – section title: font-semibold text-base
H3 – card title:    font-medium text-sm
body:               text-sm
caption:            text-xs text-muted-foreground
```

---

## 3. Auth flow – dvojité přihlášení pro admin

### 3.1 DB – rozšíření admin_users o PIN

```sql
-- supabase/migrations/004_admin_users.sql (aktualizace)

CREATE TABLE public.admin_users (
  id         UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id    UUID NOT NULL UNIQUE REFERENCES auth.users(id) ON DELETE CASCADE,
  role       TEXT NOT NULL DEFAULT 'editor'
    CHECK (role IN ('superadmin', 'editor', 'viewer', 'contributor')),
  pin_hash   TEXT,           -- bcrypt hash 6místného PIN (NULL = PIN nezad)
  pin_set_at TIMESTAMPTZ,    -- kdy byl PIN naposledy změněn
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE public.admin_users ENABLE ROW LEVEL SECURITY;
CREATE POLICY "admin_service_only" ON public.admin_users
  USING (auth.role() = 'service_role');
```

### 3.2 Edge Function – ověření PIN

```typescript
// supabase/functions/verify-admin-pin/index.ts
// Bezpečně ověří PIN na serveru (bcrypt) – PIN se nikdy neodesílá v plain textu

import { serve } from 'https://deno.land/std@0.177.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
import * as bcrypt from 'https://deno.land/x/bcrypt@v0.4.1/mod.ts'

serve(async (req) => {
  const authHeader = req.headers.get('Authorization')
  if (!authHeader) return new Response('Unauthorized', { status: 401 })

  const supabase = createClient(
    Deno.env.get('SUPABASE_URL')!,
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
  )

  // Ověřit JWT token
  const { data: { user }, error: authError } = await supabase.auth.getUser(
    authHeader.replace('Bearer ', '')
  )
  if (authError || !user) return new Response('Unauthorized', { status: 401 })

  const { pin } = await req.json()
  if (!pin || pin.length !== 6 || !/^\d{6}$/.test(pin)) {
    return new Response(JSON.stringify({ success: false, error: 'Neplatný formát PIN' }), { status: 400 })
  }

  // Načíst hash z DB
  const { data: adminUser } = await supabase
    .from('admin_users')
    .select('pin_hash, role')
    .eq('user_id', user.id)
    .single()

  if (!adminUser) return new Response(JSON.stringify({ success: false }), { status: 403 })

  // Pokud PIN není nastaven, první zadání ho nastaví
  if (!adminUser.pin_hash) {
    const hash = await bcrypt.hash(pin)
    await supabase.from('admin_users').update({ pin_hash: hash, pin_set_at: new Date().toISOString() }).eq('user_id', user.id)
    return new Response(JSON.stringify({ success: true, first_time: true }))
  }

  // Ověřit PIN
  const valid = await bcrypt.compare(pin, adminUser.pin_hash)
  if (!valid) {
    return new Response(JSON.stringify({ success: false, error: 'Nesprávný PIN' }), { status: 401 })
  }

  return new Response(JSON.stringify({ success: true, role: adminUser.role }))
})
```

### 3.3 Edge Function – změna PIN

```typescript
// supabase/functions/change-admin-pin/index.ts

serve(async (req) => {
  const authHeader = req.headers.get('Authorization')
  const supabase = createClient(
    Deno.env.get('SUPABASE_URL')!,
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
  )

  const { data: { user } } = await supabase.auth.getUser(authHeader?.replace('Bearer ', '') ?? '')
  if (!user) return new Response('Unauthorized', { status: 401 })

  const { current_pin, new_pin } = await req.json()
  if (!new_pin || !/^\d{6}$/.test(new_pin)) {
    return new Response(JSON.stringify({ error: 'PIN musí být 6 číslic' }), { status: 400 })
  }

  const { data: adminUser } = await supabase
    .from('admin_users').select('pin_hash').eq('user_id', user.id).single()

  // Pokud má existující PIN, ověřit ho
  if (adminUser?.pin_hash && current_pin) {
    const valid = await bcrypt.compare(current_pin, adminUser.pin_hash)
    if (!valid) return new Response(JSON.stringify({ error: 'Stávající PIN je nesprávný' }), { status: 401 })
  }

  const newHash = await bcrypt.hash(new_pin)
  await supabase.from('admin_users').update({ pin_hash: newHash, pin_set_at: new Date().toISOString() }).eq('user_id', user.id)

  return new Response(JSON.stringify({ success: true }))
})
```

### 3.4 AdminPinPage – krok 2 přihlášení

```tsx
// src/pages/AdminPinPage.tsx
// Zobrazí se po úspěšném přihlášení pro uživatele s admin rolí
// Admin zadá 6místný PIN pro přístup do /admin/* sekce

import { useState, useRef, useEffect } from 'react'
import { useNavigate } from 'react-router-dom'
import { supabase } from '@/lib/supabase/client'
import { useAuthStore } from '@/hooks/useAuth'
import { ShieldCheck } from 'lucide-react'

export function AdminPinPage() {
  const [pins, setPins] = useState(['', '', '', '', '', ''])
  const [error, setError] = useState('')
  const [loading, setLoading] = useState(false)
  const [isFirstTime, setIsFirstTime] = useState(false)
  const refs = Array.from({ length: 6 }, () => useRef<HTMLInputElement>(null))
  const navigate = useNavigate()
  const { setAdminVerified } = useAuthStore()

  function handleChange(idx: number, value: string) {
    if (!/^\d?$/.test(value)) return
    const next = [...pins]
    next[idx] = value
    setPins(next)
    if (value && idx < 5) refs[idx + 1].current?.focus()
    if (next.every(p => p !== '')) submitPin(next.join(''))
  }

  function handleKeyDown(idx: number, e: React.KeyboardEvent) {
    if (e.key === 'Backspace' && !pins[idx] && idx > 0) {
      refs[idx - 1].current?.focus()
    }
  }

  async function submitPin(pin: string) {
    setLoading(true)
    setError('')
    const session = (await supabase.auth.getSession()).data.session
    const res = await supabase.functions.invoke('verify-admin-pin', {
      headers: { Authorization: `Bearer ${session?.access_token}` },
      body: JSON.stringify({ pin }),
    })

    const data = res.data as any

    if (!data?.success) {
      setError(data?.error ?? 'Nesprávný PIN')
      setPins(['', '', '', '', '', ''])
      refs[0].current?.focus()
      setLoading(false)
      return
    }

    if (data.first_time) setIsFirstTime(true)
    setAdminVerified(true)
    navigate('/admin/dashboard')
  }

  return (
    <div className="min-h-screen bg-muted/20 flex flex-col items-center justify-center p-4">
      <div className="w-full max-w-sm">
        {/* Logo */}
        <div className="text-center mb-8">
          <div className="w-14 h-14 bg-primary rounded-2xl flex items-center justify-center mx-auto mb-3 shadow-md">
            <ShieldCheck className="w-7 h-7 text-white" />
          </div>
          <h1 className="text-2xl font-bold">Admin ověření</h1>
          <p className="text-muted-foreground text-sm mt-1">
            Zadejte váš 6místný admin PIN
          </p>
        </div>

        {/* PIN vstup */}
        <div className="bg-card border rounded-xl p-6 shadow-sm">
          <div className="flex justify-center gap-3 mb-6">
            {pins.map((digit, idx) => (
              <input
                key={idx}
                ref={refs[idx]}
                type="text"
                inputMode="numeric"
                maxLength={1}
                value={digit}
                onChange={e => handleChange(idx, e.target.value)}
                onKeyDown={e => handleKeyDown(idx, e)}
                className={`
                  w-11 h-14 text-center text-2xl font-bold border-2 rounded-lg
                  focus:outline-none focus:border-primary transition-colors
                  ${digit ? 'border-primary bg-primary/5' : 'border-muted-foreground/30'}
                  ${error ? 'border-red-400 bg-red-50' : ''}
                `}
                autoFocus={idx === 0}
              />
            ))}
          </div>

          {error && (
            <p className="text-red-500 text-sm text-center mb-4">{error}</p>
          )}

          {isFirstTime && (
            <div className="bg-green-50 border border-green-200 rounded-lg p-3 text-sm text-green-700 text-center mb-4">
              ✓ Nový PIN byl nastaven. Zapamatujte si ho!
            </div>
          )}

          {loading && (
            <div className="flex justify-center">
              <div className="animate-spin w-5 h-5 border-2 border-primary border-t-transparent rounded-full" />
            </div>
          )}

          <p className="text-xs text-muted-foreground text-center mt-2">
            {!loading && 'PIN se odesílá automaticky po zadání 6. číslice'}
          </p>
        </div>

        {/* První přihlášení – instrukce */}
        <div className="mt-4 p-3 bg-blue-50 border border-blue-200 rounded-lg text-xs text-blue-700">
          <strong>První přihlášení?</strong> Zadejte libovolný 6místný PIN.
          Bude uložen jako váš admin PIN pro příští přihlášení.
        </div>

        {/* Link na profil – změna PIN */}
        <p className="text-center text-xs text-muted-foreground mt-4">
          PIN lze změnit v nastavení účtu po přihlášení
        </p>

        {/* Odhlásit se */}
        <button
          onClick={() => { supabase.auth.signOut(); navigate('/login') }}
          className="w-full mt-3 text-sm text-muted-foreground hover:text-foreground py-2"
        >
          ← Zpět na přihlášení
        </button>
      </div>
    </div>
  )
}
```

### 3.5 Session management – admin PIN v paměti

```typescript
// src/hooks/useAuth.ts – rozšíření o adminVerified flag

interface AuthState {
  // ... existující
  adminVerified: boolean      // true = zadal správný PIN v této session
  setAdminVerified: (val: boolean) => void
}

// AdminGuard – ochrana /admin/* routes
// Vyžaduje: přihlášení + admin role + adminVerified = true

export function AdminGuard() {
  const { user, role, adminVerified, loading } = useAuthStore()
  const location = useLocation()

  if (loading) return <FullscreenSpinner />
  if (!user) return <Navigate to="/login" state={{ from: location }} replace />
  if (!['superadmin', 'editor', 'viewer'].includes(role ?? '')) {
    return <Navigate to="/unauthorized" replace />
  }
  if (!adminVerified) return <Navigate to="/admin-pin" replace />
  return <Outlet />
}
```

---

## 4. Instalace projektu

```bash
# 1. Vytvořit Vite projekt
npm create vite@latest placesecrets-web -- --template react-ts
cd placesecrets-web

# 2. Tailwind CSS
npm install -D tailwindcss postcss autoprefixer
npx tailwindcss init -p

# 3. Závislosti
npm install \
  @supabase/supabase-js \
  react-router-dom \
  @tanstack/react-table \
  recharts \
  react-hook-form \
  zod \
  @hookform/resolvers \
  zustand \
  date-fns \
  lucide-react \
  react-leaflet leaflet \
  @types/leaflet \
  react-dropzone \
  clsx \
  tailwind-merge

# 4. shadcn/ui
npm install -D @types/node
npx shadcn-ui@latest init
# → style: default, base color: zinc, CSS variables: yes, path alias: @

npx shadcn-ui@latest add button card input label select table badge \
  dialog sheet tabs form toast dropdown-menu avatar separator \
  skeleton alert-dialog progress

# 5. Supabase typy
npx supabase gen types typescript \
  --project-id YOUR_PROJECT_ID --schema public \
  > src/lib/supabase/types.ts
```

### 4.1 `tailwind.config.ts`

```typescript
import type { Config } from 'tailwindcss'

export default {
  darkMode: ['class'],
  content: ['./index.html', './src/**/*.{ts,tsx}'],
  theme: {
    extend: {
      colors: {
        primary:  { DEFAULT: '#2D6A4F', foreground: '#ffffff' },
        gold:     '#B8960C',
        dark:     '#1A1A2E',
      },
    },
  },
  plugins: [],
} satisfies Config
```

### 4.2 Proměnné prostředí

```bash
# .env.local
VITE_SUPABASE_URL=https://YOUR_PROJECT.supabase.co
VITE_SUPABASE_SERVICE_ROLE_KEY=eyJ...   # POUZE admin panel, NIKDY do mobilní app
VITE_SUPABASE_ANON_KEY=eyJ...           # contributor + user portál
VITE_APP_URL=https://placesecrets.app
```

---

## 5. Struktura projektu

```
placesecrets-web/
├── index.html
├── vite.config.ts
├── tailwind.config.ts
├── .env.local
├── src/
│   ├── main.tsx
│   ├── App.tsx                         ← kompletní routing
│   ├── lib/
│   │   ├── supabase/
│   │   │   ├── client.ts               ← dva klienti (admin + anon)
│   │   │   └── types.ts
│   │   ├── poi-type-icons.ts
│   │   └── utils.ts
│   ├── hooks/
│   │   ├── useAuth.ts                  ← Zustand store (role + adminVerified)
│   │   └── useToast.ts
│   ├── components/
│   │   ├── layout/
│   │   │   ├── AppShell.tsx            ← Admin shell (Sidebar + Header)
│   │   │   ├── Sidebar.tsx             ← dynamická nav dle role
│   │   │   ├── Header.tsx
│   │   │   ├── AdminGuard.tsx          ← vyžaduje email+PIN auth
│   │   │   ├── AuthGuard.tsx           ← vyžaduje email auth + roli
│   │   │   ├── ContributorShell.tsx    ← jednodušší shell pro průvodce
│   │   │   └── RoleGuard.tsx           ← inline ochrana sekcí
│   │   ├── shared/
│   │   │   ├── DataTable.tsx
│   │   │   ├── StatusBadge.tsx
│   │   │   ├── ActiveBadge.tsx
│   │   │   ├── ConfirmDialog.tsx
│   │   │   ├── MapPicker.tsx           ← lazy Leaflet
│   │   │   ├── Section.tsx
│   │   │   └── ToastProvider.tsx
│   │   ├── dashboard/
│   │   │   ├── MetricCard.tsx
│   │   │   ├── RevenueChart.tsx
│   │   │   └── ActivityChart.tsx
│   │   ├── cities/
│   │   │   └── CityForm.tsx
│   │   ├── pois/
│   │   │   ├── PoiForm.tsx
│   │   │   ├── AudioUploader.tsx
│   │   │   └── PhotoUploader.tsx
│   │   ├── poi-types/
│   │   │   └── PoiTypeModal.tsx
│   │   ├── users/
│   │   │   └── AccessGrantModal.tsx
│   │   ├── payments/
│   │   │   └── ReceiptActions.tsx
│   │   └── settings/
│   │       ├── AdminUsersTable.tsx
│   │       ├── InviteAdminForm.tsx
│   │       └── ChangePinForm.tsx       ← NOVÉ – změna admin PIN
│   └── pages/
│       ├── LoginPage.tsx
│       ├── AdminPinPage.tsx            ← NOVÉ – krok 2 přihlášení
│       ├── UnauthorizedPage.tsx
│       ├── DashboardPage.tsx
│       ├── SettingsPage.tsx
│       ├── cities/
│       │   ├── CitiesPage.tsx
│       │   ├── CityNewPage.tsx
│       │   └── CityEditPage.tsx
│       ├── pois/
│       │   ├── PoisPage.tsx
│       │   ├── PoiNewPage.tsx
│       │   └── PoiEditPage.tsx
│       ├── poi-types/
│       │   └── PoiTypesPage.tsx
│       ├── users/
│       │   ├── UsersPage.tsx
│       │   └── UserDetailPage.tsx
│       ├── payments/
│       │   ├── PaymentsPage.tsx
│       │   └── PaymentDetailPage.tsx
│       ├── contributors/              ← Admin správa přispěvatelů
│       │   ├── ContributorsPage.tsx
│       │   └── ContributorDetailPage.tsx
│       ├── hall-of-fame/
│       │   └── HallOfFamePage.tsx
│       ├── register/
│       │   └── ContributorRegisterPage.tsx
│       └── contributor/               ← Contributor portál
│           ├── ContributorDashboard.tsx
│           ├── ContributorPoiListPage.tsx
│           ├── ContributorPoiEditorPage.tsx
│           └── ContributorProfilePage.tsx
```

---

## 6. Databáze – migrace a SQL

### 6.1 Přehled migrací

```
supabase/migrations/
├── 001_base_schema.sql           ← základní schéma (z mobilní app spec)
├── 002_user_access.sql           ← user_access, free_visit_log
├── 003_payment_receipts.sql      ← payment_receipts + receipt_number trigger
├── 004_admin_users.sql           ← admin_users s pin_hash
├── 005_dashboard_rpc.sql         ← RPC funkce + admin_stats view
├── 006_poi_types.sql             ← poi_types tabulka + seed
├── 007_poi_types_rpc.sql         ← poi_types_stats funkce
├── 008_contributor_profiles.sql  ← contributor_profiles + poi_ratings
└── 009_web_roles.sql             ← web_user_roles view + RLS contributor
```

### 6.2 Migrace 003 – payment_receipts

```sql
-- supabase/migrations/003_payment_receipts.sql

CREATE SEQUENCE public.receipt_number_seq START 1;

CREATE TABLE public.payment_receipts (
  id               UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id          UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  city_id          UUID NOT NULL REFERENCES public.cities(id),
  purchased_at     TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  payment_method   TEXT NOT NULL
    CHECK (payment_method IN ('google_pay','apple_pay','revolut','stripe','admin_grant')),
  transaction_id   TEXT,
  amount_eur       DECIMAL(10,2) NOT NULL,
  currency         TEXT NOT NULL DEFAULT 'EUR',
  status           TEXT NOT NULL DEFAULT 'completed'
    CHECK (status IN ('pending','completed','refunded','disputed')),
  revolut_note     TEXT,
  confirmed_by     UUID REFERENCES auth.users(id),
  confirmed_at     TIMESTAMPTZ,
  receipt_number   TEXT UNIQUE,
  receipt_pdf_url  TEXT,
  receipt_sent_at  TIMESTAMPTZ,
  created_at       TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE OR REPLACE FUNCTION public.generate_receipt_number()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
  IF NEW.receipt_number IS NULL THEN
    NEW.receipt_number := 'PS-' || TO_CHAR(NOW(), 'YYYY') || '-'
      || LPAD(nextval('public.receipt_number_seq')::TEXT, 4, '0');
  END IF;
  RETURN NEW;
END;
$$;
-- PS- prefix = PlaceSecrets (místo HD-)

CREATE TRIGGER set_receipt_number
  BEFORE INSERT ON public.payment_receipts
  FOR EACH ROW EXECUTE FUNCTION public.generate_receipt_number();

ALTER TABLE public.payment_receipts ENABLE ROW LEVEL SECURITY;
CREATE POLICY "receipts_own_read" ON public.payment_receipts
  FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "receipts_service_all" ON public.payment_receipts
  FOR ALL USING (auth.role() = 'service_role');

CREATE INDEX idx_receipts_user ON public.payment_receipts(user_id, purchased_at DESC);
CREATE INDEX idx_receipts_status ON public.payment_receipts(status);
CREATE INDEX idx_receipts_method ON public.payment_receipts(payment_method);
```

### 6.3 Migrace 004 – admin_users s PIN

```sql
-- supabase/migrations/004_admin_users.sql

CREATE TABLE public.admin_users (
  id         UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id    UUID NOT NULL UNIQUE REFERENCES auth.users(id) ON DELETE CASCADE,
  role       TEXT NOT NULL DEFAULT 'editor'
    CHECK (role IN ('superadmin', 'editor', 'viewer', 'contributor')),
  pin_hash   TEXT,
  pin_set_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE public.admin_users ENABLE ROW LEVEL SECURITY;
CREATE POLICY "admin_service_only" ON public.admin_users
  USING (auth.role() = 'service_role');

-- Prvního superadmina přidat manuálně po nasazení:
-- INSERT INTO public.admin_users (user_id, role)
--   VALUES ('uuid-z-auth.users', 'superadmin');
-- Pak se přihlásit a nastavit PIN (první přihlášení ho vytvoří)
```

### 6.4 Migrace 005 – Dashboard RPC

```sql
-- supabase/migrations/005_dashboard_rpc.sql

-- Revenue po měsících
CREATE OR REPLACE FUNCTION public.revenue_by_month(months_back INTEGER DEFAULT 12)
RETURNS TABLE(month TEXT, revenue DECIMAL, count BIGINT)
LANGUAGE sql SECURITY DEFINER AS $$
  SELECT TO_CHAR(purchased_at, 'YYYY-MM') AS month,
    COALESCE(SUM(amount_eur), 0) AS revenue, COUNT(*) AS count
  FROM public.payment_receipts
  WHERE status = 'completed'
    AND purchased_at >= NOW() - (months_back || ' months')::INTERVAL
  GROUP BY 1 ORDER BY 1;
$$;

-- Admin stats view (včetně contributor metrik)
CREATE OR REPLACE VIEW public.admin_stats AS SELECT
  (SELECT COUNT(*) FROM auth.users WHERE is_anonymous=FALSE)     AS registered_users,
  (SELECT COUNT(*) FROM auth.users WHERE is_anonymous=TRUE)      AS anonymous_users,
  (SELECT COUNT(*) FROM public.pois WHERE is_active=TRUE)        AS active_pois,
  (SELECT COUNT(*) FROM public.cities WHERE is_active=TRUE)      AS active_cities,
  (SELECT COUNT(*) FROM public.user_access)                      AS total_purchases,
  (SELECT COALESCE(SUM(amount_eur),0) FROM public.payment_receipts WHERE status='completed') AS total_revenue_eur,
  (SELECT COUNT(*) FROM public.free_visit_log WHERE year_month=TO_CHAR(NOW(),'YYYY-MM')) AS free_visits_this_month,
  (SELECT COUNT(*) FROM public.payment_receipts WHERE payment_method='revolut' AND status='pending') AS pending_revolut,
  (SELECT COUNT(*) FROM public.contributor_profiles WHERE is_active=TRUE)   AS total_contributors,
  (SELECT COUNT(*) FROM public.contributor_profiles WHERE is_verified=TRUE) AS verified_contributors,
  (SELECT COUNT(*) FROM public.poi_ratings)                                 AS total_poi_ratings,
  (SELECT ROUND(AVG(rating)::NUMERIC,2) FROM public.poi_ratings)            AS global_avg_rating;

-- Admin users view
CREATE OR REPLACE VIEW public.admin_users_view AS
SELECT u.id, u.email, u.is_anonymous, u.created_at, u.last_sign_in_at,
  u.email_confirmed_at,
  COUNT(DISTINCT ua.id) AS access_count,
  COALESCE(SUM(pr.amount_eur) FILTER (WHERE pr.status='completed'), 0) AS total_spent
FROM auth.users u
LEFT JOIN public.user_access ua ON ua.user_id=u.id
LEFT JOIN public.payment_receipts pr ON pr.user_id=u.id
GROUP BY u.id, u.email, u.is_anonymous, u.created_at,
         u.last_sign_in_at, u.email_confirmed_at;

-- payment_summary RPC
CREATE OR REPLACE FUNCTION public.payment_summary(
  p_status TEXT DEFAULT NULL, p_method TEXT DEFAULT NULL,
  p_from TEXT DEFAULT NULL, p_to TEXT DEFAULT NULL
)
RETURNS TABLE(total_eur DECIMAL, count BIGINT, pending_revolut BIGINT)
LANGUAGE sql SECURITY DEFINER AS $$
  SELECT COALESCE(SUM(amount_eur),0), COUNT(*),
    COUNT(*) FILTER (WHERE payment_method='revolut' AND status='pending')
  FROM public.payment_receipts
  WHERE (p_status IS NULL OR status=p_status)
    AND (p_method IS NULL OR payment_method=p_method)
    AND (p_from IS NULL OR purchased_at >= p_from::TIMESTAMPTZ)
    AND (p_to IS NULL OR purchased_at <= (p_to||'T23:59:59Z')::TIMESTAMPTZ);
$$;

-- poi_types_stats RPC
CREATE OR REPLACE FUNCTION public.poi_types_stats()
RETURNS TABLE(type_name TEXT, icon_name TEXT, color_hex TEXT, poi_count BIGINT)
LANGUAGE sql SECURITY DEFINER AS $$
  SELECT t.name->>'cs', t.icon_name, t.color_hex, COUNT(p.id)
  FROM public.poi_types t
  LEFT JOIN public.pois p ON p.type_id = t.id AND p.is_active = TRUE
  WHERE t.is_active = TRUE
  GROUP BY t.id, t.name, t.icon_name, t.color_hex
  ORDER BY t.sort_order;
$$;

GRANT EXECUTE ON FUNCTION public.revenue_by_month TO service_role;
GRANT EXECUTE ON FUNCTION public.payment_summary TO service_role;
GRANT EXECUTE ON FUNCTION public.poi_types_stats TO service_role;
GRANT SELECT ON public.admin_stats TO service_role;
GRANT SELECT ON public.admin_users_view TO service_role;
```

### 6.5 Migrace 006 – POI typy

```sql
-- supabase/migrations/006_poi_types.sql

CREATE TABLE public.poi_types (
  id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name        JSONB NOT NULL,       -- { "cs": "Stavba", "en": "Building", "de": "Gebäude" }
  slug        TEXT UNIQUE NOT NULL,
  icon_name   TEXT NOT NULL DEFAULT 'place',
  color_hex   TEXT NOT NULL DEFAULT '#2D6A4F',
  sort_order  INTEGER NOT NULL DEFAULT 0,
  is_active   BOOLEAN NOT NULL DEFAULT TRUE,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE public.pois ADD COLUMN type_id UUID REFERENCES public.poi_types(id);
CREATE INDEX idx_pois_type ON public.pois(type_id);

ALTER TABLE public.poi_types ENABLE ROW LEVEL SECURITY;
CREATE POLICY "poi_types_public_read" ON public.poi_types
  FOR SELECT USING (is_active = TRUE);
CREATE POLICY "poi_types_service_write" ON public.poi_types
  FOR ALL USING (auth.role() = 'service_role');

-- Seed dat – 12 výchozích typů
INSERT INTO public.poi_types (name, slug, icon_name, color_hex, sort_order) VALUES
  ('{"cs":"Stavba","en":"Building","de":"Gebäude"}',          'building',     'apartment',       '#5C6BC0', 10),
  ('{"cs":"Socha / Pomník","en":"Statue","de":"Statue"}',     'statue',       'emoji_people',    '#8D6E63', 20),
  ('{"cs":"Hrad / Zámek","en":"Castle","de":"Schloss"}',      'castle',       'castle',          '#7B1FA2', 30),
  ('{"cs":"Kostel / Kaple","en":"Church","de":"Kirche"}',     'church',       'church',          '#546E7A', 40),
  ('{"cs":"Muzeum","en":"Museum","de":"Museum"}',             'museum',       'museum',          '#0277BD', 50),
  ('{"cs":"Příroda / Park","en":"Nature","de":"Natur"}',      'nature',       'park',            '#388E3C', 60),
  ('{"cs":"Výhled","en":"Viewpoint","de":"Aussichtspunkt"}',  'viewpoint',    'landscape',       '#00796B', 70),
  ('{"cs":"Restaurace","en":"Restaurant","de":"Restaurant"}', 'restaurant',   'restaurant',      '#E53935', 80),
  ('{"cs":"Kavárna","en":"Café","de":"Café"}',                'cafe',         'local_cafe',      '#6D4C41', 90),
  ('{"cs":"Bar / Hospoda","en":"Bar","de":"Bar"}',            'bar',          'local_bar',       '#F57F17', 100),
  ('{"cs":"Obchod","en":"Shop","de":"Geschäft"}',             'shop',         'shopping_bag',    '#558B2F', 110),
  ('{"cs":"Divadlo / Kultura","en":"Theatre","de":"Theater"}','theatre',      'theater_comedy',  '#AD1457', 120);
```

### 6.6 Migrace 008 – Contributor profiles + hodnocení

```sql
-- supabase/migrations/008_contributor_profiles.sql

CREATE TABLE public.contributor_profiles (
  id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id         UUID NOT NULL UNIQUE REFERENCES auth.users(id) ON DELETE CASCADE,
  display_name    TEXT NOT NULL,
  bio             TEXT,
  website_url     TEXT,
  avatar_url      TEXT,
  specializations TEXT[],
  is_verified     BOOLEAN NOT NULL DEFAULT FALSE,
  is_active       BOOLEAN NOT NULL DEFAULT TRUE,
  -- denormalizované statistiky (aktualizovány triggery)
  total_pois      INTEGER NOT NULL DEFAULT 0,
  avg_rating      DECIMAL(3,2),
  total_ratings   INTEGER NOT NULL DEFAULT 0,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Přidat contributor_id do pois (pokud ještě není)
ALTER TABLE public.pois
  ADD COLUMN IF NOT EXISTS contributor_id UUID REFERENCES auth.users(id),
  ADD COLUMN IF NOT EXISTS avg_rating DECIMAL(3,2),
  ADD COLUMN IF NOT EXISTS total_ratings INTEGER NOT NULL DEFAULT 0;

-- Hodnocení POI
CREATE TYPE public.rating_reason AS ENUM (
  'inaccurate', 'boring', 'too_long', 'too_short', 'wrong_location', 'other'
);

CREATE TABLE public.poi_ratings (
  id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  poi_id      UUID NOT NULL REFERENCES public.pois(id) ON DELETE CASCADE,
  user_id     UUID REFERENCES auth.users(id),
  device_id   TEXT,
  rating      SMALLINT NOT NULL CHECK (rating BETWEEN 1 AND 5),
  reason      public.rating_reason,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (poi_id, user_id),
  UNIQUE (poi_id, device_id)
);

ALTER TABLE public.poi_ratings ENABLE ROW LEVEL SECURITY;
CREATE POLICY "ratings_anon_insert" ON public.poi_ratings FOR INSERT WITH CHECK (TRUE);
CREATE POLICY "ratings_own_select" ON public.poi_ratings FOR SELECT USING (
  user_id = auth.uid() OR auth.role() = 'service_role'
);

-- Hall of Fame view
CREATE OR REPLACE VIEW public.contributor_rankings AS
WITH city_stats AS (
  SELECT
    p.contributor_id,
    p.city_id,
    COUNT(*) AS city_poi_count,
    AVG(p.avg_rating) AS city_avg_rating,
    SUM(p.total_ratings) AS city_total_ratings
  FROM public.pois p
  WHERE p.contributor_id IS NOT NULL AND p.is_active = TRUE
  GROUP BY p.contributor_id, p.city_id
  HAVING SUM(p.total_ratings) >= 10
)
SELECT
  cs.contributor_id,
  cs.city_id,
  cp.display_name,
  cp.is_verified,
  cs.city_poi_count,
  ROUND(cs.city_avg_rating::NUMERIC, 2) AS city_avg_rating,
  cs.city_total_ratings,
  ROUND(
    cs.city_avg_rating * LOG(cs.city_total_ratings + 1)::NUMERIC, 3
  ) AS hof_score,
  RANK() OVER (PARTITION BY cs.city_id ORDER BY cs.city_avg_rating * LOG(cs.city_total_ratings + 1) DESC) AS rank
FROM city_stats cs
JOIN public.contributor_profiles cp ON cp.user_id = cs.contributor_id;

-- HoF RPC
CREATE OR REPLACE FUNCTION public.poi_hall_of_fame(
  p_city_id UUID, p_limit INTEGER DEFAULT 10
)
RETURNS TABLE(
  contributor_id UUID, display_name TEXT, is_verified BOOLEAN,
  city_poi_count BIGINT, city_avg_rating DECIMAL,
  city_total_ratings BIGINT, hof_score DECIMAL, rank BIGINT
)
LANGUAGE sql SECURITY DEFINER AS $$
  SELECT contributor_id, display_name, is_verified,
    city_poi_count, city_avg_rating, city_total_ratings, hof_score, rank
  FROM public.contributor_rankings
  WHERE city_id = p_city_id
  ORDER BY rank
  LIMIT p_limit;
$$;

GRANT SELECT ON public.contributor_rankings TO service_role;
GRANT EXECUTE ON FUNCTION public.poi_hall_of_fame TO service_role;
```

### 6.7 Migrace 009 – Web role systém

```sql
-- supabase/migrations/009_web_roles.sql

-- 1. Rozšíření role v admin_users o contributor
ALTER TABLE public.admin_users
  DROP CONSTRAINT IF EXISTS admin_users_role_check;
ALTER TABLE public.admin_users
  ADD CONSTRAINT admin_users_role_check
  CHECK (role IN ('superadmin', 'editor', 'viewer', 'contributor'));

-- 2. Unified role lookup pohled
CREATE OR REPLACE VIEW public.web_user_roles AS
SELECT
  u.id                    AS user_id,
  u.email,
  au.role                 AS admin_role,
  cp.id                   AS contributor_id,
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

ALTER VIEW public.web_user_roles OWNER TO postgres;
GRANT SELECT ON public.web_user_roles TO authenticated;

-- 3. RLS pro contributor přístup k pois
CREATE POLICY "pois_contributor_write" ON public.pois
  FOR UPDATE USING (
    contributor_id = auth.uid()
    OR auth.role() = 'service_role'
  );

CREATE POLICY "pois_contributor_insert" ON public.pois
  FOR INSERT WITH CHECK (
    contributor_id = auth.uid()
    AND EXISTS (
      SELECT 1 FROM public.contributor_profiles
      WHERE user_id = auth.uid() AND is_active = TRUE
    )
  );
```

---

## 7. Supabase klienti

```typescript
// src/lib/supabase/client.ts

import { createClient } from '@supabase/supabase-js'
import type { Database } from './types'

// ──────────────────────────────────────────────
// SERVICE ROLE klient – POUZE pro /admin/* routes
// Obchází RLS – plný přístup k databázi
// NIKDY nepoužívat ve veřejné části ani contributor portálu
// ──────────────────────────────────────────────
export const supabaseAdmin = createClient<Database>(
  import.meta.env.VITE_SUPABASE_URL,
  import.meta.env.VITE_SUPABASE_SERVICE_ROLE_KEY,
  {
    auth: { persistSession: false },  // admin nemá vlastní session stav
    db: { schema: 'public' },
  }
)

// ──────────────────────────────────────────────
// ANON klient – pro contributor + user portál
// Respektuje RLS – uživatel vidí jen svá data
// Také pro auth operations (signIn, signUp)
// ──────────────────────────────────────────────
export const supabase = createClient<Database>(
  import.meta.env.VITE_SUPABASE_URL,
  import.meta.env.VITE_SUPABASE_ANON_KEY,
  {
    auth: { persistSession: true, autoRefreshToken: true },
    db: { schema: 'public' },
  }
)

// Alias pro zpětnou kompatibilitu
export { supabaseAdmin as supabaseService }
```

---

## 8. Auth a role systém

### 8.1 useAuth hook (Zustand store)

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
  adminVerified: boolean   // true = prošel PIN step
  initialize: () => Promise<void>
  signOut: () => Promise<void>
  setAdminVerified: (v: boolean) => void
}

export const useAuthStore = create<AuthState>((set) => ({
  user: null, role: null, contributorId: null,
  displayName: null, isVerified: false,
  loading: true, adminVerified: false,

  initialize: async () => {
    set({ loading: true })
    const { data: { session } } = await supabase.auth.getSession()
    if (!session) { set({ user: null, role: null, loading: false }); return }

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

    supabase.auth.onAuthStateChange(async (event, newSession) => {
      if (event === 'SIGNED_OUT' || !newSession) {
        set({ user: null, role: null, contributorId: null,
              adminVerified: false, loading: false })
      }
    })
  },

  signOut: async () => {
    await supabase.auth.signOut()
    set({ user: null, role: null, contributorId: null, adminVerified: false })
  },

  setAdminVerified: (v) => set({ adminVerified: v }),
}))

export const useIsAdmin = () =>
  ['superadmin', 'editor', 'viewer'].includes(useAuthStore(s => s.role) ?? '')

export const useIsContributor = () => {
  const role = useAuthStore(s => s.role)
  return role === 'contributor' || role === 'superadmin' || role === 'editor'
}

export const useCanEdit = () =>
  ['superadmin', 'editor'].includes(useAuthStore(s => s.role) ?? '')

export const useIsSuperAdmin = () =>
  useAuthStore(s => s.role) === 'superadmin'
```

### 8.2 AuthGuard a AdminGuard

```tsx
// src/components/layout/AuthGuard.tsx
// Základní guard – vyžaduje přihlášení a volitelně roli
import { useEffect } from 'react'
import { Navigate, Outlet, useLocation } from 'react-router-dom'
import { useAuthStore } from '@/hooks/useAuth'
import type { AppRole } from '@/hooks/useAuth'

interface AuthGuardProps { requiredRole?: 'contributor' | 'user' | 'any' }

export function AuthGuard({ requiredRole = 'any' }: AuthGuardProps) {
  const { user, role, loading, initialize } = useAuthStore()
  const location = useLocation()

  useEffect(() => { initialize() }, [])

  if (loading) return <FullscreenSpinner />
  if (!user) return <Navigate to="/login" state={{ from: location }} replace />

  if (requiredRole === 'contributor' &&
      !['contributor','superadmin','editor'].includes(role ?? '')) {
    return <Navigate to="/unauthorized" replace />
  }

  return <Outlet />
}

// src/components/layout/AdminGuard.tsx
// Rozšířený guard pro /admin/* – vyžaduje admin roli + PIN
export function AdminGuard() {
  const { user, role, adminVerified, loading, initialize } = useAuthStore()
  const location = useLocation()

  useEffect(() => { initialize() }, [])

  if (loading) return <FullscreenSpinner />
  if (!user) return <Navigate to="/login" state={{ from: location }} replace />
  if (!['superadmin','editor','viewer'].includes(role ?? '')) {
    return <Navigate to="/unauthorized" replace />
  }
  if (!adminVerified) return <Navigate to="/admin-pin" replace />
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

### 8.3 RoleGuard – inline ochrana

```tsx
// src/components/layout/RoleGuard.tsx
import { useAuthStore } from '@/hooks/useAuth'
import type { AppRole } from '@/hooks/useAuth'

interface RoleGuardProps {
  roles: AppRole[]
  fallback?: React.ReactNode
  children: React.ReactNode
}

export function RoleGuard({ roles, fallback = null, children }: RoleGuardProps) {
  const role = useAuthStore(s => s.role)
  if (!role || !roles.includes(role)) return <>{fallback}</>
  return <>{children}</>
}
```

---

## 9. Routing – tři skupiny routes

```tsx
// src/App.tsx – kompletní routing

import { BrowserRouter, Routes, Route, Navigate } from 'react-router-dom'
import { AdminGuard } from '@/components/layout/AdminGuard'
import { AuthGuard } from '@/components/layout/AuthGuard'
import { AppShell } from '@/components/layout/AppShell'
import { ContributorShell } from '@/components/layout/ContributorShell'

// Veřejné stránky
import { LoginPage } from '@/pages/LoginPage'
import { AdminPinPage } from '@/pages/AdminPinPage'
import { ContributorRegisterPage } from '@/pages/register/ContributorRegisterPage'
import { UnauthorizedPage } from '@/pages/UnauthorizedPage'

// Admin stránky
import { DashboardPage } from '@/pages/DashboardPage'
import { CitiesPage } from '@/pages/cities/CitiesPage'
import { CityNewPage } from '@/pages/cities/CityNewPage'
import { CityEditPage } from '@/pages/cities/CityEditPage'
import { PoisPage } from '@/pages/pois/PoisPage'
import { PoiNewPage } from '@/pages/pois/PoiNewPage'
import { PoiEditPage } from '@/pages/pois/PoiEditPage'
import { PoiTypesPage } from '@/pages/poi-types/PoiTypesPage'
import { UsersPage } from '@/pages/users/UsersPage'
import { UserDetailPage } from '@/pages/users/UserDetailPage'
import { PaymentsPage } from '@/pages/payments/PaymentsPage'
import { PaymentDetailPage } from '@/pages/payments/PaymentDetailPage'
import { ContributorsPage } from '@/pages/contributors/ContributorsPage'
import { ContributorDetailPage } from '@/pages/contributors/ContributorDetailPage'
import { HallOfFamePage } from '@/pages/hall-of-fame/HallOfFamePage'
import { SettingsPage } from '@/pages/SettingsPage'

// Contributor portál
import { ContributorDashboard } from '@/pages/contributor/ContributorDashboard'
import { ContributorPoiListPage } from '@/pages/contributor/ContributorPoiListPage'
import { ContributorPoiEditorPage } from '@/pages/contributor/ContributorPoiEditorPage'
import { ContributorProfilePage } from '@/pages/contributor/ContributorProfilePage'

export default function App() {
  return (
    <BrowserRouter>
      <Routes>
        {/* ── VEŘEJNÉ ROUTES ── */}
        <Route path="/login" element={<LoginPage />} />
        <Route path="/admin-pin" element={<AdminPinPage />} />
        <Route path="/register/contributor" element={<ContributorRegisterPage />} />
        <Route path="/unauthorized" element={<UnauthorizedPage />} />

        {/* ── ADMIN ROUTES (/admin/*) ── */}
        {/* Vyžaduje: přihlášení + admin role + PIN */}
        <Route path="/admin" element={<AdminGuard />}>
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
            <Route path="contributors" element={<ContributorsPage />} />
            <Route path="contributors/:id" element={<ContributorDetailPage />} />
            <Route path="hall-of-fame" element={<HallOfFamePage />} />
            <Route path="settings" element={<SettingsPage />} />
          </Route>
        </Route>

        {/* ── CONTRIBUTOR PORTÁL (/contributor/*) ── */}
        {/* Vyžaduje: přihlášení + contributor/admin role */}
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

        {/* Redirecty ze starých URL */}
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

## 10. Login a registrace

### 10.1 LoginPage – krok 1 přihlášení

```tsx
// src/pages/LoginPage.tsx
// Email + heslo → detekce role → přesměrování na PIN nebo contributor portál

import { useState } from 'react'
import { useNavigate, useLocation } from 'react-router-dom'
import { supabase } from '@/lib/supabase/client'
import { MapPin, Lock } from 'lucide-react'

export function LoginPage() {
  const navigate = useNavigate()
  const location = useLocation()
  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')
  const [error, setError] = useState('')
  const [loading, setLoading] = useState(false)

  async function handleLogin(e: React.FormEvent) {
    e.preventDefault()
    setLoading(true)
    setError('')

    const { data, error: authError } = await supabase.auth.signInWithPassword({
      email, password
    })

    if (authError) {
      setError('Nesprávný email nebo heslo')
      setLoading(false)
      return
    }

    // Zjistit roli z web_user_roles
    const { data: roleData } = await supabase
      .from('web_user_roles')
      .select('effective_role')
      .eq('user_id', data.user.id)
      .single()

    const role = roleData?.effective_role ?? 'user'

    // Přesměrování dle role
    if (['superadmin', 'editor', 'viewer'].includes(role)) {
      navigate('/admin-pin')                           // krok 2 pro adminy
    } else if (role === 'contributor') {
      navigate('/contributor/dashboard')
    } else {
      const from = (location.state as any)?.from?.pathname ?? '/'
      navigate(from)
    }
  }

  return (
    <div className="min-h-screen bg-muted/20 flex flex-col items-center justify-center p-4">
      <div className="w-full max-w-sm">
        {/* Branding */}
        <div className="text-center mb-8">
          <div className="w-14 h-14 bg-primary rounded-2xl flex items-center justify-center mx-auto mb-3 shadow-lg">
            <MapPin className="w-7 h-7 text-white" />
          </div>
          <h1 className="text-2xl font-bold tracking-tight">
            Place<span className="text-[#B8960C]">Secrets</span>
          </h1>
          <p className="text-muted-foreground text-sm mt-1">
            Průvodcovský a administrační portál
          </p>
        </div>

        {/* Login karta */}
        <div className="bg-card border rounded-xl p-6 shadow-sm">
          <form onSubmit={handleLogin} className="space-y-4">
            <div>
              <label className="block text-sm font-medium mb-1.5">Email</label>
              <input
                type="email"
                value={email}
                onChange={e => setEmail(e.target.value)}
                className="w-full px-3 py-2 border rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-primary/30 focus:border-primary"
                placeholder="vas@email.cz"
                required
                autoFocus
              />
            </div>
            <div>
              <label className="block text-sm font-medium mb-1.5">Heslo</label>
              <input
                type="password"
                value={password}
                onChange={e => setPassword(e.target.value)}
                className="w-full px-3 py-2 border rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-primary/30 focus:border-primary"
                required
              />
            </div>

            {error && (
              <div className="bg-red-50 border border-red-200 text-red-700 rounded-lg px-3 py-2 text-sm">
                {error}
              </div>
            )}

            <button
              type="submit"
              disabled={loading}
              className="w-full py-2.5 bg-primary text-white rounded-lg font-medium text-sm
                         hover:bg-primary/90 disabled:opacity-50 transition-colors"
            >
              {loading ? 'Přihlašuji...' : 'Přihlásit se'}
            </button>
          </form>
        </div>

        {/* Info o admin PIN */}
        <div className="mt-4 flex items-start gap-2 p-3 bg-blue-50 border border-blue-100 rounded-lg text-xs text-blue-700">
          <Lock className="w-3.5 h-3.5 shrink-0 mt-0.5" />
          <span>Administrátoři budou po přihlášení vyzváni k zadání admin PIN.</span>
        </div>

        {/* Link na contributor registraci */}
        <p className="text-center text-xs text-muted-foreground mt-4">
          Chcete přispívat průvodci?{' '}
          <a href="/register/contributor" className="text-primary hover:underline font-medium">
            Zaregistrujte se
          </a>
        </p>
      </div>
    </div>
  )
}
```

### 10.2 ContributorRegisterPage

```tsx
// src/pages/register/ContributorRegisterPage.tsx

export function ContributorRegisterPage() {
  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')
  const [displayName, setDisplayName] = useState('')
  const [bio, setBio] = useState('')
  const [loading, setLoading] = useState(false)
  const navigate = useNavigate()
  const toast = useToast()

  async function register() {
    if (!email || !password || !displayName) return
    setLoading(true)

    let userId: string
    const { data: existing } = await supabase.auth.getSession()

    if (existing.session) {
      userId = existing.session.user.id
    } else {
      const { data, error } = await supabase.auth.signUp({ email, password })
      if (error || !data.user) {
        toast.error('Chyba registrace: ' + error?.message)
        setLoading(false)
        return
      }
      userId = data.user.id
    }

    await supabase.from('contributor_profiles').insert({
      user_id: userId,
      display_name: displayName,
      bio,
      is_verified: false,
    })

    await supabase.from('admin_users').upsert({
      user_id: userId,
      role: 'contributor',
    }, { onConflict: 'user_id' })

    toast.success('Profil vytvořen! Čeká na ověření administrátorem.')
    navigate('/contributor/dashboard')
  }

  return (
    <div className="min-h-screen bg-muted/20 flex items-center justify-center p-4">
      <div className="w-full max-w-md space-y-5">
        <div className="text-center">
          <div className="w-12 h-12 bg-primary rounded-xl flex items-center justify-center mx-auto mb-3">
            <MapPin className="w-6 h-6 text-white" />
          </div>
          <h1 className="text-2xl font-bold">
            Staňte se průvodcem <span className="text-[#B8960C]">PlaceSecrets</span>
          </h1>
          <p className="text-muted-foreground text-sm mt-1">
            Sdílejte svůj místní pohled se světem
          </p>
        </div>

        {/* Benefity */}
        <div className="border rounded-xl p-4 bg-card space-y-2 text-sm">
          <p className="font-medium">Co jako průvodce získáte:</p>
          <ul className="text-muted-foreground space-y-1">
            {[
              'Vaše jméno u každého průvodce v aplikaci',
              'Hodnocení od tisíců turistů',
              'Místo v Hall of Fame nejlepších průvodců',
              'Uznání lokální odbornosti',
            ].map(b => (
              <li key={b} className="flex items-center gap-2">
                <span className="text-green-500 shrink-0">✓</span> {b}
              </li>
            ))}
          </ul>
        </div>

        {/* Formulář */}
        <div className="border rounded-xl p-5 bg-card space-y-4">
          {[
            { label: 'Email', value: email, setter: setEmail, type: 'email', placeholder: 'vas@email.cz', required: true },
            { label: 'Heslo', value: password, setter: setPassword, type: 'password', required: true },
            { label: 'Zobrazované jméno *', value: displayName, setter: setDisplayName, type: 'text', placeholder: 'Jan Novák', required: true },
          ].map(({ label, value, setter, type, placeholder, required }) => (
            <div key={label}>
              <label className="block text-sm font-medium mb-1">{label}</label>
              <input
                type={type}
                value={value}
                onChange={e => setter(e.target.value)}
                placeholder={placeholder}
                className="input w-full"
                required={required}
              />
            </div>
          ))}

          <div>
            <label className="block text-sm font-medium mb-1">Bio (volitelné)</label>
            <textarea
              value={bio}
              onChange={e => setBio(e.target.value.slice(0, 300))}
              className="input w-full h-20 resize-none"
              placeholder="Místní průvodce, historik..."
            />
            <p className="text-xs text-muted-foreground mt-0.5">{bio.length}/300</p>
          </div>

          <button
            onClick={register}
            disabled={!email || !password || !displayName || loading}
            className="w-full py-2.5 bg-primary text-white rounded-lg font-medium text-sm disabled:opacity-50"
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

## 11. Admin portál – layout a navigace

### 11.1 AppShell

```tsx
// src/components/layout/AppShell.tsx
import { Outlet } from 'react-router-dom'
import { Sidebar } from './Sidebar'
import { Header } from './Header'

export function AppShell() {
  return (
    <div className="flex h-screen bg-background overflow-hidden">
      <Sidebar />
      <div className="flex-1 flex flex-col min-w-0 overflow-hidden">
        <Header />
        <main className="flex-1 overflow-y-auto p-6">
          <Outlet />
        </main>
      </div>
    </div>
  )
}
```

### 11.2 Sidebar s rolemi a PIN indikátorem

```tsx
// src/components/layout/Sidebar.tsx

import { NavLink, useNavigate } from 'react-router-dom'
import {
  LayoutDashboard, MapPin, Tag, Users, CreditCard,
  PenLine, Trophy, Settings, LogOut, Shield, UserCircle
} from 'lucide-react'
import { cn } from '@/lib/utils'
import { useAuthStore, useIsSuperAdmin } from '@/hooks/useAuth'

const ADMIN_NAV = [
  { to: '/admin/dashboard',    icon: LayoutDashboard, label: 'Dashboard',        roles: ['superadmin','editor','viewer'] },
  { to: '/admin/cities',       icon: MapPin,           label: 'Oblasti & POI',    roles: ['superadmin','editor','viewer'] },
  { to: '/admin/poi-types',    icon: Tag,              label: 'Typy POI',         roles: ['superadmin','editor','viewer'] },
  { to: '/admin/users',        icon: Users,            label: 'Uživatelé',        roles: ['superadmin','editor','viewer'] },
  { to: '/admin/payments',     icon: CreditCard,       label: 'Platby',           roles: ['superadmin','editor','viewer'] },
  { to: '/admin/contributors', icon: PenLine,          label: 'Průvodci',         roles: ['superadmin','editor'] },
  { to: '/admin/hall-of-fame', icon: Trophy,           label: 'Hall of Fame',     roles: ['superadmin','editor','viewer'] },
  { to: '/admin/settings',     icon: Settings,         label: 'Nastavení',        roles: ['superadmin'] },
]

export function Sidebar() {
  const { role, user, signOut, setAdminVerified } = useAuthStore()
  const navigate = useNavigate()
  const isSuperAdmin = useIsSuperAdmin()

  const filteredNav = ADMIN_NAV.filter(item =>
    item.roles.includes(role ?? '')
  )

  async function logout() {
    await signOut()
    navigate('/login')
  }

  const ROLE_LABELS: Record<string, string> = {
    superadmin: 'Superadmin',
    editor: 'Editor',
    viewer: 'Viewer',
  }

  return (
    <aside className="w-56 bg-card border-r flex flex-col shrink-0">
      {/* Logo */}
      <div className="p-4 border-b">
        <div className="flex items-center gap-2.5">
          <div className="w-8 h-8 bg-primary rounded-lg flex items-center justify-center shrink-0">
            <MapPin className="w-4 h-4 text-white" />
          </div>
          <div className="leading-none min-w-0">
            <p className="font-bold text-sm tracking-tight">
              Place<span className="text-[#B8960C]">Secrets</span>
            </p>
            <p className="text-xs text-muted-foreground">Admin portál</p>
          </div>
        </div>
      </div>

      {/* Role badge */}
      <div className="px-4 py-2 border-b">
        <div className="flex items-center gap-1.5">
          <Shield className="w-3 h-3 text-primary" />
          <span className="text-xs font-medium text-primary">
            {ROLE_LABELS[role ?? ''] ?? role}
          </span>
        </div>
      </div>

      {/* Navigace */}
      <nav className="flex-1 p-3 space-y-0.5 overflow-y-auto">
        {filteredNav.map(({ to, icon: Icon, label }) => (
          <NavLink
            key={to}
            to={to}
            className={({ isActive }) => cn(
              'flex items-center gap-2.5 px-3 py-2 rounded-lg text-sm transition-colors',
              isActive
                ? 'bg-primary text-primary-foreground font-medium'
                : 'text-muted-foreground hover:bg-muted hover:text-foreground'
            )}
          >
            <Icon className="w-4 h-4 shrink-0" />
            <span className="truncate">{label}</span>
          </NavLink>
        ))}
      </nav>

      {/* User + odhlášení */}
      <div className="p-3 border-t space-y-1">
        <div className="flex items-center gap-2 px-3 py-1.5">
          <div className="w-6 h-6 rounded-full bg-primary/10 flex items-center justify-center shrink-0">
            <span className="text-primary text-xs font-bold">
              {user?.email?.[0]?.toUpperCase() ?? 'A'}
            </span>
          </div>
          <span className="text-xs text-muted-foreground truncate flex-1">
            {user?.email}
          </span>
        </div>

        {/* Odkaz do contributor portálu pro superadmina */}
        {isSuperAdmin && (
          <button
            onClick={() => navigate('/contributor/dashboard')}
            className="w-full flex items-center gap-2 px-3 py-1.5 text-xs text-muted-foreground hover:text-foreground rounded hover:bg-muted transition-colors"
          >
            <UserCircle className="w-3.5 h-3.5" />
            Contributor portál
          </button>
        )}

        <button
          onClick={logout}
          className="w-full flex items-center gap-2 px-3 py-1.5 text-xs text-muted-foreground hover:text-red-600 rounded hover:bg-muted transition-colors"
        >
          <LogOut className="w-3.5 h-3.5" />
          Odhlásit se
        </button>
      </div>
    </aside>
  )
}
```

### 11.3 Header

```tsx
// src/components/layout/Header.tsx
import { useLocation } from 'react-router-dom'

const TITLE_MAP: Record<string, string> = {
  '/admin/dashboard':    'Dashboard',
  '/admin/cities':       'Oblasti & POI',
  '/admin/poi-types':    'Typy POI',
  '/admin/users':        'Uživatelé',
  '/admin/payments':     'Platby',
  '/admin/contributors': 'Průvodci',
  '/admin/hall-of-fame': 'Hall of Fame',
  '/admin/settings':     'Nastavení',
}

export function Header() {
  const { pathname } = useLocation()
  const title = Object.entries(TITLE_MAP)
    .find(([k]) => pathname.startsWith(k))?.[1] ?? 'PlaceSecrets'

  return (
    <header className="h-14 border-b flex items-center px-6 bg-card shrink-0 gap-3">
      <h1 className="font-semibold text-sm">{title}</h1>
    </header>
  )
}
```

---

## 12. Dashboard

```tsx
// src/pages/DashboardPage.tsx

import { useEffect, useState } from 'react'
import { supabaseAdmin } from '@/lib/supabase/client'
import { MetricCard } from '@/components/dashboard/MetricCard'
import { RevenueChart } from '@/components/dashboard/RevenueChart'
import { ActivityChart } from '@/components/dashboard/ActivityChart'

export function DashboardPage() {
  const [stats, setStats] = useState<any>(null)
  const [revenue, setRevenue] = useState<any[]>([])
  const [activity, setActivity] = useState<any[]>([])
  const [topPois, setTopPois] = useState<any[]>([])
  const [typeStats, setTypeStats] = useState<any[]>([])
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    async function load() {
      const [s, r, a, t, ts] = await Promise.all([
        supabaseAdmin.from('admin_stats').select('*').single(),
        supabaseAdmin.rpc('revenue_by_month', { months_back: 12 }),
        supabaseAdmin.rpc('daily_activity', { days_back: 30 }),
        supabaseAdmin.rpc('top_visited_pois', { limit_count: 10 }),
        supabaseAdmin.rpc('poi_types_stats'),
      ])
      setStats(s.data); setRevenue(r.data ?? [])
      setActivity(a.data ?? []); setTopPois(t.data ?? [])
      setTypeStats(ts.data ?? [])
      setLoading(false)
    }
    load()
  }, [])

  if (loading) return <DashboardSkeleton />

  return (
    <div className="space-y-6 max-w-7xl">
      {/* Karta 1 – Uživatelé + tržby */}
      <div>
        <h2 className="text-xs font-medium text-muted-foreground uppercase tracking-wider mb-3">
          Uživatelé & Tržby
        </h2>
        <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
          <MetricCard title="Registrovaní" value={stats?.registered_users} icon="users" />
          <MetricCard title="Anonymní" value={stats?.anonymous_users} icon="ghost" />
          <MetricCard title="Celkové tržby" value={`${stats?.total_revenue_eur ?? 0} €`} icon="euro" color="green" />
          <MetricCard title="Čeká (Revolut)" value={stats?.pending_revolut} icon="clock" color="orange" />
        </div>
      </div>

      {/* Karta 2 – Obsah */}
      <div>
        <h2 className="text-xs font-medium text-muted-foreground uppercase tracking-wider mb-3">
          Obsah aplikace
        </h2>
        <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
          <MetricCard title="Aktivní oblasti" value={stats?.active_cities} icon="map" />
          <MetricCard title="Aktivní POI" value={stats?.active_pois} icon="map-pin" />
          <MetricCard title="Free návštěvy (měsíc)" value={stats?.free_visits_this_month} icon="eye" />
          <MetricCard title="Celkem nákupů" value={stats?.total_purchases} icon="credit-card" />
        </div>
      </div>

      {/* Karta 3 – Průvodci */}
      <div>
        <h2 className="text-xs font-medium text-muted-foreground uppercase tracking-wider mb-3">
          Průvodci & Hodnocení
        </h2>
        <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
          <MetricCard title="Průvodci celkem" value={stats?.total_contributors} icon="pen-line" />
          <MetricCard title="Ověření průvodci" value={stats?.verified_contributors} icon="badge-check" color="green" />
          <MetricCard title="Hodnocení POI" value={stats?.total_poi_ratings} icon="star" />
          <MetricCard title="Průměrné hodnocení"
            value={stats?.global_avg_rating ? `${stats.global_avg_rating}★` : '—'}
            icon="trophy" color="green" />
        </div>
      </div>

      {/* Grafy */}
      <div className="grid md:grid-cols-2 gap-6">
        <RevenueChart data={revenue} />
        <ActivityChart data={activity} />
      </div>

      {/* Typy POI + Top POI */}
      <div className="grid md:grid-cols-2 gap-6">
        <PoiTypesWidget data={typeStats} />
        <TopPoisTable data={topPois} />
      </div>
    </div>
  )
}
```

---

## 13. Správa měst a POI

> Kompletní kód odpovídá sekci 10 z původní spec (CityForm, MapPicker, PoiForm,
> AudioUploader, PhotoUploader, PoisPage s řazením a filtry).
> Jedinou změnou jsou importy – místo `supabase` se používá `supabaseAdmin`.

### 13.1 Klíčové změny oproti původní spec

```typescript
// Ve všech admin pages nahradit:
import { supabase } from '@/lib/supabase/client'
// Za:
import { supabaseAdmin } from '@/lib/supabase/client'

// A všechna volání supabase.from(...) → supabaseAdmin.from(...)
// Týká se: CitiesPage, CityForm, PoisPage, PoiForm, PoiEditPage, PoiNewPage
```

### 13.2 PoiForm – přidání contributor_id pole

```tsx
// src/components/pois/PoiForm.tsx – přidat sekci pro přiřazení průvodce

// Přidat state:
const [contributors, setContributors] = useState<any[]>([])

useEffect(() => {
  supabaseAdmin
    .from('contributor_profiles')
    .select('user_id, display_name, is_verified')
    .eq('is_active', true)
    .order('display_name')
    .then(({ data }) => setContributors(data ?? []))
}, [])

// Přidat do formuláře:
<div>
  <label className="block text-sm font-medium mb-1">Přiřazený průvodce</label>
  <select {...register('contributor_id')} className="input w-full">
    <option value="">— Bez průvodce —</option>
    {contributors.map(c => (
      <option key={c.user_id} value={c.user_id}>
        {c.display_name}
        {c.is_verified ? ' ✓' : ' (neověřen)'}
      </option>
    ))}
  </select>
</div>
```

---

## 14. Správa typů POI

> Kompletní kód: viz sekce 20 z původní spec.
> Změna: všechny Supabase importy → `supabaseAdmin`.

### Přehled komponent

| Soubor | Účel |
|---|---|
| `PoiTypesPage.tsx` | Seznam typů, řazení, toggle aktivní, delete |
| `PoiTypeModal.tsx` | Modal pro přidání/editaci s živým náhledem pinu |
| `poi-type-icons.ts` | Konstanty ikon + `MaterialIcon` komponenta |

---

## 15. Správa uživatelů

> Kompletní kód: viz sekce 11 z původní spec.
> Změna: všechny Supabase importy → `supabaseAdmin`.

---

## 16. Správa plateb

> Kompletní kód: viz sekce 12 z původní spec.
> Zahrnuje: PaymentsPage, PaymentDetailPage, Revolut potvrzení, Stripe Refund, CSV export.
> Prefix dokladů: `PS-` (PlaceSecrets) místo `HD-`.

### 16.1 Prefix dokladů

```sql
-- V migrace 003 – oprava prefixu pro PlaceSecrets:
NEW.receipt_number := 'PS-' || TO_CHAR(NOW(), 'YYYY') || '-'
  || LPAD(nextval('public.receipt_number_seq')::TEXT, 4, '0');

-- Výsledek: PS-2026-0001, PS-2026-0002, ...
```

---

## 17. Správa přispěvatelů

### 17.1 ContributorsPage

```tsx
// src/pages/contributors/ContributorsPage.tsx
// Seznam všech přispěvatelů – admin může verifikovat / odebrat

import { useEffect, useState } from 'react'
import { Link } from 'react-router-dom'
import { supabaseAdmin } from '@/lib/supabase/client'
import { useToast } from '@/hooks/useToast'
import { Eye, Mail } from 'lucide-react'

export function ContributorsPage() {
  const [contributors, setContributors] = useState<any[]>([])
  const [search, setSearch] = useState('')
  const [filterVerified, setFilterVerified] = useState<'all' | 'verified' | 'pending'>('all')
  const toast = useToast()

  useEffect(() => { load() }, [])

  async function load() {
    const { data } = await supabaseAdmin
      .from('contributor_profiles')
      .select('*, auth_user:user_id(email, created_at, last_sign_in_at)')
      .order('created_at', { ascending: false })
    setContributors(data ?? [])
  }

  async function toggleVerified(cp: any) {
    await supabaseAdmin.from('contributor_profiles')
      .update({ is_verified: !cp.is_verified }).eq('id', cp.id)
    setContributors(cs =>
      cs.map(c => c.id === cp.id ? { ...c, is_verified: !c.is_verified } : c)
    )
    toast.success(cp.is_verified ? 'Ověření odebráno' : 'Průvodce ověřen ✓')
  }

  async function sendInvite(email: string, message: string) {
    await supabaseAdmin.functions.invoke('invite-contributor', {
      body: JSON.stringify({ email, personalMessage: message }),
    })
    toast.success(`Pozvánka odeslána na ${email}`)
  }

  const filtered = contributors.filter(c => {
    const ms = !search
      || c.display_name?.toLowerCase().includes(search.toLowerCase())
      || c.auth_user?.email?.toLowerCase().includes(search.toLowerCase())
    const mv = filterVerified === 'all'
      || (filterVerified === 'verified' && c.is_verified)
      || (filterVerified === 'pending' && !c.is_verified)
    return ms && mv
  })

  return (
    <div className="space-y-4">
      <div className="flex items-center justify-between">
        <div>
          <h2 className="text-xl font-bold">Průvodci</h2>
          <p className="text-sm text-muted-foreground">
            Přispěvatelé textů pro POI v aplikaci
          </p>
        </div>
        <InviteContributorButton onInvite={sendInvite} />
      </div>

      <div className="flex gap-3">
        <input value={search} onChange={e => setSearch(e.target.value)}
          placeholder="Hledat jméno nebo email..." className="input flex-1" />
        <select value={filterVerified} onChange={e => setFilterVerified(e.target.value as any)}
          className="input w-44">
          <option value="all">Všichni</option>
          <option value="verified">Ověření ✓</option>
          <option value="pending">Čekají na ověření</option>
        </select>
      </div>

      <div className="border rounded-lg overflow-hidden">
        <table className="w-full text-sm">
          <thead className="bg-muted/50 border-b">
            <tr>
              {['Průvodce', 'Email', 'Průvodci', 'Hodnocení', 'Ověřen', 'Registrace', ''].map(h => (
                <th key={h} className="px-4 py-3 text-left font-medium text-muted-foreground">{h}</th>
              ))}
            </tr>
          </thead>
          <tbody>
            {filtered.map(c => (
              <tr key={c.id} className="border-t hover:bg-muted/20">
                <td className="px-4 py-3">
                  <div className="flex items-center gap-2">
                    <div className="w-8 h-8 rounded-full bg-primary/10 flex items-center justify-center text-sm font-bold text-primary">
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
                    : <span className="text-muted-foreground text-xs">—</span>}
                </td>
                <td className="px-4 py-3">
                  <button onClick={() => toggleVerified(c)}>
                    {c.is_verified
                      ? <span className="text-xs bg-blue-100 text-blue-700 px-2 py-0.5 rounded-full">✓ Ověřen</span>
                      : <span className="text-xs bg-orange-100 text-orange-700 px-2 py-0.5 rounded-full">⏳ Čeká</span>}
                  </button>
                </td>
                <td className="px-4 py-3 text-muted-foreground text-xs">
                  {new Date(c.created_at).toLocaleDateString('cs-CZ')}
                </td>
                <td className="px-4 py-3">
                  <Link to={`/admin/contributors/${c.id}`}>
                    <button className="p-1.5 hover:bg-muted rounded">
                      <Eye className="w-4 h-4" />
                    </button>
                  </Link>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
      <p className="text-xs text-muted-foreground">{filtered.length} průvodců</p>
    </div>
  )
}
```

---

## 18. Hall of Fame – admin přehled

```tsx
// src/pages/hall-of-fame/HallOfFamePage.tsx

import { useEffect, useState } from 'react'
import { Link } from 'react-router-dom'
import { supabaseAdmin } from '@/lib/supabase/client'
import { Eye } from 'lucide-react'

export function HallOfFamePage() {
  const [cities, setCities] = useState<any[]>([])
  const [selectedCity, setSelectedCity] = useState<string>('')
  const [hofData, setHofData] = useState<any[]>([])
  const [loading, setLoading] = useState(false)

  useEffect(() => {
    supabaseAdmin.from('cities').select('id, name').eq('is_active', true).order('name')
      .then(({ data }) => {
        const list = data ?? []
        setCities(list)
        if (list.length > 0) setSelectedCity(list[0].id)
      })
  }, [])

  useEffect(() => {
    if (!selectedCity) return
    setLoading(true)
    supabaseAdmin.rpc('poi_hall_of_fame', { p_city_id: selectedCity, p_limit: 10 })
      .then(({ data }) => { setHofData(data ?? []); setLoading(false) })
  }, [selectedCity])

  const rankEmoji = (r: number) => r === 1 ? '🥇' : r === 2 ? '🥈' : r === 3 ? '🥉' : `#${r}`

  return (
    <div className="space-y-5 max-w-4xl">
      <div>
        <h2 className="text-xl font-bold">Hall of Fame</h2>
        <p className="text-sm text-muted-foreground">
          Žebříček nejlepších průvodců v každém městě
        </p>
      </div>

      <div className="flex items-center gap-3">
        <label className="text-sm font-medium">Město:</label>
        <select value={selectedCity} onChange={e => setSelectedCity(e.target.value)}
          className="input w-52">
          {cities.map(c => <option key={c.id} value={c.id}>{c.name}</option>)}
        </select>
      </div>

      {loading ? (
        <div className="text-center py-12 text-muted-foreground">Načítám žebříček...</div>
      ) : hofData.length === 0 ? (
        <div className="border rounded-xl p-8 text-center text-muted-foreground">
          <p className="text-3xl mb-2">🏆</p>
          <p className="font-medium">Žebříček je prázdný</p>
          <p className="text-sm mt-1">Min. 10 hodnocení a průměr ≥ 4.0★</p>
        </div>
      ) : (
        <div className="border rounded-xl overflow-hidden">
          <table className="w-full text-sm">
            <thead className="bg-muted/50 border-b">
              <tr>
                {['#', 'Průvodce', 'POI v městě', 'Průměr', 'Hodnocení', 'HoF skóre', ''].map(h => (
                  <th key={h} className="px-4 py-3 text-left font-medium text-muted-foreground">{h}</th>
                ))}
              </tr>
            </thead>
            <tbody>
              {hofData.map((e: any) => (
                <tr key={e.contributor_id} className="border-t hover:bg-muted/20">
                  <td className="px-4 py-3 text-xl font-bold">{rankEmoji(e.rank)}</td>
                  <td className="px-4 py-3">
                    <span className="font-medium">{e.display_name}</span>
                    {e.is_verified && <span className="ml-1.5 text-blue-500 text-xs">✓</span>}
                  </td>
                  <td className="px-4 py-3">{e.city_poi_count}</td>
                  <td className="px-4 py-3 text-yellow-600 font-medium">
                    {Number(e.city_avg_rating).toFixed(1)}★
                  </td>
                  <td className="px-4 py-3">{e.city_total_ratings}</td>
                  <td className="px-4 py-3 font-mono text-xs text-muted-foreground">
                    {Number(e.hof_score).toFixed(3)}
                  </td>
                  <td className="px-4 py-3">
                    <Link to={`/admin/contributors/${e.contributor_id}`}>
                      <button className="p-1.5 hover:bg-muted rounded">
                        <Eye className="w-4 h-4" />
                      </button>
                    </Link>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}

      <div className="text-xs text-muted-foreground bg-muted/30 rounded-lg p-3 space-y-1">
        <p>• Skóre = průměrné hodnocení × log₁₀(počet hodnocení + 1)</p>
        <p>• Minimum pro vstup: 10+ hodnocení v daném městě, průměr libovolný</p>
        <p>• Žebříček se aktualizuje v reálném čase</p>
      </div>
    </div>
  )
}
```

---

## 19. Nastavení

### 19.1 SettingsPage – kompletní

```tsx
// src/pages/SettingsPage.tsx

import { useEffect, useState } from 'react'
import { supabaseAdmin } from '@/lib/supabase/client'
import { AdminUsersTable } from '@/components/settings/AdminUsersTable'
import { InviteAdminForm } from '@/components/settings/InviteAdminForm'
import { ChangePinForm } from '@/components/settings/ChangePinForm'
import { useToast } from '@/hooks/useToast'
import { RoleGuard } from '@/components/layout/RoleGuard'

const PAYMENT_FIELDS = [
  { name: 'operator_name',          label: 'Název operátora' },
  { name: 'revolut_username',       label: 'Revolut username',        placeholder: 'placesecrets' },
  { name: 'revolut_iban',           label: 'Revolut IBAN' },
  { name: 'stripe_publishable_key', label: 'Stripe Publishable Key',  placeholder: 'pk_live_...' },
  { name: 'google_pay_merchant_id', label: 'Google Pay Merchant ID' },
  { name: 'apple_pay_merchant_id',  label: 'Apple Pay Merchant ID' },
]

export function SettingsPage() {
  const [config, setConfig] = useState<Record<string, string>>({})
  const [saving, setSaving] = useState(false)
  const [adminKey, setAdminKey] = useState(0)
  const toast = useToast()

  useEffect(() => {
    supabaseAdmin.from('payment_config').select('*').single()
      .then(({ data }) => data && setConfig(data))
  }, [])

  async function saveConfig(e: React.FormEvent<HTMLFormElement>) {
    e.preventDefault()
    setSaving(true)
    const values = Object.fromEntries(new FormData(e.currentTarget).entries())
    if (config.id) {
      await supabaseAdmin.from('payment_config').update(values).eq('id', config.id)
    } else {
      await supabaseAdmin.from('payment_config').insert(values)
    }
    setSaving(false)
    toast.success('Konfigurace uložena')
  }

  return (
    <div className="space-y-6 max-w-xl">
      <h2 className="text-xl font-bold">Nastavení</h2>

      {/* Admin PIN – každý admin může měnit svůj PIN */}
      <div className="border rounded-xl p-6">
        <h3 className="font-medium mb-1">Admin PIN</h3>
        <p className="text-xs text-muted-foreground mb-4">
          6místný PIN pro vstup do admin sekce.
          Zadává se po každém přihlášení emailem+heslem.
        </p>
        <ChangePinForm />
      </div>

      {/* Platební konfigurace – jen superadmin */}
      <RoleGuard roles={['superadmin']}>
        <div className="border rounded-xl p-6">
          <h3 className="font-medium mb-4">Platební metody</h3>
          <form onSubmit={saveConfig} className="space-y-4">
            {PAYMENT_FIELDS.map(({ name, label, placeholder }) => (
              <div key={name}>
                <label className="block text-sm font-medium mb-1">{label}</label>
                <input name={name} defaultValue={config[name] ?? ''}
                  placeholder={placeholder} className="input w-full" />
              </div>
            ))}
            <button type="submit" disabled={saving}
              className="px-4 py-2 bg-primary text-white rounded text-sm disabled:opacity-50">
              {saving ? 'Ukládám...' : 'Uložit'}
            </button>
          </form>
        </div>
      </RoleGuard>

      {/* Správa adminů – jen superadmin */}
      <RoleGuard roles={['superadmin']}>
        <div className="border rounded-xl p-6">
          <div className="flex items-center justify-between mb-3">
            <div>
              <h3 className="font-medium">Administrátoři</h3>
              <p className="text-xs text-muted-foreground mt-0.5">
                Superadmin – plný přístup · Editor – editace obsahu ·
                Viewer – pouze čtení
              </p>
            </div>
            <InviteAdminForm onInvited={() => setAdminKey(k => k + 1)} />
          </div>
          <AdminUsersTable key={adminKey} />
        </div>
      </RoleGuard>

      {/* Systémové limity */}
      <div className="border rounded-xl p-6">
        <h3 className="font-medium mb-3">Systémové limity (read-only)</h3>
        <div className="space-y-2 text-sm text-muted-foreground">
          {[
            ['Free POI za měsíc', '1'],
            ['Max geofences', '100 (Android)'],
            ['Max foto na POI', '10 MB/ks'],
            ['Max audio na POI', '50 MB/ks'],
          ].map(([label, value]) => (
            <div key={label} className="flex justify-between">
              <span>{label}</span>
              <span className="font-mono text-xs">{value}</span>
            </div>
          ))}
        </div>
      </div>
    </div>
  )
}
```

### 19.2 ChangePinForm

```tsx
// src/components/settings/ChangePinForm.tsx

import { useState } from 'react'
import { supabase } from '@/lib/supabase/client'
import { useToast } from '@/hooks/useToast'

export function ChangePinForm() {
  const [currentPin, setCurrentPin] = useState('')
  const [newPin, setNewPin] = useState('')
  const [confirm, setConfirm] = useState('')
  const [loading, setLoading] = useState(false)
  const toast = useToast()

  async function changePin() {
    if (newPin.length !== 6 || !/^\d{6}$/.test(newPin)) {
      toast.error('PIN musí být 6 číslic')
      return
    }
    if (newPin !== confirm) {
      toast.error('PINy se neshodují')
      return
    }
    setLoading(true)
    const session = (await supabase.auth.getSession()).data.session
    const res = await supabase.functions.invoke('change-admin-pin', {
      headers: { Authorization: `Bearer ${session?.access_token}` },
      body: JSON.stringify({ current_pin: currentPin, new_pin: newPin }),
    })
    if (res.data?.success) {
      toast.success('PIN byl změněn')
      setCurrentPin(''); setNewPin(''); setConfirm('')
    } else {
      toast.error(res.data?.error ?? 'Chyba při změně PIN')
    }
    setLoading(false)
  }

  return (
    <div className="space-y-3 max-w-xs">
      <div>
        <label className="block text-sm font-medium mb-1">Stávající PIN</label>
        <input type="password" value={currentPin} onChange={e => setCurrentPin(e.target.value)}
          maxLength={6} inputMode="numeric" className="input w-full"
          placeholder="Ponechte prázdné pokud PIN ještě nemáte" />
      </div>
      <div>
        <label className="block text-sm font-medium mb-1">Nový PIN (6 číslic)</label>
        <input type="password" value={newPin} onChange={e => setNewPin(e.target.value)}
          maxLength={6} inputMode="numeric" className="input w-full" placeholder="••••••" />
      </div>
      <div>
        <label className="block text-sm font-medium mb-1">Potvrdit nový PIN</label>
        <input type="password" value={confirm} onChange={e => setConfirm(e.target.value)}
          maxLength={6} inputMode="numeric" className="input w-full" placeholder="••••••" />
      </div>
      <button onClick={changePin} disabled={!newPin || !confirm || loading}
        className="px-4 py-2 bg-primary text-white rounded text-sm disabled:opacity-50">
        {loading ? 'Ukládám...' : 'Změnit PIN'}
      </button>
    </div>
  )
}
```

---

## 20. Contributor portál

### 20.1 ContributorShell

```tsx
// src/components/layout/ContributorShell.tsx

import { Outlet, NavLink, useNavigate } from 'react-router-dom'
import { useAuthStore } from '@/hooks/useAuth'
import { LayoutDashboard, MapPin, UserCircle, LogOut } from 'lucide-react'

const NAV = [
  { to: '/contributor/dashboard', icon: LayoutDashboard, label: 'Přehled' },
  { to: '/contributor/pois',      icon: MapPin,          label: 'Moje průvodci' },
  { to: '/contributor/profile',   icon: UserCircle,      label: 'Můj profil' },
]

export function ContributorShell() {
  const { user, displayName, isVerified, signOut } = useAuthStore()
  const navigate = useNavigate()

  return (
    <div className="min-h-screen flex bg-background">
      <aside className="w-52 border-r bg-card flex flex-col shrink-0">
        {/* Logo */}
        <div className="p-4 border-b">
          <p className="font-bold text-sm">
            Place<span className="text-[#B8960C]">Secrets</span>
          </p>
          <p className="text-xs text-muted-foreground mt-0.5">Průvodcovský portál</p>
        </div>

        {/* Nav */}
        <nav className="flex-1 p-3 space-y-0.5">
          {NAV.map(item => (
            <NavLink key={item.to} to={item.to}
              className={({ isActive }) =>
                `flex items-center gap-2.5 px-3 py-2 rounded-lg text-sm transition-colors ${
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

        {/* Footer */}
        <div className="p-3 border-t space-y-2">
          {/* Verified badge */}
          <div className={`flex items-center gap-1.5 px-3 py-1.5 rounded-lg text-xs ${
            isVerified
              ? 'bg-blue-50 text-blue-700'
              : 'bg-orange-50 text-orange-700'
          }`}>
            {isVerified ? '✓ Ověřený průvodce' : '⏳ Čeká na ověření'}
          </div>

          <p className="text-xs text-muted-foreground px-3 truncate">{displayName}</p>

          <button
            onClick={() => { signOut(); navigate('/login') }}
            className="w-full flex items-center gap-2 px-3 py-1.5 text-xs text-muted-foreground hover:text-foreground rounded hover:bg-muted"
          >
            <LogOut className="w-3.5 h-3.5" />
            Odhlásit se
          </button>
        </div>
      </aside>

      <main className="flex-1 overflow-auto">
        <div className="p-6 max-w-3xl mx-auto">
          <Outlet />
        </div>
      </main>
    </div>
  )
}
```

### 20.2–20.5 Contributor stránky

> Kompletní kód pro `ContributorDashboard`, `ContributorPoiListPage`,
> `ContributorPoiEditorPage` a `ContributorProfilePage` viz sekce DA-012 až DA-015
> v diff-specification-admin-001.md.
>
> **Jedinou změnou** je branding – PlaceSecrets místo HeroDots.
> Všechny Supabase importy používají **anon `supabase` klient** (ne supabaseAdmin).

---

## 21. Sdílené komponenty

### 21.1 DataTable (TanStack Table wrapper)
> Kompletní kód viz sekce 19.1.1 z původní spec.

### 21.2 StatusBadge / ActiveBadge
> Kompletní kód viz sekce 19.1.2 z původní spec.

### 21.3 ConfirmDialog
> Kompletní kód viz sekce 19.1.3 z původní spec.

### 21.4 ToastProvider
> Kompletní kód viz sekce 19.1.4 z původní spec.

### 21.5 MapPicker (lazy Leaflet)
> Kompletní kód viz sekce 10.3 z původní spec.

### 21.6 MaterialIcon (pro POI typy)

```typescript
// src/lib/poi-type-icons.ts
// Přidat do index.html:
// <link href="https://fonts.googleapis.com/icon?family=Material+Icons" rel="stylesheet">

export function MaterialIcon({ name, color, size = 20 }: {
  name: string; color?: string; size?: number
}) {
  return (
    <span className="material-icons select-none"
      style={{ fontSize: size, color: color ?? 'currentColor', lineHeight: 1 }}>
      {name}
    </span>
  )
}
```

---

## 22. Edge Functions

### 22.1 Přehled Edge Functions

| Funkce | Účel | Spouštěč |
|---|---|---|
| `verify-admin-pin` | Ověří 6místný PIN (bcrypt) | AdminPinPage |
| `change-admin-pin` | Změní PIN | ChangePinForm |
| `confirm-payment` | Potvrdí platbu, email receipt | Mobilní app |
| `generate-receipt` | PDF doklad + email | Admin + mobilní app |
| `stripe-refund` | Vrátí platbu přes Stripe | Admin |
| `delete-user-data` | GDPR kaskádové smazání | Admin |
| `invite-contributor` | Pozvánkový email | Admin |

### 22.2 Deploy a secrets

```bash
# Deploy všech funkcí
supabase functions deploy verify-admin-pin
supabase functions deploy change-admin-pin
supabase functions deploy confirm-payment
supabase functions deploy generate-receipt
supabase functions deploy stripe-refund
supabase functions deploy delete-user-data
supabase functions deploy invite-contributor

# Secrets
supabase secrets set RESEND_API_KEY=re_...
supabase secrets set STRIPE_SECRET_KEY=sk_live_...
supabase secrets set STRIPE_WEBHOOK_SECRET=whsec_...

# Storage buckety
supabase storage create payment-receipts    # private
supabase storage create poi-photos          # public
supabase storage create audio-guides        # public
```

---

## 23. Roadmapa implementace

| # | Krok | Výstup |
|---|---|---|
| **Základy** | | |
| 1 | DB migrace 003–009 + storage buckety | Tabulky a funkce existují |
| 2 | Vite bootstrap + Tailwind + shadcn | `npm run dev` funguje |
| 3 | Dva Supabase klienti + .env.local | Připojení k DB ověřeno |
| **Auth systém** | | |
| 4a | useAuth Zustand store (role + adminVerified) | Store funguje |
| 4b | LoginPage – krok 1 (email + heslo + role detekce) | Login přesměrovává dle role |
| 4c | AdminPinPage – krok 2 (PIN vstup + Edge Function) | Admini zadají PIN |
| 4d | AdminGuard + AuthGuard + RoleGuard | Routes chráněny |
| 4e | verify-admin-pin + change-admin-pin Edge Functions | PIN ověřování funguje |
| **Admin portál** | | |
| 5 | AppShell – Sidebar (role-aware) + Header | Navigace funguje |
| 6 | DashboardPage + MetricCard + grafy | Metriky a grafy zobrazují data |
| 7 | CitiesPage + CityForm + MapPicker (lazy) | CRUD měst funguje |
| 8 | PoisPage + sort_order + toggle | Seznam POI s řazením |
| 9 | PoiNewPage + PoiEditPage + PoiForm (vícejazyčný) | CRUD POI |
| 10 | PhotoUploader + AudioUploader | Soubory v Supabase Storage |
| 10a | DB migrace 006 + PoiTypesPage + PoiTypeModal | CRUD typů POI |
| 11 | UsersPage + UserDetailPage + AccessGrantModal | Správa uživatelů |
| 12 | PaymentsPage + filtry + export CSV | Tabulka plateb |
| 13 | PaymentDetailPage + Revolut confirm + Stripe Refund | Detail transakce |
| 14 | generate-receipt + PDF + email | Doklady fungují |
| 15 | ContributorsPage + ContributorDetailPage | Správa průvodců |
| 16 | HallOfFamePage | Žebříčky fungují |
| **Nastavení** | | |
| 17 | SettingsPage – platby + admin správa + PIN | Konfigurace uložena |
| 17a | ChangePinForm | PIN lze měnit v profilu |
| **Contributor portál** | | |
| 18 | ContributorShell | Contributor portál se zobrazuje |
| 18a | ContributorRegisterPage (/register/contributor) | Registrace průvodce |
| 18b | ContributorDashboard | Přehled průvodce |
| 18c | ContributorPoiListPage | Vidí jen svá POI (RLS) |
| 18d | ContributorPoiEditorPage | Editace textu POI |
| 18e | ContributorProfilePage | Editace profilu |
| **Edge Functions** | | |
| 19 | invite-contributor Edge Function | Pozvánkové emaily |
| 20 | delete-user-data Edge Function | GDPR smazání |
| **Produkce** | | |
| 21 | `npm run build` + deploy Netlify/Vercel | Produkce na placesecrets.app |

---

## Přehled souborů k vytvoření (nové oproti původní spec)

```
src/pages/AdminPinPage.tsx                ← krok 2 přihlášení (PIN)
src/components/layout/AdminGuard.tsx      ← přepis (email + PIN)
src/components/settings/ChangePinForm.tsx ← změna PIN v Nastavení

supabase/functions/verify-admin-pin/index.ts
supabase/functions/change-admin-pin/index.ts

Přejmenování v brandu:
  "HeroDots Admin" → "PlaceSecrets"
  "HD-YYYY-NNNN"   → "PS-YYYY-NNNN" (čísla dokladů)
  noreply@herodots.app → noreply@placesecrets.app
  admin.herodots.app   → placesecrets.app (nebo admin.placesecrets.app)
```

---

## Checklist před spuštěním

```
PREREKVIZITY:
  ✅ Supabase projekt (dev + prod)
  ✅ Migrace 001 + 002 (základní schéma z mobilní app)

NOVÉ PRO WEB:
  1. Spustit migrace 003–009 v pořadí
  2. Vytvořit storage buckety: poi-photos, audio-guides, payment-receipts
  3. Nastavit secrets (RESEND_API_KEY, STRIPE_SECRET_KEY)
  4. Nasadit Edge Functions (verify-admin-pin, change-admin-pin, ostatní)
  5. Vytvořit prvního superadmina:
       a) Supabase Dashboard → Auth → Users → Invite
       b) Zkopírovat UUID
       c) INSERT INTO public.admin_users (user_id, role) VALUES ('uuid', 'superadmin');
  6. npm create vite + npm install
  7. .env.local naplnit (URL, SERVICE_ROLE_KEY, ANON_KEY)
  8. npm run dev → přihlásit → zadat PIN (první přihlášení PIN vytvoří)
  9. npm run build → deploy na Netlify / Vercel
  10. Nastavit vlastní doménu (placesecrets.app nebo admin.placesecrets.app)
```
