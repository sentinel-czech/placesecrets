import 'package:drift/drift.dart';

class FreeVisitsTable extends Table {
  @override
  String get tableName => 'free_visits';

  IntColumn get id => integer().autoIncrement()();
  TextColumn get poiId => text()();
  TextColumn get yearMonth => text()();
  DateTimeColumn get visitedAt => dateTime()();
}
