import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:placesecrets/data/repositories/ratings_repository.dart';
import 'package:placesecrets/domain/models/poi_rating.dart';
import 'package:placesecrets/features/poi_detail/providers/ratings_provider.dart';
import 'package:placesecrets/features/poi_detail/widgets/rating_widget.dart';

/// A minimal fake that implements the interface without extending the real class.
class FakeRatingsRepository implements RatingsRepository {
  bool submitCalled = false;
  int? submittedRating;
  RatingReason? submittedReason;
  bool shouldFail = false;

  @override
  Future<void> submitRating({
    required String poiId,
    required int rating,
    RatingReason? reason,
    required String langCode,
    String? comment,
  }) async {
    submitCalled = true;
    submittedRating = rating;
    submittedReason = reason;
    if (shouldFail) throw Exception('Submit failed');
  }

  @override
  Future<PoiRating?> getMyRating(String poiId) async => null;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Widget _wrap({
  PoiRating? existingRating,
  FakeRatingsRepository? fakeRepo,
}) {
  final repo = fakeRepo ?? FakeRatingsRepository();
  return ProviderScope(
    overrides: [
      // For family providers, override each concrete provider instance
      canSubmitRatingProvider.overrideWithValue(true),
      myPoiRatingProvider('poi-1')
          .overrideWith((ref) => Future.value(existingRating)),
      ratingsRepositoryProvider.overrideWith((ref) => repo),
    ],
    child: const MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: RatingWidget(poiId: 'poi-1', langCode: 'en'),
        ),
      ),
    ),
  );
}

void main() {
  group('RatingWidget', () {
    testWidgets('renders 5 star icons (outline) initially', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.star_outline_rounded), findsNWidgets(5));
      expect(find.byIcon(Icons.star_rounded), findsNothing);
    });

    testWidgets('renders question text', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();

      expect(find.text('How do you rate this guide?'), findsOneWidget);
    });

    testWidgets('tapping a star selects rating (fills stars up to tapped)', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();

      // Tap the 3rd star icon
      final starIcons = find.byIcon(Icons.star_outline_rounded);
      await tester.tap(starIcons.at(2));
      await tester.pumpAndSettle();

      // First 3 should be filled, last 2 should be outline
      expect(find.byIcon(Icons.star_rounded), findsNWidgets(3));
      expect(find.byIcon(Icons.star_outline_rounded), findsNWidgets(2));
    });

    testWidgets('submit button appears after selecting rating', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();

      // No submit button initially
      expect(find.text('Submit rating'), findsNothing);

      // Tap a star
      await tester.tap(find.byIcon(Icons.star_outline_rounded).first);
      await tester.pumpAndSettle();

      // Submit button should now appear
      expect(find.text('Submit rating'), findsOneWidget);
    });

    testWidgets('shows already-rated widget when existing rating exists', (tester) async {
      final existing = PoiRating(
        id: 'r1',
        poiId: 'poi-1',
        rating: 4,
        langCode: 'en',
        createdAt: DateTime(2025, 1, 1),
      );

      await tester.pumpWidget(_wrap(existingRating: existing));
      await tester.pumpAndSettle();

      expect(find.text('Your rating'), findsOneWidget);
      // 4 filled + 1 outline = 5 total star icons
      expect(find.byIcon(Icons.star_rounded), findsNWidgets(4));
      expect(find.byIcon(Icons.star_outline_rounded), findsOneWidget);
    });

    testWidgets('shows reason chips for low rating (1-2 stars)', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();

      // Tap the 1st star (rating = 1)
      await tester.tap(find.byIcon(Icons.star_outline_rounded).first);
      await tester.pumpAndSettle();

      expect(find.text('What was wrong? (optional)'), findsOneWidget);
      expect(find.text('Inaccurate'), findsOneWidget);
      expect(find.text('Too short'), findsOneWidget);
      expect(find.text('Boring'), findsOneWidget);
      expect(find.text('Wrong language'), findsOneWidget);
    });

    testWidgets('does not show reason chips for high rating (4-5 stars)', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();

      // Tap the 4th star (rating = 4)
      await tester.tap(find.byIcon(Icons.star_outline_rounded).at(3));
      await tester.pumpAndSettle();

      expect(find.text('What was wrong? (optional)'), findsNothing);
      expect(find.text('Inaccurate'), findsNothing);
    });

    testWidgets('submit calls repository and shows thank you', (tester) async {
      final fakeRepo = FakeRatingsRepository();
      await tester.pumpWidget(_wrap(fakeRepo: fakeRepo));
      await tester.pumpAndSettle();

      // Tap 5th star
      await tester.tap(find.byIcon(Icons.star_outline_rounded).last);
      await tester.pumpAndSettle();

      // Tap submit
      await tester.tap(find.text('Submit rating'));
      await tester.pumpAndSettle();

      expect(fakeRepo.submitCalled, isTrue);
      expect(fakeRepo.submittedRating, 5);
      expect(find.text('Thanks for rating!'), findsOneWidget);
    });

    testWidgets('submit button disabled while submitting', (tester) async {
      final completer = Completer<void>();

      // Make submitRating hang until we complete the future
      final slowRepo = _SlowFakeRatingsRepository(completer);

      await tester.pumpWidget(ProviderScope(
        overrides: [
          canSubmitRatingProvider.overrideWithValue(true),
          myPoiRatingProvider('poi-1')
              .overrideWith((ref) => Future.value(null)),
          ratingsRepositoryProvider.overrideWith((ref) => slowRepo),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: RatingWidget(poiId: 'poi-1', langCode: 'en'),
            ),
          ),
        ),
      ));
      await tester.pumpAndSettle();

      // Select a star
      await tester.tap(find.byIcon(Icons.star_outline_rounded).last);
      await tester.pumpAndSettle();

      // Tap submit - this will start the async operation
      await tester.tap(find.text('Submit rating'));
      await tester.pump(); // Process the tap but don't settle

      // While loading, the button should show a CircularProgressIndicator
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Complete the future
      completer.complete();
      await tester.pumpAndSettle();

      expect(find.text('Thanks for rating!'), findsOneWidget);
    });
  });
}

class _SlowFakeRatingsRepository implements RatingsRepository {
  final Completer<void> completer;

  _SlowFakeRatingsRepository(this.completer);

  @override
  Future<void> submitRating({
    required String poiId,
    required int rating,
    RatingReason? reason,
    required String langCode,
    String? comment,
  }) => completer.future;

  @override
  Future<PoiRating?> getMyRating(String poiId) async => null;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
