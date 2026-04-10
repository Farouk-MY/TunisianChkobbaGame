// lib/features/multiplayer/presentation/providers/online_game_provider.dart

import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../../game/domain/entities/game_state.dart';
import '../../../game/domain/entities/card.dart';
import '../../../game/domain/entities/player.dart';
import '../../../game/domain/usecases/initialize_game_usecase.dart';
import '../../../game/domain/usecases/play_card_usecase.dart';
import '../../../game/domain/usecases/validate_capture_usecase.dart';
import '../../../game/domain/usecases/calculate_score_usecase.dart';
import '../../data/services/matchmaking_service.dart';
import '../../data/services/online_game_service.dart';
import '../../../../core/services/supabase_service.dart';

/// Connection health
enum ConnectionStatus { connecting, connected, reconnecting, disconnected }

/// Online game provider — manages the full game lifecycle for multiplayer.
///
/// **Host**: runs the game engine locally, broadcasts state to guest.
/// **Guest**: sends actions, receives state from host.
class OnlineGameProvider extends ChangeNotifier {
  // ─── Dependencies ──────────────────────────────────────────────────────────
  final InitializeGameUseCase _initGame;
  final PlayCardUseCase _playCard;
  final ValidateCaptureUseCase _validateCapture;
  final OnlineGameService _gameService = OnlineGameService();
  final MatchmakingService _matchmaking = MatchmakingService.instance;

  OnlineGameProvider({
    required InitializeGameUseCase initializeGameUseCase,
    required PlayCardUseCase playCardUseCase,
    required ValidateCaptureUseCase validateCaptureUseCase,
  })  : _initGame = initializeGameUseCase,
        _playCard = playCardUseCase,
        _validateCapture = validateCaptureUseCase;

  // ─── State ─────────────────────────────────────────────────────────────────
  GameState? _gameState;
  MatchData? _matchData;
  bool _isHost = false;
  ConnectionStatus _connectionStatus = ConnectionStatus.disconnected;
  List<Card> _selectedCards = [];
  bool _isProcessing = false;
  String? _errorMessage;

  // Turn timer
  int _turnTimeRemaining = 30;
  Timer? _turnTimer;

  // Presence
  DateTime? _lastOpponentHeartbeat;
  Timer? _presenceCheckTimer;

  // Rematch
  bool _rematchRequested = false;
  bool _opponentRequestedRematch = false;
  bool _opponentForfeited = false;

  // Streams
  StreamSubscription? _stateSub;
  StreamSubscription? _actionSub;
  StreamSubscription? _eventSub;
  StreamSubscription? _presenceSub;

  // ─── Getters ───────────────────────────────────────────────────────────────
  GameState? get gameState => _gameState;
  MatchData? get matchData => _matchData;
  bool get isHost => _isHost;
  bool get hasGame => _gameState != null;
  ConnectionStatus get connectionStatus => _connectionStatus;
  List<Card> get selectedCards => _selectedCards;
  bool get isProcessing => _isProcessing;
  String? get errorMessage => _errorMessage;
  int get turnTimeRemaining => _turnTimeRemaining;
  bool get rematchRequested => _rematchRequested;
  bool get opponentRequestedRematch => _opponentRequestedRematch;
  bool get opponentForfeited => _opponentForfeited;

  String get matchCode => _matchData?.matchCode ?? '';

  bool get isMyTurn {
    if (_gameState == null) return false;
    final myId = SupabaseService.currentUserId;
    return _gameState!.currentPlayer.id == myId;
  }

  String get opponentName {
    if (_matchData == null) return 'Adversaire';
    return _isHost
        ? (_matchData!.guestName ?? 'Adversaire')
        : _matchData!.hostName;
  }

  String? get opponentAvatar {
    if (_matchData == null) return null;
    return _isHost ? _matchData!.guestAvatar : _matchData!.hostAvatar;
  }

  String get myId => SupabaseService.currentUserId ?? '';

  Player? get myPlayer {
    if (_gameState == null) return null;
    try {
      return _gameState!.players.firstWhere((p) => p.id == myId);
    } catch (_) {
      return null;
    }
  }

  Player? get opponentPlayer {
    if (_gameState == null) return null;
    try {
      return _gameState!.players.firstWhere((p) => p.id != myId);
    } catch (_) {
      return null;
    }
  }

  // ─── Host: Create & Start Game ─────────────────────────────────────────────

