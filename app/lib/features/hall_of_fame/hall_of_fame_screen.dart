import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../domain/models/contributor_profile.dart';
import 'hall_of_fame_provider.dart';

class HallOfFameScreen extends ConsumerWidget {
  final String cityId;
  const HallOfFameScreen({required this.cityId, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hofAsync = ref.watch(hallOfFameProvider(cityId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Hall of Fame'),
        backgroundColor: const Color(0xFF2D6A4F),
        foregroundColor: Colors.white,
      ),
      body: hofAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) {
          debugPrint('HoF load error: $err');
          return const Center(child: Text('Failed to load rankings'));
        },
        data: (entries) => entries.isEmpty
            ? const _EmptyHoF()
            : ListView(
                children: [
                  const _HoFHeader(),
                  if (entries.length >= 3)
                    _PodiumWidget(entries: entries.take(3).toList()),
                  const Divider(height: 32),
                  ...entries.skip(3).map((e) => _HoFListTile(entry: e)),
                  const SizedBox(height: 24),
                  const _ScoringInfoWidget(),
                ],
              ),
      ),
    );
  }
}

class _HoFHeader extends StatelessWidget {
  const _HoFHeader();

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              const Icon(Icons.emoji_events, size: 28, color: Color(0xFFB8960C)),
              const SizedBox(width: 8),
              Text(
                'Hall of Fame',
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
            ]),
            const SizedBox(height: 4),
            Text(
              'Top 10 guides rated by visitors',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: Colors.grey[600]),
            ),
          ],
        ),
      );
}

class _PodiumWidget extends StatelessWidget {
  final List<HallOfFameEntry> entries;

  const _PodiumWidget({required this.entries});

  @override
  Widget build(BuildContext context) {
    final order = [entries[1], entries[0], entries[2]];
    final heights = [80.0, 110.0, 60.0];
    final medals = [
      const Icon(Icons.workspace_premium, color: Colors.grey, size: 22),
      const Icon(Icons.workspace_premium, color: Color(0xFFB8960C), size: 26),
      const Icon(Icons.workspace_premium, color: Color(0xFFCD7F32), size: 20),
    ];
    final ranks = [2, 1, 3];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(
          3,
          (i) => Expanded(
            child: Column(children: [
              CircleAvatar(
                radius: ranks[i] == 1 ? 32 : 24,
                backgroundImage: order[i].avatarUrl != null
                    ? NetworkImage(order[i].avatarUrl!)
                    : null,
                child: order[i].avatarUrl == null
                    ? Text(
                        order[i].displayName.isNotEmpty
                            ? order[i].displayName[0].toUpperCase()
                            : '?',
                        style: TextStyle(fontSize: ranks[i] == 1 ? 22 : 16),
                      )
                    : null,
              ),
              const SizedBox(height: 4),
              medals[i],
              Text(
                order[i].displayName,
                style: Theme.of(context).textTheme.labelSmall,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                '${order[i].cityAvgRating?.toStringAsFixed(1) ?? '\u2013'}\u2605',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: const Color(0xFFB8960C),
                    ),
              ),
              const SizedBox(height: 4),
              Container(
                height: heights[i],
                decoration: BoxDecoration(
                  color: [
                    Colors.grey[400]!,
                    const Color(0xFFB8960C),
                    const Color(0xFFCD7F32),
                  ][i],
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(4),
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  '#${ranks[i]}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}

class _HoFListTile extends StatelessWidget {
  final HallOfFameEntry entry;
  const _HoFListTile({required this.entry});

  @override
  Widget build(BuildContext context) => ListTile(
        leading: Stack(
          children: [
            CircleAvatar(
              backgroundImage: entry.avatarUrl != null
                  ? NetworkImage(entry.avatarUrl!)
                  : null,
              child: entry.avatarUrl == null
                  ? Text(entry.displayName.isNotEmpty
                      ? entry.displayName[0].toUpperCase()
                      : '?')
                  : null,
            ),
            if (entry.isVerified)
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                  child:
                      const Icon(Icons.check, size: 9, color: Colors.white),
                ),
              ),
          ],
        ),
        title: Text(
          entry.displayName,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          '${entry.cityPoiCount} places \u00b7 '
          '${entry.cityAvgRating?.toStringAsFixed(1) ?? '\u2013'}\u2605 '
          '(${entry.cityTotalRatings} ratings)',
        ),
        trailing: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.center,
          child: Text(
            '#${entry.rank}',
            style:
                const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
        ),
      );
}

class _ScoringInfoWidget extends StatelessWidget {
  const _ScoringInfoWidget();

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.all(16),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context)
                .colorScheme
                .surfaceContainerHighest
                .withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'How does the ranking work?',
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const SizedBox(height: 6),
              Text(
                'The score combines average rating and number of votes. '
                'A guide needs at least 10 ratings to enter the ranking.',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      );
}

class _EmptyHoF extends StatelessWidget {
  const _EmptyHoF();

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.emoji_events_outlined,
                  size: 48, color: Colors.grey),
              const SizedBox(height: 16),
              Text(
                'The ranking is empty',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'Guides will appear after they collect at least 10 ratings from visitors.',
                textAlign: TextAlign.center,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: Colors.grey),
              ),
            ],
          ),
        ),
      );
}
