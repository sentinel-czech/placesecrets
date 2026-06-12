import 'package:drift/drift.dart';

@DataClassName('RatedPoi')
class RatedPoisTable extends Table {
  @override
  String get tableName => 'rated_pois';

  IntColumn get localId => integer().autoIncrement()();
  TextColumn get poiId => text()();
  IntColumn get rating => integer()();
  TextColumn get reason => text().nullable()();
  TextColumn get langCode => text().withDefault(const Constant('cs'))();
  DateTimeColumn get ratedAt => dateTime()();

  @override
  List<Set<Column>> get uniqueKeys => [
        {poiId}
      ];
}
