import 'package:drift/drift.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../app/providers.dart';
import '../../domain/models/poi_rating.dart';
import '../local/app_database.dart';

part 'ratings_repository.g.dart';

@riverpod
RatingsRepository ratingsRepository(RatingsRepositoryRef ref) =>
    RatingsRepository(Supabase.instance.client, ref.watch(appDatabaseProvider));

/// Thrown when a rating is attempted without being signed in.
class RatingAuthRequiredException implements Exception {
  const RatingAuthRequiredException();
  @override
  String toString() => 'You must be signed in to rate.';
}

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

    // Ratings are only for logged-in users (one rating per user per place).
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      throw const RatingAuthRequiredException();
    }

    await _supabase.from('poi_ratings').upsert(
      {
        'poi_id': poiId,
        'user_id': userId,
        'rating': rating,
        'reason': ratingReasonToString(reason),
        'lang_code': langCode,
      },
      onConflict: 'poi_id,user_id',
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
    if (userId == null) return null;

    final result = await _supabase
        .from('poi_ratings')
        .select()
        .eq('poi_id', poiId)
        .eq('user_id', userId)
        .maybeSingle();

    return result != null ? PoiRating.fromJson(result) : null;
  }
}
