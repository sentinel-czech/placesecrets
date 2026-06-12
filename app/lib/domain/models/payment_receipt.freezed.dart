// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'payment_receipt.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

PaymentReceipt _$PaymentReceiptFromJson(Map<String, dynamic> json) {
  return _PaymentReceipt.fromJson(json);
}

/// @nodoc
mixin _$PaymentReceipt {
  String get id => throw _privateConstructorUsedError;
  @JsonKey(name: 'user_id')
  String get userId => throw _privateConstructorUsedError;
  @JsonKey(name: 'city_id')
  String get cityId => throw _privateConstructorUsedError;
  @JsonKey(name: 'purchased_at')
  DateTime get purchasedAt => throw _privateConstructorUsedError;
  @JsonKey(name: 'payment_method')
  String get paymentMethod => throw _privateConstructorUsedError;
  @JsonKey(name: 'transaction_id')
  String? get transactionId => throw _privateConstructorUsedError;
  @JsonKey(name: 'amount_eur')
  double get amountEur => throw _privateConstructorUsedError;
  String get currency => throw _privateConstructorUsedError;
  String get status => throw _privateConstructorUsedError;
  @JsonKey(name: 'receipt_number')
  String? get receiptNumber => throw _privateConstructorUsedError;
  @JsonKey(name: 'receipt_pdf_url')
  String? get receiptPdfUrl => throw _privateConstructorUsedError;
  @JsonKey(name: 'receipt_sent_at')
  DateTime? get receiptSentAt => throw _privateConstructorUsedError;
  @JsonKey(name: 'created_at')
  DateTime get createdAt => throw _privateConstructorUsedError;

  /// Serializes this PaymentReceipt to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of PaymentReceipt
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $PaymentReceiptCopyWith<PaymentReceipt> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PaymentReceiptCopyWith<$Res> {
  factory $PaymentReceiptCopyWith(
          PaymentReceipt value, $Res Function(PaymentReceipt) then) =
      _$PaymentReceiptCopyWithImpl<$Res, PaymentReceipt>;
  @useResult
  $Res call(
      {String id,
      @JsonKey(name: 'user_id') String userId,
      @JsonKey(name: 'city_id') String cityId,
      @JsonKey(name: 'purchased_at') DateTime purchasedAt,
      @JsonKey(name: 'payment_method') String paymentMethod,
      @JsonKey(name: 'transaction_id') String? transactionId,
      @JsonKey(name: 'amount_eur') double amountEur,
      String currency,
      String status,
      @JsonKey(name: 'receipt_number') String? receiptNumber,
      @JsonKey(name: 'receipt_pdf_url') String? receiptPdfUrl,
      @JsonKey(name: 'receipt_sent_at') DateTime? receiptSentAt,
      @JsonKey(name: 'created_at') DateTime createdAt});
}

/// @nodoc
class _$PaymentReceiptCopyWithImpl<$Res, $Val extends PaymentReceipt>
    implements $PaymentReceiptCopyWith<$Res> {
  _$PaymentReceiptCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of PaymentReceipt
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? userId = null,
    Object? cityId = null,
    Object? purchasedAt = null,
    Object? paymentMethod = null,
    Object? transactionId = freezed,
    Object? amountEur = null,
    Object? currency = null,
    Object? status = null,
    Object? receiptNumber = freezed,
    Object? receiptPdfUrl = freezed,
    Object? receiptSentAt = freezed,
    Object? createdAt = null,
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
      paymentMethod: null == paymentMethod
          ? _value.paymentMethod
          : paymentMethod // ignore: cast_nullable_to_non_nullable
              as String,
      transactionId: freezed == transactionId
          ? _value.transactionId
          : transactionId // ignore: cast_nullable_to_non_nullable
              as String?,
      amountEur: null == amountEur
          ? _value.amountEur
          : amountEur // ignore: cast_nullable_to_non_nullable
              as double,
      currency: null == currency
          ? _value.currency
          : currency // ignore: cast_nullable_to_non_nullable
              as String,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as String,
      receiptNumber: freezed == receiptNumber
          ? _value.receiptNumber
          : receiptNumber // ignore: cast_nullable_to_non_nullable
              as String?,
      receiptPdfUrl: freezed == receiptPdfUrl
          ? _value.receiptPdfUrl
          : receiptPdfUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      receiptSentAt: freezed == receiptSentAt
          ? _value.receiptSentAt
          : receiptSentAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$PaymentReceiptImplCopyWith<$Res>
    implements $PaymentReceiptCopyWith<$Res> {
  factory _$$PaymentReceiptImplCopyWith(_$PaymentReceiptImpl value,
          $Res Function(_$PaymentReceiptImpl) then) =
      __$$PaymentReceiptImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      @JsonKey(name: 'user_id') String userId,
      @JsonKey(name: 'city_id') String cityId,
      @JsonKey(name: 'purchased_at') DateTime purchasedAt,
      @JsonKey(name: 'payment_method') String paymentMethod,
      @JsonKey(name: 'transaction_id') String? transactionId,
      @JsonKey(name: 'amount_eur') double amountEur,
      String currency,
      String status,
      @JsonKey(name: 'receipt_number') String? receiptNumber,
      @JsonKey(name: 'receipt_pdf_url') String? receiptPdfUrl,
      @JsonKey(name: 'receipt_sent_at') DateTime? receiptSentAt,
      @JsonKey(name: 'created_at') DateTime createdAt});
}

