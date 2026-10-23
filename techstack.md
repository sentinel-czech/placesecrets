# PlaceSecrets — Tech stack

> Přehled technologií, na kterých PlaceSecrets běží, proč jsou zvolené a kde najdeš
> specifikace/prompty, ze kterých kód vznikl. Stav k 23. 10. 2026. Verze odpovídají
> `web/package.json`, `app/pubspec.yaml` a `backend/supabase/config.toml`.
>
> Pracovní název projektu ve starších specifikacích je **HeroDots**, jde o tentýž produkt.

---

## 1. Architektura v kostce

```
 ┌──────────────────────┐     ┌──────────────────────────┐
 │ Mobilní app (Flutter)│     │ Web + Admin (React SPA)  │
 │ Android / iOS        │     │ Netlify (alt. Vercel)    │
 └──────────┬───────────┘     └────────────┬─────────────┘
            │ supabase_flutter             │ supabase-js (anon key)
            ▼                              ▼
 ┌────────────────────────────────────────────────────────┐
 │                   SUPABASE (Cloud)                     │
 │  PostgreSQL 15 + RLS │ Auth │ Storage │ Edge Functions │
 └──────────┬─────────────────────────────────────────────┘
            │ (jen z Edge Functions, secrets v Supabase)
            ▼
  Stripe · Comgate · Resend (e-mail) · Firebase FCM (push)
  + OpenStreetMap dlaždice (mapy) · Sentry (chyby webu)
```

Web a mobil sdílí **jeden backend**. Vlastní server nemáme — vše privilegované běží
v Supabase Edge Functions.

---

## 2. Backend — Supabase

### Co z Supabase používáme

| Část | Použití | Kde v repu |
|---|---|---|
| **PostgreSQL 15** | Veškerá data (města, POI, audio, platby, účtenky, ACL, …). RLS na všech tabulkách, logika v RPC funkcích (`SECURITY DEFINER` + `SET search_path`). 66 migrací, forward-only. | `backend/supabase/migrations/` |
| **Auth** | Anonymní přihlášení (mobil funguje hned bez registrace) + e-mail. Rotace refresh tokenů, JWT 1 h. Admin navíc PIN (2. faktor). | `backend/supabase/config.toml` |
| **Storage** | Buckety `poi-photos`, `audio-guides`, `payment-receipts`, limit souboru 50 MiB. | migrace 016 + storage policies |
| **Edge Functions** | Deno + TypeScript. Vše, co potřebuje `service_role` nebo tajné klíče (platby, admin operace, účtenky, GDPR). | `backend/supabase/functions/` |
| **Supabase CLI** | 2.77.0 přes `npx supabase` — lokální stack, migrace, deploy funkcí. | `backend/LOCAL_DEV.md` |

### Proč Supabase

- **Jeden spravovaný backend místo vlastních serverů.** Databáze, přihlášení, úložiště souborů
  a serverless funkce v jednom. Malý tým nemusí provozovat ani patchovat servery.
- **Autorizace přímo v databázi (RLS).** Pravidla přístupu platí stejně pro web i mobil,
  nejde je obejít jiným klientem. Klient má jen veřejný `anon` klíč.
- **Nativní anonymní účty.** Mobil je offline-first a uživatel může začít bez registrace;
  po vytvoření účtu se data převedou (`migrate-anonymous-data`).
- **Oficiální SDK pro Flutter i JavaScript** — stejné API na obou klientech.
- **Lokální prostředí 1:1 s produkcí** (`supabase start` v Dockeru) — migrace a funkce se
  testují lokálně stejně, jako poběží v cloudu.
- **Cena podle použití.** Pro tarif $25/měs. pokrývá 100 tis. aktivních uživatelů, 8 GB DB,
  100 GB souborů a 250 GB přenosu (viz business plán, kap. náklady).
- **Žádný vendor lock-in na datech.** Je to standardní PostgreSQL — data i SQL migrace jdou
  přenést jinam.
