// lib/features/game/domain/usecases/calculate_score_usecase.dart

import '../entities/player.dart';
import '../entities/card.dart';
import '../../../../core/constants/game_constants.dart';

class CalculateScoreUseCase {
  /// Calculate round scores for all players
  RoundScores calculateRoundScores(List<Player> players) {
    final scores = <String, PlayerScore>{};

    for (final player in players) {
      final playerScore = PlayerScore(
        playerId: player.id,
        playerName: player.name,
        carta: 0,
        dinari: 0,
        sevenOfDiamonds: 0,
        bermila: 0,
        chkobba: player.chkobbas,
      );

      scores[player.id] = playerScore;
    }

    // Carta: Most cards
    final cartaWinner = _findMostCards(players);
    if (cartaWinner != null) {
      scores[cartaWinner.id] = scores[cartaWinner.id]!.copyWith(
        carta: GameConstants.pointsForMostCards,
      );
    }

    // Dinari: Most diamonds
    final dinariWinner = _findMostDiamonds(players);
    if (dinariWinner != null) {
      scores[dinariWinner.id] = scores[dinariWinner.id]!.copyWith(
        dinari: GameConstants.pointsForMostDiamonds,
      );
    }

    // 7 of Diamonds
    final sevenOfDiamondsWinner = _findSevenOfDiamonds(players);
    if (sevenOfDiamondsWinner != null) {
      scores[sevenOfDiamondsWinner.id] = scores[sevenOfDiamondsWinner.id]!.copyWith(
        sevenOfDiamonds: GameConstants.pointsForSevenOfDiamonds,
      );
    }

    // Bermila: Most sevens (tiebreaker: most sixes)
    final bermilaWinner = _findBermila(players);
    if (bermilaWinner != null) {
      scores[bermilaWinner.id] = scores[bermilaWinner.id]!.copyWith(
        bermila: GameConstants.pointsForMostSevens,
      );
    }

    return RoundScores(playerScores: scores);
  }

  /// Check if any player has won the game
  String? checkWinner(List<Player> players, int targetScore) {
    final sorted = List<Player>.from(players)
      ..sort((a, b) => b.score.compareTo(a.score));

    final leader = sorted.first;

    // Must reach target score
    if (leader.score < targetScore) return null;

    // Must have at least 2-point lead
    if (sorted.length > 1) {
      final secondPlace = sorted[1];
      if (leader.score - secondPlace.score < GameConstants.minPointLeadToWin) {
        return null;
      }
    }

    return leader.id;
  }

  Player? _findMostCards(List<Player> players) {
    if (players.isEmpty) return null;

    final sorted = List<Player>.from(players)
      ..sort((a, b) => b.capturedCardCount.compareTo(a.capturedCardCount));

    final leader = sorted.first;

    // Check for tie
    if (sorted.length > 1 &&
        sorted[1].capturedCardCount == leader.capturedCardCount) {
      return null; // No point awarded on tie
    }

    return leader;
  }

  Player? _findMostDiamonds(List<Player> players) {
    if (players.isEmpty) return null;

    final sorted = List<Player>.from(players)
      ..sort((a, b) => b.diamondCount.compareTo(a.diamondCount));

    final leader = sorted.first;

    // Check for tie
    if (sorted.length > 1 && sorted[1].diamondCount == leader.diamondCount) {
      return null;
    }

    return leader;
  }

  Player? _findSevenOfDiamonds(List<Player> players) {
    for (final player in players) {
      if (player.hasSevenOfDiamonds) return player;
    }
    return null;
  }

  Player? _findBermila(List<Player> players) {
    if (players.isEmpty) return null;

    final sorted = List<Player>.from(players)
      ..sort((a, b) {
        // First compare sevens
        final sevenCompare = b.sevenCount.compareTo(a.sevenCount);
        if (sevenCompare != 0) return sevenCompare;

        // Tiebreaker: compare sixes
        return b.sixCount.compareTo(a.sixCount);
      });

    final leader = sorted.first;

    // Check for tie (both sevens and sixes must match)
    if (sorted.length > 1) {
      final second = sorted[1];
      if (second.sevenCount == leader.sevenCount &&
          second.sixCount == leader.sixCount) {
        return null;
      }
    }

    return leader;
  }
}

class RoundScores {
  final Map<String, PlayerScore> playerScores;

  const RoundScores({required this.playerScores});

  int getTotalScore(String playerId) {
    final score = playerScores[playerId];
    if (score == null) return 0;
    return score.totalScore;
  }

  PlayerScore? getPlayerScore(String playerId) => playerScores[playerId];
}

class PlayerScore {
  final String playerId;
  final String playerName;
  final int carta;
  final int dinari;
  final int sevenOfDiamonds;
  final int bermila;
  final int chkobba;

  const PlayerScore({
    required this.playerId,
    required this.playerName,
    required this.carta,
    required this.dinari,
    required this.sevenOfDiamonds,
    required this.bermila,
    required this.chkobba,
  });

  int get totalScore => carta + dinari + sevenOfDiamonds + bermila + chkobba;

  PlayerScore copyWith({
    int? carta,
    int? dinari,
    int? sevenOfDiamonds,
    int? bermila,
    int? chkobba,
  }) {
    return PlayerScore(
      playerId: playerId,
      playerName: playerName,
      carta: carta ?? this.carta,
      dinari: dinari ?? this.dinari,
      sevenOfDiamonds: sevenOfDiamonds ?? this.sevenOfDiamonds,
      bermila: bermila ?? this.bermila,
      chkobba: chkobba ?? this.chkobba,
    );
  }
}