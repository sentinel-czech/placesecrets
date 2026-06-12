import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../app/providers.dart';
import '../../../data/local/app_database.dart';
import '../../../data/repositories/visit_repository.dart';

part 'history_providers.g.dart';

@riverpod
VisitRepository visitRepository(VisitRepositoryRef ref) {
  return VisitRepository(ref.watch(appDatabaseProvider));
}

@riverpod
Stream<List<VisitedPoi>> visitHistory(VisitHistoryRef ref) {
  final repo = ref.watch(visitRepositoryProvider);
  return repo.watchAllVisits();
}

@riverpod
Future<TravelStats> travelStats(TravelStatsRef ref) async {
  final db = ref.watch(appDatabaseProvider);
  final visits = await db.select(db.visitedPoisTable).get();

  final cityIds = visits.map((v) => v.cityId).toSet();
  final withNotes = visits.where((v) => v.userNote != null && v.userNote!.isNotEmpty);
  final withPhotos = visits.where((v) => v.userPhotoPath != null && v.userPhotoPath!.isNotEmpty);

  return TravelStats(
    totalVisits: visits.length,
    citiesExplored: cityIds.length,
    notesWritten: withNotes.length,
    photosTaken: withPhotos.length,
    firstVisit: visits.isNotEmpty
        ? visits.map((v) => v.visitedAt).reduce((a, b) => a.isBefore(b) ? a : b)
        : null,
    lastVisit: visits.isNotEmpty
        ? visits.map((v) => v.visitedAt).reduce((a, b) => a.isAfter(b) ? a : b)
        : null,
  );
}

class TravelStats {
  final int totalVisits;
  final int citiesExplored;
  final int notesWritten;
  final int photosTaken;
  final DateTime? firstVisit;
  final DateTime? lastVisit;

  const TravelStats({
    this.totalVisits = 0,
    this.citiesExplored = 0,
    this.notesWritten = 0,
    this.photosTaken = 0,
    this.firstVisit,
    this.lastVisit,
  });
}
