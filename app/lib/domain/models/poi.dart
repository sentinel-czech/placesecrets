import 'package:freezed_annotation/freezed_annotation.dart';

import 'contributor_profile.dart';

part 'poi.freezed.dart';
part 'poi.g.dart';

enum PoiAccessLevel {
  public,
  registeredLimited,
  cityAccess,
  premiumPoi;

  static PoiAccessLevel fromString(String? value) {
    switch (value) {
      case 'public':
        return PoiAccessLevel.public;
      case 'registered_limited':
        return PoiAccessLevel.registeredLimited;
      case 'city_access':
        return PoiAccessLevel.cityAccess;
      case 'premium_poi':
        return PoiAccessLevel.premiumPoi;
      default:
        return PoiAccessLevel.cityAccess;
    }
  }

  String toDbString() {
    switch (this) {
      case PoiAccessLevel.public:
        return 'public';
      case PoiAccessLevel.registeredLimited:
        return 'registered_limited';
      case PoiAccessLevel.cityAccess:
        return 'city_access';
      case PoiAccessLevel.premiumPoi:
        return 'premium_poi';
    }
  }
}

Map<String, dynamic> _preprocessPoiJson(Map<String, dynamic> json) {
  final data = Map<String, dynamic>.from(json);
  if (data['cities'] is Map<String, dynamic>) {
    final cities = data['cities'] as Map<String, dynamic>;
    data['city_slug'] = cities['slug'];
    data['country_code'] = cities['country_code'];
  }
  return data;
}

@freezed
class Poi with _$Poi {
  const Poi._();

  const factory Poi({
    required String id,
    @JsonKey(name: 'city_id') required String cityId,
    @JsonKey(name: 'contributor_id') String? contributorId,
    @JsonKey(includeFromJson: false, includeToJson: false)
    ContributorProfile? contributor,
    @JsonKey(name: 'total_ratings') @Default(0) int totalRatings,
    @JsonKey(name: 'avg_rating') double? avgRating,
    required Map<String, String> name,
    required Map<String, String> description,
    required double latitude,
    required double longitude,
    @JsonKey(name: 'geofence_radius') @Default(100.0) double geofenceRadius,
    @JsonKey(name: 'photo_urls') @Default([]) List<String> photoUrls,
    @JsonKey(name: 'audio_urls') @Default({}) Map<String, String?> audioUrls,
    @JsonKey(name: 'is_premium') @Default(true) bool isPremium,
    @JsonKey(name: 'created_at') required DateTime createdAt,
    String? slug,
    @JsonKey(name: 'access_level') @Default('city_access') String accessLevel,
    String? perex,
    @JsonKey(name: 'premium_price') double? premiumPrice,
    @JsonKey(name: 'city_slug') String? citySlug,
    @JsonKey(name: 'country_code') String? countryCode,
  }) = _Poi;

  factory Poi.fromJson(Map<String, dynamic> json) =>
      _$PoiFromJson(_preprocessPoiJson(json));

  PoiAccessLevel get accessLevelEnum => PoiAccessLevel.fromString(accessLevel);

  String localizedName(String langCode) =>
      name[langCode] ?? name['en'] ?? name.values.first;

  String localizedDescription(String langCode) =>
      description[langCode] ?? description['en'] ?? '';

  String? audioUrlForLang(String langCode) =>
      audioUrls[langCode] ?? audioUrls['en'];

  bool hasAudioFile(String langCode) => audioUrlForLang(langCode) != null;

  List<String> availableLanguages() {
    final langs = <String>{};
    langs.addAll(audioUrls.keys);
    langs.addAll(description.keys);
    return langs.toList();
  }

  String? get ratingBadge => avgRating != null && totalRatings >= 5
      ? '${avgRating!.toStringAsFixed(1)}\u2605'
      : null;

  bool get qualifiesForHoF => totalRatings >= 10;

  String? get smartUri =>
      (slug != null && citySlug != null && countryCode != null)
          ? '/${countryCode!.toLowerCase()}/$citySlug/$slug'
          : null;
}