  /// Host creates the game state and waits for guest.
  Future<void> hostStartGame({
    required MatchData match,
    required String playerName,
    String? playerAvatar,
  }) async {
    _matchData = match;
    _isHost = true;
    _connectionStatus = ConnectionStatus.connecting;
    notifyListeners();

    // Join the Realtime channel
    await _gameService.joinChannel(match.id);
    _subscribeToStreams();

    _connectionStatus = ConnectionStatus.connected;
    notifyListeners();

    // Initialize the game with both players
    final hostPlayer = Player.human(
      id: match.hostId,
      name: playerName,
      avatarUrl: playerAvatar,
    );
    final guestPlayer = Player.online(
      id: match.guestId!,
      name: match.guestName ?? 'Adversaire',
      avatarUrl: match.guestAvatar,
    );

    _gameState = _initGame.execute(
      players: [hostPlayer, guestPlayer],
      targetScore: match.targetScore,
    );

    // State is ready (execute() already dealt initial cards)
    notifyListeners();

    // Broadcast initial state to guest
    _broadcastState();

    // Notify guest that game has started
    await _gameService.broadcastEvent(GameEvent.startGame, {
      'matchId': match.id,
    });

    // Start turn timer if it's host's turn
    _resetTurnTimer();
    _startPresenceCheck();
  }

  // ─── Guest: Join & Listen ──────────────────────────────────────────────────

  /// Guest joins the channel and listens for game state from host.
  Future<void> guestJoinGame({required MatchData match}) async {
    _matchData = match;
    _isHost = false;
    _connectionStatus = ConnectionStatus.connecting;
    notifyListeners();

    await _gameService.joinChannel(match.id);
    _subscribeToStreams();

    _connectionStatus = ConnectionStatus.connected;
    _startPresenceCheck();
    notifyListeners();
  }

  // ─── Stream Subscriptions ──────────────────────────────────────────────────

  void _subscribeToStreams() {
    // State updates (guest receives from host)
    _stateSub = _gameService.onGameState.listen((payload) {
      if (!_isHost) {
        try {
          _gameState = GameState.fromMap(payload);
          _resetTurnTimer();
          notifyListeners();
        } catch (e) {
          debugPrint('[OnlineGame] Error parsing state: $e');
        }
      }
    });

    // Action (host receives from guest)
    _actionSub = _gameService.onAction.listen((payload) {
      if (_isHost) {
        _handleGuestAction(payload);
      }
    });

    // Events (both)
    _eventSub = _gameService.onEvent.listen((payload) {
      _handleEvent(payload);
    });

    // Presence
    _presenceSub = _gameService.onPresence.listen((payload) {
      final senderId = payload['userId'] as String?;
      if (senderId != null && senderId != myId) {
        _lastOpponentHeartbeat = DateTime.now();
        if (_connectionStatus == ConnectionStatus.reconnecting) {
          _connectionStatus = ConnectionStatus.connected;
          notifyListeners();
        }
      }
    });
  }

  // ─── Host: Process Guest Action ────────────────────────────────────────────

  void _handleGuestAction(Map<String, dynamic> payload) {
    if (_gameState == null || !_isHost) return;
    if (_isProcessing) return;

    try {
      _isProcessing = true;
      notifyListeners();

      final guestId = _matchData?.guestId;
      if (guestId == null) {
        debugPrint('[OnlineGame] Guest action rejected: no guestId');
        _isProcessing = false;
        notifyListeners();
        return;
      }

      // Validate that it is indeed the guest's turn before processing
      if (_gameState!.currentPlayer.id != guestId) {
        debugPrint('[OnlineGame] Guest action rejected: not guest turn (current=${_gameState!.currentPlayer.id}, guest=$guestId)');
        _isProcessing = false;
        notifyListeners();
        return;
      }

      // Deserialize the card IDs from the action payload
      final playedCardMap = payload['playedCard'] as Map<String, dynamic>;
      final playedCardId = playedCardMap['id'] as String;

      final selectedCardIds = (payload['selectedCards'] as List<dynamic>)
          .map((c) => (c as Map<String, dynamic>)['id'] as String)
          .toSet();

      // Resolve the played card directly from the guest's hand in our game state
      // (prevents any chance of object mismatch from serialization)
      Card? resolvedPlayedCard;
      try {
        resolvedPlayedCard = _gameState!.currentPlayer.hand
            .firstWhere((c) => c.id == playedCardId);
      } catch (_) {
        debugPrint('[OnlineGame] Guest played card $playedCardId not found in hand: ${_gameState!.currentPlayer.hand.map((c) => c.id).toList()}');
        _isProcessing = false;
        notifyListeners();
        return;
      }

      // Resolve selected table cards from the actual table
      final resolvedSelectedCards = _gameState!.tableCards
          .where((c) => selectedCardIds.contains(c.id))
          .toList();

      // Execute the move using the game engine
      _gameState = _playCard.execute(
        gameState: _gameState!,
        playedCard: resolvedPlayedCard,
        selectedCards: resolvedSelectedCards,
      );

      _isProcessing = false;

      // Broadcast updated state to guest
      _broadcastState();

      // Check for special events
      _checkAndBroadcastEvents();

      _resetTurnTimer();
      notifyListeners();
    } catch (e) {
      debugPrint('[OnlineGame] Error processing guest action: $e');
      _isProcessing = false;
      notifyListeners();
    }
  }

