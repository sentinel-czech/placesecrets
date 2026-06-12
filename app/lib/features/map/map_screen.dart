import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../core/constants/app_constants.dart';
import '../../domain/models/poi.dart';
import 'providers/map_providers.dart';
import 'widgets/poi_bottom_sheet.dart';

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  final MapController _mapController = MapController();
  final Set<PoiAccessLevel> _activeFilters = PoiAccessLevel.values.toSet();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(userLocationProvider.notifier).requestCurrent();
    });
  }

  @override
  Widget build(BuildContext context) {
    final userLocation = ref.watch(userLocationProvider);
    final nearestCity = ref.watch(nearestCityProvider);
    final selectedPoi = ref.watch(selectedPoiProvider);

    final cityId = nearestCity?.id;
    final poisAsync = cityId != null
        ? ref.watch(cityPoisProvider(cityId))
        : const AsyncValue<List<Poi>>.data([]);

    final allPois = poisAsync.valueOrNull ?? [];
    final pois = allPois
        .where((p) => _activeFilters.contains(p.accessLevelEnum))
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(nearestCity?.name ?? 'PlaceSecrets'),
        actions: [
          if (nearestCity != null)
            IconButton(
              icon: const Icon(Icons.emoji_events_outlined),
              tooltip: 'Hall of Fame',
              onPressed: () =>
                  context.push('/hall-of-fame/${nearestCity.id}'),
            ),
        ],
      ),
      body: Column(
        children: [
          // Filter chips
          if (allPois.isNotEmpty)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                children: [
                  _buildFilterChip(
                      PoiAccessLevel.public, 'Public', Colors.green),
                  const SizedBox(width: 6),
                  _buildFilterChip(PoiAccessLevel.registeredLimited,
                      'Registered', Colors.blue),
                  const SizedBox(width: 6),
                  _buildFilterChip(PoiAccessLevel.cityAccess, 'City Access',
                      Colors.orange),
                  const SizedBox(width: 6),
                  _buildFilterChip(
                      PoiAccessLevel.premiumPoi, 'Premium', Colors.amber),
                ],
              ),
            ),
          // Map
          Expanded(
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: userLocation.valueOrNull ??
                    const LatLng(49.7475, 13.3776),
                initialZoom: AppConstants.defaultZoom,
                onTap: (_, __) =>
                    ref.read(selectedPoiProvider.notifier).clear(),
              ),
              children: [
                TileLayer(
                  urlTemplate: AppConstants.osmTileUrl,
                  userAgentPackageName: AppConstants.appId,
                ),
                if (userLocation.hasValue)
                  MarkerLayer(markers: [
                    Marker(
                      point: userLocation.value!,
                      width: 20,
                      height: 20,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.blue.withAlpha(77),
                              blurRadius: 8,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ]),
                MarkerLayer(
                  markers: pois
                      .map((poi) => _buildPoiMarker(poi, context))
                      .toList(),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _centerOnUser,
        child: const Icon(Icons.my_location),
      ),
      bottomSheet: selectedPoi != null
          ? PoiBottomSheet(
              poi: selectedPoi,
              onClose: () => ref.read(selectedPoiProvider.notifier).clear(),
              onOpen: () => context.push('/poi/${selectedPoi.id}'),
            )
          : null,
    );
  }

  Widget _buildFilterChip(PoiAccessLevel level, String label, Color color) {
    final active = _activeFilters.contains(level);
    return FilterChip(
      label: Text(label, style: const TextStyle(fontSize: 12)),
      selected: active,
      onSelected: (selected) {
        setState(() {
          if (selected) {
            _activeFilters.add(level);
          } else {
            _activeFilters.remove(level);
          }
        });
      },
      selectedColor: color.withAlpha(51),
      checkmarkColor: color,
      side: BorderSide(color: active ? color : Colors.grey.shade300),
      visualDensity: VisualDensity.compact,
    );
  }

  Color _markerColorForAccessLevel(PoiAccessLevel level) {
    switch (level) {
      case PoiAccessLevel.public:
        return Colors.green;
      case PoiAccessLevel.registeredLimited:
        return Colors.blue;
      case PoiAccessLevel.cityAccess:
        return Colors.orange;
      case PoiAccessLevel.premiumPoi:
        return Colors.amber.shade700;
    }
  }

  Marker _buildPoiMarker(Poi poi, BuildContext context) {
    final color = _markerColorForAccessLevel(poi.accessLevelEnum);
    final isPremium = poi.accessLevelEnum == PoiAccessLevel.premiumPoi;

    return Marker(
      point: LatLng(poi.latitude, poi.longitude),
      width: 40,
      height: 48,
      child: GestureDetector(
        onTap: () => ref.read(selectedPoiProvider.notifier).select(poi),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                Icon(Icons.location_on, color: color, size: 32),
                if (isPremium)
                  const Positioned(
                    bottom: 6,
                    child: Icon(Icons.lock, size: 10, color: Colors.white),
                  ),
              ],
            ),
            if (poi.ratingBadge != null)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
                decoration: BoxDecoration(
                  color: Colors.amber,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  poi.ratingBadge!,
                  style: const TextStyle(
                      fontSize: 8, fontWeight: FontWeight.bold),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _centerOnUser() async {
    await ref.read(userLocationProvider.notifier).requestCurrent();
    final location = ref.read(userLocationProvider).valueOrNull;
    if (location != null) {
      _mapController.move(location, AppConstants.defaultZoom);
    }
  }
}
