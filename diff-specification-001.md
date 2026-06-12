# HeroDots – Diferenciální specifikace mobilní aplikace
# Diff č.: 001
# Datum: 2026-03-07 09:25:36
# Téma: Hodnocení POI, systém přispěvatelů, Hall of Fame
# Soubor: specification-prompts.md
# Navazuje na: sekce 24 (POI typy, filtry, notifikace)

---

## Přehled změn

| # | Oblast | Typ změny |
|---|---|---|
| D-001 | DB – nová tabulka `poi_ratings` | NOVÉ |
| D-002 | DB – nová tabulka `contributor_profiles` | NOVÉ |
| D-003 | DB – pohled `contributor_rankings` | NOVÉ |
| D-004 | DB – RPC `poi_hall_of_fame()` | NOVÉ |
| D-005 | DB – úprava tabulky `pois` – sloupce pro autora | ZMĚNA |
| D-006 | Domain model `PoiRating` | NOVÉ |
| D-007 | Domain model `ContributorProfile` | NOVÉ |
| D-008 | Rozšíření modelu `Poi` – contributor pole | ZMĚNA |
| D-009 | `PoiDetailScreen` – widget hodnocení po poslechu | ZMĚNA |
| D-010 | Nová obrazovka `HallOfFameScreen` | NOVÉ |
| D-011 | `PoiDetailScreen` – badge autora | ZMĚNA |
| D-012 | Nový provider `poiRatingsProvider` | NOVÉ |
| D-013 | Nový provider `hallOfFameProvider` | NOVÉ |
| D-014 | Nový repository `RatingsRepository` | NOVÉ |
| D-015 | GoRouter – nové routes | ZMĚNA |
| D-016 | BottomNav / navigace – HoF záložka | ZMĚNA |
| D-017 | `SettingsScreen` – sekce přispěvatelský profil | ZMĚNA |
| D-018 | Drift lokální DB – tabulka rated_pois | NOVÉ |
| D-019 | Roadmapa – nové kroky | ZMĚNA |

---

## D-001 – DB tabulka `poi_ratings`

```sql
-- supabase/migrations/008_ratings_and_contributors.sql

-- Hodnocení jednotlivých POI průvodců
CREATE TABLE public.poi_ratings (
  id           UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  poi_id       UUID NOT NULL REFERENCES public.pois(id) ON DELETE CASCADE,
  user_id      UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  device_id    TEXT,                          -- anonymní uživatel
  rating       SMALLINT NOT NULL CHECK (rating BETWEEN 1 AND 5),
  -- Volitelný důvod při hodnocení 1–2 hvězdičky
  reason       TEXT CHECK (reason IN (
                 'inaccurate',   -- Nepřesné informace
                 'too_short',    -- Příliš krátké
                 'boring',       -- Nezajímavé
                 'wrong_lang',   -- Špatný jazyk
                 'other'
               )),
  lang_code    TEXT NOT NULL DEFAULT 'cs',   -- jazyk ve kterém uživatel poslouchal
  created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),

  -- Jeden uživatel/zařízení = jedno hodnocení per POI
  UNIQUE(poi_id, user_id),
  UNIQUE(poi_id, device_id)
);

CREATE INDEX idx_poi_ratings_poi   ON public.poi_ratings(poi_id);
CREATE INDEX idx_poi_ratings_user  ON public.poi_ratings(user_id);

ALTER TABLE public.poi_ratings ENABLE ROW LEVEL SECURITY;

-- Čtení: každý může číst agregáty (přes RPC), ne raw data
CREATE POLICY "ratings_own_read" ON public.poi_ratings
  FOR SELECT USING (auth.uid() = user_id OR device_id IS NOT NULL);

-- Vložení: přihlášený nebo anonymní (device_id)
CREATE POLICY "ratings_insert" ON public.poi_ratings
  FOR INSERT WITH CHECK (
    auth.uid() = user_id OR user_id IS NULL
  );

-- Aktualizace vlastního hodnocení (přehodnocení)
CREATE POLICY "ratings_own_update" ON public.poi_ratings
  FOR UPDATE USING (auth.uid() = user_id);
```

---

## D-002 – DB tabulka `contributor_profiles`

