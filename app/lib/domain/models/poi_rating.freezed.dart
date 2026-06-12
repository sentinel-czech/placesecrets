// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'poi_rating.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

PoiRating _$PoiRatingFromJson(Map<String, dynamic> json) {
  return _PoiRating.fromJson(json);
}

/// @nodoc
mixin _$PoiRating {
  String get id => throw _privateConstructorUsedError;
  @JsonKey(name: 'poi_id')
  String get poiId => throw _privateConstructorUsedError;
  @JsonKey(name: 'user_id')
  String? get userId => throw _privateConstructorUsedError;
  @JsonKey(name: 'device_id')
  String? get deviceId => throw _privateConstructorUsedError;
  int get rating => throw _privateConstructorUsedError;
  RatingReason? get reason => throw _privateConstructorUsedError;
  @JsonKey(name: 'lang_code')
  String get langCode => throw _privateConstructorUsedError;
  @JsonKey(name: 'created_at')
  DateTime get createdAt => throw _privateConstructorUsedError;

  /// Serializes this PoiRating to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of PoiRating
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $PoiRatingCopyWith<PoiRating> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PoiRatingCopyWith<$Res> {
  factory $PoiRatingCopyWith(PoiRating value, $Res Function(PoiRating) then) =
      _$PoiRatingCopyWithImpl<$Res, PoiRating>;
  @useResult
  $Res call(
      {String id,
      @JsonKey(name: 'poi_id') String poiId,
      @JsonKey(name: 'user_id') String? userId,
      @JsonKey(name: 'device_id') String? deviceId,
      int rating,
      RatingReason? reason,
      @JsonKey(name: 'lang_code') String langCode,
      @JsonKey(name: 'created_at') DateTime createdAt});
}

/// @nodoc
class _$PoiRatingCopyWithImpl<$Res, $Val extends PoiRating>
    implements $PoiRatingCopyWith<$Res> {
  _$PoiRatingCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of PoiRating
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? poiId = null,
    Object? userId = freezed,
    Object? deviceId = freezed,
    Object? rating = null,
    Object? reason = freezed,
    Object? langCode = null,
    Object? createdAt = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      poiId: null == poiId
          ? _value.poiId
          : poiId // ignore: cast_nullable_to_non_nullable
              as String,
      userId: freezed == userId
          ? _value.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String?,
      deviceId: freezed == deviceId
          ? _value.deviceId
          : deviceId // ignore: cast_nullable_to_non_nullable
              as String?,
      rating: null == rating
          ? _value.rating
          : rating // ignore: cast_nullable_to_non_nullable
              as int,
      reason: freezed == reason
          ? _value.reason
          : reason // ignore: cast_nullable_to_non_nullable
              as RatingReason?,
      langCode: null == langCode
          ? _value.langCode
          : langCode // ignore: cast_nullable_to_non_nullable
              as String,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$PoiRatingImplCopyWith<$Res>
    implements $PoiRatingCopyWith<$Res> {
  factory _$$PoiRatingImplCopyWith(
          _$PoiRatingImpl value, $Res Function(_$PoiRatingImpl) then) =
      __$$PoiRatingImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      @JsonKey(name: 'poi_id') String poiId,
      @JsonKey(name: 'user_id') String? userId,
      @JsonKey(name: 'device_id') String? deviceId,
      int rating,
      RatingReason? reason,
      @JsonKey(name: 'lang_code') String langCode,
      @JsonKey(name: 'created_at') DateTime createdAt});
}

