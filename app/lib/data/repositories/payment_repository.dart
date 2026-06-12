import 'package:supabase_flutter/supabase_flutter.dart';

class PaymentRepository {
  final SupabaseClient _supabase;

  PaymentRepository(this._supabase);

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
