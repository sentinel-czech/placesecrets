import 'dart:io';

import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';

/// Caches POI audio files on device so they play offline after the first online
/// playback. Files live under `<app-docs>/audio_cache/` keyed by a deterministic
/// hash of the URL (stable across app launches, unlike `String.hashCode`).
class AudioCacheService {
  final Dio _dio;
  AudioCacheService([Dio? dio]) : _dio = dio ?? Dio();

  /// Deterministic, launch-stable filename for a URL (FNV-ish rolling hash +
  /// original extension). Pure — unit-testable.
  static String fileNameFor(String url) {
    var h = 0;
    for (final c in url.codeUnits) {
      h = (h * 31 + c) & 0x7fffffff;
    }
    final ext = _extensionOf(url);
    return '${h.toRadixString(16)}$ext';
  }

  static String _extensionOf(String url) {
    final path = Uri.tryParse(url)?.path ?? url;
    final dot = path.lastIndexOf('.');
    if (dot < 0 || dot < path.length - 6) return '.mp3';
    return path.substring(dot);
  }

  Future<Directory> _cacheDir() async {
    final base = await getApplicationDocumentsDirectory();
    final dir = Directory('${base.path}/audio_cache');
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  Future<File> _fileFor(String url) async =>
      File('${(await _cacheDir()).path}/${fileNameFor(url)}');

  /// Returns the local path if the audio is already cached, else null.
  Future<String?> cachedPath(String url) async {
    final f = await _fileFor(url);
    return await f.exists() ? f.path : null;
  }

  /// Downloads and caches the audio (no-op if already cached). Returns the local
  /// path, or null on failure (offline / network error) — never throws.
  Future<String?> ensureCached(String url) async {
    try {
      final f = await _fileFor(url);
      if (await f.exists()) return f.path;
      // Download to a temp file then rename, so a failed download leaves no
      // half-written cache entry.
      final tmp = File('${f.path}.part');
      await _dio.download(url, tmp.path);
      await tmp.rename(f.path);
      return f.path;
    } catch (_) {
      return null;
    }
  }
}
