// lib/features/game/domain/entities/card.dart

import 'package:equatable/equatable.dart';
import '../../../../core/constants/game_constants.dart';

/// Represents a playing card in the Chkobba game
///
/// This is a pure domain entity with no dependencies on Flutter or external packages
/// (except Equatable for value equality)
class Card extends Equatable {
  /// Card rank (1=Ace, 2-7=number cards, 11=Jack, 12=Queen, 13=King)
  final int rank;

  /// Card suit (hearts, diamonds, clubs, spades)
  final String suit;

  /// Unique identifier for this card
  final String id;

  const Card({
    required this.rank,
    required this.suit,
    required this.id,
  });

  // ==================== COMPUTED PROPERTIES ====================

  /// Get the game value of this card (used for capture calculations)
  /// Ace=1, 2-7=face value, Queen=8, Jack=9, King=10
  int get value => GameConstants.getCardValue(rank);

  /// Check if this card is the special 7 of Diamonds
  bool get isSevenOfDiamonds =>
      rank == 7 && suit == GameConstants.diamonds;

  /// Check if this card is a seven (for Bermila scoring)
  bool get isSeven => rank == 7;

  /// Check if this card is a six (for Bermila tiebreaker)
  bool get isSix => rank == 6;

  /// Check if this card is a diamond (for Dinari scoring)
  bool get isDiamond => suit == GameConstants.diamonds;

  /// Check if this card is a face card (Jack, Queen, King)
  bool get isFaceCard => GameConstants.faceCardRanks.contains(rank);

  /// Check if this card is a number card (Ace through 7)
  bool get isNumberCard => GameConstants.numberCardRanks.contains(rank);

  // ==================== DISPLAY METHODS ====================

  /// Get display name for this card's rank
  String getRankName({bool isArabic = false}) {
    return GameConstants.getRankName(rank, isArabic: isArabic);
  }

  /// Get display name for this card's suit
  String getSuitName({bool isArabic = false}) {
    return GameConstants.getSuitName(suit, isArabic: isArabic);
  }

  /// Get symbol for this card's suit (♥ ♦ ♣ ♠)
  String getSuitSymbol() {
    return GameConstants.getSuitSymbol(suit);
  }

  /// Get full display name (e.g., "Ace of Hearts", "7 of Diamonds")
  String getFullName({bool isArabic = false}) {
    return '${getRankName(isArabic: isArabic)} of ${getSuitName(isArabic: isArabic)}';
  }

  /// Get short display name (e.g., "A♥", "7♦")
  String getShortName() {
    final rankDisplay = rank == 1 ? 'A' : rank.toString();
    return '$rankDisplay${getSuitSymbol()}';
  }

  // ==================== FACTORY CONSTRUCTORS ====================

  /// Create a card from rank and suit
  factory Card.fromRankAndSuit(int rank, String suit) {
    // Validate inputs
    if (!GameConstants.isValidRank(rank)) {
      throw ArgumentError('Invalid card rank: $rank');
    }
    if (!GameConstants.isValidSuit(suit)) {
      throw ArgumentError('Invalid card suit: $suit');
    }

    return Card(
      rank: rank,
      suit: suit,
      id: '${rank}_$suit',
    );
  }

  /// Create the special 7 of Diamonds card
  factory Card.sevenOfDiamonds() {
    return Card.fromRankAndSuit(7, GameConstants.diamonds);
  }

  // ==================== COMPARISON METHODS ====================

  /// Compare cards by value (for sorting)
  int compareTo(Card other) {
    // First compare by value
    final valueComparison = value.compareTo(other.value);
    if (valueComparison != 0) return valueComparison;

    // If values are equal, compare by suit
    return suit.compareTo(other.suit);
  }

  /// Check if this card can capture another card (same value)
  bool canCapture(Card other) {
    return value == other.value;
  }

  /// Check if this card's value equals the sum of a list of cards
  bool canCaptureSum(List<Card> cards) {
    if (cards.isEmpty) return false;
    final sum = cards.fold<int>(0, (total, card) => total + card.value);
    return value == sum;
  }

  // ==================== UTILITY METHODS ====================

  /// Create a copy of this card with optional changes
  Card copyWith({
    int? rank,
    String? suit,
    String? id,
  }) {
    return Card(
      rank: rank ?? this.rank,
      suit: suit ?? this.suit,
      id: id ?? this.id,
    );
  }

  /// Convert to a map (for serialization)
  Map<String, dynamic> toMap() {
    return {
      'rank': rank,
      'suit': suit,
      'id': id,
    };
  }

  /// Create from a map (for deserialization)
  factory Card.fromMap(Map<String, dynamic> map) {
    return Card(
      rank: map['rank'] as int,
      suit: map['suit'] as String,
      id: map['id'] as String,
    );
  }

  // ==================== EQUATABLE IMPLEMENTATION ====================

  @override
  List<Object?> get props => [id]; // Cards are equal if they have the same ID

  @override
  String toString() => getShortName();
}

// ==================== HELPER CLASS: DECK ====================

/// Helper class to create and manage a deck of cards
class Deck {
  /// Create a full deck of 40 Chkobba cards
  static List<Card> createFullDeck() {
    final cards = <Card>[];

    for (final suit in GameConstants.allSuits) {
      for (final rank in GameConstants.allRanks) {
        cards.add(Card.fromRankAndSuit(rank, suit));
      }
    }

    return cards;
  }

  /// Shuffle a deck of cards
  static List<Card> shuffle(List<Card> cards) {
    final shuffled = List<Card>.from(cards);
    shuffled.shuffle();
    return shuffled;
  }

  /// Create and shuffle a new deck
  static List<Card> createAndShuffle() {
    return shuffle(createFullDeck());
  }

  /// Sort cards by value (ascending)
  static List<Card> sortByValue(List<Card> cards) {
    final sorted = List<Card>.from(cards);
    sorted.sort((a, b) => a.compareTo(b));
    return sorted;
  }

  /// Group cards by suit
  static Map<String, List<Card>> groupBySuit(List<Card> cards) {
    final grouped = <String, List<Card>>{};

    for (final suit in GameConstants.allSuits) {
      grouped[suit] = cards.where((card) => card.suit == suit).toList();
    }

    return grouped;
  }

  /// Get all diamonds from a list of cards
  static List<Card> getDiamonds(List<Card> cards) {
    return cards.where((card) => card.isDiamond).toList();
  }

  /// Get all sevens from a list of cards
  static List<Card> getSevens(List<Card> cards) {
    return cards.where((card) => card.isSeven).toList();
  }

  /// Get all sixes from a list of cards
  static List<Card> getSixes(List<Card> cards) {
    return cards.where((card) => card.isSix).toList();
  }
}