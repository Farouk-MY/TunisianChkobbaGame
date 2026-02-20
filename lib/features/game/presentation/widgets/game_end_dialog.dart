// lib/features/game/presentation/widgets/game_end_dialog.dart

import 'dart:math';
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../domain/entities/player.dart';

/// Celebration dialog when game ends
class GameEndDialog extends StatefulWidget {
  final Player winner;
  final Player loser;
  final bool isHumanWinner;
  final VoidCallback onPlayAgain;
  final VoidCallback onHome;
  final bool isRedTheme;

  const GameEndDialog({
    super.key,
    required this.winner,
    required this.loser,
    required this.isHumanWinner,
    required this.onPlayAgain,
    required this.onHome,
    required this.isRedTheme,
  });

  static Future<void> show(
    BuildContext context, {
    required Player winner,
    required Player loser,
    required bool isHumanWinner,
    required VoidCallback onPlayAgain,
    required VoidCallback onHome,
    required bool isRedTheme,
  }) {
    return showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withAlpha(230),
      transitionDuration: const Duration(milliseconds: 600),
      pageBuilder: (context, animation, secondaryAnimation) {
        return GameEndDialog(
          winner: winner,
          loser: loser,
          isHumanWinner: isHumanWinner,
          onPlayAgain: onPlayAgain,
          onHome: onHome,
          isRedTheme: isRedTheme,
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return ScaleTransition(
          scale: CurvedAnimation(
            parent: animation,
            curve: Curves.elasticOut,
          ),
          child: FadeTransition(
            opacity: animation,
            child: child,
          ),
        );
      },
    );
  }

  @override
  State<GameEndDialog> createState() => _GameEndDialogState();
}

