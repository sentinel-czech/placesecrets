import 'package:flutter_test/flutter_test.dart';
import 'package:herodots/domain/models/poi_premium_content.dart';

void main() {
  group('PoiPremiumContent.fromJson', () {
    test('parses all fields', () {
      final json = {
        'id': 'pc-1',
        'poi_id': 'poi-1',
        'audio_url': 'https://cdn.example.com/premium.mp3',
        'text_content': 'Extended premium description.',
        'extra_photos': ['photo1.jpg', 'photo2.jpg'],
        'related_poi_ids': ['poi-2', 'poi-3'],
        'created_at': '2025-06-01T00:00:00.000Z',
        'updated_at': '2025-06-15T00:00:00.000Z',
      };
      final content = PoiPremiumContent.fromJson(json);
      expect(content.id, 'pc-1');
      expect(content.poiId, 'poi-1');
      expect(content.audioUrl, 'https://cdn.example.com/premium.mp3');
      expect(content.textContent, 'Extended premium description.');
      expect(content.extraPhotos, ['photo1.jpg', 'photo2.jpg']);
      expect(content.relatedPoiIds, ['poi-2', 'poi-3']);
    });

    test('defaults for lists are empty', () {
      final json = {
        'id': 'pc-2',
        'poi_id': 'poi-2',
      };
      final content = PoiPremiumContent.fromJson(json);
      expect(content.extraPhotos, isEmpty);
      expect(content.relatedPoiIds, isEmpty);
    });

    test('nullable fields parse as null', () {
      final json = {
        'id': 'pc-3',
        'poi_id': 'poi-3',
        'audio_url': null,
        'text_content': null,
      };
      final content = PoiPremiumContent.fromJson(json);
      expect(content.audioUrl, null);
      expect(content.textContent, null);
      expect(content.createdAt, null);
      expect(content.updatedAt, null);
    });
  });
}