- **Známá slabina:** přenos audia. Až se přiblíží 250 GB/měs., hotové audio se přesune na
  Cloudflare R2 (přenos zdarma). Zatím neimplementováno.

### Edge Functions

| Funkce | Účel |
|---|---|
| `admin-api` | Proxy pro všechny admin operace (CRUD nad tabulkami, RPC, storage) — kontrola role, ACL, whitelist tabulek/sloupců, audit log |
| `verify-admin-pin` / `change-admin-pin` | Druhý faktor pro admin (bcrypt PIN, 5 pokusů → 15 min zámek, vynucená změna výchozího PINu) |
| `invite-contributor` | Pozvánka / založení přispěvatele |
| `create-payment-intent`, `create-poi-checkout` | Založení platby přes Stripe (město / jednotlivé POI) |
| `confirm-payment`, `confirm-poi-payment`, `payment-webhook` | Potvrzení platby a přidělení přístupu (Stripe, Google/Apple Pay, Revolut, admin grant) |
| `stripe-refund` | Refundace |
| `comgate-create`, `comgate-webhook` | Česká platební brána Comgate (scaffolding, čeká na produkční credentials) |
| `generate-receipt` | PDF účtenka (EU spotřebitelské právo) + odeslání e-mailem přes Resend |
| `delete-user-data` | GDPR smazání účtu |
| `migrate-anonymous-data` | Převod dat anonymního uživatele na nový účet |
| `_shared/` | Společný kód (CORS, auth helpery) |

**Bezpečnostní model:** `service_role` klíč a platební tajemství existují **jen** v Edge
Functions (`npx supabase secrets set …`). Frontend nikdy nemá `service_role`. Přehled secrets
je v `backend/DEPLOYMENT.md`.

---

## 3. Web + Admin — `web/`

Jedna SPA pro veřejný web, uživatelský účet (`/account/*`) i administraci (`/admin/*`).

| Oblast | Technologie |
|---|---|
| Build / jazyk | **Vite 8**, **TypeScript 5.9** |
| UI framework | **React 19** (starší specifikace uvádějí React 18 — platí `package.json`) |
| Styly / komponenty | **Tailwind CSS v4**, **shadcn/ui** nad `@base-ui/react` (ne Radix — místo `asChild` je `render` prop), lucide ikony, Geist font, `sonner` toasty |
| Routing | React Router 7 |
| Stav | Zustand (auth store) |
| Formuláře | react-hook-form + zod |
| Tabulky / grafy | TanStack Table, Recharts |
| Mapy | Leaflet + react-leaflet + markercluster (OpenStreetMap) |
| i18n | i18next + react-i18next, 11 jazyků (en, cs, sk, de, es, fr, pt, ru, vi, zh, ko) |
| Exporty | jsPDF, JSZip (GDPR export), PapaParse (CSV) |
| Monitoring | Sentry (`web/src/lib/monitoring.ts`) |
| SEO | react-helmet-async |
| Backend klient | `@supabase/supabase-js`; admin volání přes `web/src/lib/supabase/admin-api.ts` |

**Hosting:** Netlify (`web/netlify.toml` — build z `web/`, SPA fallback, CSP a bezpečnostní
hlavičky), alternativně Vercel (`web/vercel.json`). Proč: statický build, žádný server,
CDN a HTTPS zdarma.
**Env proměnné (build time):** `VITE_SUPABASE_URL`, `VITE_SUPABASE_ANON_KEY` (viz `web/.env.example`).

---

## 4. Mobilní aplikace — `app/`

Flutter 3.41 / Dart 3.11, Android (min SDK 23, target 34) a iOS (min 14.0).

