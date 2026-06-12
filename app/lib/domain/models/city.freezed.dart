// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'city.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

City _$CityFromJson(Map<String, dynamic> json) {
  return _City.fromJson(json);
}

/// @nodoc
mixin _$City {
  String get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String get country => throw _privateConstructorUsedError;
  @JsonKey(name: 'country_code')
  String get countryCode => throw _privateConstructorUsedError;
  double get latitude => throw _privateConstructorUsedError;
  double get longitude => throw _privateConstructorUsedError;
  @JsonKey(name: 'bounding_box_radius_km')
  double get boundingBoxRadiusKm => throw _privateConstructorUsedError;
  @JsonKey(name: 'price_eur')
  double get priceEur => throw _privateConstructorUsedError;
  @JsonKey(name: 'is_active')
  bool get isActive => throw _privateConstructorUsedError;
  String? get slug => throw _privateConstructorUsedError;
  @JsonKey(name: 'registered_sample_poi_id')
  String? get registeredSamplePoiId => throw _privateConstructorUsedError;
  @JsonKey(name: 'premium_bundle_price')
  double? get premiumBundlePrice => throw _privateConstructorUsedError;

  /// Serializes this City to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of City
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $CityCopyWith<City> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CityCopyWith<$Res> {
  factory $CityCopyWith(City value, $Res Function(City) then) =
      _$CityCopyWithImpl<$Res, City>;
  @useResult
  $Res call(
      {String id,
      String name,
      String country,
      @JsonKey(name: 'country_code') String countryCode,
      double latitude,
      double longitude,
      @JsonKey(name: 'bounding_box_radius_km') double boundingBoxRadiusKm,
      @JsonKey(name: 'price_eur') double priceEur,
      @JsonKey(name: 'is_active') bool isActive,
      String? slug,
      @JsonKey(name: 'registered_sample_poi_id') String? registeredSamplePoiId,
      @JsonKey(name: 'premium_bundle_price') double? premiumBundlePrice});
}

/// @nodoc
class _$CityCopyWithImpl<$Res, $Val extends City>
    implements $CityCopyWith<$Res> {
  _$CityCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of City
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? country = null,
    Object? countryCode = null,
    Object? latitude = null,
    Object? longitude = null,
    Object? boundingBoxRadiusKm = null,
    Object? priceEur = null,
    Object? isActive = null,
    Object? slug = freezed,
    Object? registeredSamplePoiId = freezed,
    Object? premiumBundlePrice = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      country: null == country
          ? _value.country
          : country // ignore: cast_nullable_to_non_nullable
              as String,
      countryCode: null == countryCode
          ? _value.countryCode
          : countryCode // ignore: cast_nullable_to_non_nullable
              as String,
      latitude: null == latitude
          ? _value.latitude
          : latitude // ignore: cast_nullable_to_non_nullable
              as double,
      longitude: null == longitude
          ? _value.longitude
          : longitude // ignore: cast_nullable_to_non_nullable
              as double,
      boundingBoxRadiusKm: null == boundingBoxRadiusKm
          ? _value.boundingBoxRadiusKm
          : boundingBoxRadiusKm // ignore: cast_nullable_to_non_nullable
              as double,
      priceEur: null == priceEur
          ? _value.priceEur
          : priceEur // ignore: cast_nullable_to_non_nullable
              as double,
      isActive: null == isActive
          ? _value.isActive
          : isActive // ignore: cast_nullable_to_non_nullable
              as bool,
      slug: freezed == slug
          ? _value.slug
          : slug // ignore: cast_nullable_to_non_nullable
              as String?,
      registeredSamplePoiId: freezed == registeredSamplePoiId
          ? _value.registeredSamplePoiId
          : registeredSamplePoiId // ignore: cast_nullable_to_non_nullable
              as String?,
      premiumBundlePrice: freezed == premiumBundlePrice
          ? _value.premiumBundlePrice
          : premiumBundlePrice // ignore: cast_nullable_to_non_nullable
              as double?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$CityImplCopyWith<$Res> implements $CityCopyWith<$Res> {
  factory _$$CityImplCopyWith(
          _$CityImpl value, $Res Function(_$CityImpl) then) =
      __$$CityImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String name,
      String country,
      @JsonKey(name: 'country_code') String countryCode,
      double latitude,
      double longitude,
      @JsonKey(name: 'bounding_box_radius_km') double boundingBoxRadiusKm,
      @JsonKey(name: 'price_eur') double priceEur,
      @JsonKey(name: 'is_active') bool isActive,
      String? slug,
      @JsonKey(name: 'registered_sample_poi_id') String? registeredSamplePoiId,
      @JsonKey(name: 'premium_bundle_price') double? premiumBundlePrice});
}

