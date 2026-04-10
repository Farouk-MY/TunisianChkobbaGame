// lib/core/services/auth_service.dart

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';

/// Authentication service wrapping Supabase Auth.
///
/// Supports: Anonymous (guest), Email/Password, Google, and Facebook sign-in.
/// Also manages player gender for in-game sound effects.
class AuthService extends ChangeNotifier {
  AuthService() {
    // Listen for auth state changes
    _authSubscription = SupabaseService.auth.onAuthStateChange.listen((data) {
      _user = data.session?.user;
      if (_user != null) {
        _loadProfile();
      }
      notifyListeners();
    });
    _user = SupabaseService.auth.currentUser;
    if (_user != null) {
      _loadProfile();
    }
  }

  User? _user;
  StreamSubscription<AuthState>? _authSubscription;

  // Cached profile data
  String _gender = 'male';
  String _cachedDisplayName = 'Joueur';
  String? _cachedAvatarUrl;
  int _eloRating = 1000;
  int _gamesPlayed = 0;
  int _gamesWon = 0;
  int _totalChkobbas = 0;

  // ─── Getters ───────────────────────────────────────────────────────────────

  User? get user => _user;
  bool get isAuthenticated => _user != null;
  bool get isAnonymous => _user?.isAnonymous ?? true;
  String? get userId => _user?.id;

  /// Player gender: 'male' or 'female' — used for voice/sound effects.
  String get gender => _gender;

  String get displayName => _cachedDisplayName;

  String? get avatarUrl => _cachedAvatarUrl;

  String get email => _user?.email ?? '';

  int get eloRating => _eloRating;
  int get gamesPlayed => _gamesPlayed;
  int get gamesWon => _gamesWon;
  int get totalChkobbas => _totalChkobbas;

  // ─── Profile Loading ───────────────────────────────────────────────────────