  // ─── Player: Play Card ─────────────────────────────────────────────────────

  /// Called when the local player (host or guest) plays a card.
  Future<void> playCard(Card card) async {
    if (_gameState == null || _isProcessing) return;
    if (!isMyTurn) return;

    if (_isHost) {
      // Host: execute locally and broadcast
      try {
        _isProcessing = true;
        notifyListeners();

        _gameState = _playCard.execute(
          gameState: _gameState!,
          playedCard: card,
          selectedCards: _selectedCards,
        );

        _selectedCards = [];
        _isProcessing = false;

        _broadcastState();
        _checkAndBroadcastEvents();

        _resetTurnTimer();
        notifyListeners();
      } catch (e) {
        _errorMessage = e.toString();
        _isProcessing = false;
        notifyListeners();
      }
    } else {
      // Guest: Optimistic update + send action to host
      try {
        _isProcessing = true;

        // Snapshot before clearing
        final selectedSnapshot = List<Card>.from(_selectedCards);

        // ── Optimistic update: apply move locally for instant feedback ──
        GameState? optimisticState;
        try {
          optimisticState = _playCard.execute(
            gameState: _gameState!,
            playedCard: card,
            selectedCards: selectedSnapshot,
          );
        } catch (_) {
          // Optimistic update failed — host will send correct state
        }

        _selectedCards = [];

        if (optimisticState != null) {
          _gameState = optimisticState;
          notifyListeners(); // Instant visual feedback
        }

        // ── Send action to host ─────────────────────────────────────────
        await _gameService.broadcastAction({
          'playedCard': card.toMap(),
          'playedCardId': card.id,
          'selectedCards': selectedSnapshot.map((c) => c.toMap()).toList(),
          'selectedCardIds': selectedSnapshot.map((c) => c.id).toList(),
          'playerId': myId,
        });

        _isProcessing = false;
        notifyListeners();
      } catch (e) {
        _errorMessage = e.toString();
        _isProcessing = false;
        notifyListeners();
      }
    }
  }

  // ─── Card Selection ────────────────────────────────────────────────────────

  void toggleCardSelection(Card card) {
    if (_gameState == null || !_gameState!.isPlaying) return;
    if (!isMyTurn) return;

    if (_selectedCards.contains(card)) {
      _selectedCards.remove(card);
    } else {
      _selectedCards.add(card);
    }
    notifyListeners();
  }

  void clearSelection() {
    _selectedCards = [];
    notifyListeners();
  }

  // ─── Get Possible Captures ─────────────────────────────────────────────────

  CaptureOptions? getPossibleCaptures(Card card) {
    if (_gameState == null) return null;
    return _validateCapture.findPossibleCaptures(
      playedCard: card,
      tableCards: _gameState!.tableCards,
      isFinalMove: _gameState!.isFinalMove,
    );
  }

  bool validateCapture({
    required Card playedCard,
    required List<Card> selectedCards,
    required List<Card> tableCards,
  }) {
    return _validateCapture.isValidCapture(
      playedCard: playedCard,
      selectedCards: selectedCards,
      tableCards: tableCards,
    );
  }

  // ─── Event Broadcasting ────────────────────────────────────────────────────

