import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../constants/app_constants.dart';

class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();

  /// Called when the user taps a local notification, with its payload (a POI id
  /// for geofence alerts). Wired by the app bootstrapper to navigate.
  static void Function(String payload)? onSelect;

  static Future<void> initialize() async {
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    await _plugin.initialize(
      settings,
      onDidReceiveNotificationResponse: _onResponse,
    );

    // Create notification channel for Android
    const channel = AndroidNotificationChannel(
      AppConstants.notificationChannelId,
      'POI Nearby',
      description: 'Notifications when you are near a point of interest',
      importance: Importance.high,
    );
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  static void _onResponse(NotificationResponse response) {
    final payload = response.payload;
    if (payload != null && payload.isNotEmpty) {
      try {
        onSelect?.call(payload);
      } catch (e) {
        debugPrint('Notification tap handler failed: $e');
      }
    }
  }

  static Future<void> showPoiNearby({
    required int id,
    required String poiName,
    String? body,
    String? payload,
  }) async {
    await _plugin.show(
      id,
      poiName,
      body ?? 'You are near this point of interest',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          AppConstants.notificationChannelId,
          'POI Nearby',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      payload: payload,
    );
  }
}
