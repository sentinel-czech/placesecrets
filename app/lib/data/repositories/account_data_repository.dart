import 'package:supabase_flutter/supabase_flutter.dart';

/// GDPR self-service: export the user's own data and delete the account.
class AccountDataRepository {
  final SupabaseClient _supabase;

  AccountDataRepository(this._supabase);

  /// Collects the signed-in user's own rows (RLS restricts each query to the
  /// caller) into a single JSON-serializable map for export.
  Future<Map<String, dynamic>> exportData() async {
    final uid = _supabase.auth.currentUser?.id;
    if (uid == null) return {};

    Future<dynamic> own(String table) async {
      try {
        return await _supabase.from(table).select().eq('user_id', uid);
      } catch (_) {
        return <dynamic>[];
      }
    }

    Map<String, dynamic>? profile;
    try {
      profile = await _supabase
          .from('user_profiles')
          .select()
          .eq('user_id', uid)
          .maybeSingle();
    } catch (_) {
      profile = null;
    }

    return {
      'exported_at': DateTime.now().toUtc().toIso8601String(),
      'user_id': uid,
      'email': _supabase.auth.currentUser?.email,
      'profile': profile,
      'city_access': await own('user_access'),
      'poi_purchases': await own('user_poi_purchases'),
      'city_bundles': await own('user_city_premium_purchases'),
      'country_purchases': await own('user_country_purchases'),
      'receipts': await own('payment_receipts'),
      'ratings': await own('poi_ratings'),
    };
  }

  /// Permanently deletes the account via the `delete-user-data` edge function
  /// (the function authenticates the caller from the JWT and cascades the wipe).
  Future<void> deleteAccount() async {
    final res = await _supabase.functions.invoke('delete-user-data');
    if (res.status != 200) {
      throw Exception('Account deletion failed (status ${res.status})');
    }
  }
}
