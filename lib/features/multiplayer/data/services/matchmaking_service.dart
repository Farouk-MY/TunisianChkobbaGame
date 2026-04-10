// lib/features/multiplayer/data/services/matchmaking_service.dart

import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/services/supabase_service.dart';

/// Match status constants
class MatchStatus {
  static const waiting = 'waiting';
  static const playing = 'playing';
  static const finished = 'finished';
}

/// Data class representing a match row from Supabase.
class MatchData {
  final String id;
  final String matchCode;
  final String hostId;
  final String hostName;
  final String? hostAvatar;
  final String? guestId;
  final String? guestName;
  final String? guestAvatar;
  final String status;
  final int targetScore;
  final String? winnerId;
  final int hostScore;
  final int guestScore;
  final DateTime createdAt;

  const MatchData({
    required this.id,
    required this.matchCode,
    required this.hostId,
    required this.hostName,
    this.hostAvatar,
    this.guestId,
    this.guestName,
    this.guestAvatar,
    required this.status,
    required this.targetScore,
    this.winnerId,
    required this.hostScore,
    required this.guestScore,
    required this.createdAt,
  });

  bool get isWaiting => status == MatchStatus.waiting;
  bool get isPlaying => status == MatchStatus.playing;
  bool get isFinished => status == MatchStatus.finished;
  bool get hasGuest => guestId != null;

  factory MatchData.fromMap(Map<String, dynamic> map) {
    return MatchData(
      id: map['id'] as String,
      matchCode: map['match_code'] as String,
      hostId: map['host_id'] as String,
      hostName: map['host_name'] as String? ?? 'Joueur',
      hostAvatar: map['host_avatar'] as String?,
      guestId: map['guest_id'] as String?,
      guestName: map['guest_name'] as String?,
      guestAvatar: map['guest_avatar'] as String?,
      status: map['status'] as String? ?? MatchStatus.waiting,
      targetScore: map['target_score'] as int? ?? 21,
      winnerId: map['winner_id'] as String?,
      hostScore: map['host_score'] as int? ?? 0,
      guestScore: map['guest_score'] as int? ?? 0,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}

/// Service responsible for match creation, joining, and lifecycle.
class MatchmakingService {
  MatchmakingService._();
  static final MatchmakingService instance = MatchmakingService._();

  RealtimeChannel? _matchChannel;
  StreamController<MatchData>? _matchStreamController;

  // ─── Match Code Generation ─────────────────────────────────────────────────

  /// Generate a 6-character uppercase alphanumeric match code.
  static String _generateMatchCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'; // No O/0/1/I confusion
    final rng = Random.secure();
    return List.generate(6, (_) => chars[rng.nextInt(chars.length)]).join();
  }

  // ─── Create Match ──────────────────────────────────────────────────────────

  /// Create a new match. Returns the created [MatchData].
  Future<MatchData> createMatch({int targetScore = 21}) async {
    final userId = SupabaseService.currentUserId;
    if (userId == null) throw Exception('Not authenticated');

    // Fetch host profile for display info
    final profile = await SupabaseService.client
        .from('profiles')
        .select('display_name, avatar_url')
        .eq('id', userId)
        .maybeSingle();

    final hostName = profile?['display_name'] as String? ?? 'Joueur';
    final hostAvatar = profile?['avatar_url'] as String?;

    // Try generating a unique code (retry on collision)
    String code;
    int attempts = 0;
    do {
      code = _generateMatchCode();
      attempts++;
      if (attempts > 10) throw Exception('Failed to generate unique code');
    } while (await _codeExists(code));

    final data = await SupabaseService.client.from('matches').insert({
      'match_code': code,
      'host_id': userId,
      'host_name': hostName,
      'host_avatar': hostAvatar,
      'target_score': targetScore,
      'status': MatchStatus.waiting,
    }).select().single();

    debugPrint('[Matchmaking] Created match: $code');
    return MatchData.fromMap(data);
  }

  Future<bool> _codeExists(String code) async {
    final result = await SupabaseService.client
        .from('matches')
        .select('id')
        .eq('match_code', code)
        .eq('status', MatchStatus.waiting)
        .maybeSingle();
    return result != null;
  }

  // ─── Join by Code ──────────────────────────────────────────────────────────

  /// Join a match by its 6-character code. Returns updated [MatchData].
  Future<MatchData> joinByCode(String code) async {
    final userId = SupabaseService.currentUserId;
    if (userId == null) throw Exception('Not authenticated');

    final upperCode = code.toUpperCase().trim();

    // Find the match
    final matchRow = await SupabaseService.client
        .from('matches')
        .select()
        .eq('match_code', upperCode)
        .eq('status', MatchStatus.waiting)
        .maybeSingle();

    if (matchRow == null) {
      throw Exception('Match not found or already started');
    }

    final match = MatchData.fromMap(matchRow);

    // Can't join own match
    if (match.hostId == userId) {
      throw Exception('Cannot join your own match');
    }

    // Fetch guest profile
    final profile = await SupabaseService.client
        .from('profiles')
        .select('display_name, avatar_url')
        .eq('id', userId)
        .maybeSingle();

    final guestName = profile?['display_name'] as String? ?? 'Joueur';
    final guestAvatar = profile?['avatar_url'] as String?;

    // Update match with guest info and set to playing
    final updated = await SupabaseService.client
        .from('matches')
        .update({
          'guest_id': userId,
          'guest_name': guestName,
          'guest_avatar': guestAvatar,
          'status': MatchStatus.playing,
        })
        .eq('id', match.id)
        .eq('status', MatchStatus.waiting) // Optimistic lock
        .select()
        .single();

    debugPrint('[Matchmaking] Joined match: $upperCode');
    return MatchData.fromMap(updated);
  }

  // ─── Quick Match ───────────────────────────────────────────────────────────

  /// Find a random waiting match and join it, or create one if none available.
  Future<MatchData> quickMatch({int targetScore = 21}) async {
    final userId = SupabaseService.currentUserId;
    if (userId == null) throw Exception('Not authenticated');

    // Look for any waiting match not created by this user
    final waitingMatches = await SupabaseService.client
        .from('matches')
        .select()
        .eq('status', MatchStatus.waiting)
        .neq('host_id', userId)
        .order('created_at', ascending: true)
        .limit(5);

    if (waitingMatches.isNotEmpty) {
      // Try to join the oldest one
      final match = MatchData.fromMap(waitingMatches.first);
      try {
        return await joinByCode(match.matchCode);
      } catch (e) {
        debugPrint('[Matchmaking] Quick match join failed, creating: $e');
      }
    }

    // No matches available — create one
    return createMatch(targetScore: targetScore);
  }

  // ─── Cancel Match ──────────────────────────────────────────────────────────

  /// Cancel (delete) a waiting match. Only the host can do this.
  Future<void> cancelMatch(String matchId) async {
    final userId = SupabaseService.currentUserId;
    if (userId == null) return;

    await SupabaseService.client
        .from('matches')
        .delete()
        .eq('id', matchId)
        .eq('host_id', userId)
        .eq('status', MatchStatus.waiting);

    debugPrint('[Matchmaking] Cancelled match: $matchId');
  }

  // ─── Fetch Match ───────────────────────────────────────────────────────────

  /// Fetch a single match by ID.
  Future<MatchData?> getMatch(String matchId) async {
    final data = await SupabaseService.client
        .from('matches')
        .select()
        .eq('id', matchId)
        .maybeSingle();

    if (data == null) return null;
    return MatchData.fromMap(data);
  }

  // ─── Update Match Result ───────────────────────────────────────────────────

  /// Update a match with final results (called by host on game end).
  Future<void> finishMatch({
    required String matchId,
    required String winnerId,
    required int hostScore,
    required int guestScore,
  }) async {
    await SupabaseService.client
        .from('matches')
        .update({
          'status': MatchStatus.finished,
          'winner_id': winnerId,
          'host_score': hostScore,
          'guest_score': guestScore,
          'finished_at': DateTime.now().toIso8601String(),
        })
        .eq('id', matchId);

    debugPrint('[Matchmaking] Match finished: $matchId winner=$winnerId');
  }

  // ─── Realtime: Listen to Match Changes ─────────────────────────────────────

  /// Subscribe to real-time changes on a specific match.
  /// Returns a stream of [MatchData] updates.
  Stream<MatchData> listenToMatch(String matchId) {
    _matchStreamController?.close();
    _matchStreamController = StreamController<MatchData>.broadcast();

    _matchChannel = SupabaseService.client
        .channel('match-$matchId')
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'matches',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'id',
            value: matchId,
          ),
          callback: (payload) {
            final newData = payload.newRecord;
            if (newData.isNotEmpty) {
              _matchStreamController?.add(MatchData.fromMap(newData));
            }
          },
        )
        .subscribe();

