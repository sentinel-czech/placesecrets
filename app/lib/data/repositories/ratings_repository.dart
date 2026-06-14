import 'package:drift/drift.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../app/providers.dart';
import '../../domain/models/poi_rating.dart';
import '../../domain/models/poi_review.dart';
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
    String? comment,
  }) async {
    assert(rating >= 1 && rating <= 5);

    // Ratings are only for logged-in users (one rating per user per place).
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      throw const RatingAuthRequiredException();
    }

    final trimmed = comment?.trim();
    await _supabase.from('poi_ratings').upsert(
      {
        'poi_id': poiId,
        'user_id': userId,
        'rating': rating,
        'reason': ratingReasonToString(reason),
        'lang_code': langCode,
        'comment': (trimmed == null || trimmed.isEmpty) ? null : trimmed,
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

  /// Fetches a page of reviews (ratings with a comment) for a place via the
  /// `get_poi_reviews` RPC. The current user's own review is sorted first.
  Future<List<PoiReview>> getReviews(
    String poiId, {
    int limit = 10,
    int offset = 0,
  }) async {
    final response = await _supabase.rpc('get_poi_reviews', params: {
      'p_poi_id': poiId,
      'p_limit': limit,
      'p_offset': offset,
      'p_user_id': _supabase.auth.currentUser?.id,
    });
    final list = response as List? ?? [];
    return list
        .map((e) => PoiReview.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
