# Specifikace administračního rozhraní – HeroDots Admin

> **Verze:** 2.0 (přepsáno na Vite + React)
> **Platforma:** Vite + React 18 + TypeScript + Tailwind CSS + Supabase
> **Sdílí:** stejnou Supabase DB jako mobilní app (`specification-prompts.md`)
> **Deploy:** Netlify / Vercel (statický build) → `admin.herodots.app`
> **Backend:** Supabase (service_role přímý klient) + Supabase Edge Functions pro citlivé operace

---

## 0. Architektura – proč Vite bez Next.js/Express

```
┌─────────────────────────────────────────────────┐
│  Vite + React + Tailwind                        │
│  (SPA – statický build, žádný vlastní server)   │
│                                                  │
│  Přímé volání Supabase přes service_role klient │
│  (jen z admin panelu za auth guardou)           │
└────────────────┬────────────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────────────┐
│  Supabase                                       │
│  ├── Auth (admin_users tabulka)                 │
│  ├── PostgreSQL (cities, pois, users, payments) │
│  ├── Storage (poi-photos, audio-guides,         │
│  │            payment-receipts)                 │
│  └── Edge Functions (citlivé operace):          │
│       ├── generate-receipt (PDF + email)        │
│       ├── confirm-payment  (Revolut potvrzení)  │
│       ├── delete-user-data (GDPR kaskáda)       │
│       └── migrate-anonymous-data               │
└─────────────────────────────────────────────────┘
```

**Proč ne Express:**
- Supabase Edge Functions pokrývají veškerou serverovou logiku (PDF, email, auth admin operace)
- Admin SPA nepotřebuje SSR ani SEO
- Jednodušší deploy – jen `vite build` → statické soubory

**Proč ne Next.js:**
- Server Actions a SSR jsou overkill pro interní admin nástroj
- Vite je výrazně rychlejší při vývoji (HMR)
- Méně abstrakce = méně míst kde může dojít k chybě

---

## 1. OPRAVA MOBILNÍ APLIKACE – platební doklady

> Tato sekce popisuje mezery nalezené v mobilní app a jejich opravu.
> Musí být implementována souběžně s admin panelem.

### 1.1 Co mobilní app nemá

| Chybějící funkce | Dopad |
|---|---|
| ❌ Zobrazení zaplacené částky | Uživatel neví kolik zaplatil |
| ❌ Metoda platby v historii | Není vidět Revolut vs karta |
| ❌ `transaction_id` pro Revolut = vždy `null` | Žádný doklad pro reklamaci |
| ❌ PDF potvrzení o platbě | Nutné pro EU spotřebitelské právo |
| ❌ Email po úspěšné platbě | Uživatel nemá žádný doklad |
| ❌ `UNIQUE(user_id, city_id)` = jen poslední platba | Nelze doložit historii |

### 1.2 Nová tabulka `payment_receipts`

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
  receipt_number   TEXT UNIQUE,          -- HD-2024-0001
  receipt_pdf_url  TEXT,
  receipt_sent_at  TIMESTAMPTZ,
  created_at       TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Auto-generování čísla dokladu
CREATE OR REPLACE FUNCTION public.generate_receipt_number()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
  IF NEW.receipt_number IS NULL THEN
    NEW.receipt_number := 'HD-' || TO_CHAR(NOW(), 'YYYY') || '-'
      || LPAD(nextval('public.receipt_number_seq')::TEXT, 4, '0');
  END IF;
  RETURN NEW;
END;
$$;

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

### 1.3 Oprava Flutter – PaymentHistorySection

```dart
// Nahradit "Zakoupené oblasti" ListTile v SettingsScreen

@riverpod
Future<List<PaymentReceipt>> paymentReceipts(PaymentReceiptsRef ref) async {
  final userId = Supabase.instance.client.auth.currentUser?.id;
  if (userId == null) return [];
  final response = await Supabase.instance.client
    .from('payment_receipts')
    .select('*, cities(name)')
    .eq('user_id', userId)
    .eq('status', 'completed')
    .order('purchased_at', ascending: false);
  return (response as List).map(PaymentReceipt.fromJson).toList();
}

class PaymentHistorySection extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref.watch(paymentReceiptsProvider).when(
      data: (receipts) => Column(children: [
        const ListTile(leading: Icon(Icons.receipt_long), title: Text('Moje platby')),
        if (receipts.isEmpty)
          const Padding(padding: EdgeInsets.all(16),
            child: Text('Žádné platby', style: TextStyle(color: Colors.grey))),
        ...receipts.map((r) => ListTile(
          leading: _methodIcon(r.paymentMethod),
          title: Text(r.cityName),
          subtitle: Text('${r.amountEur.toStringAsFixed(2)} € · '
            '${DateFormat('d. M. yyyy').format(r.purchasedAt)} · ${r.receiptNumber}'),
          trailing: IconButton(
            icon: const Icon(Icons.download),
            onPressed: r.receiptPdfUrl != null
              ? () => launchUrl(Uri.parse(r.receiptPdfUrl!))
              : () => _requestReceipt(context, r.id),
          ),
        )),
      ]),
      loading: () => const LinearProgressIndicator(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}
```

### 1.4 Edge Function `confirm-payment` – nahrazuje `payment-webhook`

```typescript
// supabase/functions/confirm-payment/index.ts
// Volat z mobilní app po každé úspěšné platbě místo původního payment-webhook

serve(async (req) => {
  const { user_id, city_id, payment_method, transaction_id, amount_eur } = await req.json()
  const supabase = createClient(SUPABASE_URL, SERVICE_ROLE_KEY)

  // 1. Upsert přístup k oblasti
  await supabase.from('user_access').upsert({
    user_id, city_id, payment_method, transaction_id, amount_eur, valid_until: null
  })

  // 2. Vytvořit auditní receipt záznam
  const { data: receipt } = await supabase.from('payment_receipts').insert({
    user_id, city_id, payment_method, transaction_id, amount_eur, status: 'completed'
  }).select().single()

  // 3. Email potvrzení přes Resend
  const { data: { user } } = await supabase.auth.admin.getUserById(user_id)
  const { data: city } = await supabase.from('cities').select('name').eq('id', city_id).single()

  if (user?.email) {
    await fetch('https://api.resend.com/emails', {
      method: 'POST',
      headers: { Authorization: `Bearer ${Deno.env.get('RESEND_API_KEY')}`, 'Content-Type': 'application/json' },
      body: JSON.stringify({
        from: 'HeroDots <noreply@herodots.app>',
        to: user.email,
        subject: `Potvrzení platby ${receipt.receipt_number} – HeroDots`,
        html: `<h2>Děkujeme za váš nákup!</h2>
          <p>Doklad č.: <strong>${receipt.receipt_number}</strong></p>
          <p>Oblast: <strong>${city.name}</strong></p>
          <p>Částka: <strong>${amount_eur} EUR</strong></p>
          <p>PDF potvrzení bude dostupné v nastavení aplikace.</p>`
      })
    })
  }

  // 4. Spustit PDF generování async
  supabase.functions.invoke('generate-receipt', { body: { receipt_id: receipt.id } })

  return new Response(JSON.stringify({ success: true }), { status: 200 })
})
```

---

## 2. Instalace projektu

```bash
# 1. Vytvořit Vite projekt
npm create vite@latest herodots-admin -- --template react-ts
cd herodots-admin

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
  date-fns \
  lucide-react \
  react-leaflet leaflet \
  @types/leaflet \
  react-dropzone \
  clsx \
  tailwind-merge

# 4. shadcn/ui (funguje s Vite)
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

### 2.1 `tailwind.config.ts`

```typescript
import type { Config } from 'tailwindcss'

export default {
  darkMode: ['class'],
  content: ['./index.html', './src/**/*.{ts,tsx}'],
  theme: {
    extend: {
      colors: {
        primary: { DEFAULT: '#2D6A4F', foreground: '#ffffff' },
        gold: '#B8960C',
      },
    },
  },
  plugins: [],
} satisfies Config
```

### 2.2 `vite.config.ts`

```typescript
import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'
import path from 'path'

export default defineConfig({
  plugins: [react()],
  resolve: {
    alias: { '@': path.resolve(__dirname, './src') },
  },
})
```

### 2.3 Proměnné prostředí

```bash
# .env.local
VITE_SUPABASE_URL=https://YOUR_PROJECT.supabase.co
VITE_SUPABASE_SERVICE_ROLE_KEY=eyJ...   # jen admin panel, NIKDY do mobilní app
VITE_APP_URL=https://admin.herodots.app
```

---

## 3. Struktura projektu

```
herodots-admin/
├── index.html
├── vite.config.ts
├── tailwind.config.ts
├── .env.local
├── src/
│   ├── main.tsx                        ← entry point
│   ├── App.tsx                         ← router setup
│   ├── lib/
│   │   ├── supabase/
│   │   │   ├── client.ts               ← service_role klient
│   │   │   └── types.ts                ← generované Supabase typy
│   │   └── utils.ts                    ← cn(), formátování
│   ├── hooks/
│   │   ├── useAuth.ts                  ← přihlášení, session
│   │   └── useToast.ts
│   ├── components/
│   │   ├── layout/
│   │   │   ├── AppShell.tsx            ← Sidebar + Header + outlet
│   │   │   ├── Sidebar.tsx
│   │   │   ├── Header.tsx
│   │   │   └── AuthGuard.tsx           ← redirect nepřihlášených
│   │   ├── shared/
│   │   │   ├── DataTable.tsx           ← TanStack Table wrapper
│   │   │   ├── Pagination.tsx
│   │   │   ├── StatusBadge.tsx
│   │   │   ├── ConfirmDialog.tsx
│   │   │   └── MapPicker.tsx           ← Leaflet, lazy import
│   │   ├── cities/
│   │   │   ├── CityForm.tsx
│   │   │   └── CityTable.tsx
│   │   ├── pois/
│   │   │   ├── PoiForm.tsx
│   │   │   ├── PoiTable.tsx
│   │   │   ├── AudioUploader.tsx
│   │   │   └── PhotoUploader.tsx
│   │   ├── users/
│   │   │   ├── UserTable.tsx
│   │   │   ├── UserDetail.tsx
│   │   │   └── AccessGrantModal.tsx
│   │   ├── payments/
│   │   │   ├── PaymentTable.tsx
│   │   │   ├── PaymentDetail.tsx
│   │   │   └── ReceiptActions.tsx
│   │   └── dashboard/
│   │       ├── MetricCard.tsx
│   │       ├── RevenueChart.tsx
│   │       └── ActivityChart.tsx
│   └── pages/
│       ├── LoginPage.tsx
│       ├── DashboardPage.tsx
│       ├── cities/
│       │   ├── CitiesPage.tsx
│       │   ├── CityNewPage.tsx
│       │   └── CityEditPage.tsx
│       ├── pois/
│       │   ├── PoisPage.tsx
│       │   ├── PoiNewPage.tsx
│       │   └── PoiEditPage.tsx
│       ├── users/
│       │   ├── UsersPage.tsx
│       │   └── UserDetailPage.tsx
│       ├── payments/
│       │   ├── PaymentsPage.tsx
│       │   └── PaymentDetailPage.tsx
│       └── SettingsPage.tsx
```

---

## 4. Supabase klient

```typescript
// src/lib/supabase/client.ts
import { createClient } from '@supabase/supabase-js'
import type { Database } from './types'

// Service role – plný přístup k DB, jen pro admin panel
// Uloženo v .env.local – nikdy v mobilní app ani veřejném repozitáři
export const supabase = createClient<Database>(
  import.meta.env.VITE_SUPABASE_URL,
  import.meta.env.VITE_SUPABASE_SERVICE_ROLE_KEY,
  {
    auth: { persistSession: true, autoRefreshToken: true },
    db: { schema: 'public' },
  }
)
```

---

## 5. Routing a AuthGuard

```tsx
// src/App.tsx
import { BrowserRouter, Routes, Route, Navigate } from 'react-router-dom'
import { AuthGuard } from '@/components/layout/AuthGuard'
import { AppShell } from '@/components/layout/AppShell'
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

export default function App() {
  return (
    <BrowserRouter>
      <Routes>
        <Route path="/login" element={<LoginPage />} />
        <Route element={<AuthGuard />}>
          <Route element={<AppShell />}>
            <Route index element={<Navigate to="/dashboard" replace />} />
            <Route path="/dashboard" element={<DashboardPage />} />
            <Route path="/cities" element={<CitiesPage />} />
            <Route path="/cities/new" element={<CityNewPage />} />
            <Route path="/cities/:id" element={<CityEditPage />} />
            <Route path="/cities/:cityId/pois" element={<PoisPage />} />
            <Route path="/cities/:cityId/pois/new" element={<PoiNewPage />} />
            <Route path="/cities/:cityId/pois/:poiId" element={<PoiEditPage />} />
            <Route path="/users" element={<UsersPage />} />
            <Route path="/users/:id" element={<UserDetailPage />} />
            <Route path="/payments" element={<PaymentsPage />} />
            <Route path="/payments/:id" element={<PaymentDetailPage />} />
            <Route path="/settings" element={<SettingsPage />} />
          </Route>
        </Route>
        <Route path="*" element={<Navigate to="/dashboard" replace />} />
      </Routes>
    </BrowserRouter>
  )
}
```

```tsx
// src/components/layout/AuthGuard.tsx
import { useEffect, useState } from 'react'
import { Navigate, Outlet } from 'react-router-dom'
import { supabase } from '@/lib/supabase/client'

export function AuthGuard() {
  const [status, setStatus] = useState<'loading' | 'ok' | 'unauthorized'>('loading')

  useEffect(() => {
    async function check() {
      const { data: { session } } = await supabase.auth.getSession()
      if (!session) { setStatus('unauthorized'); return }

      // Ověřit že je v admin_users tabulce
      const { data } = await supabase
        .from('admin_users')
        .select('role')
        .eq('user_id', session.user.id)
        .single()

      setStatus(data ? 'ok' : 'unauthorized')
    }
    check()

    const { data: { subscription } } = supabase.auth.onAuthStateChange((_, session) => {
      if (!session) setStatus('unauthorized')
    })
    return () => subscription.unsubscribe()
  }, [])

  if (status === 'loading') return (
    <div className="h-screen flex items-center justify-center">
      <div className="animate-spin w-8 h-8 border-4 border-primary border-t-transparent rounded-full" />
    </div>
  )

  return status === 'ok' ? <Outlet /> : <Navigate to="/login" replace />
}
```

---

## 6. DB – tabulka admin_users a SQL rozšíření

```sql
-- supabase/migrations/004_admin_users.sql