/// @nodoc
class __$$CityImplCopyWithImpl<$Res>
    extends _$CityCopyWithImpl<$Res, _$CityImpl>
    implements _$$CityImplCopyWith<$Res> {
  __$$CityImplCopyWithImpl(_$CityImpl _value, $Res Function(_$CityImpl) _then)
      : super(_value, _then);

  /// Create a copy of City
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? country = null,
    Object? countryCode = null,
    Object? latitude = null,
    Object? longitude = null,
    Object? boundingBoxRadiusKm = null,
    Object? priceEur = null,
    Object? isActive = null,
    Object? slug = freezed,
    Object? registeredSamplePoiId = freezed,
    Object? premiumBundlePrice = freezed,
  }) {
    return _then(_$CityImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      country: null == country
          ? _value.country
          : country // ignore: cast_nullable_to_non_nullable
              as String,
      countryCode: null == countryCode
          ? _value.countryCode
          : countryCode // ignore: cast_nullable_to_non_nullable
              as String,
      latitude: null == latitude
          ? _value.latitude
          : latitude // ignore: cast_nullable_to_non_nullable
              as double,
      longitude: null == longitude
          ? _value.longitude
          : longitude // ignore: cast_nullable_to_non_nullable
              as double,
      boundingBoxRadiusKm: null == boundingBoxRadiusKm
          ? _value.boundingBoxRadiusKm
          : boundingBoxRadiusKm // ignore: cast_nullable_to_non_nullable
              as double,
      priceEur: null == priceEur
          ? _value.priceEur
          : priceEur // ignore: cast_nullable_to_non_nullable
              as double,
      isActive: null == isActive
          ? _value.isActive
          : isActive // ignore: cast_nullable_to_non_nullable
              as bool,
      slug: freezed == slug
          ? _value.slug
          : slug // ignore: cast_nullable_to_non_nullable
              as String?,
      registeredSamplePoiId: freezed == registeredSamplePoiId
          ? _value.registeredSamplePoiId
          : registeredSamplePoiId // ignore: cast_nullable_to_non_nullable
              as String?,
      premiumBundlePrice: freezed == premiumBundlePrice
          ? _value.premiumBundlePrice
          : premiumBundlePrice // ignore: cast_nullable_to_non_nullable
              as double?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$CityImpl implements _City {
  const _$CityImpl(
      {required this.id,
      required this.name,
      required this.country,
      @JsonKey(name: 'country_code') required this.countryCode,
      required this.latitude,
      required this.longitude,
      @JsonKey(name: 'bounding_box_radius_km') this.boundingBoxRadiusKm = 10.0,
      @JsonKey(name: 'price_eur') this.priceEur = 1.0,
      @JsonKey(name: 'is_active') this.isActive = true,
      this.slug,
      @JsonKey(name: 'registered_sample_poi_id') this.registeredSamplePoiId,
      @JsonKey(name: 'premium_bundle_price') this.premiumBundlePrice});

  factory _$CityImpl.fromJson(Map<String, dynamic> json) =>
      _$$CityImplFromJson(json);

  @override
  final String id;
  @override
  final String name;
  @override
  final String country;
  @override
  @JsonKey(name: 'country_code')
  final String countryCode;
  @override
  final double latitude;
  @override
  final double longitude;
  @override
  @JsonKey(name: 'bounding_box_radius_km')
  final double boundingBoxRadiusKm;
  @override
  @JsonKey(name: 'price_eur')
  final double priceEur;
  @override
  @JsonKey(name: 'is_active')
  final bool isActive;
  @override
  final String? slug;
  @override
  @JsonKey(name: 'registered_sample_poi_id')
  final String? registeredSamplePoiId;
  @override
  @JsonKey(name: 'premium_bundle_price')
  final double? premiumBundlePrice;

  @override
  String toString() {
    return 'City(id: $id, name: $name, country: $country, countryCode: $countryCode, latitude: $latitude, longitude: $longitude, boundingBoxRadiusKm: $boundingBoxRadiusKm, priceEur: $priceEur, isActive: $isActive, slug: $slug, registeredSamplePoiId: $registeredSamplePoiId, premiumBundlePrice: $premiumBundlePrice)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CityImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.country, country) || other.country == country) &&
            (identical(other.countryCode, countryCode) ||
                other.countryCode == countryCode) &&
            (identical(other.latitude, latitude) ||
                other.latitude == latitude) &&
            (identical(other.longitude, longitude) ||
                other.longitude == longitude) &&
            (identical(other.boundingBoxRadiusKm, boundingBoxRadiusKm) ||
                other.boundingBoxRadiusKm == boundingBoxRadiusKm) &&
            (identical(other.priceEur, priceEur) ||
                other.priceEur == priceEur) &&
            (identical(other.isActive, isActive) ||
                other.isActive == isActive) &&
            (identical(other.slug, slug) || other.slug == slug) &&
            (identical(other.registeredSamplePoiId, registeredSamplePoiId) ||
                other.registeredSamplePoiId == registeredSamplePoiId) &&
            (identical(other.premiumBundlePrice, premiumBundlePrice) ||
                other.premiumBundlePrice == premiumBundlePrice));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      name,
      country,
      countryCode,
      latitude,
      longitude,
      boundingBoxRadiusKm,
      priceEur,
      isActive,
      slug,
      registeredSamplePoiId,
      premiumBundlePrice);

  /// Create a copy of City
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$CityImplCopyWith<_$CityImpl> get copyWith =>
      __$$CityImplCopyWithImpl<_$CityImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$CityImplToJson(
      this,
    );
  }
}

