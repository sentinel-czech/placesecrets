import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/models/city.dart';

class CityRepository {
  final SupabaseClient _supabase;

  CityRepository(this._supabase);

  Future<List<City>> fetchActiveCities() async {
    try {
      final response = await _supabase
          .from('cities')
          .select()
          .eq('is_active', true)
          .order('name');

      final list = response as List?;
      if (list == null) return [];
      return list.map((e) => City.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<City?> fetchCity(String id) async {
    final response = await _supabase
        .from('cities')
        .select()
        .eq('id', id)
        .maybeSingle();

    return response != null ? City.fromJson(response) : null;
  }
}
