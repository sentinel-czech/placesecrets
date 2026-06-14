import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../data/repositories/search_repository.dart';
import '../../../domain/models/place_summary.dart';

part 'search_providers.g.dart';

@riverpod
SearchRepository searchRepository(SearchRepositoryRef ref) =>
    SearchRepository(Supabase.instance.client);

/// Results for [query]. A blank query returns the featured top-rated places.
@riverpod
Future<List<PlaceSummary>> searchResults(
  SearchResultsRef ref,
  String query,
) async {
  return ref.watch(searchRepositoryProvider).search(query);
}
