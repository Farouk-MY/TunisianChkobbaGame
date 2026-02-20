// lib/features/game/presentation/widgets/round_end_dialog.dart

import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../domain/entities/player.dart';

/// Premium dialog showing round-end score breakdown
class RoundEndDialog extends StatefulWidget {
  final Player humanPlayer;
  final Player aiPlayer;
  final int humanRoundScore;
  final int aiRoundScore;
  final Map<String, int> humanScoreBreakdown;
  final Map<String, int> aiScoreBreakdown;
  final VoidCallback onContinue;
  final bool isRedTheme;

  const RoundEndDialog({
    super.key,
    required this.humanPlayer,
    required this.aiPlayer,
    required this.humanRoundScore,
    required this.aiRoundScore,
    required this.humanScoreBreakdown,
    required this.aiScoreBreakdown,
    required this.onContinue,
    required this.isRedTheme,
  });

  static Future<void> show(
    BuildContext context, {
    required Player humanPlayer,
    required Player aiPlayer,
    required int humanRoundScore,
    required int aiRoundScore,
    required Map<String, int> humanScoreBreakdown,
    required Map<String, int> aiScoreBreakdown,
    required VoidCallback onContinue,
    required bool isRedTheme,
  }) {
    return showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black87,
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (context, animation, secondaryAnimation) {
        return RoundEndDialog(
          humanPlayer: humanPlayer,
          aiPlayer: aiPlayer,
          humanRoundScore: humanRoundScore,
          aiRoundScore: aiRoundScore,
          humanScoreBreakdown: humanScoreBreakdown,
          aiScoreBreakdown: aiScoreBreakdown,
          onContinue: onContinue,
          isRedTheme: isRedTheme,
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.3),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutBack)),
          child: FadeTransition(
            opacity: animation,
            child: child,
          ),
        );
      },
    );
  }

  @override
  State<RoundEndDialog> createState() => _RoundEndDialogState();
}

