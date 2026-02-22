// lib/features/game/domain/entities/team.dart

import 'package:equatable/equatable.dart';
import 'player.dart';
import 'card.dart';

/// Team entity for 2v2 mode
class Team extends Equatable {
  final String id;
  final String name;
  final List<Player> players;
  final List<Card> capturedCards;
  final int score;
  final int chkobbas;

  const Team({
    required this.id,
    required this.name,
    required this.players,
    this.capturedCards = const [],
    this.score = 0,
    this.chkobbas = 0,
  });

  /// Get combined captured cards count
  int get totalCapturedCards => capturedCards.length;

  /// Get combined diamonds count
  int get diamondsCount => capturedCards.where((c) => c.suit == 'diamonds').length;

  /// Check if team has 7 of diamonds
  bool get hasSevenOfDiamonds => capturedCards.any((c) => c.rank == 7 && c.suit == 'diamonds');

  /// Get player 1
  Player get player1 => players.isNotEmpty ? players[0] : throw Exception('No players in team');

  /// Get player 2 (partner)
  Player? get player2 => players.length > 1 ? players[1] : null;

  /// Check if a player is in this team
  bool hasPlayer(String playerId) => players.any((p) => p.id == playerId);

  /// Get partner of a player
  Player? getPartner(String playerId) {
    final playerIndex = players.indexWhere((p) => p.id == playerId);
    if (playerIndex == -1) return null;
    if (players.length < 2) return null;
    return players[playerIndex == 0 ? 1 : 0];
  }

  /// Copy with new values
  Team copyWith({
    String? id,
    String? name,
    List<Player>? players,
    List<Card>? capturedCards,
    int? score,
    int? chkobbas,
  }) {
    return Team(
      id: id ?? this.id,
      name: name ?? this.name,
      players: players ?? this.players,
      capturedCards: capturedCards ?? this.capturedCards,
      score: score ?? this.score,
      chkobbas: chkobbas ?? this.chkobbas,
    );
  }

  /// Add captured cards
  Team addCapturedCards(List<Card> cards) {
    return copyWith(
      capturedCards: [...capturedCards, ...cards],
    );
  }

  /// Add Chkobba
  Team addChkobba() {
    return copyWith(chkobbas: chkobbas + 1);
  }

  /// Add score
  Team addScore(int points) {
    return copyWith(score: score + points);
  }

  /// Reset for new round
  Team resetForNewRound() {
    return copyWith(
      capturedCards: [],
      chkobbas: 0,
      players: players.map((p) => p.copyWith(
        hand: const [],
        capturedCards: const [],
        chkobbas: 0,
      )).toList(),
    );
  }

  /// Factory for creating Team 1 (Human + AI partner)
  factory Team.humanTeam({
    required String playerName,
    String? partnerName,
  }) {
    return Team(
      id: 'team_human',
      name: 'Équipe $playerName',
      players: [
        Player.human(
          id: 'player_human',
          name: playerName,
        ),
        Player.ai(
          id: 'player_partner',
          name: partnerName ?? 'Partenaire',
          aiDifficulty: 'medium',
        ),
      ],
    );
  }

  /// Factory for creating Team 2 (AI opponents)
  factory Team.aiTeam({
    String difficulty = 'medium',
    String? name,
  }) {
    return Team(
      id: 'team_ai',
      name: name ?? 'Équipe IA',
      players: [
        Player.ai(id: 'ai_1', name: 'Adversaire 1', aiDifficulty: difficulty),
        Player.ai(id: 'ai_2', name: 'Adversaire 2', aiDifficulty: difficulty),
      ],
    );
  }

  @override
  List<Object?> get props => [id, name, players, capturedCards, score, chkobbas];
}
