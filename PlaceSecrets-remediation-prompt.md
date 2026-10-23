# PlaceSecrets: sjednocení, opravy a napojení na business plán

> **Typ dokumentu:** závazný implementační prompt pro Claude Code
> **Verze:** 1.1 · 16. 10. 2026 (doplněno o `APP-GAP-ANALYSIS.md`)
> **Nahrazuje:** všechny dřívější odchylky ve `specification-prompts.md` (v2.0), `spec-placesecrets-web.md` (v3.0), `spec-prompts-admin.md` (v2.0), `RELEASE-CHECKLIST.md` a `APP-GAP-ANALYSIS.md` (oba se stavem k 14.–15. 6. 2026)
> **Podklad:** Business Plan Review (revize 2), kapitoly 0–9

---

## 0. Pravidla práce (STRIKTNÍ)

Toto nejsou doporučení. Každé pravidlo je povinné.

0. **Nejdřív ověř, pak opravuj.** Specifikace jsou starší než kód. Před každým úkolem zjisti skutečný stav v repozitáři (grep, čtení souboru, dotaz na schéma). Výsledek zapiš do reportu jako `VERIFIED: <ID> – <co jsi našel, soubor:řádek>`. Pokud je úkol v kódu už splněný, označ ho `DONE-VERIFIED` s důkazem a nic nepřepisuj. Tvrzení z GAP analýzy označená `[agent]` vždy ověř znovu u zdroje.
1. **Pořadí je závazné.** Úkoly se plní v pořadí P0 → P1 → P2 → P3 a uvnitř fáze podle ID. Úkol se nezačíná, dokud předchozí nesplňuje všechna akceptační kritéria.
2. **Jeden úkol = jeden commit** se zprávou `PS-<ID>: <shrnutí>` (např. `PS-P0.1: remove service_role from web bundle`). Žádné míchání úkolů v jednom commitu.
3. **Nic se nevynechává potichu.** Když úkol nejde splnit (chybí přístup, chybí rozhodnutí, konflikt s kódem), zastav se. Do `REMEDIATION-REPORT.md` zapiš `BLOCKED: <ID> – důvod – co potřebuješ` a pokračuj dalším úkolem, který na blokovaném nezávisí.
4. **Žádné placeholdery v produkčním kódu.** Zakázané jsou `TODO`, `FIXME`, `XXX`, `{Provozovatel s.r.o.}`, `YOUR_PROJECT_ID`, `lorem` a natvrdo zapsané testovací ceny. Výjimkou jsou jen hodnoty, které dodá vlastník (sekce 7). Ty se načítají z konfigurace, ne z kódu.
5. **Business hodnoty nikdy natvrdo v kódu.** Ceny, limity, kurzy kreditů, prahy kvality a platnosti se čtou z tabulky `app_config` (sekce 2). V kódu smí být jen bezpečná výchozí hodnota pro offline start, označená `// fallback, zdroj pravdy je app_config`.
6. **Bezpečnost má přednost před funkcí.** Když oprava bezpečnosti rozbije funkci, opravuje se funkce, ne bezpečnost.
7. **Migrace jsou jen dopředné.** Složka `backend/supabase/migrations/`. Nová čísla navazují na poslední existující migraci (podle GAP analýzy `0457`, první nová je tedy `0458`, ověř v repozitáři). Existující migrace se nepřepisují. Každá migrace je idempotentní (`IF NOT EXISTS`, `CREATE OR REPLACE`) a má ověřený rollback skript v `…/migrations/rollback/`.
8. **Po každém úkolu musí projít:**
   - `flutter analyze` (0 problémů) a `flutter test`
   - `web`: `npm run typecheck` (tsc 0), `npm run test` (vitest), `npm audit --audit-level=high` (0)
   - edge funkce: `vitest`
   - migrace proti čistému Postgresu (stejný postup jako u 0454–0456)
   - Počet testů nesmí klesnout pod výchozí stav (Flutter 235, web 293, edge 72, E2E 5).
   - Migrace se ověřují proti Supabase projektu **PlaceSecrets**. Lokální instance „inscubator“ patří jinému projektu a k ověření se nesmí použít.
9. **Každá změna chování má test.** Unit test pro logiku a integrační test pro RLS a Edge Functions. Bezpečnostní úkoly mají **negativní test**, který dokazuje, že útok neprojde.
10. **Dokumentace se aktualizuje ve stejném commitu** jako kód (`backend/DEPLOYMENT.md`, `backend/PRODUCTION_SETUP.md`, `app/BUILD.md`, specifikace).

---

## 1. Zdroj pravdy

| Priorita | Dokument | Platí pro |
|---|---|---|
| 1 | **Tento dokument** | vše, co upravuje |
| 2 | `spec-placesecrets-web.md` v3.0 | web (admin, autoři, účet), pokud ho tento dokument neupravuje |
| 3 | `specification-prompts.md` v2.0 | mobilní aplikace, pokud ji tento dokument neupravuje |
| – | `spec-prompts-admin.md` v2.0 | **ZASTARALÉ.** Nepoužívat. Na začátek souboru vložit banner `> ZASTARALÉ – nahrazeno spec-placesecrets-web.md v3.0 a PlaceSecrets-remediation-prompt.md` |

