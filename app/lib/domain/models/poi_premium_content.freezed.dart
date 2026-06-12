// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'poi_premium_content.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

PoiPremiumContent _$PoiPremiumContentFromJson(Map<String, dynamic> json) {
  return _PoiPremiumContent.fromJson(json);
}

/// @nodoc
mixin _$PoiPremiumContent {
  String get id => throw _privateConstructorUsedError;
  @JsonKey(name: 'poi_id')
  String get poiId => throw _privateConstructorUsedError;
  @JsonKey(name: 'audio_url')
  String? get audioUrl => throw _privateConstructorUsedError;
  @JsonKey(name: 'text_content')
  String? get textContent => throw _privateConstructorUsedError;
  @JsonKey(name: 'extra_photos')
  List<String> get extraPhotos => throw _privateConstructorUsedError;
  @JsonKey(name: 'related_poi_ids')
  List<String> get relatedPoiIds => throw _privateConstructorUsedError;
  @JsonKey(name: 'created_at')
  DateTime? get createdAt => throw _privateConstructorUsedError;
  @JsonKey(name: 'updated_at')
  DateTime? get updatedAt => throw _privateConstructorUsedError;

  /// Serializes this PoiPremiumContent to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of PoiPremiumContent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $PoiPremiumContentCopyWith<PoiPremiumContent> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PoiPremiumContentCopyWith<$Res> {
  factory $PoiPremiumContentCopyWith(
          PoiPremiumContent value, $Res Function(PoiPremiumContent) then) =
      _$PoiPremiumContentCopyWithImpl<$Res, PoiPremiumContent>;
  @useResult
  $Res call(
      {String id,
      @JsonKey(name: 'poi_id') String poiId,
      @JsonKey(name: 'audio_url') String? audioUrl,
      @JsonKey(name: 'text_content') String? textContent,
      @JsonKey(name: 'extra_photos') List<String> extraPhotos,
      @JsonKey(name: 'related_poi_ids') List<String> relatedPoiIds,
      @JsonKey(name: 'created_at') DateTime? createdAt,
      @JsonKey(name: 'updated_at') DateTime? updatedAt});
}

/// @nodoc
class _$PoiPremiumContentCopyWithImpl<$Res, $Val extends PoiPremiumContent>
    implements $PoiPremiumContentCopyWith<$Res> {
  _$PoiPremiumContentCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of PoiPremiumContent
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? poiId = null,
    Object? audioUrl = freezed,
    Object? textContent = freezed,
    Object? extraPhotos = null,
    Object? relatedPoiIds = null,
    Object? createdAt = freezed,
    Object? updatedAt = freezed,
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
      audioUrl: freezed == audioUrl
          ? _value.audioUrl
          : audioUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      textContent: freezed == textContent
          ? _value.textContent
          : textContent // ignore: cast_nullable_to_non_nullable
              as String?,
      extraPhotos: null == extraPhotos
          ? _value.extraPhotos
          : extraPhotos // ignore: cast_nullable_to_non_nullable
              as List<String>,
      relatedPoiIds: null == relatedPoiIds
          ? _value.relatedPoiIds
          : relatedPoiIds // ignore: cast_nullable_to_non_nullable
              as List<String>,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      updatedAt: freezed == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$PoiPremiumContentImplCopyWith<$Res>
    implements $PoiPremiumContentCopyWith<$Res> {
  factory _$$PoiPremiumContentImplCopyWith(_$PoiPremiumContentImpl value,
          $Res Function(_$PoiPremiumContentImpl) then) =
      __$$PoiPremiumContentImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      @JsonKey(name: 'poi_id') String poiId,
      @JsonKey(name: 'audio_url') String? audioUrl,
      @JsonKey(name: 'text_content') String? textContent,
      @JsonKey(name: 'extra_photos') List<String> extraPhotos,
      @JsonKey(name: 'related_poi_ids') List<String> relatedPoiIds,
      @JsonKey(name: 'created_at') DateTime? createdAt,
      @JsonKey(name: 'updated_at') DateTime? updatedAt});
}