    return _matchStreamController!.stream;
  }

  /// Stop listening to match changes.
  void stopListening() {
    _matchChannel?.unsubscribe();
    _matchChannel = null;
    _matchStreamController?.close();
    _matchStreamController = null;
  }

  // ─── ELO Update ────────────────────────────────────────────────────────────

  /// Update ELO ratings for both players after a match.
  /// Uses standard ELO formula: K=32.
  Future<void> updateElo({
    required String winnerId,
    required String loserId,
  }) async {
    try {
      // Fetch current ratings
      final profiles = await SupabaseService.client
          .from('profiles')
          .select('id, elo_rating, games_played, games_won, total_chkobbas')
          .or('id.eq.$winnerId,id.eq.$loserId');

      if (profiles.length < 2) return;

      final winnerProfile = profiles.firstWhere((p) => p['id'] == winnerId);
      final loserProfile = profiles.firstWhere((p) => p['id'] == loserId);

      final winnerElo = winnerProfile['elo_rating'] as int? ?? 1000;
      final loserElo = loserProfile['elo_rating'] as int? ?? 1000;

      // ELO calculation (K=32)
      const k = 32;
      final expectedWinner = 1.0 / (1.0 + pow(10, (loserElo - winnerElo) / 400.0));
      final expectedLoser = 1.0 - expectedWinner;

      final newWinnerElo = (winnerElo + k * (1 - expectedWinner)).round();
      final newLoserElo = (loserElo + k * (0 - expectedLoser)).round().clamp(100, 9999);

      // Update winner
      await SupabaseService.client.from('profiles').update({
        'elo_rating': newWinnerElo,
        'games_played': (winnerProfile['games_played'] as int? ?? 0) + 1,
        'games_won': (winnerProfile['games_won'] as int? ?? 0) + 1,
      }).eq('id', winnerId);

      // Update loser
      await SupabaseService.client.from('profiles').update({
        'elo_rating': newLoserElo,
        'games_played': (loserProfile['games_played'] as int? ?? 0) + 1,
      }).eq('id', loserId);

      debugPrint('[Matchmaking] ELO updated: winner $winnerElo→$newWinnerElo, loser $loserElo→$newLoserElo');
    } catch (e) {
      debugPrint('[Matchmaking] ELO update failed: $e');
    }
  }
}
