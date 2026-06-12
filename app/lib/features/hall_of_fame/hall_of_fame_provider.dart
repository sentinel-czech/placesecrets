import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/models/contributor_profile.dart';

part 'hall_of_fame_provider.g.dart';

@riverpod
Future<List<HallOfFameEntry>> hallOfFame(
  HallOfFameRef ref,
  String cityId,
) async {
  final data = await Supabase.instance.client
      .rpc('poi_hall_of_fame', params: {'p_city_id': cityId, 'p_limit': 10});
  return (data as List? ?? [])
      .map((e) => HallOfFameEntry.fromJson(e as Map<String, dynamic>))
      .toList();
}
