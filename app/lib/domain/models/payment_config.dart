import 'package:freezed_annotation/freezed_annotation.dart';

part 'payment_config.freezed.dart';
part 'payment_config.g.dart';

@freezed
class PaymentConfig with _$PaymentConfig {
  const factory PaymentConfig({
    @JsonKey(name: 'operator_name') required String operatorName,
    @JsonKey(name: 'revolut_username') String? revolutUsername,
    @JsonKey(name: 'stripe_publishable_key') String? stripePublishableKey,
    @JsonKey(name: 'google_pay_merchant_id') String? googlePayMerchantId,
    @JsonKey(name: 'apple_pay_merchant_id') String? applePayMerchantId,
  }) = _PaymentConfig;

  factory PaymentConfig.fromJson(Map<String, dynamic> json) =>
      _$PaymentConfigFromJson(json);
}
