import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:flutter_localizations/flutter_localizations.dart';

import 'app/app_bootstrap.dart';
import 'app/locale_provider.dart';
import 'app/router.dart';
import 'app/theme.dart';
import 'core/constants/env.dart';
import 'core/services/firebase_bootstrap.dart';
import 'core/services/notification_service.dart';
import 'l10n/app_localizations.dart';

/// Whether Firebase initialized successfully this session. Overridden in [main]
/// and consumed by FCM wiring so push features stay disabled when Firebase is
/// unavailable (e.g. a dev build without `google-services.json`).
final firebaseAvailableProvider = Provider<bool>((ref) => false);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Fail fast with a clear message if the build lacks Supabase config, rather
  // than surfacing a cryptic error from Supabase.initialize later.
  Env.assertConfigured();

  // Firebase/FCM is optional — never let it block startup.
  final firebaseReady = await bootstrapFirebase();

  // Supabase is required; let a genuine failure surface (config was asserted).
  await Supabase.initialize(
    url: Env.supabaseUrl,
    anonKey: Env.supabaseAnonKey,
    debug: Env.isDev,
  );

  // Background audio + local notifications are best-effort: a platform failure
  // here must not prevent the app from running.
  try {
    await JustAudioBackground.init(
      androidNotificationChannelId: 'cz.tuma.placesecrets.audio',
      androidNotificationChannelName: 'PlaceSecrets AudioGuide',
      androidNotificationOngoing: true,
      androidStopForegroundOnPause: true,
    );
  } catch (e) {
    debugPrint('Background audio init failed: $e');
  }

  try {
    await NotificationService.initialize();
  } catch (e) {
    debugPrint('Notification init failed: $e');
  }

  // Sign in anonymously if no session, so the app is usable before login.
  final session = Supabase.instance.client.auth.currentSession;
  if (session == null) {
    try {
      await Supabase.instance.client.auth.signInAnonymously();
    } catch (e) {
      debugPrint('Anonymous sign-in failed: $e');
    }
  }

  runApp(
    ProviderScope(
      overrides: [
        firebaseAvailableProvider.overrideWithValue(firebaseReady),
      ],
      child: const PlaceSecretsApp(),
    ),
  );
}

class PlaceSecretsApp extends ConsumerWidget {
  const PlaceSecretsApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final locale = ref.watch(appLocaleProvider);
    return AppBootstrapper(
      child: MaterialApp.router(
        title: 'PlaceSecrets',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        themeMode: ThemeMode.system,
        routerConfig: router,
        locale: locale,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        // All product languages. Content + Material widgets follow the chosen
        // locale; AppLocalizations falls back to English for any not yet shipped.
        supportedLocales:
            kSupportedLanguages.keys.map((c) => Locale(c)).toList(),
      ),
    );
  }
}