/// @nodoc
class __$$PoiPremiumContentImplCopyWithImpl<$Res>
    extends _$PoiPremiumContentCopyWithImpl<$Res, _$PoiPremiumContentImpl>
    implements _$$PoiPremiumContentImplCopyWith<$Res> {
  __$$PoiPremiumContentImplCopyWithImpl(_$PoiPremiumContentImpl _value,
      $Res Function(_$PoiPremiumContentImpl) _then)
      : super(_value, _then);

  /// Create a copy of PoiPremiumContent
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? poiId = null,
    Object? audioUrl = freezed,
    Object? textContent = freezed,
    Object? extraPhotos = null,
    Object? relatedPoiIds = null,
    Object? createdAt = freezed,
    Object? updatedAt = freezed,
  }) {
    return _then(_$PoiPremiumContentImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      poiId: null == poiId
          ? _value.poiId
          : poiId // ignore: cast_nullable_to_non_nullable
              as String,
      audioUrl: freezed == audioUrl
          ? _value.audioUrl
          : audioUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      textContent: freezed == textContent
          ? _value.textContent
          : textContent // ignore: cast_nullable_to_non_nullable
              as String?,
      extraPhotos: null == extraPhotos
          ? _value._extraPhotos
          : extraPhotos // ignore: cast_nullable_to_non_nullable
              as List<String>,
      relatedPoiIds: null == relatedPoiIds
          ? _value._relatedPoiIds
          : relatedPoiIds // ignore: cast_nullable_to_non_nullable
              as List<String>,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      updatedAt: freezed == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$PoiPremiumContentImpl implements _PoiPremiumContent {
  const _$PoiPremiumContentImpl(
      {required this.id,
      @JsonKey(name: 'poi_id') required this.poiId,
      @JsonKey(name: 'audio_url') this.audioUrl,
      @JsonKey(name: 'text_content') this.textContent,
      @JsonKey(name: 'extra_photos') final List<String> extraPhotos = const [],
      @JsonKey(name: 'related_poi_ids')
      final List<String> relatedPoiIds = const [],
      @JsonKey(name: 'created_at') this.createdAt,
      @JsonKey(name: 'updated_at') this.updatedAt})
      : _extraPhotos = extraPhotos,
        _relatedPoiIds = relatedPoiIds;

  factory _$PoiPremiumContentImpl.fromJson(Map<String, dynamic> json) =>
      _$$PoiPremiumContentImplFromJson(json);

  @override
  final String id;
  @override
  @JsonKey(name: 'poi_id')
  final String poiId;
  @override
  @JsonKey(name: 'audio_url')
  final String? audioUrl;
  @override
  @JsonKey(name: 'text_content')
  final String? textContent;
  final List<String> _extraPhotos;
  @override
  @JsonKey(name: 'extra_photos')
  List<String> get extraPhotos {
    if (_extraPhotos is EqualUnmodifiableListView) return _extraPhotos;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_extraPhotos);
  }

  final List<String> _relatedPoiIds;
  @override
  @JsonKey(name: 'related_poi_ids')
  List<String> get relatedPoiIds {
    if (_relatedPoiIds is EqualUnmodifiableListView) return _relatedPoiIds;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_relatedPoiIds);
  }

  @override
  @JsonKey(name: 'created_at')
  final DateTime? createdAt;
  @override
  @JsonKey(name: 'updated_at')
  final DateTime? updatedAt;

  @override
  String toString() {
    return 'PoiPremiumContent(id: $id, poiId: $poiId, audioUrl: $audioUrl, textContent: $textContent, extraPhotos: $extraPhotos, relatedPoiIds: $relatedPoiIds, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PoiPremiumContentImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.poiId, poiId) || other.poiId == poiId) &&
            (identical(other.audioUrl, audioUrl) ||
                other.audioUrl == audioUrl) &&
            (identical(other.textContent, textContent) ||
                other.textContent == textContent) &&
            const DeepCollectionEquality()
                .equals(other._extraPhotos, _extraPhotos) &&
            const DeepCollectionEquality()
                .equals(other._relatedPoiIds, _relatedPoiIds) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      poiId,
      audioUrl,
      textContent,
      const DeepCollectionEquality().hash(_extraPhotos),
      const DeepCollectionEquality().hash(_relatedPoiIds),
      createdAt,
      updatedAt);

  /// Create a copy of PoiPremiumContent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PoiPremiumContentImplCopyWith<_$PoiPremiumContentImpl> get copyWith =>
      __$$PoiPremiumContentImplCopyWithImpl<_$PoiPremiumContentImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$PoiPremiumContentImplToJson(
      this,
    );
  }
}

abstract class _PoiPremiumContent implements PoiPremiumContent {
  const factory _PoiPremiumContent(
          {required final String id,
          @JsonKey(name: 'poi_id') required final String poiId,
          @JsonKey(name: 'audio_url') final String? audioUrl,
          @JsonKey(name: 'text_content') final String? textContent,
          @JsonKey(name: 'extra_photos') final List<String> extraPhotos,
          @JsonKey(name: 'related_poi_ids') final List<String> relatedPoiIds,
          @JsonKey(name: 'created_at') final DateTime? createdAt,
          @JsonKey(name: 'updated_at') final DateTime? updatedAt}) =
      _$PoiPremiumContentImpl;

  factory _PoiPremiumContent.fromJson(Map<String, dynamic> json) =
      _$PoiPremiumContentImpl.fromJson;

  @override
  String get id;
  @override
  @JsonKey(name: 'poi_id')
  String get poiId;
  @override
  @JsonKey(name: 'audio_url')
  String? get audioUrl;
  @override
  @JsonKey(name: 'text_content')
  String? get textContent;
  @override
  @JsonKey(name: 'extra_photos')
  List<String> get extraPhotos;
  @override
  @JsonKey(name: 'related_poi_ids')
  List<String> get relatedPoiIds;
  @override
  @JsonKey(name: 'created_at')
  DateTime? get createdAt;
  @override
  @JsonKey(name: 'updated_at')
  DateTime? get updatedAt;

  /// Create a copy of PoiPremiumContent
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PoiPremiumContentImplCopyWith<_$PoiPremiumContentImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
