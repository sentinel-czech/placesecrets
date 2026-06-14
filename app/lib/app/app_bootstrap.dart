import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/constants/app_constants.dart';
import '../core/services/fcm_service.dart';
import '../core/services/geofence_service.dart';
import '../core/services/notification_service.dart';
import '../core/services/sync_service.dart';
import '../main.dart' show firebaseAvailableProvider;
import 'providers.dart';
import 'deep_link_handler.dart';
import 'deep_link_service.dart';
import 'router.dart';

/// Wraps the app and wires the runtime integrations that were previously written
/// but never started: deep links, offline sync, geofencing and FCM. Every step
/// is guarded — a failure in one integration must not affect the others or the
/// app itself.
///
/// Runtime behavior (geofence triggers, FCM delivery, deep-link callbacks)
/// requires a real device and cannot be exercised by `flutter test`.
class AppBootstrapper extends ConsumerStatefulWidget {
  final Widget child;
  const AppBootstrapper({required this.child, super.key});

  @override
  ConsumerState<AppBootstrapper> createState() => _AppBootstrapperState();
}

class _AppBootstrapperState extends ConsumerState<AppBootstrapper> {
  DeepLinkService? _deepLinks;
  SyncService? _sync;
  GeofenceService? _geofence;
  FcmService? _fcm;
  bool _started = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _start());
  }

  Future<void> _start() async {
    if (_started || !mounted) return;
    _started = true;

    final router = ref.read(routerProvider);
    final supabase = Supabase.instance.client;
    final handler = DeepLinkHandler(router: router, ref: ref);

    // 1. Deep links (purchase callbacks + shared place URLs).
    try {
      _deepLinks = DeepLinkService(handler);
      await _deepLinks!.start();
    } catch (e) {
      debugPrint('Deep link wiring failed: $e');
    }

    // Local-notification taps (geofence alerts) navigate to the POI.
    NotificationService.onSelect = (poiId) => router.go('/poi/$poiId');

    // 2. Offline sync (push local ratings, pull POIs when connectivity returns).
    try {
      _sync = SyncService(supabase, ref.read(appDatabaseProvider))
        ..startListening();
      unawaited(_sync!.syncAll());
    } catch (e) {
      debugPrint('Sync wiring failed: $e');
    }

    // 3. Geofencing — only if location permission is already granted; the
    //    onboarding flow is responsible for requesting it (no launch-time prompt).
    await _startGeofencingIfPermitted(supabase);

    // 4. FCM — only when Firebase initialized successfully this session.
    if (ref.read(firebaseAvailableProvider)) {
      try {
        _fcm = FcmService(
          supabase,
          onMessageTap: (m) => _onFcmTap(handler, router, m),
        );
        await _fcm!.start();
      } catch (e) {
        debugPrint('FCM wiring failed: $e');
      }
    }
  }

  Future<void> _startGeofencingIfPermitted(SupabaseClient supabase) async {
    try {
      final permission = await Geolocator.checkPermission();
      final granted = permission == LocationPermission.always ||
          permission == LocationPermission.whileInUse;
      if (!granted) return;

      final geofence = GeofenceService();
      geofence.onPoiEntered =
          (poiId) => _onGeofenceEnter(supabase, poiId);
      await geofence.initialize();
      await geofence.start();
      await _registerActivePois(supabase, geofence);
      _geofence = geofence;
    } catch (e) {
      debugPrint('Geofencing wiring failed: $e');
    }
  }

  Future<void> _registerActivePois(
      SupabaseClient supabase, GeofenceService geofence) async {
    final response = await supabase
        .from('pois')
        .select('id, latitude, longitude, geofence_radius')
        .eq('is_active', true);
    final list = (response as List? ?? []).map((e) {
      final m = e as Map<String, dynamic>;
      return PoiGeofence(
        poiId: m['id'] as String,
        latitude: (m['latitude'] as num).toDouble(),
        longitude: (m['longitude'] as num).toDouble(),
        radius: (m['geofence_radius'] as num?)?.toDouble() ??
            AppConstants.defaultGeofenceRadiusMeters,
      );
    }).toList();
    await geofence.registerPois(list);
  }

  Future<void> _onGeofenceEnter(SupabaseClient supabase, String poiId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (!(prefs.getBool(AppConstants.prefNotificationsEnabled) ?? true)) {
        return;
      }
      final data = await supabase
          .from('pois')
          .select('name')
          .eq('id', poiId)
          .maybeSingle();
      final name = _localizedName(data?['name']);
      await NotificationService.showPoiNearby(
        id: poiId.hashCode,
        poiName: name,
        body: 'You are near a point of interest. Tap to listen.',
        payload: poiId,
      );
    } catch (e) {
      debugPrint('Geofence enter handling failed: $e');
    }
  }

  void _onFcmTap(DeepLinkHandler handler, GoRouter router, RemoteMessage m) {
    final link = m.data['link'];
    if (link is String && link.isNotEmpty) {
      final uri = Uri.tryParse(link);
      if (uri != null && handler.handle(uri)) return;
    }
    final poiId = m.data['poi_id'];
    if (poiId is String && poiId.isNotEmpty) {
      router.go('/poi/$poiId');
    }
  }

  String _localizedName(dynamic name) {
    if (name is Map) {
      final fallback = name.values.isNotEmpty ? name.values.first : 'PlaceSecrets';
      return (name['en'] ?? fallback).toString();
    }
    return name?.toString() ?? 'PlaceSecrets';
  }

  @override
  void dispose() {
    _deepLinks?.dispose();
    _sync?.dispose();
    _geofence?.dispose();
    _fcm?.dispose();
    NotificationService.onSelect = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
