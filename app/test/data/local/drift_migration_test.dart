import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:herodots/data/local/app_database.dart';

void main() {
  group('AppDatabase schema', () {
    test('schema version is 5', () {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      expect(db.schemaVersion, 5);
      db.close();
    });

    test('all tables are created on fresh database', () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());

      // Verify purchased POIs table works
      final pois = await db.getAllPurchasedPois();
      expect(pois, isEmpty);

      // Verify purchased city bundles table works
      final bundles = await db.getAllPurchasedCityBundles();
      expect(bundles, isEmpty);

      // Verify cached POIs table works
      final cached = await db.getAllCachedPois();
      expect(cached, isEmpty);

      // Verify visited POIs table works (stream)
      final visits = await db.watchAllVisits().first;
      expect(visits, isEmpty);

      await db.close();
    });

    test('purchased_pois table has expected columns', () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());

      // Insert a row to verify all columns exist
      await db.upsertPurchasedPoi(PurchasedPoisTableCompanion(
        poiId: const Value('test-poi'),
        pricePaid: const Value(4.99),
        purchasedAt: Value(DateTime(2025, 6, 1)),
        stripeSessionId: const Value('cs_test123'),
      ));

      final rows = await db.getAllPurchasedPois();
      expect(rows.length, 1);
      expect(rows.first.poiId, 'test-poi');
      expect(rows.first.pricePaid, 4.99);
      expect(rows.first.stripeSessionId, 'cs_test123');

      await db.close();
    });

    test('purchased_city_bundles table has expected columns', () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());

      await db.upsertPurchasedCityBundle(PurchasedCityBundlesTableCompanion(
        cityId: const Value('test-city'),
        pricePaid: const Value(9.99),
        purchasedAt: Value(DateTime(2025, 6, 1)),
        stripeSessionId: const Value('cs_city123'),
      ));

      final rows = await db.getAllPurchasedCityBundles();
      expect(rows.length, 1);
      expect(rows.first.cityId, 'test-city');
      expect(rows.first.pricePaid, 9.99);
      expect(rows.first.stripeSessionId, 'cs_city123');

      await db.close();
    });

    test('rated_pois table has langCode column (v3 migration)', () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());

      await db.upsertLocalRating(RatedPoisTableCompanion(
        poiId: const Value('poi-1'),
        rating: const Value(5),
        ratedAt: Value(DateTime.now()),
        langCode: const Value('cs'),
      ));

      final rating = await db.getLocalRating('poi-1');
      expect(rating, isNotNull);
      expect(rating!.langCode, 'cs');

      await db.close();
    });
  });
}
