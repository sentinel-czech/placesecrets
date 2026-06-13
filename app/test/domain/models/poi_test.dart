import 'package:flutter_test/flutter_test.dart';
import 'package:placesecrets/domain/models/poi.dart';

Poi _makePoi({
  Map<String, String>? name,
  Map<String, String>? description,
  Map<String, String?>? audioUrls,
  int totalRatings = 0,
  double? avgRating,
  String? slug,
  String? citySlug,
  String? countryCode,
  String accessLevel = 'city_access',
  String? perex,
  double? premiumPrice,
}) {
  return Poi(
    id: 'poi-1',
    cityId: 'city-1',
    name: name ?? {'cs': 'Karlův most', 'en': 'Charles Bridge'},
    description:
        description ?? {'cs': 'Popis', 'en': 'Description'},
    latitude: 50.0,
    longitude: 14.0,
    createdAt: DateTime(2025, 1, 1),
    audioUrls: audioUrls ?? {},
    totalRatings: totalRatings,
    avgRating: avgRating,
    slug: slug,
    citySlug: citySlug,
    countryCode: countryCode,
    accessLevel: accessLevel,
    perex: perex,
    premiumPrice: premiumPrice,
  );
}

void main() {
  group('PoiAccessLevel', () {
    test('fromString parses all valid values', () {
      expect(PoiAccessLevel.fromString('public'), PoiAccessLevel.public);
      expect(PoiAccessLevel.fromString('registered_limited'),
          PoiAccessLevel.registeredLimited);
      expect(
          PoiAccessLevel.fromString('city_access'), PoiAccessLevel.cityAccess);
      expect(
          PoiAccessLevel.fromString('premium_poi'), PoiAccessLevel.premiumPoi);
    });

    test('fromString returns cityAccess for null', () {
      expect(PoiAccessLevel.fromString(null), PoiAccessLevel.cityAccess);
    });

    test('fromString returns cityAccess for invalid string', () {
      expect(PoiAccessLevel.fromString('invalid'), PoiAccessLevel.cityAccess);
      expect(PoiAccessLevel.fromString(''), PoiAccessLevel.cityAccess);
    });

    test('toDbString round-trips with fromString', () {
      for (final level in PoiAccessLevel.values) {
        final dbStr = level.toDbString();
        expect(PoiAccessLevel.fromString(dbStr), level,
            reason: 'Round-trip failed for $level');
      }
    });

    test('toDbString returns correct strings', () {
      expect(PoiAccessLevel.public.toDbString(), 'public');
      expect(PoiAccessLevel.registeredLimited.toDbString(),
          'registered_limited');
      expect(PoiAccessLevel.cityAccess.toDbString(), 'city_access');
      expect(PoiAccessLevel.premiumPoi.toDbString(), 'premium_poi');
    });
  });

  group('Poi.localizedName', () {
    test('returns requested language', () {
      final poi = _makePoi(name: {'cs': 'Most', 'en': 'Bridge'});
      expect(poi.localizedName('cs'), 'Most');
    });

    test('falls back to en when requested lang missing', () {
      final poi = _makePoi(name: {'cs': 'Most', 'en': 'Bridge'});
      expect(poi.localizedName('de'), 'Bridge');
    });

    test('falls back to first value when en also missing', () {
      final poi = _makePoi(name: {'cs': 'Most'});
      expect(poi.localizedName('de'), 'Most');
    });
  });

  group('Poi.localizedDescription', () {
    test('returns requested language', () {
      final poi = _makePoi(description: {'cs': 'Popis', 'en': 'Desc'});
      expect(poi.localizedDescription('cs'), 'Popis');
    });

    test('falls back to en', () {
      final poi = _makePoi(description: {'en': 'Desc'});
      expect(poi.localizedDescription('de'), 'Desc');
    });

    test('returns empty string when nothing matches', () {
      final poi = _makePoi(description: {'cs': 'Popis'});
      expect(poi.localizedDescription('de'), '');
    });
  });

  group('Poi.audioUrlForLang', () {
    test('returns url for requested language', () {
      final poi =
          _makePoi(audioUrls: {'cs': 'cs.mp3', 'en': 'en.mp3'});
      expect(poi.audioUrlForLang('cs'), 'cs.mp3');
    });

    test('falls back to en', () {
      final poi = _makePoi(audioUrls: {'en': 'en.mp3'});
      expect(poi.audioUrlForLang('de'), 'en.mp3');
    });

    test('returns null when nothing matches', () {
      final poi = _makePoi(audioUrls: {'cs': 'cs.mp3'});
      expect(poi.audioUrlForLang('de'), null);
    });

    test('returns null for empty audioUrls', () {
      final poi = _makePoi(audioUrls: {});
      expect(poi.audioUrlForLang('en'), null);
    });
  });

  group('Poi.hasAudioFile', () {
    test('true when audio exists for language', () {
      final poi = _makePoi(audioUrls: {'cs': 'cs.mp3'});
      expect(poi.hasAudioFile('cs'), true);
    });

    test('true via en fallback', () {
      final poi = _makePoi(audioUrls: {'en': 'en.mp3'});
      expect(poi.hasAudioFile('de'), true);
    });

    test('false when no audio', () {
      final poi = _makePoi(audioUrls: {});
      expect(poi.hasAudioFile('cs'), false);
    });
  });

  group('Poi.availableLanguages', () {
    test('unions audio and description keys', () {
      final poi = _makePoi(
        audioUrls: {'cs': 'a.mp3', 'de': 'b.mp3'},
        description: {'cs': 'P', 'en': 'D'},
      );
      final langs = poi.availableLanguages();
      expect(langs.toSet(), {'cs', 'de', 'en'});
    });

    test('empty when both are empty', () {
      final poi = _makePoi(audioUrls: {}, description: {});
      expect(poi.availableLanguages(), isEmpty);
    });
  });

  group('Poi.ratingBadge', () {
    test('returns formatted badge when threshold met', () {
      final poi = _makePoi(avgRating: 4.5, totalRatings: 10);
      expect(poi.ratingBadge, '4.5\u2605');
    });

    test('returns null when totalRatings < 5', () {
      final poi = _makePoi(avgRating: 5.0, totalRatings: 4);
      expect(poi.ratingBadge, null);
    });

    test('returns badge when totalRatings exactly 5', () {
      final poi = _makePoi(avgRating: 3.0, totalRatings: 5);
      expect(poi.ratingBadge, '3.0\u2605');
    });

    test('returns null when avgRating is null', () {
      final poi = _makePoi(avgRating: null, totalRatings: 100);
      expect(poi.ratingBadge, null);
    });
  });

  group('Poi.qualifiesForHoF', () {
    test('true when totalRatings >= 10', () {
      expect(_makePoi(totalRatings: 10).qualifiesForHoF, true);
      expect(_makePoi(totalRatings: 100).qualifiesForHoF, true);
    });

    test('false when totalRatings < 10', () {
      expect(_makePoi(totalRatings: 9).qualifiesForHoF, false);
      expect(_makePoi(totalRatings: 0).qualifiesForHoF, false);
    });
  });

  group('Poi.smartUri', () {
    test('returns path when all slugs and countryCode present', () {
      final poi = _makePoi(slug: 'bridge', citySlug: 'prague', countryCode: 'CZ');
      expect(poi.smartUri, '/cz/prague/bridge');
    });

    test('returns null when slug is null', () {
      final poi = _makePoi(slug: null, citySlug: 'prague', countryCode: 'CZ');
      expect(poi.smartUri, null);
    });

    test('returns null when citySlug is null', () {
      final poi = _makePoi(slug: 'bridge', citySlug: null, countryCode: 'CZ');
      expect(poi.smartUri, null);
    });

    test('returns null when countryCode is null', () {
      final poi = _makePoi(slug: 'bridge', citySlug: 'prague', countryCode: null);
      expect(poi.smartUri, null);
    });

    test('returns null when all null', () {
      final poi = _makePoi(slug: null, citySlug: null, countryCode: null);
      expect(poi.smartUri, null);
    });

    test('lowercases country code', () {
      final poi = _makePoi(slug: 'bridge', citySlug: 'prague', countryCode: 'CZ');
      expect(poi.smartUri, '/cz/prague/bridge');
    });

    test('handles special characters in slug', () {
      final poi = _makePoi(slug: 'café-bridge', citySlug: 'prague', countryCode: 'CZ');
      expect(poi.smartUri, '/cz/prague/café-bridge');
    });

    test('handles empty string slug (vs null)', () {
      final poi = _makePoi(slug: '', citySlug: 'prague', countryCode: 'CZ');
      expect(poi.smartUri, '/cz/prague/');
    });

    test('handles empty string citySlug (vs null)', () {
      final poi = _makePoi(slug: 'bridge', citySlug: '', countryCode: 'CZ');
      expect(poi.smartUri, '/cz//bridge');
    });
  });

  group('Poi.accessLevelEnum', () {
    test('matches accessLevel string', () {
      expect(_makePoi(accessLevel: 'public').accessLevelEnum,
          PoiAccessLevel.public);
      expect(_makePoi(accessLevel: 'premium_poi').accessLevelEnum,
          PoiAccessLevel.premiumPoi);
      expect(_makePoi(accessLevel: 'city_access').accessLevelEnum,
          PoiAccessLevel.cityAccess);
    });
  });

  group('Poi.fromJson', () {
    test('extracts citySlug and countryCode from nested cities object', () {
      final json = {
        'id': 'poi-1',
        'city_id': 'city-1',
        'name': {'cs': 'Most'},
        'description': {'en': 'Desc'},
        'latitude': 50.0,
        'longitude': 14.0,
        'created_at': '2025-01-01T00:00:00.000Z',
        'cities': {'slug': 'prague', 'name': 'Prague', 'country_code': 'CZ'},
      };
      final poi = Poi.fromJson(json);
      expect(poi.citySlug, 'prague');
      expect(poi.countryCode, 'CZ');
    });

    test('citySlug and countryCode are null when no cities object', () {
      final json = {
        'id': 'poi-1',
        'city_id': 'city-1',
        'name': {'cs': 'Most'},
        'description': {'en': 'Desc'},
        'latitude': 50.0,
        'longitude': 14.0,
        'created_at': '2025-01-01T00:00:00.000Z',
      };
      final poi = Poi.fromJson(json);
      expect(poi.citySlug, null);
    });

    test('default accessLevel is city_access', () {
      final json = {
        'id': 'poi-1',
        'city_id': 'city-1',
        'name': {'cs': 'Most'},
        'description': {},
        'latitude': 50.0,
        'longitude': 14.0,
        'created_at': '2025-01-01T00:00:00.000Z',
      };
      final poi = Poi.fromJson(json);
      expect(poi.accessLevel, 'city_access');
    });

    test('parses premium fields', () {
      final json = {
        'id': 'poi-1',
        'city_id': 'city-1',
        'name': {'en': 'Test'},
        'description': {},
        'latitude': 50.0,
        'longitude': 14.0,
        'created_at': '2025-01-01T00:00:00.000Z',
        'slug': 'test',
        'access_level': 'premium_poi',
        'perex': 'A short summary',
        'premium_price': 4.99,
      };
      final poi = Poi.fromJson(json);
      expect(poi.slug, 'test');
      expect(poi.accessLevel, 'premium_poi');
      expect(poi.perex, 'A short summary');
      expect(poi.premiumPrice, 4.99);
    });
  });
}
