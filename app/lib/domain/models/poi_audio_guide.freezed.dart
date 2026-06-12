// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'poi_audio_guide.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

PoiAudioGuide _$PoiAudioGuideFromJson(Map<String, dynamic> json) {
  return _PoiAudioGuide.fromJson(json);
}

/// @nodoc
mixin _$PoiAudioGuide {
  String get id => throw _privateConstructorUsedError;
  @JsonKey(name: 'poi_id')
  String get poiId => throw _privateConstructorUsedError;
  @JsonKey(name: 'lang_code')
  String get langCode => throw _privateConstructorUsedError;
  String get title => throw _privateConstructorUsedError;
  String get url => throw _privateConstructorUsedError;
  @JsonKey(name: 'duration_sec')
  int? get durationSec => throw _privateConstructorUsedError;
  @JsonKey(name: 'sort_order')
  int get sortOrder => throw _privateConstructorUsedError;

  /// Serializes this PoiAudioGuide to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of PoiAudioGuide
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $PoiAudioGuideCopyWith<PoiAudioGuide> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PoiAudioGuideCopyWith<$Res> {
  factory $PoiAudioGuideCopyWith(
          PoiAudioGuide value, $Res Function(PoiAudioGuide) then) =
      _$PoiAudioGuideCopyWithImpl<$Res, PoiAudioGuide>;
  @useResult
  $Res call(
      {String id,
      @JsonKey(name: 'poi_id') String poiId,
      @JsonKey(name: 'lang_code') String langCode,
      String title,
      String url,
      @JsonKey(name: 'duration_sec') int? durationSec,
      @JsonKey(name: 'sort_order') int sortOrder});
}

/// @nodoc
class _$PoiAudioGuideCopyWithImpl<$Res, $Val extends PoiAudioGuide>
    implements $PoiAudioGuideCopyWith<$Res> {
  _$PoiAudioGuideCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of PoiAudioGuide
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? poiId = null,
    Object? langCode = null,
    Object? title = null,
    Object? url = null,
    Object? durationSec = freezed,
    Object? sortOrder = null,
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
      langCode: null == langCode
          ? _value.langCode
          : langCode // ignore: cast_nullable_to_non_nullable
              as String,
      title: null == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      url: null == url
          ? _value.url
          : url // ignore: cast_nullable_to_non_nullable
              as String,
      durationSec: freezed == durationSec
          ? _value.durationSec
          : durationSec // ignore: cast_nullable_to_non_nullable
              as int?,
      sortOrder: null == sortOrder
          ? _value.sortOrder
          : sortOrder // ignore: cast_nullable_to_non_nullable
              as int,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$PoiAudioGuideImplCopyWith<$Res>
    implements $PoiAudioGuideCopyWith<$Res> {
  factory _$$PoiAudioGuideImplCopyWith(
          _$PoiAudioGuideImpl value, $Res Function(_$PoiAudioGuideImpl) then) =
      __$$PoiAudioGuideImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      @JsonKey(name: 'poi_id') String poiId,
      @JsonKey(name: 'lang_code') String langCode,
      String title,
      String url,
      @JsonKey(name: 'duration_sec') int? durationSec,
      @JsonKey(name: 'sort_order') int sortOrder});
}

