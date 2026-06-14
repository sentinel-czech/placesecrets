# Mobile app — stav a analýza parity s webem (bez adminu)

Cíl: co musí Flutter aplikace (`app/`) umět, aby byla pro koncového uživatele **rovnocenná webu**
(administrace se mobilu netýká). Stav k 2026-06-13. Odhad pokrytí: **~60 % → ~80 %** po dodání
kritické vrstvy (viz níže).

## ✅ Kritická vrstva — IMPLEMENTOVÁNO (2026-06-13)
1. **Vyhledávání** — `search_pois` RPC → `SearchRepository`/`searchResultsProvider` →
   `features/search/search_screen.dart` (debounce, grid výsledků, thumbnaily, rating badge).
   Vstup: ikona 🔍 v app baru mapy → route `/search`.
2. **Katalog měst** — `features/catalog/catalog_screen.dart` (reuse `activeCitiesProvider`) →
   `city_places_screen.dart` (reuse `cityPoisProvider`, offline cache). Route `/catalog`, `/catalog/:cityId`.
   Vstup: ikona 🏙️ v app baru mapy.
3. **„Můj přístup"** — `get_my_entitlements` RPC → `myEntitlementsProvider` →
   `features/account/my_access_screen.dart` (free kvóta s progress barem + POI/města/bundly/země).
   Vstup: Settings → „My access" (route `/account/access`).
4. **Consent + ověření emailu** — registrační checkbox Terms/Privacy (povinný), zápis
   `terms_accepted_at`/`privacy_accepted_at` do `user_profiles` (jako web); po signu hláška o ověření;
   resend přes `auth.resend(OtpType.signup)`. Status „Email not verified" + Resend v Settings.
5. **Změna hesla / emailu** — Settings → dialogy přes `auth.updateUser` (`updatePassword`/`updateEmail`).

Navíc opraveno: rating gate teď správně vylučuje **anonymní** session (`canSubmitRatingProvider`),
ne jen `currentUser == null` — anonymní účet už hodnotit nemůže. Testy `rating_widget_test` převedeny
na override providveru (nepotřebují init Supabase). `flutter analyze` 0 errors, `flutter test` 214 passed.

## Architektura mobilu
Riverpod (+codegen), GoRouter (deep links), Drift (offline SQLite), supabase_flutter,
flutter_background_geolocation (geofencing), just_audio_background (audio na pozadí), Firebase FCM (push).

## Nativní silné stránky (web NEMÁ)
- **Geofencing + auto-přehrání** audia při vstupu do okolí místa (background location)
- **Offline-first** — POI a audio cache v Drift; funguje bez sítě
- **Audio na pozadí**, **push notifikace** (FCM), nativní mapa, lokální deník (poznámky/fotky)

## Inventář (app/lib/features/*)
auth (email/heslo, reset, anon→email migrace) · onboarding · map (+geofencing, filtr access) ·
poi_detail (foto, audio, hodnocení) · payment + purchase (Google Pay / Apple Pay / Revolut + web checkout) ·
settings (geofence, jazyk audia, handle, backup email) · history (+PDF export) ·
account/my_purchases · hall_of_fame · export · deep-links (`/:country/:city/:poi`).

## Parity gap (web user feature → mobil)
| Web feature | Mobil | Pozn. |
|---|---|---|
| Email/heslo login + reset | **má** | auth_screen |
| OAuth (Google/Apple) | chybí | jen email/heslo |
| Consent (Terms/Privacy) při registraci | **má** ✅ | checkbox + zápis consent timestamps |
| Ověření emailu (status + resend) | **má** ✅ | status v Settings + resend |
| Změna hesla / primárního emailu | **má** ✅ | Settings dialogy (`auth.updateUser`) |
| Handle / backup email | **má** | settings |
| App-wide jazyk (výběr + obsah) | **má** ✅ | výběr 11 jazyků, persist + sync `user_profiles.language`; obsah/audio/Material následují. UI chrome stringy zatím natvrdo EN |
| Detail místa: foto/audio/hodnocení/share | **má** | + login-gate hodnocení ✅ |
| Detail místa: **recenze/komentáře** | **má** ✅ | `get_poi_reviews` + komentář u hodnocení |
| Avatar (upload) | **má** ✅ | image_picker → bucket `avatars` → Settings |
| Detail místa: odkaz na profil přispěvatele | částečně | jen text |
| **Vyhledávání míst** | **má** ✅ | `search_pois` → `/search` |
| **Katalog měst** (procházení) | **má** ✅ | `/catalog` → `/catalog/:cityId` |
| **„Můj přístup"/nároky** | **má** ✅ | `get_my_entitlements` → `/account/access` |
| Stav free limitu (1/období) | **má** ✅ | kvóta na „My access" (progress bar) |
| Nákup město / POI / **země** | má (město/POI) | země = nová úroveň (web) |
| Účtenky / historie plateb | **má** ✅ | `payment_receipts` (částky, datum, stav, PDF odkaz) → `/account/receipts` |
| Hall of Fame | **má** | per-město |
| Visit history + PDF export | **má** | timeline, statistiky |
| GDPR export dat | chybí | web má |
| Registrace přispěvatele | chybí | jen stub odkaz |

