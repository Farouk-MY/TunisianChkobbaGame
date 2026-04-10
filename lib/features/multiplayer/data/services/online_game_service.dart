// lib/features/multiplayer/data/services/online_game_service.dart

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/services/supabase_service.dart';

/// Event types used in the Realtime broadcast channel.
class GameEvent {
  static const gameState = 'game_state';
  static const playerAction = 'player_action';
  static const chkobba = 'chkobba';
  static const roundEnd = 'round_end';
  static const gameOver = 'game_over';
  static const rematchRequest = 'rematch_request';
  static const rematchAccept = 'rematch_accept';
  static const forfeit = 'forfeit';
  static const presence = 'presence';
  static const startGame = 'start_game';
}

/// Service wrapping a Supabase Realtime Broadcast channel for
/// synchronising game state between host and guest.
///
/// Host broadcasts the full [GameState] after every move.
/// Guest sends [playerAction] payloads (which card to play + captures).
class OnlineGameService {
  RealtimeChannel? _channel;
  String? _currentMatchId;
  Timer? _heartbeatTimer;

  // ─── Stream Controllers ────────────────────────────────────────────────────

  final _gameStateController = StreamController<Map<String, dynamic>>.broadcast();
  final _actionController = StreamController<Map<String, dynamic>>.broadcast();
  final _eventController = StreamController<Map<String, dynamic>>.broadcast();
  final _presenceController = StreamController<Map<String, dynamic>>.broadcast();

  /// Host listens: receives guest actions.
  Stream<Map<String, dynamic>> get onAction => _actionController.stream;

  /// Guest listens: receives full game state from host.
  Stream<Map<String, dynamic>> get onGameState => _gameStateController.stream;

  /// Both listen: game events (chkobba, round-end, game-over, rematch, forfeit).
  Stream<Map<String, dynamic>> get onEvent => _eventController.stream;

  /// Both listen: opponent presence heartbeats.
  Stream<Map<String, dynamic>> get onPresence => _presenceController.stream;

  bool get isConnected => _channel != null;
  String? get matchId => _currentMatchId;

  // ─── Channel Lifecycle ─────────────────────────────────────────────────────

  /// Join (or create) the Realtime broadcast channel for the given match.
  Future<void> joinChannel(String matchId) async {
    // Leave any existing channel first
    await leaveChannel();

    _currentMatchId = matchId;
    debugPrint('[OnlineGame] Joining channel game:$matchId');

    _channel = SupabaseService.client.channel(
      'game:$matchId',
      opts: const RealtimeChannelConfig(self: true),
    );

    // Listen for all broadcast events
    _channel!
        .onBroadcast(
          event: GameEvent.gameState,
          callback: (payload) {
            _gameStateController.add(payload);
          },
        )
        .onBroadcast(
          event: GameEvent.playerAction,
          callback: (payload) {
            _actionController.add(payload);
          },
        )
        .onBroadcast(
          event: GameEvent.chkobba,
          callback: (payload) {
            _eventController.add({'type': GameEvent.chkobba, ...payload});
          },
        )
        .onBroadcast(
          event: GameEvent.roundEnd,
          callback: (payload) {
            _eventController.add({'type': GameEvent.roundEnd, ...payload});
          },
        )
        .onBroadcast(
          event: GameEvent.gameOver,
          callback: (payload) {
            _eventController.add({'type': GameEvent.gameOver, ...payload});
          },
        )
        .onBroadcast(
          event: GameEvent.rematchRequest,
          callback: (payload) {
            _eventController.add({'type': GameEvent.rematchRequest, ...payload});
          },
        )
        .onBroadcast(
          event: GameEvent.rematchAccept,
          callback: (payload) {
            _eventController.add({'type': GameEvent.rematchAccept, ...payload});
          },
        )
        .onBroadcast(
          event: GameEvent.forfeit,
          callback: (payload) {
            _eventController.add({'type': GameEvent.forfeit, ...payload});
          },
        )
        .onBroadcast(
          event: GameEvent.startGame,
          callback: (payload) {
            _eventController.add({'type': GameEvent.startGame, ...payload});
          },
        )
        .onBroadcast(
          event: GameEvent.presence,
          callback: (payload) {
            _presenceController.add(payload);
          },
        )
        .subscribe((status, [error]) {
          debugPrint('[OnlineGame] Channel status: $status error: $error');
        });

    // Start heartbeat
    _startHeartbeat();
  }

  /// Leave and clean up the current channel.
  Future<void> leaveChannel() async {
    _stopHeartbeat();
    if (_channel != null) {
      await _channel!.unsubscribe();
      _channel = null;
      _currentMatchId = null;
      debugPrint('[OnlineGame] Left channel');
    }
  }

  // ─── Broadcasting ──────────────────────────────────────────────────────────

  /// Host: broadcast the full serialised game state.
  Future<void> broadcastGameState(Map<String, dynamic> state) async {
    if (_channel == null) return;
    await _channel!.sendBroadcastMessage(
      event: GameEvent.gameState,
      payload: state,
    );
  }

  /// Guest: broadcast an action (played card + selected table cards).
  Future<void> broadcastAction(Map<String, dynamic> action) async {
    if (_channel == null) return;
    await _channel!.sendBroadcastMessage(
      event: GameEvent.playerAction,
      payload: action,
    );
  }

  /// Broadcast a game event (chkobba, round-end, game-over, rematch, forfeit).
  Future<void> broadcastEvent(String eventType, Map<String, dynamic> data) async {
    if (_channel == null) return;
    await _channel!.sendBroadcastMessage(
      event: eventType,
      payload: data,
    );
  }

  // ─── Heartbeat / Presence ──────────────────────────────────────────────────

  void _startHeartbeat() {
    _stopHeartbeat();
    final userId = SupabaseService.currentUserId ?? 'unknown';
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _channel?.sendBroadcastMessage(
        event: GameEvent.presence,
        payload: {
          'userId': userId,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        },
      );
    });
  }

  void _stopHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
  }

  // ─── Cleanup ───────────────────────────────────────────────────────────────

  void dispose() {
    _stopHeartbeat();
    _channel?.unsubscribe();
    _gameStateController.close();
    _actionController.close();
    _eventController.close();
    _presenceController.close();
  }
}
