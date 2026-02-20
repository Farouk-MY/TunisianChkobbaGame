// lib/features/game/domain/usecases/validate_capture_usecase.dart

import '../entities/card.dart';
import '../entities/capture.dart';
import '../../../../core/constants/game_constants.dart';

class ValidateCaptureUseCase {
  /// Find all possible captures for a given card
  CaptureOptions findPossibleCaptures({
    required Card playedCard,
    required List<Card> tableCards,
    required bool isFinalMove,
  }) {
    final singleMatches = _findSingleMatches(playedCard, tableCards);
    final sumCombinations = _findSumCombinations(playedCard, tableCards);

    return CaptureOptions(
      playedCard: playedCard,
      singleMatches: singleMatches,
      sumCombinations: sumCombinations,
      canCapture: singleMatches.isNotEmpty || sumCombinations.isNotEmpty,
      isFinalMove: isFinalMove,
    );
  }

  /// Create a capture based on player selection
  Capture createCapture({
    required Card playedCard,
    required List<Card> selectedCards,
    required List<Card> tableCards,
    required String playerId,
    required bool isFinalMove,
  }) {
    if (selectedCards.isEmpty) {
      return Capture.noCapture(
        playedCard: playedCard,
        playerId: playerId,
      );
    }

    // Check if Chkobba
    final isChkobba = !isFinalMove &&
        selectedCards.length == tableCards.length &&
        tableCards.isNotEmpty;

    // Determine capture type
    if (selectedCards.length == 1) {
      return Capture.single(
        playedCard: playedCard,
        capturedCard: selectedCards.first,
        playerId: playerId,
        isChkobba: isChkobba,
      );
    } else {
      return Capture.sum(
        playedCard: playedCard,
        capturedCards: selectedCards,
        playerId: playerId,
        isChkobba: isChkobba,
      );
    }
  }

  /// Validate if a capture is legal
  bool isValidCapture({
    required Card playedCard,
    required List<Card> selectedCards,
    required List<Card> tableCards,
  }) {
    if (selectedCards.isEmpty) return true; // No capture is valid

    // Check all selected cards are on table
    for (final card in selectedCards) {
      if (!tableCards.contains(card)) return false;
    }

    // Single card match
    if (selectedCards.length == 1) {
      return playedCard.value == selectedCards.first.value;
    }

    // Sum match
    final sum = selectedCards.fold<int>(0, (total, card) => total + card.value);
    return playedCard.value == sum;
  }

  /// Get best capture automatically (for AI or auto-play)
  List<Card> getBestCapture({
    required Card playedCard,
    required List<Card> tableCards,
  }) {
    // Priority 1: Single match (game rules)
    final singleMatches = _findSingleMatches(playedCard, tableCards);
    if (singleMatches.isNotEmpty) {
      return [singleMatches.first];
    }

    // Priority 2: Sum combination (prefer capturing more cards)
    final sumCombinations = _findSumCombinations(playedCard, tableCards);
    if (sumCombinations.isNotEmpty) {
      sumCombinations.sort((a, b) => b.length.compareTo(a.length));
      return sumCombinations.first;
    }

    return [];
  }

  List<Card> _findSingleMatches(Card playedCard, List<Card> tableCards) {
    return tableCards.where((card) => card.value == playedCard.value).toList();
  }

  List<List<Card>> _findSumCombinations(Card playedCard, List<Card> tableCards) {
    final combinations = <List<Card>>[];
    final targetValue = playedCard.value;

    _findCombinationsRecursive(
      tableCards,
      targetValue,
      [],
      0,
      combinations,
    );

    return combinations;
  }

  void _findCombinationsRecursive(
      List<Card> cards,
      int target,
      List<Card> current,
      int startIndex,
      List<List<Card>> results,
      ) {
    final currentSum = current.fold<int>(0, (sum, card) => sum + card.value);

    if (currentSum == target && current.length > 1) {
      results.add(List<Card>.from(current));
      return;
    }

    if (currentSum >= target || startIndex >= cards.length) {
      return;
    }

    for (int i = startIndex; i < cards.length; i++) {
      current.add(cards[i]);
      _findCombinationsRecursive(cards, target, current, i + 1, results);
      current.removeLast();
    }
  }
}

class CaptureOptions {
  final Card playedCard;
  final List<Card> singleMatches;
  final List<List<Card>> sumCombinations;
  final bool canCapture;
  final bool isFinalMove;

  const CaptureOptions({
    required this.playedCard,
    required this.singleMatches,
    required this.sumCombinations,
    required this.canCapture,
    required this.isFinalMove,
  });

  bool get hasSingleMatch => singleMatches.isNotEmpty;
  bool get hasSumCombinations => sumCombinations.isNotEmpty;
  int get totalOptions => singleMatches.length + sumCombinations.length;
}