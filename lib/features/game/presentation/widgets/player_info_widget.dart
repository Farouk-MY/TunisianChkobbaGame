// lib/features/game/presentation/widgets/player_info_widget.dart

import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../domain/entities/player.dart';

/// Compact player info widget for game board
class PlayerInfoWidget extends StatelessWidget {
  final Player player;
  final bool isCurrentTurn;
  final bool isTop;
  final bool isRedTheme;

  const PlayerInfoWidget({
    super.key,
    required this.player,
    required this.isCurrentTurn,
    required this.isTop,
    required this.isRedTheme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        gradient: isCurrentTurn
            ? LinearGradient(
                colors: [
                  AppColors.goldOpacity(0.2),
                  AppColors.goldOpacity(0.1),
                ],
              )
            : null,
        color: isCurrentTurn
            ? null
            : isRedTheme
                ? AppColors.whiteOpacity(0.08)
                : Colors.white.withAlpha(127),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCurrentTurn
              ? AppColors.gold
              : isRedTheme
                  ? AppColors.whiteOpacity(0.15)
                  : AppColors.grey200,
          width: isCurrentTurn ? 2 : 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Avatar (smaller)
          _buildAvatar(),
          
          const SizedBox(width: 8),
          
          // Name + stats inline
          Flexible(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Name
                Flexible(
                  child: Text(
                    player.name,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isRedTheme ? Colors.white : AppColors.grey800,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                // AI badge
                if (player.isAI) ...[
                  const SizedBox(width: 4),
                  Icon(
                    Icons.smart_toy,
                    size: 12,
                    color: isRedTheme ? Colors.white60 : AppColors.grey500,
                  ),
                ],
                const SizedBox(width: 8),
                // Cards in hand
                _buildMiniStat('🃏', '${player.handSize}'),
                const SizedBox(width: 6),
                // Captured
                _buildMiniStat('📥', '${player.capturedCardCount}'),
                // Chkobbas
                if (player.chkobbas > 0) ...[
                  const SizedBox(width: 6),
                  _buildMiniStat('⭐', '${player.chkobbas}', isGold: true),
                ],
              ],
            ),
          ),
          
          const SizedBox(width: 8),
          
          // Score
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isRedTheme
                  ? AppColors.whiteOpacity(0.1)
                  : AppColors.grey100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${player.score}',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: isCurrentTurn
                    ? AppColors.gold
                    : isRedTheme
                        ? Colors.white
                        : AppColors.grey800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        gradient: isCurrentTurn
            ? AppColors.goldGradient
            : LinearGradient(
                colors: player.isAI
                    ? [const Color(0xFF6B5B95), const Color(0xFF4A4063)]
                    : [AppColors.primaryRed, const Color(0xFFB71C1C)],
              ),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isCurrentTurn
              ? AppColors.gold
              : Colors.white.withAlpha(77),
          width: 2,
        ),
      ),
      child: Center(
        child: player.isAI
            ? Icon(
                Icons.smart_toy,
                size: 16,
                color: Colors.white,
              )
            : Text(
                player.name.isNotEmpty
                    ? player.name[0].toUpperCase()
                    : 'P',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: isCurrentTurn ? AppColors.darkRed : Colors.white,
                ),
              ),
      ),
    );
  }

  Widget _buildMiniStat(String emoji, String value, {bool isGold = false}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(emoji, style: const TextStyle(fontSize: 10)),
        const SizedBox(width: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: isGold
                ? AppColors.gold
                : isRedTheme
                    ? Colors.white70
                    : AppColors.grey600,
          ),
        ),
      ],
    );
  }
}