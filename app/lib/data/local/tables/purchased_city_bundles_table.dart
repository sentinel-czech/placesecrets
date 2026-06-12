import 'package:drift/drift.dart';

@DataClassName('PurchasedCityBundle')
class PurchasedCityBundlesTable extends Table {
  @override
  String get tableName => 'purchased_city_bundles';

  TextColumn get cityId => text()();
  TextColumn get stripeSessionId => text().nullable()();
  RealColumn get pricePaid => real()();
  DateTimeColumn get purchasedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {cityId};
}
