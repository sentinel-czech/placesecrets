/// Lightweight place result returned by the `search_pois` RPC.
///
/// Mirrors the reduced column set of that function (name/perex/photo_urls are
/// JSONB; avg_rating NUMERIC, total_ratings INTEGER) rather than the full
/// `pois` row, so it is intentionally separate from [Poi].
class PlaceSummary {
  final String id;
  final Map<String, String> name;
  final String? slug;
  final Map<String, String> perex;
  final String accessLevel;
  final double? avgRating;
  final int totalRatings;
  final List<String> photoUrls;
  final String? citySlug;
  final String? countryCode;

  const PlaceSummary({
    required this.id,
    required this.name,
    this.slug,
    this.perex = const {},
    this.accessLevel = 'city_access',
    this.avgRating,
    this.totalRatings = 0,
    this.photoUrls = const [],
    this.citySlug,
    this.countryCode,
  });

  factory PlaceSummary.fromJson(Map<String, dynamic> json) => PlaceSummary(
        id: json['id'] as String,
        name: _localizedMap(json['name']),
        slug: json['slug'] as String?,
        perex: _localizedMap(json['perex']),
        accessLevel: json['access_level'] as String? ?? 'city_access',
        avgRating: (json['avg_rating'] as num?)?.toDouble(),
        totalRatings: (json['total_ratings'] as num?)?.toInt() ?? 0,
        photoUrls: (json['photo_urls'] as List?)
                ?.map((e) => e.toString())
                .toList() ??
            const [],
        citySlug: json['city_slug'] as String?,
        countryCode: json['country_code'] as String?,
      );

  String localizedName(String langCode) =>
      name[langCode] ?? name['en'] ?? (name.isNotEmpty ? name.values.first : '');

  String? localizedPerex(String langCode) =>
      perex[langCode] ?? perex['en'] ?? (perex.isNotEmpty ? perex.values.first : null);

  String? get thumbnailUrl => photoUrls.isNotEmpty ? photoUrls.first : null;

  String? get ratingBadge => avgRating != null && totalRatings >= 5
      ? '${avgRating!.toStringAsFixed(1)}★'
      : null;

  /// Accepts either a localized JSON object or a bare string (legacy rows).
  static Map<String, String> _localizedMap(dynamic value) {
    if (value is Map) {
      return value.map((k, v) => MapEntry(k.toString(), v?.toString() ?? ''));
    }
    if (value is String && value.isNotEmpty) {
      return {'en': value};
    }
    return const {};
  }
}
