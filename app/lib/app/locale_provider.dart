import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'locale_provider.g.dart';

/// The 11 languages the product supports (matches the web portal's locales).
/// Map of code -> native display name, used for the picker.
const Map<String, String> kSupportedLanguages = {
  'en': 'English',
  'cs': 'Čeština',
  'sk': 'Slovenčina',
  'de': 'Deutsch',
  'es': 'Español',
  'fr': 'Français',
  'pt': 'Português',
  'ru': 'Русский',
  'vi': 'Tiếng Việt',
  'zh': '中文',
  'ko': '한국어',
};

/// App-wide language override, persisted locally and synced with
/// `user_profiles.language`. `null` means "follow the device locale".
///
/// Because content (POI names/descriptions/audio) and Material widgets resolve
/// against `Localizations.localeOf(context)`, changing this updates the whole
/// app's language. UI chrome strings that are still hardcoded English are not
/// affected (separate string-extraction effort).
@Riverpod(keepAlive: true)
class AppLocale extends _$AppLocale {
  static const _prefKey = 'pref_app_language';

  @override
  Locale? build() {
    _load();
    return null;
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_prefKey);
    if (code != null && kSupportedLanguages.containsKey(code)) {
      state = Locale(code);
    }
  }

  /// Sets (or clears, when [code] is null) the app language and persists it.
  Future<void> setLocale(String? code) async {
    final prefs = await SharedPreferences.getInstance();
    if (code == null) {
      await prefs.remove(_prefKey);
      state = null;
    } else if (kSupportedLanguages.containsKey(code)) {
      await prefs.setString(_prefKey, code);
      state = Locale(code);
    }
  }

  /// Applies a server-side preference (e.g. `user_profiles.language` on login)
  /// without overwriting an explicit local choice when [code] is empty/unknown.
  Future<void> applyFromProfile(String? code) async {
    if (code == null || !kSupportedLanguages.containsKey(code)) return;
    await setLocale(code);
  }
}
