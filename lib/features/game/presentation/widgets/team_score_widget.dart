// lib/features/game/presentation/widgets/team_score_widget.dart

import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../domain/entities/team.dart';

/// Team score display widget for 2v2 mode
class TeamScoreWidget extends StatelessWidget {
  final Team team;
  final bool isCurrentTeam;
  final bool isRedTheme;
  final bool isHumanTeam;

  const TeamScoreWidget({
    super.key,
    required this.team,
    required this.isCurrentTeam,
    required this.isRedTheme,
    this.isHumanTeam = false,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: isCurrentTeam
            ? LinearGradient(
                colors: [
                  AppColors.goldOpacity(0.3),
                  AppColors.goldOpacity(0.1),
                ],
              )
            : null,
        color: isCurrentTeam
            ? null
            : isRedTheme
                ? AppColors.whiteOpacity(0.08)
                : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCurrentTeam
              ? AppColors.gold
              : isRedTheme
                  ? AppColors.whiteOpacity(0.15)
                  : AppColors.grey200,
          width: isCurrentTeam ? 2 : 1,
        ),
        boxShadow: isCurrentTeam
            ? [
                BoxShadow(
                  color: AppColors.goldOpacity(0.2),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ]
            : null,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Team name
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isHumanTeam)
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: Icon(
                    Icons.person,
                    size: 14,
                    color: AppColors.gold,
                  ),
                ),
              Text(
                team.name,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isRedTheme ? Colors.white70 : AppColors.grey600,
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Team score
          Text(
            '${team.score}',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w900,
              color: isHumanTeam
                  ? AppColors.gold
                  : isRedTheme
                      ? Colors.white
                      : AppColors.grey800,
            ),
          ),

          const SizedBox(height: 8),

          // Players
          Row(
            mainAxisSize: MainAxisSize.min,
            children: team.players.map((player) {
              final isCurrentPlayer = player.isCurrentTurn;
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isCurrentPlayer
                      ? AppColors.goldOpacity(0.3)
                      : isRedTheme
                          ? Colors.white.withAlpha(13)
                          : AppColors.grey100,
                  borderRadius: BorderRadius.circular(8),
                  border: isCurrentPlayer
                      ? Border.all(color: AppColors.gold, width: 1.5)
                      : null,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      player.isHuman ? Icons.person : Icons.smart_toy,
                      size: 12,
                      color: isCurrentPlayer
                          ? AppColors.gold
                          : isRedTheme
                              ? Colors.white54
                              : AppColors.grey500,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      player.name,
                      style: TextStyle(
                        fontSize: 10,
                        color: isCurrentPlayer
                            ? AppColors.gold
                            : isRedTheme
                                ? Colors.white70
                                : AppColors.grey600,
                      ),
                    ),
                    if (isCurrentPlayer) ...[
                      const SizedBox(width: 4),
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: AppColors.gold,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ],
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 8),

          // Stats row
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildStatChip(
                '🃏 ${team.totalCapturedCards}',
                isRedTheme,
              ),
              const SizedBox(width: 6),
              _buildStatChip(
                '💎 ${team.diamondsCount}',
                isRedTheme,
              ),
              const SizedBox(width: 6),
              _buildStatChip(
                '⭐ ${team.chkobbas}',
                isRedTheme,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip(String text, bool isRedTheme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: isRedTheme
            ? Colors.white.withAlpha(13)
            : AppColors.grey50,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          color: isRedTheme ? Colors.white70 : AppColors.grey600,
        ),
      ),
    );
  }
}
