import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/models/user_access.dart';
import '../local/app_database.dart';

class AccessRepository {
  final SupabaseClient _supabase;
  final AppDatabase _db;

  AccessRepository(this._supabase, this._db);

  Future<bool> hasCityAccess(String cityId) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return false;

    final response = await _supabase
        .from('user_access')
        .select()
        .eq('user_id', userId)
        .eq('city_id', cityId)
        .maybeSingle();

    if (response == null) return false;

    final access = UserAccess.fromJson(response);
    if (access.validUntil != null &&
        access.validUntil!.isBefore(DateTime.now())) {
      return false;
    }
    return true;
  }

  Future<bool> canUseFreeVisit() async {
    final now = DateTime.now();
    final yearMonth = '${now.year}-${now.month.toString().padLeft(2, '0')}';
    final count = await _db.countFreeVisitsThisMonth(yearMonth);
    return count < 1; // 1 free POI per month
  }

  Future<void> useFreeVisit(String poiId) async {
    await _db.addFreeVisit(poiId);
  }

  Future<bool> isPoiFreeVisited(String poiId) async {
    return _db.isPoiInFreeVisits(poiId);
  }

  Future<List<UserAccess>> getUserAccesses() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return [];

    try {
      final response = await _supabase
          .from('user_access')
          .select()
          .eq('user_id', userId);

      final list = response as List?;
      if (list == null) return [];
      return list
          .map((e) => UserAccess.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }
}
