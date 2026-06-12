// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'poi.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$PoiImpl _$$PoiImplFromJson(Map<String, dynamic> json) => _$PoiImpl(
      id: json['id'] as String,
      cityId: json['city_id'] as String,
      contributorId: json['contributor_id'] as String?,
      totalRatings: (json['total_ratings'] as num?)?.toInt() ?? 0,
      avgRating: (json['avg_rating'] as num?)?.toDouble(),
      name: Map<String, String>.from(json['name'] as Map),
      description: Map<String, String>.from(json['description'] as Map),
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      geofenceRadius: (json['geofence_radius'] as num?)?.toDouble() ?? 100.0,
      photoUrls: (json['photo_urls'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      audioUrls: (json['audio_urls'] as Map<String, dynamic>?)?.map(
            (k, e) => MapEntry(k, e as String?),
          ) ??
          const {},
      isPremium: json['is_premium'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
      slug: json['slug'] as String?,
      accessLevel: json['access_level'] as String? ?? 'city_access',
      perex: json['perex'] as String?,
      premiumPrice: (json['premium_price'] as num?)?.toDouble(),
      citySlug: json['city_slug'] as String?,
      countryCode: json['country_code'] as String?,
    );

Map<String, dynamic> _$$PoiImplToJson(_$PoiImpl instance) => <String, dynamic>{
      'id': instance.id,
      'city_id': instance.cityId,
      'contributor_id': instance.contributorId,
      'total_ratings': instance.totalRatings,
      'avg_rating': instance.avgRating,
      'name': instance.name,
      'description': instance.description,
      'latitude': instance.latitude,
      'longitude': instance.longitude,
      'geofence_radius': instance.geofenceRadius,
      'photo_urls': instance.photoUrls,
      'audio_urls': instance.audioUrls,
      'is_premium': instance.isPremium,
      'created_at': instance.createdAt.toIso8601String(),
      'slug': instance.slug,
      'access_level': instance.accessLevel,
      'perex': instance.perex,
      'premium_price': instance.premiumPrice,
      'city_slug': instance.citySlug,
      'country_code': instance.countryCode,
    };
