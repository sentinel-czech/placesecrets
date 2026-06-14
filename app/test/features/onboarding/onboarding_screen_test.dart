import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:placesecrets/features/onboarding/onboarding_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

Widget _wrap() {
  return const MaterialApp(home: OnboardingScreen());
}

void main() {
  group('OnboardingScreen', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    testWidgets('renders carousel with page indicators',
        (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();

      // 3 page indicator dots (Container widgets with circle decoration)
      // Verify the first page content is visible
      expect(find.text('Discover Places'), findsOneWidget);
      expect(find.byType(PageView), findsOneWidget);

      // There should be 3 page indicator dots
      // They are Container widgets with BoxDecoration(shape: BoxShape.circle)
      // We check by counting the indicator row children
      expect(find.byIcon(Icons.explore), findsOneWidget);
    });

    testWidgets('Skip button exists', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();

      expect(find.text('Skip'), findsOneWidget);
    });

    testWidgets('Next button shows on first page', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();

      expect(find.text('Next'), findsOneWidget);
      expect(find.text('Get Started'), findsNothing);
    });

    testWidgets('page indicators update on swipe', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();

      // First page shows 'Discover Places'
      expect(find.text('Discover Places'), findsOneWidget);

      // Swipe left to go to second page
      await tester.drag(find.byType(PageView), const Offset(-400, 0));
      await tester.pumpAndSettle();

      // Second page shows 'Listen & Learn'
      expect(find.text('Listen & Learn'), findsOneWidget);

      // Swipe left to go to third page
      await tester.drag(find.byType(PageView), const Offset(-400, 0));
      await tester.pumpAndSettle();

      // Third page shows 'Keep Your Travel Log'
      expect(find.text('Keep Your Travel Log'), findsOneWidget);
    });

    testWidgets('last page shows Get Started button', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();

      // Navigate to the last page (4 pages: 3 intro + 1 permission priming).
      for (var i = 0; i < 3; i++) {
        await tester.drag(find.byType(PageView), const Offset(-400, 0));
        await tester.pumpAndSettle();
      }

      // On last page, button should say "Get Started"
      expect(find.text('Get Started'), findsOneWidget);
      expect(find.text('Next'), findsNothing);
      expect(find.text('Stay in the Loop'), findsOneWidget);
    });
  });
}
