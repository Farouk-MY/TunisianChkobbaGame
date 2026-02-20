// lib/features/game/presentation/widgets/score_display_widget.dart

import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../domain/entities/game_state.dart';

class ScoreDisplayWidget extends StatelessWidget {
  final GameState gameState;
  final bool isRedTheme;

  const ScoreDisplayWidget({
    super.key,
    required this.gameState,
    required this.isRedTheme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isRedTheme
            ? AppColors.whiteOpacity(0.1)
            : AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isRedTheme
              ? AppColors.whiteOpacity(0.2)
              : AppColors.grey300,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.emoji_events,
                size: 16,
                color: AppColors.gold,
              ),
              const SizedBox(width: 6),
              Text(
                'Score',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: isRedTheme ? AppColors.white : AppColors.grey900,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Target score
          _buildInfoRow(
            'Objectif',
            '${gameState.targetScore} pts',
          ),

          const Divider(height: 16),

          // Round number
          _buildInfoRow(
            'Manche',
            '${gameState.roundNumber}',
          ),

          const SizedBox(height: 8),

          // Cards left
          _buildInfoRow(
            'Cartes',
            '${gameState.deckSize}',
          ),

          const Spacer(),

          // Game phase indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _getPhaseColor(),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              _getPhaseText(),
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: AppColors.white,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: isRedTheme
                ? AppColors.whiteOpacity(0.7)
                : AppColors.grey700,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: isRedTheme ? AppColors.white : AppColors.grey900,
          ),
        ),
      ],
    );
  }

  Color _getPhaseColor() {
    switch (gameState.phase) {
      case GamePhase.playing:
        return AppColors.success;
      case GamePhase.roundEnd:
        return AppColors.warning;
      case GamePhase.gameEnd:
        return AppColors.primaryRed;
      default:
        return AppColors.grey500;
    }
  }

  String _getPhaseText() {
    switch (gameState.phase) {
      case GamePhase.playing:
        return 'EN JEU';
      case GamePhase.dealing:
        return 'DISTRIBUTION';
      case GamePhase.roundEnd:
        return 'FIN MANCHE';
      case GamePhase.gameEnd:
        return 'TERMINÉ';
      default:
        return 'PRÉPARATION';
    }
  }
}