// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'city.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$CityImpl _$$CityImplFromJson(Map<String, dynamic> json) => _$CityImpl(
      id: json['id'] as String,
      name: json['name'] as String,
      country: json['country'] as String,
      countryCode: json['country_code'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      boundingBoxRadiusKm:
          (json['bounding_box_radius_km'] as num?)?.toDouble() ?? 10.0,
      priceEur: (json['price_eur'] as num?)?.toDouble() ?? 1.0,
      isActive: json['is_active'] as bool? ?? true,
      slug: json['slug'] as String?,
      registeredSamplePoiId: json['registered_sample_poi_id'] as String?,
      premiumBundlePrice: (json['premium_bundle_price'] as num?)?.toDouble(),
    );

Map<String, dynamic> _$$CityImplToJson(_$CityImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'country': instance.country,
      'country_code': instance.countryCode,
      'latitude': instance.latitude,
      'longitude': instance.longitude,
      'bounding_box_radius_km': instance.boundingBoxRadiusKm,
      'price_eur': instance.priceEur,
      'is_active': instance.isActive,
      'slug': instance.slug,
      'registered_sample_poi_id': instance.registeredSamplePoiId,
      'premium_bundle_price': instance.premiumBundlePrice,
    };