Při rozporu vždy platí dokument s vyšší prioritou. Rozpor, který tento dokument neřeší, zapiš do reportu jako `CONFLICT: <soubor:sekce> vs <soubor:sekce>` a použij bezpečnější variantu.

### 1.1 Známý stav repozitáře (z `APP-GAP-ANALYSIS.md`, 14.–15. 6. 2026)

Struktura: `app/` (Flutter), `web/` (Vite + React), `backend/supabase/` (61 migrací, 15+ edge funkcí, `_shared/`). Tyto položky jsou podle analýzy hotové a **neprovádějí se znovu**. Jen se ověří, že platí:

| GAP ID | Stav | Dopad na tento prompt |
|---|---|---|
| A1–A6 | ✅ start bez Firebase, ikona (placeholder), release signing, deep linky, env fail-fast | PS-P0.4 jen kontroluje zbytky názvu |
| D1–D7 | ✅ geofencing, sync, FCM, contributor profil, OAuth, GDPR na mobilu, onboarding | PS-P2.1 navazuje na existující `geofence_service.dart` |
| B2–B5 | ✅ cookie banner, Comgate re-verify přes status API, storage RLS (0455), GDPR audit log | PS-P0.3 Comgate už nemění |
| C1, C2, C4, C5 | ✅ Flutter CI, web deploy config, Sentry scaffolding, deploy docs | PS-P3.1 jen doplní staging |
| Revolut | ⛔ vypnuto (tlačítko skryté, kód ponechán) | PS-P0.3: kód odstranit úplně |
| Google/Apple Pay | ✅ funkční přes Stripe (`pay`) | **PS-P0.2: v aplikaci nahradit IAP** (digitální obsah) |
| Účtenky | ✅ 0457: `item_type` / `item_label`, POI i země, PDF + PNG | PS-P1.2 je rozšíří o nové produkty |
| Android ID | ✅ `cz.tuma.placesecrets` (vyvrácený nález) | PS-P0.4 ID **nemění** |
| Otevřené | B1 právní texty, C3 živý běh edge funkcí, C6 staging + PITR, D8 lokalizace UI, licence `flutter_background_geolocation` | PS-P3.1, PS-P3.2, PS-P2.7, PS-P3.4 |

Mapování nálezů business review na tento prompt: A1 → P0.1, A2 → P0.2, A3 → P0.3, A4 → P1.4, A5 → P1.1/P1.2, A6 → P1.5, A7 → P2.3, A8 → P0.4, A9 → P1.3, A10 → P3.1/P3.3, A11 → P2.2, A12 → sekce 5.

---

## 2. Business parametry (jediný zdroj pravdy)

### 2.1 Tabulka `app_config`

Vytvoř tabulku `public.app_config` (klíč–hodnota, `value JSONB`, `updated_at`, `updated_by`). Čtení: `anon` a `authenticated` vidí **jen** klíče s `is_public = true`. Zápis: jen přes Edge Function `admin-config-update` (role `superadmin`). Tabulka nahrazuje cenová a limitní pole v `payment_config` a v kódu.

| Klíč | Hodnota | Význam |
|---|---|---|
| `free.daily_audio_limit` | `1` | bezplatná audia na uživatele/zařízení za kalendářní den (Europe/Prague) |
| `product.coffee` | `{"price_eur":1.99,"unlocks":3,"valid_days":30}` | „Kafe“: odemkne 3 libovolná audia |
| `product.beer` | `{"price_eur":2.99,"scope":"place","valid_days":30}` | „Pivo“: celé jedno místo / trasa |
| `product.city` | `{"default_eur":5.99,"valid_days":30}` | „Oběd“: celé město; cenu určuje `cities.price_eur` |
| `product.family` | `{"price_eur":7.99,"scope":"city","valid_days":30,"includes_kids":true}` | Město + dětské verze |
| `product.country_pass` | `{"price_eur":12.99,"scope":"country","valid_days":365}` | Celé Česko |
| `city.price_tiers` | `{"praha":7.99,"rim":7.99,"default":5.99,"small":4.99}` | výchozí ceny měst |
| `credits.rate_audio` | `30` | kreditů za odemčení 1 audia |
| `credits.rate_city` | `200` | kreditů za odemčení města (30 dní) |
| `credits.earn_gate` | `50` | jednorázově při průchodu bránou kvality |
| `credits.earn_per_10_listens` | `3` | za každých 10 ověřených poslechů nahrávky nad branou |
| `credits.earn_scarce_bonus` | `30` | první kvalitní audio u POI nebo v chybějícím jazyce |
| `credits.monthly_cap` | `300` | strop připsaných kreditů na autora za kalendářní měsíc |
| `credits.validity_days` | `365` | platnost každého připsání |
| `quality.min_verified_ratings` | `10` | minimum ověřených hodnocení pro bránu |
| `quality.min_score` | `4.3` | minimální vážené skóre pro bránu |
| `quality.prior_m` | `20` | váha průměru platformy ve váženém skóre |
| `listen.verified_ratio` | `0.6` | podíl poslechu pro „ověřený poslech“ |
| `geofence.default_radius_m` | `40` | výchozí poloměr pro nové POI v centru |
| `geofence.radius_bounds_m` | `[30,150]` | povolený rozsah |
| `languages.enabled` | `["cs","en"]` | jazyky v nabídce pro posluchače |
| `languages.priority` | `["cs","en","de","it","es","zh-Hant","ko","ja","fr","pl"]` | pořadí pro bonus nedostatkového obsahu |

