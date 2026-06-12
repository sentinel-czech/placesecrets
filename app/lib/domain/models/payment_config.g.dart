// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'payment_config.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$PaymentConfigImpl _$$PaymentConfigImplFromJson(Map<String, dynamic> json) =>
    _$PaymentConfigImpl(
      operatorName: json['operator_name'] as String,
      revolutUsername: json['revolut_username'] as String?,
      stripePublishableKey: json['stripe_publishable_key'] as String?,
      googlePayMerchantId: json['google_pay_merchant_id'] as String?,
      applePayMerchantId: json['apple_pay_merchant_id'] as String?,
    );

Map<String, dynamic> _$$PaymentConfigImplToJson(_$PaymentConfigImpl instance) =>
    <String, dynamic>{
      'operator_name': instance.operatorName,
      'revolut_username': instance.revolutUsername,
      'stripe_publishable_key': instance.stripePublishableKey,
      'google_pay_merchant_id': instance.googlePayMerchantId,
      'apple_pay_merchant_id': instance.applePayMerchantId,
    };
