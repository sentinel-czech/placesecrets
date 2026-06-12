import 'package:freezed_annotation/freezed_annotation.dart';

part 'poi_rating.freezed.dart';
part 'poi_rating.g.dart';

enum RatingReason {
  @JsonValue('inaccurate') inaccurate,
  @JsonValue('too_short') tooShort,
  @JsonValue('boring') boring,
  @JsonValue('wrong_lang') wrongLang,
  @JsonValue('other') other,
}

const _reasonToDb = {
  RatingReason.inaccurate: 'inaccurate',
  RatingReason.tooShort: 'too_short',
  RatingReason.boring: 'boring',
  RatingReason.wrongLang: 'wrong_lang',
  RatingReason.other: 'other',
};

String? ratingReasonToString(RatingReason? r) =>
    r != null ? _reasonToDb[r] : null;

RatingReason? ratingReasonFromString(String? s) =>
    s != null
        ? _reasonToDb.entries
            .where((e) => e.value == s)
            .map((e) => e.key)
            .firstOrNull
        : null;

@freezed
class PoiRating with _$PoiRating {
  const factory PoiRating({
    required String id,
    @JsonKey(name: 'poi_id') required String poiId,
    @JsonKey(name: 'user_id') String? userId,
    @JsonKey(name: 'device_id') String? deviceId,
    required int rating,
    RatingReason? reason,
    @JsonKey(name: 'lang_code') required String langCode,
    @JsonKey(name: 'created_at') required DateTime createdAt,
  }) = _PoiRating;

  factory PoiRating.fromJson(Map<String, dynamic> json) =>
      _$PoiRatingFromJson(json);
}
