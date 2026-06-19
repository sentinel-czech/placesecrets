# PlaceSecrets — hloubková gap analýza celého produktu (fix-prompt)

> Stav k **2026-06-14**. Tento dokument je **podklad pro opravy** (master fix-prompt). Pokrývá mobil
> (Flutter `app/`), web (`web/`), backend + edge functions (`backend/`) a průřezové téma infra/ops/compliance.

## Účel a jak ho používat
Funkčně je produkt daleko: web ~85 % (admin + free portál, 293 testů, CI), backend 61 migrací + 15 edge
funkcí, mobil má hotovou kritickou i vysokou paritu (224 testů). Tato analýza hledá **zbývající díry**,
zejména to, co reálně selže při běhu nebo blokuje launch. Každá položka má **vrstvu, soubor:řádek, problém
a směr opravy** — lze ji rozsekat na samostatné fix tasky (viz „Doporučené pořadí oprav").

## Metodika a ověření
6 Explore agentů (3 mobil, 1 web, 1 backend, 1 infra/ops). Klíčová „blocks launch" tvrzení byla **ověřena
přímo ve zdroji**. Dvě tvrzení agentů byla **mylná** a jsou vedena samostatně (sekce „Vyvrácené nálezy") —
do oprav NEpatří. Značení: `[✓zdroj]` = ověřeno ve zdroji, `[agent]` = hlášeno agentem, do hloubky neověřeno
(před opravou znovu ověřit — externí review je signál o slepém místě, ne důkaz).

## Stav oprav (živé)
- **Vlna 1 — mobil „aby nastartoval a šel vydat": ✅ HOTOVO 2026-06-14**
  - A1 ✅ resilient Firebase init (`firebase_bootstrap.dart`, guarded `main.dart`) — appka nastartuje i bez
    Firebase configu. Lidský krok (reálný Firebase projekt/config) zdokumentován v `app/BUILD.md`.
  - A2 ✅ placeholder brand ikona (`assets/icons/app_icon.png`) + `flutter_launcher_icons` (iOS bez alpha).
    Lidský krok: finální brand ikona (BUILD.md).
  - A3 ✅ release signing přes `android/key.properties` (+ `.example`, fallback na debug). Lidský krok: keystore.
  - A6 ✅ `Env.assertConfigured()` fail-fast + `--dart-define-from-file` šablony + `app/BUILD.md`.
  - Ověření: `flutter analyze` 0 errors, `flutter test` **228** (+4 nové startup testy), `flutter_launcher_icons` OK.
- **Vlna 2 — mobil „aby fungoval jak slibuje": ✅ HOTOVO 2026-06-14**
  - A4 ✅ deep-link registrace: Android intent-filters (`placesecrets://` + App Links https) + iOS `CFBundleURLTypes`.
    Lidský/server krok: `assetlinks.json` / `apple-app-site-association` (BUILD.md §5).
  - A5 ✅ `DeepLinkService` (`app_links`) napojen na `DeepLinkHandler` přes `AppBootstrapper`; cold-start i warm linky.
  - D1 ✅ geofencing zapojen v `AppBootstrapper` (init+start+registerPois z aktivních POI, jen když je location
    permission udělen → onboarding D7 ho vyžádá); vstup → lokální notifikace (tap → `/poi/:id`).
  - D2 ✅ `SyncService` spuštěn (connectivity listener + initial sync); opraven JSON encoding (`jsonEncode`)
    a push ratingů jen pro přihlášené (login-only, soulad s 0453).
  - D3 ✅ `FcmService`: permission, token → `user_profiles.fcm_token` (**migrace 0454**), foreground/tap handlery
    → deep link/`/poi/:id`. Jen když je Firebase dostupný.
  - Ověření: `flutter analyze` 0 errors, `flutter test` **228** (deep-link resolution už pokryta). **Neověřeno bez
    zařízení:** reálné geofence/FCM/deep-link callbacky. **Migrace 0454 neaplikována živě** — běžící lokální
    Supabase patří jinému projektu („inscubator", chybí `user_profiles`); SQL je triviální idempotentní `ADD COLUMN`,
    aplikuje se při příštím `supabase db reset` tohoto projektu.
- **Vlna 3 — funkční/parity díry: ✅ HOTOVO 2026-06-14**
  - D4 ✅ contributor profil (`features/contributor/*`, nahrazen router stub) + proklik z Hall of Fame
    (list i pódium) + z detailu místa; „Become a guide" → web registrace (`url_launcher`).
  - D5 ✅ OAuth Google/Apple (`signInWithOAuth` + tlačítka v `auth_screen` + auth-state listener pro
    deep-link callback). Lidský krok: Supabase provider config + redirect allowlist (BUILD.md §6).
  - D6 ✅ GDPR export + smazání účtu na mobilu (Settings → „Privacy & data", `AccountDataRepository`,
    `delete-user-data` edge fn, share JSON).
  - D7 ✅ onboarding permission priming (4. krok → location + notifications přes `permission_handler`).
  - Ověření: `flutter analyze` 0 errors, `flutter test` **228** (onboarding test aktualizován). **Neověřeno
    bez zařízení:** reálný OAuth flow, smazání účtu, export share.
- **Vlna 4 — bezpečnost / compliance: ✅ HOTOVO (kód) 2026-06-14**
  - B2 ✅ cookie/consent banner na webu (`components/shared/CookieConsent.tsx`, mount v `App.tsx`,
    informativní — jen nezbytné úložiště, bez trackingu; klíče `cookies.*` ve **všech 11 locales**, parita 0/0).
  - B3 ✅ Comgate webhook hardening — po secret-gate se transakce **re-ověřuje přes Comgate status API**
    (merchant+secret+transId); grant jen na ověřené PAID, refId/cena z ověřené odpovědi (ne z těla callbacku).
  - B4 ✅ `payment-receipts` owner-read RLS na `storage.objects` (**migrace 0455**, defense-in-depth).
  - B5 ✅ GDPR výmaz loguje do `audit_logs` (action `gdpr_account_deletion`, `target_id` přežije null-ování actor FK).
  - B1 ⏳ právní texty — **potřebují tvoje reálné údaje provozovatele + revizi právníkem** (nelze nafejkovat).
  - Ověření: web `vitest` **293**, edge `vitest` **72**, `tsc` clean, i18n parita; migrace 0454+0455 ověřeny
    proti reálnému Postgresu v rolled-back transakci (bez persistence). **Neověřeno:** Comgate hardening
    end-to-end (potřebuje live COMGATE_MERCHANT/SECRET); živý `supabase db reset` tohoto projektu (běží jiný projekt).
- **Vlna 5 — provoz / release blockers: 🔵 PROBÍHÁ 2026-06-14**
  - C1 ✅ Flutter v CI (`.github/workflows/ci.yml` job `mobile`: pub get → build_runner → analyze → test).
  - C2 ✅ web deploy: `netlify.toml` + `public/_redirects` + `vercel.json` (SPA fallback + security headers/CSP);
    `main.tsx` fail-fast bez `VITE_SUPABASE_*`; `.env.production.example`.
  - C5 ✅ `backend/DEPLOYMENT.md` + `backend/PRODUCTION_SETUP.md` (deploy fns, secrets, seed prod dat, admin).
  - C4 ✅ web monitoring scaffolding (`lib/monitoring.ts` + Sentry, no-op bez `VITE_SENTRY_DSN`, dynamic import).
    Mobil Crashlytics zbývá — vyžaduje Firebase config (koš ④), zdokumentováno.
  - Landing CMS ✅ rozšířen na všechny sekce (mig **0456** + admin grouped UI + LandingPage cms()).
- **Vlna 6 — kvalita + E2E: ✅ HOTOVO 2026-06-14**
  - ✅ mapa error/empty stav (MaterialBanner + retry); ✅ web purchase-success polling entitlementu;
    ✅ TTS resume (restart); ✅ Revolut „pending" stav místo optimistického success;
    ✅ offline audio cache (`audio_cache_service.dart`, deterministický klíč, +5 testů);
    ✅ mobil legal odkazy v consentu (Terms/Privacy → web); ✅ Android R8 minify + `proguard-rules.pro`.
  - ✅ **Playwright E2E** (`web/e2e/public.spec.ts`, 5 testů — landing, cookie banner, login, register consent,
    legal) — **reálně spuštěno v prohlížeči: 5 passed**; CI job přidán.
  - Ověření: `flutter analyze` 0 / `flutter test` **233**; web `vitest` 293 / `tsc` clean / `npm audit` 0;
    E2E 5 passed; i18n parita 0/0; mig 0456 ověřena. **Neověřitelné bez zařízení:** reálné přehrání cache audia,
    Revolut/Comgate platby, geofence/FCM/deep-link, Android release build s minify.
- 📋 **`RELEASE-CHECKLIST.md`** — rozdělení zbývající práce: ② udělám já · ③ spolu · ④ jen ty (účty/právo/design).

## Platby + účtenky (2026-06-15)
- **Revolut: vypnuto** — end-to-end nefungovalo (revolut.me odkaz → `create-payment-intent` dělá *Stripe*
  intent, žádný webhook → grant se neudělí). Tlačítko skryto (`paywall_screen`, `availableMethods`), kód
  ponechán pro budoucí Revolut Merchant API.
- **Google Pay: funguje** (mobil Android, přes Stripe gateway) — tlačítko se zobrazí jen když je
  nakonfigurované (`google_pay_merchant_id`+`stripe_publishable_key`); Apple Pay analogicky.
- **Účtenky — opraveno + PDF i obrázek:**
  - Migrace **0457**: `payment_receipts.city_id` nullable + `item_type`/`item_label` → účtenka pokryje i POI/země.
  - Pokrytí: účtenku teď vystaví i **Comgate** (`comgate-webhook`) a **Stripe** (`confirm-poi-payment`)
    přes sdílený `_shared/receipt.ts` (`createReceipt`). `confirm-payment` (Google/Apple Pay) už ji měl.
  - PDF: `generate-receipt` přepsán na **jsPDF** (provozovatel, položka, částka, metoda, datum) — ASCII-fold
    (Helvetica nemá české glyfy); obrázková verze drží plnou diakritiku.
  - **Web** (`AccountProfilePage`): opraven rozbitý dotaz (četl neexistující `pdf_path`/`city_name`) →
    `receipt_pdf_url`/`item_label`; stažení **PDF** (signed URL) i **obrázek (PNG)** přes Canvas API.
  - **Mobil** (`receipts_screen`): detail účtenky s „Open PDF" + „Share image" (RepaintBoundary→PNG→share).
  - Ověření: `flutter analyze` 0 / `flutter test` **235**; web `tsc` 0 / `vitest` 293 / build OK; edge `vitest`
    72; mig 0457 ověřena proti Postgresu (rolled-back, vč. POI účtenky s NULL city_id). **Neověřeno:** živý běh
    edge fns (Deno není nainstalován), reálné platby a PNG export na zařízení; jsPDF v Deno runtime.

## Souhrn závažnosti
| Kat. | Oblast | Počet |
|---|---|---|
| **A** | Launch blockers (mobil nenastartuje / nejde vydat) | 6 |
| **B** | Bezpečnost / compliance / právní | 5 |
| **C** | Provoz / CI / deploy / monitoring | 6 |
| **D** | Mrtvé zadrátování & parity (appka „funguje napůl") | 8 |
| **E** | Kvalita / polish | ~10 |

---

## A. LAUNCH BLOCKERS — mobilní app reálně spadne nebo nejde vydat

### A1. Firebase není nakonfigurovaný → pád při startu `[✓zdroj]`
- `app/lib/main.dart:25` volá `await Firebase.initializeApp()` **bez guardu** (a znovu v background handleru `:18`).
- Chybí `app/android/app/google-services.json`, `app/ios/Runner/GoogleService-Info.plist`,
  `app/lib/firebase_options.dart` (žádný neexistuje, nejsou ani v `.gitignore`).
- V `android/app/build.gradle.kts` ani `android/build.gradle.kts`/`settings.gradle.kts` **není aplikovaný
  `com.google.gms.google-services` plugin**.
- **Důsledek:** na reálném zařízení `Firebase.initializeApp()` vyhodí výjimku → aplikace spadne hned po splash.
- **Oprava:** založit Firebase projekt, doplnit `google-services.json` + `GoogleService-Info.plist`,
  vygenerovat `firebase_options.dart` (`flutterfire configure`), aplikovat gms plugin v gradle, obalit init
  do `try/catch` (FCM je volitelný monitoring — nesmí shodit start; viz zásada „monitoring nesmí shodit službu").

### A2. App icon chybí → selže build ikon `[✓zdroj]`
- `pubspec.yaml` (flutter_launcher_icons) odkazuje `assets/icons/app_icon.png`, ale `assets/icons/` i
  `assets/images/` jsou **prázdné adresáře**.
- **Oprava:** dodat zdrojovou ikonu (1024×1024) + spustit `flutter_launcher_icons`; doplnit splash
  (`flutter_native_splash` zatím není v deps).

### A3. Release build podepsaný debug klíčem → Play Store odmítne `[✓zdroj]`
- `app/android/app/build.gradle.kts:34-37`: `release { signingConfig = signingConfigs.getByName("debug") }` (s TODO).
- **Oprava:** keystore + `signingConfigs.release` z `key.properties` (mimo git).

### A4. Deep linky nejsou zaregistrované na platformě `[✓zdroj]`
- `AndroidManifest.xml`: pouze MAIN/LAUNCHER intent-filter, **žádný** filter pro `https://placesecrets.app`
  ani schéma `placesecrets://`. iOS `Info.plist`: **žádné** `CFBundleURLTypes`/associated domains.
- **Důsledek:** návrat z platby (Stripe/Comgate), sdílené odkazy na místo a notifikace nikam nenavigují.
- **Oprava:** Android intent-filter (autoVerify https + custom scheme) + iOS URL scheme/associated domains.
  Plus A5 (vlastní handler v appce).

### A5. `DeepLinkHandler` je napsaný, ale nikdy se nevolá `[✓zdroj]`
- `app/lib/app/deep_link_handler.dart` (třída + `resolveUri`/`handle` pro purchase success/cancel a smart URI)
  se **nikde neinstancuje** (grep: jen definice). `GoRouter` v `router.dart` na něj není napojený, není tu
  `app_links`/`uni_links` listener.
- **Důsledek:** i kdyby platforma deep link doručila (A4), appka ho nezpracuje → po platbě se entitlement
  nepromítne, sdílené odkazy nefungují.
- **Oprava:** v `main.dart`/root widgetu zapojit `app_links` (getInitialLink + uriLinkStream) → `DeepLinkHandler.handle`.

### A6. Žádné Supabase/Firebase secrets v buildu mobilu `[✓zdroj/agent]`
- `app/lib/core/constants/env.dart` čte `String.fromEnvironment(...)` (SUPABASE_URL/ANON_KEY/ENVIRONMENT/
  GOOGLE_IOS_CLIENT_ID). `app/dart_defines/prod.json` obsahuje placeholder `https://your-project.supabase.co`;
  `GOOGLE_IOS_CLIENT_ID` není vyplněn nikde. Žádný build skript/launch config `--dart-define-from-file` neexistuje.
- **Důsledek:** bez injektáže `--dart-define` se Supabase v prod buildu neinicializuje správně.
- **Oprava:** doplnit prod `dart_defines`, build skript s `--dart-define-from-file`, dokumentovat (souvisí s C).

---

## B. BEZPEČNOST / COMPLIANCE / PRÁVNÍ

### B1. Právní texty jsou placeholder `[agent]`
- `web/src/pages/legal/TermsPage.tsx` + `PrivacyPage.tsx`: `OPERATOR = '{Provozovatel s.r.o.}'`,
  `CONTACT = '{contact@placesecrets.app}'`. Šablonové, bez právní revize.
- **Oprava:** doplnit reálné údaje provozovatele + revize právníkem (DRAFT byl vědomě odložen).

### B2. Chybí cookie/consent banner na webu `[agent]`
- Privacy text tvrdí „nepoužíváme sledování bez souhlasu", ale na webu **není** žádné cookie-consent UI.
- **Oprava:** posoudit nutnost (nezbytné technické úložiště vs. analytics); při přidání analytics je banner povinný.

### B3. Comgate webhook důvěřuje echovanému `secret` `[agent]`
- `backend/supabase/functions/comgate-webhook/index.ts:19` ověřuje jen `secret` z callbacku (vlastní
  komentář v souboru to označuje jako „production hardening: ověřit přes Comgate status API").
- **Důsledek:** padělatelný webhook může udělit přístup, pokud secret unikne/je hádatelný.
- **Oprava:** před zápisem nákupu volat Comgate status API (merchant+secret+transId) a ověřit stav transakce.

### B4. `payment-receipts` bucket nemá RLS policy na `storage.objects` `[✓zdroj — NE „kritická díra"]`
- `016_indexes_atomic_buckets.sql:28` vytváří bucket jako **private** (`public=false`); žádná policy na
  `storage.objects` pro něj v migracích není.
- **Upřesnění:** protože je bucket privátní a PDF se servíruje **signed URL** z `generate-receipt`, běžný
  uživatel se k cizím účtenkám přímo nedostane (default-deny). NENÍ to aktivní únik. Doporučení =
  **defense-in-depth**: přidat owner-only policy (`(storage.foldername(name))[1] = auth.uid()`).
- Ověřit totéž pro `user-photos` bucket (pokud existuje).

### B5. GDPR výmaz bez audit logu `[agent]`
- `delete-user-data` maže atomicky + storage + auth usera, ale **neloguje** kdo/kdy požádal o výmaz
  (compliance evidence). Tabulka `audit_logs` existuje — využít ji.

---

## C. PROVOZ / CI / DEPLOY / MONITORING

### C1. CI nespouští Flutter `[✓zdroj]`
- `.github/workflows/ci.yml` běží jen web (`npm ci`/lint/tsc/build/vitest/audit) + edge testy. **Žádný**
  `flutter analyze`/`flutter test`/build. 224 mobilních testů se v CI nikdy nespustí; codegen se neověřuje.
- **Oprava:** job s `subosito/flutter-action` → `flutter pub get` → `dart run build_runner build` → `flutter analyze` → `flutter test`.

### C2. Žádná deploy konfigurace pro web `[✓zdroj]`
- Chybí `netlify.toml`/`vercel.json`/`public/_redirects`. SPA fallback (catch-all → index.html) není
  → přímá navigace na klientskou routu (`/account/...`) vrátí 404. Injektáž `VITE_*` prod proměnných nedokumentovaná.
- **Oprava:** přidat deploy config se SPA rewrite + dokumentovat env injektáž na platformě.

### C3. Edge funkce neověřené živým během `[agent — viz todo-plan.md]`
- Logika ověřena unit testy + DB, ne přes `supabase functions serve` (refund 403 / admin-api 401 / force-pin redirect).
- **Oprava:** smoke test sady přes lokální `functions serve`.

### C4. Žádný error tracking / analytics / monitoring `[agent]`
- Grep „sentry/crashlytics" = 0. Mobil jen `debugPrint`, web jen console. Edge chyby jen v Supabase logu.
- **Důsledek:** produkční pády / selhání plateb jsou neviditelné.
- **Oprava:** Sentry (web+Flutter) nebo Crashlytics; minimálně payment/edge error alerting.

### C5. Chybí dokumentace secrets + produkční setup `[agent]`
- Edge funkce vyžadují `STRIPE_SECRET_KEY`, `STRIPE_POI_WEBHOOK_SECRET`, `COMGATE_MERCHANT/SECRET`,
  `WEBHOOK_SECRET`, volitelně `RESEND_API_KEY` — bez `.env.example`/deployment guidu. Žádný `Deno.env.get`
  nemá fallback → tichý 500 při chybějícím klíči.
- Seed (`backend/supabase/seed.sql`) je dev-only (test město Plzeň, test admin) — chybí produkční setup
  checklist (countries, prvotní admin, payment_config, free_count/free_period).
- **Oprava:** `backend/DEPLOYMENT.md` + `PRODUCTION_SETUP.md`.

### C6. Bez staging prostředí + bez DR/backup strategie `[agent]`
- Vše jede na prod kredencích; žádná separace staging/prod; nezdokumentovaný backup/PITR.
- **Oprava:** druhý Supabase projekt pro staging; dokumentovat PITR/backup.

---

## D. MRTVÉ ZADRÁTOVÁNÍ & PARITY — appka „funguje napůl"

### D1. Geofencing není zapojený `[✓zdroj]`
- `app/lib/core/services/geofence_service.dart` je kompletní (initialize/start/registerPois/callbacky),
  ale **nikdy se neinstancuje** (grep: jen definice + debug printy). Neregistrují se POI geofency, nevolá se
  auto-play audia ani notifikace na vstupu.
- **Důsledek:** klíčová nativní funkce (auto-přehrání u místa) je 100 % nefunkční přes veškerý hotový kód.
- **Oprava:** instancovat na startu (po permission grantu), `registerPois` z aktivních POI, `onPoiEntered`
  → `NotificationService.showPoiNearby` + audio.

### D2. Offline sync není zapojený `[✓zdroj]`
- `app/lib/core/services/sync_service.dart` (push ratingů, pull POI) se **nikdy neinstancuje/nespouští**.
- **Důsledek:** lokální ratingy (Drift) se nikdy nesynchronizují na server → po reinstalaci zmizí.
- **Oprava:** spustit `startListening()` (connectivity) + `syncAll()` po loginu/online.

### D3. FCM push nefunguje end-to-end `[✓zdroj]`
- Jen `onBackgroundMessage` (prázdný handler). Chybí `getToken()` + uložení tokenu na server,
  `onMessage`/`onMessageOpenedApp`/`getInitialMessage`, `requestPermission()`.
- **Důsledek:** backend nemá token → push nedorazí; klepnutí na notifikaci nikam nenaviguje.
- **Oprava:** registrace tokenu do `user_profiles` (sloupec doplnit migrací), handlery zpráv → `DeepLinkHandler`.

### D4. Stub obrazovky a mrtvá tlačítka `[✓zdroj]`
- `app/lib/app/router.dart` route `/contributor/:userId` → jen placeholder `Text('Contributor: ...')`.
- `app/lib/features/hall_of_fame/hall_of_fame_screen.dart` — dlaždice nemají `onTap` (nelze otevřít profil).
- `app/lib/features/settings/settings_screen.dart` „Become a guide" → prázdný `onTap` (jen komentář).
- **Oprava:** reálný contributor profil (handle, statistiky, verified badge) + proklik z HoF;
  „Become a guide" → registrace přispěvatele (in-app nebo web redirect).

### D5. OAuth na mobilu chybí úplně `[✓zdroj]`
- Žádný `google_sign_in`/`sign_in_with_apple`/`signInWithOAuth` (web má `SocialAuthButtons`). Jen email/heslo.
- **Oprava:** `signInWithOAuth` (Supabase) + native Google/Apple (Apple je na iOS App Store povinné, je-li jiný social login).

### D6. Account deletion + GDPR export jen na webu `[agent]`
- `delete-user-data` i JSON export má jen web (`AccountProfilePage`). Mobil nemá UI → uživatel musí na web.
- **Oprava:** v mobilním Settings doplnit „Delete account" (volá `delete-user-data`) + GDPR export.

### D7. Onboarding nežádá oprávnění `[agent]`
- `onboarding_screen.dart` = jen 3 slidy + `pref_onboarding_done`. Nežádá location/notifikace.
- **Důsledek:** uživatel narazí na mapu/geofence bez grantnutých práv.
- **Oprava:** permission priming krok v onboardingu (location + notifications).

### D8. UI chrome stringy natvrdo anglicky `[✓zdroj — 0× AppLocalizations.of]`
- App-wide jazyk řídí **obsah** (POI názvy/audio) a Material widgety, ale ~200+ `Text('...')` labelů
  (AppBar tituly, tlačítka, hlášky) je hardcoded EN; `AppLocalizations.of(context)` se v `lib/features/*`
  nevolá ani jednou. `app_en.arb` má 114 klíčů, většinou nevyužitých.
- **Oprava:** extrakce stringů do `AppLocalizations` + dopřeklad do 11 jazyků (jako web). Velký, samostatný úkol.

---

## E. KVALITA / POLISH (výběr)
- **TTS pauza/resume rozbité** `[agent]` — `audio_service.dart` resume je no-op pro TTS (musí od začátku).
- **Audio se necachuje offline** `[agent]` — POI se cachují (Drift), audio soubory ne → offline poslech nejde.
- **Mapa bez error/empty stavu** `[agent]` — `map_screen.dart` tiše spadne na prázdný seznam při chybě.
- **Web success page nepolluje entitlement** `[agent]` — `PurchaseResultPage` jen zobrazí hlášku, neověří grant.
- **Revolut platba optimistická** `[agent]` — `payment_service.dart` vrací úspěch před webhook potvrzením.
- **`payment-webhook` bez idempotence** `[agent]` — replay znovu upsertne user_access (neškodné, ale slabé).
- **Web: chybí E2E testy** kritických toků (purchase, OAuth) + ModerationPage/BuyButton bez testů `[agent]`.
- **Bez API/architektury dokumentace, bez ER diagramu** `[agent]`.
- **flutter_background_geolocation = placená licence** pro release Android (transistorsoft) `[agent]` — řešit před D1.
- **TypeScript 6 / ESLint 10 odložené** kvůli peer konfliktům `[agent — todo-plan.md]`.

---

## Vyvrácené nálezy (do oprav NEPATŘÍ — ověřeno u zdroje)
- ❌ „Android balíček je pořád `cz.tuma.herodots`" — **NEPRAVDA.** `build.gradle.kts` namespace+applicationId =
  `cz.tuma.placesecrets`, `MainActivity.kt` je v `cz/tuma/placesecrets/`. Přejmenování proběhlo; poznámka v
  `todo-plan.md:132` je zastaralá (aktualizovat). `[✓zdroj]`
- ❌ „payment-receipts bucket = kdokoliv přečte cizí účtenky" — **přehnané.** Bucket je privátní + signed URL;
  default-deny chrání. Jen doporučení defense-in-depth (B4). `[✓zdroj]`
- ❌ „Google/Apple Pay je stub" — **NEPRAVDA.** `pay` balíček, reálné `PaymentConfiguration`+`showPaymentSelector`
  (`payment_service.dart`). `[✓zdroj]`
- ❌ „Stripe není zapojený" (web agent) — Stripe je plně v backendu+mobilu (create-poi-checkout/confirm-poi-payment/
  stripe-refund); web jen používá Comgate pro nákup. Není to díra, je to volba rails. `[✓zdroj backend funkcí]`

---

## Doporučené pořadí oprav (jak fix-prompt rozdělit)
1. **Mobil „aby vůbec nastartoval a šel vydat":** A1 Firebase guard+config, A2 ikona, A3 signing, A6 dart-define.
2. **Mobil „aby fungoval jak slibuje":** D1 geofencing, D3 FCM, A4+A5 deep linky, D2 sync.
3. **Funkční/parity díry:** D4 stuby (contributor/HoF/become-a-guide), D6 delete+GDPR na mobilu, D7 onboarding perms, D5 OAuth.
4. **Bezpečnost/právo před launchem:** B1 právní texty, B3 Comgate hardening, B4 storage policy, B5 audit log, B2 cookies.
5. **Provoz:** C1 Flutter CI, C2 deploy config, C5 secrets/prod-setup docs, C4 monitoring, C3 edge smoke testy, C6 staging.
6. **Kvalita:** E (TTS, audio cache, mapa error state, web success polling, i18n D8, E2E testy).

## Poznámka k použití jako fix-prompt
Značení `[✓zdroj]` vs `[agent]` je záměrné: položky `[agent]` před opravou **znovu ověř u zdroje**
(zelený lokální stav ani report agenta není důkaz). Každá oprava míří na vrstvu, kde příčina vzniká,
a preferuje deterministické/konfigurační řešení před runtime obcházením.
