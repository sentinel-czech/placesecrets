import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../app/providers.dart';
import '../../../data/repositories/poi_repository.dart';
import '../../../domain/models/poi_premium_content.dart';

part 'poi_access_provider.g.dart';

/// Returns the effective access level string for a POI (from server RPC)
@riverpod
Future<String> poiAccess(PoiAccessRef ref, String poiId) async {
  final repo = PoiRepository(
    Supabase.instance.client,
    ref.watch(appDatabaseProvider),
  );
  return repo.getPoiAccess(poiId);
}

/// Fetches premium content for a POI
@riverpod
Future<PoiPremiumContent?> premiumContent(
    PremiumContentRef ref, String poiId) async {
  final repo = PoiRepository(
    Supabase.instance.client,
    ref.watch(appDatabaseProvider),
  );
  return repo.getPremiumContent(poiId);
}

/// Set of POI IDs the user has purchased individually
@riverpod
Future<Set<String>> purchasedPoiIds(PurchasedPoiIdsRef ref) async {
  final repo = PoiRepository(
    Supabase.instance.client,
    ref.watch(appDatabaseProvider),
  );
  return repo.getUserPurchasedPoiIds();
}

/// Set of city IDs for which the user has a premium bundle
@riverpod
Future<Set<String>> purchasedCityBundleIds(
    PurchasedCityBundleIdsRef ref) async {
  final repo = PoiRepository(
    Supabase.instance.client,
    ref.watch(appDatabaseProvider),
  );
  return repo.getUserPurchasedCityBundleIds();
}