## Prioritizovaný plán k dorovnání (bez adminu)
**Kritické (před plnohodnotným launchem mobilu): ✅ HOTOVO 2026-06-13** — viz sekci nahoře.
1. ✅ **Vyhledávání** — `search_pois` RPC + `search_screen`
2. ✅ **Katalog měst** — `catalog_screen` → `city_places_screen`
3. ✅ **„Můj přístup"** — `get_my_entitlements` → `my_access_screen`
4. ✅ **Consent + ověření emailu** — checkbox + consent timestamps + resend
5. ✅ **Změna hesla / emailu** — Settings dialogy (`auth.updateUser`)

**Vysoké: ✅ HOTOVO 2026-06-14**
6. ✅ **Recenze/komentáře** u místa — `get_poi_reviews` (read, paginace „Load more") + komentář u hodnocení
   (`poi_ratings.comment`, login-only). `features/poi_detail/widgets/poi_reviews_section.dart`.
7. ✅ **Avatar** — `image_picker` → `ProfileRepository.uploadAvatar` (bucket `avatars`, `<uid>/avatar.<ext>`) →
   `user_profiles.avatar_url`; zobrazení + upload v Settings → „Profile photo".
8. ✅ **Účtenky/historie plateb** — `payment_receipts` (owner-read RLS) → `features/account/receipts_screen.dart`
   (`/account/receipts`): částky, datum, stav, metoda, PDF odkaz přes `url_launcher`. Settings → „Payment history".
9. ✅ **App-wide jazyk** — `AppLocale` controller (`app/locale_provider.dart`, persist `pref_app_language`),
   `MaterialApp.locale` + 11 `supportedLocales`; Settings → „App language" (11 jazyků + System default),
   sync do `user_profiles.language`, aplikace serverové preference při loginu (mimo default 'en').
   Pozn.: mění **obsah** (POI názvy/popisy/audio přes `localizedName(langCode)`) a Material widgety;
   UI chrome stringy jsou zatím natvrdo anglické (extrakce do `AppLocalizations` = samostatný krok).

**Střední:**
10. OAuth (Google/Apple) přihlášení
11. Registrace přispěvatele (flow nebo web redirect)
12. GDPR export profilu + dat
13. Země-level nákup (nová úroveň z webu) + stav free kvóty

## Reuse z backendu (vše už existuje)
`search_pois`, `get_my_entitlements`, `get_poi_reviews`, `get_poi_access` (v2: země+expirace),
bucket `avatars` (owner-write RLS), `payment_receipts`, Comgate edge fns (`comgate-create`/`-webhook`).
Hodnocení už je **login-only** i na mobilu (migrace 0453 + rating gate).

## Pozn. k ověření
**Kritická i vysoká vrstva implementována** (k 2026-06-14). Zbývá jen střední priorita (OAuth,
registrace přispěvatele, GDPR export, země-level nákup) + extrakce UI stringů do `AppLocalizations`.
Ověřeno: `flutter analyze lib test` 0 errors, `flutter test` **224 passed** (model testy
`place_summary`/`poi_review`, controller test `locale_provider`). **Neověřeno (bez zařízení):** reálný běh
na zařízení/emulátoru a end-to-end proti živému Supabase — upload do bucketu `avatars`, čtení
`payment_receipts`/PDF přes `url_launcher`, RPC `get_poi_reviews`/`search_pois`/`get_my_entitlements`,
flip jazyka při loginu. Backend objekty (RPC, RLS, sloupce) ověřeny ve zdroji (migrace) + dříve přes `supabase db reset`.
