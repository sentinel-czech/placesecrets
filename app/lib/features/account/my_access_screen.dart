import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'providers/entitlements_provider.dart';

/// "My Access" — shows the user's entitlements (free quota + owned POIs,
/// cities, city bundles and countries) from `get_my_entitlements()`.
class MyAccessScreen extends ConsumerWidget {
  const MyAccessScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final langCode = Localizations.localeOf(context).languageCode;
    final async = ref.watch(myEntitlementsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('My access')),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) {
          debugPrint('Entitlements load error: $err');
          return const Center(child: Text('Failed to load your access'));
        },
        data: (data) {
          if (data.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text(
                  'Sign in to see what you own and your free quota.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(myEntitlementsProvider),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _FreeQuotaCard(free: data['free'] as Map?),
                const SizedBox(height: 16),
                _EntitlementSection(
                  title: 'Purchased places',
                  icon: Icons.place,
                  items: (data['pois'] as List? ?? [])
                      .map((e) => _localized(
                          (e as Map)['name'], langCode))
                      .toList(),
                  emptyLabel: 'No individual places purchased.',
                ),
                _EntitlementSection(
                  title: 'City access',
                  icon: Icons.location_city,
                  items: (data['cities'] as List? ?? [])
                      .map((e) => (e as Map)['name']?.toString() ?? '—')
                      .toList(),
                  emptyLabel: 'No city access.',
                ),
                _EntitlementSection(
                  title: 'City bundles',
                  icon: Icons.workspace_premium,
                  items: (data['city_bundles'] as List? ?? [])
                      .map((e) => (e as Map)['name']?.toString() ?? '—')
                      .toList(),
                  emptyLabel: 'No city bundles.',
                ),
                _EntitlementSection(
                  title: 'Countries',
                  icon: Icons.public,
                  items: (data['countries'] as List? ?? [])
                      .map((e) =>
                          (e as Map)['country_code']?.toString().toUpperCase() ??
                          '—')
                      .toList(),
                  emptyLabel: 'No country access.',
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  static String _localized(dynamic name, String langCode) {
    if (name is Map) {
      final fallback = name.values.isNotEmpty ? name.values.first : '—';
      return (name[langCode] ?? name['en'] ?? fallback).toString();
    }
    return name?.toString() ?? '—';
  }
}

class _FreeQuotaCard extends StatelessWidget {
  final Map? free;
  const _FreeQuotaCard({required this.free});

  @override
  Widget build(BuildContext context) {
    final used = (free?['used'] as num?)?.toInt() ?? 0;
    final limit = (free?['limit'] as num?)?.toInt() ?? 1;
    final period = free?['period']?.toString() ?? 'month';
    final remaining = (limit - used).clamp(0, limit);
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.card_giftcard, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text('Free quota', style: theme.textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 8),
            Text('$remaining of $limit free place(s) left this $period'),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: limit == 0 ? 0 : used / limit,
              minHeight: 6,
            ),
          ],
        ),
      ),
    );
  }
}

class _EntitlementSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<String> items;
  final String emptyLabel;

  const _EntitlementSection({
    required this.title,
    required this.icon,
    required this.items,
    required this.emptyLabel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(0, 12, 0, 4),
            child: Row(
              children: [
                Icon(icon, size: 18, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(title, style: theme.textTheme.labelLarge),
                const SizedBox(width: 8),
                if (items.isNotEmpty)
                  Text('(${items.length})',
                      style: theme.textTheme.labelSmall
                          ?.copyWith(color: Colors.grey)),
              ],
            ),
          ),
          if (items.isEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 26, bottom: 4),
              child: Text(emptyLabel,
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: Colors.grey[600])),
            )
          else
            ...items.map((label) => Padding(
                  padding: const EdgeInsets.only(left: 26, top: 2, bottom: 2),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle,
                          size: 16, color: Color(0xFF2D6A4F)),
                      const SizedBox(width: 8),
                      Expanded(
                          child: Text(label,
                              maxLines: 1, overflow: TextOverflow.ellipsis)),
                    ],
                  ),
                )),
        ],
      ),
    );
  }
}
