// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'poi.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

Poi _$PoiFromJson(Map<String, dynamic> json) {
  return _Poi.fromJson(json);
}

/// @nodoc
mixin _$Poi {
  String get id => throw _privateConstructorUsedError;
  @JsonKey(name: 'city_id')
  String get cityId => throw _privateConstructorUsedError;
  @JsonKey(name: 'contributor_id')
  String? get contributorId => throw _privateConstructorUsedError;
  @JsonKey(includeFromJson: false, includeToJson: false)
  ContributorProfile? get contributor => throw _privateConstructorUsedError;
  @JsonKey(name: 'total_ratings')
  int get totalRatings => throw _privateConstructorUsedError;
  @JsonKey(name: 'avg_rating')
  double? get avgRating => throw _privateConstructorUsedError;
  Map<String, String> get name => throw _privateConstructorUsedError;
  Map<String, String> get description => throw _privateConstructorUsedError;
  double get latitude => throw _privateConstructorUsedError;
  double get longitude => throw _privateConstructorUsedError;
  @JsonKey(name: 'geofence_radius')
  double get geofenceRadius => throw _privateConstructorUsedError;
  @JsonKey(name: 'photo_urls')
  List<String> get photoUrls => throw _privateConstructorUsedError;
  @JsonKey(name: 'audio_urls')
  Map<String, String?> get audioUrls => throw _privateConstructorUsedError;
  @JsonKey(name: 'is_premium')
  bool get isPremium => throw _privateConstructorUsedError;
  @JsonKey(name: 'created_at')
  DateTime get createdAt => throw _privateConstructorUsedError;
  String? get slug => throw _privateConstructorUsedError;
  @JsonKey(name: 'access_level')
  String get accessLevel => throw _privateConstructorUsedError;
  String? get perex => throw _privateConstructorUsedError;
  @JsonKey(name: 'premium_price')
  double? get premiumPrice => throw _privateConstructorUsedError;
  @JsonKey(name: 'city_slug')
  String? get citySlug => throw _privateConstructorUsedError;
  @JsonKey(name: 'country_code')
  String? get countryCode => throw _privateConstructorUsedError;

  /// Serializes this Poi to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Poi
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $PoiCopyWith<Poi> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PoiCopyWith<$Res> {
  factory $PoiCopyWith(Poi value, $Res Function(Poi) then) =
      _$PoiCopyWithImpl<$Res, Poi>;
  @useResult
  $Res call(
      {String id,
      @JsonKey(name: 'city_id') String cityId,
      @JsonKey(name: 'contributor_id') String? contributorId,
      @JsonKey(includeFromJson: false, includeToJson: false)
      ContributorProfile? contributor,
      @JsonKey(name: 'total_ratings') int totalRatings,
      @JsonKey(name: 'avg_rating') double? avgRating,
      Map<String, String> name,
      Map<String, String> description,
      double latitude,
      double longitude,
      @JsonKey(name: 'geofence_radius') double geofenceRadius,
      @JsonKey(name: 'photo_urls') List<String> photoUrls,
      @JsonKey(name: 'audio_urls') Map<String, String?> audioUrls,
      @JsonKey(name: 'is_premium') bool isPremium,
      @JsonKey(name: 'created_at') DateTime createdAt,
      String? slug,
      @JsonKey(name: 'access_level') String accessLevel,
      String? perex,
      @JsonKey(name: 'premium_price') double? premiumPrice,
      @JsonKey(name: 'city_slug') String? citySlug,
      @JsonKey(name: 'country_code') String? countryCode});

  $ContributorProfileCopyWith<$Res>? get contributor;
}

/// @nodoc
class _$PoiCopyWithImpl<$Res, $Val extends Poi> implements $PoiCopyWith<$Res> {
  _$PoiCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Poi
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? cityId = null,
    Object? contributorId = freezed,
    Object? contributor = freezed,
    Object? totalRatings = null,
    Object? avgRating = freezed,
    Object? name = null,
    Object? description = null,
    Object? latitude = null,
    Object? longitude = null,
    Object? geofenceRadius = null,
    Object? photoUrls = null,
    Object? audioUrls = null,
    Object? isPremium = null,
    Object? createdAt = null,
    Object? slug = freezed,
    Object? accessLevel = null,
    Object? perex = freezed,
    Object? premiumPrice = freezed,
    Object? citySlug = freezed,
    Object? countryCode = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      cityId: null == cityId
          ? _value.cityId
          : cityId // ignore: cast_nullable_to_non_nullable
              as String,
      contributorId: freezed == contributorId
          ? _value.contributorId
          : contributorId // ignore: cast_nullable_to_non_nullable
              as String?,
      contributor: freezed == contributor
          ? _value.contributor
          : contributor // ignore: cast_nullable_to_non_nullable
              as ContributorProfile?,
      totalRatings: null == totalRatings
          ? _value.totalRatings
          : totalRatings // ignore: cast_nullable_to_non_nullable
              as int,
      avgRating: freezed == avgRating
          ? _value.avgRating
          : avgRating // ignore: cast_nullable_to_non_nullable
              as double?,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as Map<String, String>,
      description: null == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as Map<String, String>,
      latitude: null == latitude
          ? _value.latitude
          : latitude // ignore: cast_nullable_to_non_nullable
              as double,
      longitude: null == longitude
          ? _value.longitude
          : longitude // ignore: cast_nullable_to_non_nullable
              as double,
      geofenceRadius: null == geofenceRadius
          ? _value.geofenceRadius
          : geofenceRadius // ignore: cast_nullable_to_non_nullable
              as double,
      photoUrls: null == photoUrls
          ? _value.photoUrls
          : photoUrls // ignore: cast_nullable_to_non_nullable
              as List<String>,
      audioUrls: null == audioUrls
          ? _value.audioUrls
          : audioUrls // ignore: cast_nullable_to_non_nullable
              as Map<String, String?>,
      isPremium: null == isPremium
          ? _value.isPremium
          : isPremium // ignore: cast_nullable_to_non_nullable
              as bool,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      slug: freezed == slug
          ? _value.slug
          : slug // ignore: cast_nullable_to_non_nullable
              as String?,
      accessLevel: null == accessLevel
          ? _value.accessLevel
          : accessLevel // ignore: cast_nullable_to_non_nullable
              as String,
      perex: freezed == perex
          ? _value.perex
          : perex // ignore: cast_nullable_to_non_nullable
              as String?,
      premiumPrice: freezed == premiumPrice
          ? _value.premiumPrice
          : premiumPrice // ignore: cast_nullable_to_non_nullable
              as double?,
      citySlug: freezed == citySlug
          ? _value.citySlug
          : citySlug // ignore: cast_nullable_to_non_nullable
              as String?,
      countryCode: freezed == countryCode
          ? _value.countryCode
          : countryCode // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }

  /// Create a copy of Poi
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $ContributorProfileCopyWith<$Res>? get contributor {
    if (_value.contributor == null) {
      return null;
    }

    return $ContributorProfileCopyWith<$Res>(_value.contributor!, (value) {
      return _then(_value.copyWith(contributor: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$PoiImplCopyWith<$Res> implements $PoiCopyWith<$Res> {
  factory _$$PoiImplCopyWith(_$PoiImpl value, $Res Function(_$PoiImpl) then) =
      __$$PoiImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      @JsonKey(name: 'city_id') String cityId,
      @JsonKey(name: 'contributor_id') String? contributorId,
      @JsonKey(includeFromJson: false, includeToJson: false)
      ContributorProfile? contributor,
      @JsonKey(name: 'total_ratings') int totalRatings,
      @JsonKey(name: 'avg_rating') double? avgRating,
      Map<String, String> name,
      Map<String, String> description,
      double latitude,
      double longitude,
      @JsonKey(name: 'geofence_radius') double geofenceRadius,
      @JsonKey(name: 'photo_urls') List<String> photoUrls,
      @JsonKey(name: 'audio_urls') Map<String, String?> audioUrls,
      @JsonKey(name: 'is_premium') bool isPremium,
      @JsonKey(name: 'created_at') DateTime createdAt,
      String? slug,
      @JsonKey(name: 'access_level') String accessLevel,
      String? perex,
      @JsonKey(name: 'premium_price') double? premiumPrice,
      @JsonKey(name: 'city_slug') String? citySlug,
      @JsonKey(name: 'country_code') String? countryCode});

  @override
  $ContributorProfileCopyWith<$Res>? get contributor;
}

/// @nodoc
class __$$PoiImplCopyWithImpl<$Res> extends _$PoiCopyWithImpl<$Res, _$PoiImpl>
    implements _$$PoiImplCopyWith<$Res> {
  __$$PoiImplCopyWithImpl(_$PoiImpl _value, $Res Function(_$PoiImpl) _then)
      : super(_value, _then);

  /// Create a copy of Poi
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? cityId = null,
    Object? contributorId = freezed,
    Object? contributor = freezed,
    Object? totalRatings = null,
    Object? avgRating = freezed,
    Object? name = null,
    Object? description = null,
    Object? latitude = null,
    Object? longitude = null,
    Object? geofenceRadius = null,
    Object? photoUrls = null,
    Object? audioUrls = null,
    Object? isPremium = null,
    Object? createdAt = null,
    Object? slug = freezed,
    Object? accessLevel = null,
    Object? perex = freezed,
    Object? premiumPrice = freezed,
    Object? citySlug = freezed,
    Object? countryCode = freezed,
  }) {
    return _then(_$PoiImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      cityId: null == cityId
          ? _value.cityId
          : cityId // ignore: cast_nullable_to_non_nullable
              as String,
      contributorId: freezed == contributorId
          ? _value.contributorId
          : contributorId // ignore: cast_nullable_to_non_nullable
              as String?,
      contributor: freezed == contributor
          ? _value.contributor
          : contributor // ignore: cast_nullable_to_non_nullable
              as ContributorProfile?,
      totalRatings: null == totalRatings
          ? _value.totalRatings
          : totalRatings // ignore: cast_nullable_to_non_nullable
              as int,
      avgRating: freezed == avgRating
          ? _value.avgRating
          : avgRating // ignore: cast_nullable_to_non_nullable
              as double?,
      name: null == name
          ? _value._name
          : name // ignore: cast_nullable_to_non_nullable
              as Map<String, String>,
      description: null == description
          ? _value._description
          : description // ignore: cast_nullable_to_non_nullable
              as Map<String, String>,
      latitude: null == latitude
          ? _value.latitude
          : latitude // ignore: cast_nullable_to_non_nullable
              as double,
      longitude: null == longitude
          ? _value.longitude
          : longitude // ignore: cast_nullable_to_non_nullable
              as double,
      geofenceRadius: null == geofenceRadius
          ? _value.geofenceRadius
          : geofenceRadius // ignore: cast_nullable_to_non_nullable
              as double,
      photoUrls: null == photoUrls
          ? _value._photoUrls
          : photoUrls // ignore: cast_nullable_to_non_nullable
              as List<String>,
      audioUrls: null == audioUrls
          ? _value._audioUrls
          : audioUrls // ignore: cast_nullable_to_non_nullable
              as Map<String, String?>,
      isPremium: null == isPremium
          ? _value.isPremium
          : isPremium // ignore: cast_nullable_to_non_nullable
              as bool,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      slug: freezed == slug
          ? _value.slug
          : slug // ignore: cast_nullable_to_non_nullable
              as String?,
      accessLevel: null == accessLevel
          ? _value.accessLevel
          : accessLevel // ignore: cast_nullable_to_non_nullable
              as String,
      perex: freezed == perex
          ? _value.perex
          : perex // ignore: cast_nullable_to_non_nullable
              as String?,
      premiumPrice: freezed == premiumPrice
          ? _value.premiumPrice
          : premiumPrice // ignore: cast_nullable_to_non_nullable
              as double?,
      citySlug: freezed == citySlug
          ? _value.citySlug
          : citySlug // ignore: cast_nullable_to_non_nullable
              as String?,
      countryCode: freezed == countryCode
          ? _value.countryCode
          : countryCode // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$PoiImpl extends _Poi {
  const _$PoiImpl(
      {required this.id,
      @JsonKey(name: 'city_id') required this.cityId,
      @JsonKey(name: 'contributor_id') this.contributorId,
      @JsonKey(includeFromJson: false, includeToJson: false) this.contributor,
      @JsonKey(name: 'total_ratings') this.totalRatings = 0,
      @JsonKey(name: 'avg_rating') this.avgRating,
      required final Map<String, String> name,
      required final Map<String, String> description,
      required this.latitude,
      required this.longitude,
      @JsonKey(name: 'geofence_radius') this.geofenceRadius = 100.0,
      @JsonKey(name: 'photo_urls') final List<String> photoUrls = const [],
      @JsonKey(name: 'audio_urls')
      final Map<String, String?> audioUrls = const {},
      @JsonKey(name: 'is_premium') this.isPremium = true,
      @JsonKey(name: 'created_at') required this.createdAt,
      this.slug,
      @JsonKey(name: 'access_level') this.accessLevel = 'city_access',
      this.perex,
      @JsonKey(name: 'premium_price') this.premiumPrice,
      @JsonKey(name: 'city_slug') this.citySlug,
      @JsonKey(name: 'country_code') this.countryCode})
      : _name = name,
        _description = description,
        _photoUrls = photoUrls,
        _audioUrls = audioUrls,
        super._();

  factory _$PoiImpl.fromJson(Map<String, dynamic> json) =>
      _$$PoiImplFromJson(json);

  @override
  final String id;
  @override
  @JsonKey(name: 'city_id')
  final String cityId;
  @override
  @JsonKey(name: 'contributor_id')
  final String? contributorId;
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  final ContributorProfile? contributor;
  @override
  @JsonKey(name: 'total_ratings')
  final int totalRatings;
  @override
  @JsonKey(name: 'avg_rating')
  final double? avgRating;
  final Map<String, String> _name;
  @override
  Map<String, String> get name {
    if (_name is EqualUnmodifiableMapView) return _name;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_name);
  }

  final Map<String, String> _description;
  @override
  Map<String, String> get description {
    if (_description is EqualUnmodifiableMapView) return _description;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_description);
  }

  @override
  final double latitude;
  @override
  final double longitude;
  @override
  @JsonKey(name: 'geofence_radius')
  final double geofenceRadius;
  final List<String> _photoUrls;
  @override
  @JsonKey(name: 'photo_urls')
  List<String> get photoUrls {
    if (_photoUrls is EqualUnmodifiableListView) return _photoUrls;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_photoUrls);
  }

  final Map<String, String?> _audioUrls;
  @override
  @JsonKey(name: 'audio_urls')
  Map<String, String?> get audioUrls {
    if (_audioUrls is EqualUnmodifiableMapView) return _audioUrls;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_audioUrls);
  }

  @override
  @JsonKey(name: 'is_premium')
  final bool isPremium;
  @override
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @override
  final String? slug;
  @override
  @JsonKey(name: 'access_level')
  final String accessLevel;
  @override
  final String? perex;
  @override
  @JsonKey(name: 'premium_price')
  final double? premiumPrice;
  @override
  @JsonKey(name: 'city_slug')
  final String? citySlug;
  @override
  @JsonKey(name: 'country_code')
  final String? countryCode;

  @override
  String toString() {
    return 'Poi(id: $id, cityId: $cityId, contributorId: $contributorId, contributor: $contributor, totalRatings: $totalRatings, avgRating: $avgRating, name: $name, description: $description, latitude: $latitude, longitude: $longitude, geofenceRadius: $geofenceRadius, photoUrls: $photoUrls, audioUrls: $audioUrls, isPremium: $isPremium, createdAt: $createdAt, slug: $slug, accessLevel: $accessLevel, perex: $perex, premiumPrice: $premiumPrice, citySlug: $citySlug, countryCode: $countryCode)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PoiImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.cityId, cityId) || other.cityId == cityId) &&
            (identical(other.contributorId, contributorId) ||
                other.contributorId == contributorId) &&
            (identical(other.contributor, contributor) ||
                other.contributor == contributor) &&
            (identical(other.totalRatings, totalRatings) ||
                other.totalRatings == totalRatings) &&
            (identical(other.avgRating, avgRating) ||
                other.avgRating == avgRating) &&
            const DeepCollectionEquality().equals(other._name, _name) &&
            const DeepCollectionEquality()
                .equals(other._description, _description) &&
            (identical(other.latitude, latitude) ||
                other.latitude == latitude) &&
            (identical(other.longitude, longitude) ||
                other.longitude == longitude) &&
            (identical(other.geofenceRadius, geofenceRadius) ||
                other.geofenceRadius == geofenceRadius) &&
            const DeepCollectionEquality()
                .equals(other._photoUrls, _photoUrls) &&
            const DeepCollectionEquality()
                .equals(other._audioUrls, _audioUrls) &&
            (identical(other.isPremium, isPremium) ||
                other.isPremium == isPremium) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.slug, slug) || other.slug == slug) &&
            (identical(other.accessLevel, accessLevel) ||
                other.accessLevel == accessLevel) &&
            (identical(other.perex, perex) || other.perex == perex) &&
            (identical(other.premiumPrice, premiumPrice) ||
                other.premiumPrice == premiumPrice) &&
            (identical(other.citySlug, citySlug) ||
                other.citySlug == citySlug) &&
            (identical(other.countryCode, countryCode) ||
                other.countryCode == countryCode));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hashAll([
        runtimeType,
        id,
        cityId,
        contributorId,
        contributor,
        totalRatings,
        avgRating,
        const DeepCollectionEquality().hash(_name),
        const DeepCollectionEquality().hash(_description),
        latitude,
        longitude,
        geofenceRadius,
        const DeepCollectionEquality().hash(_photoUrls),
        const DeepCollectionEquality().hash(_audioUrls),
        isPremium,
        createdAt,
        slug,
        accessLevel,
        perex,
        premiumPrice,
        citySlug,
        countryCode
      ]);

  /// Create a copy of Poi
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PoiImplCopyWith<_$PoiImpl> get copyWith =>
      __$$PoiImplCopyWithImpl<_$PoiImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$PoiImplToJson(
      this,
    );
  }
}