### 2.2 Vážené skóre (jediný vzorec v celém systému)

```
score = (v × R + m × C) / (v + m)
v = počet ověřených hodnocení nahrávky
R = průměr ověřených hodnocení nahrávky
C = průměr ověřených hodnocení všech aktivních nahrávek platformy
m = quality.prior_m
```

Implementuj jedinou SQL funkci `public.weighted_score(poi_id uuid, lang text) RETURNS numeric`. Hall of Fame, brána kvality, řazení v aplikaci i admin ji **musí** volat. Jiné vzorce se smažou. Vzorec `avg × log(n+1)` v `contributor_rankings` nahraď tak, že `hof_score = SUM(weighted_score)` nahrávek autora nad branou.

### 2.3 Ověřená návštěva a ověřený poslech

- **Ověřená návštěva:** server zapíše `poi_visits` (user_id, poi_id, entered_at, source = 'geofence'), když klient pošle podepsanou událost vstupu do geofence. Kontrola: POI je aktivní, poloha v události je do `geofence_radius + 30 m`, nejvýš 1 návštěva na uživatele, POI a 6 h.
- **Ověřený poslech:** `listen_events` (user_id, poi_id, lang, duration_listened_s, audio_duration_s) s `duration_listened_s / audio_duration_s ≥ listen.verified_ratio` a existující ověřenou návštěvou do 2 h před poslechem.
- **Ověřené hodnocení:** smí ho dát jen přihlášený uživatel s ověřeným poslechem dané nahrávky. Nikdy autor vlastní nahrávky.

---

## 3. Úkoly

Formát každého úkolu: **Kontext → Kroky → Akceptační kritéria (AK) → Testy**.

### P0 – Blokery vydání (bezpečnost, platby, identita)

#### PS-P0.1 Odstranit `service_role` z webu (audit A1)

**Kontext:** `VITE_SUPABASE_SERVICE_ROLE_KEY` se při buildu dostane do veřejného JavaScriptu. Kdo otevře admin, získá plný přístup k databázi. Admin PIN chrání jen UI.

**Kroky:**
1. Smaž `supabaseAdmin` klienta z `web/`. Web používá výhradně `VITE_SUPABASE_URL` + `VITE_SUPABASE_ANON_KEY`.
2. Vytvoř SQL funkci `public.is_admin(min_role text) RETURNS boolean` (SECURITY DEFINER, `search_path = public`). Kontroluje `auth.uid()` v `admin_users` a hierarchii `viewer < editor < superadmin`.
3. Ke každé tabulce, kterou admin čte, přidej RLS politiku `USING (public.is_admin('viewer'))`. Pro zápis přidej politiku s `'editor'` nebo `'superadmin'` podle matice rolí ve web spec §11.2.
4. Operace, které nesmí jít přes RLS (smazání uživatele, ruční udělení přístupu, schválení platby, změna `app_config`), přesuň do Edge Functions. Každá funkce:
   - ověří JWT (`supabase.auth.getUser(token)`),
   - ověří roli voláním `is_admin`,
   - **ověří platnost admin PIN session** (krátkodobý podepsaný token z `verify-admin-pin`, TTL 30 min, `aud = 'admin'`),
   - teprve potom použije service_role, který je jen v Supabase Secrets.
5. `stripe_secret_key` a další tajemství odstraň z tabulky `payment_config` a nech je jen v Supabase Secrets. Migrace sloupec smaže.
6. Do CI přidej krok, který po `vite build` prohledá `web/dist/` a selže, pokud najde `service_role`, `sk_live_`, `sk_test_`, `whsec_` nebo JWT s `"role":"service_role"`.
7. V `backend/PRODUCTION_SETUP.md` popiš **rotaci service_role klíče** jako povinný krok před produkcí.

**AK:**
- `grep -ri "service_role" web/src web/.env* web/dist` → 0 výsledků (kromě komentáře v dokumentaci).
- Uživatel bez řádku v `admin_users` dostane z každé admin tabulky 0 řádků a na každou admin Edge Function odpověď 403.
- Admin bez platné PIN session dostane 403 od každé zapisující admin funkce.

**Testy:** negativní RLS testy pro `anon`, `authenticated` bez role, `viewer` (zápis), `editor` (superadmin operace). E2E: přihlášení admina → PIN → úprava POI.

#### PS-P0.2 Platby: IAP v aplikaci, web zvlášť (audit A2)