  /// Load the user's profile data from the `profiles` table.
  Future<void> _loadProfile() async {
    if (_user == null) return;

    try {
      final data = await SupabaseService.client
          .from('profiles')
          .select()
          .eq('id', _user!.id)
          .maybeSingle();

      if (data != null) {
        _cachedDisplayName = data['display_name'] as String? ?? 'Joueur';
        _cachedAvatarUrl = data['avatar_url'] as String?;
        _gender = data['gender'] as String? ?? 'male';
        _eloRating = data['elo_rating'] as int? ?? 1000;
        _gamesPlayed = data['games_played'] as int? ?? 0;
        _gamesWon = data['games_won'] as int? ?? 0;
        _totalChkobbas = data['total_chkobbas'] as int? ?? 0;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('[AuthService] _loadProfile failed: $e');
      // Use auth metadata as fallback
      final meta = _user?.userMetadata;
      _cachedDisplayName = meta?['display_name'] as String? ??
          meta?['full_name'] as String? ??
          meta?['name'] as String? ??
          'Joueur';
      _cachedAvatarUrl = meta?['avatar_url'] as String?;
    }
  }

  /// Refresh profile data from the database.
  Future<void> refreshProfile() async => _loadProfile();

  // ─── Anonymous / Guest ─────────────────────────────────────────────────────

  /// Sign in anonymously (guest mode).
  /// Creates a temporary account that can be upgraded later.
  Future<AuthResponse> signInAnonymous() async {
    try {
      final response = await SupabaseService.auth.signInAnonymously();
      _user = response.user;
      if (_user != null) {
        await _ensureProfile();
      }
      notifyListeners();
      return response;
    } catch (e) {
      debugPrint('[AuthService] anonymous sign-in failed: $e');
      rethrow;
    }
  }

  // ─── Email / Password ──────────────────────────────────────────────────────

  /// Sign up with email and password.
  Future<AuthResponse> signUpWithEmail({
    required String email,
    required String password,
    required String displayName,
    String gender = 'male',
  }) async {
    try {
      final response = await SupabaseService.auth.signUp(
        email: email,
        password: password,
        data: {'display_name': displayName},
      );
      _user = response.user;
      if (_user != null) {
        await _ensureProfile(name: displayName, gender: gender);
      }
      notifyListeners();
      return response;
    } catch (e) {
      debugPrint('[AuthService] email sign-up failed: $e');
      rethrow;
    }
  }

  /// Sign in with email and password.
  Future<AuthResponse> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final response = await SupabaseService.auth.signInWithPassword(
        email: email,
        password: password,
      );
      _user = response.user;
      if (_user != null) {
        await _loadProfile();
      }
      notifyListeners();
      return response;
    } catch (e) {
      debugPrint('[AuthService] email sign-in failed: $e');
      rethrow;
    }
  }

  // ─── Google ────────────────────────────────────────────────────────────────

  /// Sign in with Google using native Google Sign-In + Supabase ID token.
  Future<AuthResponse> signInWithGoogle() async {
    try {
      debugPrint('[AuthService] Starting Google sign-in flow...');
      const webClientId = '208975629145-2352qqj1s3rpjuu1immu0spv86mc1hsn.apps.googleusercontent.com';
      
      if (webClientId.startsWith('YOUR_WEB_CLIENT_ID')) {
        debugPrint('[AuthService] WARNING: webClientId is still using the placeholder!');
      }

      final googleSignIn = GoogleSignIn(serverClientId: webClientId);
      debugPrint('[AuthService] Calling googleSignIn.signIn()...');
      final googleUser = await googleSignIn.signIn();

      if (googleUser == null) {
        debugPrint('[AuthService] Google sign-in cancelled by user.');
        throw Exception('Google sign-in cancelled');
      }

      debugPrint('[AuthService] Google user: ${googleUser.email}');
      final googleAuth = await googleUser.authentication;
      final idToken = googleAuth.idToken;
      final accessToken = googleAuth.accessToken;

      if (idToken == null) {
        debugPrint('[AuthService] Error: No ID token from Google.');
        throw Exception('No ID token from Google');
      }

      debugPrint('[AuthService] Signing into Supabase with ID token...');
      final response = await SupabaseService.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: accessToken,
      );

      _user = response.user;
      if (_user != null) {
        debugPrint('[AuthService] Supabase login success for ${_user!.email}');
        await _ensureProfile(
          name: googleUser.displayName,
          avatar: googleUser.photoUrl,
        );
      }
      notifyListeners();
      return response;
    } catch (e) {
      debugPrint('[AuthService] Google sign-in ERROR: $e');
      rethrow;
    }
  }



  // ─── Sign Out ──────────────────────────────────────────────────────────────

  /// Sign out the current user.
  Future<void> signOut() async {
    try {
      await SupabaseService.auth.signOut();
      _user = null;
      _gender = 'male';
      _cachedDisplayName = 'Joueur';
      _cachedAvatarUrl = null;
      _eloRating = 1000;
      _gamesPlayed = 0;
      _gamesWon = 0;
      _totalChkobbas = 0;
      notifyListeners();
    } catch (e) {
      debugPrint('[AuthService] sign-out failed: $e');
      rethrow;
    }
  }

  // ─── Profile Helpers ───────────────────────────────────────────────────────

  /// Ensure a profile row exists in the `profiles` table for this user.
  Future<void> _ensureProfile({
    String? name,
    String? avatar,
    String? gender,
  }) async {
    if (_user == null) return;

    try {
      final profileData = <String, dynamic>{
        'id': _user!.id,
        'display_name': name ?? displayName,
        'avatar_url': avatar ?? avatarUrl,
      };

      if (gender != null) {
        profileData['gender'] = gender;
      }

      await SupabaseService.client
          .from('profiles')
          .upsert(profileData, onConflict: 'id');

      // Reload cached profile data
      await _loadProfile();
    } catch (e) {
      debugPrint('[AuthService] profile upsert failed: $e');
      // Non-fatal — the profile can be created later
    }
  }

  /// Update the user's display name.
  Future<void> updateDisplayName(String newName) async {
    if (_user == null) return;

    try {
      await SupabaseService.auth.updateUser(
        UserAttributes(data: {'display_name': newName}),
      );
      await SupabaseService.client
          .from('profiles')
          .update({'display_name': newName})
          .eq('id', _user!.id);
      _cachedDisplayName = newName;
      notifyListeners();
    } catch (e) {
      debugPrint('[AuthService] updateDisplayName failed: $e');
    }
  }

  /// Update the user's gender (for sound effects).
  Future<void> updateGender(String newGender) async {
    if (_user == null) return;
    if (newGender != 'male' && newGender != 'female') return;

    try {
      await SupabaseService.client
          .from('profiles')
          .update({'gender': newGender})
          .eq('id', _user!.id);
      _gender = newGender;
      notifyListeners();
    } catch (e) {
      debugPrint('[AuthService] updateGender failed: $e');
    }
  }

  /// Update avatar URL.
  Future<void> updateAvatar(String newAvatarUrl) async {
    if (_user == null) return;

    try {
      await SupabaseService.client
          .from('profiles')
          .update({'avatar_url': newAvatarUrl})
          .eq('id', _user!.id);
      _cachedAvatarUrl = newAvatarUrl;
      notifyListeners();
    } catch (e) {
      debugPrint('[AuthService] updateAvatar failed: $e');
    }
  }

  // ─── Cleanup ───────────────────────────────────────────────────────────────

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}