```sql
-- Profil přispěvatele obsahu (průvodce)
-- Uživatel se dobrovolně přihlásí jako přispěvatel
CREATE TABLE public.contributor_profiles (
  id               UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id          UUID NOT NULL UNIQUE REFERENCES auth.users(id) ON DELETE CASCADE,

  -- Veřejně viditelné informace
  display_name     TEXT NOT NULL,                -- "Jan Novák"
  bio              TEXT,                          -- krátké představení, max 300 znaků
  avatar_url       TEXT,                          -- Supabase Storage: contributor-avatars/
  website_url      TEXT,                          -- osobní web / LinkedIn

  -- Specializace (vícejazyčný JSONB nebo pole slugů z poi_types)
  specializations  TEXT[] DEFAULT '{}',           -- ['monument', 'church', 'historic']

  -- Statistiky (denormalizované pro rychlé čtení, aktualizuje trigger)
  total_pois       INTEGER NOT NULL DEFAULT 0,
  avg_rating       DECIMAL(3,2),                  -- průměr přes všechna jeho POI
  total_ratings    INTEGER NOT NULL DEFAULT 0,    -- celkový počet hodnocení

  -- Stav
  is_verified      BOOLEAN NOT NULL DEFAULT FALSE, -- admin ověřil identitu
  is_active        BOOLEAN NOT NULL DEFAULT TRUE,

  created_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at       TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_contributor_user ON public.contributor_profiles(user_id);
CREATE INDEX idx_contributor_rating ON public.contributor_profiles(avg_rating DESC NULLS LAST);

ALTER TABLE public.contributor_profiles ENABLE ROW LEVEL SECURITY;

-- Veřejné čtení aktivních profilů
CREATE POLICY "contributor_public_read" ON public.contributor_profiles
  FOR SELECT USING (is_active = TRUE);

-- Uživatel edituje jen svůj profil
CREATE POLICY "contributor_own_write" ON public.contributor_profiles
  FOR ALL USING (auth.uid() = user_id);
```

---

## D-003 – DB pohled `contributor_rankings`

```sql
-- Pohled pro ranking přispěvatelů per město
-- Použití: Hall of Fame obrazovka, badge na POI

CREATE OR REPLACE VIEW public.contributor_rankings AS
SELECT
  cp.id                AS contributor_id,
  cp.user_id,
  cp.display_name,
  cp.avatar_url,
  cp.is_verified,
  cp.total_pois,
  cp.avg_rating,
  cp.total_ratings,
  c.id                 AS city_id,
  c.name               AS city_name,

  -- Počet POI v daném městě
  COUNT(p.id)          AS city_poi_count,

  -- Průměrné hodnocení v daném městě
  ROUND(AVG(
    (SELECT AVG(r.rating) FROM public.poi_ratings r WHERE r.poi_id = p.id)
  )::NUMERIC, 2)       AS city_avg_rating,

  -- Celkový počet hodnocení v daném městě
  SUM(
    (SELECT COUNT(*) FROM public.poi_ratings r WHERE r.poi_id = p.id)
  )                    AS city_total_ratings,

  -- Skóre pro řazení: avg_rating × log10(total_ratings + 1)
  -- Minimálně 10 hodnocení pro vstup do žebříčku
  CASE
    WHEN SUM(
      (SELECT COUNT(*) FROM public.poi_ratings r WHERE r.poi_id = p.id)
    ) >= 10
    THEN ROUND((
      AVG(
        (SELECT AVG(r.rating) FROM public.poi_ratings r WHERE r.poi_id = p.id)
      ) * LOG(
        SUM(
          (SELECT COUNT(*) FROM public.poi_ratings r WHERE r.poi_id = p.id)
        ) + 1
      )
    )::NUMERIC, 4)
    ELSE NULL
  END                  AS hof_score,

  -- Pořadí v daném městě (NULL pokud nesplňuje minimum)
  RANK() OVER (
    PARTITION BY c.id
    ORDER BY CASE
      WHEN SUM(
        (SELECT COUNT(*) FROM public.poi_ratings r WHERE r.poi_id = p.id)
      ) >= 10
      THEN AVG(
        (SELECT AVG(r.rating) FROM public.poi_ratings r WHERE r.poi_id = p.id)
      ) * LOG(
        SUM(
          (SELECT COUNT(*) FROM public.poi_ratings r WHERE r.poi_id = p.id)
        ) + 1
      )
      ELSE NULL
    END DESC NULLS LAST
  )                    AS city_rank

FROM public.contributor_profiles cp
JOIN public.pois p ON p.contributor_id = cp.user_id AND p.is_active = TRUE
JOIN public.cities c ON c.id = p.city_id
GROUP BY cp.id, cp.user_id, cp.display_name, cp.avatar_url,
         cp.is_verified, cp.total_pois, cp.avg_rating, cp.total_ratings,
         c.id, c.name;

GRANT SELECT ON public.contributor_rankings TO anon, authenticated, service_role;
```

---

## D-004 – DB RPC `poi_hall_of_fame()`

```sql
-- RPC pro načtení Top 10 průvodců pro dané město
-- Použití: HallOfFameScreen, widget na MapScreen

CREATE OR REPLACE FUNCTION public.poi_hall_of_fame(
  p_city_id   UUID,
  p_limit     INTEGER DEFAULT 10
)
RETURNS TABLE (
  rank            BIGINT,
  contributor_id  UUID,
  display_name    TEXT,
  avatar_url      TEXT,
  is_verified     BOOLEAN,
  city_poi_count  BIGINT,
  city_avg_rating DECIMAL,
  city_total_ratings BIGINT,
  hof_score       DECIMAL,
  -- Příklady POI (první 3 jména pro náhled)
  sample_poi_names JSONB
)
LANGUAGE sql STABLE SECURITY DEFINER AS $$
  SELECT
    cr.city_rank        AS rank,
    cr.contributor_id,
    cr.display_name,
    cr.avatar_url,
    cr.is_verified,
    cr.city_poi_count,
    cr.city_avg_rating,
    cr.city_total_ratings,
    cr.hof_score,
    (
      SELECT jsonb_agg(p.name ORDER BY p.sort_order)
      FROM public.pois p
      WHERE p.contributor_id = cr.user_id
        AND p.city_id = p_city_id
        AND p.is_active = TRUE
      LIMIT 3
    ) AS sample_poi_names
  FROM public.contributor_rankings cr
  WHERE cr.city_id = p_city_id
    AND cr.hof_score IS NOT NULL
    AND cr.city_rank <= p_limit
  ORDER BY cr.city_rank
  LIMIT p_limit;
$$;

GRANT EXECUTE ON FUNCTION public.poi_hall_of_fame TO anon, authenticated;
```