**Kontext:** Digitální obsah odemčený v iOS a Android aplikaci musí jít přes App Store In-App Purchase (pravidlo 3.1.1) a Google Play Billing. Revolut, Stripe/`pay` a Comgate v aplikaci hrozí zamítnutím.

**Kroky:**
1. V mobilní aplikaci odstraň balíček `pay` (Google/Apple Pay přes Stripe v `payment_service.dart`), Revolut tok (`payWithRevolut`, `revolutme` v `LSApplicationQueriesSchemes`) a jakýkoli odkaz nebo výzvu k platbě mimo obchod. Ponech edge funkce `create-poi-checkout`, `confirm-poi-payment` a `stripe-refund`, protože je dál používá web. Ověř, že je nevolá mobil.
2. Přidej `in_app_purchase` a definuj produkty:

   | Product ID | Typ (Apple / Google) | Zdroj ceny |
   |---|---|---|
   | `ps.coffee.3audio` | Consumable / consumable | `product.coffee` |
   | `ps.beer.place` | Consumable / consumable | `product.beer` |
   | `ps.city.30d.tier1` … `tier4` | Non-renewing subscription / one-time product | `city.price_tiers` → nejbližší cenová úroveň obchodu |
   | `ps.family.30d` | Non-renewing / one-time | `product.family` |
   | `ps.country.365d` | Non-renewing / one-time | `product.country_pass` |

   Město se váže na produkt podle své cenové úrovně, ne vlastním produktem pro každé město.
3. Nová Edge Function `iap-verify`: přijme účtenku, ověří ji u **App Store Server API** nebo **Google Play Developer API**, zkontroluje `bundleId` / `packageName`, zabrání opakovanému použití (`transaction_id` UNIQUE) a teprve potom zapíše nárok (PS-P1.2).
4. Server-to-server notifikace (Apple App Store Server Notifications v2, Google RTDN) → Edge Function `iap-notifications`: refundace nárok zruší (`status = 'refunded'`).
5. Tlačítko **Obnovit nákupy** v nastavení a na paywallu.
6. **Web** (`/account/*`) smí prodávat stejné produkty přes Comgate a Stripe. Nárok je společný v `entitlements`, takže nákup z webu funguje i v aplikaci. V aplikaci se web jako platební kanál **nezmiňuje**.

**AK:**
- V mobilním kódu neexistuje `revolut`, `comgate`, `stripe`, `pay` ani `launchUrl` vedoucí na platební doménu.
- Sandbox nákup na iOS i Androidu vytvoří nárok. Druhé odeslání stejné účtenky nový nárok nevytvoří. Refundace nárok zruší.

**Testy:** unit test mapování produktů na nárok. Integrační test `iap-verify` s mockem Apple/Google API: platná, neplatná, duplicitní a cizí `bundleId`.

#### PS-P0.3 Žádný přístup bez ověřené platby (audit A3)

**Kroky:**
1. Smaž `showRevolutConfirmationDialog` a každé volání `grantAccess` z klienta (mobil i web).
2. Nárok vzniká **pouze** v `iap-verify`, ve webhooku Comgate / Stripe (s ověřeným podpisem) nebo v admin funkci `admin-grant-access` (důvod je povinný a zapisuje se do audit logu).
3. Všechny Edge Functions berou `user_id` **výhradně z JWT**, nikdy z těla požadavku. Částka se bere z `app_config` a ověřené platby, nikdy z klienta.
4. Revolut je podle GAP analýzy vypnutý a end-to-end nefungoval (revolut.me odkaz volal Stripe intent bez webhooku). Kód Revolutu **odstraň z mobilu i webu úplně**, včetně `availableMethods` a polí `revolut_username` / `revolut_iban` (migrace). Budoucí Revolut Merchant API je mimo rozsah (sekce 6).
5. `payment-webhook`: doplň idempotenci (GAP E). Opakované doručení stejné události nesmí nic změnit.

**AK:** Pokus zavolat jakoukoli funkci s cizím `user_id` v těle požadavku vytvoří nárok jen volajícímu, nebo vrátí 400. Žádná cesta z klienta nevytvoří nárok. Replay webhooku nevytvoří druhý nárok ani druhou účtenku.

**Testy:** negativní testy podvržení `user_id`, `amount_eur` a `city_id`.

#### PS-P0.4 Jednotný název a identita PlaceSecrets (audit A8)

**Kroky:** proveď v celém repozitáři (kód, konfigurace, texty, testy, dokumentace, specifikace):

| Starý | Nový |
|---|---|
| `HeroDots`, `herodots`, `Hero Dots` | `PlaceSecrets` / `placesecrets` |
| Android applicationId | **beze změny** `cz.tuma.placesecrets` (už přejmenováno, GAP „Vyvrácené nálezy“) |
| iOS bundle ID | `cz.tuma.placesecrets` (ověř `PRODUCT_BUNDLE_IDENTIFIER` v `ios/Runner.xcodeproj`) |
| Dart package `herodots` (pokud ještě existuje) | `placesecrets` |
| `todo-plan.md:132` (zastaralá poznámka) | aktualizovat |
| `admin.herodots.app` | `placesecrets.app/admin` |
| `herodots.app` | `placesecrets.app` |
| deep link scheme | `placesecrets://` (jediný) |
| prefix dokladů `HD-` | `PS-` |
| `operator_name DEFAULT 'HeroDots'` | hodnota z `app_config.operator.name` |
| `seed.sql`: `revolut_username = 'herodots'` | odstranit |

