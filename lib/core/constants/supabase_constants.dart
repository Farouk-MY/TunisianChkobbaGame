// lib/core/constants/supabase_constants.dart

/// Supabase project credentials.
/// Replace these with your own Supabase project URL and anon key.
class SupabaseConstants {
  SupabaseConstants._();

  /// Your Supabase project URL
  static const String url = 'https://iomgniafrprrlggyqeec.supabase.co';

  /// Your Supabase anon/public key
  static const String anonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImlvbWduaWFmcnBycmxnZ3lxZWVjIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzE4NjQyMTAsImV4cCI6MjA4NzQ0MDIxMH0.ZE_ZvHdJIlXcUQ6YAjw45a3KI9COzHZTs1RgFxPNeCg';

  /// Deep link scheme for the app
  static const String deepLinkScheme = 'chkobba';

  /// Match code length
  static const int matchCodeLength = 6;

  /// Turn timeout in seconds
  static const int turnTimeoutSeconds = 30;

  /// Reconnection timeout in seconds
  static const int reconnectTimeoutSeconds = 30;

  /// Default ELO rating for new players
  static const int defaultElo = 1000;
}