abstract class _Poi extends Poi {
  const factory _Poi(
      {required final String id,
      @JsonKey(name: 'city_id') required final String cityId,
      @JsonKey(name: 'contributor_id') final String? contributorId,
      @JsonKey(includeFromJson: false, includeToJson: false)
      final ContributorProfile? contributor,
      @JsonKey(name: 'total_ratings') final int totalRatings,
      @JsonKey(name: 'avg_rating') final double? avgRating,
      required final Map<String, String> name,
      required final Map<String, String> description,
      required final double latitude,
      required final double longitude,
      @JsonKey(name: 'geofence_radius') final double geofenceRadius,
      @JsonKey(name: 'photo_urls') final List<String> photoUrls,
      @JsonKey(name: 'audio_urls') final Map<String, String?> audioUrls,
      @JsonKey(name: 'is_premium') final bool isPremium,
      @JsonKey(name: 'created_at') required final DateTime createdAt,
      final String? slug,
      @JsonKey(name: 'access_level') final String accessLevel,
      final String? perex,
      @JsonKey(name: 'premium_price') final double? premiumPrice,
      @JsonKey(name: 'city_slug') final String? citySlug,
      @JsonKey(name: 'country_code') final String? countryCode}) = _$PoiImpl;
  const _Poi._() : super._();

