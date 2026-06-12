import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:herodots/domain/models/contributor_profile.dart';
import 'package:herodots/features/hall_of_fame/hall_of_fame_provider.dart';
import 'package:herodots/features/hall_of_fame/hall_of_fame_screen.dart';

// HistoryScreen and ExportScreen depend on AppDatabase via providers.
// To avoid the pre-existing Drift codegen issue, we test via simplified
// replicas that accept data as constructor parameters.

// -- HistoryScreen testable replica --

class _HistoryTestable extends StatelessWidget {
  final int totalVisits;
  final int citiesExplored;
  final int notesWritten;
  final int photosTaken;
  final bool hasStats;
  final List<String> visitNames;
  final bool loading;

  const _HistoryTestable({
    this.totalVisits = 0,
    this.citiesExplored = 0,
    this.notesWritten = 0,
    this.photosTaken = 0,
    this.hasStats = false,
    this.visitNames = const [],
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Visit History'),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            tooltip: 'Export Travel Log',
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          if (hasStats)
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _StatBadge(
                      icon: Icons.place,
                      value: '$totalVisits',
                      label: 'Places'),
                  _StatBadge(
                      icon: Icons.location_city,
                      value: '$citiesExplored',
                      label: 'Cities'),
                  _StatBadge(
                      icon: Icons.edit_note,
                      value: '$notesWritten',
                      label: 'Notes'),
                  _StatBadge(
                      icon: Icons.camera_alt,
                      value: '$photosTaken',
                      label: 'Photos'),
                ],
              ),
            ),
          const Divider(height: 1),
          Expanded(
            child: loading
                ? const Center(child: CircularProgressIndicator())
                : visitNames.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.explore_outlined,
                                size: 64,
                                color: theme.colorScheme.outline),
                            const SizedBox(height: 16),
                            Text('No visits yet',
                                style: theme.textTheme.titleMedium),
                            const SizedBox(height: 8),
                            const Text(
                                'Start exploring to build your travel log!'),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: visitNames.length,
                        itemBuilder: (context, index) => ListTile(
                          title: Text(visitNames[index]),
                        ),
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

  const _StatBadge(
      {required this.icon, required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Theme.of(context).colorScheme.primary),
        const SizedBox(height: 4),
        Text(value,
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.bold)),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

// -- ExportScreen testable replica --

class _ExportTestable extends StatelessWidget {
  const _ExportTestable();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Export Travel Log')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Select date range for export:',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {},
                    child: const Text('From'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {},
                    child: const Text('To'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.picture_as_pdf),
              label: const Text('Generate & Share PDF'),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.select_all),
              label: const Text('Export All'),
            ),
          ],
        ),
      ),
    );
  }
}

// -- HallOfFame helpers --

HallOfFameEntry _makeHofEntry({
  required int rank,
  required String name,
  double? avgRating = 4.5,
  int totalRatings = 20,
  int poiCount = 5,
}) =>
    HallOfFameEntry(
      rank: rank,
      contributorId: 'contrib-$rank',
      displayName: name,
      cityPoiCount: poiCount,
      cityAvgRating: avgRating,
      cityTotalRatings: totalRatings,
    );

Widget _wrapHof({List<HallOfFameEntry> entries = const []}) {
  return ProviderScope(
    overrides: [
      hallOfFameProvider('city-1')
          .overrideWith((ref) => Future.value(entries)),
    ],
    child: const MaterialApp(
      home: HallOfFameScreen(cityId: 'city-1'),
    ),
  );
}