abstract class _City implements City {
  const factory _City(
      {required final String id,
      required final String name,
      required final String country,
      @JsonKey(name: 'country_code') required final String countryCode,
      required final double latitude,
      required final double longitude,
      @JsonKey(name: 'bounding_box_radius_km') final double boundingBoxRadiusKm,
      @JsonKey(name: 'price_eur') final double priceEur,
      @JsonKey(name: 'is_active') final bool isActive,
      final String? slug,
      @JsonKey(name: 'registered_sample_poi_id')
      final String? registeredSamplePoiId,
      @JsonKey(name: 'premium_bundle_price')
      final double? premiumBundlePrice}) = _$CityImpl;

  factory _City.fromJson(Map<String, dynamic> json) = _$CityImpl.fromJson;

  @override
  String get id;
  @override
  String get name;
  @override
  String get country;
  @override
  @JsonKey(name: 'country_code')
  String get countryCode;
  @override
  double get latitude;
  @override
  double get longitude;
  @override
  @JsonKey(name: 'bounding_box_radius_km')
  double get boundingBoxRadiusKm;
  @override
  @JsonKey(name: 'price_eur')
  double get priceEur;
  @override
  @JsonKey(name: 'is_active')
  bool get isActive;
  @override
  String? get slug;
  @override
  @JsonKey(name: 'registered_sample_poi_id')
  String? get registeredSamplePoiId;
  @override
  @JsonKey(name: 'premium_bundle_price')
  double? get premiumBundlePrice;

  /// Create a copy of City
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$CityImplCopyWith<_$CityImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
