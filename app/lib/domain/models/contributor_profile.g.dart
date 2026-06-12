// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'contributor_profile.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ContributorProfileImpl _$$ContributorProfileImplFromJson(
        Map<String, dynamic> json) =>
    _$ContributorProfileImpl(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      displayName: json['display_name'] as String,
      bio: json['bio'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      websiteUrl: json['website_url'] as String?,
      specializations: (json['specializations'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      totalPois: (json['total_pois'] as num?)?.toInt() ?? 0,
      avgRating: (json['avg_rating'] as num?)?.toDouble(),
      totalRatings: (json['total_ratings'] as num?)?.toInt() ?? 0,
      isVerified: json['is_verified'] as bool? ?? false,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
    );

Map<String, dynamic> _$$ContributorProfileImplToJson(
        _$ContributorProfileImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'user_id': instance.userId,
      'display_name': instance.displayName,
      'bio': instance.bio,
      'avatar_url': instance.avatarUrl,
      'website_url': instance.websiteUrl,
      'specializations': instance.specializations,
      'total_pois': instance.totalPois,
      'avg_rating': instance.avgRating,
      'total_ratings': instance.totalRatings,
      'is_verified': instance.isVerified,
      'is_active': instance.isActive,
      'created_at': instance.createdAt.toIso8601String(),
    };

_$HallOfFameEntryImpl _$$HallOfFameEntryImplFromJson(
        Map<String, dynamic> json) =>
    _$HallOfFameEntryImpl(
      rank: (json['rank'] as num).toInt(),
      contributorId: json['contributor_id'] as String,
      displayName: json['display_name'] as String,
      avatarUrl: json['avatar_url'] as String?,
      isVerified: json['is_verified'] as bool? ?? false,
      cityPoiCount: (json['city_poi_count'] as num).toInt(),
      cityAvgRating: (json['city_avg_rating'] as num?)?.toDouble(),
      cityTotalRatings: (json['city_total_ratings'] as num).toInt(),
      hofScore: (json['hof_score'] as num?)?.toDouble(),
      samplePoiNames: (json['sample_poi_names'] as List<dynamic>?)
              ?.map((e) => e as Map<String, dynamic>)
              .toList() ??
          const [],
    );

Map<String, dynamic> _$$HallOfFameEntryImplToJson(
        _$HallOfFameEntryImpl instance) =>
    <String, dynamic>{
      'rank': instance.rank,
      'contributor_id': instance.contributorId,
      'display_name': instance.displayName,
      'avatar_url': instance.avatarUrl,
      'is_verified': instance.isVerified,
      'city_poi_count': instance.cityPoiCount,
      'city_avg_rating': instance.cityAvgRating,
      'city_total_ratings': instance.cityTotalRatings,
      'hof_score': instance.hofScore,
      'sample_poi_names': instance.samplePoiNames,
    };
