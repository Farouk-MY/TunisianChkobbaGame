// lib/core/services/game_history_service.dart

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Service for saving and loading game history
class GameHistoryService {
  static const String _historyKey = 'game_history';
  static const String _statsKey = 'player_stats';
  static const int _maxHistoryItems = 50;

  /// Save game result to history
  static Future<void> saveGameResult(GameResult result) async {
    final prefs = await SharedPreferences.getInstance();
    final history = await getGameHistory();
    
    history.insert(0, result);
    
    // Limit history size
    if (history.length > _maxHistoryItems) {
      history.removeRange(_maxHistoryItems, history.length);
    }
    
    final jsonList = history.map((r) => r.toJson()).toList();
    await prefs.setString(_historyKey, jsonEncode(jsonList));
    
    // Update stats
    await _updateStats(result);
  }

  /// Get game history
  static Future<List<GameResult>> getGameHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_historyKey);
    
    if (jsonString == null) return [];
    
    try {
      final jsonList = jsonDecode(jsonString) as List;
      return jsonList.map((j) => GameResult.fromJson(j)).toList();
    } catch (_) {
      return [];
    }
  }

  /// Get player statistics
  static Future<PlayerStats> getPlayerStats() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_statsKey);
    
    if (jsonString == null) return PlayerStats.empty();
    
    try {
      return PlayerStats.fromJson(jsonDecode(jsonString));
    } catch (_) {
      return PlayerStats.empty();
    }
  }

  /// Update player statistics
  static Future<void> _updateStats(GameResult result) async {
    final prefs = await SharedPreferences.getInstance();
    final stats = await getPlayerStats();
    
    final updatedStats = stats.copyWith(
      gamesPlayed: stats.gamesPlayed + 1,
      gamesWon: stats.gamesWon + (result.isHumanWinner ? 1 : 0),
      totalChkobbas: stats.totalChkobbas + result.humanChkobbas,
      highestScore: result.humanScore > stats.highestScore 
          ? result.humanScore 
          : stats.highestScore,
    );
    
    await prefs.setString(_statsKey, jsonEncode(updatedStats.toJson()));
  }

  /// Clear all history
  static Future<void> clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_historyKey);
  }

  /// Reset statistics
  static Future<void> resetStats() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_statsKey);
  }
}

/// Game result model
class GameResult {
  final DateTime date;
  final int humanScore;
  final int aiScore;
  final bool isHumanWinner;
  final int humanChkobbas;
  final int aiChkobbas;
  final String aiDifficulty;
  final int targetScore;
  final int roundsPlayed;

  const GameResult({
    required this.date,
    required this.humanScore,
    required this.aiScore,
    required this.isHumanWinner,
    required this.humanChkobbas,
    required this.aiChkobbas,
    required this.aiDifficulty,
    required this.targetScore,
    required this.roundsPlayed,
  });

  Map<String, dynamic> toJson() => {
    'date': date.toIso8601String(),
    'humanScore': humanScore,
    'aiScore': aiScore,
    'isHumanWinner': isHumanWinner,
    'humanChkobbas': humanChkobbas,
    'aiChkobbas': aiChkobbas,
    'aiDifficulty': aiDifficulty,
    'targetScore': targetScore,
    'roundsPlayed': roundsPlayed,
  };

  factory GameResult.fromJson(Map<String, dynamic> json) => GameResult(
    date: DateTime.parse(json['date']),
    humanScore: json['humanScore'] ?? 0,
    aiScore: json['aiScore'] ?? 0,
    isHumanWinner: json['isHumanWinner'] ?? false,
    humanChkobbas: json['humanChkobbas'] ?? 0,
    aiChkobbas: json['aiChkobbas'] ?? 0,
    aiDifficulty: json['aiDifficulty'] ?? 'medium',
    targetScore: json['targetScore'] ?? 11,
    roundsPlayed: json['roundsPlayed'] ?? 0,
  );
}

/// Player statistics model
class PlayerStats {
  final int gamesPlayed;
  final int gamesWon;
  final int totalChkobbas;
  final int highestScore;

  const PlayerStats({
    required this.gamesPlayed,
    required this.gamesWon,
    required this.totalChkobbas,
    required this.highestScore,
  });

  factory PlayerStats.empty() => const PlayerStats(
    gamesPlayed: 0,
    gamesWon: 0,
    totalChkobbas: 0,
    highestScore: 0,
  );

  double get winRate => gamesPlayed > 0 ? gamesWon / gamesPlayed * 100 : 0;

  PlayerStats copyWith({
    int? gamesPlayed,
    int? gamesWon,
    int? totalChkobbas,
    int? highestScore,
  }) => PlayerStats(
    gamesPlayed: gamesPlayed ?? this.gamesPlayed,
    gamesWon: gamesWon ?? this.gamesWon,
    totalChkobbas: totalChkobbas ?? this.totalChkobbas,
    highestScore: highestScore ?? this.highestScore,
  );

  Map<String, dynamic> toJson() => {
    'gamesPlayed': gamesPlayed,
    'gamesWon': gamesWon,
    'totalChkobbas': totalChkobbas,
    'highestScore': highestScore,
  };

  factory PlayerStats.fromJson(Map<String, dynamic> json) => PlayerStats(
    gamesPlayed: json['gamesPlayed'] ?? 0,
    gamesWon: json['gamesWon'] ?? 0,
    totalChkobbas: json['totalChkobbas'] ?? 0,
    highestScore: json['highestScore'] ?? 0,
  );
}
