import 'dart:async';

import 'package:just_audio/just_audio.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../constants/app_constants.dart';
import 'audio_cache_service.dart';

enum AudioSource { file, tts, none }

class AudioGuideService {
  final AudioPlayer _player = AudioPlayer();
  final FlutterTts _tts = FlutterTts();
  final AudioCacheService _cache = AudioCacheService();

  AudioSource _currentSource = AudioSource.none;
  bool _ttsPlaying = false;
  // Last TTS request, kept so resume() can restart it (flutter_tts has no
  // reliable resume-from-position across platforms).
  String? _lastTtsText;
  String _lastTtsLang = 'en';
  final _ttsCompletionController = StreamController<void>.broadcast();

  AudioSource get currentSource => _currentSource;
  bool get isPlaying => _player.playing || _ttsPlaying;

  Stream<bool> get playingStream => _player.playingStream.map((playing) {
        if (_currentSource == AudioSource.tts) return _ttsPlaying;
        return playing;
      });

  Stream<Duration> get positionStream => _player.positionStream;

  Duration? get duration => _player.duration;
  Duration get position => _player.position;

  Stream<void> get onTtsComplete => _ttsCompletionController.stream;

  Stream<PlayerState> get playerStateStream => _player.playerStateStream;

  Future<void> init() async {
    _tts.setCompletionHandler(() {
      _ttsPlaying = false;
      _ttsCompletionController.add(null);
    });

    _tts.setCancelHandler(() {
      _ttsPlaying = false;
    });

    _tts.setErrorHandler((msg) {
      _ttsPlaying = false;
    });
  }

  Future<void> playGuide({
    String? audioUrl,
    String? ttsText,
    String lang = 'en',
  }) async {
    await stop();

    if (audioUrl != null && audioUrl.isNotEmpty) {
      await playAudioFile(audioUrl);
    } else if (ttsText != null && ttsText.isNotEmpty) {
      await playTts(ttsText, lang: lang);
    }
  }

  Future<void> playAudioFile(String url) async {
    _currentSource = AudioSource.file;
    // Prefer a cached local copy (offline playback); otherwise stream and cache
    // in the background for next time.
    final cached = await _cache.cachedPath(url);
    if (cached != null) {
      await _player.setFilePath(cached);
    } else {
      await _player.setUrl(url);
      unawaited(_cache.ensureCached(url));
    }
    await _player.play();
  }

  Future<void> playTts(String text, {String lang = 'en'}) async {
    _currentSource = AudioSource.tts;
    _ttsPlaying = true;
    _lastTtsText = text;
    _lastTtsLang = lang;
    await _tts.setLanguage(lang);
    await _tts.setSpeechRate(AppConstants.defaultTtsSpeechRate);
    await _tts.speak(text);
  }

  Future<void> pause() async {
    if (_currentSource == AudioSource.file) {
      await _player.pause();
    } else if (_currentSource == AudioSource.tts) {
      await _tts.pause();
      _ttsPlaying = false;
    }
  }

  Future<void> resume() async {
    if (_currentSource == AudioSource.file) {
      await _player.play();
    } else if (_currentSource == AudioSource.tts && _lastTtsText != null) {
      // flutter_tts can't resume mid-utterance reliably — restart playback.
      _ttsPlaying = true;
      await _tts.setLanguage(_lastTtsLang);
      await _tts.setSpeechRate(AppConstants.defaultTtsSpeechRate);
      await _tts.speak(_lastTtsText!);
    }
  }

  Future<void> stop() async {
    _currentSource = AudioSource.none;
    _ttsPlaying = false;
    await _player.stop();
    await _tts.stop();
  }

  Future<void> seek(Duration position) async {
    if (_currentSource == AudioSource.file) {
      await _player.seek(position);
    }
  }

  Future<void> dispose() async {
    await _ttsCompletionController.close();
    await _player.dispose();
  }
}
