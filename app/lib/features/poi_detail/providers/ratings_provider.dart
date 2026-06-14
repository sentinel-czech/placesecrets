import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../data/repositories/ratings_repository.dart';
import '../../../domain/models/poi_rating.dart';
import '../../../domain/models/poi_review.dart';

part 'ratings_provider.g.dart';

/// Whether the current session may submit a rating: signed in with a real
/// (non-anonymous) account. The app keeps a persistent anonymous session, so
/// `currentUser != null` is not enough — anonymous users must be excluded.
@riverpod
bool canSubmitRating(CanSubmitRatingRef ref) {
  final user = Supabase.instance.client.auth.currentUser;
  return user != null && !user.isAnonymous;
}

@riverpod
Future<PoiRating?> myPoiRating(MyPoiRatingRef ref, String poiId) async {
  return ref.read(ratingsRepositoryProvider).getMyRating(poiId);
}

/// First page of reviews for a place. Additional pages are loaded by the
/// reviews widget directly via the repository; invalidate this to refresh.
@riverpod
Future<List<PoiReview>> poiReviews(PoiReviewsRef ref, String poiId) async {
  return ref.read(ratingsRepositoryProvider).getReviews(poiId);
}

@riverpod
Future<({double? avg, int count})> poiRatingStats(
  PoiRatingStatsRef ref,
  String poiId,
) async {
  final data = await Supabase.instance.client
      .from('pois')
      .select('avg_rating, total_ratings')
      .eq('id', poiId)
      .maybeSingle();
  if (data == null) return (avg: null, count: 0);
  return (
    avg: (data['avg_rating'] as num?)?.toDouble(),
    count: (data['total_ratings'] as num?)?.toInt() ?? 0,
  );
}