| Oblast | Technologie |
|---|---|
| Stav | Riverpod (+ `riverpod_generator`, hooks_riverpod) |
| Navigace | GoRouter |
| Backend | `supabase_flutter` |
| Lokální DB (offline-first) | Drift (SQLite) |
| Mapy | `flutter_map` + `flutter_map_tile_caching` (OpenStreetMap — bez Google Maps kvůli licenci a ceně; offline dlaždice) |
| Poloha / geofencing | `geolocator`, `flutter_background_geolocation` (spuštění audia při vstupu do okruhu POI) |
| Audio | `just_audio` (+ background), `flutter_tts`, `audio_session` |
| Platby | `pay` (Google Pay / Apple Pay), Revolut přes deep link (`url_launcher`) |
| Push notifikace | Firebase Messaging + `flutter_local_notifications` |
| Deep linky | `app_links` (smart URI míst, návrat z platby) |
| PDF | `pdf`, `printing` (export cestovního deníku) |
| Ostatní | `dio`, `workmanager` (sync na pozadí), `connectivity_plus`, `share_plus`, `image_picker` |
| Generování kódu | `build_runner`, freezed, json_serializable, drift_dev |

Build a release: `app/BUILD.md`.

---

## 5. Externí služby

| Služba | K čemu | Kde se nastavuje |
|---|---|---|
| **Stripe** | Karetní platby, refundy, webhooky | Supabase secrets `STRIPE_*` |
| **Comgate** | Česká platební brána (připraveno) | `COMGATE_MERCHANT`, `COMGATE_SECRET` |
| **Google Pay / Apple Pay** | Platby v mobilu | balíček `pay` |
| **Revolut** | Platba přes deep link | `payment_config.revolut_username` |
| **Resend** | Transakční e-maily (účtenky) | `RESEND_API_KEY` |
| **Firebase** | Push notifikace (FCM) | Firebase projekt + `user_profiles.fcm_token` |
| **Sentry** | Hlášení chyb webu | DSN v env webu |
| **OpenStreetMap** | Mapové dlaždice (web i mobil) | — |

---

## 6. Kde to běží

| Prostředí | Backend | Web | Mobil |
|---|---|---|---|
| **Lokál** | Supabase CLI v Dockeru: API `:54321`, DB `:54322`, Studio `:54323`, Inbucket (e-maily) `:54324` | Vite dev server `:5173` | `flutter run` proti lokálnímu Supabase |
| **Staging** | Druhý Supabase projekt (plánováno, viz business plán) | Netlify preview | interní testovací build |
| **Produkce** | Supabase Cloud (Pro) | Netlify — `placesecrets.app` / `admin.placesecrets.app` | Google Play, App Store |

Pomocné skripty v kořeni: `dev.sh` (backend + frontend), `start_backend.sh`, `start_frontend.sh`,
`stop.sh`, `reset-db.sh` (**destruktivní** reset lokální DB + seed), `test.sh`.

Návody:
- [DEV.md](DEV.md) — lokální vývoj, seed přihlašovací údaje
- [backend/LOCAL_DEV.md](backend/LOCAL_DEV.md) — lokální Supabase
- [backend/DEPLOYMENT.md](backend/DEPLOYMENT.md) — deploy migrací, funkcí a secrets
- [backend/PRODUCTION_SETUP.md](backend/PRODUCTION_SETUP.md) — produkční data (země, config, první admin)
- [app/BUILD.md](app/BUILD.md) — build mobilní aplikace
- [RELEASE-CHECKLIST.md](RELEASE-CHECKLIST.md) — checklist před vydáním

---

## 7. Testy a CI

| Co | Nástroj |
|---|---|
| Web unit/komponenty | Vitest + Testing Library + jsdom, MSW (mock API) |
| Web E2E | Playwright (`web/e2e/`) |
| Edge Functions | Vitest (`backend/supabase/functions/__tests__/`) |
| Mobil | `flutter analyze`, `flutter test`, mockito |
| CI | GitHub Actions — [.github/workflows/ci.yml](.github/workflows/ci.yml): web (lint, tsc, build, vitest, `npm audit`), edge functions, mobil, e2e |
| Pre-commit | Secret-scan hook v `.githooks/` (zapnout dle `DEV.md`) |

---

## 8. Business a prompty

### Business

- [PlaceSecrets Business Plan.md](PlaceSecrets%20Business%20Plan.md) — business plán a review
  (cílový stav produktu, ceny, náklady na infrastrukturu, roadmapa).

