# DIFF-SPECIFICATION-005: Hierarchický strom měst a míst

Datum: 2026-03-10

## Přehled změn

Sdílená stromová komponenta `CityPoiTree` pro CitiesPage (admin) a MyPoisPage (contributor).
Cross-level vyhledávání (země, města, místa), fixní výška s vnitřním scrollem,
obnovení tvorby měst pro contributory.

---

## D5-001: Migrace 029 — Contributor city write

**Soubor:** `backend/supabase/migrations/029_contributor_city_write.sql`

Povolení zápisu do tabulky `cities` pro roli `contributor` v ACL:

```sql
UPDATE acl_permissions SET can_write = true
WHERE role = 'contributor' AND resource = 'cities';
```

Contributor může vytvořit město, ale admin-api vynucuje `is_active = false`.

---

## D5-002: admin-api guard — contributor insert force is_active=false

**Soubor:** `backend/supabase/functions/admin-api/index.ts`

Před existující insert handler přidáno:

```ts
if (role === 'contributor' && table === 'cities') {
  data.is_active = false
}
```

Legacy fallback pro contributor rozšířen o `'cities'` v write seznamu.

Důsledek:
- Contributor INSERT cities → OK (vždy `is_active = false`)
- Contributor UPDATE cities → 403 (nemá write na cities v ACL pro update — ACL povoluje pouze insert via admin-api guard)

---

## D5-003: CityPoiTree sdílená komponenta

**Nový soubor:** `web/src/components/shared/CityPoiTree.tsx`

### Props
- `cities: City[]` — seznam měst
- `poisByCity: Record<string, Poi[]>` — POI seskupené podle city_id
- `search: string` — aktuální vyhledávací řetězec
- `renderCityActions?: (city: City) => ReactNode` — custom akce pro řádek města
- `renderPoiRow?: (poi: Poi, city: City) => ReactNode` — custom renderování POI řádku
- `emptyMessage?: string` — zpráva pro prázdný stav
- `className?: string` — doplňkové CSS třídy

### Funkcionalita
- **3-úrovňový strom:** Country → City → POI, každá úroveň rozbalitelná kliknutím
- **Cross-level search:**
  - Match na POI → auto-rozbalí parent country + city, zobrazí jen matchující POI
  - Match na city → auto-rozbalí parent country
  - Match na country → zobrazí celou zemi (města sbalená)
  - Prázdný search → normální strom (uživatel rozbaluje ručně)
- **Fixní výška:** `overflow-y-auto` s `max-h` nastaveným přes `className` prop
- **Vizuální hierarchie:**
  - Country: `bg-muted/50`, font-semibold, ChevronDown/Right, počet měst + POI
  - City: `pl-6`, font-medium, custom actions slot
  - POI: `pl-12`, text-sm, custom render slot
- **Performance:** `useMemo` na filtrování, 200ms debounce na search v rodičovské stránce

---

## D5-004: CitiesPage redesign

**Soubor:** `web/src/pages/cities/CitiesPage.tsx` — přepis

### Layout
```
┌─────────────────────────────────────┐
│ [🔍 Search...]         [Map ▾] [+] │  ← fixní header
├─────────────────────────────────────┤
│ CitiesMap (collapsible, default ON) │  ← h-[360px], toggle tlačítko
├─────────────────────────────────────┤
│ CityPoiTree                        │
│   ▸ Czech Republic (3 · 12 places) │  ← max-h s overflow scroll
│     ▸ Prague · 4.99 EUR · Active   │
│       • Old Town Square · public   │
│       • Charles Bridge · premium   │
│     ▸ Brno · 2.99 EUR · Inactive  │
│   ▸ Germany (2)                    │
└─────────────────────────────────────┘
```

### Klíčové změny
- Všechny POI se načtou při mount (lightweight select: id, name, city_id, is_active, access_level, type_id, sort_order)
- Mapa: collapsible (default visible), toggle tlačítkem v headeru
- Search: placeholder "Search countries, cities, places..." — hledá na všech úrovních
- Strom: `CityPoiTree` s `renderCityActions` (cena, active badge, Edit + POIs tlačítka)
- POI řádky: odkaz na detail, access_level badge, active badge
- Tree kontejner: `max-h-[calc(100vh-16rem)]` pro scroll

---

## D5-005: MyPoisPage redesign

**Soubor:** `web/src/pages/my-pois/MyPoisPage.tsx` — přepis

### Layout
```
┌─────────────────────────────────────┐
│ My Places    [🔍 Search...] [+ New]│  ← fixní header
├─────────────────────────────────────┤
│ CityPoiTree                        │
│   ▸ Czech Republic (2)             │  ← max-h s overflow scroll
│     ▸ Prague                       │
│       • My POI 1 · ★ 4.2 · Active │
│       • My POI 2 · Inactive       │
└─────────────────────────────────────┘
```

### Klíčové změny
- Použije `CityPoiTree` s custom `renderPoiRow` (rating hvězdička, edit button, active badge)
- Search bar s debounce
- Data: fetch z `supabase.from('pois')` s city join, přestrukturováno do `poisByCity`
- Tree kontejner: `max-h-[calc(100vh-14rem)]`

---

## D5-006: MyPoiEditorPage — obnovení city creation flow

**Soubor:** `web/src/pages/my-pois/MyPoiEditorPage.tsx` — úprava

