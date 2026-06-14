import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';

import 'deep_link_handler.dart';

/// Listens for incoming deep links (cold-start and while running) and routes
/// them through [DeepLinkHandler]. Handles both the custom `placesecrets://`
/// scheme and `https://placesecrets.app/...` App Links.
///
/// Resilient by design: any platform error is logged and swallowed so a deep
/// link problem never crashes the app.
class DeepLinkService {
  final DeepLinkHandler handler;
  final AppLinks _appLinks;
  StreamSubscription<Uri>? _sub;

  DeepLinkService(this.handler, {AppLinks? appLinks})
      : _appLinks = appLinks ?? AppLinks();

  Future<void> start() async {
    // Cold start: the link that launched the app, if any.
    try {
      final initial = await _appLinks.getInitialLink();
      if (initial != null) {
        handler.handle(initial);
      }
    } catch (e) {
      debugPrint('Deep link (initial) failed: $e');
    }

    // Warm: links delivered while the app is already running.
    _sub = _appLinks.uriLinkStream.listen(
      (uri) {
        try {
          handler.handle(uri);
        } catch (e) {
          debugPrint('Deep link handling failed for $uri: $e');
        }
      },
      onError: (Object e) => debugPrint('Deep link stream error: $e'),
    );
  }

  void dispose() {
    _sub?.cancel();
    _sub = null;
  }
}
