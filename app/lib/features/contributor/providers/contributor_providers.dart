import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../data/repositories/contributor_repository.dart';
import '../../../domain/models/contributor_profile.dart';
import '../../../domain/models/poi.dart';

part 'contributor_providers.g.dart';

@riverpod
ContributorRepository contributorRepository(ContributorRepositoryRef ref) =>
    ContributorRepository(Supabase.instance.client);

@riverpod
Future<ContributorProfile?> contributorProfile(
  ContributorProfileRef ref,
  String contributorId,
) async {
  return ref.watch(contributorRepositoryProvider).getProfile(contributorId);
}

@riverpod
Future<List<Poi>> contributorPois(
  ContributorPoisRef ref,
  String contributorId,
) async {
  return ref.watch(contributorRepositoryProvider).getPois(contributorId);
}
