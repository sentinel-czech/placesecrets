# Mobile app — stav a analýza parity s webem (bez adminu)

Cíl: co musí Flutter aplikace (`app/`) umět, aby byla pro koncového uživatele **rovnocenná webu**
(administrace se mobilu netýká). Stav k 2026-06-13. Odhad pokrytí: **~60 % user-facing parity**.

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
| Consent (Terms/Privacy) při registraci | chybí | nutné pro launch |
| Ověření emailu (status + resend) | chybí | nekontroluje `email_confirmed_at` |
| Změna hesla / primárního emailu | chybí | jen backup email |
| Handle / backup email | **má** | settings |
| Avatar (upload) | chybí | bucket `avatars` už existuje |
| App-wide jazyk (lokalizace UI) | částečně | jen jazyk audia, ne UI |
| Detail místa: foto/audio/hodnocení/share | **má** | + login-gate hodnocení ✅ |
| Detail místa: **recenze/komentáře** | chybí | web má `get_poi_reviews` |
| Detail místa: odkaz na profil přispěvatele | částečně | jen text |
| **Vyhledávání míst** | chybí | RPC `search_pois` existuje |
| **Katalog měst** (procházení) | chybí | jen auto-detekce nejbližších |
| **„Můj přístup"/nároky** | chybí | RPC `get_my_entitlements` existuje |
| Stav free limitu (1/období) | částečně | uživatel nevidí kvótu |
| Nákup město / POI / **země** | má (město/POI) | země = nová úroveň (web) |
| Účtenky / historie plateb | částečně | jen IDs, bez částek/účtenek |
| Hall of Fame | **má** | per-město |
| Visit history + PDF export | **má** | timeline, statistiky |
| GDPR export dat | chybí | web má |
| Registrace přispěvatele | chybí | jen stub odkaz |

## Prioritizovaný plán k dorovnání (bez adminu)
**Kritické (před plnohodnotným launchem mobilu):**
1. **Vyhledávání** — `search_pois` RPC + obrazovka s gridem výsledků
2. **Katalog měst** — seznam aktivních měst → místa ve městě (reuse `cities`/`pois` query)
3. **„Můj přístup"** — `get_my_entitlements` (POI/město/země/free) na profilu
4. **Consent + ověření emailu při registraci** — checkbox Terms/Privacy, kontrola `email_confirmed_at` + resend
5. **Změna hesla / emailu** v nastavení (`auth.updateUser`)

**Vysoké:**
6. **Recenze/komentáře** u místa — `get_poi_reviews` (read) + submit (login-only, jako web)
7. **Avatar** — image_picker → upload do bucketu `avatars` → `user_profiles.avatar_url`
8. **Účtenky/historie plateb** — z `payment_receipts` (částky, datum, PDF odkaz)
9. **App-wide jazyk** — persist locale + override UI i audio

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
Tato analýza je dokument; mobilní featury jsou samostatný implementační krok. Reálný běh appky
nebyl spuštěn (bez zařízení/emulátoru) — ověřeno jen `flutter analyze` u změněných souborů.
