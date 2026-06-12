// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'poi_premium_content.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$PoiPremiumContentImpl _$$PoiPremiumContentImplFromJson(
        Map<String, dynamic> json) =>
    _$PoiPremiumContentImpl(
      id: json['id'] as String,
      poiId: json['poi_id'] as String,
      audioUrl: json['audio_url'] as String?,
      textContent: json['text_content'] as String?,
      extraPhotos: (json['extra_photos'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      relatedPoiIds: (json['related_poi_ids'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      createdAt: json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] == null
          ? null
          : DateTime.parse(json['updated_at'] as String),
    );

Map<String, dynamic> _$$PoiPremiumContentImplToJson(
        _$PoiPremiumContentImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'poi_id': instance.poiId,
      'audio_url': instance.audioUrl,
      'text_content': instance.textContent,
      'extra_photos': instance.extraPhotos,
      'related_poi_ids': instance.relatedPoiIds,
      'created_at': instance.createdAt?.toIso8601String(),
      'updated_at': instance.updatedAt?.toIso8601String(),
    };
