import 'package:drift/drift.dart';

@DataClassName('CachedPoi')
class CachedPoisTable extends Table {
  @override
  String get tableName => 'cached_pois';

  TextColumn get id => text()();
  TextColumn get cityId => text()();
  TextColumn get nameJson => text()();
  TextColumn get descriptionJson => text()();
  RealColumn get latitude => real()();
  RealColumn get longitude => real()();
  RealColumn get geofenceRadius => real()();
  TextColumn get photoUrlsJson => text()();
  TextColumn get audioUrlsJson => text()();
  BoolColumn get isPremium => boolean()();
  DateTimeColumn get cachedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
