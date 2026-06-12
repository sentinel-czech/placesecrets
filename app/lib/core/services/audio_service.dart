import 'dart:async';

import 'package:just_audio/just_audio.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../constants/app_constants.dart';

enum AudioSource { file, tts, none }

class AudioGuideService {
  final AudioPlayer _player = AudioPlayer();
  final FlutterTts _tts = FlutterTts();

  AudioSource _currentSource = AudioSource.none;
  bool _ttsPlaying = false;
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
    await _player.setUrl(url);
    await _player.play();
  }

  Future<void> playTts(String text, {String lang = 'en'}) async {
    _currentSource = AudioSource.tts;
    _ttsPlaying = true;
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
    }
    // TTS cannot be resumed — must restart
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
