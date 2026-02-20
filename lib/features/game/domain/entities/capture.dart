// lib/features/game/domain/entities/capture.dart

import 'package:equatable/equatable.dart';
import 'card.dart';

/// Type of capture that occurred
enum CaptureType {
  single,   // Captured a single card with matching value
  sum,      // Captured multiple cards whose values sum to played card
  none,     // No capture (card remains on table)
}

/// Represents a capture action in the game
/// Records what card was played and what cards (if any) were captured
class Capture extends Equatable {
  /// The card that was played by the player
  final Card playedCard;

  /// The cards that were captured from the table
  final List<Card> capturedCards;

  /// Type of capture that occurred
  final CaptureType type;

  /// Whether this capture was a Chkobba (swept the entire table)
  final bool isChkobba;

  /// ID of the player who made this capture
  final String playerId;

  /// Timestamp when the capture occurred
  final DateTime timestamp;

  const Capture({
    required this.playedCard,
    required this.capturedCards,
    required this.type,
    required this.isChkobba,
    required this.playerId,
    required this.timestamp,
  });

  // ==================== COMPUTED PROPERTIES ====================

  /// Check if any cards were captured
  bool get isCaptureSuccessful => capturedCards.isNotEmpty;

  /// Check if no capture occurred (card went to table)
  bool get isNoCapture => type == CaptureType.none;

  /// Check if this was a single-card capture
  bool get isSingleCapture => type == CaptureType.single;

  /// Check if this was a sum capture
  bool get isSumCapture => type == CaptureType.sum;

  /// Total number of cards involved in the capture (played + captured)
  int get totalCards => 1 + capturedCards.length;

  /// Total value of all captured cards
  int get totalCapturedValue {
    return capturedCards.fold<int>(
      0,
          (sum, card) => sum + card.value,
    );
  }

  /// All cards involved (played card + captured cards)
  List<Card> get allCards => [playedCard, ...capturedCards];

  // ==================== FACTORY CONSTRUCTORS ====================

  /// Create a single-card capture
  factory Capture.single({
    required Card playedCard,
    required Card capturedCard,
    required String playerId,
    required bool isChkobba,
  }) {
    return Capture(
      playedCard: playedCard,
      capturedCards: [capturedCard],
      type: CaptureType.single,
      isChkobba: isChkobba,
      playerId: playerId,
      timestamp: DateTime.now(),
    );
  }

  /// Create a sum capture (multiple cards)
  factory Capture.sum({
    required Card playedCard,
    required List<Card> capturedCards,
    required String playerId,
    required bool isChkobba,
  }) {
    return Capture(
      playedCard: playedCard,
      capturedCards: capturedCards,
      type: CaptureType.sum,
      isChkobba: isChkobba,
      playerId: playerId,
      timestamp: DateTime.now(),
    );
  }

  /// Create a no-capture (card goes to table)
  factory Capture.noCapture({
    required Card playedCard,
    required String playerId,
  }) {
    return Capture(
      playedCard: playedCard,
      capturedCards: const [],
      type: CaptureType.none,
      isChkobba: false,
      playerId: playerId,
      timestamp: DateTime.now(),
    );
  }

  // ==================== VALIDATION METHODS ====================

  /// Validate that this capture is legal according to game rules
  bool isValid() {
    // No capture is always valid (card goes to table)
    if (isNoCapture) return true;

    // Single capture: played card value must match captured card value
    if (isSingleCapture) {
      if (capturedCards.length != 1) return false;
      return playedCard.value == capturedCards.first.value;
    }

    // Sum capture: played card value must equal sum of captured cards
    if (isSumCapture) {
      if (capturedCards.isEmpty) return false;
      return playedCard.value == totalCapturedValue;
    }

    return false;
  }

  /// Check if this capture includes a specific card
  bool includesCard(Card card) {
    return playedCard == card || capturedCards.contains(card);
  }

  /// Check if this capture includes the 7 of Diamonds
  bool includesSevenOfDiamonds() {
    return allCards.any((card) => card.isSevenOfDiamonds);
  }

  /// Check if this capture includes any diamonds
  bool includesDiamonds() {
    return allCards.any((card) => card.isDiamond);
  }

  /// Check if this capture includes any sevens
  bool includesSevens() {
    return allCards.any((card) => card.isSeven);
  }

  // ==================== DISPLAY METHODS ====================

