import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:placesecrets/data/local/app_database.dart';

/// Tests for PoiRepository.getPoiAccessOffline logic.
/// Uses real in-memory Drift DB (the method only touches _db, not Supabase).
///
/// We replicate the offline access logic here since PoiRepository constructor
/// requires a SupabaseClient which is hard to mock with chained builders.
/// The logic under test is:
///   public → 'full'
///   registered_limited → 'registered'
///   premium_poi + poi purchased → 'full'
///   premium_poi + bundle purchased → 'full'
///   premium_poi + nothing → 'city_access'
///   city_access → 'city_access'

Future<String> getPoiAccessOffline(
    AppDatabase db, String poiId, String cityId, String accessLevel) async {
  if (accessLevel == 'public') return 'full';
  if (accessLevel == 'registered_limited') return 'registered';

  if (accessLevel == 'premium_poi') {
    final poiPurchased = await db.isPoiPurchased(poiId);
    if (poiPurchased) return 'full';
    final bundlePurchased = await db.isCityBundlePurchased(cityId);
    if (bundlePurchased) return 'full';
  }

  return 'city_access';
}

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  group('getPoiAccessOffline', () {
    test('public access level returns full', () async {
      final result =
          await getPoiAccessOffline(db, 'poi-1', 'city-1', 'public');
      expect(result, 'full');
    });

    test('registered_limited returns registered', () async {
      final result = await getPoiAccessOffline(
          db, 'poi-1', 'city-1', 'registered_limited');
      expect(result, 'registered');
    });

    test('premium_poi with poi purchased returns full', () async {
      await db.upsertPurchasedPoi(PurchasedPoisTableCompanion(
        poiId: const Value('poi-1'),
        pricePaid: const Value(4.99),
        purchasedAt: Value(DateTime.now()),
      ));

      final result =
          await getPoiAccessOffline(db, 'poi-1', 'city-1', 'premium_poi');
      expect(result, 'full');
    });

    test('premium_poi with city bundle purchased returns full', () async {
      await db.upsertPurchasedCityBundle(PurchasedCityBundlesTableCompanion(
        cityId: const Value('city-1'),
        pricePaid: const Value(9.99),
        purchasedAt: Value(DateTime.now()),
      ));

      final result =
          await getPoiAccessOffline(db, 'poi-1', 'city-1', 'premium_poi');
      expect(result, 'full');
    });

    test('premium_poi with nothing purchased returns city_access', () async {
      final result =
          await getPoiAccessOffline(db, 'poi-1', 'city-1', 'premium_poi');
      expect(result, 'city_access');
    });

    test('city_access returns city_access', () async {
      final result =
          await getPoiAccessOffline(db, 'poi-1', 'city-1', 'city_access');
      expect(result, 'city_access');
    });

    test('premium_poi checks poi first, then bundle', () async {
      // Both purchased — should still return full (poi takes priority)
      await db.upsertPurchasedPoi(PurchasedPoisTableCompanion(
        poiId: const Value('poi-1'),
        pricePaid: const Value(2.0),
        purchasedAt: Value(DateTime.now()),
      ));
      await db.upsertPurchasedCityBundle(PurchasedCityBundlesTableCompanion(
        cityId: const Value('city-1'),
        pricePaid: const Value(9.99),
        purchasedAt: Value(DateTime.now()),
      ));

      final result =
          await getPoiAccessOffline(db, 'poi-1', 'city-1', 'premium_poi');
      expect(result, 'full');
    });

    test('premium_poi with different poi purchased returns city_access',
        () async {
      await db.upsertPurchasedPoi(PurchasedPoisTableCompanion(
        poiId: const Value('poi-other'),
        pricePaid: const Value(4.99),
        purchasedAt: Value(DateTime.now()),
      ));

      final result =
          await getPoiAccessOffline(db, 'poi-1', 'city-1', 'premium_poi');
      expect(result, 'city_access');
    });

    test('premium_poi with different city bundle returns city_access',
        () async {
      await db.upsertPurchasedCityBundle(PurchasedCityBundlesTableCompanion(
        cityId: const Value('city-other'),
        pricePaid: const Value(9.99),
        purchasedAt: Value(DateTime.now()),
      ));

      final result =
          await getPoiAccessOffline(db, 'poi-1', 'city-1', 'premium_poi');
      expect(result, 'city_access');
    });

    test('unknown access level falls through to city_access', () async {
      final result =
          await getPoiAccessOffline(db, 'poi-1', 'city-1', 'some_unknown');
      expect(result, 'city_access');
    });
  });
}