Android i iOS musí mít stejné ID `cz.tuma.placesecrets`. Pokud se liší, nebo pokud už aplikace v konzoli Google Play či App Store Connect existuje pod jiným ID, **zastav se** a zapiš `BLOCKED: PS-P0.4`.

**AK:** `grep -rni "herodot\|hero dots\|HD-" --exclude-dir=.git --exclude-dir=migrations` → 0. Historické migrace se nemění, název přejmenuje nová migrace. `assetlinks.json` a `apple-app-site-association` odpovídají novému ID.

---

### P1 – Napojení na business plán

#### PS-P1.1 Bezplatný limit: 1 audio denně (audit A5)

1. `payment_config` už podle GAP C5 obsahuje `free_count` a `free_period`. Ověř, co `free_period` podporuje. Cílový stav: `free_count = 1`, `free_period = 'day'`, kalendářní den Europe/Prague. Pokud den nepodporuje, rozšiř ho. `free_visit_log` počítá po dnech (`visit_date DATE`). Konstantu `freePoiPerMonth` a měsíční logiku (`year_month`) odstraň. Zdrojem pravdy je `app_config.free.daily_audio_limit` a `payment_config.free_*` se z něj odvodí view, aby neexistovaly dvě hodnoty.
2. Serverová funkce `public.can_play(poi_id, lang)` vrací `{allowed, reason: 'entitlement'|'free_daily'|'credit'|'none', remaining_free_today}`. Klient rozhoduje **jen** podle ní. Offline: klient smí přehrát jen obsah s lokálně uloženým nárokem a podpisem.
3. Anonymní uživatel: `device_id` vzniká při prvním spuštění (UUID v secure storage) a po registraci se sloučí přes `migrate-anonymous-data`. Tím se uzavře UC-30.

**AK:** 2. bezplatné audio téhož dne vrátí `allowed = false`. Po půlnoci pražského času `true`.

#### PS-P1.2 Nároky, produkty a platnost

0. Nejdřív zmapuj existující model nároků: `user_access` (města), POI nákupy přes `create-poi-checkout` / `confirm-poi-payment`, nákupy zemí a `payment_receipts.item_type` (0457). Výsledek zapiš do reportu. Pokud existující tabulky pokryjí `scope`, `valid_until` a `source`, rozšiř je místo zavedení nové tabulky. Novou tabulku `entitlements` zaveď jen tehdy, když by rozšíření vedlo ke třem různým místům pro jeden nárok.
1. Cílový model `entitlements` (nová tabulka, nebo sjednocení existujících): Sloupce: `id`, `user_id`, `scope` ('poi'|'place'|'city'|'country'), `scope_id`, `includes_kids`, `source` ('iap'|'web'|'credits'|'admin'), `transaction_ref`, `valid_from`, `valid_until NOT NULL`, `status`, `created_at`. UNIQUE (`source`, `transaction_ref`).
2. `user_access` převeď migrací na `entitlements` (stávající trvalé přístupy dostanou `valid_until = now() + 365 days`) a nahraď ho view kvůli zpětné kompatibilitě.
3. „Kafe“ přidá 3 tokeny do `unlock_tokens`. Každé odemčení audia spotřebuje 1 token a vytvoří nárok `scope = 'poi'` na `product.coffee.valid_days`.
4. `cities.price_eur DEFAULT 1.00` změň: výchozí hodnota se bere z `city.price_tiers`. Seed nastaví Praha 7,99 a Kutná Hora 5,99 (`price_tier = 'default'`).

**AK:** Po 30 dnech nárok na město vyprší. Celé Česko pokryje všechna města s `country_code = 'CZ'`.

#### PS-P1.3 Kredity autorů (audit A9)

1. Tabulka `credit_ledger` (append-only): `id`, `user_id`, `delta INT`, `reason` ('gate'|'listens'|'scarce'|'spend_audio'|'spend_city'|'expire'|'clawback'|'admin'), `ref_id`, `expires_at`, `created_at`. UPDATE a DELETE jsou zakázané triggerem. Zůstatek se počítá jako view `credit_balance` (jen nevypršená připsání mínus čerpání, FIFO).
2. Připisování dělá **jen** plánovaná Edge Function `credits-accrue` (denně ve 03:00 Europe/Prague) podle pravidel 2.1 a 2.3. Musí být idempotentní pro daný den a respektovat `credits.monthly_cap`.
3. Čerpání přes RPC `spend_credits(scope, scope_id)` podle kurzu 2.1. **Zakázáno:** čerpat na vlastní obsah, na obsah institucí (`pois.owner_type = 'institution'`) a převádět kredity mezi účty.
4. `clawback`: když se nahrávka stáhne za porušení pravidel, odečtou se kredity za ni připsané (zůstatek smí jít do minusu a další připsání ho nejdřív vyrovnají).
5. Admin: přehled kreditů autora, ruční korekce (`superadmin`, s povinným důvodem) a metrika „podíl odemčení kredity na všech odemčeních“ s varováním nad 10 %.
6. Obchodní podmínky: kredity nemají peněžní hodnotu, nejsou převoditelné, platí 12 měsíců a mohou být odebrány.

