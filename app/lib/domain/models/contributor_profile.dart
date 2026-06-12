import 'package:freezed_annotation/freezed_annotation.dart';

part 'contributor_profile.freezed.dart';
part 'contributor_profile.g.dart';

@freezed
class ContributorProfile with _$ContributorProfile {
  const ContributorProfile._();

  const factory ContributorProfile({
    required String id,
    @JsonKey(name: 'user_id') required String userId,
    @JsonKey(name: 'display_name') required String displayName,
    String? bio,
    @JsonKey(name: 'avatar_url') String? avatarUrl,
    @JsonKey(name: 'website_url') String? websiteUrl,
    @Default([]) List<String> specializations,
    @JsonKey(name: 'total_pois') @Default(0) int totalPois,
    @JsonKey(name: 'avg_rating') double? avgRating,
    @JsonKey(name: 'total_ratings') @Default(0) int totalRatings,
    @JsonKey(name: 'is_verified') @Default(false) bool isVerified,
    @JsonKey(name: 'is_active') @Default(true) bool isActive,
    @JsonKey(name: 'created_at') required DateTime createdAt,
  }) = _ContributorProfile;

  factory ContributorProfile.fromJson(Map<String, dynamic> json) =>
      _$ContributorProfileFromJson(json);

  String get ratingLabel {
    if (avgRating == null || totalRatings == 0) return 'No ratings';
    return '${avgRating!.toStringAsFixed(1)} \u2605 ($totalRatings ratings)';
  }
}

@freezed
class HallOfFameEntry with _$HallOfFameEntry {
  const factory HallOfFameEntry({
    required int rank,
    @JsonKey(name: 'contributor_id') required String contributorId,
    @JsonKey(name: 'display_name') required String displayName,
    @JsonKey(name: 'avatar_url') String? avatarUrl,
    @JsonKey(name: 'is_verified') @Default(false) bool isVerified,
    @JsonKey(name: 'city_poi_count') required int cityPoiCount,
    @JsonKey(name: 'city_avg_rating') double? cityAvgRating,
    @JsonKey(name: 'city_total_ratings') required int cityTotalRatings,
    @JsonKey(name: 'hof_score') double? hofScore,
    @JsonKey(name: 'sample_poi_names')
    @Default([])
    List<Map<String, dynamic>> samplePoiNames,
  }) = _HallOfFameEntry;

  factory HallOfFameEntry.fromJson(Map<String, dynamic> json) =>
      _$HallOfFameEntryFromJson(json);
}
