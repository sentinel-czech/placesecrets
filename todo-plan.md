# todo-plan.md — implementační plán (free verze webu + hardening)

Living plán. `~~přeškrtnuté~~` = ověřeno v kódu jako hotové (neimplementovat). Zbytek = k implementaci.
Rozsah free verze: **vyhledávání po přihlášení + náhledy/procházení (katalog měst i search) + reset hesla**,
sjednocené společnou `PoiCard`. Detaily a verifikace dole.

---

## Hotovo (ověřeno) — neimplementovat

Bezpečnostní průchod (commity v gitu):
- ~~npm závislosti 19 → 0 zranitelností (`npm audit fix`)~~
- ~~`git init` + kořenový `.gitignore` + sjednocení monorepa~~
- ~~PIN sjednocen na přesně 6 číslic (sdílené `PIN_RE`) — opraven i latentní lockout bug~~
- ~~migrace `0444`: `acl_permissions` SELECT jen authenticated + drop mrtvého `payment_config.stripe_secret_key` (ověřeno v živé DB)~~
- ~~`ForceChangePinPage` `!user` → `/login` (defense-in-depth)~~
- ~~`generate_docs.py` oprava staré cesty + `web/README.md` + `web/.env.example` + regen PDF~~
- ~~flaky test `AclManagementPage` → deterministický (`getByRole`→`querySelector`, 5557 ms → 107 ms; bez zvýšení timeoutu)~~

Funkční jádro (ověřeno):
- ~~Zobrazení místa — `PlaceDetailPage` (foto, popis, audio guides, mapa, hodnocení, recenze)~~
- ~~Administrace míst — `CitiesPage`/`PoisPage`/`PoiEditPage` + moderace POI recenzí~~
- ~~Přihlášení — email/heslo + OAuth (Google/FB/Apple), session persistence, logout~~
- ~~Správa účtu — `AccountProfilePage` (profil, změna emailu/hesla, záložní email, mazání účtu, účtenky)~~
- ~~Hodnocení audio guidů — submit i zobrazení v `PlaceDetailPage`~~
- ~~Mapové procházení míst — `ExploreMap` / `AccountExplorePage`~~

---

## A. Free verze — HOTOVO ✅ (tento průchod, commit `feat(web): free-version browsing…`)

Vše dole dodáno a otestováno (web 293 testů, edge 70, `search_pois` ověřeno přes `supabase db reset`).
Ponecháno jako záznam; položky přeškrtnuté.

### ~~A1. Společná `PoiCard` (základ náhledů)~~ ✅
- Nová `web/src/components/places/PoiCard.tsx`: foto (`photo_urls[0]` / placeholder), název dle jazyka,
  perex snippet, hvězdičky (`avg_rating`/`total_ratings`), access badge, odkaz `/{country}/{citySlug}/{slug}`.
- Vytáhnout duplikovanou logiku z `components/account/PlaceDetailSheet.tsx` a featured karet `pages/LandingPage.tsx`;
  obě přepojit na `PoiCard` (landing pak s **reálnými fotkami**, ne natvrdo příklady).
- Reuse: `Badge`, `Star` (lucide), jazyk `i18n.language.substring(0,2)`.

### ~~A2. Vyhledávání míst (po přihlášení) — migrace 0445 search_pois~~ ✅
- **DB**: migrace `0445_search_pois.sql` — RPC `search_pois(p_query text, p_limit int default 30)`,
  `SECURITY DEFINER SET search_path = public`, `GRANT EXECUTE TO anon, authenticated`. ILIKE přes
  `name->>lang`, `aliases`, perex, název města; jen `is_active = true`; řazení relevance + `avg_rating`.
  Vrací preview sloupce (id, name, perex, slug, city_slug, country_code, access_level, avg_rating,
  total_ratings, photo_urls, type_id). Vzor: `027_acl_rpcs.sql`, `0442_get_poi_reviews_user_priority.sql`.
- **UI**: `web/src/pages/account/SearchPage.tsx` + route `/account/search` (pod `AccountGuard`).
  Debounced input → `supabase.rpc('search_pois', { p_query })`, výsledky = grid `PoiCard`.
  Reuse debounce z `pages/cities/CitiesPage.tsx`.

### ~~A3. Katalog procházení — města → místa~~ ✅
- **Katalog měst**: `web/src/pages/account/CitiesCatalogPage.tsx` + route `/account/cities`.
  `supabase.from('cities').select(...).eq('is_active', true)` (RLS dovoluje anon read — viz `LandingPage.tsx:38`).
  Grid karet měst (název, země, počet míst).