**AK:** Opakované spuštění `credits-accrue` pro stejný den nic nezmění. Strop 300 nejde překročit. Pokus o UPDATE ledgeru selže.

#### PS-P1.4 Brána kvality a ověřené hodnocení (audit A4)

1. Ověř aktuální politiky `poi_ratings`. Podle GAP D2 je push ratingů po migraci 0453 jen pro přihlášené, ale web spec §6.6 stále uvádí `ratings_anon_insert WITH CHECK (TRUE)`. Výsledná politika: přímý INSERT zakázaný, insert jen přes RPC `rate_poi(poi_id, lang, rating, reason)`, která ověří podmínky z 2.3. Lokální ratingy z Drift (`sync_service.dart`) se odesílají přes stejné RPC.
2. `device_id` z `poi_ratings` odstraň. Hodnotí jen přihlášení.
3. Stav nahrávky: `pois.audio_status` (JSONB po jazycích): `draft` → `in_review` (kurátor) → `published` → `quality_passed` (brána) | `removed`.
4. `contributor_rankings` přepiš podle 2.2.

**AK:** Anonymní insert vrací chybu. Hodnocení bez ověřeného poslechu vrací chybu. Autor nemůže hodnotit sám sebe.

#### PS-P1.5 Lidský hlas a TTS (audit A6)

1. TTS smí přehrát jen **text** POI, které není v placené sekci (`pois.is_premium = false`). Přehrávač ho musí viditelně označit jako „Strojový hlas“.
2. POI s `is_premium = true` se v aplikaci zobrazí jen tehdy, když má nahrávku v aktuálním jazyce. Jinak se ukáže s textem „Příběh se nahrává“ a bez paywallu.
3. Admin: filtr „POI bez nahrávky“ podle města a jazyka a export úkolů pro autory.

#### PS-P1.6 Jazyky

1. Jazyk posluchače: systémový jazyk, pokud je v `languages.enabled`, jinak `en`. Přepínač v přehrávači i nastavení.
2. Když chybí nahrávka v jazyce posluchače, nabídni angličtinu se štítkem jazyka. Nepoužívej TTS (PS-P1.5).
3. Bonus `credits.earn_scarce_bonus` se připíše za první nahrávku POI v jazyce z `languages.priority`, který u POI chybí.

---

### P2 – Kvalita produktu a právní čistota

#### PS-P2.1 Geofence a fronta přehrávání

1. `pois.geofence_radius`: CHECK v rozsahu `geofence.radius_bounds_m`, výchozí `geofence.default_radius_m`.
2. **Fronta přehrávání:** když uživatel vstoupí do více geofencí, hraje se nejbližší POI. Ostatní jdou do fronty (nejvýš 3 položky) seřazené podle vzdálenosti a skóre. Žádné POI se nespustí dvakrát za 6 h.
3. Ruční záloha: tlačítko „Jsem tady“ a seznam POI do 150 m.
4. Režim „Jen se sluchátky“ (výchozí zapnutý): bez sluchátek se automatické přehrávání nespustí a zobrazí se jen notifikace.

**AK:** Unit testy fronty pro 1, 3 a 5 současných geofencí. Test, že se POI nespustí podruhé.

#### PS-P2.2 Offline město

1. Tlačítko „Stáhnout město“ u platného nároku na město: stáhne audio v aktuálním jazyce, fotky a mapové dlaždice oblasti. Ukazuje velikost a průběh.
2. Sjednoť `audio_cache_service.dart` se specifikací. Spec §13 („audio jen streamuje“) přepiš na skutečné chování.
3. Po vypršení nároku se stažené audio smaže.

**AK:** V režimu letadlo hraje celé koupené město včetně mapy.

#### PS-P2.3 Mapové dlaždice (audit A7)

1. Odstraň `tile.openstreetmap.org` z kódu i konfigurace.
2. Použij vektorové dlaždice ve formátu PMTiles (Protomaps / OpenMapTiles) uložené v Supabase Storage, nebo poskytovatele s licencí pro offline. Volbu zapiš do `app/BUILD.md`.
3. `flutter_map_tile_caching` smí ukládat jen z vlastního zdroje.
4. Atribuce „© OpenStreetMap contributors“ zůstává viditelná.

**AK:** `grep -r "tile.openstreetmap.org"` → 0.

#### PS-P2.4a Přehrávání TTS (GAP E)

Ověř, že pauza a obnovení TTS po opravě „restart“ nepůsobí jako chyba. Tlačítko u TTS se jmenuje „Přehrát znovu“, ne „Pokračovat“.

