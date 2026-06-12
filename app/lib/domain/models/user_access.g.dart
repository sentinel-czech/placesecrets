// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_access.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$UserAccessImpl _$$UserAccessImplFromJson(Map<String, dynamic> json) =>
    _$UserAccessImpl(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      cityId: json['city_id'] as String,
      purchasedAt: DateTime.parse(json['purchased_at'] as String),
      validUntil: json['valid_until'] == null
          ? null
          : DateTime.parse(json['valid_until'] as String),
      paymentMethod: json['payment_method'] as String,
      transactionId: json['transaction_id'] as String?,
      amountEur: (json['amount_eur'] as num?)?.toDouble(),
    );

Map<String, dynamic> _$$UserAccessImplToJson(_$UserAccessImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'user_id': instance.userId,
      'city_id': instance.cityId,
      'purchased_at': instance.purchasedAt.toIso8601String(),
      'valid_until': instance.validUntil?.toIso8601String(),
      'payment_method': instance.paymentMethod,
      'transaction_id': instance.transactionId,
      'amount_eur': instance.amountEur,
    };