  void _checkAndBroadcastEvents() {
    if (_gameState == null) return;

    // Check for chkobba (last capture was a chkobba)
    if (_gameState!.captureHistory.isNotEmpty) {
      final lastCapture = _gameState!.captureHistory.last;
      if (lastCapture.isChkobba) {
        _gameService.broadcastEvent(GameEvent.chkobba, {
          'playerId': lastCapture.playerId,
        });
      }
    }

    // Check for round end
    if (_gameState!.isRoundOver) {
      _gameService.broadcastEvent(GameEvent.roundEnd, {
        'players': _gameState!.players.map((p) => {
          'id': p.id,
          'name': p.name,
          'score': p.score,
          'chkobbas': p.chkobbas,
          'capturedCardCount': p.capturedCardCount,
        }).toList(),
        'roundNumber': _gameState!.roundNumber,
      });
    }

    // Check for game over
    if (_gameState!.isGameOver) {
      _stopTurnTimer();

      final winnerId = _gameState!.winnerPlayerId;
      _gameService.broadcastEvent(GameEvent.gameOver, {
        'winnerId': winnerId,
        'hostScore': _gameState!.players[0].score,
        'guestScore': _gameState!.players[1].score,
      });

      // Update match in database
      if (_isHost && _matchData != null && winnerId != null) {
        _matchmaking.finishMatch(
          matchId: _matchData!.id,
          winnerId: winnerId,
          hostScore: _gameState!.players[0].score,
          guestScore: _gameState!.players[1].score,
        );
        // Update ELO
        final loserId = _gameState!.players
            .firstWhere((p) => p.id != winnerId)
            .id;
        _matchmaking.updateElo(winnerId: winnerId, loserId: loserId);
      }
    }
  }

  void _broadcastState() {
    if (_gameState == null || !_isHost) return;
    // Host broadcasts full state (but hides guest's hand from other guests)
    final guestId = _matchData?.guestId;
    _gameService.broadcastGameState(_gameState!.toMap(forPlayer: guestId));
  }

  // ─── Event Handling ────────────────────────────────────────────────────────

  void _handleEvent(Map<String, dynamic> payload) {
    final type = payload['type'] as String?;

    switch (type) {
      case GameEvent.rematchRequest:
        _opponentRequestedRematch = true;
        notifyListeners();
        break;

      case GameEvent.rematchAccept:
        // Both agreed — restart will be triggered by host
        break;

      case GameEvent.forfeit:
        final forfeiter = payload['playerId'] as String?;
        if (forfeiter != null && forfeiter != myId) {
          // Opponent forfeited — flag UI immediately
          _opponentForfeited = true;
          // Host also ends the game officially
          if (_isHost && _gameState != null) {
            _gameState = _gameState!.endGame(myId);
            _broadcastState();
            _checkAndBroadcastEvents();
          }
          notifyListeners();
        }
        break;

      case GameEvent.startGame:
        // Guest received start signal (state will come separately)
        break;
    }
  }

  // ─── Turn Timer ────────────────────────────────────────────────────────────

