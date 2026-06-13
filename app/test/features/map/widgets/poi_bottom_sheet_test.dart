import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:placesecrets/domain/models/poi.dart';
import 'package:placesecrets/features/map/widgets/poi_bottom_sheet.dart';

Poi _makePoi({
  String? name,
  String? description,
  double? avgRating,
  int totalRatings = 0,
  List<String> photoUrls = const [],
  bool isPremium = false,
  Map<String, String?>? audioUrls,
}) =>
    Poi(
      id: 'poi-1',
      cityId: 'city-1',
      name: {'en': name ?? 'Charles Bridge'},
      description: {'en': description ?? 'A historic bridge in Prague'},
      latitude: 50.0,
      longitude: 14.0,
      createdAt: DateTime(2025, 1, 1),
      avgRating: avgRating,
      totalRatings: totalRatings,
      photoUrls: photoUrls,
      isPremium: isPremium,
      audioUrls: audioUrls ?? {},
    );

Widget _wrap({
  required Poi poi,
  VoidCallback? onClose,
  VoidCallback? onOpen,
}) {
  return MaterialApp(
    home: Scaffold(
      body: PoiBottomSheet(
        poi: poi,
        onClose: onClose ?? () {},
        onOpen: onOpen ?? () {},
      ),
    ),
  );
}

void main() {
  group('PoiBottomSheet', () {
    testWidgets('shows POI name', (tester) async {
      await tester.pumpWidget(_wrap(poi: _makePoi(name: 'Old Town Square')));

      expect(find.text('Old Town Square'), findsOneWidget);
    });

    testWidgets('shows POI description excerpt', (tester) async {
      await tester.pumpWidget(_wrap(
        poi: _makePoi(description: 'A beautiful historic square in Prague'),
      ));

      expect(find.text('A beautiful historic square in Prague'), findsOneWidget);
    });

    testWidgets('close button triggers onClose callback', (tester) async {
      bool closeCalled = false;
      await tester.pumpWidget(_wrap(
        poi: _makePoi(),
        onClose: () => closeCalled = true,
      ));

      await tester.tap(find.byIcon(Icons.close));
      expect(closeCalled, isTrue);
    });

    testWidgets('open button triggers onOpen callback', (tester) async {
      bool openCalled = false;
      await tester.pumpWidget(_wrap(
        poi: _makePoi(),
        onOpen: () => openCalled = true,
      ));

      await tester.tap(find.text('View Details'));
      expect(openCalled, isTrue);
    });

    testWidgets('rating badge shown when available (totalRatings >= 5)', (tester) async {
      await tester.pumpWidget(_wrap(
        poi: _makePoi(avgRating: 4.5, totalRatings: 10),
      ));

      // ratingBadge returns "4.5★" when conditions are met
      expect(find.text('4.5\u2605'), findsOneWidget);
      expect(find.byIcon(Icons.star), findsOneWidget);
    });

    testWidgets('rating badge not shown when totalRatings < 5', (tester) async {
      await tester.pumpWidget(_wrap(
        poi: _makePoi(avgRating: 4.5, totalRatings: 3),
      ));

      // ratingBadge is null, so no star icon for rating
      expect(find.text('4.5\u2605'), findsNothing);
    });

    testWidgets('shows View Details button', (tester) async {
      await tester.pumpWidget(_wrap(poi: _makePoi()));

      expect(find.text('View Details'), findsOneWidget);
      expect(find.byType(FilledButton), findsOneWidget);
    });

    testWidgets('shows audio icon when audio exists', (tester) async {
      await tester.pumpWidget(_wrap(
        poi: _makePoi(audioUrls: {'en': 'https://example.com/audio.mp3'}),
      ));

      expect(find.byIcon(Icons.headphones), findsOneWidget);
    });

    testWidgets('shows lock icon when premium', (tester) async {
      await tester.pumpWidget(_wrap(
        poi: _makePoi(isPremium: true),
      ));

      expect(find.byIcon(Icons.lock), findsOneWidget);
    });

    testWidgets('no lock icon when not premium', (tester) async {
      await tester.pumpWidget(_wrap(
        poi: _makePoi(isPremium: false),
      ));

      expect(find.byIcon(Icons.lock), findsNothing);
    });
  });
}
