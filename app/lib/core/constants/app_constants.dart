abstract class AppConstants {
  static const appId = 'cz.tuma.herodots';

  // Notifications
  static const notificationChannelId = 'cz.tuma.herodots.poi_nearby';
  static const audioChannelId = 'cz.tuma.herodots.audio';

  // Map
  static const defaultZoom = 14.0;
  static const poiLoadRadiusKm = 50.0;
  static const osmTileUrl = 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
  static const osmAttribution = '\u00a9 OpenStreetMap contributors';

  // Geofencing
  static const maxActiveGeofences = 100;
  static const defaultGeofenceRadiusMeters = 100.0;

  // Free limit
  static const freePoiPerMonth = 1;

  // Audio
  static const defaultAudioLanguage = 'en';
  static const defaultTtsSpeechRate = 0.85;

  // SharedPreferences keys
  static const prefAudioLanguage = 'pref_audio_language';
  static const prefGeofenceRadius = 'pref_geofence_radius';
  static const prefNotificationsEnabled = 'pref_notifications_enabled';
  static const prefDeviceId = 'pref_device_id';
  static const prefOnboardingDone = 'pref_onboarding_done';

  // Local photo storage
  static const privatePhotosDir = 'herodots/photos';
}
