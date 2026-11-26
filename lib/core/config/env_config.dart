/// Compile-time environment configuration populated via
/// `--dart-define-from-file=.env`.
abstract final class EnvConfig {
  /// Supabase project URL (`SUPABASE_URL`).
  static const String supabaseUrl = String.fromEnvironment('SUPABASE_URL');

  /// Supabase anonymous public key (`SUPABASE_ANON_KEY`).
  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
  );

  /// Web Push VAPID public key (`VAPID_PUBLIC_KEY`).
  static const String vapidPublicKey = String.fromEnvironment(
    'VAPID_PUBLIC_KEY',
    defaultValue: '',
  );

  /// Validates that all required compile-time environment variables are set.
  ///
  /// Throws a [StateError] if any required key is empty.
  static void validate() {
    final missing = <String>[
      if (supabaseUrl.isEmpty) 'SUPABASE_URL',
      if (supabaseAnonKey.isEmpty) 'SUPABASE_ANON_KEY',
    ];

    if (missing.isNotEmpty) {
      throw StateError(
        'Missing required environment variable(s): ${missing.join(', ')}. '
        'Run with --dart-define-from-file=.env (or pass --dart-define for each key).',
      );
    }
  }
}
