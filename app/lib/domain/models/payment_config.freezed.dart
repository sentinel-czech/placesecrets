// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'payment_config.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

PaymentConfig _$PaymentConfigFromJson(Map<String, dynamic> json) {
  return _PaymentConfig.fromJson(json);
}

/// @nodoc
mixin _$PaymentConfig {
  @JsonKey(name: 'operator_name')
  String get operatorName => throw _privateConstructorUsedError;
  @JsonKey(name: 'revolut_username')
  String? get revolutUsername => throw _privateConstructorUsedError;
  @JsonKey(name: 'stripe_publishable_key')
  String? get stripePublishableKey => throw _privateConstructorUsedError;
  @JsonKey(name: 'google_pay_merchant_id')
  String? get googlePayMerchantId => throw _privateConstructorUsedError;
  @JsonKey(name: 'apple_pay_merchant_id')
  String? get applePayMerchantId => throw _privateConstructorUsedError;

  /// Serializes this PaymentConfig to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of PaymentConfig
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $PaymentConfigCopyWith<PaymentConfig> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PaymentConfigCopyWith<$Res> {
  factory $PaymentConfigCopyWith(
          PaymentConfig value, $Res Function(PaymentConfig) then) =
      _$PaymentConfigCopyWithImpl<$Res, PaymentConfig>;
  @useResult
  $Res call(
      {@JsonKey(name: 'operator_name') String operatorName,
      @JsonKey(name: 'revolut_username') String? revolutUsername,
      @JsonKey(name: 'stripe_publishable_key') String? stripePublishableKey,
      @JsonKey(name: 'google_pay_merchant_id') String? googlePayMerchantId,
      @JsonKey(name: 'apple_pay_merchant_id') String? applePayMerchantId});
}

/// @nodoc
class _$PaymentConfigCopyWithImpl<$Res, $Val extends PaymentConfig>
    implements $PaymentConfigCopyWith<$Res> {
  _$PaymentConfigCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of PaymentConfig
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? operatorName = null,
    Object? revolutUsername = freezed,
    Object? stripePublishableKey = freezed,
    Object? googlePayMerchantId = freezed,
    Object? applePayMerchantId = freezed,
  }) {
    return _then(_value.copyWith(
      operatorName: null == operatorName
          ? _value.operatorName
          : operatorName // ignore: cast_nullable_to_non_nullable
              as String,
      revolutUsername: freezed == revolutUsername
          ? _value.revolutUsername
          : revolutUsername // ignore: cast_nullable_to_non_nullable
              as String?,
      stripePublishableKey: freezed == stripePublishableKey
          ? _value.stripePublishableKey
          : stripePublishableKey // ignore: cast_nullable_to_non_nullable
              as String?,
      googlePayMerchantId: freezed == googlePayMerchantId
          ? _value.googlePayMerchantId
          : googlePayMerchantId // ignore: cast_nullable_to_non_nullable
              as String?,
      applePayMerchantId: freezed == applePayMerchantId
          ? _value.applePayMerchantId
          : applePayMerchantId // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$PaymentConfigImplCopyWith<$Res>
    implements $PaymentConfigCopyWith<$Res> {
  factory _$$PaymentConfigImplCopyWith(
          _$PaymentConfigImpl value, $Res Function(_$PaymentConfigImpl) then) =
      __$$PaymentConfigImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {@JsonKey(name: 'operator_name') String operatorName,
      @JsonKey(name: 'revolut_username') String? revolutUsername,
      @JsonKey(name: 'stripe_publishable_key') String? stripePublishableKey,
      @JsonKey(name: 'google_pay_merchant_id') String? googlePayMerchantId,
      @JsonKey(name: 'apple_pay_merchant_id') String? applePayMerchantId});
}

/// @nodoc
class __$$PaymentConfigImplCopyWithImpl<$Res>
    extends _$PaymentConfigCopyWithImpl<$Res, _$PaymentConfigImpl>
    implements _$$PaymentConfigImplCopyWith<$Res> {
  __$$PaymentConfigImplCopyWithImpl(
      _$PaymentConfigImpl _value, $Res Function(_$PaymentConfigImpl) _then)
      : super(_value, _then);

  /// Create a copy of PaymentConfig
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? operatorName = null,
    Object? revolutUsername = freezed,
    Object? stripePublishableKey = freezed,
    Object? googlePayMerchantId = freezed,
    Object? applePayMerchantId = freezed,
  }) {
    return _then(_$PaymentConfigImpl(
      operatorName: null == operatorName
          ? _value.operatorName
          : operatorName // ignore: cast_nullable_to_non_nullable
              as String,
      revolutUsername: freezed == revolutUsername
          ? _value.revolutUsername
          : revolutUsername // ignore: cast_nullable_to_non_nullable
              as String?,
      stripePublishableKey: freezed == stripePublishableKey
          ? _value.stripePublishableKey
          : stripePublishableKey // ignore: cast_nullable_to_non_nullable
              as String?,
      googlePayMerchantId: freezed == googlePayMerchantId
          ? _value.googlePayMerchantId
          : googlePayMerchantId // ignore: cast_nullable_to_non_nullable
              as String?,
      applePayMerchantId: freezed == applePayMerchantId
          ? _value.applePayMerchantId
          : applePayMerchantId // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$PaymentConfigImpl implements _PaymentConfig {
  const _$PaymentConfigImpl(
      {@JsonKey(name: 'operator_name') required this.operatorName,
      @JsonKey(name: 'revolut_username') this.revolutUsername,
      @JsonKey(name: 'stripe_publishable_key') this.stripePublishableKey,
      @JsonKey(name: 'google_pay_merchant_id') this.googlePayMerchantId,
      @JsonKey(name: 'apple_pay_merchant_id') this.applePayMerchantId});

  factory _$PaymentConfigImpl.fromJson(Map<String, dynamic> json) =>
      _$$PaymentConfigImplFromJson(json);

  @override
  @JsonKey(name: 'operator_name')
  final String operatorName;
  @override
  @JsonKey(name: 'revolut_username')
  final String? revolutUsername;
  @override
  @JsonKey(name: 'stripe_publishable_key')
  final String? stripePublishableKey;
  @override
  @JsonKey(name: 'google_pay_merchant_id')
  final String? googlePayMerchantId;
  @override
  @JsonKey(name: 'apple_pay_merchant_id')
  final String? applePayMerchantId;

  @override
  String toString() {
    return 'PaymentConfig(operatorName: $operatorName, revolutUsername: $revolutUsername, stripePublishableKey: $stripePublishableKey, googlePayMerchantId: $googlePayMerchantId, applePayMerchantId: $applePayMerchantId)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PaymentConfigImpl &&
            (identical(other.operatorName, operatorName) ||
                other.operatorName == operatorName) &&
            (identical(other.revolutUsername, revolutUsername) ||
                other.revolutUsername == revolutUsername) &&
            (identical(other.stripePublishableKey, stripePublishableKey) ||
                other.stripePublishableKey == stripePublishableKey) &&
            (identical(other.googlePayMerchantId, googlePayMerchantId) ||
                other.googlePayMerchantId == googlePayMerchantId) &&
            (identical(other.applePayMerchantId, applePayMerchantId) ||
                other.applePayMerchantId == applePayMerchantId));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, operatorName, revolutUsername,
      stripePublishableKey, googlePayMerchantId, applePayMerchantId);

  /// Create a copy of PaymentConfig
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PaymentConfigImplCopyWith<_$PaymentConfigImpl> get copyWith =>
      __$$PaymentConfigImplCopyWithImpl<_$PaymentConfigImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$PaymentConfigImplToJson(
      this,
    );
  }
}

abstract class _PaymentConfig implements PaymentConfig {
  const factory _PaymentConfig(
      {@JsonKey(name: 'operator_name') required final String operatorName,
      @JsonKey(name: 'revolut_username') final String? revolutUsername,
      @JsonKey(name: 'stripe_publishable_key')
      final String? stripePublishableKey,
      @JsonKey(name: 'google_pay_merchant_id')
      final String? googlePayMerchantId,
      @JsonKey(name: 'apple_pay_merchant_id')
      final String? applePayMerchantId}) = _$PaymentConfigImpl;

  factory _PaymentConfig.fromJson(Map<String, dynamic> json) =
      _$PaymentConfigImpl.fromJson;

  @override
  @JsonKey(name: 'operator_name')
  String get operatorName;
  @override
  @JsonKey(name: 'revolut_username')
  String? get revolutUsername;
  @override
  @JsonKey(name: 'stripe_publishable_key')
  String? get stripePublishableKey;
  @override
  @JsonKey(name: 'google_pay_merchant_id')
  String? get googlePayMerchantId;
  @override
  @JsonKey(name: 'apple_pay_merchant_id')
  String? get applePayMerchantId;

  /// Create a copy of PaymentConfig
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PaymentConfigImplCopyWith<_$PaymentConfigImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
