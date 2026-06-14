import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../data/repositories/ratings_repository.dart';
import '../../../domain/models/poi_review.dart';
import '../providers/ratings_provider.dart';

/// Read-only list of place reviews (ratings with a comment) via
/// `get_poi_reviews`. The first page comes from [poiReviewsProvider]; "Load
/// more" pages are fetched directly from the repository and accumulated here.
class PoiReviewsSection extends ConsumerStatefulWidget {
  final String poiId;
  const PoiReviewsSection({required this.poiId, super.key});

  @override
  ConsumerState<PoiReviewsSection> createState() => _PoiReviewsSectionState();
}

class _PoiReviewsSectionState extends ConsumerState<PoiReviewsSection> {
  static const _pageSize = 10;
  final List<PoiReview> _extra = [];
  bool _loadingMore = false;

  Future<void> _loadMore(int currentCount) async {
    setState(() => _loadingMore = true);
    try {
      final page = await ref.read(ratingsRepositoryProvider).getReviews(
            widget.poiId,
            limit: _pageSize,
            offset: currentCount,
          );
      if (mounted) setState(() => _extra.addAll(page));
    } catch (e) {
      debugPrint('Load more reviews failed: $e');
    } finally {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // When the first page is refreshed (e.g. after submitting a rating),
    // drop the accumulated extra pages so they don't duplicate/desync.
    ref.listen(poiReviewsProvider(widget.poiId), (_, __) {
      if (_extra.isNotEmpty) setState(() => _extra.clear());
    });

    final firstPage = ref.watch(poiReviewsProvider(widget.poiId));
    final theme = Theme.of(context);

    return firstPage.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (err, _) {
        debugPrint('Reviews load error: $err');
        return const SizedBox.shrink();
      },
      data: (first) {
        final total = first.isNotEmpty ? first.first.totalCount : 0;
        final reviews = [...first, ..._extra];

        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.reviews_outlined, size: 20),
                  const SizedBox(width: 8),
                  Text('Reviews', style: theme.textTheme.titleMedium),
                  if (total > 0) ...[
                    const SizedBox(width: 6),
                    Text('($total)',
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: Colors.grey[600])),
                  ],
                ],
              ),
              const SizedBox(height: 8),
              if (reviews.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    'No reviews yet. Be the first to share your experience.',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: Colors.grey[600]),
                  ),
                )
              else
                ...reviews.map((r) => _ReviewTile(review: r)),
              if (reviews.length < total)
                Align(
                  alignment: Alignment.center,
                  child: _loadingMore
                      ? const Padding(
                          padding: EdgeInsets.all(8),
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : TextButton(
                          onPressed: () => _loadMore(reviews.length),
                          child: const Text('Load more reviews'),
                        ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _ReviewTile extends StatelessWidget {
  final PoiReview review;
  const _ReviewTile({required this.review});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final name = review.isOwn ? 'Your review' : review.displayName;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 14,
                child: Text(
                  name.isNotEmpty ? name[0].toUpperCase() : '?',
                  style: const TextStyle(fontSize: 12),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  name,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: review.isOwn ? theme.colorScheme.primary : null,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                _formatDate(review.createdAt),
                style: theme.textTheme.labelSmall
                    ?.copyWith(color: Colors.grey[600]),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: List.generate(
              5,
              (i) => Icon(
                i < review.rating
                    ? Icons.star_rounded
                    : Icons.star_outline_rounded,
                size: 14,
                color: const Color(0xFFB8960C),
              ),
            ),
          ),
          if (review.isHidden)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                'This comment was hidden by a moderator.',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontStyle: FontStyle.italic,
                  color: Colors.grey[600],
                ),
              ),
            )
          else if (review.comment != null && review.comment!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(review.comment!, style: theme.textTheme.bodyMedium),
            ),
          const Divider(height: 16),
        ],
      ),
    );
  }

  String _formatDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}
