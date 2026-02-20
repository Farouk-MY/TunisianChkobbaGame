// lib/features/game/domain/repositories/game_repository.dart

import '../entities/game_state.dart';

abstract class GameRepository {
  /// Save current game state
  Future<void> saveGame(GameState gameState);

  /// Load saved game state
  Future<GameState?> loadGame(String gameId);

  /// Delete saved game
  Future<void> deleteGame(String gameId);

  /// Get all saved games
  Future<List<GameState>> getAllSavedGames();

  /// Check if game exists
  Future<bool> gameExists(String gameId);
}