class _RoundEndDialogState extends State<RoundEndDialog>
    with TickerProviderStateMixin {
  late AnimationController _scoreController;
  late AnimationController _confettiController;
  late List<Animation<double>> _scoreAnimations;

  @override
  void initState() {
    super.initState();
    _scoreController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _confettiController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );

    // Staggered animations for each score item
    final items = widget.humanScoreBreakdown.length;
    _scoreAnimations = List.generate(items, (index) {
      final start = index / items * 0.7;
      final end = start + 0.3;
      return CurvedAnimation(
        parent: _scoreController,
        curve: Interval(start.clamp(0.0, 1.0), end.clamp(0.0, 1.0), curve: Curves.elasticOut),
      );
    });

    _scoreController.forward();
    if (widget.humanRoundScore > widget.aiRoundScore) {
      _confettiController.repeat();
    }
  }

  @override
  void dispose() {
    _scoreController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final humanWon = widget.humanRoundScore > widget.aiRoundScore;

    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: MediaQuery.of(context).size.width * 0.85,
          constraints: const BoxConstraints(maxWidth: 600),
          decoration: BoxDecoration(
            gradient: widget.isRedTheme
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(0xFF2D1B4E),
                      const Color(0xFF1A0F2E),
                    ],
                  )
                : LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Colors.white, const Color(0xFFF5F5F5)],
                  ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: humanWon ? AppColors.gold : AppColors.grey400,
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: humanWon
                    ? AppColors.goldOpacity(0.3)
                    : Colors.black.withAlpha(64),
                blurRadius: 30,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Stack(
            children: [
              // Confetti for winner
              if (humanWon) _buildConfetti(),

              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header
                    _buildHeader(humanWon),

                    const SizedBox(height: 24),

                    // Score comparison
                    _buildScoreComparison(),

                    const SizedBox(height: 20),

                    // Score breakdown
                    _buildScoreBreakdown(),

                    const SizedBox(height: 24),

                    // Continue button
                    _buildContinueButton(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildConfetti() {
    return AnimatedBuilder(
      animation: _confettiController,
      builder: (context, child) {
        return Positioned.fill(
          child: IgnorePointer(
            child: CustomPaint(
              painter: _ConfettiPainter(
                progress: _confettiController.value,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(bool humanWon) {
    return Column(
      children: [
        Text(
          humanWon ? '🎉' : '📊',
          style: const TextStyle(fontSize: 48),
        ),
        const SizedBox(height: 8),
        ShaderMask(
          shaderCallback: (bounds) => LinearGradient(
            colors: humanWon
                ? [AppColors.gold, const Color(0xFFFFD700)]
                : [AppColors.grey600, AppColors.grey400],
          ).createShader(bounds),
          child: Text(
            'Fin de Manche',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildScoreComparison() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: widget.isRedTheme
            ? Colors.white.withAlpha(26)
            : AppColors.grey100,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildPlayerScore(
            widget.humanPlayer.name,
            widget.humanRoundScore,
            widget.humanPlayer.score,
            isWinner: widget.humanRoundScore > widget.aiRoundScore,
          ),
          Container(
            width: 2,
            height: 60,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  widget.isRedTheme ? Colors.white30 : AppColors.grey300,
                  Colors.transparent,
                ],
              ),
            ),
          ),
          _buildPlayerScore(
            widget.aiPlayer.name,
            widget.aiRoundScore,
            widget.aiPlayer.score,
            isWinner: widget.aiRoundScore > widget.humanRoundScore,
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerScore(String name, int roundScore, int totalScore,
      {required bool isWinner}) {
    return Column(
      children: [
        Text(
          name,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: widget.isRedTheme ? Colors.white70 : AppColors.grey600,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '+$roundScore',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w900,
                color: isWinner
                    ? AppColors.gold
                    : widget.isRedTheme
                        ? Colors.white
                        : AppColors.grey800,
              ),
            ),
            if (isWinner) ...[
              const SizedBox(width: 4),
              Icon(Icons.star, color: AppColors.gold, size: 20),
            ],
          ],
        ),
        Text(
          'Total: $totalScore',
          style: TextStyle(
            fontSize: 12,
            color: widget.isRedTheme ? Colors.white54 : AppColors.grey500,
          ),
        ),
      ],
    );
  }

  Widget _buildScoreBreakdown() {
    final categories = [
      ('cards', 'Cartes', Icons.style),
      ('diamonds', 'Carreaux', Icons.diamond),
      ('sevenOfDiamonds', '7 de Carreau', Icons.filter_7),
      ('bermila', 'Bermila', Icons.casino),
      ('chkobbas', 'Chkobbas', Icons.star),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Détails des points',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: widget.isRedTheme ? Colors.white70 : AppColors.grey600,
          ),
        ),
        const SizedBox(height: 12),
        ...List.generate(categories.length, (index) {
          final cat = categories[index];
          final humanVal = widget.humanScoreBreakdown[cat.$1] ?? 0;
          final aiVal = widget.aiScoreBreakdown[cat.$1] ?? 0;

          if (humanVal == 0 && aiVal == 0) return const SizedBox.shrink();

          return AnimatedBuilder(
            animation: _scoreAnimations[index.clamp(0, _scoreAnimations.length - 1)],
            builder: (context, child) {
              final scale = _scoreAnimations[index.clamp(0, _scoreAnimations.length - 1)].value;
              return Transform.scale(
                scale: scale.clamp(0.0, 1.0),
                child: Opacity(
                  opacity: scale.clamp(0.0, 1.0),
                  child: child,
                ),
              );
            },
            child: Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: widget.isRedTheme
                    ? Colors.white.withAlpha(13)
                    : Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: widget.isRedTheme
                      ? Colors.white.withAlpha(26)
                      : AppColors.grey200,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    cat.$3,
                    size: 18,
                    color: widget.isRedTheme ? AppColors.gold : AppColors.primaryRed,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      cat.$2,
                      style: TextStyle(
                        fontSize: 13,
                        color: widget.isRedTheme ? Colors.white : AppColors.grey800,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: humanVal > 0
                          ? AppColors.goldOpacity(0.2)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      humanVal > 0 ? '+$humanVal' : '-',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: humanVal > 0
                            ? AppColors.gold
                            : widget.isRedTheme
                                ? Colors.white54
                                : AppColors.grey400,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: aiVal > 0
                          ? Colors.white.withAlpha(26)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      aiVal > 0 ? '+$aiVal' : '-',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: aiVal > 0
                            ? (widget.isRedTheme ? Colors.white : AppColors.grey700)
                            : (widget.isRedTheme ? Colors.white54 : AppColors.grey400),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildContinueButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () {
          Navigator.pop(context);
          widget.onContinue();
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.gold,
          foregroundColor: AppColors.darkRed,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 4,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.play_arrow_rounded, size: 24),
            const SizedBox(width: 8),
            const Text(
              'Manche Suivante',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Custom painter for confetti effect
class _ConfettiPainter extends CustomPainter {
  final double progress;

  _ConfettiPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final colors = [
      AppColors.gold,
      AppColors.primaryRed,
      Colors.green,
      Colors.blue,
      Colors.purple,
    ];

    for (var i = 0; i < 30; i++) {
      final x = (i * 37 + progress * 100) % size.width;
      final y = (progress * size.height * 2 + i * 23) % (size.height + 50) - 25;
      final color = colors[i % colors.length];
      final rotation = progress * 6.28 + i;

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(rotation);

      final paint = Paint()..color = color.withAlpha(179);
      canvas.drawRect(
        Rect.fromCenter(center: Offset.zero, width: 8, height: 4),
        paint,
      );

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
