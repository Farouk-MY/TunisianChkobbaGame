// lib/features/game/domain/entities/game_state.dart

import 'package:equatable/equatable.dart';
import 'card.dart';
import 'player.dart';
import 'capture.dart';
import '../../../../core/constants/game_constants.dart';

/// Game phase enumeration
enum GamePhase {
  setup,       // Game is being set up
  dealing,     // Cards are being dealt
  playing,     // Active gameplay
  roundEnd,    // Round has ended, calculating scores
  gameEnd,     // Game has ended, showing final results
}

/// Represents the complete state of a Chkobba game
class GameState extends Equatable {
  /// Unique game identifier
  final String gameId;

  /// Current game phase
  final GamePhase phase;

  /// List of players in the game
  final List<Player> players;

  /// Index of the current player (whose turn it is)
  final int currentPlayerIndex;

  /// Cards currently on the table
  final List<Card> tableCards;

  /// Remaining cards in the deck
  final List<Card> deck;

  /// History of all captures made in the current round
  final List<Capture> captureHistory;

  /// ID of the player who last captured cards (for end-of-round rule)
  final String? lastCapturerPlayerId;

  /// Target score to win the game
  final int targetScore;

  /// Current round number
  final int roundNumber;

  /// Whether this is the final move of the round
  final bool isFinalMove;

  /// ID of the winning player (if game has ended)
  final String? winnerPlayerId;

  /// Timestamp when the game started
  final DateTime startTime;

  /// Timestamp of the last action
  final DateTime lastActionTime;

  const GameState({
    required this.gameId,
    required this.phase,
    required this.players,
    required this.currentPlayerIndex,
    required this.tableCards,
    required this.deck,
    required this.captureHistory,
    this.lastCapturerPlayerId,
    this.targetScore = GameConstants.defaultTargetScore,
    this.roundNumber = 1,
    this.isFinalMove = false,
    this.winnerPlayerId,
    required this.startTime,
    required this.lastActionTime,
  });

  // ==================== COMPUTED PROPERTIES ====================

  /// Get the current player
  Player get currentPlayer => players[currentPlayerIndex];

  /// Check if it's a human player's turn
  bool get isHumanTurn => currentPlayer.isHuman;

  /// Check if it's an AI player's turn
  bool get isAITurn => currentPlayer.isAI;

  /// Check if game is in active play
  bool get isPlaying => phase == GamePhase.playing;

  /// Check if game has ended
  bool get isGameOver => phase == GamePhase.gameEnd;

  /// Check if round has ended
  bool get isRoundOver => phase == GamePhase.roundEnd;

  /// Get number of players
  int get playerCount => players.length;

  /// Get number of cards remaining in deck
  int get deckSize => deck.length;

  /// Check if deck is empty
  bool get isDeckEmpty => deck.isEmpty;

  /// Check if all players have no cards
  bool get allPlayersOutOfCards => players.every((p) => p.hand.isEmpty);

  /// Check if table is empty
  bool get isTableEmpty => tableCards.isEmpty;

  /// Get the winning player (if game has ended)
  Player? get winner {
    if (winnerPlayerId == null) return null;
    return players.firstWhere((p) => p.id == winnerPlayerId);
  }

  /// Get player who last captured
  Player? get lastCapturer {
    if (lastCapturerPlayerId == null) return null;
    try {
      return players.firstWhere((p) => p.id == lastCapturerPlayerId);
    } catch (e) {
      return null;
    }
  }

  /// Get player by ID
  Player? getPlayerById(String playerId) {
    try {
      return players.firstWhere((p) => p.id == playerId);
    } catch (e) {
      return null;
    }
  }

  /// Get player by index
  Player? getPlayerByIndex(int index) {
    if (index < 0 || index >= players.length) return null;
    return players[index];
  }

  /// Get sorted players by score (descending)
  List<Player> getPlayersByScore() {
    final sorted = List<Player>.from(players);
    sorted.sort((a, b) => b.score.compareTo(a.score));
    return sorted;
  }

  /// Get the leading player
  Player get leadingPlayer => getPlayersByScore().first;

  // ==================== FACTORY CONSTRUCTORS ====================