---

## D-005 – Úprava tabulky `pois` – sloupce pro autora

```sql
-- Přidat do 008_ratings_and_contributors.sql:

ALTER TABLE public.pois
  ADD COLUMN contributor_id   UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  ADD COLUMN contributor_note TEXT;   -- interní poznámka autora (admin-only)

-- Agregovaná hodnocení na POI (denormalizováno pro rychlé čtení)
ALTER TABLE public.pois
  ADD COLUMN avg_rating     DECIMAL(3,2),
  ADD COLUMN total_ratings  INTEGER NOT NULL DEFAULT 0;

CREATE INDEX idx_pois_contributor ON public.pois(contributor_id);

-- Trigger: po každém novém hodnocení aktualizovat avg_rating + total_ratings na POI
-- a přepočítat statistiky contributor_profile
CREATE OR REPLACE FUNCTION public.update_poi_rating_stats()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
DECLARE
  v_avg    DECIMAL(3,2);
  v_count  INTEGER;
  v_contributor_id UUID;
BEGIN
  -- Přepočítat stats POI
  SELECT ROUND(AVG(rating)::NUMERIC, 2), COUNT(*)
    INTO v_avg, v_count
    FROM public.poi_ratings
    WHERE poi_id = NEW.poi_id;

  UPDATE public.pois
    SET avg_rating = v_avg, total_ratings = v_count
    WHERE id = NEW.poi_id
    RETURNING contributor_id INTO v_contributor_id;

  -- Přepočítat stats contributor_profile
  IF v_contributor_id IS NOT NULL THEN
    UPDATE public.contributor_profiles
      SET
        avg_rating = (
          SELECT ROUND(AVG(pr.rating)::NUMERIC, 2)
          FROM public.poi_ratings pr
          JOIN public.pois p ON p.id = pr.poi_id
          WHERE p.contributor_id = v_contributor_id
        ),
        total_ratings = (
          SELECT COUNT(*)
          FROM public.poi_ratings pr
          JOIN public.pois p ON p.id = pr.poi_id
          WHERE p.contributor_id = v_contributor_id
        ),
        updated_at = NOW()
      WHERE user_id = v_contributor_id;
  END IF;

  RETURN NEW;
END;
$$;

CREATE TRIGGER trg_update_poi_rating_stats
  AFTER INSERT OR UPDATE ON public.poi_ratings
  FOR EACH ROW EXECUTE FUNCTION public.update_poi_rating_stats();

-- Trigger: aktualizovat total_pois v contributor_profile při změně POI
CREATE OR REPLACE FUNCTION public.update_contributor_poi_count()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
  IF NEW.contributor_id IS NOT NULL THEN
    UPDATE public.contributor_profiles
      SET total_pois = (
        SELECT COUNT(*) FROM public.pois
        WHERE contributor_id = NEW.contributor_id AND is_active = TRUE
      ),
      updated_at = NOW()
    WHERE user_id = NEW.contributor_id;
  END IF;
  RETURN NEW;
END;
$$;

CREATE TRIGGER trg_update_contributor_poi_count
  AFTER INSERT OR UPDATE OF is_active, contributor_id ON public.pois
  FOR EACH ROW EXECUTE FUNCTION public.update_contributor_poi_count();
```

---

## D-006 – Domain model `PoiRating`

```dart
// lib/domain/models/poi_rating.dart
import 'package:freezed_annotation/freezed_annotation.dart';
part 'poi_rating.freezed.dart';
part 'poi_rating.g.dart';

enum RatingReason {
  @JsonValue('inaccurate')  inaccurate,
  @JsonValue('too_short')   tooShort,
  @JsonValue('boring')      boring,
  @JsonValue('wrong_lang')  wrongLang,
  @JsonValue('other')       other,
}

@freezed
class PoiRating with _$PoiRating {
  const factory PoiRating({
    required String id,
    required String poiId,
    String? userId,
    String? deviceId,
    required int rating,              // 1–5
    RatingReason? reason,
    required String langCode,
    required DateTime createdAt,
  }) = _PoiRating;

  factory PoiRating.fromJson(Map<String, dynamic> json) =>
      _$PoiRatingFromJson(json);
}
```

---

## D-007 – Domain model `ContributorProfile`

