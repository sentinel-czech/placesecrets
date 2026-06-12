import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:herodots/domain/models/poi.dart';
import 'package:herodots/features/poi_detail/widgets/share_poi_button.dart';

Poi _makePoi({String? slug, String? citySlug, String? countryCode}) => Poi(
      id: 'poi-1',
      cityId: 'city-1',
      name: const {'en': 'Charles Bridge'},
      description: const {'en': 'A famous bridge'},
      latitude: 50.0,
      longitude: 14.0,
      createdAt: DateTime(2025, 1, 1),
      slug: slug,
      citySlug: citySlug,
      countryCode: countryCode,
    );

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  group('SharePoiButton', () {
    testWidgets('renders IconButton when smartUri exists (slug + citySlug + countryCode not null)', (tester) async {
      final poi = _makePoi(slug: 'charles-bridge', citySlug: 'prague', countryCode: 'CZ');

      await tester.pumpWidget(_wrap(SharePoiButton(poi: poi)));

      expect(find.byType(IconButton), findsOneWidget);
      expect(find.byIcon(Icons.share), findsOneWidget);
    });

    testWidgets('hidden (SizedBox.shrink) when slug is null', (tester) async {
      final poi = _makePoi(slug: null, citySlug: 'prague', countryCode: 'CZ');

      await tester.pumpWidget(_wrap(SharePoiButton(poi: poi)));

      expect(find.byType(IconButton), findsNothing);
      expect(find.byIcon(Icons.share), findsNothing);
      expect(find.byType(SizedBox), findsOneWidget);
    });

    testWidgets('hidden when citySlug is null', (tester) async {
      final poi = _makePoi(slug: 'charles-bridge', citySlug: null, countryCode: 'CZ');

      await tester.pumpWidget(_wrap(SharePoiButton(poi: poi)));

      expect(find.byType(IconButton), findsNothing);
      expect(find.byIcon(Icons.share), findsNothing);
    });

    testWidgets('hidden when both slug and citySlug are null', (tester) async {
      final poi = _makePoi(slug: null, citySlug: null);

      await tester.pumpWidget(_wrap(SharePoiButton(poi: poi)));

      expect(find.byType(IconButton), findsNothing);
    });

    testWidgets('IconButton has Share tooltip', (tester) async {
      final poi = _makePoi(slug: 'bridge', citySlug: 'prague', countryCode: 'CZ');

      await tester.pumpWidget(_wrap(SharePoiButton(poi: poi)));

      final iconButton = tester.widget<IconButton>(find.byType(IconButton));
      expect(iconButton.tooltip, 'Share');
    });
  });
}
