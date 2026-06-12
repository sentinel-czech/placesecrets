import 'package:freezed_annotation/freezed_annotation.dart';

part 'poi_audio_guide.freezed.dart';
part 'poi_audio_guide.g.dart';

@freezed
class PoiAudioGuide with _$PoiAudioGuide {
  const PoiAudioGuide._();

  const factory PoiAudioGuide({
    required String id,
    @JsonKey(name: 'poi_id') required String poiId,
    @JsonKey(name: 'lang_code') required String langCode,
    @Default('') String title,
    required String url,
    @JsonKey(name: 'duration_sec') int? durationSec,
    @JsonKey(name: 'sort_order') @Default(0) int sortOrder,
  }) = _PoiAudioGuide;

  factory PoiAudioGuide.fromJson(Map<String, dynamic> json) =>
      _$PoiAudioGuideFromJson(json);

  String get displayTitle => title.isNotEmpty ? title : 'Untitled';

  String? get formattedDuration {
    if (durationSec == null) return null;
    final m = durationSec! ~/ 60;
    final s = durationSec! % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }
}