```dart
// lib/domain/models/contributor_profile.dart
import 'package:freezed_annotation/freezed_annotation.dart';
part 'contributor_profile.freezed.dart';
part 'contributor_profile.g.dart';

@freezed
class ContributorProfile with _$ContributorProfile {
  const ContributorProfile._();

  const factory ContributorProfile({
    required String id,
    required String userId,
    required String displayName,
    String? bio,
    String? avatarUrl,
    String? websiteUrl,
    @Default([]) List<String> specializations,
    @Default(0) int totalPois,
    double? avgRating,
    @Default(0) int totalRatings,
    @Default(false) bool isVerified,
    @Default(true) bool isActive,
    required DateTime createdAt,
  }) = _ContributorProfile;

  factory ContributorProfile.fromJson(Map<String, dynamic> json) =>
      _$ContributorProfileFromJson(json);

  /// Zobrazit počet hvězdiček jako text: "4.7 ★ (142 hodnocení)"
  String get ratingLabel {
    if (avgRating == null || totalRatings == 0) return 'Bez hodnocení';
    return '${avgRating!.toStringAsFixed(1)} ★ ($totalRatings hodnocení)';
  }
}

// Hall of Fame entry (výsledek RPC poi_hall_of_fame)
@freezed
class HallOfFameEntry with _$HallOfFameEntry {
  const factory HallOfFameEntry({
    required int rank,
    required String contributorId,
    required String displayName,
    String? avatarUrl,
    @Default(false) bool isVerified,
    required int cityPoiCount,
    double? cityAvgRating,
    required int cityTotalRatings,
    double? hofScore,
    @Default([]) List<Map<String, String>> samplePoiNames,
  }) = _HallOfFameEntry;

  factory HallOfFameEntry.fromJson(Map<String, dynamic> json) =>
      _$HallOfFameEntryFromJson(json);
}
```

---

## D-008 – Rozšíření modelu `Poi`

```dart
// lib/domain/models/poi.dart – přidat pole:

@freezed
class Poi with _$Poi {
  const Poi._();

  const factory Poi({
    required String id,
    required String cityId,
    String? typeId,
    PoiType? poiType,
    // ── NOVÉ ──────────────────────────────────
    String? contributorId,
    ContributorProfile? contributor,    // joined ze Supabase
    @Default(0) int totalRatings,
    double? avgRating,
    // ──────────────────────────────────────────
    required Map<String, String> name,
    required Map<String, String> description,
    required double latitude,
    required double longitude,
    @Default(100.0) double geofenceRadius,
    @Default([]) List<String> photoUrls,
    @Default({}) Map<String, String?> audioUrls,
    @Default(true) bool isPremium,
    required DateTime createdAt,
  }) = _Poi;

  factory Poi.fromJson(Map<String, dynamic> json) => _$PoiFromJson(json);

  // ... stávající extension metody beze změny ...

  /// Zobrazit zkrácené hodnocení pro badge: "4.8★"
  String? get ratingBadge => avgRating != null && totalRatings >= 5
    ? '${avgRating!.toStringAsFixed(1)}★'
    : null;

  /// Splňuje minimum pro Hall of Fame
  bool get qualifiesForHoF => totalRatings >= 10;
}
```

---

## D-009 – `PoiDetailScreen` – widget hodnocení po poslechu

```
Umístění v layoutu PoiDetailScreen:
  Section 2 – AudioGuideWidget (beze změny)
  ↓
  Section 2b – RatingWidget (NOVÉ – zobrazí se po dokončení poslechu nebo po 30s)
  ↓
  Section 3 – Vaše záznamy (beze změny)
```

