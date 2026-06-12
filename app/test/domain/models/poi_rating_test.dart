import 'package:flutter_test/flutter_test.dart';
import 'package:herodots/domain/models/poi_rating.dart';

void main() {
  group('ratingReasonToString', () {
    test('maps all enum values correctly', () {
      expect(ratingReasonToString(RatingReason.inaccurate), 'inaccurate');
      expect(ratingReasonToString(RatingReason.tooShort), 'too_short');
      expect(ratingReasonToString(RatingReason.boring), 'boring');
      expect(ratingReasonToString(RatingReason.wrongLang), 'wrong_lang');
      expect(ratingReasonToString(RatingReason.other), 'other');
    });

    test('returns null for null input', () {
      expect(ratingReasonToString(null), null);
    });
  });

  group('ratingReasonFromString', () {
    test('maps all valid strings correctly', () {
      expect(ratingReasonFromString('inaccurate'), RatingReason.inaccurate);
      expect(ratingReasonFromString('too_short'), RatingReason.tooShort);
      expect(ratingReasonFromString('boring'), RatingReason.boring);
      expect(ratingReasonFromString('wrong_lang'), RatingReason.wrongLang);
      expect(ratingReasonFromString('other'), RatingReason.other);
    });

    test('returns null for invalid string', () {
      expect(ratingReasonFromString('invalid'), null);
      expect(ratingReasonFromString(''), null);
      expect(ratingReasonFromString('INACCURATE'), null);
    });

    test('returns null for null input', () {
      expect(ratingReasonFromString(null), null);
    });
  });

  group('round-trip', () {
    test('toStr then fromStr returns same enum for all values', () {
      for (final reason in RatingReason.values) {
        final str = ratingReasonToString(reason);
        final back = ratingReasonFromString(str);
        expect(back, reason, reason: 'Round-trip failed for $reason');
      }
    });
  });
}
