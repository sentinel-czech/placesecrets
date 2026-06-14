import 'package:flutter_test/flutter_test.dart';
import 'package:placesecrets/core/services/audio_cache_service.dart';

void main() {
  group('AudioCacheService.fileNameFor', () {
    test('is deterministic for the same URL', () {
      const url = 'https://cdn.example.com/audio/prague/guide-en.mp3';
      expect(AudioCacheService.fileNameFor(url),
          AudioCacheService.fileNameFor(url));
    });

    test('differs for different URLs', () {
      expect(
        AudioCacheService.fileNameFor('https://x/a.mp3'),
        isNot(AudioCacheService.fileNameFor('https://x/b.mp3')),
      );
    });

    test('preserves the audio extension', () {
      expect(AudioCacheService.fileNameFor('https://x/a.m4a'), endsWith('.m4a'));
      expect(AudioCacheService.fileNameFor('https://x/a.mp3'), endsWith('.mp3'));
    });

    test('falls back to .mp3 when no extension', () {
      expect(AudioCacheService.fileNameFor('https://x/audio/stream'),
          endsWith('.mp3'));
    });

    test('ignores query strings when deriving extension', () {
      expect(AudioCacheService.fileNameFor('https://x/a.mp3?token=abc'),
          endsWith('.mp3'));
    });
  });
}