```dart
// lib/features/poi_detail/widgets/rating_widget.dart

class RatingWidget extends ConsumerStatefulWidget {
  final String poiId;
  final String langCode;

  const RatingWidget({required this.poiId, required this.langCode, super.key});

  @override
  ConsumerState<RatingWidget> createState() => _RatingWidgetState();
}

class _RatingWidgetState extends ConsumerState<RatingWidget> {
  int? _selected;       // 1–5, null = ještě nevybráno
  bool _submitted = false;
  bool _loading = false;
  RatingReason? _reason;

  @override
  Widget build(BuildContext context) {
    // Pokud uživatel již hodnotil → zobrazit jen výsledek
    final existing = ref.watch(myPoiRatingProvider(widget.poiId));
    if (existing.valueOrNull != null) {
      return _AlreadyRatedWidget(rating: existing.value!.rating);
    }

    if (_submitted) {
      return _ThankYouWidget();
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).colorScheme.outline.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Jak hodnotíte tohoto průvodce?',
            style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 12),

          // Hvězdičky 1–5
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(5, (i) {
              final star = i + 1;
              return GestureDetector(
                onTap: () => setState(() => _selected = star),
                child: AnimatedScale(
                  scale: _selected != null && _selected! >= star ? 1.2 : 1.0,
                  duration: const Duration(milliseconds: 150),
                  child: Icon(
                    _selected != null && _selected! >= star
                      ? Icons.star_rounded
                      : Icons.star_outline_rounded,
                    color: _selected != null && _selected! >= star
                      ? const Color(0xFFB8960C)
                      : Colors.grey[400],
                    size: 36,
                  ),
                ),
              );
            }),
          ),

          // Důvod při nízkém hodnocení (1–2 hvězdičky)
          if (_selected != null && _selected! <= 2) ...[
            const SizedBox(height: 12),
            Text('Co bylo špatně? (volitelné)',
              style: Theme.of(context).textTheme.labelMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8, runSpacing: 8,
              children: [
                _ReasonChip(
                  label: 'Nepřesné informace',
                  value: RatingReason.inaccurate,
                  selected: _reason,
                  onTap: (r) => setState(() => _reason = r),
                ),
                _ReasonChip(
                  label: 'Příliš krátké',
                  value: RatingReason.tooShort,
                  selected: _reason,
                  onTap: (r) => setState(() => _reason = r),
                ),
                _ReasonChip(
                  label: 'Nezajímavé',
                  value: RatingReason.boring,
                  selected: _reason,
                  onTap: (r) => setState(() => _reason = r),
                ),
                _ReasonChip(
                  label: 'Špatný jazyk',
                  value: RatingReason.wrongLang,
                  selected: _reason,
                  onTap: (r) => setState(() => _reason = r),
                ),
              ],
            ),
          ],

          // Odeslat tlačítko
          if (_selected != null) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _loading ? null : _submit,
                child: _loading
                  ? const SizedBox(height: 16, width: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Odeslat hodnocení'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _submit() async {
    if (_selected == null) return;
    setState(() => _loading = true);

    await ref.read(ratingsRepositoryProvider).submitRating(
      poiId: widget.poiId,
      rating: _selected!,
      reason: _reason,
      langCode: widget.langCode,
    );

    setState(() { _loading = false; _submitted = true; });
  }
}

class _ThankYouWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    child: Row(children: [
      const Icon(Icons.check_circle_outline, color: Colors.green, size: 18),
      const SizedBox(width: 8),
      Text('Díky za hodnocení!',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.green)),
    ]),
  );
}

class _AlreadyRatedWidget extends StatelessWidget {
  final int rating;
  const _AlreadyRatedWidget({required this.rating});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    child: Row(children: [
      ...List.generate(5, (i) => Icon(
        i < rating ? Icons.star_rounded : Icons.star_outline_rounded,
        color: const Color(0xFFB8960C), size: 16,
      )),
      const SizedBox(width: 8),
      Text('Vaše hodnocení', style: Theme.of(context).textTheme.bodySmall),
    ]),
  );
}

class _ReasonChip extends StatelessWidget {
  final String label;
  final RatingReason value;
  final RatingReason? selected;
  final void Function(RatingReason) onTap;

  const _ReasonChip({
    required this.label, required this.value,
    required this.selected, required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: () => onTap(value),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: selected == value
          ? Theme.of(context).colorScheme.primary
          : Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: selected == value
            ? Theme.of(context).colorScheme.primary
            : Theme.of(context).colorScheme.outline,
        ),
      ),
      child: Text(label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: selected == value ? Colors.white : null,
        )),
    ),
  );
}
```

**Kdy zobrazit RatingWidget v PoiDetailScreen:**

```dart
// lib/features/poi_detail/poi_detail_screen.dart – přidat logiku zobrazení

// V AudioGuideNotifier – po dokončení přehrávání:
// state: completed → nastavit flag showRatingWidget = true

// V PoiDetailScreen buildu:
// Zobrazit RatingWidget pokud:
//   a) audio dokončeno (audioState == completed), NEBO
//   b) uživatel byl na stránce >30 sekund (Timer)
// Podmínka: ještě nehodnotil (myPoiRatingProvider == null)

// Implementace Timer:
late Timer _ratingTimer;

@override
void initState() {
  super.initState();
  _ratingTimer = Timer(const Duration(seconds: 30), () {
    if (mounted) setState(() => _showRating = true);
  });
}

@override
void dispose() {
  _ratingTimer.cancel();
  super.dispose();
}
```

---

## D-010 – Nová obrazovka `HallOfFameScreen`

