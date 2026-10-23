import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:placesecrets/domain/models/poi.dart';
import 'package:placesecrets/domain/models/poi_premium_content.dart';
import 'package:placesecrets/features/poi_detail/widgets/premium_poi_content.dart';

Poi _makePoi({String id = 'poi-1'}) => Poi(
      id: id,
      cityId: 'city-1',
      name: const {'en': 'Test POI'},
      description: const {'en': 'A test point of interest'},
      latitude: 50.0,
      longitude: 14.0,
      createdAt: DateTime(2025, 1, 1),
    );

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: SingleChildScrollView(child: child)));

void main() {
  group('PremiumPoiContent', () {
    testWidgets('renders premium badge with workspace_premium icon', (tester) async {
      const content = PoiPremiumContent(id: 'c1', poiId: 'poi-1');

      await tester.pumpWidget(_wrap(PremiumPoiContent(content: content, poi: _makePoi())));

      expect(find.byIcon(Icons.workspace_premium), findsOneWidget);
      expect(find.text('Premium Content'), findsOneWidget);
    });

    testWidgets('displays text content when present', (tester) async {
      const content = PoiPremiumContent(
        id: 'c1',
        poiId: 'poi-1',
        textContent: 'This is premium text about the place.',
      );

      await tester.pumpWidget(_wrap(PremiumPoiContent(content: content, poi: _makePoi())));

      expect(find.text('This is premium text about the place.'), findsOneWidget);
    });

    testWidgets('hides text content when null', (tester) async {
      const content = PoiPremiumContent(id: 'c1', poiId: 'poi-1', textContent: null);

      await tester.pumpWidget(_wrap(PremiumPoiContent(content: content, poi: _makePoi())));

      // Only the badge text should be present, no body text
      expect(find.text('Premium Content'), findsOneWidget);
      // No additional Text widgets beyond badge and framework ones
    });

    testWidgets('hides text content when empty string', (tester) async {
      const content = PoiPremiumContent(id: 'c1', poiId: 'poi-1', textContent: '');

      await tester.pumpWidget(_wrap(PremiumPoiContent(content: content, poi: _makePoi())));

      // Empty string should not be displayed (the condition checks isNotEmpty)
      final textWidgets = tester.widgetList<Text>(find.byType(Text));
      final texts = textWidgets.map((t) => t.data).where((d) => d != null).toList();
      expect(texts, contains('Premium Content'));
      expect(texts, isNot(contains('')));
    });

    testWidgets('renders extra photos section with correct count', (tester) async {
      const content = PoiPremiumContent(
        id: 'c1',
        poiId: 'poi-1',
        extraPhotos: [
          'https://example.com/photo1.jpg',
          'https://example.com/photo2.jpg',
          'https://example.com/photo3.jpg',
        ],
      );

      await tester.pumpWidget(_wrap(PremiumPoiContent(content: content, poi: _makePoi())));

      // The ListView should have 3 CachedNetworkImage items
      expect(find.byType(CachedNetworkImage), findsNWidgets(3));
      // There should be a horizontal ListView
      expect(find.byType(ListView), findsOneWidget);
    });

    testWidgets('renders related POIs section', (tester) async {
      const content = PoiPremiumContent(
        id: 'c1',
        poiId: 'poi-1',
        relatedPoiIds: ['poi-2', 'poi-3'],
      );

      await tester.pumpWidget(_wrap(PremiumPoiContent(content: content, poi: _makePoi())));

      expect(find.text('Related Places'), findsOneWidget);
      expect(find.text('Place poi-2'), findsOneWidget);
      expect(find.text('Place poi-3'), findsOneWidget);
      expect(find.byIcon(Icons.place_outlined), findsNWidgets(2));
      expect(find.byIcon(Icons.chevron_right), findsNWidgets(2));
    });

    testWidgets('empty content shows only badge', (tester) async {
      const content = PoiPremiumContent(
        id: 'c1',
        poiId: 'poi-1',
        textContent: null,
        extraPhotos: [],
        relatedPoiIds: [],
      );

      await tester.pumpWidget(_wrap(PremiumPoiContent(content: content, poi: _makePoi())));

      expect(find.text('Premium Content'), findsOneWidget);
      expect(find.byIcon(Icons.workspace_premium), findsOneWidget);
      // No photos, no related places
      expect(find.byType(CachedNetworkImage), findsNothing);
      expect(find.text('Related Places'), findsNothing);
      expect(find.byType(ListTile), findsNothing);
    });
  });
}
