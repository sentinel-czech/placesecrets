// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'contributor_profile.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

ContributorProfile _$ContributorProfileFromJson(Map<String, dynamic> json) {
  return _ContributorProfile.fromJson(json);
}

/// @nodoc
mixin _$ContributorProfile {
  String get id => throw _privateConstructorUsedError;
  @JsonKey(name: 'user_id')
  String get userId => throw _privateConstructorUsedError;
  @JsonKey(name: 'display_name')
  String get displayName => throw _privateConstructorUsedError;
  String? get bio => throw _privateConstructorUsedError;
  @JsonKey(name: 'avatar_url')
  String? get avatarUrl => throw _privateConstructorUsedError;
  @JsonKey(name: 'website_url')
  String? get websiteUrl => throw _privateConstructorUsedError;
  List<String> get specializations => throw _privateConstructorUsedError;
  @JsonKey(name: 'total_pois')
  int get totalPois => throw _privateConstructorUsedError;
  @JsonKey(name: 'avg_rating')
  double? get avgRating => throw _privateConstructorUsedError;
  @JsonKey(name: 'total_ratings')
  int get totalRatings => throw _privateConstructorUsedError;
  @JsonKey(name: 'is_verified')
  bool get isVerified => throw _privateConstructorUsedError;
  @JsonKey(name: 'is_active')
  bool get isActive => throw _privateConstructorUsedError;
  @JsonKey(name: 'created_at')
  DateTime get createdAt => throw _privateConstructorUsedError;

  /// Serializes this ContributorProfile to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ContributorProfile
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ContributorProfileCopyWith<ContributorProfile> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ContributorProfileCopyWith<$Res> {
  factory $ContributorProfileCopyWith(
          ContributorProfile value, $Res Function(ContributorProfile) then) =
      _$ContributorProfileCopyWithImpl<$Res, ContributorProfile>;
  @useResult
  $Res call(
      {String id,
      @JsonKey(name: 'user_id') String userId,
      @JsonKey(name: 'display_name') String displayName,
      String? bio,
      @JsonKey(name: 'avatar_url') String? avatarUrl,
      @JsonKey(name: 'website_url') String? websiteUrl,
      List<String> specializations,
      @JsonKey(name: 'total_pois') int totalPois,
      @JsonKey(name: 'avg_rating') double? avgRating,
      @JsonKey(name: 'total_ratings') int totalRatings,
      @JsonKey(name: 'is_verified') bool isVerified,
      @JsonKey(name: 'is_active') bool isActive,
      @JsonKey(name: 'created_at') DateTime createdAt});
}

/// @nodoc
class _$ContributorProfileCopyWithImpl<$Res, $Val extends ContributorProfile>
    implements $ContributorProfileCopyWith<$Res> {
  _$ContributorProfileCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ContributorProfile
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? userId = null,
    Object? displayName = null,
    Object? bio = freezed,
    Object? avatarUrl = freezed,
    Object? websiteUrl = freezed,
    Object? specializations = null,
    Object? totalPois = null,
    Object? avgRating = freezed,
    Object? totalRatings = null,
    Object? isVerified = null,
    Object? isActive = null,
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
      displayName: null == displayName
          ? _value.displayName
          : displayName // ignore: cast_nullable_to_non_nullable
              as String,
      bio: freezed == bio
          ? _value.bio
          : bio // ignore: cast_nullable_to_non_nullable
              as String?,
      avatarUrl: freezed == avatarUrl
          ? _value.avatarUrl
          : avatarUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      websiteUrl: freezed == websiteUrl
          ? _value.websiteUrl
          : websiteUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      specializations: null == specializations
          ? _value.specializations
          : specializations // ignore: cast_nullable_to_non_nullable
              as List<String>,
      totalPois: null == totalPois
          ? _value.totalPois
          : totalPois // ignore: cast_nullable_to_non_nullable
              as int,
      avgRating: freezed == avgRating
          ? _value.avgRating
          : avgRating // ignore: cast_nullable_to_non_nullable
              as double?,
      totalRatings: null == totalRatings
          ? _value.totalRatings
          : totalRatings // ignore: cast_nullable_to_non_nullable
              as int,
      isVerified: null == isVerified
          ? _value.isVerified
          : isVerified // ignore: cast_nullable_to_non_nullable
              as bool,
      isActive: null == isActive
          ? _value.isActive
          : isActive // ignore: cast_nullable_to_non_nullable
              as bool,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ContributorProfileImplCopyWith<$Res>
    implements $ContributorProfileCopyWith<$Res> {
  factory _$$ContributorProfileImplCopyWith(_$ContributorProfileImpl value,
          $Res Function(_$ContributorProfileImpl) then) =
      __$$ContributorProfileImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      @JsonKey(name: 'user_id') String userId,
      @JsonKey(name: 'display_name') String displayName,
      String? bio,
      @JsonKey(name: 'avatar_url') String? avatarUrl,
      @JsonKey(name: 'website_url') String? websiteUrl,
      List<String> specializations,
      @JsonKey(name: 'total_pois') int totalPois,
      @JsonKey(name: 'avg_rating') double? avgRating,
      @JsonKey(name: 'total_ratings') int totalRatings,
      @JsonKey(name: 'is_verified') bool isVerified,
      @JsonKey(name: 'is_active') bool isActive,
      @JsonKey(name: 'created_at') DateTime createdAt});
}

