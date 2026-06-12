import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../constants/app_constants.dart';

class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();

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
    await _plugin.initialize(settings);

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

  static Future<void> showPoiNearby({
    required int id,
    required String poiName,
    String? body,
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
    );
  }
}
