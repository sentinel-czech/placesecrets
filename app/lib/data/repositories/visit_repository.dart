import 'package:drift/drift.dart';

import '../local/app_database.dart';

class VisitRepository {
  final AppDatabase _db;

  VisitRepository(this._db);

  Stream<List<VisitedPoi>> watchAllVisits() => _db.watchAllVisits();

  Future<List<VisitedPoi>> getVisitsInRange(DateTime from, DateTime to) =>
      _db.getVisitsInRange(from, to);

  Future<VisitedPoi?> getVisitByPoiId(String poiId) =>
      _db.getVisitByPoiId(poiId);

  Future<void> recordVisit({
    required String poiId,
    required String cityId,
    required String poiName,
    required double latitude,
    required double longitude,
  }) async {
    await _db.upsertVisit(VisitedPoisTableCompanion(
      poiId: Value(poiId),
      cityId: Value(cityId),
      poiName: Value(poiName),
      latitude: Value(latitude),
      longitude: Value(longitude),
      visitedAt: Value(DateTime.now()),
    ));
  }

  Future<void> updateNote(int localId, String? note) =>
      _db.updateNote(localId, note);

  Future<void> updatePhoto(int localId, String? path) =>
      _db.updatePrivatePhoto(localId, path);

  Future<List<VisitedPoi>> searchVisits(String query) =>
      _db.searchVisits(query);
}