  /// Get a human-readable description of the capture
  String getDescription({bool isArabic = false}) {
    if (isNoCapture) {
      return isArabic
          ? 'لم يتم الالتقاط - الورقة على الطاولة'
          : 'No capture - card placed on table';
    }

    if (isChkobba) {
      return isArabic
          ? 'شكبة! تنظيف الطاولة'
          : 'Chkobba! Table swept clean';
    }

    if (isSingleCapture) {
      return isArabic
          ? 'التقط ${capturedCards.first.getFullName(isArabic: true)}'
          : 'Captured ${capturedCards.first.getFullName()}';
    }

    if (isSumCapture) {
      final cardNames = capturedCards
          .map((c) => c.getShortName())
          .join(', ');
      return isArabic
          ? 'التقط مجموع: $cardNames'
          : 'Captured sum: $cardNames';
    }

    return 'Unknown capture';
  }

  /// Get a short summary for logging
  String getSummary() {
    if (isNoCapture) return '${playedCard.getShortName()} → table';
    if (isChkobba) return '${playedCard.getShortName()} → CHKOBBA!';

    final capturedNames = capturedCards
        .map((c) => c.getShortName())
        .join('+');
    return '${playedCard.getShortName()} → $capturedNames';
  }

  // ==================== UTILITY METHODS ====================

  /// Create a copy with optional changes
  Capture copyWith({
    Card? playedCard,
    List<Card>? capturedCards,
    CaptureType? type,
    bool? isChkobba,
    String? playerId,
    DateTime? timestamp,
  }) {
    return Capture(
      playedCard: playedCard ?? this.playedCard,
      capturedCards: capturedCards ?? this.capturedCards,
      type: type ?? this.type,
      isChkobba: isChkobba ?? this.isChkobba,
      playerId: playerId ?? this.playerId,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  /// Convert to map for serialization
  Map<String, dynamic> toMap() {
    return {
      'playedCard': playedCard.toMap(),
      'capturedCards': capturedCards.map((card) => card.toMap()).toList(),
      'type': type.toString().split('.').last,
      'isChkobba': isChkobba,
      'playerId': playerId,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  /// Create from map for deserialization
  factory Capture.fromMap(Map<String, dynamic> map) {
    return Capture(
      playedCard: Card.fromMap(map['playedCard'] as Map<String, dynamic>),
      capturedCards: (map['capturedCards'] as List<dynamic>)
          .map((cardMap) => Card.fromMap(cardMap as Map<String, dynamic>))
          .toList(),
      type: CaptureType.values.firstWhere(
            (e) => e.toString().split('.').last == map['type'],
      ),
      isChkobba: map['isChkobba'] as bool,
      playerId: map['playerId'] as String,
      timestamp: DateTime.parse(map['timestamp'] as String),
    );
  }

  // ==================== EQUATABLE IMPLEMENTATION ====================

  @override
  List<Object?> get props => [
    playedCard,
    capturedCards,
    type,
    isChkobba,
    playerId,
    timestamp,
  ];

  @override
  String toString() => getSummary();
}

// ==================== HELPER: CAPTURE VALIDATOR ====================

/// Validates and creates captures according to Chkobba rules
class CaptureValidator {
  /// Find all valid single-card captures for a played card
  static List<Card> findSingleMatches(Card playedCard, List<Card> tableCards) {
    return tableCards
        .where((card) => card.value == playedCard.value)
        .toList();
  }

  /// Find all valid sum combinations for a played card
  /// Returns a list of possible capture combinations
  static List<List<Card>> findSumCombinations(
      Card playedCard,
      List<Card> tableCards,
      ) {
    final combinations = <List<Card>>[];
    final targetValue = playedCard.value;

    // Try all possible combinations of table cards
    _findCombinations(
      tableCards,
      targetValue,
      [],
      0,
      combinations,
    );

    return combinations;
  }

  /// Recursive helper to find all combinations that sum to target
  static void _findCombinations(
      List<Card> cards,
      int target,
      List<Card> current,
      int startIndex,
      List<List<Card>> results,
      ) {
    final currentSum = current.fold<int>(0, (sum, card) => sum + card.value);

    // Found a valid combination
    if (currentSum == target && current.length > 1) {
      results.add(List<Card>.from(current));
      return;
    }

    // Exceeded target or reached end
    if (currentSum >= target || startIndex >= cards.length) {
      return;
    }

    // Try including each remaining card
    for (int i = startIndex; i < cards.length; i++) {
      current.add(cards[i]);
      _findCombinations(cards, target, current, i + 1, results);
      current.removeLast();
    }
  }

  /// Check if played card results in a Chkobba
  /// (captures all cards on the table, but not on final move)
  static bool isChkobba(
      List<Card> capturedCards,
      List<Card> tableCards,
      bool isFinalMove,
      ) {
    if (isFinalMove) return false;
    return capturedCards.length == tableCards.length && tableCards.isNotEmpty;
  }
}