import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

/// Background FCM handler. Must be a top-level function (runs in a separate
/// isolate). The OS renders the notification itself; we only ensure Firebase is
/// initialized so any plugin work in the isolate has a default app.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp();
  } catch (_) {
    // Nothing actionable in the background isolate; swallow to avoid a crash.
  }
}

/// Initializes Firebase resiliently.
///
/// Firebase/FCM is an **optional** capability (push notifications). Its absence
/// or misconfiguration (e.g. missing `google-services.json` /
/// `GoogleService-Info.plist` in a dev build) must never prevent the app from
/// starting — see the project rule "monitoring must not take the service down".
///
/// Returns `true` when Firebase is available so callers can decide whether to
/// wire FCM token registration and message handlers.
Future<bool> bootstrapFirebase() async {
  try {
    await Firebase.initializeApp();
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    return true;
  } catch (e) {
    debugPrint('Firebase unavailable — push notifications disabled: $e');
    return false;
  }
}
