import 'package:flutter_test/flutter_test.dart';
import 'package:placesecrets/domain/models/poi_review.dart';

void main() {
  group('PoiReview.fromJson', () {
    test('parses the get_poi_reviews RPC shape', () {
      final r = PoiReview.fromJson({
        'review_id': 'rev-1',
        'rating': 5,
        'comment': 'Loved it!',
        'is_hidden': false,
        'created_at': '2026-01-15T10:00:00Z',
        'display_name': 'jane',
        'total_count': 7,
        'is_own': true,
      });

      expect(r.reviewId, 'rev-1');
      expect(r.rating, 5);
      expect(r.comment, 'Loved it!');
      expect(r.isHidden, isFalse);
      expect(r.displayName, 'jane');
      expect(r.totalCount, 7);
      expect(r.isOwn, isTrue);
      expect(r.createdAt.year, 2026);
    });

    test('hidden review has null comment and defaults applied', () {
      final r = PoiReview.fromJson({
        'review_id': 'rev-2',
        'rating': 1,
        'comment': null,
        'is_hidden': true,
        'created_at': '2026-02-01T00:00:00Z',
        'display_name': null,
        'total_count': null,
        'is_own': null,
      });

      expect(r.comment, isNull);
      expect(r.isHidden, isTrue);
      expect(r.displayName, 'Anonymous');
      expect(r.totalCount, 0);
      expect(r.isOwn, isFalse);
    });
  });
}
