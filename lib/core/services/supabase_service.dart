// lib/core/services/supabase_service.dart

import 'package:supabase_flutter/supabase_flutter.dart';
import '../constants/supabase_constants.dart';

/// Singleton service for Supabase client access.
///
/// Initialize once in main() via [SupabaseService.initialize()],
/// then access the client anywhere via [SupabaseService.client].
class SupabaseService {
  SupabaseService._();

  static bool _initialized = false;

  /// Initialize Supabase. Must be called once before using the client.
  static Future<void> initialize() async {
    if (_initialized) return;

    await Supabase.initialize(
      url: SupabaseConstants.url,
      anonKey: SupabaseConstants.anonKey,
      authOptions: const FlutterAuthClientOptions(
        authFlowType: AuthFlowType.pkce,
      ),
    );

    _initialized = true;
  }

  /// Get the Supabase client instance.
  static SupabaseClient get client => Supabase.instance.client;

  /// Shortcut to the auth module.
  static GoTrueClient get auth => client.auth;

  /// Shortcut to the realtime module.
  static RealtimeClient get realtime => client.realtime;

  /// Check if user is currently authenticated.
  static bool get isAuthenticated => auth.currentUser != null;

  /// Get current user ID (or null).
  static String? get currentUserId => auth.currentUser?.id;

  /// Get current user's display name from metadata.
  static String? get currentDisplayName {
    final meta = auth.currentUser?.userMetadata;
    return meta?['display_name'] as String? ??
        meta?['full_name'] as String? ??
        meta?['name'] as String?;
  }
}
