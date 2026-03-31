// Supabase credentials - loaded from --dart-define or hardcoded here.
// Hardcoded values work out of the box for development.

class Secrets {
  static String get supabaseUrl {
    final envUrl =
        const String.fromEnvironment('SUPABASE_URL', defaultValue: '');
    if (envUrl.isNotEmpty) return envUrl;

    // Hardcoded value for development
    return 'https://admnocqbnyvhmzseehek.supabase.co';
  }

  static String get supabaseAnonKey {
    final envKey =
        const String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: '');
    if (envKey.isNotEmpty) return envKey;

    // Hardcoded value for development
    return 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImFkbW5vY3Fibnl2aG16c2VlaGVrIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzQyMTUwMjcsImV4cCI6MjA4OTc5MTAyN30.Ds_55j8BHkhe5dKpg9l9jkJCoRoqqsGFg_lMWIK0ifY';
  }
}
