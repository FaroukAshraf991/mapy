// Supabase credentials loaded at build time via --dart-define.
// Never commit real values — see secrets.dart.example for setup.

class Secrets {
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: '',
  );
  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: '',
  );
}