  /// Create a new game
  factory GameState.newGame({
    required String gameId,
    required List<Player> players,
    int targetScore = GameConstants.defaultTargetScore,
  }) {
    // Validate inputs
    if (players.length < GameConstants.minPlayers ||
        players.length > GameConstants.maxPlayers) {
      throw ArgumentError(
        'Invalid player count: ${players.length}. '
            'Must be between ${GameConstants.minPlayers} and ${GameConstants.maxPlayers}',
      );
    }

    if (!GameConstants.isValidTargetScore(targetScore)) {
      throw ArgumentError('Invalid target score: $targetScore');
    }

    final now = DateTime.now();

    // Create and shuffle deck
    final deck = Deck.createAndShuffle();

    // Set first player as current
    final updatedPlayers = List<Player>.from(players);
    updatedPlayers[0] = updatedPlayers[0].setCurrentTurn(true);

    return GameState(
      gameId: gameId,
      phase: GamePhase.setup,
      players: updatedPlayers,
      currentPlayerIndex: 0,
      tableCards: [],
      deck: deck,
      captureHistory: [],
      targetScore: targetScore,
      roundNumber: 1,
      startTime: now,
      lastActionTime: now,
    );
  }

  // ==================== GAME ACTIONS ====================

  /// Deal initial cards (3 to each player, 4 to table)
  GameState dealInitialCards() {
    if (deck.length < (playerCount * GameConstants.cardsPerDeal +
        GameConstants.initialTableCards)) {
      throw StateError('Not enough cards in deck to deal');
    }

    var remainingDeck = List<Card>.from(deck);
    final updatedPlayers = <Player>[];

    // Deal cards to each player
    for (final player in players) {
      final playerCards = remainingDeck.take(GameConstants.cardsPerDeal).toList();
      remainingDeck = remainingDeck.skip(GameConstants.cardsPerDeal).toList();
      updatedPlayers.add(player.addCardsToHand(playerCards));
    }

    // Deal cards to table
    final newTableCards = remainingDeck.take(GameConstants.initialTableCards).toList();
    remainingDeck = remainingDeck.skip(GameConstants.initialTableCards).toList();

    return copyWith(
      phase: GamePhase.playing,
      players: updatedPlayers,
      tableCards: newTableCards,
      deck: remainingDeck,
      lastActionTime: DateTime.now(),
    );
  }

  /// Deal next round of cards (3 to each player)
  GameState dealNextRound() {
    if (deck.length < playerCount * GameConstants.cardsPerDeal) {
      throw StateError('Not enough cards in deck to deal');
    }

    var remainingDeck = List<Card>.from(deck);
    final updatedPlayers = <Player>[];

    // Deal cards to each player
    for (final player in players) {
      final playerCards = remainingDeck.take(GameConstants.cardsPerDeal).toList();
      remainingDeck = remainingDeck.skip(GameConstants.cardsPerDeal).toList();
      updatedPlayers.add(player.addCardsToHand(playerCards));
    }

    return copyWith(
      phase: GamePhase.playing,
      players: updatedPlayers,
      deck: remainingDeck,
      isFinalMove: remainingDeck.isEmpty, // Mark if this is the final deal
      lastActionTime: DateTime.now(),
    );
  }

  /// Play a card and execute capture
  GameState playCard(Card card, Capture capture) {
    // Validate that the card is in current player's hand
    if (!currentPlayer.hand.contains(card)) {
      throw StateError('Card not in player hand: $card');
    }

    // Validate capture is legal
    if (!capture.isValid()) {
      throw StateError('Invalid capture: ${capture.getSummary()}');
    }

    // Update current player
    var updatedPlayer = currentPlayer.removeCardFromHand(card);

    // Update table cards
    var updatedTableCards = List<Card>.from(tableCards);

    if (capture.isCaptureSuccessful) {
      // Remove captured cards from table
      for (final capturedCard in capture.capturedCards) {
        updatedTableCards.remove(capturedCard);
      }

      // Add all cards to player's captured pile
      updatedPlayer = updatedPlayer.addCapturedCards(capture.allCards);

      // Increment chkobba count if applicable
      if (capture.isChkobba) {
        updatedPlayer = updatedPlayer.incrementChkobba();
      }
    } else {
      // No capture - add played card to table
      updatedTableCards.add(card);
    }

    // Update players list
    final updatedPlayers = List<Player>.from(players);
    updatedPlayers[currentPlayerIndex] = updatedPlayer;

    // Add to capture history
    final updatedHistory = [...captureHistory, capture];

    // Update last capturer if capture was successful
    final newLastCapturer = capture.isCaptureSuccessful
        ? currentPlayer.id
        : lastCapturerPlayerId;

    return copyWith(
      players: updatedPlayers,
      tableCards: updatedTableCards,
      captureHistory: updatedHistory,
      lastCapturerPlayerId: newLastCapturer,
      lastActionTime: DateTime.now(),
    );
  }