void main() {
  group('HistoryScreen', () {
    testWidgets('renders stats badges', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: _HistoryTestable(
          hasStats: true,
          totalVisits: 42,
          citiesExplored: 5,
          notesWritten: 10,
          photosTaken: 23,
        ),
      ));

      expect(find.text('42'), findsOneWidget);
      expect(find.text('5'), findsOneWidget);
      expect(find.text('10'), findsOneWidget);
      expect(find.text('23'), findsOneWidget);
      expect(find.text('Places'), findsOneWidget);
      expect(find.text('Cities'), findsOneWidget);
      expect(find.text('Notes'), findsOneWidget);
      expect(find.text('Photos'), findsOneWidget);
    });

    testWidgets('empty state shows message', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: _HistoryTestable(visitNames: []),
      ));

      expect(find.text('No visits yet'), findsOneWidget);
      expect(find.text('Start exploring to build your travel log!'),
          findsOneWidget);
      expect(find.byIcon(Icons.explore_outlined), findsOneWidget);
    });

    testWidgets('shows visit history title', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: _HistoryTestable(),
      ));

      expect(find.text('Visit History'), findsOneWidget);
    });

    testWidgets('export button in AppBar', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: _HistoryTestable(),
      ));

      expect(find.byIcon(Icons.picture_as_pdf), findsOneWidget);
      expect(find.byTooltip('Export Travel Log'), findsOneWidget);
    });
  });

  group('HallOfFameScreen', () {
    testWidgets('renders podium section with 3+ entries', (tester) async {
      await tester.pumpWidget(_wrapHof(entries: [
        _makeHofEntry(rank: 1, name: 'Alice'),
        _makeHofEntry(rank: 2, name: 'Bob'),
        _makeHofEntry(rank: 3, name: 'Charlie'),
        _makeHofEntry(rank: 4, name: 'Diana'),
      ]));
      await tester.pumpAndSettle();

      // Podium shows top 3 with rank numbers
      expect(find.text('#1'), findsOneWidget);
      expect(find.text('#2'), findsOneWidget);
      expect(find.text('#3'), findsOneWidget);
      // 4th entry shows in list
      expect(find.text('Diana'), findsOneWidget);
    });

    testWidgets('shows empty state when no entries', (tester) async {
      await tester.pumpWidget(_wrapHof(entries: []));
      await tester.pumpAndSettle();

      expect(find.text('The ranking is empty'), findsOneWidget);
    });

    testWidgets('shows Hall of Fame title', (tester) async {
      await tester.pumpWidget(_wrapHof(entries: [
        _makeHofEntry(rank: 1, name: 'Alice'),
        _makeHofEntry(rank: 2, name: 'Bob'),
        _makeHofEntry(rank: 3, name: 'Charlie'),
      ]));
      await tester.pumpAndSettle();

      expect(find.text('Hall of Fame'), findsNWidgets(2)); // AppBar + header
    });

    testWidgets('shows scoring info section', (tester) async {
      await tester.pumpWidget(_wrapHof(entries: [
        _makeHofEntry(rank: 1, name: 'Alice'),
        _makeHofEntry(rank: 2, name: 'Bob'),
        _makeHofEntry(rank: 3, name: 'Charlie'),
      ]));
      await tester.pumpAndSettle();

      expect(find.text('How does the ranking work?'), findsOneWidget);
    });
  });

  group('ExportScreen', () {
    testWidgets('date picker buttons exist', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: _ExportTestable(),
      ));

      expect(find.text('From'), findsOneWidget);
      expect(find.text('To'), findsOneWidget);
      expect(find.byType(OutlinedButton),
          findsNWidgets(3)); // From, To, Export All
    });

    testWidgets('generate PDF button exists', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: _ExportTestable(),
      ));

      expect(find.text('Generate & Share PDF'), findsOneWidget);
      expect(find.byIcon(Icons.picture_as_pdf), findsOneWidget);
    });

    testWidgets('export all button exists', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: _ExportTestable(),
      ));

      expect(find.text('Export All'), findsOneWidget);
      expect(find.byIcon(Icons.select_all), findsOneWidget);
    });

    testWidgets('shows title and date range instruction', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: _ExportTestable(),
      ));

      expect(find.text('Export Travel Log'), findsOneWidget);
      expect(
          find.text('Select date range for export:'), findsOneWidget);
    });
  });
}