  void _resetTurnTimer() {
    _stopTurnTimer();
    if (_gameState == null || !_gameState!.isPlaying) return;

    _turnTimeRemaining = 30;
    _turnTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _turnTimeRemaining--;
      if (_turnTimeRemaining <= 0) {
        timer.cancel();
        _handleTurnTimeout();
      }
      notifyListeners();
    });
  }

  void _stopTurnTimer() {
    _turnTimer?.cancel();
    _turnTimer = null;
  }

  void _handleTurnTimeout() {
    if (!_isHost || _gameState == null) return;
    if (!_gameState!.isPlaying) return;

    // Auto-play the lowest card with no capture (just drop on table)
    final currentPlayer = _gameState!.currentPlayer;
    if (currentPlayer.hand.isNotEmpty) {
      final lowestCard = currentPlayer.hand.reduce(
        (a, b) => a.value <= b.value ? a : b,
      );

      try {
        _gameState = _playCard.execute(
          gameState: _gameState!,
          playedCard: lowestCard,
          selectedCards: [],
        );
        _broadcastState();
        _checkAndBroadcastEvents();
        _resetTurnTimer();
        notifyListeners();
      } catch (e) {
        debugPrint('[OnlineGame] Auto-play failed: $e');
      }
    }
  }

  // ─── Next Round ────────────────────────────────────────────────────────────

  /// Transition from roundEnd → new round (called by UI).
  void startNextRound() {
    if (_gameState == null || !_gameState!.isRoundOver) return;
    if (!_isHost) return; // Only host controls round transitions

    _gameState = _gameState!.startNewRound();
    _gameState = _gameState!.dealInitialCards();

    _broadcastState();
    _resetTurnTimer();
    notifyListeners();
  }

  // ─── Presence Check ────────────────────────────────────────────────────────

  void _startPresenceCheck() {
    _presenceCheckTimer?.cancel();
    _lastOpponentHeartbeat = DateTime.now();

    _presenceCheckTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (_lastOpponentHeartbeat == null) return;

      final elapsed = DateTime.now().difference(_lastOpponentHeartbeat!);

      if (elapsed.inSeconds > 30) {
        // Opponent disconnected — handle forfeit
        if (_connectionStatus != ConnectionStatus.disconnected) {
          _connectionStatus = ConnectionStatus.disconnected;
          notifyListeners();
        }
      } else if (elapsed.inSeconds > 15) {
        if (_connectionStatus != ConnectionStatus.reconnecting) {
          _connectionStatus = ConnectionStatus.reconnecting;
          notifyListeners();
        }
      }
    });
  }

  // ─── Forfeit ───────────────────────────────────────────────────────────────

  Future<void> forfeit() async {
    await _gameService.broadcastEvent(GameEvent.forfeit, {
      'playerId': myId,
    });

    // If host, end the game with opponent as winner
    if (_isHost && _gameState != null) {
      final opponentId = _gameState!.players
          .firstWhere((p) => p.id != myId)
          .id;
      _gameState = _gameState!.endGame(opponentId);
      _broadcastState();
      _checkAndBroadcastEvents();
      notifyListeners();
    }
  }

  // ─── Rematch ───────────────────────────────────────────────────────────────

  Future<void> requestRematch() async {
    _rematchRequested = true;
    notifyListeners();

    await _gameService.broadcastEvent(GameEvent.rematchRequest, {
      'playerId': myId,
    });

    // If opponent already requested, both want rematch → restart
    if (_opponentRequestedRematch) {
      await _gameService.broadcastEvent(GameEvent.rematchAccept, {});
      await _startRematch();
    }
  }

  Future<void> _startRematch() async {
    if (!_isHost || _matchData == null) return;

    // Create a new match with same settings
    final newMatch = await _matchmaking.createMatch(
      targetScore: _matchData!.targetScore,
    );

    // Join automatically as host and start the game
    _rematchRequested = false;
    _opponentRequestedRematch = false;

    await hostStartGame(
      match: newMatch.copyWith(
        guestId: _matchData!.guestId,
        guestName: _matchData!.guestName,
        guestAvatar: _matchData!.guestAvatar,
      ),
      playerName: _matchData!.hostName,
      playerAvatar: _matchData!.hostAvatar,
    );
  }

  // ─── Cleanup ───────────────────────────────────────────────────────────────

  Future<void> leaveGame() async {
    _stopTurnTimer();
    _presenceCheckTimer?.cancel();
    _stateSub?.cancel();
    _actionSub?.cancel();
    _eventSub?.cancel();
    _presenceSub?.cancel();
    await _gameService.leaveChannel();

    _gameState = null;
    _matchData = null;
    _isHost = false;
    _connectionStatus = ConnectionStatus.disconnected;
    _selectedCards = [];
    _isProcessing = false;
    _errorMessage = null;
    _rematchRequested = false;
    _opponentRequestedRematch = false;

    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    leaveGame();
    _gameService.dispose();
    super.dispose();
  }
}

// ─── MatchData Extension ─────────────────────────────────────────────────────

extension MatchDataCopy on MatchData {
  MatchData copyWith({
    String? id,
    String? matchCode,
    String? hostId,
    String? hostName,
    String? hostAvatar,
    String? guestId,
    String? guestName,
    String? guestAvatar,
    String? status,
    int? targetScore,
    String? winnerId,
    int? hostScore,
    int? guestScore,
    DateTime? createdAt,
  }) {
    return MatchData(
      id: id ?? this.id,
      matchCode: matchCode ?? this.matchCode,
      hostId: hostId ?? this.hostId,
      hostName: hostName ?? this.hostName,
      hostAvatar: hostAvatar ?? this.hostAvatar,
      guestId: guestId ?? this.guestId,
      guestName: guestName ?? this.guestName,
      guestAvatar: guestAvatar ?? this.guestAvatar,
      status: status ?? this.status,
      targetScore: targetScore ?? this.targetScore,
      winnerId: winnerId ?? this.winnerId,
      hostScore: hostScore ?? this.hostScore,
      guestScore: guestScore ?? this.guestScore,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
