// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'locale_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$appLocaleHash() => r'd62ca4e9300c34692651b2400e961f47d41dea69';

/// App-wide language override, persisted locally and synced with
/// `user_profiles.language`. `null` means "follow the device locale".
///
/// Because content (POI names/descriptions/audio) and Material widgets resolve
/// against `Localizations.localeOf(context)`, changing this updates the whole
/// app's language. UI chrome strings that are still hardcoded English are not
/// affected (separate string-extraction effort).
///
/// Copied from [AppLocale].
@ProviderFor(AppLocale)
final appLocaleProvider = NotifierProvider<AppLocale, Locale?>.internal(
  AppLocale.new,
  name: r'appLocaleProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$appLocaleHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$AppLocale = Notifier<Locale?>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
