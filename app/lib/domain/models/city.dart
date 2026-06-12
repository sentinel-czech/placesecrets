import 'package:freezed_annotation/freezed_annotation.dart';

part 'city.freezed.dart';
part 'city.g.dart';

@freezed
class City with _$City {
  const factory City({
    required String id,
    required String name,
    required String country,
    @JsonKey(name: 'country_code') required String countryCode,
    required double latitude,
    required double longitude,
    @JsonKey(name: 'bounding_box_radius_km')
    @Default(10.0)
    double boundingBoxRadiusKm,
    @JsonKey(name: 'price_eur') @Default(1.0) double priceEur,
    @JsonKey(name: 'is_active') @Default(true) bool isActive,
    String? slug,
    @JsonKey(name: 'registered_sample_poi_id') String? registeredSamplePoiId,
    @JsonKey(name: 'premium_bundle_price') double? premiumBundlePrice,
  }) = _City;

  factory City.fromJson(Map<String, dynamic> json) => _$CityFromJson(json);
}