  /// Move to next player's turn
  GameState nextTurn() {
    // Clear current player's turn flag
    final updatedPlayers = List<Player>.from(players);
    updatedPlayers[currentPlayerIndex] =
        updatedPlayers[currentPlayerIndex].setCurrentTurn(false);

    // Move to next player
    final nextIndex = (currentPlayerIndex + 1) % playerCount;
    updatedPlayers[nextIndex] = updatedPlayers[nextIndex].setCurrentTurn(true);

    return copyWith(
      players: updatedPlayers,
      currentPlayerIndex: nextIndex,
      lastActionTime: DateTime.now(),
    );
  }

  /// End the current round
  GameState endRound() {
    // Give remaining table cards to last capturer
    var updatedPlayers = List<Player>.from(players);

    if (lastCapturerPlayerId != null && tableCards.isNotEmpty) {
      final capturerIndex = updatedPlayers
          .indexWhere((p) => p.id == lastCapturerPlayerId);

      if (capturerIndex != -1) {
        updatedPlayers[capturerIndex] = updatedPlayers[capturerIndex]
            .addCapturedCards(tableCards);
      }
    }

    return copyWith(
      phase: GamePhase.roundEnd,
      players: updatedPlayers,
      tableCards: [], // Clear table
      lastActionTime: DateTime.now(),
    );
  }

  /// Start a new round
  GameState startNewRound() {
    // Create new shuffled deck
    final newDeck = Deck.createAndShuffle();

    // Reset players for new round
    final updatedPlayers = players
        .map((p) => p.resetForNewRound())
        .toList();

    // Set first player as current
    updatedPlayers[0] = updatedPlayers[0].setCurrentTurn(true);

    return copyWith(
      phase: GamePhase.dealing,
      players: updatedPlayers,
      currentPlayerIndex: 0,
      tableCards: [],
      deck: newDeck,
      captureHistory: [],
      lastCapturerPlayerId: null,
      roundNumber: roundNumber + 1,
      isFinalMove: false,
      lastActionTime: DateTime.now(),
    );
  }

  /// End the game with a winner
  GameState endGame(String winnerPlayerId) {
    return copyWith(
      phase: GamePhase.gameEnd,
      winnerPlayerId: winnerPlayerId,
      lastActionTime: DateTime.now(),
    );
  }

  // ==================== UTILITY METHODS ====================

  /// Create a copy with optional changes
  GameState copyWith({
    String? gameId,
    GamePhase? phase,
    List<Player>? players,
    int? currentPlayerIndex,
    List<Card>? tableCards,
    List<Card>? deck,
    List<Capture>? captureHistory,
    String? lastCapturerPlayerId,
    int? targetScore,
    int? roundNumber,
    bool? isFinalMove,
    String? winnerPlayerId,
    DateTime? startTime,
    DateTime? lastActionTime,
  }) {
    return GameState(
      gameId: gameId ?? this.gameId,
      phase: phase ?? this.phase,
      players: players ?? this.players,
      currentPlayerIndex: currentPlayerIndex ?? this.currentPlayerIndex,
      tableCards: tableCards ?? this.tableCards,
      deck: deck ?? this.deck,
      captureHistory: captureHistory ?? this.captureHistory,
      lastCapturerPlayerId: lastCapturerPlayerId ?? this.lastCapturerPlayerId,
      targetScore: targetScore ?? this.targetScore,
      roundNumber: roundNumber ?? this.roundNumber,
      isFinalMove: isFinalMove ?? this.isFinalMove,
      winnerPlayerId: winnerPlayerId ?? this.winnerPlayerId,
      startTime: startTime ?? this.startTime,
      lastActionTime: lastActionTime ?? this.lastActionTime,
    );
  }

  // ==================== EQUATABLE IMPLEMENTATION ====================

  @override
  List<Object?> get props => [
    gameId,
    phase,
    players,
    currentPlayerIndex,
    tableCards,
    deck,
    captureHistory,
    lastCapturerPlayerId,
    targetScore,
    roundNumber,
    isFinalMove,
    winnerPlayerId,
    startTime,
    lastActionTime,
  ];

  @override
  String toString() =>
      'GameState(Phase: $phase, Round: $roundNumber, '
          'Current: ${currentPlayer.name}, Table: ${tableCards.length})';
}