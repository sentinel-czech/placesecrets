import 'package:flutter_test/flutter_test.dart';
import 'package:herodots/domain/models/contributor_profile.dart';

ContributorProfile _makeProfile({
  double? avgRating,
  int totalRatings = 0,
}) {
  return ContributorProfile(
    id: 'cp-1',
    userId: 'u-1',
    displayName: 'John',
    avgRating: avgRating,
    totalRatings: totalRatings,
    createdAt: DateTime(2025, 1, 1),
  );
}

void main() {
  group('ContributorProfile.ratingLabel', () {
    test('shows formatted label when ratings exist', () {
      final p = _makeProfile(avgRating: 4.5, totalRatings: 10);
      expect(p.ratingLabel, '4.5 \u2605 (10 ratings)');
    });

    test('shows No ratings when avgRating is null', () {
      final p = _makeProfile(avgRating: null, totalRatings: 5);
      expect(p.ratingLabel, 'No ratings');
    });

    test('shows No ratings when totalRatings is 0', () {
      final p = _makeProfile(avgRating: 4.0, totalRatings: 0);
      expect(p.ratingLabel, 'No ratings');
    });

    test('shows No ratings when both null/zero', () {
      final p = _makeProfile(avgRating: null, totalRatings: 0);
      expect(p.ratingLabel, 'No ratings');
    });

    test('formats to one decimal place', () {
      final p = _makeProfile(avgRating: 3.333, totalRatings: 1);
      expect(p.ratingLabel, '3.3 \u2605 (1 ratings)');
    });
  });
}
