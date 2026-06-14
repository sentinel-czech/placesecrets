import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/models/place_summary.dart';

/// Wraps the `search_pois` SECURITY DEFINER RPC (see migration 0445).
///
/// * empty/blank query -> top active places by rating (featured)
/// * non-empty query   -> ILIKE over name / aliases / perex / city name
class SearchRepository {
  final SupabaseClient _supabase;

  SearchRepository(this._supabase);

  Future<List<PlaceSummary>> search(String query, {int limit = 30}) async {
    try {
      final response = await _supabase.rpc(
        'search_pois',
        params: {
          'p_query': query.trim().isEmpty ? null : query.trim(),
          'p_limit': limit,
        },
      );
      final list = response as List? ?? [];
      return list
          .map((e) => PlaceSummary.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }
}
