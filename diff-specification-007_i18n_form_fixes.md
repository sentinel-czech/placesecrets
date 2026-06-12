# DIFF-007 — PlaceDetailPage vylepšení + PoiForm i18n rozšíření + perex JSONB

## Kontext

PlaceDetailPage zobrazuje data, ale chybí GPS souřadnice, ikona typu, audio guide zobrazení pro všechny jazyky. Admin PoiForm má pouze CS/EN záložky — rozšířeno na 11 jazyků. Label "Name" se nesmí překládat. Perex konvertován z TEXT na JSONB (vícejazyčný).

---

## D7-001: Sdílené konstanty jazyků

**Nový soubor:** `web/src/lib/constants.ts`

- `LANG_CODES` — 11 jazyků: en, cs, sk, de, es, fr, pt, ru, vi, zh, ko
- `LangCode` type
- `LANG_LABELS` — anglické názvy jazyků
- Nahrazuje lokální definice v PlaceDetailPage, AudioUploader, PoiTypesPage, PoiForm

---

## D7-002: Migrace 035 — perex TEXT → JSONB + uploaded_by

**Nový soubor:** `backend/supabase/migrations/035_perex_jsonb_audio_uploaded_by.sql`

1. `ALTER TABLE pois ALTER COLUMN perex TYPE JSONB` — existující textové hodnoty migrovány do `{"en": "..."}`
2. `ALTER TABLE poi_audio_guides ADD COLUMN uploaded_by UUID REFERENCES auth.users(id) ON DELETE SET NULL`

---

## D7-003: Migrace 036 — aktualizace get_poi_by_slug RPC

**Nový soubor:** `backend/supabase/migrations/036_fix_get_poi_by_slug_perex.sql`

- `poi_perex` návratový typ změněn z TEXT na JSONB
- Zbytek RPC beze změn

---

## D7-004: admin-api — auto-set uploaded_by

**Soubor:** `backend/supabase/functions/admin-api/index.ts`

- Při INSERT do `poi_audio_guides` se automaticky nastaví `uploaded_by` na ID aktuálního uživatele z JWT

---

## D7-005: Web typy aktualizace

**Soubor:** `web/src/lib/supabase/types.ts`

- `Poi.perex` typ změněn z `string | null` na `Record<string, string> | null`
- `PoiAudioGuide` — nový sloupec `uploaded_by: string | null`

---

## D7-006: PlaceDetailPage vylepšení

**Soubor:** `web/src/pages/PlaceDetailPage.tsx`

### A1. GPS souřadnice (textové)
- Nová funkce `formatCoord()` — formát: `49.7474° N, 13.3776° E`
- Zobrazeno pod mapou jako malý text

### A2. Ikona typu
- Mapování Material Design → lucide-react: apartment→Building2, church→Church, museum→Landmark, park→Trees, atd.
- Ikona zobrazena uvnitř type badge před názvem
- Výchozí: MapPin pro neznámé/chybějící ikony

### A3. Perex — vícejazyčný
- `PoiSlugData.poi_perex` typ změněn na `Record<string, string> | null`
- Perex rozlišen dle aktuálního jazyka (fallback: cs → en)

### A4. Audio guides — všech 11 jazyků
- Místo filtrování jen existujících jazyků se zobrazují všechny z `LANG_CODES`
- Jazyky bez guides: "No guides" placeholder
- Pro přihlášené: zobrazení zkráceného ID guide (prvních 8 znaků UUID)

---

## D7-007: PoiForm — 11 jazyků + opravy

**Soubor:** `web/src/components/pois/PoiForm.tsx`

### B1. "Name" label — hardcoded
- Label "Name" se nikdy nepřekládá, vždy `Name ({jazyk})`

### B2. 11jazyčný pill switcher
- Nahrazeny 2záložkové CS/EN Tabs jedním pill switcherem (stejný styl jako PoiTypesPage)
- Jeden aktivní jazyk, jedno textové pole pro Name/Description/Perex
- Schema dynamicky generuje `name_{code}`, `description_{code}`, `perex_{code}` pro všech 11 jazyků
- Na submit: JSONB objekty sestaveny pouze z neprázdných hodnot

### B3. Perex nad Description
- Perex blok přesunut před Description

### B4. Perex — vícejazyčný JSONB
- Perex nyní používá stejný pill switcher jako Name/Description
- Na submit: `perex: { cs: "...", en: "..." }` (JSONB)

---

## D7-008: AudioUploader — 11 jazyků + file info + uploader

**Soubor:** `web/src/components/pois/AudioUploader.tsx`

### C1. 11 jazyků
- Místo 6 jazyků (cs, en, de, sk, es, fr) nyní všech 11 z `LANG_CODES`

### C2. File ID/název
- Extrakce názvu souboru z URL
- Zobrazení vedle přehrávače (monospace, muted)

### C3. Jméno uploadera
- Po načtení guides: dotaz na `admin_users_view` pro `uploaded_by` IDs
- Zobrazení emailu/jména uploadera vedle každého guide

---

## D7-009: Opravy závislých komponent

### PlaceDetailSheet
**Soubor:** `web/src/components/account/PlaceDetailSheet.tsx`
- `perex` typ změněn na `Record<string, string> | null`
- Perex rozlišen dle jazyka (fallback: cs → en)

### ExploreMap
**Soubor:** `web/src/components/account/ExploreMap.tsx`
- `NearbyPoi.perex` typ změněn na `Record<string, string> | null`

---

## D7-010: PoiTypesPage — import ze sdílených konstant

**Soubor:** `web/src/pages/poi-types/PoiTypesPage.tsx`

- Lokální `LANG_CODES` odstraněn, nahrazen importem z `@/lib/constants`

---

## Ověření

1. `npm run build` + `tsc --noEmit` — bez chyb ✓
2. Migrace 035 + 036 — perex konvertován na JSONB, RPC aktualizován
3. PlaceDetailPage: GPS souřadnice, type icon, 11 jazyků v audio sekci, vícejazyčný perex
4. PoiForm: pill switcher 11 jazyků, Name vždy anglicky, perex nad description, JSONB perex
5. AudioUploader: 11 jazyků, file info, uploader info

---

## Soubory změněné

| Soubor | Operace |
|--------|---------|
| `web/src/lib/constants.ts` | NOVÝ — sdílené LANG_CODES, LANG_LABELS |
| `backend/supabase/migrations/035_perex_jsonb_audio_uploaded_by.sql` | NOVÝ |
| `backend/supabase/migrations/036_fix_get_poi_by_slug_perex.sql` | NOVÝ |
| `backend/supabase/functions/admin-api/index.ts` | UPRAVENO — uploaded_by auto-set |
| `web/src/lib/supabase/types.ts` | UPRAVENO — perex JSONB, uploaded_by |
| `web/src/pages/PlaceDetailPage.tsx` | UPRAVENO — GPS, icon, 11 langs, perex JSONB |
| `web/src/components/pois/PoiForm.tsx` | UPRAVENO — 11 langs, perex JSONB, reorder |
| `web/src/components/pois/AudioUploader.tsx` | UPRAVENO — 11 langs, file info, uploader |
| `web/src/pages/poi-types/PoiTypesPage.tsx` | UPRAVENO — import z constants |
| `web/src/components/account/PlaceDetailSheet.tsx` | UPRAVENO — perex JSONB |
| `web/src/components/account/ExploreMap.tsx` | UPRAVENO — perex JSONB |
