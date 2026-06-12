import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../data/repositories/ratings_repository.dart';
import '../../../domain/models/poi_rating.dart';

part 'ratings_provider.g.dart';

@riverpod
Future<PoiRating?> myPoiRating(MyPoiRatingRef ref, String poiId) async {
  return ref.read(ratingsRepositoryProvider).getMyRating(poiId);
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
