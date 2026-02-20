// lib/features/game/domain/usecases/initialize_game_usecase.dart

import '../entities/game_state.dart';
import '../entities/player.dart';
import '../../../../core/constants/game_constants.dart';

class InitializeGameUseCase {
  /// Create a new game with given configuration
  GameState execute({
    required List<Player> players,
    int targetScore = GameConstants.defaultTargetScore,
  }) {
    // Validate players
    if (players.isEmpty) {
      throw ArgumentError('At least one player required');
    }

    if (players.length < GameConstants.minPlayers ||
        players.length > GameConstants.maxPlayers) {
      throw ArgumentError(
        'Player count must be between ${GameConstants.minPlayers} '
            'and ${GameConstants.maxPlayers}',
      );
    }

    // Validate target score
    if (!GameConstants.isValidTargetScore(targetScore)) {
      throw ArgumentError(
        'Invalid target score. Must be one of: '
            '${GameConstants.availableTargetScores.join(", ")}',
      );
    }

    // Generate unique game ID
    final gameId = _generateGameId();

    // Reset all players
    final resetPlayers = players
        .map((p) => p.resetCompletely())
        .toList();

    // Create new game state
    var gameState = GameState.newGame(
      gameId: gameId,
      players: resetPlayers,
      targetScore: targetScore,
    );

    // Deal initial cards
    gameState = gameState.dealInitialCards();

    return gameState;
  }

  /// Create a quick game vs AI
  GameState createQuickGameVsAI({
    required String playerName,
    String aiDifficulty = GameConstants.defaultAiDifficulty,
    int targetScore = GameConstants.defaultTargetScore,
  }) {
    final players = [
      Player.human(
        id: 'player_1',
        name: playerName,
      ),
      Player.ai(
        id: 'ai_1',
        name: 'AI Opponent',
        aiDifficulty: aiDifficulty,
      ),
    ];

    return execute(
      players: players,
      targetScore: targetScore,
    );
  }

  /// Create a local multiplayer game
  GameState createLocalMultiplayer({
    required List<String> playerNames,
    int targetScore = GameConstants.defaultTargetScore,
  }) {
    final players = playerNames
        .asMap()
        .entries
        .map((entry) => Player.human(
      id: 'player_${entry.key + 1}',
      name: entry.value,
    ))
        .toList();

    return execute(
      players: players,
      targetScore: targetScore,
    );
  }

  String _generateGameId() {
    return 'game_${DateTime.now().millisecondsSinceEpoch}';
  }
}