# DIFF-008 — Audio guide řádek redesign + širší PlaceDetailPage + přehrávač pro oprávněné uživatele

## Kontext

Audio guide řádky v admin panelu jsou stísněné — titulky se ořezávají, pořadí informací je suboptimální. Veřejná PlaceDetailPage je zbytečně úzká (`max-w-2xl` = 672px vs. header/footer `max-w-7xl`). Metadata audio guide jsou skrytá pro nepřihlášené návštěvníky. Uživatelé s oprávněním nemohou přehrávat audio na veřejné stránce.

---

## D8-001: Admin AudioUploader — přeuspořádání a přestylování řádku

**Soubor:** `web/src/components/pois/AudioUploader.tsx`

Nové pořadí prvků v řádku:
```
grip | @uploader | title | filename | duration | ████ audio player ████ | delete
                                                  ^--- černé pozadí, flex-1 (vyplní zbytek)
```

Změny:
- Blok uploadera přesunut hned za `<GripVertical>` (byl na konci)
- `max-w-[80px]` na jménu uploadera → `max-w-[120px]`
- Titulek změněn z `flex-1` na `flex-shrink min-w-0 truncate max-w-[300px]` — audio přehrávač dostane zbývající prostor
- Audio přehrávač: zabalený v `<div className="flex-1 min-w-[160px] bg-gray-900 rounded px-1 py-0.5">` s `<audio className="h-6 w-full" />`
- Tlačítko smazání zůstává na konci

---

## D8-002: Rozšíření PlaceDetailPage

**Soubor:** `web/src/pages/PlaceDetailPage.tsx`

- Breadcrumb kontejner: `max-w-2xl` → `max-w-7xl`
- Hlavní obsah kontejner: `max-w-2xl` → `max-w-7xl`
- Odpovídá šířce header/footer

---

## D8-003: Audio guide detaily viditelné pro VŠECHNY návštěvníky

**Soubor:** `web/src/pages/PlaceDetailPage.tsx`

- Odstraněna podmínka `isLoggedIn &&` — řádky s detaily průvodců se renderují pro všechny
- Pořadí řádku odpovídá admin (bez přehrávače a mazání):
  ```
  @uploader_handle | title | filename (8-char ID) | duration
  ```

---

## D8-004: Audio přehrávač na veřejné stránce pro oprávněné uživatele

**Soubor:** `web/src/pages/PlaceDetailPage.tsx`

### D8-004a: Nový stav
```tsx
const [accessLevel, setAccessLevel] = useState<string | null>(null)
const [audioUrls, setAudioUrls] = useState<Map<string, string>>(new Map())
```

### D8-004b: Načtení úrovně přístupu
- Nový `useEffect` — volá `get_poi_access` RPC při nastavení `poi` + `user`
- Výsledek uložen do `accessLevel`

### D8-004c: Určení oprávnění
```tsx
const ACCESS_HIERARCHY = {
  public: 0, registered: 1, registered_limited: 1,
  city_access: 2, premium_poi: 3, full: 4,
}
const hasAudioAccess = userLevel >= poiRequired
```

### D8-004d: Načtení audio URL
- Nový `useEffect` — při `hasAudioAccess === true` dotáže `poi_audio_guides` tabulku
- Výsledek uložen jako `Map<id, url>`

### D8-004e: Vykreslení přehrávače
- Pod info řádkem každého guide se zobrazí `<audio>` v černém kontejneru, pokud `audioUrls.has(g.id)`

### D8-004f: Aktualizace spodní CTA
- Má audio přístup → nic (přehrávač je inline)
- Přihlášen, nemá přístup → "Purchase to listen"
- Nepřihlášen → "Sign in to listen"

---

## D8-005: Žádné backendové změny

- `get_poi_access` RPC už existuje (migrace 018)
- `poi_audio_guides` má `FOR SELECT USING (true)` RLS → čitelné pro kohokoli
- `audio-guides` storage bucket je veřejný
- Žádné nové migrace, žádné úpravy RPC

---

## Dotčené soubory

| # | Soubor | Změna |
|---|--------|-------|
| 1 | `web/src/components/pois/AudioUploader.tsx` | Přeuspořádání řádku: uploader→title→filename→duration→player(černý,flex-1)→delete |
| 2 | `web/src/pages/PlaceDetailPage.tsx` | Rozšíření `max-w-2xl`→`max-w-7xl`, odstraněna brána pro detaily, kontrola přístupu + načtení audia + přehrávač |

## Ověření

1. `tsc --noEmit` — čistý
2. `npm run build` — čistý
3. Vizuálně: admin POI edit → Audio záložka → ověřit pořadí řádku: @handle, title, filename, duration, černý přehrávač
4. Vizuálně: veřejná stránka → vyplní šířku headeru, detaily průvodce viditelné bez přihlášení
5. Vizuálně: přihlášení → přehrávač se zobrazí pokud má oprávnění