/// @nodoc
class __$$PaymentReceiptImplCopyWithImpl<$Res>
    extends _$PaymentReceiptCopyWithImpl<$Res, _$PaymentReceiptImpl>
    implements _$$PaymentReceiptImplCopyWith<$Res> {
  __$$PaymentReceiptImplCopyWithImpl(
      _$PaymentReceiptImpl _value, $Res Function(_$PaymentReceiptImpl) _then)
      : super(_value, _then);

  /// Create a copy of PaymentReceipt
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? userId = null,
    Object? cityId = null,
    Object? purchasedAt = null,
    Object? paymentMethod = null,
    Object? transactionId = freezed,
    Object? amountEur = null,
    Object? currency = null,
    Object? status = null,
    Object? receiptNumber = freezed,
    Object? receiptPdfUrl = freezed,
    Object? receiptSentAt = freezed,
    Object? createdAt = null,
  }) {
    return _then(_$PaymentReceiptImpl(
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
      paymentMethod: null == paymentMethod
          ? _value.paymentMethod
          : paymentMethod // ignore: cast_nullable_to_non_nullable
              as String,
      transactionId: freezed == transactionId
          ? _value.transactionId
          : transactionId // ignore: cast_nullable_to_non_nullable
              as String?,
      amountEur: null == amountEur
          ? _value.amountEur
          : amountEur // ignore: cast_nullable_to_non_nullable
              as double,
      currency: null == currency
          ? _value.currency
          : currency // ignore: cast_nullable_to_non_nullable
              as String,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as String,
      receiptNumber: freezed == receiptNumber
          ? _value.receiptNumber
          : receiptNumber // ignore: cast_nullable_to_non_nullable
              as String?,
      receiptPdfUrl: freezed == receiptPdfUrl
          ? _value.receiptPdfUrl
          : receiptPdfUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      receiptSentAt: freezed == receiptSentAt
          ? _value.receiptSentAt
          : receiptSentAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$PaymentReceiptImpl implements _PaymentReceipt {
  const _$PaymentReceiptImpl(
      {required this.id,
      @JsonKey(name: 'user_id') required this.userId,
      @JsonKey(name: 'city_id') required this.cityId,
      @JsonKey(name: 'purchased_at') required this.purchasedAt,
      @JsonKey(name: 'payment_method') required this.paymentMethod,
      @JsonKey(name: 'transaction_id') this.transactionId,
      @JsonKey(name: 'amount_eur') required this.amountEur,
      this.currency = 'EUR',
      this.status = 'completed',
      @JsonKey(name: 'receipt_number') this.receiptNumber,
      @JsonKey(name: 'receipt_pdf_url') this.receiptPdfUrl,
      @JsonKey(name: 'receipt_sent_at') this.receiptSentAt,
      @JsonKey(name: 'created_at') required this.createdAt});

  factory _$PaymentReceiptImpl.fromJson(Map<String, dynamic> json) =>
      _$$PaymentReceiptImplFromJson(json);

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
  @JsonKey(name: 'payment_method')
  final String paymentMethod;
  @override
  @JsonKey(name: 'transaction_id')
  final String? transactionId;
  @override
  @JsonKey(name: 'amount_eur')
  final double amountEur;
  @override
  @JsonKey()
  final String currency;
  @override
  @JsonKey()
  final String status;
  @override
  @JsonKey(name: 'receipt_number')
  final String? receiptNumber;
  @override
  @JsonKey(name: 'receipt_pdf_url')
  final String? receiptPdfUrl;
  @override
  @JsonKey(name: 'receipt_sent_at')
  final DateTime? receiptSentAt;
  @override
  @JsonKey(name: 'created_at')
  final DateTime createdAt;

  @override
  String toString() {
    return 'PaymentReceipt(id: $id, userId: $userId, cityId: $cityId, purchasedAt: $purchasedAt, paymentMethod: $paymentMethod, transactionId: $transactionId, amountEur: $amountEur, currency: $currency, status: $status, receiptNumber: $receiptNumber, receiptPdfUrl: $receiptPdfUrl, receiptSentAt: $receiptSentAt, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PaymentReceiptImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.cityId, cityId) || other.cityId == cityId) &&
            (identical(other.purchasedAt, purchasedAt) ||
                other.purchasedAt == purchasedAt) &&
            (identical(other.paymentMethod, paymentMethod) ||
                other.paymentMethod == paymentMethod) &&
            (identical(other.transactionId, transactionId) ||
                other.transactionId == transactionId) &&
            (identical(other.amountEur, amountEur) ||
                other.amountEur == amountEur) &&
            (identical(other.currency, currency) ||
                other.currency == currency) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.receiptNumber, receiptNumber) ||
                other.receiptNumber == receiptNumber) &&
            (identical(other.receiptPdfUrl, receiptPdfUrl) ||
                other.receiptPdfUrl == receiptPdfUrl) &&
            (identical(other.receiptSentAt, receiptSentAt) ||
                other.receiptSentAt == receiptSentAt) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      userId,
      cityId,
      purchasedAt,
      paymentMethod,
      transactionId,
      amountEur,
      currency,
      status,
      receiptNumber,
      receiptPdfUrl,
      receiptSentAt,
      createdAt);

  /// Create a copy of PaymentReceipt
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PaymentReceiptImplCopyWith<_$PaymentReceiptImpl> get copyWith =>
      __$$PaymentReceiptImplCopyWithImpl<_$PaymentReceiptImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$PaymentReceiptImplToJson(
      this,
    );
  }
}

