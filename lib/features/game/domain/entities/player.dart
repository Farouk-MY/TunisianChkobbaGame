// lib/features/game/domain/entities/player.dart

import 'package:equatable/equatable.dart';
import 'card.dart';

/// Player type enumeration
enum PlayerType {
  human,    // Human player
  ai,       // AI opponent
  online,   // Online multiplayer opponent
}

/// Represents a player in the Chkobba game
class Player extends Equatable {
  /// Unique identifier for the player
  final String id;

  /// Player's display name
  final String name;

  /// Type of player (human, AI, or online)
  final PlayerType type;

  /// Cards currently in the player's hand
  final List<Card> hand;

  /// Cards captured by the player during the current round
  final List<Card> capturedCards;

  /// Number of Chkobbas (table sweeps) scored by the player
  final int chkobbas;

  /// Current total score
  final int score;

  /// Avatar URL or identifier (for display)
  final String? avatarUrl;

  /// Whether it's currently this player's turn
  final bool isCurrentTurn;

  /// AI difficulty level (only relevant for AI players)
  final String? aiDifficulty;

  const Player({
    required this.id,
    required this.name,
    required this.type,
    this.hand = const [],
    this.capturedCards = const [],
    this.chkobbas = 0,
    this.score = 0,
    this.avatarUrl,
    this.isCurrentTurn = false,
    this.aiDifficulty,
  });

  // ==================== COMPUTED PROPERTIES ====================

  /// Check if this player is human
  bool get isHuman => type == PlayerType.human;

  /// Check if this player is AI
  bool get isAI => type == PlayerType.ai;

  /// Check if this player is online
  bool get isOnline => type == PlayerType.online;

  /// Number of cards in hand
  int get handSize => hand.length;

  /// Number of captured cards
  int get capturedCardCount => capturedCards.length;

  /// Check if player has cards in hand
  bool get hasCardsInHand => hand.isNotEmpty;

  /// Check if player has captured any cards
  bool get hasCapturedCards => capturedCards.isNotEmpty;

  /// Get all diamonds captured by this player
  List<Card> get capturedDiamonds {
    return capturedCards.where((card) => card.isDiamond).toList();
  }

  /// Count of diamonds captured
  int get diamondsCount => capturedDiamonds.length;

  /// Get all sevens captured by this player
  List<Card> get capturedSevens {
    return capturedCards.where((card) => card.isSeven).toList();
  }

  /// Get all sixes captured by this player (for Bermila tiebreaker)
  List<Card> get capturedSixes {
    return capturedCards.where((card) => card.isSix).toList();
  }

  /// Check if player captured the 7 of Diamonds
  bool get hasSevenOfDiamonds {
    return capturedCards.any((card) => card.isSevenOfDiamonds);
  }

  /// Number of diamonds captured
  int get diamondCount => capturedDiamonds.length;

  /// Number of sevens captured
  int get sevenCount => capturedSevens.length;

  /// Number of sixes captured
  int get sixCount => capturedSixes.length;

  // ==================== FACTORY CONSTRUCTORS ====================

  /// Create a human player
  factory Player.human({
    required String id,
    required String name,
    String? avatarUrl,
  }) {
    return Player(
      id: id,
      name: name,
      type: PlayerType.human,
      avatarUrl: avatarUrl,
    );
  }

  /// Create an AI player
  factory Player.ai({
    required String id,
    String name = 'AI',
    String aiDifficulty = 'medium',
  }) {
    return Player(
      id: id,
      name: name,
      type: PlayerType.ai,
      aiDifficulty: aiDifficulty,
    );
  }

  /// Create an online player
  factory Player.online({
    required String id,
    required String name,
    String? avatarUrl,
  }) {
    return Player(
      id: id,
      name: name,
      type: PlayerType.online,
      avatarUrl: avatarUrl,
    );
  }

  /// Create a guest player
  factory Player.guest({String name = 'Guest'}) {
    return Player(
      id: 'guest_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      type: PlayerType.human,
    );
  }

  // ==================== METHODS ====================