/// @nodoc
class __$$PoiAudioGuideImplCopyWithImpl<$Res>
    extends _$PoiAudioGuideCopyWithImpl<$Res, _$PoiAudioGuideImpl>
    implements _$$PoiAudioGuideImplCopyWith<$Res> {
  __$$PoiAudioGuideImplCopyWithImpl(
      _$PoiAudioGuideImpl _value, $Res Function(_$PoiAudioGuideImpl) _then)
      : super(_value, _then);

  /// Create a copy of PoiAudioGuide
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? poiId = null,
    Object? langCode = null,
    Object? title = null,
    Object? url = null,
    Object? durationSec = freezed,
    Object? sortOrder = null,
  }) {
    return _then(_$PoiAudioGuideImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      poiId: null == poiId
          ? _value.poiId
          : poiId // ignore: cast_nullable_to_non_nullable
              as String,
      langCode: null == langCode
          ? _value.langCode
          : langCode // ignore: cast_nullable_to_non_nullable
              as String,
      title: null == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      url: null == url
          ? _value.url
          : url // ignore: cast_nullable_to_non_nullable
              as String,
      durationSec: freezed == durationSec
          ? _value.durationSec
          : durationSec // ignore: cast_nullable_to_non_nullable
              as int?,
      sortOrder: null == sortOrder
          ? _value.sortOrder
          : sortOrder // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$PoiAudioGuideImpl extends _PoiAudioGuide {
  const _$PoiAudioGuideImpl(
      {required this.id,
      @JsonKey(name: 'poi_id') required this.poiId,
      @JsonKey(name: 'lang_code') required this.langCode,
      this.title = '',
      required this.url,
      @JsonKey(name: 'duration_sec') this.durationSec,
      @JsonKey(name: 'sort_order') this.sortOrder = 0})
      : super._();

  factory _$PoiAudioGuideImpl.fromJson(Map<String, dynamic> json) =>
      _$$PoiAudioGuideImplFromJson(json);

  @override
  final String id;
  @override
  @JsonKey(name: 'poi_id')
  final String poiId;
  @override
  @JsonKey(name: 'lang_code')
  final String langCode;
  @override
  @JsonKey()
  final String title;
  @override
  final String url;
  @override
  @JsonKey(name: 'duration_sec')
  final int? durationSec;
  @override
  @JsonKey(name: 'sort_order')
  final int sortOrder;

  @override
  String toString() {
    return 'PoiAudioGuide(id: $id, poiId: $poiId, langCode: $langCode, title: $title, url: $url, durationSec: $durationSec, sortOrder: $sortOrder)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PoiAudioGuideImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.poiId, poiId) || other.poiId == poiId) &&
            (identical(other.langCode, langCode) ||
                other.langCode == langCode) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.url, url) || other.url == url) &&
            (identical(other.durationSec, durationSec) ||
                other.durationSec == durationSec) &&
            (identical(other.sortOrder, sortOrder) ||
                other.sortOrder == sortOrder));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType, id, poiId, langCode, title, url, durationSec, sortOrder);

  /// Create a copy of PoiAudioGuide
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PoiAudioGuideImplCopyWith<_$PoiAudioGuideImpl> get copyWith =>
      __$$PoiAudioGuideImplCopyWithImpl<_$PoiAudioGuideImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$PoiAudioGuideImplToJson(
      this,
    );
  }
}

abstract class _PoiAudioGuide extends PoiAudioGuide {
  const factory _PoiAudioGuide(
      {required final String id,
      @JsonKey(name: 'poi_id') required final String poiId,
      @JsonKey(name: 'lang_code') required final String langCode,
      final String title,
      required final String url,
      @JsonKey(name: 'duration_sec') final int? durationSec,
      @JsonKey(name: 'sort_order') final int sortOrder}) = _$PoiAudioGuideImpl;
  const _PoiAudioGuide._() : super._();

  factory _PoiAudioGuide.fromJson(Map<String, dynamic> json) =
      _$PoiAudioGuideImpl.fromJson;

  @override
  String get id;
  @override
  @JsonKey(name: 'poi_id')
  String get poiId;
  @override
  @JsonKey(name: 'lang_code')
  String get langCode;
  @override
  String get title;
  @override
  String get url;
  @override
  @JsonKey(name: 'duration_sec')
  int? get durationSec;
  @override
  @JsonKey(name: 'sort_order')
  int get sortOrder;

  /// Create a copy of PoiAudioGuide
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PoiAudioGuideImplCopyWith<_$PoiAudioGuideImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
