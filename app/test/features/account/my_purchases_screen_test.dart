import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:placesecrets/features/account/my_purchases_screen.dart';
import 'package:placesecrets/features/poi_detail/providers/poi_access_provider.dart';

/// Completers that never complete, used to keep providers in loading state
/// without creating pending timers.
Completer<Set<String>>? _poiCompleter;
Completer<Set<String>>? _bundleCompleter;

Widget _wrap({
  bool loadingPois = false,
  bool loadingBundles = false,
  Set<String> poiData = const {},
  Set<String> bundleData = const {},
}) {
  _poiCompleter = loadingPois ? Completer<Set<String>>() : null;
  _bundleCompleter = loadingBundles ? Completer<Set<String>>() : null;

  return ProviderScope(
    overrides: [
      purchasedPoiIdsProvider.overrideWith((ref) {
        if (_poiCompleter != null) return _poiCompleter!.future;
        return Future.value(poiData);
      }),
      purchasedCityBundleIdsProvider.overrideWith((ref) {
        if (_bundleCompleter != null) return _bundleCompleter!.future;
        return Future.value(bundleData);
      }),
    ],
    child: const MaterialApp(home: MyPurchasesScreen()),
  );
}

void main() {
  group('MyPurchasesScreen', () {
    testWidgets('shows app bar title', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();

      expect(find.text('My Purchases'), findsOneWidget);
    });

    testWidgets('shows empty state for individual purchases', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();

      expect(find.text('No individual purchases yet'), findsOneWidget);
    });

    testWidgets('shows empty state for city bundles', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();

      expect(find.text('No city bundles purchased'), findsOneWidget);
    });

    testWidgets('shows loading state', (tester) async {
      await tester.pumpWidget(_wrap(loadingPois: true, loadingBundles: true));
      // Do NOT call pumpAndSettle since the future never resolves
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsWidgets);
    });

    testWidgets('shows section titles', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();

      expect(find.text('Individual Places'), findsOneWidget);
      expect(find.text('City Bundles'), findsOneWidget);
    });

    testWidgets('shows purchased POI items', (tester) async {
      await tester.pumpWidget(_wrap(
        poiData: const {'poi-1', 'poi-2'},
      ));
      await tester.pumpAndSettle();

      expect(find.text('Place poi-1'), findsOneWidget);
      expect(find.text('Place poi-2'), findsOneWidget);
      expect(find.text('Premium content unlocked'), findsNWidgets(2));
      expect(find.byIcon(Icons.place), findsNWidgets(2));
    });

    testWidgets('shows purchased city bundle items', (tester) async {
      await tester.pumpWidget(_wrap(
        bundleData: const {'city-1'},
      ));
      await tester.pumpAndSettle();

      expect(find.text('City bundle city-1'), findsOneWidget);
      expect(find.text('All premium content unlocked'), findsOneWidget);
      expect(find.byIcon(Icons.location_city), findsOneWidget);
    });
  });
}