```dart
// lib/features/hall_of_fame/hall_of_fame_screen.dart
// Route: /hall-of-fame/:cityId

class HallOfFameScreen extends ConsumerWidget {
  final String cityId;
  const HallOfFameScreen({required this.cityId, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hofAsync = ref.watch(hallOfFameProvider(cityId));
    final cityAsync = ref.watch(cityProvider(cityId));

    return Scaffold(
      appBar: AppBar(
        title: cityAsync.whenData((c) => Text('Průvodci – ${c.name}'))
                 .valueOrNull ?? const Text('Hall of Fame'),
        backgroundColor: const Color(0xFF2D6A4F),
        foregroundColor: Colors.white,
      ),
      body: hofAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(child: Text('Nepodařilo se načíst žebříček')),
        data: (entries) => entries.isEmpty
          ? _EmptyHoF()
          : ListView(
              children: [
                // Hlavička s vysvětlením
                _HoFHeader(),

                // Top 3 – zvýrazněné podium
                if (entries.length >= 3)
                  _PodiumWidget(entries: entries.take(3).toList()),

                const Divider(height: 32),

                // Zbytek seznamu (#4–#10)
                ...entries.skip(3).map((e) => _HoFListTile(entry: e)),

                const SizedBox(height: 24),

                // Info o způsobu hodnocení
                _ScoringInfoWidget(),
              ],
            ),
      ),
    );
  }
}

// ── Sub-widgets ──────────────────────────────────────────────

class _HoFHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(16),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        const Text('🏆', style: TextStyle(fontSize: 24)),
        const SizedBox(width: 8),
        Text('Hall of Fame',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold)),
      ]),
      const SizedBox(height: 4),
      Text('Top 10 průvodců podle hodnocení návštěvníků',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Colors.grey[600])),
    ]),
  );
}

class _PodiumWidget extends StatelessWidget {
  final List<HallOfFameEntry> entries; // přesně 3

  const _PodiumWidget({required this.entries});

  @override
  Widget build(BuildContext context) {
    // Vizuální podium: #2 vlevo, #1 uprostřed (výše), #3 vpravo
    final order = [entries[1], entries[0], entries[2]];
    final heights = [80.0, 110.0, 60.0];
    final medals = ['🥈', '🥇', '🥉'];
    final ranks = [2, 1, 3];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(3, (i) => Expanded(
          child: Column(children: [
            // Avatar
            CircleAvatar(
              radius: ranks[i] == 1 ? 32 : 24,
              backgroundImage: order[i].avatarUrl != null
                ? NetworkImage(order[i].avatarUrl!) : null,
              child: order[i].avatarUrl == null
                ? Text(order[i].displayName[0].toUpperCase(),
                    style: TextStyle(fontSize: ranks[i] == 1 ? 22 : 16))
                : null,
            ),
            const SizedBox(height: 4),
            Text(medals[i], style: const TextStyle(fontSize: 18)),
            Text(order[i].displayName,
              style: Theme.of(context).textTheme.labelSmall,
              textAlign: TextAlign.center,
              maxLines: 1, overflow: TextOverflow.ellipsis),
            Text('${order[i].cityAvgRating?.toStringAsFixed(1) ?? '–'}★',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: const Color(0xFFB8960C))),
            // Podium sloupec
            const SizedBox(height: 4),
            Container(
              height: heights[i],
              decoration: BoxDecoration(
                color: [Colors.grey[400], const Color(0xFFB8960C), const Color(0xFFCD7F32)][i],
                borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
              ),
              alignment: Alignment.center,
              child: Text('#${ranks[i]}',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ]),
        )),
      ),
    );
  }
}

class _HoFListTile extends StatelessWidget {
  final HallOfFameEntry entry;
  const _HoFListTile({required this.entry});

  @override
  Widget build(BuildContext context) => ListTile(
    leading: Stack(
      children: [
        CircleAvatar(
          backgroundImage: entry.avatarUrl != null
            ? NetworkImage(entry.avatarUrl!) : null,
          child: entry.avatarUrl == null
            ? Text(entry.displayName[0].toUpperCase()) : null,
        ),
        if (entry.isVerified)
          Positioned(bottom: 0, right: 0,
            child: Container(
              width: 14, height: 14,
              decoration: BoxDecoration(
                color: Colors.blue, shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1.5),
              ),
              child: const Icon(Icons.check, size: 9, color: Colors.white),
            )),
      ],
    ),
    title: Text(entry.displayName,
      style: const TextStyle(fontWeight: FontWeight.w600)),
    subtitle: Text(
      '${entry.cityPoiCount} míst · '
      '${entry.cityAvgRating?.toStringAsFixed(1) ?? '–'}★ '
      '(${entry.cityTotalRatings} hodnocení)'),
    trailing: Container(
      width: 36, height: 36,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(8),
      ),
      alignment: Alignment.center,
      child: Text('#${entry.rank}',
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
    ),
  );
}

class _ScoringInfoWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(16),
    child: Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Jak funguje žebříček?',
          style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 6),
        Text(
          'Skóre kombinuje průměrné hodnocení a počet hlasů. '
          'Průvodce potřebuje alespoň 10 hodnocení pro vstup do žebříčku.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Colors.grey[600]),
        ),
      ]),
    ),
  );
}

class _EmptyHoF extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Text('🏆', style: TextStyle(fontSize: 48)),
        const SizedBox(height: 16),
        Text('Žebříček je zatím prázdný',
          style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Text(
          'Průvodci se zobrazí poté, co nasbírají alespoň 10 hodnocení od návštěvníků.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey),
        ),
      ]),
    ),
  );
}
```

---

## D-011 – `PoiDetailScreen` – badge autora