/// @nodoc
class __$$PoiRatingImplCopyWithImpl<$Res>
    extends _$PoiRatingCopyWithImpl<$Res, _$PoiRatingImpl>
    implements _$$PoiRatingImplCopyWith<$Res> {
  __$$PoiRatingImplCopyWithImpl(
      _$PoiRatingImpl _value, $Res Function(_$PoiRatingImpl) _then)
      : super(_value, _then);

  /// Create a copy of PoiRating
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? poiId = null,
    Object? userId = freezed,
    Object? deviceId = freezed,
    Object? rating = null,
    Object? reason = freezed,
    Object? langCode = null,
    Object? createdAt = null,
  }) {
    return _then(_$PoiRatingImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      poiId: null == poiId
          ? _value.poiId
          : poiId // ignore: cast_nullable_to_non_nullable
              as String,
      userId: freezed == userId
          ? _value.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String?,
      deviceId: freezed == deviceId
          ? _value.deviceId
          : deviceId // ignore: cast_nullable_to_non_nullable
              as String?,
      rating: null == rating
          ? _value.rating
          : rating // ignore: cast_nullable_to_non_nullable
              as int,
      reason: freezed == reason
          ? _value.reason
          : reason // ignore: cast_nullable_to_non_nullable
              as RatingReason?,
      langCode: null == langCode
          ? _value.langCode
          : langCode // ignore: cast_nullable_to_non_nullable
              as String,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$PoiRatingImpl implements _PoiRating {
  const _$PoiRatingImpl(
      {required this.id,
      @JsonKey(name: 'poi_id') required this.poiId,
      @JsonKey(name: 'user_id') this.userId,
      @JsonKey(name: 'device_id') this.deviceId,
      required this.rating,
      this.reason,
      @JsonKey(name: 'lang_code') required this.langCode,
      @JsonKey(name: 'created_at') required this.createdAt});

  factory _$PoiRatingImpl.fromJson(Map<String, dynamic> json) =>
      _$$PoiRatingImplFromJson(json);

  @override
  final String id;
  @override
  @JsonKey(name: 'poi_id')
  final String poiId;
  @override
  @JsonKey(name: 'user_id')
  final String? userId;
  @override
  @JsonKey(name: 'device_id')
  final String? deviceId;
  @override
  final int rating;
  @override
  final RatingReason? reason;
  @override
  @JsonKey(name: 'lang_code')
  final String langCode;
  @override
  @JsonKey(name: 'created_at')
  final DateTime createdAt;

  @override
  String toString() {
    return 'PoiRating(id: $id, poiId: $poiId, userId: $userId, deviceId: $deviceId, rating: $rating, reason: $reason, langCode: $langCode, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PoiRatingImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.poiId, poiId) || other.poiId == poiId) &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.deviceId, deviceId) ||
                other.deviceId == deviceId) &&
            (identical(other.rating, rating) || other.rating == rating) &&
            (identical(other.reason, reason) || other.reason == reason) &&
            (identical(other.langCode, langCode) ||
                other.langCode == langCode) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, id, poiId, userId, deviceId,
      rating, reason, langCode, createdAt);

  /// Create a copy of PoiRating
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PoiRatingImplCopyWith<_$PoiRatingImpl> get copyWith =>
      __$$PoiRatingImplCopyWithImpl<_$PoiRatingImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$PoiRatingImplToJson(
      this,
    );
  }
}

abstract class _PoiRating implements PoiRating {
  const factory _PoiRating(
          {required final String id,
          @JsonKey(name: 'poi_id') required final String poiId,
          @JsonKey(name: 'user_id') final String? userId,
          @JsonKey(name: 'device_id') final String? deviceId,
          required final int rating,
          final RatingReason? reason,
          @JsonKey(name: 'lang_code') required final String langCode,
          @JsonKey(name: 'created_at') required final DateTime createdAt}) =
      _$PoiRatingImpl;

  factory _PoiRating.fromJson(Map<String, dynamic> json) =
      _$PoiRatingImpl.fromJson;

  @override
  String get id;
  @override
  @JsonKey(name: 'poi_id')
  String get poiId;
  @override
  @JsonKey(name: 'user_id')
  String? get userId;
  @override
  @JsonKey(name: 'device_id')
  String? get deviceId;
  @override
  int get rating;
  @override
  RatingReason? get reason;
  @override
  @JsonKey(name: 'lang_code')
  String get langCode;
  @override
  @JsonKey(name: 'created_at')
  DateTime get createdAt;

  /// Create a copy of PoiRating
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PoiRatingImplCopyWith<_$PoiRatingImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
