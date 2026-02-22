// lib/features/game/presentation/providers/game_provider.dart

import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../domain/entities/game_state.dart';
import '../../domain/entities/card.dart';
import '../../domain/entities/player.dart';
import '../../domain/usecases/initialize_game_usecase.dart';
import '../../domain/usecases/play_card_usecase.dart';
import '../../domain/usecases/validate_capture_usecase.dart';
import '../../../ai/ai_engine/ai_player.dart';
import '../../../../core/constants/game_constants.dart';

class GameProvider with ChangeNotifier {
  final InitializeGameUseCase initializeGameUseCase;
  final PlayCardUseCase playCardUseCase;
  final ValidateCaptureUseCase validateCaptureUseCase;

  GameState? _gameState;
  List<Card> _selectedCards = [];
  bool _isProcessing = false;
  String? _errorMessage;
  AIPlayer? _aiPlayer;
  String _aiDifficulty = GameConstants.aiMedium;

  GameProvider({
    required this.initializeGameUseCase,
    required this.playCardUseCase,
    required this.validateCaptureUseCase,
  });

  // Getters
  GameState? get gameState => _gameState;
  List<Card> get selectedCards => _selectedCards;
  bool get isProcessing => _isProcessing;
  String? get errorMessage => _errorMessage;
  bool get hasGame => _gameState != null;
  String get aiDifficulty => _aiDifficulty;

  // Initialize new game
  Future<void> startNewGame({
    required List<Player> players,
    int targetScore = 21,
  }) async {
    try {
      _isProcessing = true;
      _errorMessage = null;
      notifyListeners();

      _gameState = initializeGameUseCase.execute(
        players: players,
        targetScore: targetScore,
      );

      _selectedCards = [];
      _isProcessing = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isProcessing = false;
      notifyListeners();
    }
  }

  // Quick game vs AI with difficulty
  Future<void> startQuickGameVsAI({
    required String playerName,
    String aiDifficulty = 'medium',
    int targetScore = 21,
  }) async {
    try {
      _isProcessing = true;
      _errorMessage = null;
      _aiDifficulty = aiDifficulty;
      notifyListeners();

      // Initialize AI player with selected difficulty
      _aiPlayer = AIPlayer(difficulty: aiDifficulty);

      _gameState = initializeGameUseCase.createQuickGameVsAI(
        playerName: playerName,
        aiDifficulty: aiDifficulty,
        targetScore: targetScore,
      );

      _selectedCards = [];
      _isProcessing = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isProcessing = false;
      notifyListeners();
    }
  }

  // Toggle card selection
  void toggleCardSelection(Card card) {
    if (_gameState == null || !_gameState!.isPlaying) return;

    if (_selectedCards.contains(card)) {
      _selectedCards.remove(card);
    } else {
      _selectedCards.add(card);
    }

    notifyListeners();
  }

  // Clear selection
  void clearSelection() {
    _selectedCards = [];
    notifyListeners();
  }

  // Play a card (human player)
  Future<void> playCard(Card card) async {
    if (_gameState == null || _isProcessing) return;

    try {
      _isProcessing = true;
      _errorMessage = null;
      notifyListeners();

      _gameState = playCardUseCase.execute(
        gameState: _gameState!,
        playedCard: card,
        selectedCards: _selectedCards,
      );

      _selectedCards = [];
      _isProcessing = false;
      notifyListeners();
      
      if (_gameState?.isGameOver == true) {
        return;
      }
    } catch (e) {
      _errorMessage = e.toString();
      _isProcessing = false;
      notifyListeners();
    }
  }

  // AI plays automatically
  Future<void> playAITurn() async {
    if (_gameState == null || !_gameState!.isAITurn || _isProcessing) return;
    if (_aiPlayer == null) {
      _aiPlayer = AIPlayer(difficulty: _aiDifficulty);
    }

    try {
      _isProcessing = true;
      notifyListeners();

      // Get AI move
      final move = _aiPlayer!.selectMove(_gameState!);

      // Apply selections
      _selectedCards.clear();
      for (final captureCard in move.captureCards) {
        _selectedCards.add(captureCard);
      }

      // Small delay to make AI feel more natural
      await Future.delayed(const Duration(milliseconds: 300));

      // Execute move
      _gameState = playCardUseCase.execute(
        gameState: _gameState!,
        playedCard: move.card,
        selectedCards: _selectedCards,
      );

      _selectedCards = [];
      _isProcessing = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isProcessing = false;
      notifyListeners();
    }
  }

  /// Transition from roundEnd → new round.
  /// Called by the UI after the round score board is dismissed.
  void startNextRound() {
    if (_gameState == null) return;
    if (!_gameState!.isRoundOver) return;

    _gameState = _gameState!.startNewRound();
    _gameState = _gameState!.dealInitialCards();
    notifyListeners();
  }

  // Get possible captures for a card
  CaptureOptions? getPossibleCaptures(Card card) {
    if (_gameState == null) return null;

    return validateCaptureUseCase.findPossibleCaptures(
      playedCard: card,
      tableCards: _gameState!.tableCards,
      isFinalMove: _gameState!.isFinalMove,
    );
  }

  // Clear error
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Reset game
  void resetGame() {
    _gameState = null;
    _selectedCards = [];
    _isProcessing = false;
    _errorMessage = null;
    _aiPlayer = null;
    notifyListeners();
  }

  // Play again with same settings
  Future<void> playAgain() async {
    if (_gameState == null) return;
    
    final targetScore = _gameState!.targetScore;
    final playerName = _gameState!.players[0].name;

    await startQuickGameVsAI(
      playerName: playerName,
      aiDifficulty: _aiDifficulty,
      targetScore: targetScore,
    );
  }
}