#### PS-P2.4 Rodinný režim

1. `pois.kids_audio_urls` (JSONB po jazycích) a přepínač „Dětská verze“ v přehrávači, aktivní jen s nárokem `includes_kids = true`.
2. Admin a portál autorů umožní nahrát dětskou verzi.

#### PS-P2.5 Obsah, licence a moderace

1. Při nahrání nahrávky musí autor potvrdit licenci (nevýhradní, celosvětová, pro komerční užití včetně institucí, s možností sublicence). Ukládá se `content_licenses` (verze textu, čas, IP hash).
2. Povinné pole „Zdroj textu“. Volba „Wikipedie“ zobrazí upozornění na CC BY-SA a vyžádá si uvedení autorů v textu.
3. Zákaz hudby v pozadí uvedený v pravidlech nahrávání.
4. Tlačítko „Nahlásit“ u každého příběhu → `content_reports`. Admin fronta se SLA 24 h a stažení nahrávky jedním klikem (spustí clawback kreditů).
5. Kodex pro pietní místa (`poi_types.is_sensitive`): nahrávka vždy projde kurátorem.

#### PS-P2.6 Ochrana dat

1. Poloha se nezapisuje na server průběžně. Server dostává jen události vstupu do geofence (2.3).
2. Účty jen od 16 let (potvrzení věku při registraci). Mluvčí mladší 18 let potřebuje souhlas zákonného zástupce (zaškrtávací pole + uložení).
3. Privacy policy doplň o zpracování polohy, události poslechu a kredity.

---

#### PS-P2.7 Lokalizace UI aplikace (GAP D8)

1. Všechny UI texty v `app/lib/features/*` (~200 `Text('…')`) převeď na `AppLocalizations`. Klíče patří do `app_*.arb` a nevyužité klíče se smažou.
2. Pořadí jazyků podle `languages.priority`: nejdřív `cs`, `en`, `de` (povinné pro release), potom zbylé jazyky webu (11) bez změny klíčů.
3. CI kontrola parity klíčů `.arb`, stejně jako na webu (0/0).

**AK:** `grep -rn "Text('[A-Z]" app/lib/features` → 0 (kromě názvů POI a dat). Parita `cs` / `en` / `de` je 0/0.

---

### P3 – Release

#### PS-P3.1 Prostředí

1. Staging Supabase projekt je **povinný**. CI nasazuje nejdřív na staging, produkce jen ručně spuštěným jobem.
2. Firebase (FCM, Crashlytics) zapojit v obou prostředích. Sentry DSN pro web.
3. `app/dart_defines/staging.json` a `prod.json`. Žádné tajemství v repozitáři.

4. Edge funkce ověř živě přes `supabase functions serve` (nainstaluj Deno). Smoke test: `refund` → 403 pro cizí nákup, `admin-api` → 401 bez tokenu, force-PIN redirect, `generate-receipt` s jsPDF v Deno runtime, `iap-verify` a `comgate-webhook` proti sandboxu (GAP C3).
5. Zálohy: zapni PITR nebo denní zálohy na produkčním projektu a v `backend/PRODUCTION_SETUP.md` popiš obnovu. Obnovu jednou vyzkoušej na stagingu (GAP C6).

#### PS-P3.2 Právní texty a obchody

1. `TermsPage.tsx` a `PrivacyPage.tsx` načítají údaje provozovatele z `app_config.operator.*`. Bez vyplnění se produkční build nespustí (fail-fast).
2. Obchodní podmínky obsahují produkty a platnosti z 2.1, pravidla kreditů z PS-P1.3, licenci obsahu z PS-P2.5 a odstoupení od smlouvy u digitálního obsahu.
3. Store metadata (fastlane) v `cs`, `en`, `de`. Název „PlaceSecrets“, kategorie Travel.

#### PS-P3.3 Smoke test před každým releasem

Na fyzickém iOS i Android zařízení proti stagingu projdi a výsledek zapiš do `REMEDIATION-REPORT.md`:

1. Registrace (e-mail, Google, Apple) → souhlasy
2. Bezplatné audio dne → druhé audio zablokované
3. Nákup Kafe v sandboxu → 3 odemčení → obnovení nákupu na druhém zařízení
4. Nákup Města → stažení offline → přehrání v režimu letadlo
5. Geofence: automatické spuštění se sluchátky, fronta při 2 bodech blízko sebe
6. Push notifikace a deep link `placesecrets://poi/<id>` + Universal Link / App Link
7. Hodnocení po ověřeném poslechu → připsání kreditů po `credits-accrue` → čerpání kreditů

---

#### PS-P3.4 Licence `flutter_background_geolocation` (GAP E)

Balíček od Transistorsoft vyžaduje pro Android release placenou licenci. Úkol:
1. Zjisti aktuální cenu a podmínky licence a zapiš je do reportu.
2. Připrav variantu B: `geofence_service.dart` za rozhraním `GeofenceProvider` tak, aby šel vyměnit za bezplatnou implementaci (nativní geofencing Androidu a iOS). Zatím nic nepřepínej.
3. Rozhodnutí patří vlastníkovi (sekce 7). Bez licence se Android release nevydává: `BLOCKED: PS-P3.4`.