CREATE TABLE public.admin_users (
  id         UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id    UUID NOT NULL UNIQUE REFERENCES auth.users(id) ON DELETE CASCADE,
  role       TEXT NOT NULL DEFAULT 'editor'
    CHECK (role IN ('superadmin', 'editor', 'viewer')),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
ALTER TABLE public.admin_users ENABLE ROW LEVEL SECURITY;
-- Pouze service_role vidí tabulku (admin klient ji čte přes service_role)
CREATE POLICY "admin_service_only" ON public.admin_users
  USING (auth.role() = 'service_role');

-- První admin ručně po prvním nasazení:
-- INSERT INTO public.admin_users (user_id, role) VALUES ('uuid-z-auth.users', 'superadmin');
```

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

-- Denní aktivita
CREATE OR REPLACE FUNCTION public.daily_activity(days_back INTEGER DEFAULT 30)
RETURNS TABLE(day TEXT, visits BIGINT, new_users BIGINT)
LANGUAGE sql SECURITY DEFINER AS $$
  SELECT TO_CHAR(d.day, 'YYYY-MM-DD'), COALESCE(v.visits,0), COALESCE(u.new_users,0)
  FROM generate_series(CURRENT_DATE-(days_back||' days')::INTERVAL, CURRENT_DATE, '1 day'::INTERVAL) d(day)
  LEFT JOIN (SELECT DATE(visited_at) day, COUNT(*) visits FROM public.free_visit_log GROUP BY 1) v ON v.day=d.day
  LEFT JOIN (SELECT DATE(created_at) day, COUNT(*) new_users FROM auth.users WHERE is_anonymous=FALSE GROUP BY 1) u ON u.day=d.day
  ORDER BY d.day;
$$;

-- Top navštívená POI
CREATE OR REPLACE FUNCTION public.top_visited_pois(limit_count INTEGER DEFAULT 10)
RETURNS TABLE(poi_id UUID, poi_name JSONB, city_name TEXT, visit_count BIGINT)
LANGUAGE sql SECURITY DEFINER AS $$
  SELECT p.id, p.name, c.name, COUNT(fvl.id)
  FROM public.pois p JOIN public.cities c ON c.id=p.city_id
  LEFT JOIN public.free_visit_log fvl ON fvl.poi_id=p.id
  WHERE p.is_active=TRUE GROUP BY p.id, p.name, c.name
  ORDER BY 4 DESC LIMIT limit_count;
$$;

-- Souhrn plateb s filtry
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

-- Admin stats view (doplnit o pending_revolut)
CREATE OR REPLACE VIEW public.admin_stats AS SELECT
  (SELECT COUNT(*) FROM auth.users WHERE is_anonymous=FALSE) AS registered_users,
  (SELECT COUNT(*) FROM auth.users WHERE is_anonymous=TRUE)  AS anonymous_users,
  (SELECT COUNT(*) FROM public.pois WHERE is_active=TRUE)    AS active_pois,
  (SELECT COUNT(*) FROM public.cities WHERE is_active=TRUE)  AS active_cities,
  (SELECT COUNT(*) FROM public.user_access)                  AS total_purchases,
  (SELECT COALESCE(SUM(amount_eur),0) FROM public.payment_receipts WHERE status='completed') AS total_revenue_eur,
  (SELECT COUNT(*) FROM public.free_visit_log WHERE year_month=TO_CHAR(NOW(),'YYYY-MM')) AS free_visits_this_month,
  (SELECT COUNT(*) FROM public.payment_receipts WHERE payment_method='revolut' AND status='pending') AS pending_revolut;

-- Admin users view pro seznam uživatelů
CREATE OR REPLACE VIEW public.admin_users_view AS
SELECT u.id, u.email, u.is_anonymous, u.created_at, u.last_sign_in_at, u.email_confirmed_at,
  COUNT(DISTINCT ua.id) AS access_count,
  COALESCE(SUM(pr.amount_eur) FILTER (WHERE pr.status='completed'), 0) AS total_spent
FROM auth.users u
LEFT JOIN public.user_access ua ON ua.user_id=u.id
LEFT JOIN public.payment_receipts pr ON pr.user_id=u.id
GROUP BY u.id, u.email, u.is_anonymous, u.created_at, u.last_sign_in_at, u.email_confirmed_at;

GRANT EXECUTE ON FUNCTION public.revenue_by_month TO service_role;
GRANT EXECUTE ON FUNCTION public.daily_activity TO service_role;
GRANT EXECUTE ON FUNCTION public.top_visited_pois TO service_role;
GRANT EXECUTE ON FUNCTION public.payment_summary TO service_role;
GRANT SELECT ON public.admin_stats TO service_role;
GRANT SELECT ON public.admin_users_view TO service_role;
```

---

## 7. Login

```tsx
// src/pages/LoginPage.tsx
import { useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { supabase } from '@/lib/supabase/client'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { MapPin } from 'lucide-react'

export function LoginPage() {
  const navigate = useNavigate()
  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')
  const [error, setError] = useState('')
  const [loading, setLoading] = useState(false)

  async function handleLogin(e: React.FormEvent) {
    e.preventDefault()
    setLoading(true)
    setError('')

    const { data, error: authError } = await supabase.auth.signInWithPassword({ email, password })
    if (authError) { setError('Nesprávné přihlašovací údaje'); setLoading(false); return }

    // Ověřit admin roli
    const { data: admin } = await supabase
      .from('admin_users').select('role').eq('user_id', data.user.id).single()

    if (!admin) { setError('Nemáte přístup do admin panelu'); setLoading(false); return }

    navigate('/dashboard')
  }

  return (
    <div className="min-h-screen bg-muted flex items-center justify-center">
      <Card className="w-full max-w-sm">
        <CardHeader className="text-center">
          <div className="w-12 h-12 bg-primary rounded-xl flex items-center justify-center mx-auto mb-3">
            <MapPin className="w-6 h-6 text-white" />
          </div>
          <CardTitle>HeroDots Admin</CardTitle>
        </CardHeader>
        <CardContent>
          <form onSubmit={handleLogin} className="space-y-4">
            <div>
              <Label>Email</Label>
              <Input type="email" value={email} onChange={e => setEmail(e.target.value)} required />
            </div>
            <div>
              <Label>Heslo</Label>
              <Input type="password" value={password} onChange={e => setPassword(e.target.value)} required />
            </div>
            {error && <p className="text-sm text-red-500">{error}</p>}
            <Button type="submit" className="w-full" disabled={loading}>
              {loading ? 'Přihlašuji...' : 'Přihlásit se'}
            </Button>
          </form>
        </CardContent>
      </Card>
    </div>
  )
}
```

---

## 8. Layout – AppShell a Sidebar

```tsx
// src/components/layout/AppShell.tsx
import { Outlet } from 'react-router-dom'
import { Sidebar } from './Sidebar'
import { Header } from './Header'

export function AppShell() {
  return (
    <div className="flex h-screen bg-background overflow-hidden">
      <Sidebar />
      <div className="flex-1 flex flex-col min-w-0">
        <Header />
        <main className="flex-1 overflow-y-auto p-6">
          <Outlet />
        </main>
      </div>
    </div>
  )
}

// src/components/layout/Sidebar.tsx
import { NavLink } from 'react-router-dom'
import { LayoutDashboard, MapPin, Users, CreditCard, Settings } from 'lucide-react'
import { cn } from '@/lib/utils'

const NAV = [
  { to: '/dashboard', icon: LayoutDashboard, label: 'Dashboard' },
  { to: '/cities', icon: MapPin, label: 'Oblasti & POI' },
  { to: '/users', icon: Users, label: 'Uživatelé' },
  { to: '/payments', icon: CreditCard, label: 'Platby' },
  { to: '/settings', icon: Settings, label: 'Nastavení' },
]

export function Sidebar() {
  return (
    <aside className="w-56 bg-card border-r flex flex-col shrink-0">
      {/* Logo */}
      <div className="p-4 border-b flex items-center gap-3">
        <div className="w-8 h-8 bg-primary rounded-lg flex items-center justify-center">
          <MapPin className="w-4 h-4 text-white" />
        </div>
        <div className="leading-none">
          <p className="font-bold text-sm">HeroDots</p>
          <p className="text-xs text-muted-foreground">Admin</p>
        </div>
      </div>

      {/* Navigace */}
      <nav className="flex-1 p-3 space-y-1">
        {NAV.map(({ to, icon: Icon, label }) => (
          <NavLink key={to} to={to} className={({ isActive }) =>
            cn('flex items-center gap-3 px-3 py-2 rounded-md text-sm transition-colors',
              isActive
                ? 'bg-primary text-primary-foreground font-medium'
                : 'text-muted-foreground hover:bg-muted hover:text-foreground')
          }>
            <Icon className="w-4 h-4" />
            {label}
          </NavLink>
        ))}
      </nav>

      {/* Odhlášení */}
      <div className="p-3 border-t">
        <AdminUserMenu />
      </div>
    </aside>
  )
}

// src/components/layout/Header.tsx
import { useLocation } from 'react-router-dom'

const TITLES: Record<string, string> = {
  '/dashboard': 'Dashboard',
  '/cities': 'Oblasti & POI',
  '/users': 'Uživatelé',
  '/payments': 'Platby',
  '/settings': 'Nastavení',
}

export function Header() {
  const { pathname } = useLocation()
  const title = Object.entries(TITLES).find(([k]) => pathname.startsWith(k))?.[1] ?? 'HeroDots Admin'
  return (
    <header className="h-14 border-b flex items-center px-6 bg-card shrink-0">
      <h1 className="font-semibold">{title}</h1>
    </header>
  )
}
```

---

## 9. Dashboard

```tsx
// src/pages/DashboardPage.tsx
import { useEffect, useState } from 'react'
import { supabase } from '@/lib/supabase/client'
import { MetricCard } from '@/components/dashboard/MetricCard'
import { RevenueChart } from '@/components/dashboard/RevenueChart'
import { ActivityChart } from '@/components/dashboard/ActivityChart'

export function DashboardPage() {
  const [stats, setStats] = useState<any>(null)
  const [revenue, setRevenue] = useState<any[]>([])
  const [activity, setActivity] = useState<any[]>([])
  const [topPois, setTopPois] = useState<any[]>([])
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    async function load() {
      const [s, r, a, t] = await Promise.all([
        supabase.from('admin_stats').select('*').single(),
        supabase.rpc('revenue_by_month', { months_back: 12 }),
        supabase.rpc('daily_activity', { days_back: 30 }),
        supabase.rpc('top_visited_pois', { limit_count: 10 }),
      ])
      setStats(s.data)
      setRevenue(r.data ?? [])
      setActivity(a.data ?? [])
      setTopPois(t.data ?? [])
      setLoading(false)
    }
    load()
  }, [])

  if (loading) return <DashboardSkeleton />

  return (
    <div className="space-y-6">
      {/* Metriky */}
      <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
        <MetricCard title="Registrovaní uživatelé" value={stats?.registered_users} icon="users" />
        <MetricCard title="Celkové tržby" value={`${stats?.total_revenue_eur ?? 0} €`} icon="euro" color="green" />
        <MetricCard title="Počet nákupů" value={stats?.total_purchases} icon="credit-card" />
        <MetricCard title="Čeká potvrzení" value={stats?.pending_revolut} icon="clock" color="orange" />
        <MetricCard title="Aktivní POI" value={stats?.active_pois} icon="map-pin" />
        <MetricCard title="Aktivní oblasti" value={stats?.active_cities} icon="map" />
        <MetricCard title="Anonymní uživatelé" value={stats?.anonymous_users} icon="ghost" />
        <MetricCard title="Free návštěvy (měsíc)" value={stats?.free_visits_this_month} icon="eye" />
      </div>

      {/* Grafy */}
      <div className="grid md:grid-cols-2 gap-6">
        <RevenueChart data={revenue} />
        <ActivityChart data={activity} />
      </div>

      {/* Top POI tabulka */}
      <TopPoisTable data={topPois} />
    </div>
  )
}
```

```tsx
// src/components/dashboard/MetricCard.tsx
import { Card, CardContent } from '@/components/ui/card'
import { Users, Euro, CreditCard, Clock, MapPin, Map, Ghost, Eye } from 'lucide-react'
import { cn } from '@/lib/utils'

const ICONS = { users: Users, euro: Euro, 'credit-card': CreditCard, clock: Clock,
  'map-pin': MapPin, map: Map, ghost: Ghost, eye: Eye }

interface MetricCardProps {
  title: string; value: string | number | null | undefined
  icon: keyof typeof ICONS; color?: 'default' | 'green' | 'orange'
}

export function MetricCard({ title, value, icon, color = 'default' }: MetricCardProps) {
  const Icon = ICONS[icon]
  return (
    <Card>
      <CardContent className="pt-6 flex items-start justify-between">
        <div>
          <p className="text-sm text-muted-foreground">{title}</p>
          <p className={cn('text-2xl font-bold mt-1',
            color === 'green' && 'text-green-600',
            color === 'orange' && 'text-orange-500'
          )}>
            {value ?? '—'}
          </p>
        </div>
        <div className="p-2 bg-muted rounded-lg">
          <Icon className="w-5 h-5 text-muted-foreground" />
        </div>
      </CardContent>
    </Card>
  )
}
```

```tsx
// src/components/dashboard/RevenueChart.tsx
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { BarChart, Bar, XAxis, YAxis, Tooltip, ResponsiveContainer } from 'recharts'

export function RevenueChart({ data }: { data: { month: string; revenue: number }[] }) {
  return (
    <Card>
      <CardHeader><CardTitle>Tržby po měsících</CardTitle></CardHeader>
      <CardContent>
        <ResponsiveContainer width="100%" height={200}>
          <BarChart data={data}>
            <XAxis dataKey="month" tick={{ fontSize: 11 }} />
            <YAxis tick={{ fontSize: 11 }} unit=" €" />
            <Tooltip formatter={(v: number) => [`${v} €`, 'Tržby']} />
            <Bar dataKey="revenue" fill="#2D6A4F" radius={[4, 4, 0, 0]} />
          </BarChart>
        </ResponsiveContainer>
      </CardContent>
    </Card>
  )
}
```

---

## 10. Správa měst a POI

### 10.1 CitiesPage

```tsx
// src/pages/cities/CitiesPage.tsx
import { useEffect, useState } from 'react'
import { Link } from 'react-router-dom'
import { supabase } from '@/lib/supabase/client'
import { Button } from '@/components/ui/button'
import { Badge } from '@/components/ui/badge'
import { DataTable } from '@/components/shared/DataTable'
import { ColumnDef } from '@tanstack/react-table'
import { Plus, Pencil, ToggleLeft } from 'lucide-react'
import { format } from 'date-fns'

export function CitiesPage() {
  const [cities, setCities] = useState<any[]>([])

  useEffect(() => {
    supabase.from('cities').select('*, pois(count)').order('name').then(({ data }) => setCities(data ?? []))
  }, [])

  const columns: ColumnDef<any>[] = [
    { accessorKey: 'name', header: 'Název' },
    { accessorKey: 'country', header: 'Stát' },
    { accessorKey: 'price_eur', header: 'Cena', cell: ({ row }) => `${row.original.price_eur} €` },
    { id: 'pois', header: 'POI', cell: ({ row }) => row.original.pois?.[0]?.count ?? 0 },
    { accessorKey: 'is_active', header: 'Status',
      cell: ({ row }) => <Badge variant={row.original.is_active ? 'default' : 'secondary'}>
        {row.original.is_active ? 'Aktivní' : 'Neaktivní'}
      </Badge> },
    { id: 'actions', header: '',
      cell: ({ row }) => (
        <div className="flex gap-2">
          <Link to={`/cities/${row.original.id}`}><Button variant="ghost" size="sm"><Pencil className="w-4 h-4" /></Button></Link>
          <Link to={`/cities/${row.original.id}/pois`}><Button variant="outline" size="sm">POI</Button></Link>
        </div>
      )
    },
  ]

  return (
    <div className="space-y-4">
      <div className="flex justify-between items-center">
        <h2 className="text-xl font-bold">Oblasti</h2>
        <Link to="/cities/new"><Button><Plus className="w-4 h-4 mr-2" />Přidat oblast</Button></Link>
      </div>
      <DataTable columns={columns} data={cities} />
    </div>
  )
}
```

### 10.2 CityForm

```tsx
// src/components/cities/CityForm.tsx
import { useForm } from 'react-hook-form'
import { zodResolver } from '@hookform/resolvers/zod'
import { z } from 'zod'
import { supabase } from '@/lib/supabase/client'
import { useNavigate } from 'react-router-dom'
import { lazy, Suspense, useState } from 'react'

const MapPicker = lazy(() => import('@/components/shared/MapPicker'))

const schema = z.object({
  name: z.string().min(2),
  country: z.string().min(2),
  country_code: z.string().length(2),
  latitude: z.coerce.number().min(-90).max(90),
  longitude: z.coerce.number().min(-180).max(180),
  bounding_box_radius_km: z.coerce.number().min(1).max(200),
  price_eur: z.coerce.number().min(0),
  is_active: z.boolean().default(true),
})

export function CityForm({ city }: { city?: any }) {
  const navigate = useNavigate()
  const { register, handleSubmit, setValue, watch, formState: { errors, isSubmitting } } = useForm({
    resolver: zodResolver(schema),
    defaultValues: city ?? { is_active: true, bounding_box_radius_km: 5, price_eur: 1 },
  })

  async function onSubmit(values: any) {
    if (city) {
      await supabase.from('cities').update({ ...values, updated_at: new Date().toISOString() }).eq('id', city.id)
    } else {
      await supabase.from('cities').insert(values)
    }
    navigate('/cities')
  }

  const lat = watch('latitude')
  const lng = watch('longitude')
  const radius = watch('bounding_box_radius_km')

  return (
    <form onSubmit={handleSubmit(onSubmit)} className="space-y-6 max-w-2xl">
      <div className="grid grid-cols-2 gap-4">
        <Field label="Název" error={errors.name?.message}><input {...register('name')} className="input" /></Field>
        <Field label="Stát" error={errors.country?.message}><input {...register('country')} className="input" /></Field>
        <Field label="Kód státu (CZ)" error={errors.country_code?.message}>
          <input {...register('country_code')} maxLength={2} className="input uppercase" />
        </Field>
        <Field label="Cena (EUR)" error={errors.price_eur?.message}>
          <input {...register('price_eur')} type="number" step="0.01" className="input" />
        </Field>
        <Field label="Radius oblasti (km)" error={errors.bounding_box_radius_km?.message}>
          <input {...register('bounding_box_radius_km')} type="number" className="input" />
        </Field>
      </div>

      <div className="grid grid-cols-2 gap-4">
        <Field label="Latitude" error={errors.latitude?.message}>
          <input {...register('latitude')} type="number" step="0.000001" className="input" />
        </Field>
        <Field label="Longitude" error={errors.longitude?.message}>
          <input {...register('longitude')} type="number" step="0.000001" className="input" />
        </Field>
      </div>

      {/* Mapa – lazy load (Leaflet je velký balík) */}
      <Suspense fallback={<div className="h-64 bg-muted rounded-lg animate-pulse" />}>
        <MapPicker lat={lat} lng={lng} radiusKm={radius}
          onChange={(lat, lng) => { setValue('latitude', lat); setValue('longitude', lng) }} />
      </Suspense>

      <label className="flex items-center gap-2 cursor-pointer">
        <input {...register('is_active')} type="checkbox" />
        <span className="text-sm">Aktivní oblast</span>
      </label>

      <div className="flex gap-3">
        <button type="submit" disabled={isSubmitting}
          className="px-4 py-2 bg-primary text-white rounded-md text-sm disabled:opacity-50">
          {isSubmitting ? 'Ukládám...' : 'Uložit'}
        </button>
        <button type="button" onClick={() => navigate(-1)}
          className="px-4 py-2 border rounded-md text-sm">Zrušit</button>
      </div>
    </form>
  )
}
```

### 10.3 MapPicker – lazy loaded Leaflet

```tsx
// src/components/shared/MapPicker.tsx
// Tento soubor je lazy imported – Leaflet se nenačte pokud není potřeba
import { MapContainer, TileLayer, Marker, Circle, useMapEvents } from 'react-leaflet'
import 'leaflet/dist/leaflet.css'
import L from 'leaflet'

// Fix pro chybějící ikony v bundleru
delete (L.Icon.Default.prototype as any)._getIconUrl
L.Icon.Default.mergeOptions({
  iconRetinaUrl: 'https://cdnjs.cloudflare.com/ajax/libs/leaflet/1.9.4/images/marker-icon-2x.png',
  iconUrl: 'https://cdnjs.cloudflare.com/ajax/libs/leaflet/1.9.4/images/marker-icon.png',
  shadowUrl: 'https://cdnjs.cloudflare.com/ajax/libs/leaflet/1.9.4/images/marker-shadow.png',
})

function ClickHandler({ onChange }: { onChange: (lat: number, lng: number) => void }) {
  useMapEvents({ click: (e) => onChange(e.latlng.lat, e.latlng.lng) })
  return null
}

interface MapPickerProps {
  lat?: number; lng?: number; radiusKm?: number
  onChange: (lat: number, lng: number) => void
}

export default function MapPicker({ lat, lng, radiusKm = 1, onChange }: MapPickerProps) {
  const center: [number, number] = lat && lng ? [lat, lng] : [49.7475, 13.3776]
  return (
    <div className="h-64 rounded-lg overflow-hidden border">
      <MapContainer center={center} zoom={12} className="h-full w-full">
        <TileLayer url="https://tile.openstreetmap.org/{z}/{x}/{y}.png"
          attribution="© OpenStreetMap contributors" />
        <ClickHandler onChange={onChange} />
        {lat && lng && (
          <>
            <Marker position={[lat, lng]} />
            <Circle center={[lat, lng]} radius={radiusKm * 1000}
              color="#2D6A4F" fillColor="#2D6A4F" fillOpacity={0.1} weight={2} />
          </>
        )}
      </MapContainer>
    </div>
  )
}
```

### 10.4 PoiForm – vícejazyčný obsah

```tsx
// src/components/pois/PoiForm.tsx
import { useState, lazy, Suspense } from 'react'
import { useForm } from 'react-hook-form'
import { supabase } from '@/lib/supabase/client'
import { useNavigate } from 'react-router-dom'

const MapPicker = lazy(() => import('@/components/shared/MapPicker'))
const LANGS = ['cs', 'en', 'de'] as const

export function PoiForm({ cityId, poi }: { cityId: string; poi?: any }) {
  const navigate = useNavigate()
  const [activeLang, setActiveLang] = useState<'cs' | 'en' | 'de'>('cs')
  const { register, handleSubmit, setValue, watch } = useForm({
    defaultValues: poi ?? {
      name: { cs: '', en: '', de: '' },
      description: { cs: '', en: '', de: '' },
      geofence_radius: 100, is_premium: false, sort_order: 0, is_active: true,
    }
  })

  async function onSubmit(values: any) {
    if (poi) {
      await supabase.from('pois').update({ ...values, updated_at: new Date().toISOString() }).eq('id', poi.id)
    } else {
      await supabase.from('pois').insert({ ...values, city_id: cityId, photo_urls: [], audio_urls: {} })
    }
    navigate(`/cities/${cityId}/pois`)
  }

  return (
    <form onSubmit={handleSubmit(onSubmit)} className="space-y-6 max-w-2xl">

      {/* Jazyk tabs */}
      <div>
        <div className="flex border-b mb-4">
          {LANGS.map(l => (
            <button key={l} type="button" onClick={() => setActiveLang(l)}
              className={`px-4 py-2 text-sm font-medium border-b-2 transition-colors ${
                activeLang === l ? 'border-primary text-primary' : 'border-transparent text-muted-foreground'
              }`}>
              {l.toUpperCase()}
            </button>
          ))}
        </div>

        <Field label="Název">
          <input {...register(`name.${activeLang}`)} className="input w-full"
            placeholder={`Název v ${activeLang}`} />
        </Field>

        <Field label="Popis (text pro audioprůvodce / TTS)" className="mt-4">
          <textarea {...register(`description.${activeLang}`)} rows={7}
            className="input w-full resize-none"
            placeholder={`Popis v ${activeLang} – čte se jako audioprůvodce pokud chybí MP3`} />
        </Field>
      </div>

      {/* Souřadnice */}
      <div className="grid grid-cols-3 gap-4">
        <Field label="Latitude">
          <input {...register('latitude')} type="number" step="0.000001" className="input" />
        </Field>
        <Field label="Longitude">
          <input {...register('longitude')} type="number" step="0.000001" className="input" />
        </Field>
        <Field label="Geofence radius (m)">
          <input {...register('geofence_radius')} type="number" className="input" />
        </Field>
      </div>

      <Suspense fallback={<div className="h-64 bg-muted rounded-lg animate-pulse" />}>
        <MapPicker lat={watch('latitude')} lng={watch('longitude')}
          radiusKm={watch('geofence_radius') / 1000}
          onChange={(lat, lng) => { setValue('latitude', lat); setValue('longitude', lng) }} />
      </Suspense>

      <label className="flex items-center gap-2 cursor-pointer">
        <input {...register('is_premium')} type="checkbox" />
        <span className="text-sm">Premium POI (vyžaduje zakoupení oblasti)</span>
      </label>

      <div className="flex gap-3">
        <button type="submit" className="px-4 py-2 bg-primary text-white rounded-md text-sm">Uložit</button>
        <button type="button" onClick={() => navigate(-1)} className="px-4 py-2 border rounded-md text-sm">Zrušit</button>
      </div>
    </form>
  )
}
```

### 10.5 AudioUploader

```tsx
// src/components/pois/AudioUploader.tsx
import { useState } from 'react'
import { supabase } from '@/lib/supabase/client'
import { CheckCircle, Upload, Trash2, Loader2, Play } from 'lucide-react'

const LANGS = [
  { code: 'cs', label: 'Čeština' },
  { code: 'en', label: 'English' },
  { code: 'de', label: 'Deutsch' },
]

export function AudioUploader({ poiId, audioUrls }: { poiId: string; audioUrls: Record<string, string | null> }) {
  const [urls, setUrls] = useState(audioUrls)
  const [uploading, setUploading] = useState<string | null>(null)
  const baseUrl = `${import.meta.env.VITE_SUPABASE_URL}/storage/v1/object/public/`

  async function upload(lang: string, file: File) {
    setUploading(lang)
    const path = `${poiId}/${lang}.mp3`
    await supabase.storage.from('audio-guides').upload(path, file, { upsert: true, contentType: 'audio/mpeg' })
    const newUrls = { ...urls, [lang]: `audio-guides/${path}` }
    await supabase.from('pois').update({ audio_urls: newUrls }).eq('id', poiId)
    setUrls(newUrls)
    setUploading(null)
  }

  async function remove(lang: string) {
    await supabase.storage.from('audio-guides').remove([`${poiId}/${lang}.mp3`])
    const newUrls = { ...urls, [lang]: null }
    await supabase.from('pois').update({ audio_urls: newUrls }).eq('id', poiId)
    setUrls(newUrls)
  }

  return (
    <div className="border rounded-lg p-4 space-y-3">
      <h3 className="font-medium text-sm">Audio průvodce (MP3, max 50 MB)</h3>
      {LANGS.map(({ code, label }) => (
        <div key={code} className="flex items-center gap-3 p-3 bg-muted/40 rounded-md">
          <span className="font-mono font-bold text-sm w-8">{code.toUpperCase()}</span>
          <span className="flex-1 text-sm">
            {urls[code]
              ? <span className="flex items-center gap-1 text-green-600">
                  <CheckCircle className="w-4 h-4" />
                  {urls[code]?.split('/').pop()}
                </span>
              : <span className="text-orange-500">Žádný soubor → TTS fallback</span>}
          </span>
          <div className="flex gap-1">
            {urls[code] && (
              <a href={`${baseUrl}${urls[code]}`} target="_blank" rel="noreferrer"
                className="p-1 hover:bg-muted rounded" title="Přehrát">
                <Play className="w-4 h-4" />
              </a>
            )}
            <label className="p-1 hover:bg-muted rounded cursor-pointer" title="Nahrát">
              <input type="file" accept="audio/mpeg,audio/mp3" className="hidden"
                onChange={(e) => e.target.files?.[0] && upload(code, e.target.files[0])} />
              {uploading === code
                ? <Loader2 className="w-4 h-4 animate-spin" />
                : <Upload className="w-4 h-4" />}
            </label>
            {urls[code] && (
              <button onClick={() => remove(code)} className="p-1 hover:bg-muted rounded text-red-500">
                <Trash2 className="w-4 h-4" />
              </button>
            )}
          </div>
        </div>
      ))}
    </div>
  )
}
```

### 10.6 PhotoUploader

```tsx
// src/components/pois/PhotoUploader.tsx
import { useState } from 'react'
import { useDropzone } from 'react-dropzone'
import { supabase } from '@/lib/supabase/client'
import { Loader2, Upload, X } from 'lucide-react'

export function PhotoUploader({ poiId, photoUrls }: { poiId: string; photoUrls: string[] }) {
  const [photos, setPhotos] = useState(photoUrls)
  const [uploading, setUploading] = useState(false)
  const transformBase = `${import.meta.env.VITE_SUPABASE_URL}/storage/v1/render/image/public/`

  const { getRootProps, getInputProps, isDragActive } = useDropzone({
    accept: { 'image/*': ['.jpg', '.jpeg', '.png', '.webp'] },
    maxSize: 10 * 1024 * 1024,
    onDrop: async (files) => {
      setUploading(true)
      const newPaths: string[] = []
      for (const file of files) {
        const name = `${Date.now()}-${file.name.replace(/[^a-z0-9.]/gi, '-').toLowerCase()}`
        const path = `${poiId}/${name}`
        const { error } = await supabase.storage.from('poi-photos').upload(path, file)
        if (!error) newPaths.push(`poi-photos/${path}`)
      }
      const updated = [...photos, ...newPaths]
      await supabase.from('pois').update({ photo_urls: updated }).eq('id', poiId)
      setPhotos(updated)
      setUploading(false)
    }
  })

  async function deletePhoto(path: string) {
    await supabase.storage.from('poi-photos').remove([path.replace('poi-photos/', '')])
    const updated = photos.filter(p => p !== path)
    await supabase.from('pois').update({ photo_urls: updated }).eq('id', poiId)
    setPhotos(updated)
  }

  return (
    <div className="border rounded-lg p-4 space-y-4">
      <h3 className="font-medium text-sm">Fotografie (JPG/PNG/WebP, max 10 MB)</h3>
      {/* Náhled fotek */}
      <div className="grid grid-cols-4 md:grid-cols-6 gap-2">
        {photos.map((photo, i) => (
          <div key={photo} className="relative group aspect-square">
            <img src={`${transformBase}${photo}?width=150&quality=70`}
              alt="" className="w-full h-full object-cover rounded" />
            {i === 0 && <span className="absolute top-1 left-1 bg-green-600 text-white text-xs px-1 rounded">Hlavní</span>}
            <button onClick={() => deletePhoto(photo)}
              className="absolute top-1 right-1 bg-red-500 text-white rounded-full w-5 h-5 text-xs opacity-0 group-hover:opacity-100 flex items-center justify-center">
              <X className="w-3 h-3" />
            </button>
          </div>
        ))}
      </div>
      {/* Dropzone */}
      <div {...getRootProps()} className={`border-2 border-dashed rounded-lg p-6 text-center cursor-pointer transition-colors
        ${isDragActive ? 'border-primary bg-primary/5' : 'border-muted-foreground/30 hover:border-primary/50'}`}>
        <input {...getInputProps()} />
        {uploading
          ? <div className="flex items-center justify-center gap-2 text-sm"><Loader2 className="w-4 h-4 animate-spin" /> Nahrávám...</div>
          : <div><Upload className="w-6 h-6 mx-auto mb-1 text-muted-foreground" />
              <p className="text-sm text-muted-foreground">Přetáhněte nebo klikněte pro výběr</p></div>}
      </div>
    </div>
  )
}
```

---

## 11. Správa uživatelů

### 11.1 UsersPage

```tsx
// src/pages/users/UsersPage.tsx
import { useEffect, useState } from 'react'
import { Link } from 'react-router-dom'
import { supabase } from '@/lib/supabase/client'
import { DataTable } from '@/components/shared/DataTable'
import { Badge } from '@/components/ui/badge'
import { Button } from '@/components/ui/button'
import { format } from 'date-fns'
import { cs } from 'date-fns/locale'

export function UsersPage() {
  const [users, setUsers] = useState<any[]>([])
  const [search, setSearch] = useState('')
  const [filter, setFilter] = useState('all')

  useEffect(() => {
    let q = supabase.from('admin_users_view').select('*').order('created_at', { ascending: false })
    if (search) q = q.ilike('email', `%${search}%`)
    if (filter === 'registered') q = q.eq('is_anonymous', false)
    if (filter === 'anonymous') q = q.eq('is_anonymous', true)
    if (filter === 'paid') q = q.gt('access_count', 0)
    q.then(({ data }) => setUsers(data ?? []))
  }, [search, filter])

  const columns = [
    { accessorKey: 'email', header: 'Email',
      cell: ({ row }: any) => row.original.email ?? <span className="text-muted-foreground italic">Anonymní</span> },
    { id: 'type', header: 'Typ',
      cell: ({ row }: any) => <Badge variant={row.original.is_anonymous ? 'secondary' : 'default'}>
        {row.original.is_anonymous ? 'Anonymní' : 'Registrovaný'}
      </Badge> },
    { accessorKey: 'access_count', header: 'Nákupy' },
    { accessorKey: 'total_spent', header: 'Utraceno',
      cell: ({ row }: any) => `${Number(row.original.total_spent).toFixed(2)} €` },
    { accessorKey: 'created_at', header: 'Registrace',
      cell: ({ row }: any) => format(new Date(row.original.created_at), 'd. M. yyyy', { locale: cs }) },
    { id: 'actions', header: '',
      cell: ({ row }: any) => (
        <Link to={`/users/${row.original.id}`}><Button variant="ghost" size="sm">Detail</Button></Link>
      ) }
  ]

  return (
    <div className="space-y-4">
      <h2 className="text-xl font-bold">Uživatelé</h2>
      <div className="flex gap-3">
        <input value={search} onChange={e => setSearch(e.target.value)}
          placeholder="Hledat email..." className="input w-64" />
        <select value={filter} onChange={e => setFilter(e.target.value)} className="input w-44">
          <option value="all">Všichni</option>
          <option value="registered">Registrovaní</option>
          <option value="anonymous">Anonymní</option>
          <option value="paid">Mají nákupy</option>
        </select>
      </div>
      <DataTable columns={columns} data={users} />
    </div>
  )
}
```

### 11.2 UserDetailPage

```tsx
// src/pages/users/UserDetailPage.tsx
import { useEffect, useState } from 'react'
import { useParams, Link } from 'react-router-dom'
import { supabase } from '@/lib/supabase/client'
import { format } from 'date-fns'
import { cs } from 'date-fns/locale'
import { AccessGrantModal } from '@/components/users/AccessGrantModal'
import { Badge } from '@/components/ui/badge'
import { Button } from '@/components/ui/button'
import { ArrowLeft, Trash2 } from 'lucide-react'

export function UserDetailPage() {
  const { id } = useParams<{ id: string }>()
  const [user, setUser] = useState<any>(null)
  const [accesses, setAccesses] = useState<any[]>([])
  const [receipts, setReceipts] = useState<any[]>([])
  const [freeVisits, setFreeVisits] = useState<any[]>([])

  useEffect(() => {
    if (!id) return
    Promise.all([
      supabase.from('admin_users_view').select('*').eq('id', id).single(),
      supabase.from('user_access').select('*, cities(name, price_eur)').eq('user_id', id),
      supabase.from('payment_receipts').select('*, cities(name)').eq('user_id', id).order('purchased_at', { ascending: false }),
      supabase.from('free_visit_log').select('*, pois(name)').eq('user_id', id).order('visited_at', { ascending: false }).limit(20),
    ]).then(([u, a, r, f]) => {
      setUser(u.data); setAccesses(a.data ?? [])
      setReceipts(r.data ?? []); setFreeVisits(f.data ?? [])
    })
  }, [id])

  const totalSpent = receipts.filter(r => r.status === 'completed').reduce((s, r) => s + Number(r.amount_eur), 0)

  async function revokeAccess(accessId: string) {
    await supabase.from('user_access').delete().eq('id', accessId)
    setAccesses(a => a.filter(x => x.id !== accessId))
  }

  async function deleteUser() {
    if (!confirm(`Opravdu smazat uživatele ${user?.email}? Tato akce je nevratná.`)) return
    await supabase.functions.invoke('delete-user-data', {
      headers: { Authorization: `Bearer ${(await supabase.auth.getSession()).data.session?.access_token}` },
      body: JSON.stringify({ user_id: id })
    })
    window.location.href = '/users'
  }

  if (!user) return <div className="animate-pulse">Načítám...</div>

  return (
    <div className="space-y-6 max-w-3xl">
      {/* Zpět + profil */}
      <div className="flex items-center gap-3">
        <Link to="/users"><Button variant="ghost" size="sm"><ArrowLeft className="w-4 h-4" /></Button></Link>
        <div className="flex-1">
          <h2 className="text-xl font-bold">{user.email ?? 'Anonymní uživatel'}</h2>
          <p className="text-sm text-muted-foreground">
            Registrace: {format(new Date(user.created_at), 'd. M. yyyy', { locale: cs })}
            {user.last_sign_in_at && ` · Poslední přihlášení: ${format(new Date(user.last_sign_in_at), 'd. M. yyyy')}`}
          </p>
        </div>
        <div className="text-right">
          <p className="text-2xl font-bold text-green-600">{totalSpent.toFixed(2)} €</p>
          <p className="text-xs text-muted-foreground">celkem zaplaceno</p>
        </div>
      </div>

      {/* Zakoupené oblasti */}
      <Section title="Zakoupené oblasti" action={<AccessGrantModal userId={id!} onGranted={a => setAccesses(prev => [...prev, a])} />}>
        {accesses.length === 0
          ? <p className="text-sm text-muted-foreground">Žádné zakoupené oblasti.</p>
          : <table className="w-full text-sm">
              <thead><tr className="border-b text-left text-muted-foreground">
                <th className="pb-2">Oblast</th><th>Datum</th><th>Metoda</th><th>Platnost</th><th></th>
              </tr></thead>
              <tbody>{accesses.map(a => (
                <tr key={a.id} className="border-b last:border-0">
                  <td className="py-2 font-medium">{a.cities?.name}</td>
                  <td>{format(new Date(a.purchased_at), 'd. M. yyyy')}</td>
                  <td><Badge variant="outline">{a.payment_method}</Badge></td>
                  <td>{a.valid_until ? format(new Date(a.valid_until), 'd. M. yyyy') : 'Trvalý'}</td>
                  <td><button onClick={() => revokeAccess(a.id)} className="text-red-500 text-xs hover:underline">Odebrat</button></td>
                </tr>
              ))}</tbody>
            </table>}
      </Section>

      {/* Historie plateb */}
      <Section title="Historie plateb">
        {receipts.length === 0
          ? <p className="text-sm text-muted-foreground">Žádné platby.</p>
          : <table className="w-full text-sm">
              <thead><tr className="border-b text-left text-muted-foreground">
                <th className="pb-2">Doklad</th><th>Oblast</th><th>Datum</th><th>Částka</th><th>Status</th><th></th>
              </tr></thead>
              <tbody>{receipts.map(r => (
                <tr key={r.id} className="border-b last:border-0">
                  <td className="py-2 font-mono text-xs">{r.receipt_number}</td>
                  <td>{r.cities?.name}</td>
                  <td>{format(new Date(r.purchased_at), 'd. M. yyyy')}</td>
                  <td className="font-bold">{Number(r.amount_eur).toFixed(2)} €</td>
                  <td><StatusBadge status={r.status} /></td>
                  <td><Link to={`/payments/${r.id}`} className="text-primary text-xs hover:underline">Detail</Link></td>
                </tr>
              ))}</tbody>
            </table>}
      </Section>

      {/* Danger zone */}
      <div className="border border-red-200 rounded-lg p-4">
        <h3 className="font-medium text-red-600 mb-2">Nebezpečná zóna</h3>
        <button onClick={deleteUser}
          className="flex items-center gap-2 px-3 py-2 bg-red-50 text-red-600 border border-red-200 rounded text-sm hover:bg-red-100">
          <Trash2 className="w-4 h-4" />Smazat účet a všechna data
        </button>
      </div>
    </div>
  )
}
```

---

## 12. Správa plateb

### 12.1 PaymentsPage

```tsx
// src/pages/payments/PaymentsPage.tsx
import { useEffect, useState } from 'react'
import { Link } from 'react-router-dom'
import { supabase } from '@/lib/supabase/client'
import { MetricCard } from '@/components/dashboard/MetricCard'
import { DataTable } from '@/components/shared/DataTable'
import { StatusBadge } from '@/components/shared/StatusBadge'
import { format } from 'date-fns'
import { cs } from 'date-fns/locale'
import { Download } from 'lucide-react'

export function PaymentsPage() {
  const [receipts, setReceipts] = useState<any[]>([])
  const [summary, setSummary] = useState<any>(null)
  const [filters, setFilters] = useState({ status: '', method: '', from: '', to: '' })

  useEffect(() => {
    load()
  }, [filters])

  async function load() {
    let q = supabase.from('payment_receipts')
      .select('*, cities(name), user:user_id(email)')
      .order('purchased_at', { ascending: false })
      .limit(200)

    if (filters.status) q = q.eq('status', filters.status)
    if (filters.method) q = q.eq('payment_method', filters.method)
    if (filters.from) q = q.gte('purchased_at', filters.from)
    if (filters.to) q = q.lte('purchased_at', filters.to + 'T23:59:59Z')

    const [{ data }, { data: s }] = await Promise.all([
      q,
      supabase.rpc('payment_summary', {
        p_status: filters.status || null, p_method: filters.method || null,
        p_from: filters.from || null, p_to: filters.to || null,
      })
    ])
    setReceipts(data ?? [])
    setSummary(s?.[0])
  }

  function exportCsv() {
    const header = 'Doklad č.;Email;Oblast;Datum;Částka;Měna;Metoda;Status;Transaction ID'
    const rows = receipts.map(r =>
      `${r.receipt_number};${(r.user as any)?.email ?? ''};${r.cities?.name ?? ''};` +
      `${format(new Date(r.purchased_at), 'dd.MM.yyyy')};${r.amount_eur};${r.currency};` +
      `${r.payment_method};${r.status};${r.transaction_id ?? ''}`
    )
    const csv = [header, ...rows].join('\n')
    const blob = new Blob(['\ufeff' + csv], { type: 'text/csv;charset=utf-8' })
    const url = URL.createObjectURL(blob)
    const a = document.createElement('a'); a.href = url; a.download = 'platby.csv'; a.click()
  }

  const columns = [
    { accessorKey: 'receipt_number', header: 'Doklad č.', cell: ({ row }: any) => <span className="font-mono text-xs">{row.original.receipt_number}</span> },
    { id: 'user', header: 'Uživatel', cell: ({ row }: any) => (row.original.user as any)?.email ?? '—' },
    { id: 'city', header: 'Oblast', cell: ({ row }: any) => row.original.cities?.name },
    { accessorKey: 'purchased_at', header: 'Datum', cell: ({ row }: any) => format(new Date(row.original.purchased_at), 'd. M. yyyy HH:mm') },
    { accessorKey: 'amount_eur', header: 'Částka', cell: ({ row }: any) => <span className="font-bold">{Number(row.original.amount_eur).toFixed(2)} €</span> },
    { accessorKey: 'payment_method', header: 'Metoda' },
    { accessorKey: 'status', header: 'Status', cell: ({ row }: any) => <StatusBadge status={row.original.status} /> },
    { id: 'actions', header: '', cell: ({ row }: any) => <Link to={`/payments/${row.original.id}`} className="text-primary text-xs hover:underline">Detail</Link> },
  ]

  return (
    <div className="space-y-4">
      <h2 className="text-xl font-bold">Platby</h2>

      {/* Filtry */}
      <div className="flex flex-wrap gap-3">
        <select value={filters.status} onChange={e => setFilters(f => ({ ...f, status: e.target.value }))} className="input w-36">
          <option value="">Všechny statusy</option>
          <option value="completed">Completed</option>
          <option value="pending">Pending</option>
          <option value="refunded">Refunded</option>
          <option value="disputed">Disputed</option>
        </select>
        <select value={filters.method} onChange={e => setFilters(f => ({ ...f, method: e.target.value }))} className="input w-36">
          <option value="">Všechny metody</option>
          <option value="revolut">Revolut</option>
          <option value="stripe">Stripe</option>
          <option value="google_pay">Google Pay</option>
          <option value="apple_pay">Apple Pay</option>
          <option value="admin_grant">Admin grant</option>
        </select>
        <input type="date" value={filters.from} onChange={e => setFilters(f => ({ ...f, from: e.target.value }))} className="input" />
        <input type="date" value={filters.to} onChange={e => setFilters(f => ({ ...f, to: e.target.value }))} className="input" />
        <button onClick={exportCsv} className="flex items-center gap-2 px-3 py-2 border rounded text-sm hover:bg-muted">
          <Download className="w-4 h-4" />Export CSV
        </button>
      </div>

      {/* Souhrn */}
      {summary && (
        <div className="grid grid-cols-3 gap-4">
          <MetricCard title="Celková částka" value={`${Number(summary.total_eur).toFixed(2)} €`} icon="euro" color="green" />
          <MetricCard title="Počet transakcí" value={summary.count} icon="credit-card" />
          <MetricCard title="Čeká potvrzení (Revolut)" value={summary.pending_revolut} icon="clock" color="orange" />
        </div>
      )}

      <DataTable columns={columns} data={receipts} />
    </div>
  )
}
```

### 12.2 PaymentDetailPage

```tsx
// src/pages/payments/PaymentDetailPage.tsx
import { useEffect, useState } from 'react'
import { useParams, Link } from 'react-router-dom'
import { supabase } from '@/lib/supabase/client'
import { format } from 'date-fns'
import { cs } from 'date-fns/locale'
import { ArrowLeft, CheckCircle, Download, Mail } from 'lucide-react'
import { StatusBadge } from '@/components/shared/StatusBadge'

export function PaymentDetailPage() {
  const { id } = useParams<{ id: string }>()
  const [receipt, setReceipt] = useState<any>(null)
  const [working, setWorking] = useState(false)

  useEffect(() => {
    supabase.from('payment_receipts')
      .select('*, cities(*), user:user_id(email)')
      .eq('id', id!).single()
      .then(({ data }) => setReceipt(data))
  }, [id])

  async function confirmRevolut() {
    setWorking(true)
    const session = (await supabase.auth.getSession()).data.session
    await supabase.functions.invoke('confirm-revolut', {
      headers: { Authorization: `Bearer ${session?.access_token}` },
      body: JSON.stringify({ receipt_id: id }),
    })
    setReceipt((r: any) => ({ ...r, status: 'completed' }))
    setWorking(false)
  }

  async function generatePdf() {
    setWorking(true)
    const { data } = await supabase.functions.invoke('generate-receipt', {
      body: JSON.stringify({ receipt_id: id }),
    })
    setReceipt((r: any) => ({ ...r, receipt_pdf_url: data?.pdf_url }))
    setWorking(false)
  }

  async function sendEmail() {
    setWorking(true)
    await supabase.functions.invoke('generate-receipt', {
      body: JSON.stringify({ receipt_id: id, send_email: true }),
    })
    setReceipt((r: any) => ({ ...r, receipt_sent_at: new Date().toISOString() }))
    setWorking(false)
  }

  if (!receipt) return <div className="animate-pulse">Načítám...</div>

  return (
    <div className="space-y-6 max-w-xl">
      <div className="flex items-center gap-3">
        <Link to="/payments"><button className="p-2 hover:bg-muted rounded"><ArrowLeft className="w-4 h-4" /></button></Link>
        <div>
          <h2 className="text-xl font-bold">{receipt.receipt_number}</h2>
          <StatusBadge status={receipt.status} />
        </div>
      </div>

      {/* Detail */}
      <div className="border rounded-lg divide-y text-sm">
        {[
          ['Číslo dokladu', receipt.receipt_number],
          ['Uživatel', receipt.user?.email ?? 'Anonymní'],
          ['Oblast', receipt.cities?.name],
          ['Datum', format(new Date(receipt.purchased_at), 'd. M. yyyy HH:mm', { locale: cs })],
          ['Částka', `${Number(receipt.amount_eur).toFixed(2)} ${receipt.currency}`],
          ['Metoda platby', receipt.payment_method],
          receipt.transaction_id ? ['Transaction ID', receipt.transaction_id] : null,
          receipt.revolut_note ? ['Poznámka', receipt.revolut_note] : null,
        ].filter(Boolean).map(([label, value]) => (
          <div key={label as string} className="flex justify-between p-3">
            <span className="text-muted-foreground">{label}</span>
            <span className="font-medium">{value as string}</span>
          </div>
        ))}
      </div>

      {/* Revolut potvrzení */}
      {receipt.status === 'pending' && receipt.payment_method === 'revolut' && (
        <div className="border border-orange-300 bg-orange-50 rounded-lg p-4">
          <h3 className="font-medium text-orange-700 mb-3">Čeká na manuální potvrzení</h3>
          <div className="flex gap-3">
            <button onClick={confirmRevolut} disabled={working}
              className="px-4 py-2 bg-green-600 text-white rounded text-sm disabled:opacity-50">
              ✓ Potvrdit platbu
            </button>
            <button onClick={async () => {
              await supabase.from('payment_receipts').update({ status: 'disputed' }).eq('id', id)
              setReceipt((r: any) => ({ ...r, status: 'disputed' }))
            }} className="px-4 py-2 border border-red-300 text-red-600 rounded text-sm">
              ✗ Zamítnout
            </button>
          </div>
        </div>
      )}

      {/* PDF receipt */}
      <div className="border rounded-lg p-4 space-y-3">
        <h3 className="font-medium">Potvrzení o platbě (PDF)</h3>
        {receipt.receipt_pdf_url
          ? <div className="flex items-center gap-3">
              <CheckCircle className="w-5 h-5 text-green-500" />
              <span className="text-sm">PDF vygenerováno</span>
              <a href={receipt.receipt_pdf_url} target="_blank" rel="noreferrer"
                className="flex items-center gap-1 text-sm text-primary hover:underline">
                <Download className="w-4 h-4" />Stáhnout
              </a>
            </div>
          : <p className="text-sm text-muted-foreground">PDF zatím nebylo vygenerováno.</p>}
        <div className="flex gap-3">
          <button onClick={generatePdf} disabled={working}
            className="px-3 py-2 bg-primary text-white rounded text-sm disabled:opacity-50">
            Vygenerovat PDF
          </button>
          {receipt.user?.email && (
            <button onClick={sendEmail} disabled={working || !receipt.receipt_pdf_url}
              className="flex items-center gap-2 px-3 py-2 border rounded text-sm disabled:opacity-50">
              <Mail className="w-4 h-4" />
              {receipt.receipt_sent_at ? `Odesláno ${format(new Date(receipt.receipt_sent_at), 'd. M. yyyy')}` : 'Odeslat emailem'}
            </button>
          )}
        </div>
      </div>
    </div>
  )
}
```

---

## 13. Edge Function – `generate-receipt`

```typescript
// supabase/functions/generate-receipt/index.ts
import { serve } from 'https://deno.land/std@0.177.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

serve(async (req) => {
  const { receipt_id, send_email = false } = await req.json()
  const supabase = createClient(
    Deno.env.get('SUPABASE_URL')!,
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
  )

  const { data: r } = await supabase
    .from('payment_receipts')
    .select('*, cities(name), user:user_id(email)')
    .eq('id', receipt_id).single()
  if (!r) return new Response('Not found', { status: 404 })

  // Sestavit PDF jako textový stream (bez závislostí)
  const date = new Date(r.purchased_at).toLocaleDateString('cs-CZ', { day: 'numeric', month: 'long', year: 'numeric' })
  const lines = [
    'HeroDots – Potvrzeni o platbe', '',
    `Doklad c.: ${r.receipt_number}`,
    `Datum: ${date}`,
    `Zakaznik: ${r.user?.email ?? 'Anonymni'}`,
    `Oblast: ${r.cities?.name ?? ''}`,
    `Castka: ${Number(r.amount_eur).toFixed(2)} ${r.currency}`,
    `Metoda platby: ${r.payment_method}`,
    r.transaction_id ? `Transaction ID: ${r.transaction_id}` : '',
    '', 'HeroDots · cz.tuma.herodots',
  ]

  const content = lines.filter(Boolean).join('\n')
  const pdfText = `%PDF-1.4
1 0 obj<</Type/Catalog/Pages 2 0 R>>endobj
2 0 obj<</Type/Pages/Kids[3 0 R]/Count 1>>endobj
3 0 obj<</Type/Page/Parent 2 0 R/MediaBox[0 0 595 842]/Contents 4 0 R/Resources<</Font<</F1 5 0 R>>>>>>endobj
4 0 obj<</Length ${content.length + 100}>>
stream
BT /F1 12 Tf 50 780 Td 16 TL
${lines.map(l => `(${l.replace(/[()\\]/g, c => '\\' + c)}) Tj T*`).join('\n')}
ET
endstream
endobj
5 0 obj<</Type/Font/Subtype/Type1/BaseFont/Helvetica>>endobj
xref
0 6
0000000000 65535 f 
trailer<</Size 6/Root 1 0 R>>
startxref 0
%%EOF`

  const pdfBytes = new TextEncoder().encode(pdfText)
  const path = `${r.user_id}/${r.receipt_number}.pdf`

  await supabase.storage.from('payment-receipts')
    .upload(path, pdfBytes, { contentType: 'application/pdf', upsert: true })

  const { data: signed } = await supabase.storage.from('payment-receipts')
    .createSignedUrl(path, 60 * 60 * 24 * 365)

  await supabase.from('payment_receipts')
    .update({ receipt_pdf_url: signed?.signedUrl }).eq('id', receipt_id)

  if (send_email && r.user?.email) {
    const key = Deno.env.get('RESEND_API_KEY')
    if (key) {
      await fetch('https://api.resend.com/emails', {
        method: 'POST',
        headers: { Authorization: `Bearer ${key}`, 'Content-Type': 'application/json' },
        body: JSON.stringify({
          from: 'HeroDots <noreply@herodots.app>',
          to: r.user.email,
          subject: `Potvrzení platby ${r.receipt_number} – HeroDots`,
          html: `<div style="font-family:sans-serif;max-width:500px">
            <div style="background:#2D6A4F;padding:20px;border-radius:8px 8px 0 0">
              <h1 style="color:white;margin:0;font-size:22px">HeroDots</h1>
              <p style="color:#b7ddc8;margin:4px 0 0">Potvrzení o platbě</p>
            </div>
            <div style="border:1px solid #e5e7eb;border-top:none;padding:24px;border-radius:0 0 8px 8px">
              <p>Doklad č.: <strong>${r.receipt_number}</strong></p>
              <p>Oblast: <strong>${r.cities?.name}</strong></p>
              <p>Částka: <strong style="color:#2D6A4F;font-size:20px">${Number(r.amount_eur).toFixed(2)} ${r.currency}</strong></p>
              <p>Metoda: ${r.payment_method}</p>
              <p>Datum: ${date}</p>
              ${signed?.signedUrl ? `<p><a href="${signed.signedUrl}" style="background:#2D6A4F;color:white;padding:10px 20px;border-radius:6px;text-decoration:none;display:inline-block">Stáhnout PDF potvrzení</a></p>` : ''}
            </div>
          </div>`
        })
      })
      await supabase.from('payment_receipts')
        .update({ receipt_sent_at: new Date().toISOString() }).eq('id', receipt_id)
    }
  }

  return new Response(JSON.stringify({ success: true, pdf_url: signed?.signedUrl }))
})
```

---

## 14. Nastavení – SettingsPage

```tsx
// src/pages/SettingsPage.tsx
import { useEffect, useState } from 'react'
import { supabase } from '@/lib/supabase/client'

export function SettingsPage() {
  const [config, setConfig] = useState<any>(null)
  const [saving, setSaving] = useState(false)
  const [saved, setSaved] = useState(false)

  useEffect(() => {
    supabase.from('payment_config').select('*').single().then(({ data }) => setConfig(data))
  }, [])

  async function save(e: React.FormEvent<HTMLFormElement>) {
    e.preventDefault()
    setSaving(true)
    const fd = new FormData(e.currentTarget)
    const values = Object.fromEntries(fd.entries())
    if (config) {
      await supabase.from('payment_config').update(values).eq('id', config.id)
    } else {
      await supabase.from('payment_config').insert(values)
    }
    setSaving(false); setSaved(true)
    setTimeout(() => setSaved(false), 3000)
  }

  return (
    <div className="space-y-6 max-w-lg">
      <h2 className="text-xl font-bold">Nastavení</h2>

      <div className="border rounded-lg p-6">
        <h3 className="font-medium mb-4">Platební konfigurace</h3>
        <form onSubmit={save} className="space-y-4">
          {[
            { name: 'operator_name', label: 'Název operátora' },
            { name: 'revolut_username', label: 'Revolut username', placeholder: 'herodots' },
            { name: 'revolut_iban', label: 'Revolut IBAN' },
            { name: 'stripe_publishable_key', label: 'Stripe Publishable Key', placeholder: 'pk_live_...' },
          ].map(({ name, label, placeholder }) => (
            <div key={name}>
              <label className="block text-sm font-medium mb-1">{label}</label>
              <input name={name} defaultValue={config?.[name] ?? ''} placeholder={placeholder}
                className="input w-full" />
            </div>
          ))}
          <button type="submit" disabled={saving}
            className="px-4 py-2 bg-primary text-white rounded text-sm disabled:opacity-50">
            {saving ? 'Ukládám...' : saved ? '✓ Uloženo' : 'Uložit'}
          </button>
        </form>
      </div>
    </div>
  )
}
```

---

## 15. Kompletní seznam DB migrací

```
supabase/migrations/003_payment_receipts.sql  ← tabulka receipts + trigger čísla dokladu
supabase/migrations/004_admin_users.sql       ← admin_users tabulka + RLS
supabase/migrations/005_dashboard_rpc.sql     ← RPC funkce, admin_stats view, admin_users_view
```

## 16. Edge Functions – deploy

```bash
supabase functions deploy confirm-payment     # nahrazuje payment-webhook
supabase functions deploy generate-receipt    # PDF + email
supabase functions deploy delete-user-data    # již v hlavní spec
supabase functions deploy migrate-anonymous-data

# Secrets
supabase secrets set RESEND_API_KEY=re_...

# Storage
supabase storage create payment-receipts      # private bucket pro PDF
```

---

## 17. Instalační checklist

```
PREREKVIZITY (z hlavní spec – specification-prompts.md):
  ✅ Supabase projekt (dev + prod)
  ✅ Migrace 001 + 002 (základní schéma)
  ✅ Storage buckety: poi-photos, audio-guides

NOVÉ PRO ADMIN PANEL:
  1. supabase/migrations/003_payment_receipts.sql → spustit
  2. supabase/migrations/004_admin_users.sql       → spustit
  3. supabase/migrations/005_dashboard_rpc.sql     → spustit
  4. supabase storage create payment-receipts      → private bucket
  5. supabase secrets set RESEND_API_KEY=re_...
  6. supabase functions deploy confirm-payment
  7. supabase functions deploy generate-receipt
  8. Vytvořit prvního admin uživatele:
       a) Supabase Dashboard → Auth → Users → Invite user
       b) Zkopírovat UUID nového uživatele
       c) INSERT INTO public.admin_users (user_id, role) VALUES ('uuid', 'superadmin');
  9. npm create vite + npm install (viz sekce 2)
  10. .env.local naplnit
  11. npm run dev → přihlásit se → ověřit dashboard
  12. npm run build → deploy na Netlify/Vercel
```

---

## 18. Roadmapa implementace

| # | Krok | Výstup |
|---|---|---|
| 1 | DB migrace 003–005 + storage bucket | Tabulky a funkce existují |
| 2 | Vite bootstrap + Tailwind + shadcn | `npm run dev` funguje |
| 3 | Supabase klient + .env.local | Připojení k DB ověřeno |
| 4 | React Router + AuthGuard + Login | Nepřihlášený → redirect login |
| 5 | AppShell – Sidebar + Header | Navigace funguje |
| 6 | DashboardPage + MetricCard + grafy | Metriky a grafy zobrazují data |
| 7 | CitiesPage + CityForm + MapPicker (lazy) | CRUD měst funguje |
| 8 | PoisPage + PoiForm (vícejazyčný) | CRUD POI funguje |
| 9 | PhotoUploader (dropzone + storage) | Upload fotek do Supabase Storage |
| 10 | AudioUploader (per jazyk + delete) | Upload MP3 do Supabase Storage |
| 11 | UsersPage + filtrování | Tabulka uživatelů |
| 12 | UserDetailPage (přístupy + platby + free) | Kompletní detail uživatele |
| 13 | AccessGrantModal + revokeAccess | Manuální udělení/odebrání přístupu |
| 14 | DeleteUser (volá Edge Function) | Smazání uživatele |
| 15 | PaymentsPage + filtry + export CSV | Tabulka plateb + CSV |
| 16 | PaymentDetailPage | Detail transakce |
| 17 | generate-receipt Edge Function | PDF generování |
| 18 | GeneratePdf + download tlačítko | PDF ke stažení |
| 19 | SendEmail tlačítko (Resend) | Email odeslán |
| 20 | ConfirmRevolut + zamítnutí | Manuální potvrzení Revolut platby |
| 21 | SettingsPage – platební konfigurace | Konfigurace uložena |
| 22 | `npm run build` + deploy Netlify/Vercel | Produkce na admin.herodots.app |

---

## 19. Doplnění mezer – chybějící komponenty a use-cases

> Tato sekce doplňuje mezery identifikované analýzou pokrytí. Každá podsekce je
> implementačně samostatná a navazuje na příslušné sekce výše.

---

### 19.1 Sdílené komponenty – implementace

#### 19.1.1 `DataTable` – TanStack Table wrapper

```tsx
// src/components/shared/DataTable.tsx
import {
  useReactTable, getCoreRowModel, getSortedRowModel,
  getPaginationRowModel, flexRender,
  type ColumnDef, type SortingState,
} from '@tanstack/react-table'
import { useState } from 'react'
import { ChevronUp, ChevronDown, ChevronsUpDown } from 'lucide-react'

interface DataTableProps<T> {
  columns: ColumnDef<T>[]
  data: T[]
  pageSize?: number
}

export function DataTable<T>({ columns, data, pageSize = 25 }: DataTableProps<T>) {
  const [sorting, setSorting] = useState<SortingState>([])

  const table = useReactTable({
    data,
    columns,
    state: { sorting },
    onSortingChange: setSorting,
    getCoreRowModel: getCoreRowModel(),
    getSortedRowModel: getSortedRowModel(),
    getPaginationRowModel: getPaginationRowModel(),
    initialState: { pagination: { pageSize } },
  })

  return (
    <div className="space-y-3">
      <div className="border rounded-lg overflow-hidden">
        <table className="w-full text-sm">
          <thead className="bg-muted/50">
            {table.getHeaderGroups().map(hg => (
              <tr key={hg.id}>
                {hg.headers.map(header => (
                  <th key={header.id}
                    className="px-4 py-3 text-left font-medium text-muted-foreground whitespace-nowrap"
                    onClick={header.column.getToggleSortingHandler()}
                    style={{ cursor: header.column.getCanSort() ? 'pointer' : 'default' }}
                  >
                    <div className="flex items-center gap-1">
                      {flexRender(header.column.columnDef.header, header.getContext())}
                      {header.column.getCanSort() && (
                        header.column.getIsSorted() === 'asc' ? <ChevronUp className="w-3 h-3" />
                        : header.column.getIsSorted() === 'desc' ? <ChevronDown className="w-3 h-3" />
                        : <ChevronsUpDown className="w-3 h-3 opacity-40" />
                      )}
                    </div>
                  </th>
                ))}
              </tr>
            ))}
          </thead>
          <tbody>
            {table.getRowModel().rows.length === 0 ? (
              <tr><td colSpan={columns.length} className="px-4 py-8 text-center text-muted-foreground">Žádná data</td></tr>
            ) : (
              table.getRowModel().rows.map(row => (
                <tr key={row.id} className="border-t hover:bg-muted/30 transition-colors">
                  {row.getVisibleCells().map(cell => (
                    <td key={cell.id} className="px-4 py-3">
                      {flexRender(cell.column.columnDef.cell, cell.getContext())}
                    </td>
                  ))}
                </tr>
              ))
            )}
          </tbody>
        </table>
      </div>

      {/* Paginace */}
      {table.getPageCount() > 1 && (
        <div className="flex items-center justify-between text-sm text-muted-foreground">
          <span>
            Strana {table.getState().pagination.pageIndex + 1} z {table.getPageCount()}
            {' '}· celkem {data.length} záznamů
          </span>
          <div className="flex gap-1">
            <button onClick={() => table.previousPage()} disabled={!table.getCanPreviousPage()}
              className="px-3 py-1 border rounded disabled:opacity-40 hover:bg-muted">‹ Předchozí</button>
            <button onClick={() => table.nextPage()} disabled={!table.getCanNextPage()}
              className="px-3 py-1 border rounded disabled:opacity-40 hover:bg-muted">Další ›</button>
          </div>
        </div>
      )}
    </div>
  )
}
```

#### 19.1.2 `StatusBadge` – jednotné badge pro statusy

```tsx
// src/components/shared/StatusBadge.tsx
import { cn } from '@/lib/utils'

type PaymentStatus = 'pending' | 'completed' | 'refunded' | 'disputed'
type ActiveStatus = boolean

const PAYMENT_CONFIG: Record<PaymentStatus, { label: string; className: string }> = {
  pending:   { label: 'Čeká',      className: 'bg-orange-100 text-orange-700 border-orange-200' },
  completed: { label: 'Dokončeno', className: 'bg-green-100 text-green-700 border-green-200' },
  refunded:  { label: 'Vráceno',   className: 'bg-blue-100 text-blue-700 border-blue-200' },
  disputed:  { label: 'Zamítnuto', className: 'bg-red-100 text-red-700 border-red-200' },
}

export function StatusBadge({ status }: { status: PaymentStatus }) {
  const cfg = PAYMENT_CONFIG[status] ?? { label: status, className: 'bg-muted text-muted-foreground' }
  return (
    <span className={cn('inline-flex items-center px-2 py-0.5 rounded-full text-xs font-medium border', cfg.className)}>
      {cfg.label}
    </span>
  )
}

export function ActiveBadge({ active }: { active: boolean }) {
  return (
    <span className={cn('inline-flex items-center px-2 py-0.5 rounded-full text-xs font-medium border',
      active ? 'bg-green-100 text-green-700 border-green-200' : 'bg-muted text-muted-foreground border-border')}>
      {active ? 'Aktivní' : 'Neaktivní'}
    </span>
  )
}
```

#### 19.1.3 `ConfirmDialog` – potvrzovací modal

```tsx
// src/components/shared/ConfirmDialog.tsx
import { useState } from 'react'
import { AlertTriangle } from 'lucide-react'

interface ConfirmDialogProps {
  trigger: React.ReactNode
  title: string
  description: string
  confirmLabel?: string
  destructive?: boolean
  onConfirm: () => Promise<void> | void
}

export function ConfirmDialog({
  trigger, title, description,
  confirmLabel = 'Potvrdit', destructive = false, onConfirm
}: ConfirmDialogProps) {
  const [open, setOpen] = useState(false)
  const [loading, setLoading] = useState(false)

  async function handleConfirm() {
    setLoading(true)
    await onConfirm()
    setLoading(false)
    setOpen(false)
  }

  return (
    <>
      <span onClick={() => setOpen(true)}>{trigger}</span>

      {open && (
        <div className="fixed inset-0 z-50 flex items-center justify-center">
          {/* Overlay */}
          <div className="absolute inset-0 bg-black/40" onClick={() => setOpen(false)} />
          {/* Dialog */}
          <div className="relative bg-card border rounded-lg shadow-xl p-6 w-full max-w-sm mx-4">
            <div className="flex items-start gap-3 mb-4">
              {destructive && <AlertTriangle className="w-5 h-5 text-red-500 shrink-0 mt-0.5" />}
              <div>
                <h3 className="font-semibold">{title}</h3>
                <p className="text-sm text-muted-foreground mt-1">{description}</p>
              </div>
            </div>
            <div className="flex gap-3 justify-end">
              <button onClick={() => setOpen(false)}
                className="px-4 py-2 border rounded text-sm hover:bg-muted">
                Zrušit
              </button>
              <button onClick={handleConfirm} disabled={loading}
                className={`px-4 py-2 rounded text-sm text-white disabled:opacity-50 ${
                  destructive ? 'bg-red-600 hover:bg-red-700' : 'bg-primary hover:bg-primary/90'
                }`}>
                {loading ? 'Zpracovávám...' : confirmLabel}
              </button>
            </div>
          </div>
        </div>
      )}
    </>
  )
}
```

#### 19.1.4 `Toast` – globální notifikace

```tsx
// src/hooks/useToast.ts
import { useState, useCallback } from 'react'

type ToastType = 'success' | 'error' | 'info'

interface Toast {
  id: number; message: string; type: ToastType
}

// Jednoduchý singleton store pro toasty
let _addToast: (msg: string, type: ToastType) => void = () => {}

export function useToast() {
  return {
    success: (msg: string) => _addToast(msg, 'success'),
    error: (msg: string) => _addToast(msg, 'error'),
    info: (msg: string) => _addToast(msg, 'info'),
  }
}

// src/components/shared/ToastProvider.tsx
import { useState, useEffect } from 'react'
import { CheckCircle, XCircle, Info, X } from 'lucide-react'
import { cn } from '@/lib/utils'

let addFn: (msg: string, type: ToastType) => void

export function ToastProvider() {
  const [toasts, setToasts] = useState<Toast[]>([])
  let counter = 0

  addFn = useCallback((message: string, type: ToastType) => {
    const id = ++counter
    setToasts(t => [...t, { id, message, type }])
    setTimeout(() => setToasts(t => t.filter(x => x.id !== id)), 4000)
  }, [])

  // Exportovat funkci pro hook
  useEffect(() => { _addToast = addFn }, [addFn])

  const ICONS = { success: CheckCircle, error: XCircle, info: Info }
  const COLORS = {
    success: 'bg-green-50 border-green-200 text-green-800',
    error: 'bg-red-50 border-red-200 text-red-800',
    info: 'bg-blue-50 border-blue-200 text-blue-800',
  }

  return (
    <div className="fixed bottom-4 right-4 z-50 flex flex-col gap-2 max-w-sm">
      {toasts.map(t => {
        const Icon = ICONS[t.type]
        return (
          <div key={t.id} className={cn('flex items-start gap-3 p-3 border rounded-lg shadow-md text-sm', COLORS[t.type])}>
            <Icon className="w-4 h-4 shrink-0 mt-0.5" />
            <span className="flex-1">{t.message}</span>
            <button onClick={() => setToasts(ts => ts.filter(x => x.id !== t.id))}>
              <X className="w-3 h-3" />
            </button>
          </div>
        )
      })}
    </div>
  )
}

// Přidat do src/main.tsx:
// <ToastProvider /> vedle <App />
```

#### 19.1.5 `Section` helper – používaný v UserDetailPage

```tsx
// src/components/shared/Section.tsx
interface SectionProps {
  title: string
  action?: React.ReactNode
  children: React.ReactNode
}

export function Section({ title, action, children }: SectionProps) {
  return (
    <div className="border rounded-lg overflow-hidden">
      <div className="flex items-center justify-between px-4 py-3 bg-muted/30 border-b">
        <h3 className="font-medium text-sm">{title}</h3>
        {action}
      </div>
      <div className="p-4">{children}</div>
    </div>
  )
}
```

#### 19.1.6 `AdminUserMenu` – odhlášení v Sidebar

```tsx
// src/components/layout/AdminUserMenu.tsx
import { useState, useEffect } from 'react'
import { supabase } from '@/lib/supabase/client'
import { LogOut, ChevronDown } from 'lucide-react'

export function AdminUserMenu() {
  const [email, setEmail] = useState<string | null>(null)
  const [open, setOpen] = useState(false)

  useEffect(() => {
    supabase.auth.getUser().then(({ data }) => setEmail(data.user?.email ?? null))
  }, [])

  async function logout() {
    await supabase.auth.signOut()
    window.location.href = '/login'
  }

  return (
    <div className="relative">
      <button onClick={() => setOpen(o => !o)}
        className="w-full flex items-center gap-2 px-2 py-2 rounded hover:bg-muted text-sm text-left">
        <div className="w-6 h-6 bg-primary rounded-full flex items-center justify-center text-white text-xs font-bold shrink-0">
          {email?.[0]?.toUpperCase() ?? 'A'}
        </div>
        <span className="flex-1 truncate text-xs text-muted-foreground">{email ?? 'Admin'}</span>
        <ChevronDown className="w-3 h-3 text-muted-foreground" />
      </button>
      {open && (
        <div className="absolute bottom-full left-0 right-0 mb-1 bg-card border rounded-lg shadow-lg overflow-hidden">
          <button onClick={logout}
            className="w-full flex items-center gap-2 px-3 py-2 text-sm text-red-600 hover:bg-muted">
            <LogOut className="w-4 h-4" />Odhlásit se
          </button>
        </div>
      )}
    </div>
  )
}
```

---

### 19.2 PoisPage – seznam POI s aktivací a řazením

```tsx
// src/pages/pois/PoisPage.tsx
import { useEffect, useState } from 'react'
import { useParams, Link } from 'react-router-dom'
import { supabase } from '@/lib/supabase/client'
import { DataTable } from '@/components/shared/DataTable'
import { ActiveBadge } from '@/components/shared/StatusBadge'
import { ConfirmDialog } from '@/components/shared/ConfirmDialog'
import { useToast } from '@/hooks/useToast'
import { Plus, Pencil, ArrowUp, ArrowDown, ToggleLeft, ToggleRight } from 'lucide-react'
import type { ColumnDef } from '@tanstack/react-table'

export function PoisPage() {
  const { cityId } = useParams<{ cityId: string }>()
  const [pois, setPois] = useState<any[]>([])
  const [city, setCity] = useState<any>(null)
  const [search, setSearch] = useState('')
  const toast = useToast()

  useEffect(() => {
    supabase.from('cities').select('name').eq('id', cityId!).single()
      .then(({ data }) => setCity(data))
    loadPois()
  }, [cityId])

  async function loadPois() {
    const { data } = await supabase.from('pois')
      .select('*')
      .eq('city_id', cityId!)
      .order('sort_order')
    setPois(data ?? [])
  }

  async function toggleActive(poi: any) {
    await supabase.from('pois')
      .update({ is_active: !poi.is_active, updated_at: new Date().toISOString() })
      .eq('id', poi.id)
    setPois(ps => ps.map(p => p.id === poi.id ? { ...p, is_active: !p.is_active } : p))
    toast.success(`POI ${poi.is_active ? 'deaktivováno' : 'aktivováno'}`)
  }

  async function moveSortOrder(poi: any, direction: 'up' | 'down') {
    // Najít souseda a prohodit sort_order
    const idx = pois.findIndex(p => p.id === poi.id)
    const targetIdx = direction === 'up' ? idx - 1 : idx + 1
    if (targetIdx < 0 || targetIdx >= pois.length) return

    const neighbor = pois[targetIdx]
    const newPois = [...pois]
    newPois[idx] = { ...poi, sort_order: neighbor.sort_order }
    newPois[targetIdx] = { ...neighbor, sort_order: poi.sort_order }
    newPois.sort((a, b) => a.sort_order - b.sort_order)

    // Uložit oba záznamy
    await Promise.all([
      supabase.from('pois').update({ sort_order: neighbor.sort_order }).eq('id', poi.id),
      supabase.from('pois').update({ sort_order: poi.sort_order }).eq('id', neighbor.id),
    ])
    setPois(newPois)
  }

  const filtered = pois.filter(p =>
    !search || p.name?.cs?.toLowerCase().includes(search.toLowerCase())
      || p.name?.en?.toLowerCase().includes(search.toLowerCase())
  )

  const columns: ColumnDef<any>[] = [
    {
      id: 'order', header: 'Pořadí',
      cell: ({ row }) => (
        <div className="flex items-center gap-1">
          <span className="text-muted-foreground w-6 text-right text-xs">{row.original.sort_order}</span>
          <div className="flex flex-col">
            <button onClick={() => moveSortOrder(row.original, 'up')} className="hover:text-primary p-0.5">
              <ArrowUp className="w-3 h-3" />
            </button>
            <button onClick={() => moveSortOrder(row.original, 'down')} className="hover:text-primary p-0.5">
              <ArrowDown className="w-3 h-3" />
            </button>
          </div>
        </div>
      )
    },
    {
      id: 'name', header: 'Název',
      cell: ({ row }) => (
        <div>
          <p className="font-medium">{row.original.name?.cs ?? '—'}</p>
          <p className="text-xs text-muted-foreground">{row.original.name?.en}</p>
        </div>
      )
    },
    {
      id: 'premium', header: 'Typ',
      cell: ({ row }) => (
        <span className={`text-xs px-2 py-0.5 rounded-full border ${
          row.original.is_premium
            ? 'bg-yellow-50 text-yellow-700 border-yellow-200'
            : 'bg-muted text-muted-foreground border-border'
        }`}>
          {row.original.is_premium ? '★ Premium' : 'Free'}
        </span>
      )
    },
    {
      id: 'audio', header: 'Audio',
      cell: ({ row }) => {
        const urls = row.original.audio_urls ?? {}
        const langs = ['cs', 'en', 'de'].filter(l => urls[l])
        return langs.length > 0
          ? <span className="text-xs text-green-600">{langs.join(', ')}</span>
          : <span className="text-xs text-orange-500">TTS</span>
      }
    },
    {
      id: 'photos', header: 'Fotky',
      cell: ({ row }) => (
        <span className="text-sm">{row.original.photo_urls?.length ?? 0}</span>
      )
    },
    {
      id: 'status', header: 'Status',
      cell: ({ row }) => <ActiveBadge active={row.original.is_active} />
    },
    {
      id: 'actions', header: '',
      cell: ({ row }) => (
        <div className="flex items-center gap-2">
          <Link to={`/cities/${cityId}/pois/${row.original.id}`}>
            <button className="p-1.5 hover:bg-muted rounded" title="Editovat">
              <Pencil className="w-4 h-4" />
            </button>
          </Link>
          <button onClick={() => toggleActive(row.original)}
            className={`p-1.5 rounded ${row.original.is_active ? 'hover:bg-red-50 text-red-500' : 'hover:bg-green-50 text-green-600'}`}
            title={row.original.is_active ? 'Deaktivovat' : 'Aktivovat'}>
            {row.original.is_active ? <ToggleRight className="w-4 h-4" /> : <ToggleLeft className="w-4 h-4" />}
          </button>
        </div>
      )
    },
  ]

  return (
    <div className="space-y-4">
      {/* Breadcrumb */}
      <div className="flex items-center gap-2 text-sm text-muted-foreground">
        <Link to="/cities" className="hover:underline">Oblasti</Link>
        <span>/</span>
        <span className="text-foreground font-medium">{city?.name}</span>
        <span>/</span>
        <span>POI</span>
      </div>

      <div className="flex items-center justify-between">
        <h2 className="text-xl font-bold">POI v oblasti {city?.name}</h2>
        <Link to={`/cities/${cityId}/pois/new`}>
          <button className="flex items-center gap-2 px-4 py-2 bg-primary text-white rounded text-sm">
            <Plus className="w-4 h-4" />Přidat POI
          </button>
        </Link>
      </div>

      {/* Vyhledávání */}
      <input
        value={search}
        onChange={e => setSearch(e.target.value)}
        placeholder="Hledat podle názvu..."
        className="input w-72"
      />

      {/* Legenda řazení */}
      <p className="text-xs text-muted-foreground">
        ↕ Šipkami měníte pořadí zobrazení POI v mobilní aplikaci (sort_order).
      </p>

      <DataTable columns={columns} data={filtered} pageSize={30} />
    </div>
  )
}
```

```tsx
// src/pages/pois/PoiNewPage.tsx
import { PoiForm } from '@/components/pois/PoiForm'
import { useParams, Link } from 'react-router-dom'
import { ArrowLeft } from 'lucide-react'

export function PoiNewPage() {
  const { cityId } = useParams<{ cityId: string }>()
  return (
    <div className="space-y-4">
      <div className="flex items-center gap-3">
        <Link to={`/cities/${cityId}/pois`}>
          <button className="p-2 hover:bg-muted rounded"><ArrowLeft className="w-4 h-4" /></button>
        </Link>
        <h2 className="text-xl font-bold">Nové POI</h2>
      </div>
      <PoiForm cityId={cityId!} />
    </div>
  )
}
```

```tsx
// src/pages/pois/PoiEditPage.tsx
import { useEffect, useState } from 'react'
import { useParams, Link } from 'react-router-dom'
import { supabase } from '@/lib/supabase/client'
import { PoiForm } from '@/components/pois/PoiForm'
import { ArrowLeft } from 'lucide-react'

export function PoiEditPage() {
  const { cityId, poiId } = useParams<{ cityId: string; poiId: string }>()
  const [poi, setPoi] = useState<any>(null)

  useEffect(() => {
    supabase.from('pois').select('*').eq('id', poiId!).single()
      .then(({ data }) => setPoi(data))
  }, [poiId])

  if (!poi) return (
    <div className="space-y-4 animate-pulse">
      <div className="h-8 bg-muted rounded w-48" />
      <div className="h-96 bg-muted rounded" />
    </div>
  )

  return (
    <div className="space-y-4">
      <div className="flex items-center gap-3">
        <Link to={`/cities/${cityId}/pois`}>
          <button className="p-2 hover:bg-muted rounded"><ArrowLeft className="w-4 h-4" /></button>
        </Link>
        <div>
          <h2 className="text-xl font-bold">Editace POI</h2>
          <p className="text-sm text-muted-foreground">{poi.name?.cs}</p>
        </div>
      </div>
      <PoiForm cityId={cityId!} poi={poi} />
    </div>
  )
}
```

---

### 19.3 AccessGrantModal – manuální udělení přístupu

```tsx
// src/components/users/AccessGrantModal.tsx
import { useState, useEffect } from 'react'
import { supabase } from '@/lib/supabase/client'
import { useToast } from '@/hooks/useToast'
import { Plus, X } from 'lucide-react'

interface AccessGrantModalProps {
  userId: string
  onGranted: (access: any) => void
}

export function AccessGrantModal({ userId, onGranted }: AccessGrantModalProps) {
  const [open, setOpen] = useState(false)
  const [cities, setCities] = useState<any[]>([])
  const [selectedCity, setSelectedCity] = useState('')
  const [note, setNote] = useState('')
  const [loading, setLoading] = useState(false)
  const toast = useToast()

  useEffect(() => {
    if (open) {
      supabase.from('cities').select('id, name, price_eur').eq('is_active', true).order('name')
        .then(({ data }) => setCities(data ?? []))
    }
  }, [open])

  async function grant() {
    if (!selectedCity) return
    setLoading(true)

    const city = cities.find(c => c.id === selectedCity)

    // 1. Upsert user_access
    const { error: accessError } = await supabase.from('user_access').upsert({
      user_id: userId,
      city_id: selectedCity,
      payment_method: 'admin_grant',
      amount_eur: 0,
      valid_until: null,
    })

    if (accessError) {
      toast.error('Chyba při udělování přístupu: ' + accessError.message)
      setLoading(false)
      return
    }

    // 2. Vytvořit receipt záznam (pro auditní log)
    const { data: receipt } = await supabase.from('payment_receipts').insert({
      user_id: userId,
      city_id: selectedCity,
      payment_method: 'admin_grant',
      amount_eur: 0,
      status: 'completed',
      revolut_note: note || 'Manuálně uděleno administrátorem',
    }).select().single()

    const newAccess = {
      id: receipt?.id ?? crypto.randomUUID(),
      user_id: userId,
      city_id: selectedCity,
      purchased_at: new Date().toISOString(),
      payment_method: 'admin_grant',
      valid_until: null,
      cities: { name: city?.name, price_eur: city?.price_eur },
    }

    onGranted(newAccess)
    toast.success(`Přístup k oblasti "${city?.name}" udělen.`)
    setOpen(false)
    setSelectedCity('')
    setNote('')
    setLoading(false)
  }

  return (
    <>
      <button onClick={() => setOpen(true)}
        className="flex items-center gap-1 px-3 py-1.5 bg-primary text-white rounded text-sm">
        <Plus className="w-3 h-3" />Udělit přístup
      </button>

      {open && (
        <div className="fixed inset-0 z-50 flex items-center justify-center">
          <div className="absolute inset-0 bg-black/40" onClick={() => setOpen(false)} />
          <div className="relative bg-card border rounded-lg shadow-xl p-6 w-full max-w-md mx-4">
            <div className="flex items-center justify-between mb-4">
              <h3 className="font-semibold">Udělit přístup k oblasti</h3>
              <button onClick={() => setOpen(false)} className="p-1 hover:bg-muted rounded">
                <X className="w-4 h-4" />
              </button>
            </div>

            <div className="space-y-4">
              {/* Výběr oblasti */}
              <div>
                <label className="block text-sm font-medium mb-1">Oblast *</label>
                <select value={selectedCity} onChange={e => setSelectedCity(e.target.value)}
                  className="input w-full">
                  <option value="">— Vyberte oblast —</option>
                  {cities.map(c => (
                    <option key={c.id} value={c.id}>
                      {c.name} ({c.price_eur} €)
                    </option>
                  ))}
                </select>
              </div>

              {/* Poznámka */}
              <div>
                <label className="block text-sm font-medium mb-1">Poznámka (interní)</label>
                <input
                  value={note}
                  onChange={e => setNote(e.target.value)}
                  placeholder="Např. výměna za nahlášenou chybu"
                  className="input w-full"
                />
              </div>

              {/* Info */}
              <p className="text-xs text-muted-foreground bg-muted/50 p-2 rounded">
                Udělení přístupu je zdarma (admin_grant). Záznam bude uložen do auditního logu.
              </p>
            </div>

            <div className="flex gap-3 justify-end mt-6">
              <button onClick={() => setOpen(false)}
                className="px-4 py-2 border rounded text-sm hover:bg-muted">Zrušit</button>
              <button onClick={grant} disabled={!selectedCity || loading}
                className="px-4 py-2 bg-primary text-white rounded text-sm disabled:opacity-50">
                {loading ? 'Ukládám...' : 'Udělit přístup'}
              </button>
            </div>
          </div>
        </div>
      )}
    </>
  )
}
```

---

### 19.4 Správa admin uživatelů – Settings rozšíření

```tsx
// Doplnit do src/pages/SettingsPage.tsx – sekce správy adminů

// src/components/settings/AdminUsersTable.tsx
import { useEffect, useState } from 'react'
import { supabase } from '@/lib/supabase/client'
import { useToast } from '@/hooks/useToast'
import { ConfirmDialog } from '@/components/shared/ConfirmDialog'
import { Trash2 } from 'lucide-react'

type AdminRole = 'superadmin' | 'editor' | 'viewer'

const ROLE_LABELS: Record<AdminRole, string> = {
  superadmin: 'Superadmin',
  editor: 'Editor',
  viewer: 'Viewer',
}

export function AdminUsersTable() {
  const [admins, setAdmins] = useState<any[]>([])
  const toast = useToast()

  useEffect(() => { loadAdmins() }, [])

  async function loadAdmins() {
    // Spojit admin_users s auth.users přes email
    const { data } = await supabase
      .from('admin_users')
      .select('*, user:user_id(email)')
      .order('created_at')
    setAdmins(data ?? [])
  }

  async function changeRole(adminId: string, role: AdminRole) {
    await supabase.from('admin_users').update({ role }).eq('id', adminId)
    setAdmins(a => a.map(x => x.id === adminId ? { ...x, role } : x))
    toast.success('Role změněna')
  }

  async function removeAdmin(adminId: string) {
    await supabase.from('admin_users').delete().eq('id', adminId)
    setAdmins(a => a.filter(x => x.id !== adminId))
    toast.success('Admin odebrán')
  }

  return (
    <div className="space-y-3">
      <table className="w-full text-sm">
        <thead>
          <tr className="border-b text-left text-muted-foreground">
            <th className="pb-2">Email</th>
            <th>Role</th>
            <th>Přidán</th>
            <th></th>
          </tr>
        </thead>
        <tbody>
          {admins.map(admin => (
            <tr key={admin.id} className="border-b last:border-0">
              <td className="py-2 font-medium">{admin.user?.email ?? admin.user_id}</td>
              <td>
                <select
                  value={admin.role}
                  onChange={e => changeRole(admin.id, e.target.value as AdminRole)}
                  className="text-xs border rounded px-2 py-1 bg-background"
                >
                  {Object.entries(ROLE_LABELS).map(([val, label]) => (
                    <option key={val} value={val}>{label}</option>
                  ))}
                </select>
              </td>
              <td className="text-muted-foreground text-xs">
                {new Date(admin.created_at).toLocaleDateString('cs-CZ')}
              </td>
              <td>
                <ConfirmDialog
                  trigger={
                    <button className="p-1 hover:bg-muted rounded text-red-500" title="Odebrat admina">
                      <Trash2 className="w-4 h-4" />
                    </button>
                  }
                  title="Odebrat administrátora"
                  description={`Opravdu odebrat přístup uživateli ${admin.user?.email}?`}
                  confirmLabel="Odebrat"
                  destructive
                  onConfirm={() => removeAdmin(admin.id)}
                />
              </td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  )
}
```

```tsx
// src/components/settings/InviteAdminForm.tsx
import { useState } from 'react'
import { supabase } from '@/lib/supabase/client'
import { useToast } from '@/hooks/useToast'
import { UserPlus, X } from 'lucide-react'

export function InviteAdminForm({ onInvited }: { onInvited?: () => void }) {
  const [open, setOpen] = useState(false)
  const [email, setEmail] = useState('')
  const [role, setRole] = useState<'editor' | 'viewer'>('editor')
  const [loading, setLoading] = useState(false)
  const toast = useToast()

  async function invite() {
    if (!email) return
    setLoading(true)

    // 1. Pozvat uživatele přes Supabase Auth (odešle email s magic linkem)
    const { data: invited, error } = await supabase.auth.admin.inviteUserByEmail(email)

    if (error) {
      // Pokud uživatel již existuje, zkusit najít podle emailu
      toast.error('Chyba: ' + error.message)
      setLoading(false)
      return
    }

    // 2. Přidat do admin_users
    await supabase.from('admin_users').insert({
      user_id: invited.user.id,
      role,
    })

    toast.success(`Pozvánka odeslána na ${email}. Po přihlášení bude mít admin přístup.`)
    setEmail('')
    setOpen(false)
    onInvited?.()
    setLoading(false)
  }

  return (
    <>
      <button onClick={() => setOpen(true)}
        className="flex items-center gap-2 px-3 py-1.5 border rounded text-sm hover:bg-muted">
        <UserPlus className="w-4 h-4" />Přidat admina
      </button>

      {open && (
        <div className="fixed inset-0 z-50 flex items-center justify-center">
          <div className="absolute inset-0 bg-black/40" onClick={() => setOpen(false)} />
          <div className="relative bg-card border rounded-lg shadow-xl p-6 w-full max-w-sm mx-4">
            <div className="flex items-center justify-between mb-4">
              <h3 className="font-semibold">Přidat administrátora</h3>
              <button onClick={() => setOpen(false)}><X className="w-4 h-4" /></button>
            </div>
            <div className="space-y-3">
              <div>
                <label className="block text-sm font-medium mb-1">Email *</label>
                <input value={email} onChange={e => setEmail(e.target.value)}
                  type="email" placeholder="admin@example.com" className="input w-full" />
              </div>
              <div>
                <label className="block text-sm font-medium mb-1">Role</label>
                <select value={role} onChange={e => setRole(e.target.value as any)} className="input w-full">
                  <option value="editor">Editor – může editovat obsah</option>
                  <option value="viewer">Viewer – pouze čtení</option>
                </select>
              </div>
              <p className="text-xs text-muted-foreground">
                Uživateli bude odeslán email s pozvánkou. Po kliknutí na odkaz a nastavení hesla
                bude mít přístup do admin panelu.
              </p>
            </div>
            <div className="flex gap-3 justify-end mt-4">
              <button onClick={() => setOpen(false)} className="px-4 py-2 border rounded text-sm">Zrušit</button>
              <button onClick={invite} disabled={!email || loading}
                className="px-4 py-2 bg-primary text-white rounded text-sm disabled:opacity-50">
                {loading ? 'Odesílám...' : 'Odeslat pozvánku'}
              </button>
            </div>
          </div>
        </div>
      )}
    </>
  )
}
```

```tsx
// Aktualizovaná src/pages/SettingsPage.tsx – přidat admin sekci

// ... (stávající import kódu)
import { AdminUsersTable } from '@/components/settings/AdminUsersTable'
import { InviteAdminForm } from '@/components/settings/InviteAdminForm'

// Přidat do JSX za platební konfigurace:

<div className="border rounded-lg p-6">
  <div className="flex items-center justify-between mb-4">
    <h3 className="font-medium">Administrátoři</h3>
    <InviteAdminForm onInvited={() => { /* reload */ }} />
  </div>
  <p className="text-xs text-muted-foreground mb-4">
    <strong>Superadmin</strong> – plný přístup včetně správy adminů.<br />
    <strong>Editor</strong> – může přidávat/editovat obsah a spravovat platby.<br />
    <strong>Viewer</strong> – pouze čtení dashboardu a plateb.
  </p>
  <AdminUsersTable />
</div>

// Přidat Google Pay + Apple Pay do payment_config formuláře:
{ name: 'google_pay_merchant_id', label: 'Google Pay Merchant ID', placeholder: 'merchant.cz.tuma.herodots' },
{ name: 'apple_pay_merchant_id', label: 'Apple Pay Merchant ID', placeholder: 'merchant.cz.tuma.herodots' },
```

---

### 19.5 PaymentsPage – textové hledání + Revolut poznámka

```tsx
// Doplnit do src/pages/payments/PaymentsPage.tsx:

// 1. Přidat stav pro textové hledání
const [searchText, setSearchText] = useState('')

// 2. Přidat do filtrů:
<input
  value={searchText}
  onChange={e => setSearchText(e.target.value)}
  placeholder="Číslo dokladu nebo email..."
  className="input w-56"
/>

// 3. Přidat do Supabase query v load():
if (searchText) {
  // Hledat v receipt_number nebo v emailu uživatele
  q = q.or(`receipt_number.ilike.%${searchText}%,user.email.ilike.%${searchText}%`)
}
```

```tsx
// Doplnit do src/pages/payments/PaymentDetailPage.tsx:
// Pole pro poznámku při Revolut potvrzení

// Přidat state:
const [revNote, setRevNote] = useState('')

// Upravit confirmRevolut():
async function confirmRevolut() {
  setWorking(true)
  // Uložit poznámku do DB
  if (revNote) {
    await supabase.from('payment_receipts')
      .update({ revolut_note: revNote }).eq('id', id)
  }
  const session = (await supabase.auth.getSession()).data.session
  await supabase.functions.invoke('confirm-revolut', {
    headers: { Authorization: `Bearer ${session?.access_token}` },
    body: JSON.stringify({ receipt_id: id }),
  })
  setReceipt((r: any) => ({ ...r, status: 'completed', revolut_note: revNote }))
  setWorking(false)
}

// Přidat do Revolut sekce (před tlačítka):
<div className="mb-3">
  <label className="block text-sm font-medium mb-1">Poznámka operátora (volitelné)</label>
  <input
    value={revNote}
    onChange={e => setRevNote(e.target.value)}
    placeholder="Např. platba ověřena v Revolut Business"
    className="input w-full text-sm"
  />
</div>
```

---

### 19.6 Stripe Refund – akce v PaymentDetailPage

```tsx
// Doplnit do src/pages/payments/PaymentDetailPage.tsx:

async function refundStripe() {
  if (!receipt.transaction_id) return
  setWorking(true)
  // Volá Edge Function která zavolá Stripe API
  const { error } = await supabase.functions.invoke('stripe-refund', {
    body: JSON.stringify({
      payment_intent_id: receipt.transaction_id,
      receipt_id: id,
    }),
  })
  if (error) {
    toast.error('Refund selhal: ' + error.message)
  } else {
    setReceipt((r: any) => ({ ...r, status: 'refunded' }))
    toast.success('Refund byl odeslán přes Stripe.')
  }
  setWorking(false)
}

// Přidat do JSX za PDF sekci:
{receipt.payment_method === 'stripe' && receipt.status === 'completed' && (
  <div className="border border-red-100 rounded-lg p-4">
    <h3 className="font-medium text-red-700 mb-2">Vrácení platby (Stripe Refund)</h3>
    <p className="text-xs text-muted-foreground mb-3">
      Vrátí plnou částku {Number(receipt.amount_eur).toFixed(2)} € přes Stripe.
      Akce je nevratná.
    </p>
    <ConfirmDialog
      trigger={
        <button className="px-3 py-2 border border-red-300 text-red-600 rounded text-sm hover:bg-red-50">
          Vrátit platbu
        </button>
      }
      title="Vrátit platbu?"
      description={`Bude vráceno ${Number(receipt.amount_eur).toFixed(2)} € uživateli ${receipt.user?.email}. Akce je nevratná.`}
      confirmLabel="Vrátit"
      destructive
      onConfirm={refundStripe}
    />
  </div>
)}
```

```typescript
// supabase/functions/stripe-refund/index.ts
import { serve } from 'https://deno.land/std@0.177.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
import Stripe from 'https://esm.sh/stripe@14'

serve(async (req) => {
  const { payment_intent_id, receipt_id } = await req.json()
  const supabase = createClient(
    Deno.env.get('SUPABASE_URL')!,
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
  )
  const stripe = new Stripe(Deno.env.get('STRIPE_SECRET_KEY')!, { apiVersion: '2023-10-16' })

  // Refund přes Stripe
  const refund = await stripe.refunds.create({ payment_intent: payment_intent_id })

  if (refund.status !== 'succeeded') {
    return new Response(JSON.stringify({ error: 'Refund failed' }), { status: 500 })
  }

  // Aktualizovat receipt status
  await supabase.from('payment_receipts')
    .update({ status: 'refunded' }).eq('id', receipt_id)

  // Odebrat user_access k dané oblasti
  const { data: receipt } = await supabase.from('payment_receipts')
    .select('user_id, city_id').eq('id', receipt_id).single()
  if (receipt) {
    await supabase.from('user_access')
      .delete().eq('user_id', receipt.user_id).eq('city_id', receipt.city_id)
  }

  return new Response(JSON.stringify({ success: true }), { status: 200 })
})
```

---

### 19.7 Opravená SettingsPage – kompletní verze

```tsx
// src/pages/SettingsPage.tsx – kompletní přepis
import { useEffect, useState } from 'react'
import { supabase } from '@/lib/supabase/client'
import { AdminUsersTable } from '@/components/settings/AdminUsersTable'
import { InviteAdminForm } from '@/components/settings/InviteAdminForm'
import { useToast } from '@/hooks/useToast'

const PAYMENT_FIELDS = [
  { name: 'operator_name',         label: 'Název operátora' },
  { name: 'revolut_username',      label: 'Revolut username',       placeholder: 'herodots' },
  { name: 'revolut_iban',          label: 'Revolut IBAN' },
  { name: 'stripe_publishable_key',label: 'Stripe Publishable Key', placeholder: 'pk_live_...' },
  { name: 'google_pay_merchant_id',label: 'Google Pay Merchant ID', placeholder: 'merchant.cz.tuma.herodots' },
  { name: 'apple_pay_merchant_id', label: 'Apple Pay Merchant ID',  placeholder: 'merchant.cz.tuma.herodots' },
]

export function SettingsPage() {
  const [config, setConfig] = useState<Record<string, string>>({})
  const [saving, setSaving] = useState(false)
  const [adminKey, setAdminKey] = useState(0)  // pro reload AdminUsersTable
  const toast = useToast()

  useEffect(() => {
    supabase.from('payment_config').select('*').single()
      .then(({ data }) => data && setConfig(data))
  }, [])

  async function save(e: React.FormEvent<HTMLFormElement>) {
    e.preventDefault()
    setSaving(true)
    const fd = new FormData(e.currentTarget)
    const values = Object.fromEntries(fd.entries()) as Record<string, string>

    if (config.id) {
      await supabase.from('payment_config').update(values).eq('id', config.id)
    } else {
      await supabase.from('payment_config').insert(values)
    }
    setSaving(false)
    toast.success('Konfigurace uložena')
  }

  return (
    <div className="space-y-6 max-w-xl">
      <h2 className="text-xl font-bold">Nastavení</h2>

      {/* Platební konfigurace */}
      <div className="border rounded-lg p-6">
        <h3 className="font-medium mb-4">Platební metody</h3>
        <form onSubmit={save} className="space-y-4">
          {PAYMENT_FIELDS.map(({ name, label, placeholder }) => (
            <div key={name}>
              <label className="block text-sm font-medium mb-1">{label}</label>
              <input
                name={name}
                defaultValue={config[name] ?? ''}
                placeholder={placeholder}
                className="input w-full"
              />
            </div>
          ))}
          <button type="submit" disabled={saving}
            className="px-4 py-2 bg-primary text-white rounded text-sm disabled:opacity-50">
            {saving ? 'Ukládám...' : 'Uložit'}
          </button>
        </form>
      </div>

      {/* Správa adminů */}
      <div className="border rounded-lg p-6">
        <div className="flex items-center justify-between mb-2">
          <h3 className="font-medium">Administrátoři</h3>
          <InviteAdminForm onInvited={() => setAdminKey(k => k + 1)} />
        </div>
        <p className="text-xs text-muted-foreground mb-4">
          <strong>Superadmin</strong> – plný přístup včetně správy adminů.<br />
          <strong>Editor</strong> – editace obsahu, správa plateb.<br />
          <strong>Viewer</strong> – pouze čtení.
        </p>
        <AdminUsersTable key={adminKey} />
      </div>

      {/* Systémové limity – pouze info */}
      <div className="border rounded-lg p-6">
        <h3 className="font-medium mb-3">Systémové limity (read-only)</h3>
        <div className="space-y-2 text-sm text-muted-foreground">
          {[
            ['Free POI za měsíc', '1 (napevno v kódu mobilní app)'],
            ['Max geofences', '100 (Android limit)'],
            ['Max foto na POI', '10 MB/ks'],
            ['Max audio na POI', '50 MB/ks'],
            ['Tile cache', '200 MB / 14 dní'],
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

---

### 19.8 Opravená roadmapa – aktualizace sekce 18

```
Aktualizovaná roadmapa (nahrazuje sekci 18):

# | Krok                                           | Výstup
--+------------------------------------------------+------------------------------------------
1 | DB migrace 003–005 + storage bucket            | Tabulky a funkce existují
2 | Vite bootstrap + Tailwind + shadcn             | npm run dev funguje
3 | Supabase klient + .env.local                   | Připojení ověřeno
4 | React Router + AuthGuard + LoginPage           | Nepřihlášený → redirect
5 | AppShell – Sidebar + Header + AdminUserMenu    | Navigace + odhlášení funguje
6 | ToastProvider v main.tsx + useToast hook       | Toast notifikace fungují
7 | Sdílené komponenty: DataTable, StatusBadge,    | Compile bez chyb
  | ActiveBadge, ConfirmDialog, Section            |
8 | DashboardPage + MetricCard + RevenueChart      | Metriky a grafy zobrazují data
9 | CitiesPage + CityForm + MapPicker (lazy)       | CRUD měst funguje
10| PoisPage + sort_order + toggle active           | Seznam POI s řazením
11| PoiNewPage + PoiEditPage + PoiForm              | CRUD POI funguje
12| PhotoUploader (dropzone + storage)             | Upload fotek do Storage
13| AudioUploader (per jazyk + delete + preview)   | Upload MP3 do Storage
14| UsersPage + filtrování + DataTable             | Tabulka uživatelů
15| UserDetailPage (přístupy, platby, free)        | Kompletní detail
16| AccessGrantModal + revokeAccess                | Manuální udělení/odebrání přístupu
17| DeleteUser (ConfirmDialog + Edge Function)     | Smazání uživatele
18| PaymentsPage + textové hledání + filtry + CSV  | Tabulka plateb + export
19| PaymentDetailPage                              | Detail transakce
20| generate-receipt Edge Function                 | PDF generování
21| PDF tlačítko + SendEmail (Resend)              | PDF ke stažení, email odeslán
22| ConfirmRevolut + pole poznámky + zamítnutí     | Revolut potvrzení s poznámkou
23| Stripe Refund tlačítko + stripe-refund EF      | Vrácení platby přes Stripe
24| SettingsPage – platby + Google/Apple Pay IDs   | Konfigurace uložena
25| AdminUsersTable + InviteAdminForm              | Správa adminů funguje
26| npm run build + deploy Netlify/Vercel          | Produkce na admin.herodots.app

Edge Functions celkem (deploy):
  supabase functions deploy confirm-payment
  supabase functions deploy generate-receipt
  supabase functions deploy stripe-refund
  supabase functions deploy delete-user-data
  supabase functions deploy migrate-anonymous-data

Secrets:
  supabase secrets set RESEND_API_KEY=re_...
  supabase secrets set STRIPE_SECRET_KEY=sk_live_...
  supabase secrets set STRIPE_WEBHOOK_SECRET=whsec_...
```

---

## 20. Správa typů POI (`/poi-types`)

> POI typy jsou globální (sdílí se napříč všemi oblastmi). Admin je spravuje
> na samostatné stránce dostupné ze Sidebar. Každý typ má vícejazyčný název,
> ikonu z Material Icons a barvu pinu.

---

### 20.1 Rozšíření Sidebar navigace

```tsx
// src/components/layout/Sidebar.tsx – aktualizovat NAV pole:
const NAV = [
  { to: '/dashboard',  icon: LayoutDashboard, label: 'Dashboard' },
  { to: '/cities',     icon: MapPin,           label: 'Oblasti & POI' },
  { to: '/poi-types',  icon: Tag,              label: 'Typy POI' },     // ← nový
  { to: '/users',      icon: Users,            label: 'Uživatelé' },
  { to: '/payments',   icon: CreditCard,       label: 'Platby' },
  { to: '/settings',   icon: Settings,         label: 'Nastavení' },
]
// Import: import { Tag } from 'lucide-react'
```

```tsx
// src/App.tsx – přidat route:
import { PoiTypesPage } from '@/pages/poi-types/PoiTypesPage'

// Do Routes:
<Route path="/poi-types" element={<PoiTypesPage />} />
```

---

### 20.2 Dostupné ikony – konstanta

```typescript
// src/lib/poi-type-icons.ts
// Podmnožina Material Icons dostupná v mobilní Flutter app
// icon_name v DB → zobrazení v admin preview + mobilní app

export const POI_TYPE_ICONS: { name: string; label: string }[] = [
  { name: 'place',           label: 'Místo (výchozí)' },
  { name: 'apartment',       label: 'Apartmán / Stavba' },
  { name: 'account_balance', label: 'Budova / Instituce' },
  { name: 'emoji_people',    label: 'Socha / Postava' },
  { name: 'military_tech',   label: 'Památník / Ocenění' },
  { name: 'restaurant',      label: 'Restaurace' },
  { name: 'local_cafe',      label: 'Kavárna' },
  { name: 'shopping_bag',    label: 'Obchod' },
  { name: 'park',            label: 'Příroda / Park' },
  { name: 'landscape',       label: 'Výhled' },
  { name: 'museum',          label: 'Muzeum' },
  { name: 'church',          label: 'Kostel / Kaple' },
  { name: 'castle',          label: 'Hrad / Zámek' },
  { name: 'hotel',           label: 'Hotel / Ubytování' },
  { name: 'local_bar',       label: 'Bar / Hospoda' },
  { name: 'theater_comedy',  label: 'Divadlo / Kultura' },
  { name: 'stadium',         label: 'Stadion / Sport' },
  { name: 'school',          label: 'Škola / Vzdělání' },
  { name: 'directions_bike', label: 'Cyklotrasa' },
]

// Komponenta pro preview ikony v admin (pomocí Google Material Icons font)
// Přidat do index.html:
// <link href="https://fonts.googleapis.com/icon?family=Material+Icons" rel="stylesheet">

export function MaterialIcon({ name, color, size = 20 }: {
  name: string; color?: string; size?: number
}) {
  return (
    <span
      className="material-icons select-none"
      style={{ fontSize: size, color: color ?? 'currentColor', lineHeight: 1 }}
    >
      {name}
    </span>
  )
}
```

---

### 20.3 PoiTypesPage – seznam a inline editace

```
GUI layout stránky /poi-types:

┌─────────────────────────────────────────────────────────────┐
│  Typy POI                              [+ Přidat typ]       │
│                                                             │
│  ┌─────────────────────────────────────────────────────┐   │
│  │  ↕  │  Preview  │  Název (CS)    │  Ikona   │  Barva │  Aktivní │  Akce  │
│  ├─────┼───────────┼────────────────┼──────────┼───────┼──────────┼────────┤
│  │  ↑↓ │  🏛️ ████  │  Stavba        │ apartment│ #5C6BC0│  ●       │  ✎  🗑 │
│  │  ↑↓ │  🗿 ████  │  Socha         │ emoji... │ #8D6E63│  ●       │  ✎  🗑 │
│  │  ↑↓ │  🍽️ ████  │  Restaurace    │ restaur..│ #E53935│  ●       │  ✎  🗑 │
│  │  ↑↓ │  ☕ ████  │  Kavárna       │ local_ca │ #6D4C41│  ○       │  ✎  🗑 │
│  └─────────────────────────────────────────────────────┘   │
│                                                             │
│  ℹ️  10 typů celkem · 9 aktivních                          │
└─────────────────────────────────────────────────────────────┘

Preview sloupec: kruhový barevný badge s ikonou (vizuální náhled
jak bude pin vypadat v mobilní aplikaci)
```

```tsx
// src/pages/poi-types/PoiTypesPage.tsx
import { useEffect, useState } from 'react'
import { supabase } from '@/lib/supabase/client'
import { useToast } from '@/hooks/useToast'
import { ConfirmDialog } from '@/components/shared/ConfirmDialog'
import { PoiTypeModal } from '@/components/poi-types/PoiTypeModal'
import { ActiveBadge } from '@/components/shared/StatusBadge'
import { MaterialIcon } from '@/lib/poi-type-icons'
import { Plus, Pencil, Trash2, ArrowUp, ArrowDown } from 'lucide-react'

export function PoiTypesPage() {
  const [types, setTypes] = useState<any[]>([])
  const [editingType, setEditingType] = useState<any | null>(null)
  const [showModal, setShowModal] = useState(false)
  const toast = useToast()

  useEffect(() => { loadTypes() }, [])

  async function loadTypes() {
    const { data } = await supabase
      .from('poi_types')
      .select('*')
      .order('sort_order')
    setTypes(data ?? [])
  }

  async function toggleActive(type: any) {
    await supabase.from('poi_types')
      .update({ is_active: !type.is_active, updated_at: new Date().toISOString() })
      .eq('id', type.id)
    setTypes(ts => ts.map(t => t.id === type.id ? { ...t, is_active: !t.is_active } : t))
    toast.success(`Typ "${type.name?.cs}" ${type.is_active ? 'deaktivován' : 'aktivován'}`)
  }

  async function deleteType(type: any) {
    // Kontrola: typ má přiřazené POI?
    const { count } = await supabase
      .from('pois').select('id', { count: 'exact', head: true })
      .eq('type_id', type.id)
    if ((count ?? 0) > 0) {
      toast.error(`Nelze smazat – typ je přiřazen k ${count} POI. Nejdřív přeřaďte POI.`)
      return
    }
    await supabase.from('poi_types').delete().eq('id', type.id)
    setTypes(ts => ts.filter(t => t.id !== type.id))
    toast.success(`Typ "${type.name?.cs}" smazán`)
  }

  async function moveSortOrder(type: any, dir: 'up' | 'down') {
    const idx = types.findIndex(t => t.id === type.id)
    const targetIdx = dir === 'up' ? idx - 1 : idx + 1
    if (targetIdx < 0 || targetIdx >= types.length) return
    const neighbor = types[targetIdx]
    const updated = [...types]
    updated[idx] = { ...type, sort_order: neighbor.sort_order }
    updated[targetIdx] = { ...neighbor, sort_order: type.sort_order }
    updated.sort((a, b) => a.sort_order - b.sort_order)
    await Promise.all([
      supabase.from('poi_types').update({ sort_order: neighbor.sort_order }).eq('id', type.id),
      supabase.from('poi_types').update({ sort_order: type.sort_order }).eq('id', neighbor.id),
    ])
    setTypes(updated)
  }

  function openNew() { setEditingType(null); setShowModal(true) }
  function openEdit(type: any) { setEditingType(type); setShowModal(true) }

  const activeCount = types.filter(t => t.is_active).length

  return (
    <div className="space-y-4">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h2 className="text-xl font-bold">Typy POI</h2>
          <p className="text-sm text-muted-foreground">
            Kategorie míst zobrazované v mobilní aplikaci jako ikony a barvy pinů.
          </p>
        </div>
        <button onClick={openNew}
          className="flex items-center gap-2 px-4 py-2 bg-primary text-white rounded text-sm">
          <Plus className="w-4 h-4" />Přidat typ
        </button>
      </div>

      {/* Tabulka */}
      <div className="border rounded-lg overflow-hidden">
        <table className="w-full text-sm">
          <thead className="bg-muted/50 border-b">
            <tr>
              <th className="px-3 py-3 text-left text-muted-foreground w-16">Pořadí</th>
              <th className="px-3 py-3 text-left text-muted-foreground w-20">Náhled</th>
              <th className="px-3 py-3 text-left text-muted-foreground">Název</th>
              <th className="px-3 py-3 text-left text-muted-foreground">Ikona</th>
              <th className="px-3 py-3 text-left text-muted-foreground">Barva</th>
              <th className="px-3 py-3 text-left text-muted-foreground">POI</th>
              <th className="px-3 py-3 text-left text-muted-foreground">Status</th>
              <th className="px-3 py-3 text-right text-muted-foreground">Akce</th>
            </tr>
          </thead>
          <tbody>
            {types.map((type, idx) => (
              <tr key={type.id} className="border-t hover:bg-muted/20 transition-colors">
                {/* Řazení */}
                <td className="px-3 py-3">
                  <div className="flex items-center gap-0.5">
                    <span className="text-xs text-muted-foreground w-5">{type.sort_order}</span>
                    <div className="flex flex-col">
                      <button onClick={() => moveSortOrder(type, 'up')} disabled={idx === 0}
                        className="p-0.5 hover:text-primary disabled:opacity-30">
                        <ArrowUp className="w-3 h-3" />
                      </button>
                      <button onClick={() => moveSortOrder(type, 'down')} disabled={idx === types.length - 1}
                        className="p-0.5 hover:text-primary disabled:opacity-30">
                        <ArrowDown className="w-3 h-3" />
                      </button>
                    </div>
                  </div>
                </td>

                {/* Náhled pinu */}
                <td className="px-3 py-3">
                  <PoiTypePreview iconName={type.icon_name} colorHex={type.color_hex} />
                </td>

                {/* Název */}
                <td className="px-3 py-3">
                  <div>
                    <p className="font-medium">{type.name?.cs || '—'}</p>
                    <p className="text-xs text-muted-foreground">{type.name?.en}</p>
                  </div>
                </td>

                {/* Ikona name */}
                <td className="px-3 py-3">
                  <div className="flex items-center gap-2">
                    <MaterialIcon name={type.icon_name} size={16} color="#666" />
                    <span className="text-xs text-muted-foreground font-mono">{type.icon_name}</span>
                  </div>
                </td>

                {/* Barva */}
                <td className="px-3 py-3">
                  <div className="flex items-center gap-2">
                    <div className="w-5 h-5 rounded border border-border"
                      style={{ backgroundColor: type.color_hex }} />
                    <span className="text-xs font-mono text-muted-foreground">{type.color_hex}</span>
                  </div>
                </td>

                {/* Počet POI s tímto typem */}
                <td className="px-3 py-3">
                  <PoiCountBadge typeId={type.id} />
                </td>

                {/* Status toggle */}
                <td className="px-3 py-3">
                  <button onClick={() => toggleActive(type)}>
                    <ActiveBadge active={type.is_active} />
                  </button>
                </td>

                {/* Akce */}
                <td className="px-3 py-3">
                  <div className="flex items-center gap-1 justify-end">
                    <button onClick={() => openEdit(type)}
                      className="p-1.5 hover:bg-muted rounded" title="Editovat">
                      <Pencil className="w-4 h-4" />
                    </button>
                    <ConfirmDialog
                      trigger={
                        <button className="p-1.5 hover:bg-red-50 rounded text-red-500" title="Smazat">
                          <Trash2 className="w-4 h-4" />
                        </button>
                      }
                      title="Smazat typ POI?"
                      description={`Smazat typ "${type.name?.cs}"? POI s tímto typem zůstanou bez kategorie.`}
                      confirmLabel="Smazat"
                      destructive
                      onConfirm={() => deleteType(type)}
                    />
                  </div>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>

      {/* Footer info */}
      <p className="text-xs text-muted-foreground">
        {types.length} typů celkem · {activeCount} aktivních
        {' '}· Pořadí určuje řazení v filtru mobilní aplikace.
      </p>

      {/* Modal pro přidání/editaci */}
      {showModal && (
        <PoiTypeModal
          type={editingType}
          onSaved={(saved) => {
            if (editingType) {
              setTypes(ts => ts.map(t => t.id === saved.id ? saved : t))
            } else {
              setTypes(ts => [...ts, saved].sort((a, b) => a.sort_order - b.sort_order))
            }
            setShowModal(false)
            toast.success(editingType ? 'Typ upraven' : 'Typ přidán')
          }}
          onClose={() => setShowModal(false)}
        />
      )}
    </div>
  )
}

// Náhled pinu – jak bude vypadat v mobilní aplikaci
function PoiTypePreview({ iconName, colorHex }: { iconName: string; colorHex: string }) {
  return (
    <div className="flex flex-col items-center gap-0.5 w-10">
      {/* Kruhový pin */}
      <div className="w-9 h-9 rounded-full border-2 border-white shadow-md flex items-center justify-center"
        style={{ backgroundColor: colorHex }}>
        <MaterialIcon name={iconName} size={18} color="white" />
      </div>
      {/* Hrot pinu */}
      <div className="w-0 h-0 border-l-[5px] border-r-[5px] border-t-[6px] border-l-transparent border-r-transparent"
        style={{ borderTopColor: colorHex }} />
    </div>
  )
}

// Async počítadlo POI pro daný typ
function PoiCountBadge({ typeId }: { typeId: string }) {
  const [count, setCount] = useState<number | null>(null)
  useEffect(() => {
    supabase.from('pois').select('id', { count: 'exact', head: true })
      .eq('type_id', typeId)
      .then(({ count: c }) => setCount(c ?? 0))
  }, [typeId])
  if (count === null) return <span className="text-xs text-muted-foreground">…</span>
  return (
    <span className={`text-sm font-medium ${count > 0 ? '' : 'text-muted-foreground'}`}>
      {count}
    </span>
  )
}
```

---

### 20.4 PoiTypeModal – přidání a editace typu

```
Modal design:

┌──────────────────────────────────────────────────┐
│  Přidat typ POI                            [✕]   │
│                                                  │
│  Náhled pinu:                                    │
│                    🏛️                            │ ← živý náhled
│                   ████                           │   aktualizuje se
│                  (indigo)                        │   při změně ikony/barvy
│                                                  │
│  Název                                           │
│  [CS] [EN] [DE]                                  │ ← tabs
│  ┌──────────────────────────────────┐            │
│  │  Restaurace                      │            │
│  └──────────────────────────────────┘            │
│                                                  │
│  Ikona                                           │
│  ┌──────────────────────────────────┐            │
│  │  🍽️  restaurant          ▾       │            │ ← select s ikonou
│  └──────────────────────────────────┘            │
│                                                  │
│  Barva pinu                                      │
│  ┌────────┐                                      │
│  │ #E53935│  [color picker]                      │
│  └────────┘                                      │
│  Rychlá volba:                                   │
│  ● ● ● ● ● ● ● ●  (8 přednastavených barev)     │
│                                                  │
│  Pořadí (číslo)    [ 60 ]                        │
│                                                  │
│              [Zrušit]  [Uložit typ]              │
└──────────────────────────────────────────────────┘
```

```tsx
// src/components/poi-types/PoiTypeModal.tsx
import { useState } from 'react'
import { supabase } from '@/lib/supabase/client'
import { MaterialIcon, POI_TYPE_ICONS } from '@/lib/poi-type-icons'
import { X } from 'lucide-react'

const LANGS = ['cs', 'en', 'de'] as const

// 8 přednastavených barev
const PRESET_COLORS = [
  '#5C6BC0', // indigo – budovy
  '#8D6E63', // hnědá – sochy
  '#546E7A', // šedá – architektura
  '#F57F17', // oranžová – památníky
  '#E53935', // červená – restaurace
  '#6D4C41', // tmavě hnědá – kavárny
  '#7B1FA2', // fialová – obchody
  '#388E3C', // zelená – příroda
  '#0277BD', // modrá – výhledy
  '#2D6A4F', // tmavě zelená – výchozí
]

interface PoiTypeModalProps {
  type?: any
  onSaved: (saved: any) => void
  onClose: () => void
}

export function PoiTypeModal({ type, onSaved, onClose }: PoiTypeModalProps) {
  const [activeLang, setActiveLang] = useState<'cs' | 'en' | 'de'>('cs')
  const [names, setNames] = useState<Record<string, string>>(type?.name ?? { cs: '', en: '', de: '' })
  const [iconName, setIconName] = useState(type?.icon_name ?? 'place')
  const [colorHex, setColorHex] = useState(type?.color_hex ?? '#2D6A4F')
  const [sortOrder, setSortOrder] = useState(type?.sort_order ?? 0)
  const [saving, setSaving] = useState(false)

  async function save() {
    if (!names.cs.trim()) return
    setSaving(true)
    const payload = {
      name: names,
      icon_name: iconName,
      color_hex: colorHex,
      sort_order: Number(sortOrder),
      updated_at: new Date().toISOString(),
    }
    if (type) {
      const { data } = await supabase.from('poi_types')
        .update(payload).eq('id', type.id).select().single()
      onSaved(data)
    } else {
      const { data } = await supabase.from('poi_types')
        .insert({ ...payload, is_active: true }).select().single()
      onSaved(data)
    }
    setSaving(false)
  }

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center">
      <div className="absolute inset-0 bg-black/40" onClick={onClose} />
      <div className="relative bg-card border rounded-xl shadow-xl w-full max-w-md mx-4 overflow-y-auto max-h-[90vh]">

        {/* Header */}
        <div className="flex items-center justify-between p-5 border-b">
          <h3 className="font-semibold text-base">
            {type ? 'Editovat typ POI' : 'Přidat typ POI'}
          </h3>
          <button onClick={onClose} className="p-1 hover:bg-muted rounded">
            <X className="w-4 h-4" />
          </button>
        </div>

        <div className="p-5 space-y-5">

          {/* Živý náhled pinu */}
          <div className="flex flex-col items-center py-3 bg-muted/30 rounded-lg">
            <p className="text-xs text-muted-foreground mb-3">Náhled pinu v aplikaci</p>
            <div className="flex flex-col items-center gap-0.5">
              <div className="w-12 h-12 rounded-full border-[3px] border-white shadow-lg flex items-center justify-center"
                style={{ backgroundColor: colorHex }}>
                <MaterialIcon name={iconName} size={22} color="white" />
              </div>
              <div className="w-0 h-0 border-l-[7px] border-r-[7px] border-t-[8px] border-l-transparent border-r-transparent"
                style={{ borderTopColor: colorHex }} />
            </div>
            <p className="text-xs font-medium mt-2" style={{ color: colorHex }}>
              {names[activeLang] || 'Název typu'}
            </p>
          </div>

          {/* Název – jazykové záložky */}
          <div>
            <label className="block text-sm font-medium mb-2">Název</label>
            <div className="flex border-b mb-3">
              {LANGS.map(l => (
                <button key={l} type="button" onClick={() => setActiveLang(l)}
                  className={`px-4 py-1.5 text-sm font-medium border-b-2 transition-colors ${
                    activeLang === l
                      ? 'border-primary text-primary'
                      : 'border-transparent text-muted-foreground hover:text-foreground'
                  }`}>
                  {l.toUpperCase()}
                  {!names[l] && l !== 'cs' && (
                    <span className="ml-1 text-orange-400 text-xs">!</span>
                  )}
                </button>
              ))}
            </div>
            <input
              value={names[activeLang] ?? ''}
              onChange={e => setNames(n => ({ ...n, [activeLang]: e.target.value }))}
              placeholder={activeLang === 'cs' ? 'Název (povinný)' : `Překlad – ${activeLang}`}
              className="input w-full"
            />
            {activeLang === 'cs' && !names.cs && (
              <p className="text-xs text-red-500 mt-1">Český název je povinný</p>
            )}
          </div>

          {/* Výběr ikony */}
          <div>
            <label className="block text-sm font-medium mb-2">Ikona</label>
            <select
              value={iconName}
              onChange={e => setIconName(e.target.value)}
              className="input w-full"
            >
              {POI_TYPE_ICONS.map(icon => (
                <option key={icon.name} value={icon.name}>
                  {icon.label} ({icon.name})
                </option>
              ))}
            </select>
            {/* Náhled aktuální ikony */}
            <div className="mt-2 flex items-center gap-2 text-sm text-muted-foreground">
              <MaterialIcon name={iconName} size={18} />
              <span className="font-mono text-xs">{iconName}</span>
            </div>
          </div>

          {/* Výběr barvy */}
          <div>
            <label className="block text-sm font-medium mb-2">Barva pinu</label>
            <div className="flex items-center gap-3 mb-3">
              <input
                type="color"
                value={colorHex}
                onChange={e => setColorHex(e.target.value)}
                className="w-10 h-10 rounded border cursor-pointer p-0.5"
              />
              <input
                value={colorHex}
                onChange={e => {
                  const v = e.target.value
                  if (/^#[0-9A-Fa-f]{0,6}$/.test(v)) setColorHex(v)
                }}
                placeholder="#2D6A4F"
                className="input w-28 font-mono text-sm"
                maxLength={7}
              />
            </div>
            {/* Přednastavené barvy */}
            <div>
              <p className="text-xs text-muted-foreground mb-2">Rychlá volba:</p>
              <div className="flex flex-wrap gap-2">
                {PRESET_COLORS.map(c => (
                  <button
                    key={c}
                    type="button"
                    onClick={() => setColorHex(c)}
                    className="w-7 h-7 rounded-full border-2 transition-transform hover:scale-110"
                    style={{
                      backgroundColor: c,
                      borderColor: colorHex === c ? 'black' : 'transparent',
                    }}
                    title={c}
                  />
                ))}
              </div>
            </div>
          </div>

          {/* Pořadí */}
          <div>
            <label className="block text-sm font-medium mb-1">
              Pořadí v mobilní aplikaci
            </label>
            <input
              type="number"
              value={sortOrder}
              onChange={e => setSortOrder(e.target.value)}
              className="input w-24"
              min={0}
              step={10}
            />
            <p className="text-xs text-muted-foreground mt-1">
              Nižší číslo = výše ve filtru. Doporučujeme násobky 10.
            </p>
          </div>
        </div>

        {/* Footer */}
        <div className="flex gap-3 justify-end p-5 border-t bg-muted/20">
          <button onClick={onClose}
            className="px-4 py-2 border rounded text-sm hover:bg-muted">
            Zrušit
          </button>
          <button
            onClick={save}
            disabled={!names.cs.trim() || saving}
            className="px-4 py-2 bg-primary text-white rounded text-sm disabled:opacity-50"
          >
            {saving ? 'Ukládám...' : type ? 'Uložit změny' : 'Přidat typ'}
          </button>
        </div>
      </div>
    </div>
  )
}
```

---

### 20.5 Integrace typů do PoiForm

```tsx
// src/components/pois/PoiForm.tsx – přidat výběr typu

// Přidat state pro načtení typů:
const [poiTypes, setPoiTypes] = useState<any[]>([])
useEffect(() => {
  supabase.from('poi_types').select('id, name, icon_name, color_hex')
    .eq('is_active', true).order('sort_order')
    .then(({ data }) => setPoiTypes(data ?? []))
}, [])

// Přidat do defaultValues:
// type_id: poi?.type_id ?? null,

// Přidat do formuláře (za checkbox is_premium):
<div>
  <label className="block text-sm font-medium mb-1">Typ POI</label>
  <select {...register('type_id')} className="input w-full">
    <option value="">— Bez kategorie —</option>
    {poiTypes.map(t => (
      <option key={t.id} value={t.id}>
        {t.name?.cs}
        {t.name?.en ? ` / ${t.name.en}` : ''}
      </option>
    ))}
  </select>
  {/* Náhled vybraného typu */}
  {watch('type_id') && (() => {
    const selected = poiTypes.find(t => t.id === watch('type_id'))
    if (!selected) return null
    return (
      <div className="mt-2 flex items-center gap-2 p-2 bg-muted/30 rounded text-sm">
        <div className="w-6 h-6 rounded-full flex items-center justify-center"
          style={{ backgroundColor: selected.color_hex }}>
          <MaterialIcon name={selected.icon_name} size={14} color="white" />
        </div>
        <span>{selected.name?.cs}</span>
        <span className="text-xs text-muted-foreground font-mono">({selected.color_hex})</span>
      </div>
    )
  })()}
</div>
```

---

### 20.6 Integrace typů do PoisPage – filtr dle typu

```tsx
// src/pages/pois/PoisPage.tsx – přidat filtr dle typu

// Přidat state:
const [filterTypeId, setFilterTypeId] = useState('')
const [poiTypes, setPoiTypes] = useState<any[]>([])

useEffect(() => {
  supabase.from('poi_types').select('id, name').eq('is_active', true).order('sort_order')
    .then(({ data }) => setPoiTypes(data ?? []))
}, [])

// Přidat select filtr vedle search inputu:
<select value={filterTypeId} onChange={e => setFilterTypeId(e.target.value)} className="input w-44">
  <option value="">Všechny typy</option>
  {poiTypes.map(t => (
    <option key={t.id} value={t.id}>{t.name?.cs}</option>
  ))}
</select>

// Aktualizovat filtrování:
const filtered = pois.filter(p => {
  const matchSearch = !search
    || p.name?.cs?.toLowerCase().includes(search.toLowerCase())
    || p.name?.en?.toLowerCase().includes(search.toLowerCase())
  const matchType = !filterTypeId || p.type_id === filterTypeId
  return matchSearch && matchType
})

// Přidat type_id do Supabase query v loadPois():
// .select('*, poi_types(id, name, icon_name, color_hex)')

// Přidat sloupec "Typ" do columns:
{
  id: 'type', header: 'Typ',
  cell: ({ row }: any) => {
    const t = row.original.poi_types
    if (!t) return <span className="text-xs text-muted-foreground">—</span>
    return (
      <div className="flex items-center gap-1.5">
        <div className="w-5 h-5 rounded-full flex items-center justify-center shrink-0"
          style={{ backgroundColor: t.color_hex }}>
          <MaterialIcon name={t.icon_name} size={12} color="white" />
        </div>
        <span className="text-xs">{t.name?.cs}</span>
      </div>
    )
  }
},
```

---

### 20.7 Dashboard – statistika typů

```tsx
// Přidat do DashboardPage jako nová karta pod stávajícími metrikami:

// Supabase query – počet POI per typ:
const { data: typeStats } = await supabase.rpc('poi_types_stats')

// SQL funkce (přidat do 005_dashboard_rpc.sql):
// CREATE OR REPLACE FUNCTION public.poi_types_stats()
// RETURNS TABLE(type_name TEXT, icon_name TEXT, color_hex TEXT, poi_count BIGINT)
// LANGUAGE sql SECURITY DEFINER AS $$
//   SELECT t.name->>'cs', t.icon_name, t.color_hex, COUNT(p.id)
//   FROM public.poi_types t
//   LEFT JOIN public.pois p ON p.type_id = t.id AND p.is_active = TRUE
//   WHERE t.is_active = TRUE
//   GROUP BY t.id, t.name, t.icon_name, t.color_hex
//   ORDER BY t.sort_order;
// $$;

// Widget:
<div className="border rounded-lg p-4">
  <h3 className="font-medium mb-3 text-sm">POI podle typů</h3>
  <div className="space-y-2">
    {typeStats?.map((s: any) => (
      <div key={s.type_name} className="flex items-center gap-2">
        <div className="w-5 h-5 rounded-full flex items-center justify-center shrink-0"
          style={{ backgroundColor: s.color_hex }}>
          <MaterialIcon name={s.icon_name} size={12} color="white" />
        </div>
        <span className="text-sm flex-1">{s.type_name}</span>
        <span className="text-sm font-medium">{s.poi_count}</span>
        <div className="w-20 bg-muted rounded-full h-1.5">
          <div className="h-1.5 rounded-full"
            style={{
              backgroundColor: s.color_hex,
              width: `${Math.min(100, (s.poi_count / Math.max(...typeStats.map((x:any) => x.poi_count))) * 100)}%`
            }} />
        </div>
      </div>
    ))}
  </div>
</div>
```

---

### 20.8 Doplnit do roadmapy (sekce 18 + 19.8)

```
Přidat za krok 10 (AudioUploader):

10a | DB migrace 006_poi_types.sql + seed dat     | Tabulka poi_types existuje
10b | poi-type-icons.ts + MaterialIcon komponenta | Ikony renderují správně
10c | PoiTypesPage – tabulka se seřazením         | CRUD typů funguje
10d | PoiTypeModal – přidání/editace s náhledem   | Modal s živým náhledem
10e | Integrace type_id do PoiForm                | POI lze přiřadit typ
10f | Filtr dle typu v PoisPage                   | Filtrování POI funguje
10g | poi_types_stats RPC + Dashboard widget      | Statistika typů na dashboardu
10h | index.html – Material Icons font link       | Ikony se zobrazují
```

---

### 20.9 Doplnění do DB migrací (sekce 15)

```
supabase/migrations/006_poi_types.sql  ← nová tabulka + type_id v pois + seed
supabase/migrations/007_poi_types_rpc.sql  ← poi_types_stats funkce

-- 007_poi_types_rpc.sql:
CREATE OR REPLACE FUNCTION public.poi_types_stats()
RETURNS TABLE(type_name TEXT, icon_name TEXT, color_hex TEXT, poi_count BIGINT)
LANGUAGE sql SECURITY DEFINER AS $$
  SELECT
    t.name->>'cs' AS type_name,
    t.icon_name,
    t.color_hex,
    COUNT(p.id) AS poi_count
  FROM public.poi_types t
  LEFT JOIN public.pois p ON p.type_id = t.id AND p.is_active = TRUE
  WHERE t.is_active = TRUE
  GROUP BY t.id, t.name, t.icon_name, t.color_hex
  ORDER BY t.sort_order;
$$;
GRANT EXECUTE ON FUNCTION public.poi_types_stats TO service_role;
```
