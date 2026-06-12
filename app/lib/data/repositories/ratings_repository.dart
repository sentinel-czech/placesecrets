import 'package:drift/drift.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../app/providers.dart';
import '../../core/services/device_service.dart';
import '../../domain/models/poi_rating.dart';
import '../local/app_database.dart';

part 'ratings_repository.g.dart';

@riverpod
RatingsRepository ratingsRepository(RatingsRepositoryRef ref) =>
    RatingsRepository(Supabase.instance.client, ref.watch(appDatabaseProvider));

class RatingsRepository {
  final SupabaseClient _supabase;
  final AppDatabase _db;
  RatingsRepository(this._supabase, this._db);

  Future<void> submitRating({
    required String poiId,
    required int rating,
    RatingReason? reason,
    required String langCode,
  }) async {
    assert(rating >= 1 && rating <= 5);

    final userId = _supabase.auth.currentUser?.id;
    final deviceId = userId == null ? await DeviceService.getOrCreateDeviceId() : null;

    await _supabase.from('poi_ratings').upsert(
      {
        'poi_id': poiId,
        'user_id': userId,
        'device_id': deviceId,
        'rating': rating,
        'reason': ratingReasonToString(reason),
        'lang_code': langCode,
      },
      onConflict: userId != null ? 'poi_id,user_id' : 'poi_id,device_id',
    );

    await _db.upsertLocalRating(RatedPoisTableCompanion(
      poiId: Value(poiId),
      rating: Value(rating),
      reason: Value(ratingReasonToString(reason)),
      langCode: Value(langCode),
      ratedAt: Value(DateTime.now()),
    ));
  }

  Future<PoiRating?> getMyRating(String poiId) async {
    // Check local DB first (offline support)
    final local = await _db.getLocalRating(poiId);
    if (local != null) {
      return PoiRating(
        id: 'local-${local.localId}',
        poiId: local.poiId,
        rating: local.rating,
        reason: ratingReasonFromString(local.reason),
        langCode: local.langCode,
        createdAt: local.ratedAt,
      );
    }

    final userId = _supabase.auth.currentUser?.id;
    final deviceId = userId == null ? await DeviceService.getOrCreateDeviceId() : null;

    final query = _supabase.from('poi_ratings').select().eq('poi_id', poiId);
    final result = userId != null
        ? await query.eq('user_id', userId).maybeSingle()
        : await query.eq('device_id', deviceId!).maybeSingle();

    return result != null ? PoiRating.fromJson(result) : null;
  }
}