  factory _Poi.fromJson(Map<String, dynamic> json) = _$PoiImpl.fromJson;

  @override
  String get id;
  @override
  @JsonKey(name: 'city_id')
  String get cityId;
  @override
  @JsonKey(name: 'contributor_id')
  String? get contributorId;
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  ContributorProfile? get contributor;
  @override
  @JsonKey(name: 'total_ratings')
  int get totalRatings;
  @override
  @JsonKey(name: 'avg_rating')
  double? get avgRating;
  @override
  Map<String, String> get name;
  @override
  Map<String, String> get description;
  @override
  double get latitude;
  @override
  double get longitude;
  @override
  @JsonKey(name: 'geofence_radius')
  double get geofenceRadius;
  @override
  @JsonKey(name: 'photo_urls')
  List<String> get photoUrls;
  @override
  @JsonKey(name: 'audio_urls')
  Map<String, String?> get audioUrls;
  @override
  @JsonKey(name: 'is_premium')
  bool get isPremium;
  @override
  @JsonKey(name: 'created_at')
  DateTime get createdAt;
  @override
  String? get slug;
  @override
  @JsonKey(name: 'access_level')
  String get accessLevel;
  @override
  String? get perex;
  @override
  @JsonKey(name: 'premium_price')
  double? get premiumPrice;
  @override
  @JsonKey(name: 'city_slug')
  String? get citySlug;
  @override
  @JsonKey(name: 'country_code')
  String? get countryCode;

  /// Create a copy of Poi
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PoiImplCopyWith<_$PoiImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