/// @nodoc
class __$$ContributorProfileImplCopyWithImpl<$Res>
    extends _$ContributorProfileCopyWithImpl<$Res, _$ContributorProfileImpl>
    implements _$$ContributorProfileImplCopyWith<$Res> {
  __$$ContributorProfileImplCopyWithImpl(_$ContributorProfileImpl _value,
      $Res Function(_$ContributorProfileImpl) _then)
      : super(_value, _then);

  /// Create a copy of ContributorProfile
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? userId = null,
    Object? displayName = null,
    Object? bio = freezed,
    Object? avatarUrl = freezed,
    Object? websiteUrl = freezed,
    Object? specializations = null,
    Object? totalPois = null,
    Object? avgRating = freezed,
    Object? totalRatings = null,
    Object? isVerified = null,
    Object? isActive = null,
    Object? createdAt = null,
  }) {
    return _then(_$ContributorProfileImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      userId: null == userId
          ? _value.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String,
      displayName: null == displayName
          ? _value.displayName
          : displayName // ignore: cast_nullable_to_non_nullable
              as String,
      bio: freezed == bio
          ? _value.bio
          : bio // ignore: cast_nullable_to_non_nullable
              as String?,
      avatarUrl: freezed == avatarUrl
          ? _value.avatarUrl
          : avatarUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      websiteUrl: freezed == websiteUrl
          ? _value.websiteUrl
          : websiteUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      specializations: null == specializations
          ? _value._specializations
          : specializations // ignore: cast_nullable_to_non_nullable
              as List<String>,
      totalPois: null == totalPois
          ? _value.totalPois
          : totalPois // ignore: cast_nullable_to_non_nullable
              as int,
      avgRating: freezed == avgRating
          ? _value.avgRating
          : avgRating // ignore: cast_nullable_to_non_nullable
              as double?,
      totalRatings: null == totalRatings
          ? _value.totalRatings
          : totalRatings // ignore: cast_nullable_to_non_nullable
              as int,
      isVerified: null == isVerified
          ? _value.isVerified
          : isVerified // ignore: cast_nullable_to_non_nullable
              as bool,
      isActive: null == isActive
          ? _value.isActive
          : isActive // ignore: cast_nullable_to_non_nullable
              as bool,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ContributorProfileImpl extends _ContributorProfile {
  const _$ContributorProfileImpl(
      {required this.id,
      @JsonKey(name: 'user_id') required this.userId,
      @JsonKey(name: 'display_name') required this.displayName,
      this.bio,
      @JsonKey(name: 'avatar_url') this.avatarUrl,
      @JsonKey(name: 'website_url') this.websiteUrl,
      final List<String> specializations = const [],
      @JsonKey(name: 'total_pois') this.totalPois = 0,
      @JsonKey(name: 'avg_rating') this.avgRating,
      @JsonKey(name: 'total_ratings') this.totalRatings = 0,
      @JsonKey(name: 'is_verified') this.isVerified = false,
      @JsonKey(name: 'is_active') this.isActive = true,
      @JsonKey(name: 'created_at') required this.createdAt})
      : _specializations = specializations,
        super._();

  factory _$ContributorProfileImpl.fromJson(Map<String, dynamic> json) =>
      _$$ContributorProfileImplFromJson(json);

  @override
  final String id;
  @override
  @JsonKey(name: 'user_id')
  final String userId;
  @override
  @JsonKey(name: 'display_name')
  final String displayName;
  @override
  final String? bio;
  @override
  @JsonKey(name: 'avatar_url')
  final String? avatarUrl;
  @override
  @JsonKey(name: 'website_url')
  final String? websiteUrl;
  final List<String> _specializations;
  @override
  @JsonKey()
  List<String> get specializations {
    if (_specializations is EqualUnmodifiableListView) return _specializations;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_specializations);
  }

  @override
  @JsonKey(name: 'total_pois')
  final int totalPois;
  @override
  @JsonKey(name: 'avg_rating')
  final double? avgRating;
  @override
  @JsonKey(name: 'total_ratings')
  final int totalRatings;
  @override
  @JsonKey(name: 'is_verified')
  final bool isVerified;
  @override
  @JsonKey(name: 'is_active')
  final bool isActive;
  @override
  @JsonKey(name: 'created_at')
  final DateTime createdAt;

  @override
  String toString() {
    return 'ContributorProfile(id: $id, userId: $userId, displayName: $displayName, bio: $bio, avatarUrl: $avatarUrl, websiteUrl: $websiteUrl, specializations: $specializations, totalPois: $totalPois, avgRating: $avgRating, totalRatings: $totalRatings, isVerified: $isVerified, isActive: $isActive, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ContributorProfileImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.displayName, displayName) ||
                other.displayName == displayName) &&
            (identical(other.bio, bio) || other.bio == bio) &&
            (identical(other.avatarUrl, avatarUrl) ||
                other.avatarUrl == avatarUrl) &&
            (identical(other.websiteUrl, websiteUrl) ||
                other.websiteUrl == websiteUrl) &&
            const DeepCollectionEquality()
                .equals(other._specializations, _specializations) &&
            (identical(other.totalPois, totalPois) ||
                other.totalPois == totalPois) &&
            (identical(other.avgRating, avgRating) ||
                other.avgRating == avgRating) &&
            (identical(other.totalRatings, totalRatings) ||
                other.totalRatings == totalRatings) &&
            (identical(other.isVerified, isVerified) ||
                other.isVerified == isVerified) &&
            (identical(other.isActive, isActive) ||
                other.isActive == isActive) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      userId,
      displayName,
      bio,
      avatarUrl,
      websiteUrl,
      const DeepCollectionEquality().hash(_specializations),
      totalPois,
      avgRating,
      totalRatings,
      isVerified,
      isActive,
      createdAt);

  /// Create a copy of ContributorProfile
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ContributorProfileImplCopyWith<_$ContributorProfileImpl> get copyWith =>
      __$$ContributorProfileImplCopyWithImpl<_$ContributorProfileImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ContributorProfileImplToJson(
      this,
    );
  }
}

