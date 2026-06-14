import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/models/contributor_profile.dart';
import '../../domain/models/poi.dart';

/// Reads public contributor data. `contributor_profiles` has a public-read RLS
/// policy (migration 008), so a normal session can fetch it.
class ContributorRepository {
  final SupabaseClient _supabase;

  ContributorRepository(this._supabase);

  Future<ContributorProfile?> getProfile(String contributorId) async {
    final data = await _supabase
        .from('contributor_profiles')
        .select()
        .eq('id', contributorId)
        .maybeSingle();
    return data == null ? null : ContributorProfile.fromJson(data);
  }

  /// Active places authored by this contributor.
  Future<List<Poi>> getPois(String contributorId) async {
    final response = await _supabase
        .from('pois')
        .select('*, cities!inner(slug, name, country_code)')
        .eq('contributor_id', contributorId)
        .eq('is_active', true)
        .order('sort_order');
    final list = response as List? ?? [];
    return list.map((e) => Poi.fromJson(e as Map<String, dynamic>)).toList();
  }
}