```dart
// Přidat do AppBar actions nebo pod nadpis POI:

// V AppBar subtitle nebo jako řádek pod názvem POI:
if (poi.contributor != null)
  InkWell(
    onTap: () => context.push('/contributor/${poi.contributor!.userId}'),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        // Avatar
        CircleAvatar(
          radius: 12,
          backgroundImage: poi.contributor!.avatarUrl != null
            ? NetworkImage(poi.contributor!.avatarUrl!) : null,
          child: poi.contributor!.avatarUrl == null
            ? Text(poi.contributor!.displayName[0],
                style: const TextStyle(fontSize: 10)) : null,
        ),
        const SizedBox(width: 6),
        Text('Průvodce: ${poi.contributor!.displayName}',
          style: Theme.of(context).textTheme.bodySmall),
        // Verified badge
        if (poi.contributor!.isVerified) ...[
          const SizedBox(width: 3),
          const Icon(Icons.verified, size: 13, color: Colors.blue),
        ],
        // Rank badge pokud existuje
        if (poi.ratingBadge != null) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFFB8960C).withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(poi.ratingBadge!,
              style: const TextStyle(
                color: Color(0xFFB8960C),
                fontSize: 11, fontWeight: FontWeight.bold)),
          ),
        ],
      ]),
    ),
  ),
```

---

## D-012 – Nový provider `poiRatingsProvider`

```dart
// lib/features/poi_detail/providers/ratings_provider.dart

// Existující hodnocení aktuálního uživatele pro dané POI
@riverpod
Future<PoiRating?> myPoiRating(MyPoiRatingRef ref, String poiId) async {
  return ref.read(ratingsRepositoryProvider).getMyRating(poiId);
}

// Agregované stats pro POI (avg, count) – čte přímo z pois.avg_rating
@riverpod
Future<({double? avg, int count})> poiRatingStats(
  PoiRatingStatsRef ref, String poiId
) async {
  final data = await Supabase.instance.client
    .from('pois')
    .select('avg_rating, total_ratings')
    .eq('id', poiId)
    .single();
  return (
    avg: (data['avg_rating'] as num?)?.toDouble(),
    count: (data['total_ratings'] as int?) ?? 0,
  );
}
```

---

## D-013 – Nový provider `hallOfFameProvider`

```dart
// lib/features/hall_of_fame/hall_of_fame_provider.dart

@riverpod
Future<List<HallOfFameEntry>> hallOfFame(
  HallOfFameRef ref, String cityId
) async {
  final data = await Supabase.instance.client
    .rpc('poi_hall_of_fame', params: {'p_city_id': cityId, 'p_limit': 10});
  return (data as List)
    .map((e) => HallOfFameEntry.fromJson(e as Map<String, dynamic>))
    .toList();
}
```

---

## D-014 – Nový repository `RatingsRepository`

```dart
// lib/data/repositories/ratings_repository.dart

@riverpod
RatingsRepository ratingsRepository(RatingsRepositoryRef ref) =>
  RatingsRepository(Supabase.instance.client);

class RatingsRepository {
  final SupabaseClient _supabase;
  RatingsRepository(this._supabase);

  /// Odeslat hodnocení (INSERT nebo UPDATE při přehodnocení)
  Future<void> submitRating({
    required String poiId,
    required int rating,
    RatingReason? reason,
    required String langCode,
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    final deviceId = userId == null
      ? await _getOrCreateDeviceId()
      : null;

    await _supabase.from('poi_ratings').upsert({
      'poi_id':    poiId,
      'user_id':   userId,
      'device_id': deviceId,
      'rating':    rating,
      'reason':    reason?.name,
      'lang_code': langCode,
    }, onConflict: userId != null
      ? 'poi_id,user_id'
      : 'poi_id,device_id');
  }

  /// Načíst vlastní hodnocení daného POI (null = ještě nehodnotil)
  Future<PoiRating?> getMyRating(String poiId) async {
    final userId = _supabase.auth.currentUser?.id;
    final deviceId = userId == null ? await _getOrCreateDeviceId() : null;

    final query = _supabase.from('poi_ratings').select().eq('poi_id', poiId);
    final result = userId != null
      ? await query.eq('user_id', userId).maybeSingle()
      : await query.eq('device_id', deviceId!).maybeSingle();

    return result != null ? PoiRating.fromJson(result) : null;
  }

  Future<String> _getOrCreateDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    var id = prefs.getString('device_id');
    if (id == null) {
      id = const Uuid().v4();
      await prefs.setString('device_id', id);
    }
    return id;
  }
}
```

---

## D-015 – GoRouter – nové routes

```dart
// lib/app/router.dart – přidat:

GoRoute(
  path: '/hall-of-fame/:cityId',
  builder: (context, state) => HallOfFameScreen(
    cityId: state.pathParameters['cityId']!,
  ),
),
GoRoute(
  path: '/contributor/:userId',
  builder: (context, state) => ContributorProfileScreen(
    userId: state.pathParameters['userId']!,
  ),
),
```

---

## D-016 – Vstup do Hall of Fame z aplikace

