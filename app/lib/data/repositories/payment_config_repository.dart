import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/models/payment_config.dart';

class PaymentConfigRepository {
  final SupabaseClient _supabase;

  PaymentConfigRepository(this._supabase);

  Future<PaymentConfig?> fetchConfig() async {
    try {
      final response = await _supabase.rpc('get_publishable_payment_config');
      final list = response as List?;
      if (list == null || list.isEmpty) return null;
      return PaymentConfig.fromJson(list.first as Map<String, dynamic>);
    } catch (e) {
      return null;
    }
  }
}
