import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';

import '../../data/local/app_database.dart';
import 'providers/history_providers.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(visitHistoryProvider);
    final statsAsync = ref.watch(travelStatsProvider);
    final theme = Theme.of(context);
    final dateFormat = DateFormat('MMM d, yyyy HH:mm');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Visit History'),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            tooltip: 'Export Travel Log',
            onPressed: () => context.push('/export'),
          ),
        ],
      ),
      body: Column(
        children: [
          // Stats header
          statsAsync.when(
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
            data: (stats) => Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _StatBadge(
                    icon: Icons.place,
                    value: '${stats.totalVisits}',
                    label: 'Places',
                  ),
                  _StatBadge(
                    icon: Icons.location_city,
                    value: '${stats.citiesExplored}',
                    label: 'Cities',
                  ),
                  _StatBadge(
                    icon: Icons.edit_note,
                    value: '${stats.notesWritten}',
                    label: 'Notes',
                  ),
                  _StatBadge(
                    icon: Icons.camera_alt,
                    value: '${stats.photosTaken}',
                    label: 'Photos',
                  ),
                ],
              ),
            ),
          ),

          const Divider(height: 1),

          // Visit list
          Expanded(
            child: historyAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (visits) {
                if (visits.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.explore_outlined,
                            size: 64,
                            color: theme.colorScheme.outline),
                        const SizedBox(height: 16),
                        Text(
                          'No visits yet',
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Start exploring to build your travel log!',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: visits.length,
                  itemBuilder: (context, index) {
                    final visit = visits[index];
                    return _VisitTile(
                      visit: visit,
                      dateFormat: dateFormat,
                      onTap: () => context.push('/poi/${visit.poiId}'),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _StatBadge extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _StatBadge({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: theme.colorScheme.primary),
        const SizedBox(height: 4),
        Text(value,
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.bold)),
        Text(label, style: theme.textTheme.bodySmall),
      ],
    );
  }
}

class _VisitTile extends StatelessWidget {
  final VisitedPoi visit;
  final DateFormat dateFormat;
  final VoidCallback onTap;

  const _VisitTile({
    required this.visit,
    required this.dateFormat,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: theme.colorScheme.primaryContainer,
        child: Icon(Icons.place, color: theme.colorScheme.primary),
      ),
      title: Text(visit.poiName),
      subtitle: Text(dateFormat.format(visit.visitedAt)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (visit.userNote != null && visit.userNote!.isNotEmpty)
            Icon(Icons.note, size: 16, color: theme.colorScheme.outline),
          if (visit.userPhotoPath != null && visit.userPhotoPath!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 4),
              child: Icon(Icons.photo, size: 16,
                  color: theme.colorScheme.outline),
            ),
          const Icon(Icons.chevron_right),
        ],
      ),
      onTap: onTap,
    );
  }
}
