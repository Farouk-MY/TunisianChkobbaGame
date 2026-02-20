// lib/features/game/presentation/widgets/turn_timer_widget.dart

import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

/// Circular turn timer with visual countdown
class TurnTimerWidget extends StatelessWidget {
  final int remainingSeconds;
  final int totalSeconds;
  final bool isRedTheme;

  const TurnTimerWidget({
    super.key,
    required this.remainingSeconds,
    required this.totalSeconds,
    required this.isRedTheme,
  });

  @override
  Widget build(BuildContext context) {
    final progress = remainingSeconds / totalSeconds;
    final isWarning = remainingSeconds <= 10;
    final isCritical = remainingSeconds <= 5;
    
    Color progressColor;
    if (isCritical) {
      progressColor = Colors.red;
    } else if (isWarning) {
      progressColor = Colors.orange;
    } else {
      progressColor = AppColors.gold;
    }

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isRedTheme
            ? AppColors.whiteOpacity(0.15)
            : AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCritical
              ? Colors.red.withOpacity(0.5)
              : isRedTheme
                  ? AppColors.whiteOpacity(0.2)
                  : AppColors.grey300,
          width: 2,
        ),
        boxShadow: isCritical
            ? [
                BoxShadow(
                  color: Colors.red.withOpacity(0.3),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ]
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Circular progress
          SizedBox(
            width: 36,
            height: 36,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 3,
                  backgroundColor: isRedTheme
                      ? AppColors.whiteOpacity(0.1)
                      : AppColors.grey200,
                  valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                ),
                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 200),
                  style: TextStyle(
                    fontSize: isCritical ? 14 : 12,
                    fontWeight: FontWeight.bold,
                    color: isCritical
                        ? Colors.red
                        : isRedTheme
                            ? Colors.white
                            : AppColors.grey800,
                  ),
                  child: Text('$remainingSeconds'),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Votre tour',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isRedTheme ? Colors.white : AppColors.grey700,
                ),
              ),
              Text(
                isWarning ? 'Dépêchez-vous!' : 'Choisissez une carte',
                style: TextStyle(
                  fontSize: 9,
                  color: isCritical
                      ? Colors.red
                      : isRedTheme
                          ? Colors.white60
                          : AppColors.grey500,
                ),
              ),
            ],
          ),
          const SizedBox(width: 4),
        ],
      ),
    );
  }
}
