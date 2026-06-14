# PlaceSecrets — release checklist (co umím já vs. co musíš ty)

> Stav k **2026-06-14**. Doprovod k `APP-GAP-ANALYSIS.md`. Rozděluje zbývající práci na tři koše:
> **① hotovo**, **② udělám já (kód)**, **③ uděláme spolu (kód + tvé vstupy)**, **④ jen ty (účty/právo/design)**.
> Legenda: 🟢 hotovo · 🔵 dělám/umím udělat · 🟡 spolu · 🔴 jen ty.

---

## ① HOTOVO (ověřeno)
- 🟢 Vlna 1 — mobil nastartuje i bez Firebase; env fail-fast; release signing přes keystore; brand ikona pipeline.
- 🟢 Vlna 2 — deep linky (platforma + handler), geofencing, offline sync, FCM (token→`user_profiles.fcm_token`, mig 0454).
- 🟢 Vlna 3 — contributor profil, OAuth Google/Apple (kód), GDPR export+smazání účtu na mobilu, onboarding permissions.
- 🟢 Vlna 4 — web cookie banner (11 jazyků), Comgate webhook hardening, receipts storage RLS (mig 0455), GDPR audit log.
- 🟢 Landing CMS rozšířen na všechny sekce (mig 0456 + admin `/admin/landing` + LandingPage).
- 🟢 Flutter v CI (`.github/workflows/ci.yml`), web deploy config (netlify.toml/_redirects/vercel.json + security headers + env fail-fast).
- Ověření: `flutter analyze` 0 / `flutter test` 228; web `vitest` 293; edge `vitest` 72; migrace 0454/0455/0456 ověřeny proti Postgresu.

---

## ② UDĚLÁM JÁ — zbývající KÓD (bez tvého vstupu) — ✅ HOTOVO
- 🟢 **C5** — `backend/DEPLOYMENT.md` + `backend/PRODUCTION_SETUP.md`.
- 🟢 **Vlna 6 kvalita** — mapa error/empty stav (retry); web purchase-success polling entitlementu;
  TTS resume (restart); Revolut „pending" stav; offline audio cache (`audio_cache_service.dart`);
  mobil legal odkazy v consentu (Terms/Privacy → web); Android R8 minify + `proguard-rules.pro`.
- 🟢 **C4 web monitoring** — Sentry scaffolding (`web/src/lib/monitoring.ts`, no-op bez DSN).
- 🟢 **E2E** — Playwright (`web/e2e/public.spec.ts`, 5 testů) **reálně spuštěno: 5 passed**; CI job přidán.
- 🟢 Dokumentace aktualizována.
- 🟡 Zbývá jen **mobil Crashlytics** — vyžaduje Firebase config (koš ④), takže patří do „spolu/jen ty".

→ Hotovo. Ověřeno: `flutter analyze` 0 / `flutter test` 233; web `vitest` 293 / `tsc` 0 / `audit` 0; E2E 5/5.

---

## ③ UDĚLÁME SPOLU (já kód, ty hodnoty/spuštění)
- 🟡 **Prod konfigurace mobilu** — ty dodáš prod `SUPABASE_URL` + anon key → já vyplním `app/dart_defines/prod.json`.
- 🟡 **Nasazení backendu** — připravím přesné příkazy; ty spustíš `supabase login` → `supabase db push`
  (migrace) → `supabase functions deploy <fn>` (15 funkcí) → `supabase secrets set …`.
- 🟡 **Monitoring** — ty založíš Sentry projekt (web DSN) a zapneš Firebase Crashlytics; já zapojím kód (init/guards).
- 🟡 **Právní texty** — ty dodáš reálné údaje provozovatele (název, IČO, adresa, kontakt) + revizi právníkem;
  já je vložím do `web/src/pages/legal/TermsPage.tsx` + `PrivacyPage.tsx` (placeholdery `{Provozovatel s.r.o.}`).
- 🟡 **Store metadata** — připravím texty popisů/keywords + fastlane strukturu; ty je nahraješ do účtů.
- 🟡 **CI/deploy secrets** — řeknu které proměnné; ty je vyplníš v GitHub/Netlify/Vercel/Supabase.

---

## ④ JEN TY (kód to neumí — účty, kredenciály, právo, design, zařízení)
- 🔴 **Firebase projekt** + `google-services.json` (Android) + `GoogleService-Info.plist` (iOS) + gms gradle plugin (návod v `app/BUILD.md`).
- 🔴 **Android upload keystore** (`keytool`) → `android/key.properties` (gitignored).
- 🔴 **Finální brand ikona** 1024×1024 (teď je placeholder; `dart run flutter_launcher_icons`).
- 🔴 **Prod Supabase projekt** — URL + anon key + service_role (pro edge secrets).
- 🔴 **Supabase dashboard config** — OAuth providers (Google/Apple) + redirect allowlist `placesecrets://login-callback`;
  Auth e-mailové šablony; seed prod dat (countries, prvotní admin, `payment_config` ceny + `free_count`).
- 🔴 **Platby LIVE** — Comgate (`COMGATE_MERCHANT`/`COMGATE_SECRET`) + Stripe (`STRIPE_SECRET_KEY`/webhook secret) + `RESEND_API_KEY`.
- 🔴 **Doménové soubory pro deep linky** — `https://placesecrets.app/.well-known/assetlinks.json` (Android)
  + `apple-app-site-association` (iOS Universal Links).
- 🔴 **App Store / Play Store** — vývojářské účty, listing, screenshoty, **privacy policy URL**, content rating,
  Apple „Sign in with Apple" service id.
- 🔴 **On-device ověření** — geofence auto-play, FCM doručení, deep-link callbacky, reálné platby, OAuth flow (nelze z testů).
- 🔴 **Staging Supabase projekt** (doporučeno před prod).

---

## Finální release postup (až bude ④ připravené)
1. Mobil: `flutter build appbundle --release --dart-define-from-file=dart_defines/prod.json` (s keystore) → Play Console.
2. iOS: `flutter build ipa --release --dart-define-from-file=dart_defines/prod.json` → App Store Connect.
3. Backend: `supabase db push` + `supabase functions deploy` (vše) + `supabase secrets set` (platby/email).
4. Web: nasadit `web/` na Netlify/Vercel s `VITE_SUPABASE_*` env (deploy config je hotový).
5. Doména: nahrát `assetlinks.json` + `apple-app-site-association`.
6. Smoke test na zařízení: registrace → consent → nákup → audio → geofence → push → deep link.

## Podmínky platnosti
Vše v ① je ověřeno staticky (analyze/test/tsc/i18n parita) a migrace proti reálnému Postgresu. **Runtime
chování (platby, OAuth, geofence/FCM/deep-link, push, store buildy) nelze ověřit bez zařízení a reálných
účtů** — to je obsah koše ④.
