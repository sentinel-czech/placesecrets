import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import 'tables/visited_pois_table.dart';
import 'tables/cached_pois_table.dart';
import 'tables/free_visits_table.dart';
import 'tables/rated_pois_table.dart';
import 'tables/purchased_pois_table.dart';
import 'tables/purchased_city_bundles_table.dart';
import 'tables/cached_audio_guides_table.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [
  VisitedPoisTable,
  CachedPoisTable,
  FreeVisitsTable,
  RatedPoisTable,
  PurchasedPoisTable,
  PurchasedCityBundlesTable,
  CachedAudioGuidesTable,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  /// Test-only constructor that accepts a custom [QueryExecutor]
  /// (e.g. `NativeDatabase.memory()` for in-memory SQLite).
  AppDatabase.forTesting(super.e);

  @override
  int get schemaVersion => 5;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) => m.createAll(),
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            await m.createTable(ratedPoisTable);
          }
          if (from < 3) {
            await m.addColumn(ratedPoisTable, ratedPoisTable.langCode);
          }
          if (from < 4) {
            await m.createTable(purchasedPoisTable);
            await m.createTable(purchasedCityBundlesTable);
          }
          if (from < 5) {
            await m.createTable(cachedAudioGuidesTable);
          }
        },
      );

  static QueryExecutor _openConnection() {
    return driftDatabase(name: 'herodots_local_db');
  }

  // ---- VisitedPois queries ----
  Future<List<VisitedPoi>> getVisitsInRange(DateTime from, DateTime to) =>
      (select(visitedPoisTable)
            ..where((t) => t.visitedAt.isBetweenValues(from, to))
            ..orderBy([(t) => OrderingTerm.asc(t.visitedAt)]))
          .get();

  Stream<List<VisitedPoi>> watchAllVisits() =>
      (select(visitedPoisTable)
            ..orderBy([(t) => OrderingTerm.desc(t.visitedAt)]))
          .watch();

  Future<VisitedPoi?> getVisitByPoiId(String poiId) =>
      (select(visitedPoisTable)
            ..where((t) => t.poiId.equals(poiId))
            ..limit(1))
          .getSingleOrNull();

  Future<int> upsertVisit(VisitedPoisTableCompanion visit) =>
      into(visitedPoisTable).insertOnConflictUpdate(visit);

  Future<void> updateNote(int localId, String? note) =>
      (update(visitedPoisTable)
            ..where((t) => t.localId.equals(localId)))
          .write(VisitedPoisTableCompanion(userNote: Value(note)));

  Future<void> updatePrivatePhoto(int localId, String? path) =>
      (update(visitedPoisTable)
            ..where((t) => t.localId.equals(localId)))
          .write(VisitedPoisTableCompanion(userPhotoPath: Value(path)));

  Future<List<VisitedPoi>> searchVisits(String query) {
    // Escape LIKE special characters to prevent SQL injection
    final escaped = query
        .replaceAll('\\', '\\\\')
        .replaceAll('%', '\\%')
        .replaceAll('_', '\\_');
    return (select(visitedPoisTable)
          ..where((t) =>
              t.poiName.like('%$escaped%') | t.userNote.like('%$escaped%'))
          ..orderBy([(t) => OrderingTerm.desc(t.visitedAt)]))
        .get();
  }

  // ---- CachedPois queries ----
  Future<List<CachedPoi>> getAllCachedPois() =>
      select(cachedPoisTable).get();

  Future<void> upsertCachedPoi(CachedPoisTableCompanion poi) =>
      into(cachedPoisTable).insertOnConflictUpdate(poi);

  Future<void> clearCache() => delete(cachedPoisTable).go();

  // ---- RatedPois queries ----
  Future<RatedPoi?> getLocalRating(String poiId) =>
      (select(ratedPoisTable)
            ..where((t) => t.poiId.equals(poiId))
            ..limit(1))
          .getSingleOrNull();

  Future<void> upsertLocalRating(RatedPoisTableCompanion row) =>
      into(ratedPoisTable).insertOnConflictUpdate(row);

  // ---- Free visit tracking ----
  Future<int> countFreeVisitsThisMonth(String yearMonth) async {
    final rows = await (select(freeVisitsTable)
          ..where((t) => t.yearMonth.equals(yearMonth)))
        .get();
    return rows.length;
  }

  Future<void> addFreeVisit(String poiId) async {
    final now = DateTime.now();
    final yearMonth = '${now.year}-${now.month.toString().padLeft(2, '0')}';
    await into(freeVisitsTable).insert(FreeVisitsTableCompanion(
      poiId: Value(poiId),
      yearMonth: Value(yearMonth),
      visitedAt: Value(now),
    ));
  }

  Future<bool> isPoiInFreeVisits(String poiId) async {
    final row = await (select(freeVisitsTable)
          ..where((t) => t.poiId.equals(poiId))
          ..limit(1))
        .getSingleOrNull();
    return row != null;
  }

  // ---- PurchasedPois queries ----
  Future<List<PurchasedPoi>> getAllPurchasedPois() =>
      select(purchasedPoisTable).get();

  Future<void> upsertPurchasedPoi(PurchasedPoisTableCompanion row) =>
      into(purchasedPoisTable).insertOnConflictUpdate(row);

  Future<bool> isPoiPurchased(String poiId) async {
    final row = await (select(purchasedPoisTable)
          ..where((t) => t.poiId.equals(poiId))
          ..limit(1))
        .getSingleOrNull();
    return row != null;
  }

  // ---- CachedAudioGuides queries ----
  Future<List<CachedAudioGuide>> getAudioGuidesForPoi(String poiId) =>
      (select(cachedAudioGuidesTable)
            ..where((t) => t.poiId.equals(poiId))
            ..orderBy([
              (t) => OrderingTerm.asc(t.langCode),
              (t) => OrderingTerm.asc(t.sortOrder),
            ]))
          .get();

  Future<void> upsertAudioGuide(CachedAudioGuidesTableCompanion row) =>
      into(cachedAudioGuidesTable).insertOnConflictUpdate(row);

  Future<void> clearAudioGuidesForPoi(String poiId) =>
      (delete(cachedAudioGuidesTable)
            ..where((t) => t.poiId.equals(poiId)))
          .go();

  // ---- PurchasedCityBundles queries ----
  Future<List<PurchasedCityBundle>> getAllPurchasedCityBundles() =>
      select(purchasedCityBundlesTable).get();

  Future<void> upsertPurchasedCityBundle(
          PurchasedCityBundlesTableCompanion row) =>
      into(purchasedCityBundlesTable).insertOnConflictUpdate(row);

  Future<bool> isCityBundlePurchased(String cityId) async {
    final row = await (select(purchasedCityBundlesTable)
          ..where((t) => t.cityId.equals(cityId))
          ..limit(1))
        .getSingleOrNull();
    return row != null;
  }
}
