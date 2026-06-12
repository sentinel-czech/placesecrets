import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:herodots/features/auth/auth_screen.dart';
import 'package:herodots/features/auth/providers/auth_providers.dart';

Widget _wrap({bool isAnonymous = false}) {
  return ProviderScope(
    overrides: [
      authStateProvider.overrideWith(() => _FakeAuthStateNotifier(
            AppAuthState(isAnonymous: isAnonymous),
          )),
    ],
    child: const MaterialApp(home: AuthScreen()),
  );
}

class _FakeAuthStateNotifier extends AuthState {
  final AppAuthState _initial;
  _FakeAuthStateNotifier(this._initial);

  @override
  AppAuthState build() => _initial;

  @override
  Future<void> signInWithEmail(String email, String password) async {}

  @override
  Future<void> signUp(String email, String password, {String? handle}) async {}

  @override
  Future<void> resetPassword(String email) async {}

  @override
  Future<void> signOut() async {}
}

void main() {
  group('AuthScreen', () {
    testWidgets('renders email and password fields', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();

      expect(find.text('Email'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
      expect(find.byType(TextField), findsNWidgets(2));
    });

    testWidgets('toggle between Sign In and Create Account modes',
        (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();

      // Initially in Sign In mode
      expect(find.text('Sign In'), findsNWidgets(2)); // AppBar + button
      expect(
          find.text("Don't have an account? Create one"), findsOneWidget);

      // Tap the toggle button
      await tester.tap(find.text("Don't have an account? Create one"));
      await tester.pumpAndSettle();

      // Now in Create Account mode
      expect(find.text('Create Account'), findsNWidgets(2));
      expect(
          find.text('Already have an account? Sign in'), findsOneWidget);
    });

    testWidgets('Create Account mode shows handle field', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();

      // Handle field should not be visible in Sign In mode
      expect(find.text('Handle (optional)'), findsNothing);

      // Switch to Create Account mode
      await tester.tap(find.text("Don't have an account? Create one"));
      await tester.pumpAndSettle();

      // Handle field should now be visible
      expect(find.text('Handle (optional)'), findsOneWidget);
      expect(find.byIcon(Icons.alternate_email), findsOneWidget);
    });

    testWidgets('validation: empty email shows error after submit',
        (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();

      // Tap Sign In button without entering anything
      await tester.tap(find.widgetWithText(FilledButton, 'Sign In'));
      await tester.pumpAndSettle();

      expect(
          find.text('Please enter email and password'), findsOneWidget);
    });

    testWidgets('password visibility: password field is obscured',
        (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();

      // The password TextField should be obscured
      final passwordField = tester.widget<TextField>(
        find.widgetWithText(TextField, 'Password'),
      );
      expect(passwordField.obscureText, isTrue);
    });

    testWidgets('error response shows error text', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();

      // Enter email but a short password to trigger validation error
      await tester.enterText(
          find.widgetWithText(TextField, 'Email'), 'test@example.com');
      await tester.enterText(
          find.widgetWithText(TextField, 'Password'), 'short');
      await tester.tap(find.widgetWithText(FilledButton, 'Sign In'));
      await tester.pumpAndSettle();

      expect(find.text('Password must be at least 8 characters'),
          findsOneWidget);
    });

    testWidgets('Forgot password link visible in sign in mode',
        (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();

      expect(find.text('Forgot password?'), findsOneWidget);

      // Switch to sign up mode
      await tester.tap(find.text("Don't have an account? Create one"));
      await tester.pumpAndSettle();

      // Forgot password should not be visible in sign up mode
      expect(find.text('Forgot password?'), findsNothing);
    });
  });
}