abstract class _ContributorProfile extends ContributorProfile {
  const factory _ContributorProfile(
          {required final String id,
          @JsonKey(name: 'user_id') required final String userId,
          @JsonKey(name: 'display_name') required final String displayName,
          final String? bio,
          @JsonKey(name: 'avatar_url') final String? avatarUrl,
          @JsonKey(name: 'website_url') final String? websiteUrl,
          final List<String> specializations,
          @JsonKey(name: 'total_pois') final int totalPois,
          @JsonKey(name: 'avg_rating') final double? avgRating,
          @JsonKey(name: 'total_ratings') final int totalRatings,
          @JsonKey(name: 'is_verified') final bool isVerified,
          @JsonKey(name: 'is_active') final bool isActive,
          @JsonKey(name: 'created_at') required final DateTime createdAt}) =
      _$ContributorProfileImpl;
  const _ContributorProfile._() : super._();

  factory _ContributorProfile.fromJson(Map<String, dynamic> json) =
      _$ContributorProfileImpl.fromJson;

  @override
  String get id;
  @override
  @JsonKey(name: 'user_id')
  String get userId;
  @override
  @JsonKey(name: 'display_name')
  String get displayName;
  @override
  String? get bio;
  @override
  @JsonKey(name: 'avatar_url')
  String? get avatarUrl;
  @override
  @JsonKey(name: 'website_url')
  String? get websiteUrl;
  @override
  List<String> get specializations;
  @override
  @JsonKey(name: 'total_pois')
  int get totalPois;
  @override
  @JsonKey(name: 'avg_rating')
  double? get avgRating;
  @override
  @JsonKey(name: 'total_ratings')
  int get totalRatings;
  @override
  @JsonKey(name: 'is_verified')
  bool get isVerified;
  @override
  @JsonKey(name: 'is_active')
  bool get isActive;
  @override
  @JsonKey(name: 'created_at')
  DateTime get createdAt;