  /// Add a card to the player's hand
  Player addCardToHand(Card card) {
    return copyWith(
      hand: [...hand, card],
    );
  }

  /// Add multiple cards to the player's hand
  Player addCardsToHand(List<Card> cards) {
    return copyWith(
      hand: [...hand, ...cards],
    );
  }

  /// Remove a card from the player's hand
  Player removeCardFromHand(Card card) {
    final newHand = List<Card>.from(hand);
    newHand.remove(card);
    return copyWith(hand: newHand);
  }

  /// Add captured cards
  Player addCapturedCards(List<Card> cards) {
    return copyWith(
      capturedCards: [...capturedCards, ...cards],
    );
  }

  /// Increment Chkobba count
  Player incrementChkobba() {
    return copyWith(chkobbas: chkobbas + 1);
  }

  /// Update score
  Player updateScore(int newScore) {
    return copyWith(score: newScore);
  }

  /// Add points to current score
  Player addPoints(int points) {
    return copyWith(score: score + points);
  }

  /// Set as current turn
  Player setCurrentTurn(bool isTurn) {
    return copyWith(isCurrentTurn: isTurn);
  }

  /// Clear hand (used when dealing new cards)
  Player clearHand() {
    return copyWith(hand: []);
  }

  /// Reset for new round (keep score but clear cards and chkobbas)
  Player resetForNewRound() {
    return copyWith(
      hand: [],
      capturedCards: [],
      chkobbas: 0,
    );
  }

  /// Reset completely (new game)
  Player resetCompletely() {
    return copyWith(
      hand: [],
      capturedCards: [],
      chkobbas: 0,
      score: 0,
      isCurrentTurn: false,
    );
  }

  // ==================== UTILITY METHODS ====================

  /// Create a copy with optional changes
  Player copyWith({
    String? id,
    String? name,
    PlayerType? type,
    List<Card>? hand,
    List<Card>? capturedCards,
    int? chkobbas,
    int? score,
    String? avatarUrl,
    bool? isCurrentTurn,
    String? aiDifficulty,
  }) {
    return Player(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      hand: hand ?? this.hand,
      capturedCards: capturedCards ?? this.capturedCards,
      chkobbas: chkobbas ?? this.chkobbas,
      score: score ?? this.score,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      isCurrentTurn: isCurrentTurn ?? this.isCurrentTurn,
      aiDifficulty: aiDifficulty ?? this.aiDifficulty,
    );
  }

  /// Convert to map for serialization
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type.toString().split('.').last,
      'hand': hand.map((card) => card.toMap()).toList(),
      'capturedCards': capturedCards.map((card) => card.toMap()).toList(),
      'chkobbas': chkobbas,
      'score': score,
      'avatarUrl': avatarUrl,
      'isCurrentTurn': isCurrentTurn,
      'aiDifficulty': aiDifficulty,
    };
  }

  /// Create from map for deserialization
  factory Player.fromMap(Map<String, dynamic> map) {
    return Player(
      id: map['id'] as String,
      name: map['name'] as String,
      type: PlayerType.values.firstWhere(
            (e) => e.toString().split('.').last == map['type'],
      ),
      hand: (map['hand'] as List<dynamic>)
          .map((cardMap) => Card.fromMap(cardMap as Map<String, dynamic>))
          .toList(),
      capturedCards: (map['capturedCards'] as List<dynamic>)
          .map((cardMap) => Card.fromMap(cardMap as Map<String, dynamic>))
          .toList(),
      chkobbas: map['chkobbas'] as int,
      score: map['score'] as int,
      avatarUrl: map['avatarUrl'] as String?,
      isCurrentTurn: map['isCurrentTurn'] as bool,
      aiDifficulty: map['aiDifficulty'] as String?,
    );
  }

  // ==================== EQUATABLE IMPLEMENTATION ====================

  @override
  List<Object?> get props => [
    id,
    name,
    type,
    hand,
    capturedCards,
    chkobbas,
    score,
    avatarUrl,
    isCurrentTurn,
    aiDifficulty,
  ];

  @override
  String toString() => 'Player($name, Score: $score, Cards: $handSize)';
}