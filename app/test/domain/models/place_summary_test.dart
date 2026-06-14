import 'package:flutter_test/flutter_test.dart';
import 'package:placesecrets/domain/models/place_summary.dart';

void main() {
  group('PlaceSummary.fromJson', () {
    test('parses the search_pois RPC shape', () {
      final p = PlaceSummary.fromJson({
        'id': 'poi-1',
        'name': {'en': 'Old Town', 'cs': 'Staré Město'},
        'slug': 'old-town',
        'perex': {'en': 'A historic square.'},
        'access_level': 'public',
        'avg_rating': 4.5,
        'total_ratings': 12,
        'photo_urls': ['https://x/a.jpg', 'https://x/b.jpg'],
        'city_slug': 'prague',
        'country_code': 'CZ',
      });

      expect(p.id, 'poi-1');
      expect(p.localizedName('cs'), 'Staré Město');
      expect(p.localizedName('de'), 'Old Town'); // falls back to en
      expect(p.localizedPerex('en'), 'A historic square.');
      expect(p.avgRating, 4.5);
      expect(p.totalRatings, 12);
      expect(p.thumbnailUrl, 'https://x/a.jpg');
      expect(p.ratingBadge, '4.5★'); // >= 5 ratings
    });

    test('accepts a bare string for name/perex (legacy rows)', () {
      final p = PlaceSummary.fromJson({
        'id': 'poi-2',
        'name': 'Plain Name',
        'perex': 'Plain perex',
      });
      expect(p.localizedName('en'), 'Plain Name');
      expect(p.localizedPerex('en'), 'Plain perex');
    });

    test('handles nulls and missing fields with safe defaults', () {
      final p = PlaceSummary.fromJson({
        'id': 'poi-3',
        'name': {'en': 'X'},
      });
      expect(p.accessLevel, 'city_access');
      expect(p.totalRatings, 0);
      expect(p.photoUrls, isEmpty);
      expect(p.thumbnailUrl, isNull);
      expect(p.ratingBadge, isNull); // no avg rating
      expect(p.localizedPerex('en'), isNull);
    });

    test('no rating badge below 5 ratings', () {
      final p = PlaceSummary.fromJson({
        'id': 'poi-4',
        'name': {'en': 'X'},
        'avg_rating': 5.0,
        'total_ratings': 3,
      });
      expect(p.ratingBadge, isNull);
    });
  });
}
