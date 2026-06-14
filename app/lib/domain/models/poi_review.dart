/// A single review row returned by the `get_poi_reviews` RPC (migration 0442).
///
/// `comment` is NULL when the review is hidden by moderation; `isOwn` marks the
/// signed-in user's own review (sorted first by the RPC). `totalCount` is the
/// window count over the full result set, used for "load more" pagination.
class PoiReview {
  final String reviewId;
  final int rating;
  final String? comment;
  final bool isHidden;
  final DateTime createdAt;
  final String displayName;
  final int totalCount;
  final bool isOwn;

  const PoiReview({
    required this.reviewId,
    required this.rating,
    this.comment,
    this.isHidden = false,
    required this.createdAt,
    this.displayName = 'Anonymous',
    this.totalCount = 0,
    this.isOwn = false,
  });

  factory PoiReview.fromJson(Map<String, dynamic> json) => PoiReview(
        reviewId: json['review_id'] as String,
        rating: (json['rating'] as num?)?.toInt() ?? 0,
        comment: json['comment'] as String?,
        isHidden: json['is_hidden'] as bool? ?? false,
        createdAt: DateTime.parse(json['created_at'] as String),
        displayName: json['display_name'] as String? ?? 'Anonymous',
        totalCount: (json['total_count'] as num?)?.toInt() ?? 0,
        isOwn: json['is_own'] as bool? ?? false,
      );
}
