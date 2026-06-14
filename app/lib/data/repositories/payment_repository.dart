import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/models/payment_receipt.dart';

class PaymentRepository {
  final SupabaseClient _supabase;

  PaymentRepository(this._supabase);

  /// Fetches the signed-in user's receipts (owner-read RLS, migration 003).
  /// Returns an empty list for anonymous/signed-out sessions.
  Future<List<PaymentReceipt>> fetchReceipts() async {
    final user = _supabase.auth.currentUser;
    if (user == null || user.isAnonymous) return [];
    final response = await _supabase
        .from('payment_receipts')
        .select()
        .eq('user_id', user.id)
        .order('purchased_at', ascending: false);
    final list = response as List? ?? [];
    return list
        .map((e) => PaymentReceipt.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Creates a Stripe Checkout session for POI or city premium bundle purchase.
  /// Returns the checkout URL to open in browser.
  Future<String> createPoiCheckout({
    required String purchaseType,
    String? poiId,
    String? cityId,
  }) async {
    final body = <String, dynamic>{
      'purchase_type': purchaseType,
    };
    if (poiId != null) body['poi_id'] = poiId;
    if (cityId != null) body['city_id'] = cityId;

    final response = await _supabase.functions.invoke(
      'create-poi-checkout',
      body: body,
    );

    final data = response.data as Map<String, dynamic>?;
    final url = data?['url'] as String?;
    if (url == null || url.isEmpty) {
      throw Exception(
          data?['error'] as String? ?? 'Failed to create checkout session');
    }
    return url;
  }
}