### City selection flow
1. Dropdown s městy seskupenými podle země (`<optgroup>`) + poslední option `"+ Create new city/area"`
2. Po výběru `__create_new__` → inline formulář:
   - Name, Country, Country code (2 chars), Lat/Lng + MapPicker
   - Note: "New city will be inactive until approved by admin"
   - Button "Create City" → `adminInsert('cities', { ...data, is_active: false })`
3. Po úspěšném vytvoření → město se přidá do selectu a automaticky vybere
4. Dropdown nyní zobrazuje i neaktivní města (odstraněn filter `is_active: true`)

---

## D5-007: i18n klíče

### Nové klíče (EN + CS)
```
admin.cities.searchAll      — "Search countries, cities, places..."
admin.cities.toggleMap      — "Map"
admin.cities.poiCount       — "{{count}} places"
admin.myPois.searchPlaceholder — "Search places..."
admin.myPois.cityPendingNote   — "New city will be inactive until approved by admin."
```

Existující klíče beze změn:
- `admin.myPois.createNewCity`, `createCity`, `newCityDetails`, `cityNamePlaceholder`,
  `country`, `countryPlaceholder`, `countryCode`, `newCityNote`, `cityCreated`,
  `cityFieldsRequired`, `countryCodeLength`

---

## D5-008: Migrace 030 — aliases columns

**Soubor:** `backend/supabase/migrations/030_aliases.sql`

Přidání sloupců pro alternativní názvy na všech 3 úrovních stromu:

```sql
ALTER TABLE public.cities ADD COLUMN aliases TEXT[] NOT NULL DEFAULT '{}';
ALTER TABLE public.cities ADD COLUMN country_aliases TEXT[] NOT NULL DEFAULT '{}';
ALTER TABLE public.pois ADD COLUMN aliases TEXT[] NOT NULL DEFAULT '{}';
```

- `cities.aliases` — alternativní názvy města (Plzeň → ["Pilsen", "Pilsner"])
- `cities.country_aliases` — alternativní názvy země (Czech Republic → ["Czechia", "Česká Republika"])
- `pois.aliases` — alternativní názvy místa

Country aliases žijí na city row (není tabulka countries). CityPoiTree agreguje ze všech měst dané země přes Set.

---

## D5-009: Diacritics-insensitive search

**Soubor:** `web/src/lib/utils.ts`

Nová utility funkce:

```ts
export function removeDiacritics(str: string): string {
  return str.normalize('NFD').replace(/[\u0300-\u036f]/g, '')
}
```

CityPoiTree používá normalizaci přes helper `norm()`:
```ts
const norm = (s: string) => removeDiacritics(s).toLowerCase()
```

Všechny `.toLowerCase().includes()` nahrazeny za `norm().includes()` — hledání "Plzen" najde "Plzeň", "Ceska" najde "Česká".

---

## D5-010: Alternativní názvy — DB schema, TagInput, formuláře, zobrazení

### TagInput komponenta

**Nový soubor:** `web/src/components/shared/TagInput.tsx`

Props: `value: string[]`, `onChange: (tags: string[]) => void`, `placeholder?: string`

UX:
- Input → Enter přidá tag jako pill s X tlačítkem
- Backspace na prázdném inputu smaže poslední tag
- Blur na neprázdném inputu přidá tag
- Deduplikace — nelze přidat duplicitní tag

### Formuláře

- **CityForm:** 2× `<TagInput>` pod Name/Country — "City Aliases" + "Country Aliases"
- **PoiForm:** 1× `<TagInput>` pod language tabs — "Aliases / Alternative Names"
- **MyPoiEditorPage:** 1× `<TagInput>` v content card

### Zobrazení v CityPoiTree

- Country řádek: `{country} (alias1, alias2)` — max 2 aliasy z agregovaných country_aliases
- City řádek: `{city.name} (first_alias)` — první alias
- POI řádek (default): `{poi_name} (first_alias)` — první alias
- CitiesPage custom renderPoiRow: první alias v závorce

### Search

Aliasy se prohledávají na všech 3 úrovních:
- Country: `norm(country).includes(ns) || countryAliases.some(a => norm(a).includes(ns))`
- City: `norm(city.name).includes(ns) || city.aliases.some(a => norm(a).includes(ns))`
- POI: `Object.values(poi.name).some(n => norm(n).includes(ns)) || poi.aliases.some(a => norm(a).includes(ns))`

---

## D5-011: i18n klíče pro aliases

### Nové klíče (EN + CS)

```
poiForm.aliases          — "Aliases / Alternative Names" / "Aliasy / Alternativní názvy"
poiForm.aliasesHelp      — "Alternative names for this place" / "Alternativní názvy tohoto místa"
poiForm.aliasPlaceholder — "Type and press Enter..." / "Napište a stiskněte Enter..."
cityForm.aliases         — "City Aliases" / "Aliasy města"
cityForm.aliasesHelp     — "Alternative names (e.g., Pilsen, Pilsner)" / "Alternativní názvy (např. Pilsen, Pilsner)"
cityForm.countryAliases  — "Country Aliases" / "Aliasy země"
cityForm.countryAliasesHelp — "Alternative names for the country" / "Alternativní názvy země"
cityForm.aliasPlaceholder — "Type and press Enter..." / "Napište a stiskněte Enter..."
```
