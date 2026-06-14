import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../map/providers/map_providers.dart';

/// Browseable catalog of active cities (web parity: city browsing, not just
/// nearest-city auto-detection). Tapping a city opens its list of places.
class CatalogScreen extends ConsumerWidget {
  const CatalogScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final citiesAsync = ref.watch(activeCitiesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Explore cities')),
      body: citiesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) {
          debugPrint('Catalog load error: $err');
          return const Center(child: Text('Failed to load cities'));
        },
        data: (cities) {
          if (cities.isEmpty) {
            return const Center(child: Text('No cities available yet.'));
          }
          return ListView.separated(
            itemCount: cities.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (_, i) {
              final city = cities[i];
              return ListTile(
                leading: const Icon(Icons.location_city),
                title: Text(city.name),
                subtitle: Text(city.country),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push(
                  '/catalog/${city.id}',
                  extra: city.name,
                ),
              );
            },
          );
        },
      ),
    );
  }
}
