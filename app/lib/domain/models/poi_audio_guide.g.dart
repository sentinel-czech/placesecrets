// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'poi_audio_guide.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$PoiAudioGuideImpl _$$PoiAudioGuideImplFromJson(Map<String, dynamic> json) =>
    _$PoiAudioGuideImpl(
      id: json['id'] as String,
      poiId: json['poi_id'] as String,
      langCode: json['lang_code'] as String,
      title: json['title'] as String? ?? '',
      url: json['url'] as String,
      durationSec: (json['duration_sec'] as num?)?.toInt(),
      sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$$PoiAudioGuideImplToJson(_$PoiAudioGuideImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'poi_id': instance.poiId,
      'lang_code': instance.langCode,
      'title': instance.title,
      'url': instance.url,
      'duration_sec': instance.durationSec,
      'sort_order': instance.sortOrder,
    };
