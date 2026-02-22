// lib/features/game/domain/usecases/play_card_usecase.dart

import '../entities/card.dart';
import '../entities/capture.dart';
import '../entities/game_state.dart';
import 'validate_capture_usecase.dart';
import 'calculate_score_usecase.dart';

class PlayCardUseCase {
  final ValidateCaptureUseCase validateCaptureUseCase;
  final CalculateScoreUseCase calculateScoreUseCase;

  PlayCardUseCase({
    required this.validateCaptureUseCase,
    required this.calculateScoreUseCase,
  });

  /// Execute a complete turn: play card, capture, update state
  GameState execute({
    required GameState gameState,
    required Card playedCard,
    required List<Card> selectedCards,
  }) {
    // Validate turn
    if (!gameState.isPlaying) {
      throw StateError('Game is not in playing phase');
    }

    if (!gameState.currentPlayer.hand.contains(playedCard)) {
      throw StateError('Card not in current player hand');
    }

    // Validate capture
    final isValid = validateCaptureUseCase.isValidCapture(
      playedCard: playedCard,
      selectedCards: selectedCards,
      tableCards: gameState.tableCards,
    );

    if (!isValid) {
      throw StateError('Invalid capture');
    }

    // Create capture
    final capture = validateCaptureUseCase.createCapture(
      playedCard: playedCard,
      selectedCards: selectedCards,
      tableCards: gameState.tableCards,
      playerId: gameState.currentPlayer.id,
      isFinalMove: gameState.isFinalMove,
    );

    // Execute capture and update game state
    var updatedState = gameState.playCard(playedCard, capture);

    // Move to next turn
    updatedState = updatedState.nextTurn();

    // Check if round should end
    if (updatedState.allPlayersOutOfCards) {
      if (updatedState.isDeckEmpty) {
        // Round is over
        updatedState = _endRound(updatedState);
      } else {
        // Deal next round of cards
        updatedState = updatedState.dealNextRound();
      }
    }

    return updatedState;
  }

  GameState _endRound(GameState gameState) {
    // End the round (gives remaining cards to last capturer)
    var updatedState = gameState.endRound();

    // Calculate scores
    final roundScores = calculateScoreUseCase.calculateRoundScores(
      updatedState.players,
    );

    // Update player scores
    final updatedPlayers = updatedState.players.map((player) {
      final roundScore = roundScores.getTotalScore(player.id);
      return player.addPoints(roundScore);
    }).toList();

    updatedState = updatedState.copyWith(players: updatedPlayers);

    // Check for winner
    final winnerId = calculateScoreUseCase.checkWinner(
      updatedPlayers,
      updatedState.targetScore,
    );

    if (winnerId != null) {
      // Game over!
      updatedState = updatedState.endGame(winnerId);
    }
    // Otherwise, stay in roundEnd phase.
    // The UI will show the score board, then call GameProvider.startNextRound()
    // which handles startNewRound() + dealInitialCards().

    return updatedState;
  }
}