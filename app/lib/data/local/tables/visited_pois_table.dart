import 'package:drift/drift.dart';

@DataClassName('VisitedPoi')
class VisitedPoisTable extends Table {
  @override
  String get tableName => 'visited_pois';

  IntColumn get localId => integer().autoIncrement()();
  TextColumn get poiId => text()();
  TextColumn get cityId => text()();
  TextColumn get poiName => text()();
  RealColumn get latitude => real()();
  RealColumn get longitude => real()();
  DateTimeColumn get visitedAt => dateTime()();
  TextColumn get userNote => text().nullable()();
  TextColumn get userPhotoPath => text().nullable()();
  BoolColumn get isSynced =>
      boolean().withDefault(const Constant(false))();
  BoolColumn get exportedToPdf =>
      boolean().withDefault(const Constant(false))();
}
