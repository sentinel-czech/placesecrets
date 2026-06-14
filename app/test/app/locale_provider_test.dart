import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:placesecrets/app/locale_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('kSupportedLanguages covers the 11 product locales', () {
    expect(kSupportedLanguages.keys, containsAll(
        ['en', 'cs', 'sk', 'de', 'es', 'fr', 'pt', 'ru', 'vi', 'zh', 'ko']));
    expect(kSupportedLanguages.length, 11);
  });

  test('setLocale persists, validates, and clears', () async {
    SharedPreferences.setMockInitialValues({});
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(appLocaleProvider.notifier);

    await notifier.setLocale('cs');
    expect(container.read(appLocaleProvider), const Locale('cs'));

    // Unknown codes are ignored (state unchanged).
    await notifier.setLocale('xx');
    expect(container.read(appLocaleProvider), const Locale('cs'));

    // Null clears the override (follow system).
    await notifier.setLocale(null);
    expect(container.read(appLocaleProvider), isNull);
  });

  test('persisted preference is loaded on build', () async {
    SharedPreferences.setMockInitialValues({'pref_app_language': 'de'});
    final container = ProviderContainer();
    addTearDown(container.dispose);

    // build() kicks off an async load; let it settle.
    container.read(appLocaleProvider);
    await Future<void>.delayed(Duration.zero);
    expect(container.read(appLocaleProvider), const Locale('de'));
  });

  test('applyFromProfile ignores empty/unknown languages', () async {
    SharedPreferences.setMockInitialValues({});
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(appLocaleProvider.notifier);

    await notifier.applyFromProfile(null);
    expect(container.read(appLocaleProvider), isNull);
    await notifier.applyFromProfile('zz');
    expect(container.read(appLocaleProvider), isNull);
    await notifier.applyFromProfile('fr');
    expect(container.read(appLocaleProvider), const Locale('fr'));
  });
}