```dart
// Přístupové body v UI:

// 1. MapScreen – ikona trofeje v AppBar (pokud je načteno město)
AppBar(
  actions: [
    if (currentCityId != null)
      IconButton(
        icon: const Icon(Icons.emoji_events_outlined),
        tooltip: 'Hall of Fame',
        onPressed: () => context.push('/hall-of-fame/$currentCityId'),
      ),
  ],
)

// 2. PoiDetailScreen – odkaz přes badge autora (viz D-011)
// onTap → context.push('/hall-of-fame/${poi.cityId}')

// 3. SettingsScreen – odkaz v sekci komunita
ListTile(
  leading: const Icon(Icons.emoji_events_outlined),
  title: const Text('Hall of Fame'),
  subtitle: const Text('Top průvodci v navštívených městech'),
  trailing: const Icon(Icons.chevron_right),
  onTap: () {
    // Otevřít HoF pro poslední navštívené město
    final lastCityId = ref.read(lastVisitedCityProvider);
    if (lastCityId != null) context.push('/hall-of-fame/$lastCityId');
  },
),
```

---

## D-017 – `SettingsScreen` – sekce přispěvatelský profil

```dart
// Přidat novou sekci do SettingsScreen (pokud je přihlášen):

Consumer(builder: (context, ref, _) {
  final profile = ref.watch(myContributorProfileProvider);
  return profile.when(
    loading: () => const SizedBox.shrink(),
    error: (_, __) => const SizedBox.shrink(),
    data: (p) => Column(children: [
      const _SectionHeader('PŘISPĚVATEL'),
      if (p == null)
        // Výzva k registraci jako přispěvatel
        ListTile(
          leading: const Icon(Icons.edit_note),
          title: const Text('Stát se průvodcem'),
          subtitle: const Text('Napište texty pro POI a získejte uznání'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => context.push('/contributor/register'),
        )
      else
        // Přispěvatelský profil
        ListTile(
          leading: CircleAvatar(
            backgroundImage: p.avatarUrl != null
              ? NetworkImage(p.avatarUrl!) : null,
            child: p.avatarUrl == null
              ? Text(p.displayName[0]) : null,
          ),
          title: Text(p.displayName),
          subtitle: Text(p.ratingLabel),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => context.push('/contributor/${p.userId}'),
        ),
    ]),
  );
}),
```

---

## D-018 – Drift lokální DB – tabulka `rated_pois`

```dart
// lib/data/local/tables/rated_pois_table.dart
// Lokální záznam hodnocení – aby se widget nezobrazoval znovu po restartu
// i pokud offline (Supabase cache nemusí být dostupná)

class RatedPoisTable extends Table {
  @override
  String get tableName => 'rated_pois';

  IntColumn get localId  => integer().autoIncrement()();
  TextColumn get poiId   => text()();
  IntColumn  get rating  => integer()();         // 1–5
  TextColumn get reason  => text().nullable()();
  DateTimeColumn get ratedAt => dateTime()();

  @override
  List<Set<Column>> get uniqueKeys => [{ poiId }];
}

// Přidat do AppDatabase:
// @DriftDatabase(tables: [..., RatedPoisTable])
```

---

## D-019 – Aktualizace roadmapy – nové kroky

```
Přidat za krok 13 (PoiDetailScreen):

13a | DB migrace 008_ratings_and_contributors.sql | Tabulky, triggery, pohled, RPC
13b | PoiRating + ContributorProfile + HallOfFameEntry modely | Freezed modely
13c | Rozšíření Poi modelu (contributorId, avgRating) | Model aktualizován
13d | RatingsRepository + myPoiRatingProvider | Submit + čtení hodnocení
13e | RatingWidget v PoiDetailScreen (timer + audio hook) | Hodnocení funguje
13f | Drift tabulka rated_pois (offline cache hodnocení) | Lokální cache
13g | D-011 – ContributorBadge v PoiDetailScreen AppBar | Badge autora
13h | HallOfFameScreen + PodiumWidget + HoFListTile | Obrazovka funguje
13i | hallOfFameProvider (RPC volání) | Data se načítají
13j | GoRouter routes /hall-of-fame/:cityId | Navigace funguje
13k | Vstupní body: MapScreen AppBar + SettingsScreen | HoF přístupný
13l | SettingsScreen – sekce přispěvatel + výzva k registraci | UI sekce
```

---

## Nové soubory k vytvoření

```
lib/domain/models/
├── poi_rating.dart
├── poi_rating.freezed.dart       (generovaný)
├── poi_rating.g.dart             (generovaný)
├── contributor_profile.dart
├── contributor_profile.freezed.dart  (generovaný)
└── contributor_profile.g.dart        (generovaný)

lib/data/repositories/
└── ratings_repository.dart

lib/data/local/tables/
└── rated_pois_table.dart

lib/features/poi_detail/widgets/
└── rating_widget.dart

lib/features/hall_of_fame/
├── hall_of_fame_screen.dart
└── hall_of_fame_provider.dart

supabase/migrations/
└── 008_ratings_and_contributors.sql
```

---

*Konec diff-specification-001.md*
*Následující diff: diff-specification-admin-001.md (administrace – správa přispěvatelů, HoF admin)*
