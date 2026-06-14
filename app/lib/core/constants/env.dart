/// Compile-time environment configuration.
///
/// Values are injected at build time via `--dart-define` (or, preferably,
/// `--dart-define-from-file=dart_defines/<env>.json`). See `app/BUILD.md`.
///
/// Nothing secret lives here: the Supabase anon key and URL are *publishable*
/// (they ship inside the client anyway and are protected by Row Level Security).
abstract class Env {
  static const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');
  static const environment =
      String.fromEnvironment('ENVIRONMENT', defaultValue: 'dev');
  static const googleIosClientId =
      String.fromEnvironment('GOOGLE_IOS_CLIENT_ID');

  static bool get isDev => environment == 'dev';
  static bool get isProd => environment == 'prod';

  /// Whether the mandatory Supabase configuration was injected at build time.
  static bool get isConfigured =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;

  /// Throws a clear, actionable error if the build was produced without the
  /// required `--dart-define` values, instead of letting Supabase fail later
  /// with a cryptic message. Call once during startup before `Supabase.initialize`.
  static void assertConfigured() {
    if (!isConfigured) {
      throw StateError(
        'Missing Supabase configuration. Build with '
        '--dart-define-from-file=dart_defines/<env>.json '
        '(SUPABASE_URL and SUPABASE_ANON_KEY must be set). See app/BUILD.md.',
      );
    }
  }
}
