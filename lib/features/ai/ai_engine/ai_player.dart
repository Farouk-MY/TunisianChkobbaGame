// lib/features/ai/ai_engine/ai_player.dart

import 'dart:math';
import '../../../features/game/domain/entities/card.dart';
import '../../../features/game/domain/entities/game_state.dart';
import '../../../features/game/domain/usecases/validate_capture_usecase.dart';
import '../../../core/constants/game_constants.dart';

/// AI Player for Chkobba with multiple difficulty levels
class AIPlayer {
  final String difficulty;
  final Random _random = Random();
  final ValidateCaptureUseCase _validateCapture = ValidateCaptureUseCase();

  AIPlayer({this.difficulty = GameConstants.aiMedium});

  /// Select the best card to play based on difficulty
  AIMove selectMove(GameState gameState) {
    final hand = gameState.currentPlayer.hand;
    final tableCards = gameState.tableCards;
    
    if (hand.isEmpty) {
      throw StateError('AI has no cards to play');
    }

    switch (difficulty) {
      case GameConstants.aiEasy:
        return _selectEasyMove(hand, tableCards);
      case GameConstants.aiMedium:
        return _selectMediumMove(hand, tableCards);
      case GameConstants.aiHard:
        return _selectHardMove(hand, tableCards, gameState);
      case GameConstants.aiExpert:
        return _selectExpertMove(hand, tableCards, gameState);
      default:
        return _selectMediumMove(hand, tableCards);
    }
  }

  /// Easy: Mostly random with slight preference for captures
  AIMove _selectEasyMove(List<Card> hand, List<Card> tableCards) {
    // 30% chance to make a smart capture
    if (_random.nextDouble() < 0.3) {
      final captureMoves = _findAllCaptures(hand, tableCards);
      if (captureMoves.isNotEmpty) {
        return captureMoves[_random.nextInt(captureMoves.length)];
      }
    }
    
    // Otherwise play randomly
    return AIMove(
      card: hand[_random.nextInt(hand.length)],
      captureCards: [],
    );
  }

  /// Medium: Always capture if possible, prefer higher value captures
  AIMove _selectMediumMove(List<Card> hand, List<Card> tableCards) {
    final captureMoves = _findAllCaptures(hand, tableCards);
    
    if (captureMoves.isNotEmpty) {
      // Sort by number of cards captured
      captureMoves.sort((a, b) => 
        b.captureCards.length.compareTo(a.captureCards.length));
      return captureMoves.first;
    }
    
    // No capture possible - play lowest value card
    final sortedHand = List<Card>.from(hand)
      ..sort((a, b) => a.value.compareTo(b.value));
    return AIMove(card: sortedHand.first, captureCards: []);
  }

  /// Hard: Strategic with priority for valuable cards
  AIMove _selectHardMove(
    List<Card> hand,
    List<Card> tableCards,
    GameState gameState,
  ) {
    final captureMoves = _findAllCaptures(hand, tableCards);
    
    if (captureMoves.isNotEmpty) {
      // Score each capture
      int bestScore = -1000;
      AIMove? bestMove;
      
      for (final move in captureMoves) {
        int score = 0;
        
        // Points for number of cards
        score += move.captureCards.length * 2;
        
        // Extra points for 7 of diamonds
        if (move.captureCards.any((c) => c.isSevenOfDiamonds)) {
          score += 20;
        }
        
        // Points for diamonds
        score += move.captureCards.where((c) => c.isDiamond).length * 3;
        
        // Points for sevens
        score += move.captureCards.where((c) => c.isSeven).length * 4;
        
        // Chkobba bonus
        if (tableCards.length == move.captureCards.length) {
          if (!gameState.isFinalMove) {
            score += 15;
          }
        }
        
        if (score > bestScore) {
          bestScore = score;
          bestMove = move;
        }
      }
      
      if (bestMove != null) return bestMove;
    }
    
    // No capture - avoid leaving valuable cards for opponent
    return _selectSafeDrop(hand, tableCards);
  }