class _GameEndDialogState extends State<GameEndDialog>
    with TickerProviderStateMixin {
  late AnimationController _fireworksController;
  late AnimationController _glowController;
  late AnimationController _trophyController;
  late Animation<double> _trophyScale;
  final Random _random = Random();
  List<_Firework> _fireworks = [];

  @override
  void initState() {
    super.initState();

    _fireworksController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    );

    _glowController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _trophyController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _trophyScale = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _trophyController, curve: Curves.elasticOut),
    );

    // Generate fireworks
    if (widget.isHumanWinner) {
      _generateFireworks();
      _fireworksController.repeat();
    }

    _trophyController.forward();
  }

  void _generateFireworks() {
    _fireworks = List.generate(20, (i) {
      return _Firework(
        x: _random.nextDouble(),
        y: _random.nextDouble() * 0.6,
        color: [
          AppColors.gold,
          AppColors.primaryRed,
          Colors.blue,
          Colors.green,
          Colors.purple,
          Colors.orange,
        ][i % 6],
        delay: _random.nextDouble(),
        speed: 0.5 + _random.nextDouble() * 0.5,
      );
    });
  }

  @override
  void dispose() {
    _fireworksController.dispose();
    _glowController.dispose();
    _trophyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Fireworks background
        if (widget.isHumanWinner)
          AnimatedBuilder(
            animation: _fireworksController,
            builder: (context, child) {
              return CustomPaint(
                size: MediaQuery.of(context).size,
                painter: _FireworksPainter(
                  fireworks: _fireworks,
                  progress: _fireworksController.value,
                ),
              );
            },
          ),

        // Main dialog
        Center(
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: MediaQuery.of(context).size.width * 0.8,
              constraints: const BoxConstraints(maxWidth: 450),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: widget.isHumanWinner
                      ? [
                          const Color(0xFF2D1B4E),
                          const Color(0xFF1A0F2E),
                        ]
                      : [
                          const Color(0xFF1A1A2E),
                          const Color(0xFF16213E),
                        ],
                ),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: widget.isHumanWinner
                      ? AppColors.gold
                      : AppColors.grey600,
                  width: 3,
                ),
                boxShadow: [
                  BoxShadow(
                    color: widget.isHumanWinner
                        ? AppColors.goldOpacity(0.4)
                        : Colors.black54,
                    blurRadius: 40,
                    spreadRadius: 10,
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Trophy / Icon
                    _buildTrophy(),

                    const SizedBox(height: 24),

                    // Title
                    _buildTitle(),

                    const SizedBox(height: 16),

                    // Score display
                    _buildScoreDisplay(),

                    const SizedBox(height: 32),

                    // Buttons
                    _buildButtons(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTrophy() {
    return ScaleTransition(
      scale: _trophyScale,
      child: AnimatedBuilder(
        animation: _glowController,
        builder: (context, child) {
          return Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: widget.isHumanWinner
                    ? [
                        AppColors.goldOpacity(0.3 + _glowController.value * 0.2),
                        Colors.transparent,
                      ]
                    : [
                        Colors.blueGrey.withAlpha(51),
                        Colors.transparent,
                      ],
              ),
            ),
            child: Center(
              child: Text(
                widget.isHumanWinner ? '🏆' : '😔',
                style: TextStyle(
                  fontSize: 72,
                  shadows: widget.isHumanWinner
                      ? [
                          Shadow(
                            color: AppColors.goldOpacity(0.8),
                            blurRadius: 20 + _glowController.value * 10,
                          ),
                        ]
                      : null,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTitle() {
    return Column(
      children: [
        ShaderMask(
          shaderCallback: (bounds) => LinearGradient(
            colors: widget.isHumanWinner
                ? [AppColors.gold, const Color(0xFFFFE082)]
                : [Colors.white, Colors.white70],
          ).createShader(bounds),
          child: Text(
            widget.isHumanWinner ? 'VICTOIRE!' : 'DÉFAITE',
            style: const TextStyle(
              fontSize: 40,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: 4,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          widget.isHumanWinner
              ? 'Félicitations, vous avez gagné!'
              : 'L\'IA remporte la partie',
          style: TextStyle(
            fontSize: 16,
            color: Colors.white70,
          ),
        ),
      ],
    );
  }

  Widget _buildScoreDisplay() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(13),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withAlpha(26)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildScoreColumn(
            widget.winner.name,
            widget.winner.score,
            isWinner: true,
          ),
          Container(
            width: 2,
            height: 50,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.white30,
                  Colors.transparent,
                ],
              ),
            ),
          ),
          _buildScoreColumn(
            widget.loser.name,
            widget.loser.score,
            isWinner: false,
          ),
        ],
      ),
    );
  }

  Widget _buildScoreColumn(String name, int score, {required bool isWinner}) {
    return Column(
      children: [
        Text(
          name,
          style: TextStyle(
            fontSize: 14,
            color: Colors.white70,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$score',
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.w900,
                color: isWinner ? AppColors.gold : Colors.white,
              ),
            ),
            if (isWinner) ...[
              const SizedBox(width: 4),
              Icon(Icons.emoji_events, color: AppColors.gold, size: 24),
            ],
          ],
        ),
        Text(
          'points',
          style: TextStyle(
            fontSize: 11,
            color: Colors.white54,
          ),
        ),
      ],
    );
  }

  Widget _buildButtons() {
    return Column(
      children: [
        // Play Again button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              widget.onPlayAgain();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.gold,
              foregroundColor: AppColors.darkRed,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              elevation: 8,
              shadowColor: AppColors.goldOpacity(0.5),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.refresh, size: 22),
                const SizedBox(width: 8),
                const Text(
                  'Rejouer',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 12),

        // Home button
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () {
              Navigator.pop(context);
              widget.onHome();
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              side: BorderSide(color: Colors.white.withAlpha(77)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.home_outlined, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Menu Principal',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Firework data class
class _Firework {
  final double x;
  final double y;
  final Color color;
  final double delay;
  final double speed;

  _Firework({
    required this.x,
    required this.y,
    required this.color,
    required this.delay,
    required this.speed,
  });
}

/// Custom painter for fireworks
class _FireworksPainter extends CustomPainter {
  final List<_Firework> fireworks;
  final double progress;

  _FireworksPainter({required this.fireworks, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    for (final firework in fireworks) {
      final adjustedProgress = ((progress + firework.delay) * firework.speed) % 1.0;
      final burstProgress = (adjustedProgress * 3).clamp(0.0, 1.0);

      if (burstProgress < 1.0) {
        final centerX = firework.x * size.width;
        final centerY = firework.y * size.height;

        // Draw burst
        for (var i = 0; i < 12; i++) {
          final angle = i * (3.14159 * 2 / 12);
          final radius = burstProgress * 60;
          final opacity = (1 - burstProgress).clamp(0.0, 1.0);

          final paint = Paint()
            ..color = firework.color.withAlpha((opacity * 255).toInt())
            ..strokeWidth = 3
            ..style = PaintingStyle.stroke;

          final x = centerX + cos(angle) * radius;
          final y = centerY + sin(angle) * radius;

          canvas.drawCircle(Offset(x, y), 3 * (1 - burstProgress), paint);
        }

        // Center glow
        final glowPaint = Paint()
          ..color = firework.color.withAlpha(((1 - burstProgress) * 128).toInt())
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);

        canvas.drawCircle(
          Offset(centerX, centerY),
          20 * burstProgress,
          glowPaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _FireworksPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
