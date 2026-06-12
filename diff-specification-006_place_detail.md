# DIFF-006 — PlaceDetailPage oprava + rozšířený layout + audio guides schéma

## Kontext

PlaceDetailPage (`/:countryCode/:citySlug/:poiSlug`) zobrazovala "Place not found", protože seed data mají NULL slugy (vloženy před migrací 018 triggery). Stránka potřebuje bohatší layout s auth-gated obsahem. Audio schéma potřebuje rozšíření z jednoho souboru na jazyk (JSONB) na plnohodnotnou tabulku `poi_audio_guides` podporující více audio nahrávek na jazyk s trváním.

---

## D6-001: Migrace 033 — tabulka `poi_audio_guides`

**Soubor:** `backend/supabase/migrations/033_poi_audio_guides.sql`

### Nová tabulka

- `poi_audio_guides` — UUID PK, `poi_id` FK (CASCADE), `lang_code` (2-znakový kód), `title`, `url`, `duration_sec`, `sort_order`, timestamps
- Indexy: `idx_poi_audio_guides_poi`, `idx_poi_audio_guides_poi_lang`
- RLS: SELECT pro všechny (veřejné čtení)

### Migrace dat

Existující data z `pois.audio_urls` (JSONB) se překopírují do nové tabulky.

### Rozšíření RPC `get_poi_by_slug`

Nové sloupce ve výstupu:
- `poi_description` — plný popis (JSONB)
- `poi_audio_urls` — zachováno pro kompatibilitu
- `audio_guides` — JSON agregace z `poi_audio_guides` (metadata bez URL)
- `poi_type_*` — typ místa (id, name, icon, color)
- `contributor_*` — přispěvatel (id, name, avatar, verified)
- `poi_aliases` — alternativní názvy
- Filtr: `AND p.is_active = TRUE`

---

## D6-002: Oprava seed dat

**Soubor:** `backend/supabase/seed.sql`

Přidány příkazy pro backfill slugů:
```sql
UPDATE public.cities SET updated_at = NOW() WHERE slug IS NULL;
UPDATE public.pois SET updated_at = NOW() WHERE slug IS NULL;
```

Trigger z migrace 018 se spustí při UPDATE a vygeneruje slug z názvu.

---

## D6-003: admin-api aktualizace

**Soubor:** `backend/supabase/functions/admin-api/index.ts`

- `poi_audio_guides` přidáno do `ALLOWED_TABLES`
- `poi_audio_guides: 'audio'` přidáno do `TABLE_TO_RESOURCE`
- Contributor kontrola rozšířena o `poi_audio_guides`

---

## D6-004: Web typy

**Soubor:** `web/src/lib/supabase/types.ts`

Nový interface `PoiAudioGuide` (id, poi_id, lang_code, title, url, duration_sec, sort_order, timestamps).

---

## D6-005: AudioUploader přepis

**Soubor:** `web/src/components/pois/AudioUploader.tsx`

Samostatná CRUD komponenta pracující přímo s tabulkou `poi_audio_guides`:
- Props: `{ poiId: string }` (bez audioUrls/onChange)
- Načítání existujících guides přes `adminSelect`
- Upload: soubor → storage → public URL → extrakce trvání → `adminInsert`
- Smazání: `adminDelete` + storage
- Inline editace titulku
- Více souborů na jazyk
- Pro nové POI: zobrazí "Save POI first"

---

## D6-006: PoiForm aktualizace

**Soubor:** `web/src/components/pois/PoiForm.tsx`

- Odebrán stav `audioUrls` a jeho použití
- Odebráno `audio_urls` z payloadu `handleFormSubmit`
- AudioUploader volán pouze s `poiId`

---

## D6-007: PlaceDetailPage redesign

**Soubor:** `web/src/pages/PlaceDetailPage.tsx`

Rozšířený `PoiSlugData` interface. Auth-gating přes `useAuthStore()`.

### Layout:
1. **PublicHeader** (showNav=false)
2. **Breadcrumb**: PlaceSecrets › City
3. **Foto karusel** — rozšířen na max-w-2xl, výška h-64
4. **Type badge** (barevný štítek typu) + **Share tlačítko**
5. **Název** (h1) + město/země subtitle
6. **Rating hvězdičky**
7. **Perex** — vždy viditelný
8. **Popis** — auth-gated:
   - Přihlášen: plný text
   - Anonym: blur + "Sign in to read more"
9. **Audio guides sekce**:
   - Seskupeny dle jazyka, počet na jazyk
   - Celkové trvání na jazyk
   - Anonym: pouze počet + "Download app to listen"
   - Přihlášen: seznam titulků + trvání + "Open in app to listen"
10. **Contributor karta** (avatar + jméno + verified badge)
11. **Premium cena** — existující
12. **Mapa** — existující
13. **Open in App CTA**
14. **PublicFooter**

---

## D6-008: i18n

**Soubory:** `web/src/locales/*/translation.json` (11 jazyků)

Nové klíče:
- `placeDetail.*` — notFound, description, signInToRead, audioGuides, contributedBy, premiumContent, openInApp, downloadPrompt aj.
- `audioUploader.*` — saveFirst, uploaded, deleted, upload, clickToEditTitle, untitled

---

## D6-009: Flutter model

**Soubor:** `app/lib/domain/models/poi_audio_guide.dart`

Freezed třída: id, poiId, langCode, title, url, durationSec, sortOrder.
Pomocné metody: `displayTitle`, `formattedDuration`.

---

## D6-010: Flutter Drift schéma v5

**Soubor:** `app/lib/data/local/tables/cached_audio_guides_table.dart`

Nová tabulka `cached_audio_guides` zrcadlící Supabase tabulku.
Schema version bumped na 5 v `app_database.dart`.
Queries: `getAudioGuidesForPoi`, `upsertAudioGuide`, `clearAudioGuidesForPoi`.

---

## D6-011: Flutter audio providers

**Soubor:** `app/lib/features/map/providers/audio_providers.dart`

Nový provider `poiAudioGuides(poiId)` — načítá z Supabase tabulky `poi_audio_guides`.

---

## D6-012: Flutter audio player widget

**Soubor:** `app/lib/features/poi_detail/widgets/audio_player_widget.dart`

Přepsán na podporu seznamu guides:
- Načítá `poiAudioGuidesProvider` (async)
- Seskupení dle jazyka
- Výběr konkrétního guide k přehrání
- Rozbalovací seznam s titulky a trváním
- Fallback na legacy player (audio_urls / TTS) pokud žádné guides
- Progress bar pro aktuálně přehrávaný guide
