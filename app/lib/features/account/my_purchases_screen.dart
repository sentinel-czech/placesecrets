import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../poi_detail/providers/poi_access_provider.dart';

class MyPurchasesScreen extends ConsumerWidget {
  const MyPurchasesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final purchasedPois = ref.watch(purchasedPoiIdsProvider);
    final purchasedBundles = ref.watch(purchasedCityBundleIdsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('My Purchases')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // POI purchases
          Text('Individual Places', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          purchasedPois.when(
            data: (poiIds) {
              if (poiIds.isEmpty) {
                return const Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('No individual purchases yet'),
                  ),
                );
              }
              return Column(
                children: poiIds
                    .map((id) => Card(
                          child: ListTile(
                            leading: const Icon(Icons.place),
                            title: Text('Place $id'),
                            subtitle: const Text('Premium content unlocked'),
                          ),
                        ))
                    .toList(),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text('Error: $e'),
          ),

          const SizedBox(height: 24),

          // City bundle purchases
          Text('City Bundles', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          purchasedBundles.when(
            data: (cityIds) {
              if (cityIds.isEmpty) {
                return const Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('No city bundles purchased'),
                  ),
                );
              }
              return Column(
                children: cityIds
                    .map((id) => Card(
                          child: ListTile(
                            leading: const Icon(Icons.location_city),
                            title: Text('City bundle $id'),
                            subtitle:
                                const Text('All premium content unlocked'),
                          ),
                        ))
                    .toList(),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text('Error: $e'),
          ),
        ],
      ),
    );
  }
}
