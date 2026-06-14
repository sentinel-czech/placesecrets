import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../app/providers.dart';
import '../../../core/services/payment_service.dart';
import '../../../data/repositories/access_repository.dart';
import '../../../data/repositories/payment_config_repository.dart';
import '../../../data/repositories/payment_repository.dart';
import '../../../domain/models/payment_config.dart';
import '../../../domain/models/payment_receipt.dart';
import '../../../domain/models/user_access.dart';

part 'payment_providers.g.dart';

@Riverpod(keepAlive: true)
PaymentService paymentService(PaymentServiceRef ref) {
  return PaymentService(Supabase.instance.client);
}

@riverpod
Future<PaymentConfig?> paymentConfig(PaymentConfigRef ref) async {
  final repo = PaymentConfigRepository(Supabase.instance.client);
  return repo.fetchConfig();
}

@riverpod
Future<List<UserAccess>> userPurchases(UserPurchasesRef ref) async {
  final repo = AccessRepository(
    Supabase.instance.client,
    ref.watch(appDatabaseProvider),
  );
  return repo.getUserAccesses();
}

@riverpod
Future<List<PaymentReceipt>> userReceipts(UserReceiptsRef ref) async {
  return PaymentRepository(Supabase.instance.client).fetchReceipts();
}

@riverpod
Future<bool> hasCityAccess(HasCityAccessRef ref, String cityId) async {
  final repo = AccessRepository(
    Supabase.instance.client,
    ref.watch(appDatabaseProvider),
  );
  return repo.hasCityAccess(cityId);
}

@riverpod
class PaymentFlowState extends _$PaymentFlowState {
  @override
  PaymentState build() => const PaymentState();

  void startPayment(String cityId, PaymentMethod method) {
    state = PaymentState(
      cityId: cityId,
      method: method,
      status: PaymentStatus.processing,
    );
  }

  void setSuccess(String? transactionId) {
    state = state.copyWith(
      status: PaymentStatus.success,
      transactionId: transactionId,
    );
  }

  void setPending(String? transactionId) {
    state = state.copyWith(
      status: PaymentStatus.pending,
      transactionId: transactionId,
    );
  }

  void setError(String error) {
    state = state.copyWith(
      status: PaymentStatus.error,
      error: error,
    );
  }

  void reset() {
    state = const PaymentState();
  }
}

enum PaymentStatus { idle, processing, success, pending, error }

class PaymentState {
  final String? cityId;
  final PaymentMethod? method;
  final PaymentStatus status;
  final String? transactionId;
  final String? error;

  const PaymentState({
    this.cityId,
    this.method,
    this.status = PaymentStatus.idle,
    this.transactionId,
    this.error,
  });

  PaymentState copyWith({
    String? cityId,
    PaymentMethod? method,
    PaymentStatus? status,
    String? transactionId,
    String? error,
  }) =>
      PaymentState(
        cityId: cityId ?? this.cityId,
        method: method ?? this.method,
        status: status ?? this.status,
        transactionId: transactionId ?? this.transactionId,
        error: error ?? this.error,
      );
}
