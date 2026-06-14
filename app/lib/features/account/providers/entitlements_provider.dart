import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

part 'entitlements_provider.g.dart';

/// Calls the `get_my_entitlements()` RPC (migration 0448) returning the unified
/// "what do I own" payload: free quota, purchased POIs, cities, city bundles and
/// countries. Returns an empty map for anonymous/signed-out users.
@riverpod
Future<Map<String, dynamic>> myEntitlements(MyEntitlementsRef ref) async {
  final user = Supabase.instance.client.auth.currentUser;
  if (user == null || user.isAnonymous) return {};
  final data = await Supabase.instance.client.rpc('get_my_entitlements');
  if (data is Map<String, dynamic>) return data;
  if (data is Map) return Map<String, dynamic>.from(data);
  return {};
}