### Prompty a specifikace

Kód vznikal z promptů pro Claude Code v tomto pořadí: základní specifikace → diff specifikace
(přírůstkové změny) → analýzy/fix-prompty. **Aktuálně závazný je remediation prompt** — přepisuje
odchylky ve starších specifikacích.

**Závazný cílový stav**

| Soubor | Obsah |
|---|---|
| [PlaceSecrets-remediation-prompt.md](PlaceSecrets-remediation-prompt.md) | Sjednocení, opravy a napojení na business plán (v1.1, 16. 10. 2026). Nahrazuje odchylky ve všech níže uvedených specifikacích. |

**Základní specifikace**

| Soubor | Část | Obsah |
|---|---|---|
| [specification-prompts.md](specification-prompts.md) | Mobil | Specifikace Flutter aplikace (v2.0), sekce 1–17 |
| [spec-prompts-admin.md](spec-prompts-admin.md) | Admin | Původní administrace (v2.0, Vite + React) |
| [spec-placesecrets-web.md](spec-placesecrets-web.md) | Web | Webové rozhraní (v3.0 — merge admin specifikace + diff-admin-001 + admin PIN) |

**Diff specifikace (chronologicky)**

| Soubor | Část | Obsah |
|---|---|---|
| [diff-specification-001.md](diff-specification-001.md) | Mobil | Hodnocení, přispěvatelé, Hall of Fame |
| [diff-specification-admin-001.md](diff-specification-admin-001.md) | Admin/web | Diff administrace k diff-001 |
| [diff-specification-002.md](diff-specification-002.md) | Vše | Přístupové úrovně POI, prémiový obsah, Smart URI sdílení |
| [diff-specification-003_web_admin.md](diff-specification-003_web_admin.md) | Web | Administrace a uživatelské rozhraní (i18n, mapy, účet) |
| [diff-specification-004_acl_user_management.md](diff-specification-004_acl_user_management.md) | Web + backend | ACL systém a sjednocená správa uživatelů |
| [diff-specification-005_city_tree.md](diff-specification-005_city_tree.md) | Web | Hierarchický strom měst a míst |
| [diff-specification-006_place_detail.md](diff-specification-006_place_detail.md) | Web + backend | PlaceDetailPage, tabulka `poi_audio_guides` |
| [diff-specification-007_i18n_form_fixes.md](diff-specification-007_i18n_form_fixes.md) | Web | i18n formulářů POI, perex JSONB |
| [diff-specification-008_audio_row_redesign.md](diff-specification-008_audio_row_redesign.md) | Web | Redesign řádku audio průvodce, přehrávač |

**Analýzy, fix-prompty a pracovní poznámky**

| Soubor | Obsah |
|---|---|
| [APP-GAP-ANALYSIS.md](APP-GAP-ANALYSIS.md) | Hloubková gap analýza celého produktu (master fix-prompt, stav 14. 6. 2026) |
| [MOBILE-PARITY.md](MOBILE-PARITY.md) | Stav mobilu a parita s webem |
| [todo-plan.md](todo-plan.md) | Implementační plán (free verze webu + hardening) |
| [insturkce](insturkce) | Ručně psané požadavky na administraci (strom zemí/měst, uživatelé, překlady) |

**Testy**

| Soubor | Obsah |
|---|---|
| [tests.md](tests.md) | Komplexní testovací plán (DB, Edge Functions, web, mobil) |
| [tst-prompt.md](tst-prompt.md) | Audit GUI testů webu a mobilu (prompt pro doplnění testů) |

**Další dokumentace**

- [CLAUDE.md](CLAUDE.md) — instrukce pro Claude Code v tomto repu
- [tex/manual-administrator.pdf](tex/manual-administrator.pdf) — manuál administrátora (zdroj `tex/manual-administrator.tex`)
- [project-documentation.pdf](project-documentation.pdf) — projektová dokumentace
- [web/README.md](web/README.md), [app/README.md](app/README.md) — README jednotlivých částí
