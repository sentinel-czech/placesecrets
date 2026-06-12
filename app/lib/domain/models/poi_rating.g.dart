// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'poi_rating.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$PoiRatingImpl _$$PoiRatingImplFromJson(Map<String, dynamic> json) =>
    _$PoiRatingImpl(
      id: json['id'] as String,
      poiId: json['poi_id'] as String,
      userId: json['user_id'] as String?,
      deviceId: json['device_id'] as String?,
      rating: (json['rating'] as num).toInt(),
      reason: $enumDecodeNullable(_$RatingReasonEnumMap, json['reason']),
      langCode: json['lang_code'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );

Map<String, dynamic> _$$PoiRatingImplToJson(_$PoiRatingImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'poi_id': instance.poiId,
      'user_id': instance.userId,
      'device_id': instance.deviceId,
      'rating': instance.rating,
      'reason': _$RatingReasonEnumMap[instance.reason],
      'lang_code': instance.langCode,
      'created_at': instance.createdAt.toIso8601String(),
    };

const _$RatingReasonEnumMap = {
  RatingReason.inaccurate: 'inaccurate',
  RatingReason.tooShort: 'too_short',
  RatingReason.boring: 'boring',
  RatingReason.wrongLang: 'wrong_lang',
  RatingReason.other: 'other',
};
