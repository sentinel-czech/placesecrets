import 'package:drift/drift.dart';

@DataClassName('CachedAudioGuide')
class CachedAudioGuidesTable extends Table {
  @override
  String get tableName => 'cached_audio_guides';

  TextColumn get id => text()();
  TextColumn get poiId => text()();
  TextColumn get langCode => text()();
  TextColumn get title => text().withDefault(const Constant(''))();
  TextColumn get url => text()();
  IntColumn get durationSec => integer().nullable()();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  DateTimeColumn get cachedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}
