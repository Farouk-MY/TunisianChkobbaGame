// lib/core/services/profile_service.dart

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'supabase_service.dart';

/// Dual-layer profile cache:
///  1. SharedPreferences (instant cold-start reads)
///  2. Supabase `profiles` table (source of truth, refreshed in background)
class ProfileService extends ChangeNotifier {
  static const _kName = 'profile_display_name';
  static const _kAvatar = 'profile_avatar_url';
  static const _kGender = 'profile_gender';
  static const _kElo = 'profile_elo';
  static const _kPlayed = 'profile_games_played';
  static const _kWon = 'profile_games_won';
  static const _kChkobbas = 'profile_total_chkobbas';

  /// Cached values (in-memory, backed by SharedPreferences)
  String displayName = 'Joueur';
  String? avatarUrl;
  String gender = 'male';
  int eloRating = 1000;
  int gamesPlayed = 0;
  int gamesWon = 0;
  int totalChkobbas = 0;

  bool _loaded = false;
  bool get loaded => _loaded;

  double get winRate =>
      gamesPlayed == 0 ? 0 : (gamesWon / gamesPlayed * 100);

  int get level => (gamesPlayed ~/ 5) + 1;

  String get initials {
    final parts = displayName.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return displayName.length >= 2
        ? displayName.substring(0, 2).toUpperCase()
        : displayName.isNotEmpty
            ? displayName[0].toUpperCase()
            : '?';
  }

  // ─── Load ──────────────────────────────────────────────────────────────────

  /// Load from SharedPreferences first (instant), then refresh from Supabase.
  Future<void> load(String userId) async {
    await _loadFromPrefs();
    _loaded = true;
    notifyListeners();
    // Background refresh from network
    _refreshFromSupabase(userId);
  }

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    displayName = prefs.getString(_kName) ?? 'Joueur';
    avatarUrl = prefs.getString(_kAvatar);
    gender = prefs.getString(_kGender) ?? 'male';
    eloRating = prefs.getInt(_kElo) ?? 1000;
    gamesPlayed = prefs.getInt(_kPlayed) ?? 0;
    gamesWon = prefs.getInt(_kWon) ?? 0;
    totalChkobbas = prefs.getInt(_kChkobbas) ?? 0;
  }

  Future<void> _refreshFromSupabase(String userId) async {
    try {
      final data = await SupabaseService.client
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();

      if (data != null) {
        displayName = data['display_name'] as String? ?? displayName;
        avatarUrl = data['avatar_url'] as String? ?? avatarUrl;
        gender = data['gender'] as String? ?? gender;
        eloRating = data['elo_rating'] as int? ?? eloRating;
        gamesPlayed = data['games_played'] as int? ?? gamesPlayed;
        gamesWon = data['games_won'] as int? ?? gamesWon;
        totalChkobbas = data['total_chkobbas'] as int? ?? totalChkobbas;
        await _saveToPrefs();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('[ProfileService] Supabase refresh failed: $e');
    }
  }

  Future<void> _saveToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await Future.wait([
      prefs.setString(_kName, displayName),
      if (avatarUrl != null)
        prefs.setString(_kAvatar, avatarUrl!)
      else
        prefs.remove(_kAvatar),
      prefs.setString(_kGender, gender),
      prefs.setInt(_kElo, eloRating),
      prefs.setInt(_kPlayed, gamesPlayed),
      prefs.setInt(_kWon, gamesWon),
      prefs.setInt(_kChkobbas, totalChkobbas),
    ]);
  }

  // ─── Update helpers ────────────────────────────────────────────────────────

  Future<void> updateDisplayName(String userId, String newName) async {
    displayName = newName;
    notifyListeners();
    await _saveToPrefs();
    try {
      await SupabaseService.client
          .from('profiles')
          .update({'display_name': newName}).eq('id', userId);
    } catch (e) {
      debugPrint('[ProfileService] updateDisplayName DB failed: $e');
    }
  }

  Future<void> updateGender(String userId, String newGender) async {
    if (newGender != 'male' && newGender != 'female') return;
    gender = newGender;
    notifyListeners();
    await _saveToPrefs();
    try {
      await SupabaseService.client
          .from('profiles')
          .update({'gender': newGender}).eq('id', userId);
    } catch (e) {
      debugPrint('[ProfileService] updateGender DB failed: $e');
    }
  }

  Future<void> updateAvatar(String userId, String newAvatarUrl) async {
    avatarUrl = newAvatarUrl;
    notifyListeners();
    await _saveToPrefs();
    try {
      await SupabaseService.client
          .from('profiles')
          .update({'avatar_url': newAvatarUrl}).eq('id', userId);
    } catch (e) {
      debugPrint('[ProfileService] updateAvatar DB failed: $e');
    }
  }

  // ─── Clear (on logout) ─────────────────────────────────────────────────────

  Future<void> clear() async {
    displayName = 'Joueur';
    avatarUrl = null;
    gender = 'male';
    eloRating = 1000;
    gamesPlayed = 0;
    gamesWon = 0;
    totalChkobbas = 0;
    _loaded = false;

    final prefs = await SharedPreferences.getInstance();
    await Future.wait([
      prefs.remove(_kName),
      prefs.remove(_kAvatar),
      prefs.remove(_kGender),
      prefs.remove(_kElo),
      prefs.remove(_kPlayed),
      prefs.remove(_kWon),
      prefs.remove(_kChkobbas),
    ]);
    notifyListeners();
  }
}
