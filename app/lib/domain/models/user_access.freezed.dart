// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'user_access.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

UserAccess _$UserAccessFromJson(Map<String, dynamic> json) {
  return _UserAccess.fromJson(json);
}

/// @nodoc
mixin _$UserAccess {
  String get id => throw _privateConstructorUsedError;
  @JsonKey(name: 'user_id')
  String get userId => throw _privateConstructorUsedError;
  @JsonKey(name: 'city_id')
  String get cityId => throw _privateConstructorUsedError;
  @JsonKey(name: 'purchased_at')
  DateTime get purchasedAt => throw _privateConstructorUsedError;
  @JsonKey(name: 'valid_until')
  DateTime? get validUntil => throw _privateConstructorUsedError;
  @JsonKey(name: 'payment_method')
  String get paymentMethod => throw _privateConstructorUsedError;
  @JsonKey(name: 'transaction_id')
  String? get transactionId => throw _privateConstructorUsedError;
  @JsonKey(name: 'amount_eur')
  double? get amountEur => throw _privateConstructorUsedError;

  /// Serializes this UserAccess to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of UserAccess
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $UserAccessCopyWith<UserAccess> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $UserAccessCopyWith<$Res> {
  factory $UserAccessCopyWith(
          UserAccess value, $Res Function(UserAccess) then) =
      _$UserAccessCopyWithImpl<$Res, UserAccess>;
  @useResult
  $Res call(
      {String id,
      @JsonKey(name: 'user_id') String userId,
      @JsonKey(name: 'city_id') String cityId,
      @JsonKey(name: 'purchased_at') DateTime purchasedAt,
      @JsonKey(name: 'valid_until') DateTime? validUntil,
      @JsonKey(name: 'payment_method') String paymentMethod,
      @JsonKey(name: 'transaction_id') String? transactionId,
      @JsonKey(name: 'amount_eur') double? amountEur});
}

/// @nodoc
class _$UserAccessCopyWithImpl<$Res, $Val extends UserAccess>
    implements $UserAccessCopyWith<$Res> {
  _$UserAccessCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of UserAccess
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? userId = null,
    Object? cityId = null,
    Object? purchasedAt = null,
    Object? validUntil = freezed,
    Object? paymentMethod = null,
    Object? transactionId = freezed,
    Object? amountEur = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      userId: null == userId
          ? _value.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String,
      cityId: null == cityId
          ? _value.cityId
          : cityId // ignore: cast_nullable_to_non_nullable
              as String,
      purchasedAt: null == purchasedAt
          ? _value.purchasedAt
          : purchasedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      validUntil: freezed == validUntil
          ? _value.validUntil
          : validUntil // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      paymentMethod: null == paymentMethod
          ? _value.paymentMethod
          : paymentMethod // ignore: cast_nullable_to_non_nullable
              as String,
      transactionId: freezed == transactionId
          ? _value.transactionId
          : transactionId // ignore: cast_nullable_to_non_nullable
              as String?,
      amountEur: freezed == amountEur
          ? _value.amountEur
          : amountEur // ignore: cast_nullable_to_non_nullable
              as double?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$UserAccessImplCopyWith<$Res>
    implements $UserAccessCopyWith<$Res> {
  factory _$$UserAccessImplCopyWith(
          _$UserAccessImpl value, $Res Function(_$UserAccessImpl) then) =
      __$$UserAccessImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      @JsonKey(name: 'user_id') String userId,
      @JsonKey(name: 'city_id') String cityId,
      @JsonKey(name: 'purchased_at') DateTime purchasedAt,
      @JsonKey(name: 'valid_until') DateTime? validUntil,
      @JsonKey(name: 'payment_method') String paymentMethod,
      @JsonKey(name: 'transaction_id') String? transactionId,
      @JsonKey(name: 'amount_eur') double? amountEur});
}

