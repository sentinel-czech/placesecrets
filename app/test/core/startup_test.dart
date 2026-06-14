import 'package:flutter_test/flutter_test.dart';
import 'package:placesecrets/core/constants/env.dart';
import 'package:placesecrets/core/services/firebase_bootstrap.dart';

void main() {
  // The test runner does not pass --dart-define, so the Supabase config is empty
  // here. These tests pin the fail-fast and resilience behavior.
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Env', () {
    test('isConfigured is false without injected --dart-define values', () {
      expect(Env.isConfigured, isFalse);
    });

    test('assertConfigured throws an actionable error when unconfigured', () {
      expect(Env.assertConfigured, throwsA(isA<StateError>()));
    });

    test('environment defaults to dev', () {
      expect(Env.environment, 'dev');
      expect(Env.isDev, isTrue);
      expect(Env.isProd, isFalse);
    });
  });

  group('bootstrapFirebase', () {
    test('returns false (does not throw) when Firebase is unavailable', () async {
      // No Firebase config / platform in the test host → must degrade gracefully.
      final ready = await bootstrapFirebase();
      expect(ready, isFalse);
    });
  });
}
