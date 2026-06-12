import 'package:drift/drift.dart';

@DataClassName('PurchasedPoi')
class PurchasedPoisTable extends Table {
  @override
  String get tableName => 'purchased_pois';

  TextColumn get poiId => text()();
  TextColumn get stripeSessionId => text().nullable()();
  RealColumn get pricePaid => real()();
  DateTimeColumn get purchasedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {poiId};
}