  /// Create a copy of ContributorProfile
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ContributorProfileImplCopyWith<_$ContributorProfileImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

HallOfFameEntry _$HallOfFameEntryFromJson(Map<String, dynamic> json) {
  return _HallOfFameEntry.fromJson(json);
}

/// @nodoc
mixin _$HallOfFameEntry {
  int get rank => throw _privateConstructorUsedError;
  @JsonKey(name: 'contributor_id')
  String get contributorId => throw _privateConstructorUsedError;
  @JsonKey(name: 'display_name')
  String get displayName => throw _privateConstructorUsedError;
  @JsonKey(name: 'avatar_url')
  String? get avatarUrl => throw _privateConstructorUsedError;
  @JsonKey(name: 'is_verified')
  bool get isVerified => throw _privateConstructorUsedError;
  @JsonKey(name: 'city_poi_count')
  int get cityPoiCount => throw _privateConstructorUsedError;
  @JsonKey(name: 'city_avg_rating')
  double? get cityAvgRating => throw _privateConstructorUsedError;
  @JsonKey(name: 'city_total_ratings')
  int get cityTotalRatings => throw _privateConstructorUsedError;
  @JsonKey(name: 'hof_score')
  double? get hofScore => throw _privateConstructorUsedError;
  @JsonKey(name: 'sample_poi_names')
  List<Map<String, dynamic>> get samplePoiNames =>
      throw _privateConstructorUsedError;

  /// Serializes this HallOfFameEntry to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of HallOfFameEntry
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $HallOfFameEntryCopyWith<HallOfFameEntry> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $HallOfFameEntryCopyWith<$Res> {
  factory $HallOfFameEntryCopyWith(
          HallOfFameEntry value, $Res Function(HallOfFameEntry) then) =
      _$HallOfFameEntryCopyWithImpl<$Res, HallOfFameEntry>;
  @useResult
  $Res call(
      {int rank,
      @JsonKey(name: 'contributor_id') String contributorId,
      @JsonKey(name: 'display_name') String displayName,
      @JsonKey(name: 'avatar_url') String? avatarUrl,
      @JsonKey(name: 'is_verified') bool isVerified,
      @JsonKey(name: 'city_poi_count') int cityPoiCount,
      @JsonKey(name: 'city_avg_rating') double? cityAvgRating,
      @JsonKey(name: 'city_total_ratings') int cityTotalRatings,
      @JsonKey(name: 'hof_score') double? hofScore,
      @JsonKey(name: 'sample_poi_names')
      List<Map<String, dynamic>> samplePoiNames});
}

/// @nodoc
class _$HallOfFameEntryCopyWithImpl<$Res, $Val extends HallOfFameEntry>
    implements $HallOfFameEntryCopyWith<$Res> {
  _$HallOfFameEntryCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of HallOfFameEntry
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? rank = null,
    Object? contributorId = null,
    Object? displayName = null,
    Object? avatarUrl = freezed,
    Object? isVerified = null,
    Object? cityPoiCount = null,
    Object? cityAvgRating = freezed,
    Object? cityTotalRatings = null,
    Object? hofScore = freezed,
    Object? samplePoiNames = null,
  }) {
    return _then(_value.copyWith(
      rank: null == rank
          ? _value.rank
          : rank // ignore: cast_nullable_to_non_nullable
              as int,
      contributorId: null == contributorId
          ? _value.contributorId
          : contributorId // ignore: cast_nullable_to_non_nullable
              as String,
      displayName: null == displayName
          ? _value.displayName
          : displayName // ignore: cast_nullable_to_non_nullable
              as String,
      avatarUrl: freezed == avatarUrl
          ? _value.avatarUrl
          : avatarUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      isVerified: null == isVerified
          ? _value.isVerified
          : isVerified // ignore: cast_nullable_to_non_nullable
              as bool,
      cityPoiCount: null == cityPoiCount
          ? _value.cityPoiCount
          : cityPoiCount // ignore: cast_nullable_to_non_nullable
              as int,
      cityAvgRating: freezed == cityAvgRating
          ? _value.cityAvgRating
          : cityAvgRating // ignore: cast_nullable_to_non_nullable
              as double?,
      cityTotalRatings: null == cityTotalRatings
          ? _value.cityTotalRatings
          : cityTotalRatings // ignore: cast_nullable_to_non_nullable
              as int,
      hofScore: freezed == hofScore
          ? _value.hofScore
          : hofScore // ignore: cast_nullable_to_non_nullable
              as double?,
      samplePoiNames: null == samplePoiNames
          ? _value.samplePoiNames
          : samplePoiNames // ignore: cast_nullable_to_non_nullable
              as List<Map<String, dynamic>>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$HallOfFameEntryImplCopyWith<$Res>
    implements $HallOfFameEntryCopyWith<$Res> {
  factory _$$HallOfFameEntryImplCopyWith(_$HallOfFameEntryImpl value,
          $Res Function(_$HallOfFameEntryImpl) then) =
      __$$HallOfFameEntryImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {int rank,
      @JsonKey(name: 'contributor_id') String contributorId,
      @JsonKey(name: 'display_name') String displayName,
      @JsonKey(name: 'avatar_url') String? avatarUrl,
      @JsonKey(name: 'is_verified') bool isVerified,
      @JsonKey(name: 'city_poi_count') int cityPoiCount,
      @JsonKey(name: 'city_avg_rating') double? cityAvgRating,
      @JsonKey(name: 'city_total_ratings') int cityTotalRatings,
      @JsonKey(name: 'hof_score') double? hofScore,
      @JsonKey(name: 'sample_poi_names')
      List<Map<String, dynamic>> samplePoiNames});
}

/// @nodoc
class __$$HallOfFameEntryImplCopyWithImpl<$Res>
    extends _$HallOfFameEntryCopyWithImpl<$Res, _$HallOfFameEntryImpl>
    implements _$$HallOfFameEntryImplCopyWith<$Res> {
  __$$HallOfFameEntryImplCopyWithImpl(
      _$HallOfFameEntryImpl _value, $Res Function(_$HallOfFameEntryImpl) _then)
      : super(_value, _then);

  /// Create a copy of HallOfFameEntry
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? rank = null,
    Object? contributorId = null,
    Object? displayName = null,
    Object? avatarUrl = freezed,
    Object? isVerified = null,
    Object? cityPoiCount = null,
    Object? cityAvgRating = freezed,
    Object? cityTotalRatings = null,
    Object? hofScore = freezed,
    Object? samplePoiNames = null,
  }) {
    return _then(_$HallOfFameEntryImpl(
      rank: null == rank
          ? _value.rank
          : rank // ignore: cast_nullable_to_non_nullable
              as int,
      contributorId: null == contributorId
          ? _value.contributorId
          : contributorId // ignore: cast_nullable_to_non_nullable
              as String,
      displayName: null == displayName
          ? _value.displayName
          : displayName // ignore: cast_nullable_to_non_nullable
              as String,
      avatarUrl: freezed == avatarUrl
          ? _value.avatarUrl
          : avatarUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      isVerified: null == isVerified
          ? _value.isVerified
          : isVerified // ignore: cast_nullable_to_non_nullable
              as bool,
      cityPoiCount: null == cityPoiCount
          ? _value.cityPoiCount
          : cityPoiCount // ignore: cast_nullable_to_non_nullable
              as int,
      cityAvgRating: freezed == cityAvgRating
          ? _value.cityAvgRating
          : cityAvgRating // ignore: cast_nullable_to_non_nullable
              as double?,
      cityTotalRatings: null == cityTotalRatings
          ? _value.cityTotalRatings
          : cityTotalRatings // ignore: cast_nullable_to_non_nullable
              as int,
      hofScore: freezed == hofScore
          ? _value.hofScore
          : hofScore // ignore: cast_nullable_to_non_nullable
              as double?,
      samplePoiNames: null == samplePoiNames
          ? _value._samplePoiNames
          : samplePoiNames // ignore: cast_nullable_to_non_nullable
              as List<Map<String, dynamic>>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$HallOfFameEntryImpl implements _HallOfFameEntry {
  const _$HallOfFameEntryImpl(
      {required this.rank,
      @JsonKey(name: 'contributor_id') required this.contributorId,
      @JsonKey(name: 'display_name') required this.displayName,
      @JsonKey(name: 'avatar_url') this.avatarUrl,
      @JsonKey(name: 'is_verified') this.isVerified = false,
      @JsonKey(name: 'city_poi_count') required this.cityPoiCount,
      @JsonKey(name: 'city_avg_rating') this.cityAvgRating,
      @JsonKey(name: 'city_total_ratings') required this.cityTotalRatings,
      @JsonKey(name: 'hof_score') this.hofScore,
      @JsonKey(name: 'sample_poi_names')
      final List<Map<String, dynamic>> samplePoiNames = const []})
      : _samplePoiNames = samplePoiNames;

  factory _$HallOfFameEntryImpl.fromJson(Map<String, dynamic> json) =>
      _$$HallOfFameEntryImplFromJson(json);

  @override
  final int rank;
  @override
  @JsonKey(name: 'contributor_id')
  final String contributorId;
  @override
  @JsonKey(name: 'display_name')
  final String displayName;
  @override
  @JsonKey(name: 'avatar_url')
  final String? avatarUrl;
  @override
  @JsonKey(name: 'is_verified')
  final bool isVerified;
  @override
  @JsonKey(name: 'city_poi_count')
  final int cityPoiCount;
  @override
  @JsonKey(name: 'city_avg_rating')
  final double? cityAvgRating;
  @override
  @JsonKey(name: 'city_total_ratings')
  final int cityTotalRatings;
  @override
  @JsonKey(name: 'hof_score')
  final double? hofScore;
  final List<Map<String, dynamic>> _samplePoiNames;
  @override
  @JsonKey(name: 'sample_poi_names')
  List<Map<String, dynamic>> get samplePoiNames {
    if (_samplePoiNames is EqualUnmodifiableListView) return _samplePoiNames;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_samplePoiNames);
  }

  @override
  String toString() {
    return 'HallOfFameEntry(rank: $rank, contributorId: $contributorId, displayName: $displayName, avatarUrl: $avatarUrl, isVerified: $isVerified, cityPoiCount: $cityPoiCount, cityAvgRating: $cityAvgRating, cityTotalRatings: $cityTotalRatings, hofScore: $hofScore, samplePoiNames: $samplePoiNames)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$HallOfFameEntryImpl &&
            (identical(other.rank, rank) || other.rank == rank) &&
            (identical(other.contributorId, contributorId) ||
                other.contributorId == contributorId) &&
            (identical(other.displayName, displayName) ||
                other.displayName == displayName) &&
            (identical(other.avatarUrl, avatarUrl) ||
                other.avatarUrl == avatarUrl) &&
            (identical(other.isVerified, isVerified) ||
                other.isVerified == isVerified) &&
            (identical(other.cityPoiCount, cityPoiCount) ||
                other.cityPoiCount == cityPoiCount) &&
            (identical(other.cityAvgRating, cityAvgRating) ||
                other.cityAvgRating == cityAvgRating) &&
            (identical(other.cityTotalRatings, cityTotalRatings) ||
                other.cityTotalRatings == cityTotalRatings) &&
            (identical(other.hofScore, hofScore) ||
                other.hofScore == hofScore) &&
            const DeepCollectionEquality()
                .equals(other._samplePoiNames, _samplePoiNames));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      rank,
      contributorId,
      displayName,
      avatarUrl,
      isVerified,
      cityPoiCount,
      cityAvgRating,
      cityTotalRatings,
      hofScore,
      const DeepCollectionEquality().hash(_samplePoiNames));

  /// Create a copy of HallOfFameEntry
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$HallOfFameEntryImplCopyWith<_$HallOfFameEntryImpl> get copyWith =>
      __$$HallOfFameEntryImplCopyWithImpl<_$HallOfFameEntryImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$HallOfFameEntryImplToJson(
      this,
    );
  }
}

abstract class _HallOfFameEntry implements HallOfFameEntry {
  const factory _HallOfFameEntry(
      {required final int rank,
      @JsonKey(name: 'contributor_id') required final String contributorId,
      @JsonKey(name: 'display_name') required final String displayName,
      @JsonKey(name: 'avatar_url') final String? avatarUrl,
      @JsonKey(name: 'is_verified') final bool isVerified,
      @JsonKey(name: 'city_poi_count') required final int cityPoiCount,
      @JsonKey(name: 'city_avg_rating') final double? cityAvgRating,
      @JsonKey(name: 'city_total_ratings') required final int cityTotalRatings,
      @JsonKey(name: 'hof_score') final double? hofScore,
      @JsonKey(name: 'sample_poi_names')
      final List<Map<String, dynamic>> samplePoiNames}) = _$HallOfFameEntryImpl;

  factory _HallOfFameEntry.fromJson(Map<String, dynamic> json) =
      _$HallOfFameEntryImpl.fromJson;

  @override
  int get rank;
  @override
  @JsonKey(name: 'contributor_id')
  String get contributorId;
  @override
  @JsonKey(name: 'display_name')
  String get displayName;
  @override
  @JsonKey(name: 'avatar_url')
  String? get avatarUrl;
  @override
  @JsonKey(name: 'is_verified')
  bool get isVerified;
  @override
  @JsonKey(name: 'city_poi_count')
  int get cityPoiCount;
  @override
  @JsonKey(name: 'city_avg_rating')
  double? get cityAvgRating;
  @override
  @JsonKey(name: 'city_total_ratings')
  int get cityTotalRatings;
  @override
  @JsonKey(name: 'hof_score')
  double? get hofScore;
  @override
  @JsonKey(name: 'sample_poi_names')
  List<Map<String, dynamic>> get samplePoiNames;

  /// Create a copy of HallOfFameEntry
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$HallOfFameEntryImplCopyWith<_$HallOfFameEntryImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
