import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../app/providers.dart';
import '../../../core/services/location_service.dart';
import '../../../data/repositories/city_repository.dart';
import '../../../data/repositories/poi_repository.dart';
import '../../../domain/models/city.dart';
import '../../../domain/models/poi.dart';

part 'map_providers.g.dart';

@riverpod
class UserLocation extends _$UserLocation {
  StreamSubscription<Position>? _sub;

  @override
  AsyncValue<LatLng> build() {
    _startListening();
    ref.onDispose(() => _sub?.cancel());
    return const AsyncValue.loading();
  }

  void _startListening() {
    final service = LocationService();
    _sub = service.getPositionStream().listen(
      (pos) {
        state = AsyncValue.data(LatLng(pos.latitude, pos.longitude));
      },
      onError: (e) {
        state = AsyncValue.error(e, StackTrace.current);
      },
    );
  }

  Future<void> requestCurrent() async {
    try {
      final service = LocationService();
      final pos = await service.getCurrentPosition();
      state = AsyncValue.data(LatLng(pos.latitude, pos.longitude));
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

@riverpod
class SelectedCity extends _$SelectedCity {
  @override
  City? build() => null;

  void select(City city) => state = city;
  void clear() => state = null;
}

@riverpod
class SelectedPoi extends _$SelectedPoi {
  @override
  Poi? build() => null;

  void select(Poi poi) => state = poi;
  void clear() => state = null;
}

@riverpod
Future<List<City>> activeCities(ActiveCitiesRef ref) async {
  final repo = CityRepository(Supabase.instance.client);
  return repo.fetchActiveCities();
}

@riverpod
Future<List<Poi>> cityPois(CityPoisRef ref, String cityId) async {
  final repo = PoiRepository(
    Supabase.instance.client,
    ref.watch(appDatabaseProvider),
  );
  return repo.fetchPoisForCity(cityId);
}

@riverpod
City? nearestCity(NearestCityRef ref) {
  final locationValue = ref.watch(userLocationProvider);
  final citiesValue = ref.watch(activeCitiesProvider);

  final location = locationValue.valueOrNull;
  final cities = citiesValue.valueOrNull;
  if (location == null || cities == null || cities.isEmpty) return null;

  City? nearest;
  double minDist = double.infinity;
  const distCalc = Distance();

  for (final city in cities) {
    final dist = distCalc.as(
      LengthUnit.Kilometer,
      location,
      LatLng(city.latitude, city.longitude),
    );
    if (dist < minDist) {
      minDist = dist;
      nearest = city;
    }
  }

  if (nearest != null && minDist <= nearest.boundingBoxRadiusKm) {
    return nearest;
  }
  return null;
}