- **Místa ve městě**: `web/src/pages/account/CityPlacesPage.tsx` + route `/account/cities/:countryCode/:citySlug`.
  `supabase.from('pois').select(preview).eq('city_id', …).eq('is_active', true)` (vzor `ExploreMap.tsx`).
  Grid `PoiCard`; detail reuse veřejné route `/:countryCode/:citySlug/:poiSlug`.
- Fallback: kdyby RLS nestačil, doplnit RPC `list_published_cities()` / `list_city_pois(city_id)`.

### ~~A4. Reset zapomenutého hesla~~ ✅
- `web/src/pages/ForgotPasswordPage.tsx` + route `/forgot-password` (public):
  `supabase.auth.resetPasswordForEmail(email, { redirectTo: origin + '/reset-password' })`.
- `web/src/pages/ResetPasswordPage.tsx` + route `/reset-password` (public): zachytit `PASSWORD_RECOVERY`
  (`onAuthStateChange`) → nové heslo → `supabase.auth.updateUser({ password })` → `/login`.
- Odkaz „Zapomenuté heslo?" v `pages/LoginPage.tsx`. Vzor: `AccountProfilePage` (volá `auth.updateUser`).
- Env: vyžaduje Auth e-mailové šablony/SMTP v Supabase — ověřit v prostředí.

### ~~A5. Sjednocení navigace~~ ✅
- `components/layout/AccountShell.tsx`: globální search box (→ `/account/search`) + odkazy Explore / Katalog / Hledat.
  `LandingPage` CTA → `/account/cities`. Konzistentní `PoiCard` všude.

### ~~A6. Submit hodnocení místa~~ ✅
- Do `PlaceDetailPage` (tab Rating) formulář hvězdy+komentář, upsert do `poi_ratings` (RLS to dovoluje).
  Volitelné — hodnocení audio guidů už funguje.

### ~~A7. Resend potvrzovacího e-mailu~~ ✅
- Tlačítko na success `RegisterPage` → `supabase.auth.resend({ type: 'signup', email })`.

### Testy k A
- Unit `PoiCard`; page testy (mock `supabase.rpc`/`from`): Search, CitiesCatalog, CityPlaces, ForgotPassword, ResetPassword.
- DB: `search_pois` přes `supabase db reset` + dotaz (ILIKE vrací jen `is_active`). Cíl: `./test.sh` zeleno, `npm audit` 0.

---

## B. Hardening / cleanup

**P1:**
- ~~Smazat mrtvý top-level `supabase/`~~ ✅
- ~~`reset-db.sh` potvrzovací prompt + dev creds → DEV.md~~ ✅
- ~~Vyjmenovat povinné env v dodávaných artefaktech~~ ✅ (DEV.md „Production env"). **Zbývá:** ověřit při reálném deployi (start z artefaktů).
- **Zbývá:** live test edge funkcí přes `supabase functions serve` (refund 403 / admin-api 401 / force-pin redirect) — logika ověřena unit testy + DB, ne živým voláním.

**P2:**
- ~~Vite 8 upgrade~~ ✅ (nová dev-server CVE; audit 0). **Odloženo:** TS 6 (i18next peer `typescript:^5`) a eslint 10 (✗ `typescript-eslint@8`) — až ekosystém dozraje.
- ~~Web bundle code-split (2,5 MB → 559 kB main)~~ ✅
- ~~Lint dluh → 0 errors~~ ✅ (20 warnings ponecháno; CI gate přidán)
- ~~Edge-fn hardening: UUID metadata (confirm-poi-payment), max délka emailu (invite-contributor)~~ ✅ (content-type v payment-webhook ponechán `includes` — Stripe posílá `; charset=utf-8`).
- ~~DB medium: ověřeno~~ ✅ — `backup_email` už chráněn RLS „read own profile" (019); `payment_receipts` owner-read + mutace jen service_role; anon device-id rating je záměrně off (009). Žádná migrace netřeba.

**P3:**
- ~~Odstranit `admin.herodots.app` z CORS allowlistů~~ ✅. Wildcard u `create-poi-checkout`/`confirm-poi-payment` ponechán (chrání JWT/Stripe podpis; allowlist by rozbil veřejný nákup).
- ~~CI pipeline (`.github/workflows/ci.yml`: lint+tsc+build+test+audit) + secret-scan pre-commit hook~~ ✅
- ~~Branding `operator_name` HeroDots → PlaceSecrets~~ ✅ (seed + migrace 0446 + generate_docs). **Zbývá (mimo rozsah):** balíček `cz.tuma.herodots` / `herodots.iml` (breaking pro app store — samostatná úloha).
- **Zbývá:** generovaný PDF v gitu (zvážit generování v CI místo commitování). Konvence migrací: nepřečíslovávat, forward-only (rozhodnuto).
- **Zbývá:** Flutter závislosti review (mobil). Admin UI pro moderaci hodnocení audio guidů (dnes jen POI recenze).