/// @nodoc
class __$$UserAccessImplCopyWithImpl<$Res>
    extends _$UserAccessCopyWithImpl<$Res, _$UserAccessImpl>
    implements _$$UserAccessImplCopyWith<$Res> {
  __$$UserAccessImplCopyWithImpl(
      _$UserAccessImpl _value, $Res Function(_$UserAccessImpl) _then)
      : super(_value, _then);

  /// Create a copy of UserAccess
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? userId = null,
    Object? cityId = null,
    Object? purchasedAt = null,
    Object? validUntil = freezed,
    Object? paymentMethod = null,
    Object? transactionId = freezed,
    Object? amountEur = freezed,
  }) {
    return _then(_$UserAccessImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      userId: null == userId
          ? _value.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String,
      cityId: null == cityId
          ? _value.cityId
          : cityId // ignore: cast_nullable_to_non_nullable
              as String,
      purchasedAt: null == purchasedAt
          ? _value.purchasedAt
          : purchasedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      validUntil: freezed == validUntil
          ? _value.validUntil
          : validUntil // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      paymentMethod: null == paymentMethod
          ? _value.paymentMethod
          : paymentMethod // ignore: cast_nullable_to_non_nullable
              as String,
      transactionId: freezed == transactionId
          ? _value.transactionId
          : transactionId // ignore: cast_nullable_to_non_nullable
              as String?,
      amountEur: freezed == amountEur
          ? _value.amountEur
          : amountEur // ignore: cast_nullable_to_non_nullable
              as double?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$UserAccessImpl implements _UserAccess {
  const _$UserAccessImpl(
      {required this.id,
      @JsonKey(name: 'user_id') required this.userId,
      @JsonKey(name: 'city_id') required this.cityId,
      @JsonKey(name: 'purchased_at') required this.purchasedAt,
      @JsonKey(name: 'valid_until') this.validUntil,
      @JsonKey(name: 'payment_method') required this.paymentMethod,
      @JsonKey(name: 'transaction_id') this.transactionId,
      @JsonKey(name: 'amount_eur') this.amountEur});

  factory _$UserAccessImpl.fromJson(Map<String, dynamic> json) =>
      _$$UserAccessImplFromJson(json);

  @override
  final String id;
  @override
  @JsonKey(name: 'user_id')
  final String userId;
  @override
  @JsonKey(name: 'city_id')
  final String cityId;
  @override
  @JsonKey(name: 'purchased_at')
  final DateTime purchasedAt;
  @override
  @JsonKey(name: 'valid_until')
  final DateTime? validUntil;
  @override
  @JsonKey(name: 'payment_method')
  final String paymentMethod;
  @override
  @JsonKey(name: 'transaction_id')
  final String? transactionId;
  @override
  @JsonKey(name: 'amount_eur')
  final double? amountEur;

  @override
  String toString() {
    return 'UserAccess(id: $id, userId: $userId, cityId: $cityId, purchasedAt: $purchasedAt, validUntil: $validUntil, paymentMethod: $paymentMethod, transactionId: $transactionId, amountEur: $amountEur)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$UserAccessImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.cityId, cityId) || other.cityId == cityId) &&
            (identical(other.purchasedAt, purchasedAt) ||
                other.purchasedAt == purchasedAt) &&
            (identical(other.validUntil, validUntil) ||
                other.validUntil == validUntil) &&
            (identical(other.paymentMethod, paymentMethod) ||
                other.paymentMethod == paymentMethod) &&
            (identical(other.transactionId, transactionId) ||
                other.transactionId == transactionId) &&
            (identical(other.amountEur, amountEur) ||
                other.amountEur == amountEur));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, id, userId, cityId, purchasedAt,
      validUntil, paymentMethod, transactionId, amountEur);

  /// Create a copy of UserAccess
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$UserAccessImplCopyWith<_$UserAccessImpl> get copyWith =>
      __$$UserAccessImplCopyWithImpl<_$UserAccessImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$UserAccessImplToJson(
      this,
    );
  }
}

abstract class _UserAccess implements UserAccess {
  const factory _UserAccess(
      {required final String id,
      @JsonKey(name: 'user_id') required final String userId,
      @JsonKey(name: 'city_id') required final String cityId,
      @JsonKey(name: 'purchased_at') required final DateTime purchasedAt,
      @JsonKey(name: 'valid_until') final DateTime? validUntil,
      @JsonKey(name: 'payment_method') required final String paymentMethod,
      @JsonKey(name: 'transaction_id') final String? transactionId,
      @JsonKey(name: 'amount_eur') final double? amountEur}) = _$UserAccessImpl;

  factory _UserAccess.fromJson(Map<String, dynamic> json) =
      _$UserAccessImpl.fromJson;

  @override
  String get id;
  @override
  @JsonKey(name: 'user_id')
  String get userId;
  @override
  @JsonKey(name: 'city_id')
  String get cityId;
  @override
  @JsonKey(name: 'purchased_at')
  DateTime get purchasedAt;
  @override
  @JsonKey(name: 'valid_until')
  DateTime? get validUntil;
  @override
  @JsonKey(name: 'payment_method')
  String get paymentMethod;
  @override
  @JsonKey(name: 'transaction_id')
  String? get transactionId;
  @override
  @JsonKey(name: 'amount_eur')
  double? get amountEur;

  /// Create a copy of UserAccess
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$UserAccessImplCopyWith<_$UserAccessImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
