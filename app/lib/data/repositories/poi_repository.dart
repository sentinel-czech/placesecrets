import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/models/poi.dart';
import '../../domain/models/poi_premium_content.dart';
import '../local/app_database.dart';

class PoiRepository {
  final SupabaseClient _supabase;
  final AppDatabase _db;

  PoiRepository(this._supabase, this._db);

  Future<List<Poi>> fetchPoisForCity(String cityId) async {
    try {
      final response = await _supabase
          .from('pois')
          .select('*, cities!inner(slug, name, country_code)')
          .eq('city_id', cityId)
          .eq('is_active', true)
          .order('sort_order');

      final list = response as List? ?? [];
      final pois =
          list.map((e) => Poi.fromJson(e as Map<String, dynamic>)).toList();

      // Cache locally
      for (final poi in pois) {
        await _db.upsertCachedPoi(CachedPoisTableCompanion(
          id: Value(poi.id),
          cityId: Value(poi.cityId),
          nameJson: Value(jsonEncode(poi.name)),
          descriptionJson: Value(jsonEncode(poi.description)),
          latitude: Value(poi.latitude),
          longitude: Value(poi.longitude),
          geofenceRadius: Value(poi.geofenceRadius),
          photoUrlsJson: Value(jsonEncode(poi.photoUrls)),
          audioUrlsJson: Value(jsonEncode(poi.audioUrls)),
          isPremium: Value(poi.isPremium),
          cachedAt: Value(DateTime.now()),
        ));
      }

      return pois;
    } catch (_) {
      // Offline fallback: load from cache
      return _getCachedPois(cityId);
    }
  }

  Future<List<Poi>> _getCachedPois(String cityId) async {
    final cached = await _db.getAllCachedPois();
    return cached
        .where((c) => c.cityId == cityId)
        .map((c) => Poi(
              id: c.id,
              cityId: c.cityId,
              name: Map<String, String>.from(jsonDecode(c.nameJson)),
              description:
                  Map<String, String>.from(jsonDecode(c.descriptionJson)),
              latitude: c.latitude,
              longitude: c.longitude,
              geofenceRadius: c.geofenceRadius,
              photoUrls: List<String>.from(jsonDecode(c.photoUrlsJson)),
              audioUrls:
                  Map<String, String?>.from(jsonDecode(c.audioUrlsJson)),
              isPremium: c.isPremium,
              createdAt: c.cachedAt,
            ))
        .toList();
  }

  /// Calls the `get_poi_access` RPC to determine effective access level
  Future<String> getPoiAccess(String poiId) async {
    final response = await _supabase.rpc(
      'get_poi_access',
      params: {'p_poi_id': poiId},
    );
    return response as String? ?? 'none';
  }

  /// Fetches premium content for a POI
  Future<PoiPremiumContent?> getPremiumContent(String poiId) async {
    final response = await _supabase
        .from('poi_premium_content')
        .select()
        .eq('poi_id', poiId)
        .maybeSingle();

    if (response == null) return null;
    return PoiPremiumContent.fromJson(response);
  }

  /// Resolves a POI by country code + city slug + poi slug
  Future<Map<String, dynamic>?> getPoiBySlug(
      String countryCode, String citySlug, String poiSlug) async {
    final response = await _supabase.rpc(
      'get_poi_by_slug',
      params: {
        'p_country_code': countryCode,
        'p_city_slug': citySlug,
        'p_poi_slug': poiSlug,
      },
    );
    if (response is Map<String, dynamic>) return response;
    return null;
  }

  /// Gets the set of POI IDs purchased by the current user
  Future<Set<String>> getUserPurchasedPoiIds() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return {};

    final response = await _supabase
        .from('user_poi_purchases')
        .select('poi_id')
        .eq('user_id', userId);

    final list = response as List? ?? [];
    return list.map((e) => e['poi_id'] as String).toSet();
  }

  /// Gets the set of city IDs for premium bundle purchases
  Future<Set<String>> getUserPurchasedCityBundleIds() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return {};

    final response = await _supabase
        .from('user_city_premium_purchases')
        .select('city_id')
        .eq('user_id', userId);

    final list = response as List? ?? [];
    return list.map((e) => e['city_id'] as String).toSet();
  }

  /// Syncs remote purchases to local Drift DB
  Future<void> syncPurchasesToLocal() async {
    final poiIds = await getUserPurchasedPoiIds();
    for (final poiId in poiIds) {
      await _db.upsertPurchasedPoi(PurchasedPoisTableCompanion(
        poiId: Value(poiId),
        pricePaid: const Value(0),
        purchasedAt: Value(DateTime.now()),
      ));
    }

    final cityIds = await getUserPurchasedCityBundleIds();
    for (final cityId in cityIds) {
      await _db.upsertPurchasedCityBundle(PurchasedCityBundlesTableCompanion(
        cityId: Value(cityId),
        pricePaid: const Value(0),
        purchasedAt: Value(DateTime.now()),
      ));
    }
  }

  /// Offline access check for a POI
  Future<String> getPoiAccessOffline(String poiId, String cityId,
      String accessLevel) async {
    // Check local purchases
    if (accessLevel == 'public') return 'full';
    if (accessLevel == 'registered_limited') return 'registered';

    if (accessLevel == 'premium_poi') {
      final poiPurchased = await _db.isPoiPurchased(poiId);
      if (poiPurchased) return 'full';
      final bundlePurchased = await _db.isCityBundlePurchased(cityId);
      if (bundlePurchased) return 'full';
    }

    // city_access — check free visits or existing access
    return 'city_access';
  }
}
