import 'package:flutter/foundation.dart';
import 'package:flutter_background_geolocation/flutter_background_geolocation.dart'
    as bg;

import '../constants/app_constants.dart';

typedef GeofenceCallback = void Function(String poiId);

class GeofenceService {
  GeofenceCallback? onPoiEntered;
  GeofenceCallback? onPoiExited;
  bool _ready = false;

  Future<void> initialize() async {
    if (_ready) return;

    await bg.BackgroundGeolocation.ready(bg.Config(
      desiredAccuracy: bg.Config.DESIRED_ACCURACY_HIGH,
      distanceFilter: 10.0,
      stopOnTerminate: false,
      startOnBoot: true,
      enableHeadless: true,
      geofenceProximityRadius: 1000,
      geofenceInitialTriggerEntry: true,
      debug: false,
      logLevel: bg.Config.LOG_LEVEL_OFF,
      notification: bg.Notification(
        title: 'PlaceSecrets',
        text: 'Detecting nearby points of interest',
        channelName: 'Location tracking',
      ),
    ));

    bg.BackgroundGeolocation.onGeofence(_onGeofence);
    _ready = true;
  }

  Future<void> start() async {
    if (!_ready) await initialize();
    await bg.BackgroundGeolocation.start();
    await bg.BackgroundGeolocation.startGeofences();
  }

  Future<void> stop() async {
    await bg.BackgroundGeolocation.stop();
  }

  Future<void> registerPois(List<PoiGeofence> pois) async {
    await bg.BackgroundGeolocation.removeGeofences();

    final geofences = pois
        .take(AppConstants.maxActiveGeofences)
        .map((poi) => bg.Geofence(
              identifier: poi.poiId,
              radius: poi.radius,
              latitude: poi.latitude,
              longitude: poi.longitude,
              notifyOnEntry: true,
              notifyOnExit: true,
              notifyOnDwell: false,
            ))
        .toList();

    for (final gf in geofences) {
      await bg.BackgroundGeolocation.addGeofence(gf);
    }

    debugPrint('GeofenceService: registered ${geofences.length} geofences');
  }

  void _onGeofence(bg.GeofenceEvent event) {
    final poiId = event.identifier;
    if (event.action == 'ENTER') {
      debugPrint('GeofenceService: entered POI $poiId');
      onPoiEntered?.call(poiId);
    } else if (event.action == 'EXIT') {
      debugPrint('GeofenceService: exited POI $poiId');
      onPoiExited?.call(poiId);
    }
  }

  Future<bg.Location> getCurrentLocation() async {
    return bg.BackgroundGeolocation.getCurrentPosition();
  }

  void dispose() {
    // Callback-based API — no subscriptions to cancel
  }
}

class PoiGeofence {
  final String poiId;
  final double latitude;
  final double longitude;
  final double radius;

  const PoiGeofence({
    required this.poiId,
    required this.latitude,
    required this.longitude,
    this.radius = AppConstants.defaultGeofenceRadiusMeters,
  });
}
