import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:drift/drift.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/local/app_database.dart';
import 'device_service.dart';

class SyncService {
  final SupabaseClient _supabase;
  final AppDatabase _db;
  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;
  bool _syncing = false;

  SyncService(this._supabase, this._db);

  void startListening() {
    _connectivitySub = _connectivity.onConnectivityChanged.listen((results) {
      if (results.any((r) => r != ConnectivityResult.none)) {
        syncAll();
      }
    });
  }

  void stopListening() {
    _connectivitySub?.cancel();
    _connectivitySub = null;
  }

  Future<void> syncAll() async {
    if (_syncing) return;
    _syncing = true;
    try {
      await _pushLocalRatings();
      await _pullCityPois();
    } finally {
      _syncing = false;
    }
  }

  Future<void> _pushLocalRatings() async {
    final userId = _supabase.auth.currentUser?.id;
    final deviceId =
        userId == null ? await DeviceService.getOrCreateDeviceId() : null;

    final localRatings = await _db.select(_db.ratedPoisTable).get();
    for (final rating in localRatings) {
      try {
        await _supabase.from('poi_ratings').upsert(
          {
            'poi_id': rating.poiId,
            'user_id': userId,
            'device_id': deviceId,
            'rating': rating.rating,
            'reason': rating.reason,
            'lang_code': rating.langCode,
          },
          onConflict: userId != null ? 'poi_id,user_id' : 'poi_id,device_id',
        );
      } catch (_) {
        // Will retry on next sync
      }
    }
  }

  Future<void> _pullCityPois() async {
    try {
      final response = await _supabase
          .from('pois')
          .select()
          .eq('is_active', true);

      final list = response as List? ?? [];
      for (final item in list) {
        final data = item as Map<String, dynamic>;
        await _db.upsertCachedPoi(CachedPoisTableCompanion(
          id: Value(data['id'] as String),
          cityId: Value(data['city_id'] as String),
          nameJson: Value(_encodeJson(data['name'])),
          descriptionJson: Value(_encodeJson(data['description'])),
          latitude: Value((data['latitude'] as num).toDouble()),
          longitude: Value((data['longitude'] as num).toDouble()),
          geofenceRadius:
              Value((data['geofence_radius'] as num?)?.toDouble() ?? 100.0),
          photoUrlsJson: Value(_encodeJson(data['photo_urls'] ?? [])),
          audioUrlsJson: Value(_encodeJson(data['audio_urls'] ?? {})),
          isPremium: Value(data['is_premium'] as bool? ?? true),
          cachedAt: Value(DateTime.now()),
        ));
      }
    } catch (_) {
      // Offline — skip
    }
  }

  String _encodeJson(dynamic value) {
    if (value is String) return value;
    return value.toString();
  }

  void dispose() {
    stopListening();
  }
}
