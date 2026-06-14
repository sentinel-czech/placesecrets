import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'notification_service.dart';

/// Wires Firebase Cloud Messaging end-to-end: permission, token registration
/// (persisted to `user_profiles.fcm_token`, migration 0454), and message
/// handlers for foreground / background-tap / cold-start-tap.
///
/// Only started when Firebase is available (see `firebaseAvailableProvider`).
/// Every step is guarded so a messaging failure never crashes the app.
class FcmService {
  final SupabaseClient _supabase;

  /// Called when the user taps a notification. The message data may carry a
  /// `link` (full deep-link URI) or a `poi_id`; the coordinator decides routing.
  final void Function(RemoteMessage message) onMessageTap;

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  StreamSubscription<RemoteMessage>? _onMessageSub;
  StreamSubscription<RemoteMessage>? _onOpenedSub;
  StreamSubscription<String>? _tokenRefreshSub;

  FcmService(this._supabase, {required this.onMessageTap});

  Future<void> start() async {
    try {
      await _messaging.requestPermission();
      // Show heads-up notifications while in foreground on iOS.
      await _messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      await _registerToken();
      _tokenRefreshSub = _messaging.onTokenRefresh.listen(_saveToken);

      _onMessageSub = FirebaseMessaging.onMessage.listen(_onForegroundMessage);
      _onOpenedSub = FirebaseMessaging.onMessageOpenedApp.listen(onMessageTap);

      // App opened from terminated state by tapping a notification.
      final initial = await _messaging.getInitialMessage();
      if (initial != null) onMessageTap(initial);
    } catch (e) {
      debugPrint('FCM start failed: $e');
    }
  }

  Future<void> _registerToken() async {
    try {
      final token = await _messaging.getToken();
      if (token != null) await _saveToken(token);
    } catch (e) {
      debugPrint('FCM getToken failed: $e');
    }
  }

  Future<void> _saveToken(String token) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;
    try {
      await _supabase.from('user_profiles').upsert(
        {
          'user_id': user.id,
          'fcm_token': token,
          'fcm_token_updated_at': DateTime.now().toUtc().toIso8601String(),
        },
        onConflict: 'user_id',
      );
    } catch (e) {
      debugPrint('FCM token save failed: $e');
    }
  }

  /// Foreground messages don't auto-display on Android — surface them as a
  /// local notification so they're not silently dropped.
  Future<void> _onForegroundMessage(RemoteMessage message) async {
    final n = message.notification;
    if (n == null) return;
    try {
      await NotificationService.showPoiNearby(
        id: message.hashCode,
        poiName: n.title ?? 'PlaceSecrets',
        body: n.body,
      );
    } catch (e) {
      debugPrint('FCM foreground display failed: $e');
    }
  }

  void dispose() {
    _onMessageSub?.cancel();
    _onOpenedSub?.cancel();
    _tokenRefreshSub?.cancel();
  }
}
