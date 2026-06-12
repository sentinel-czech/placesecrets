abstract class Env {
  static const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');
  static const environment =
      String.fromEnvironment('ENVIRONMENT', defaultValue: 'dev');
  static const googleIosClientId =
      String.fromEnvironment('GOOGLE_IOS_CLIENT_ID');

  static bool get isDev => environment == 'dev';
  static bool get isProd => environment == 'prod';
}
