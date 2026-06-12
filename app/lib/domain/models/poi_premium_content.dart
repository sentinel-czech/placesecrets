import 'package:freezed_annotation/freezed_annotation.dart';

part 'poi_premium_content.freezed.dart';
part 'poi_premium_content.g.dart';

@freezed
class PoiPremiumContent with _$PoiPremiumContent {
  const factory PoiPremiumContent({
    required String id,
    @JsonKey(name: 'poi_id') required String poiId,
    @JsonKey(name: 'audio_url') String? audioUrl,
    @JsonKey(name: 'text_content') String? textContent,
    @JsonKey(name: 'extra_photos') @Default([]) List<String> extraPhotos,
    @JsonKey(name: 'related_poi_ids') @Default([]) List<String> relatedPoiIds,
    @JsonKey(name: 'created_at') DateTime? createdAt,
    @JsonKey(name: 'updated_at') DateTime? updatedAt,
  }) = _PoiPremiumContent;

  factory PoiPremiumContent.fromJson(Map<String, dynamic> json) =>
      _$PoiPremiumContentFromJson(json);
}