abstract class _PaymentReceipt implements PaymentReceipt {
  const factory _PaymentReceipt(
          {required final String id,
          @JsonKey(name: 'user_id') required final String userId,
          @JsonKey(name: 'city_id') required final String cityId,
          @JsonKey(name: 'purchased_at') required final DateTime purchasedAt,
          @JsonKey(name: 'payment_method') required final String paymentMethod,
          @JsonKey(name: 'transaction_id') final String? transactionId,
          @JsonKey(name: 'amount_eur') required final double amountEur,
          final String currency,
          final String status,
          @JsonKey(name: 'receipt_number') final String? receiptNumber,
          @JsonKey(name: 'receipt_pdf_url') final String? receiptPdfUrl,
          @JsonKey(name: 'receipt_sent_at') final DateTime? receiptSentAt,
          @JsonKey(name: 'created_at') required final DateTime createdAt}) =
      _$PaymentReceiptImpl;

  factory _PaymentReceipt.fromJson(Map<String, dynamic> json) =
      _$PaymentReceiptImpl.fromJson;

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
  @JsonKey(name: 'payment_method')
  String get paymentMethod;
  @override
  @JsonKey(name: 'transaction_id')
  String? get transactionId;
  @override
  @JsonKey(name: 'amount_eur')
  double get amountEur;
  @override
  String get currency;
  @override
  String get status;
  @override
  @JsonKey(name: 'receipt_number')
  String? get receiptNumber;
  @override
  @JsonKey(name: 'receipt_pdf_url')
  String? get receiptPdfUrl;
  @override
  @JsonKey(name: 'receipt_sent_at')
  DateTime? get receiptSentAt;
  @override
  @JsonKey(name: 'created_at')
  DateTime get createdAt;

  /// Create a copy of PaymentReceipt
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PaymentReceiptImplCopyWith<_$PaymentReceiptImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