---

## 4. Zakázané vzory (kontrola v CI)

Přidej skript `scripts/forbidden-patterns.sh`, spouštěný v CI. Při jakémkoli nálezu selže.

| Vzor | Kde | Důvod |
|---|---|---|
| `service_role`, `SERVICE_ROLE_KEY` | `web/`, `app/` | A1 |
| `sk_live_`, `sk_test_`, `whsec_`, `re_[A-Za-z0-9]{10,}` | celý repozitář mimo `.env.example` | tajemství |
| `revolut`, `comgate`, `stripe`, `package:pay/` | `app/lib/` | A2 |
| `revolut` | `web/src/`, `backend/supabase/functions/` | A3 |
| `grantAccess(` | `app/lib/`, `web/src/` | A3 |
| `herodot`, `HD-` | celý repozitář mimo `migrations/` a `.git/` | A8 |
| `tile.openstreetmap.org` | celý repozitář | A7 |
| `freePoiPerMonth`, `year_month` | `app/lib/`, `web/src/`, nové migrace | A5 |
| `WITH CHECK (TRUE)` | nové migrace | A4 |
| `TODO`, `FIXME`, `{Provozovatel` | `app/lib/`, `web/src/`, `supabase/functions/` | pravidlo 0.4 |

---

## 5. Aktualizace specifikací

Po dokončení P0–P2 uprav specifikace tak, aby popisovaly skutečný stav:

1. `specification-prompts.md`: přejmenuj na PlaceSecrets. Sekce 1.1, 1.3 (bez `pay`, s `in_app_purchase`), 5 (nové tabulky), 8.2 (TTS pravidla), 10.6 (paywall s IAP), 11 (konstanty → `app_config`), 13 (offline město) a 20 (mapy). Zastaralé části škrtni blokem `> NAHRAZENO: viz PS-<ID>`, nemaž je.
2. `spec-placesecrets-web.md`: §1.2 a §7 bez service_role, §6.6 nové hodnocení, nová sekce „Kredity“ a nová sekce „App config“.
3. `RELEASE-CHECKLIST.md` a `APP-GAP-ANALYSIS.md`: nový stav k datu dokončení, koše ①–④ podle skutečnosti a odkaz na tento dokument. V GAP analýze nové nálezy z tohoto promptu doplň jako kategorii **F – soulad s business plánem**.
4. `spec-prompts-admin.md`: banner ZASTARALÉ (sekce 1).

---

## 6. Mimo rozsah (NEDĚLAT)

- Instituce, oficiální kanály a B2B licence (fáze 3)
- Výplaty autorům v penězích (Stripe Connect, Revolut payouts)
- Gamifikace nad rámec Hall of Fame a odznaků
- Sociální funkce (feed, komentáře, sledování)
- Generování audia pomocí AI pro placenou sekci
- Předplatné s automatickou obnovou

Návrh v těchto oblastech zapiš do reportu jako `IDEA:`, ale neimplementuj ho.

---

## 7. Hodnoty, které dodá vlastník

Neodhaduj je. Načítej z konfigurace. Když chybí, zapiš `BLOCKED`.

| Hodnota | Kam |
|---|---|
| Název, IČO, adresa a kontakt provozovatele | `app_config.operator.*` |
| Prod a staging Supabase URL + anon key | `dart_defines/*.json`, env webu |
| Apple Team ID, App Store Connect API klíč, Google Play service account | Supabase Secrets (pro `iap-verify`) |
| Comgate merchant + secret, Stripe klíče | Supabase Secrets |
| Firebase konfigurační soubory, upload keystore | podle `app/BUILD.md` |
| Finální ikona 1024×1024 | `assets/icons/app_icon.png` |
| Potvrzení ID `cz.tuma.placesecrets` pro iOS i Android | PS-P0.4 |
| Koupě licence Transistorsoft, nebo volba varianty B | PS-P3.4 |

---

## 8. Definice hotovo a závěrečný report

Práce je hotová, když:

- všechny úkoly P0–P3 splňují AK, nebo jsou v reportu jako `BLOCKED` s důvodem,
- `scripts/forbidden-patterns.sh` nic nenajde,
- všechny testy z pravidla 0.8 projdou a počty testů vzrostly,
- smoke test PS-P3.3 je zapsaný pro obě platformy,
- specifikace odpovídají kódu (sekce 5).

`REMEDIATION-REPORT.md` musí obsahovat:

```
## Souhrn
Hotovo: N/M · Blokováno: K · Konflikty: C

## Úkoly
| ID | Stav (DONE/BLOCKED/PARTIAL) | Commit | Testy (přidané/celkem) | Poznámka |

## Bezpečnost
- důkaz, že dist/ neobsahuje service_role (výstup příkazu)
- seznam negativních testů

## Migrace
| Číslo | Účel | Rollback ověřen |

## Smoke test
| Krok | iOS | Android | Poznámka |

## BLOCKED / CONFLICT / IDEA
```