  /// Expert: Full game analysis with opponent prediction
  AIMove _selectExpertMove(
    List<Card> hand,
    List<Card> tableCards,
    GameState gameState,
  ) {
    final captureMoves = _findAllCaptures(hand, tableCards);
    
    if (captureMoves.isNotEmpty) {
      int bestScore = -1000;
      AIMove? bestMove;
      
      for (final move in captureMoves) {
        int score = 0;
        
        // Base capture value
        score += move.captureCards.length * 3;
        
        // 7 of diamonds is critical
        if (move.captureCards.any((c) => c.isSevenOfDiamonds)) {
          score += 50;
        }
        
        // Diamonds are valuable
        score += move.captureCards.where((c) => c.isDiamond).length * 5;
        
        // Sevens for bermila
        score += move.captureCards.where((c) => c.isSeven).length * 8;
        
        // Sixes (bermila tiebreaker)
        score += move.captureCards.where((c) => c.isSix).length * 2;
        
        // Chkobba (except on final move)
        if (tableCards.length == move.captureCards.length) {
          if (!gameState.isFinalMove) {
            score += 25;
          }
        }
        
        // Avoid leaving chkobba opportunity for opponent
        final remainingTable = tableCards
            .where((c) => !move.captureCards.contains(c))
            .toList();
        if (remainingTable.isNotEmpty) {
          // Check if any single card could capture all remaining
          final remainingSum = remainingTable.fold<int>(
            0, (sum, card) => sum + card.value);
          if (remainingSum <= 10) {
            score -= 10; // Penalty for leaving easy chkobba
          }
        }
        
        if (score > bestScore) {
          bestScore = score;
          bestMove = move;
        }
      }
      
      if (bestMove != null) return bestMove;
    }
    
    // No capture - expert drop strategy
    return _selectExpertDrop(hand, tableCards);
  }

  /// Find all possible capture moves
  List<AIMove> _findAllCaptures(List<Card> hand, List<Card> tableCards) {
    final moves = <AIMove>[];
    
    for (final card in hand) {
      final options = _validateCapture.findPossibleCaptures(
        playedCard: card,
        tableCards: tableCards,
        isFinalMove: false,
      );
      
      if (options.canCapture) {
        // Add single matches
        for (final match in options.singleMatches) {
          moves.add(AIMove(card: card, captureCards: [match]));
        }
        
        // Add sum combinations
        for (final combo in options.sumCombinations) {
          moves.add(AIMove(card: card, captureCards: combo));
        }
      }
    }
    
    return moves;
  }

  /// Select safest card to drop (Hard difficulty)
  AIMove _selectSafeDrop(List<Card> hand, List<Card> tableCards) {
    // Avoid dropping cards that could help opponent make chkobba
    final tableSum = tableCards.fold<int>(0, (sum, card) => sum + card.value);
    
    // Find card that makes worst total for opponent captures
    Card? bestDrop;
    int worstScore = 1000;
    
    for (final card in hand) {
      int dangerScore = 0;
      
      // Dropping a seven is risky
      if (card.isSeven) dangerScore += 5;
      
      // Dropping a diamond is risky
      if (card.isDiamond) dangerScore += 3;
      
      // Check if this creates easy capture for opponent
      final newSum = tableSum + card.value;
      if (newSum <= 10) dangerScore += 8;
      
      // Low value cards are safer to drop
      dangerScore -= (10 - card.value);
      
      if (dangerScore < worstScore) {
        worstScore = dangerScore;
        bestDrop = card;
      }
    }
    
    return AIMove(card: bestDrop ?? hand.first, captureCards: []);
  }

  /// Expert drop strategy
  AIMove _selectExpertDrop(List<Card> hand, List<Card> tableCards) {
    // Similar to hard but more nuanced
    final tableSum = tableCards.fold<int>(0, (sum, card) => sum + card.value);
    
    Card? bestDrop;
    int lowestRisk = 1000;
    
    for (final card in hand) {
      int risk = 0;
      
      // Never drop 7 of diamonds unless forced
      if (card.isSevenOfDiamonds) {
        risk += 100;
      } else if (card.isSeven) {
        risk += 15;
      }
      
      if (card.isDiamond) risk += 8;
      if (card.isSix) risk += 3;
      
      // Check if dropping creates chkobba opportunity
      final newSum = tableSum + card.value;
      if (tableCards.isEmpty || newSum <= 10) {
        risk += 20;
      }
      
      // Prefer dropping face cards (high rank but limited capture value)
      if (card.isFaceCard) risk -= 2;
      
      // Low base value cards are safer
      risk -= card.value;
      
      if (risk < lowestRisk) {
        lowestRisk = risk;
        bestDrop = card;
      }
    }
    
    return AIMove(card: bestDrop ?? hand.first, captureCards: []);
  }
}

/// Represents an AI move decision
class AIMove {
  final Card card;
  final List<Card> captureCards;

  AIMove({
    required this.card,
    required this.captureCards,
  });

  bool get isCapture => captureCards.isNotEmpty;
}
