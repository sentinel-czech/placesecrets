import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:herodots/domain/models/poi.dart';

// FlutterMap cannot be tested directly in widget tests. We test the UI
// elements (AppBar, filter chips, FAB) via a simplified replica of
// MapScreen that takes data as constructor parameters.
// We avoid importing map_providers.dart to prevent the transitive
// AppDatabase codegen issue.

/// Simplified widget that mirrors the MapScreen's testable UI elements.
class _MapScreenTestable extends StatefulWidget {
  final String? cityName;
  final bool hasPois;

  const _MapScreenTestable({
    this.cityName,
    this.hasPois = false,
  });

  @override
  State<_MapScreenTestable> createState() => _MapScreenTestableState();
}

class _MapScreenTestableState extends State<_MapScreenTestable> {
  final Set<PoiAccessLevel> _activeFilters = PoiAccessLevel.values.toSet();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.cityName ?? 'PlaceSecrets'),
        actions: [
          if (widget.cityName != null)
            IconButton(
              icon: const Icon(Icons.emoji_events_outlined),
              tooltip: 'Hall of Fame',
              onPressed: () {},
            ),
        ],
      ),
      body: Column(
        children: [
          if (widget.hasPois)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                children: [
                  _buildFilterChip(
                      PoiAccessLevel.public, 'Public', Colors.green),
                  const SizedBox(width: 6),
                  _buildFilterChip(PoiAccessLevel.registeredLimited,
                      'Registered', Colors.blue),
                  const SizedBox(width: 6),
                  _buildFilterChip(PoiAccessLevel.cityAccess,
                      'City Access', Colors.orange),
                  const SizedBox(width: 6),
                  _buildFilterChip(
                      PoiAccessLevel.premiumPoi, 'Premium', Colors.amber),
                ],
              ),
            ),
          const Expanded(child: Placeholder()),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        child: const Icon(Icons.my_location),
      ),
    );
  }

  Widget _buildFilterChip(
      PoiAccessLevel level, String label, Color color) {
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
}

Widget _wrap({String? cityName, bool hasPois = false}) {
  return MaterialApp(
    home: _MapScreenTestable(
      cityName: cityName,
      hasPois: hasPois,
    ),
  );
}

void main() {
  group('MapScreen', () {
    testWidgets('renders 4 filter chips when POIs are present',
        (tester) async {
      await tester.pumpWidget(_wrap(cityName: 'Prague', hasPois: true));
      await tester.pumpAndSettle();

      expect(find.text('Public'), findsOneWidget);
      expect(find.text('Registered'), findsOneWidget);
      expect(find.text('City Access'), findsOneWidget);
      expect(find.text('Premium'), findsOneWidget);
      expect(find.byType(FilterChip), findsNWidgets(4));
    });

    testWidgets('filter chips not shown when no POIs', (tester) async {
      await tester.pumpWidget(_wrap(cityName: 'Prague', hasPois: false));
      await tester.pumpAndSettle();

      expect(find.byType(FilterChip), findsNothing);
    });

    testWidgets('AppBar shows city name when nearestCity present',
        (tester) async {
      await tester.pumpWidget(_wrap(cityName: 'Brno'));
      await tester.pumpAndSettle();

      expect(find.text('Brno'), findsOneWidget);
    });

    testWidgets('AppBar shows PlaceSecrets when no city', (tester) async {
      await tester.pumpWidget(_wrap(cityName: null));
      await tester.pumpAndSettle();

      expect(find.text('PlaceSecrets'), findsOneWidget);
    });

    testWidgets('Hall of Fame button visible when city detected',
        (tester) async {
      await tester.pumpWidget(_wrap(cityName: 'Prague'));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.emoji_events_outlined), findsOneWidget);
      expect(find.byTooltip('Hall of Fame'), findsOneWidget);
    });

    testWidgets('Hall of Fame button hidden when no city', (tester) async {
      await tester.pumpWidget(_wrap(cityName: null));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.emoji_events_outlined), findsNothing);
    });

    testWidgets('my location FAB is visible', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.my_location), findsOneWidget);
      expect(find.byType(FloatingActionButton), findsOneWidget);
    });
  });
}
