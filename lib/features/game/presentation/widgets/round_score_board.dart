// lib/features/game/presentation/widgets/round_score_board.dart

import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../domain/entities/player.dart';

/// Chalkboard-style round score display
class RoundScoreBoard extends StatefulWidget {
  final Player humanPlayer;
  final Player aiPlayer;
  final bool isGameEnd;
  final bool isHumanWinner;
  final VoidCallback? onContinue;
  final VoidCallback? onPlayAgain;
  final VoidCallback? onHome;

  const RoundScoreBoard({
    super.key,
    required this.humanPlayer,
    required this.aiPlayer,
    this.isGameEnd = false,
    this.isHumanWinner = false,
    this.onContinue,
    this.onPlayAgain,
    this.onHome,
  });

  @override
  State<RoundScoreBoard> createState() => _RoundScoreBoardState();
}

class _RoundScoreBoardState extends State<RoundScoreBoard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  Timer? _autoCloseTimer;
  int _countdown = 10;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    );
    _controller.forward();

    // Auto-close timer (only for round end, not game end)
    if (!widget.isGameEnd) {
      _autoCloseTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (mounted) {
          setState(() {
            _countdown--;
            if (_countdown <= 0) {
              timer.cancel();
              widget.onContinue?.call();
            }
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _autoCloseTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(20),
        child: Container(
          width: 320,
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.6,
          ),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF2D2D2D),
                Color(0xFF1A1A1A),
                Color(0xFF252525),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFF5C4033),
              width: 6,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(150),
                blurRadius: 30,
                spreadRadius: 5,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Close button with countdown
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (!widget.isGameEnd)
                          Text(
                            '$_countdown',
                            style: const TextStyle(
                              color: Colors.white38,
                              fontSize: 14,
                            ),
                          ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: widget.onContinue ?? widget.onHome,
                          child: Container(
                            width: 26,
                            height: 26,
                            decoration: const BoxDecoration(
                              color: Color(0xFFB71C1C),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                    
                    // Player names header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildPlayerHeader('VOUS', widget.isHumanWinner),
                        const SizedBox(width: 16),
                        const Text(
                          'vs',
                          style: TextStyle(
                            color: Colors.white54,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 16),
                        _buildPlayerHeader('IA', !widget.isHumanWinner),
                      ],
                    ),
                    
                    const SizedBox(height: 4),
                    
                    // Main scores
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildMainScore(widget.humanPlayer.score, true),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            '-',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        _buildMainScore(widget.aiPlayer.score, false),
                      ],
                    ),
                    
                    const SizedBox(height: 8),
                    
                    // Score breakdown
                    _buildScoreRow(
                      '⭐ SETTEBELLO',
                      widget.humanPlayer.hasSevenOfDiamonds ? 1 : 0,
                      widget.aiPlayer.hasSevenOfDiamonds ? 1 : 0,
                    ),
                    _buildScoreRow(
                      '📚 CARTE',
                      widget.humanPlayer.capturedCardCount,
                      widget.aiPlayer.capturedCardCount,
                    ),
                    _buildScoreRow(
                      '💎 DINARI',
                      widget.humanPlayer.diamondsCount,
                      widget.aiPlayer.diamondsCount,
                    ),
                    _buildScoreRow(
                      '🏆 SCOPE',
                      widget.humanPlayer.chkobbas,
                      widget.aiPlayer.chkobbas,
                    ),
                    
                    const SizedBox(height: 4),
                    
                    // Game end buttons
                    if (widget.isGameEnd) ...[
                      const SizedBox(height: 12),
                      _buildGameEndButtons(),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlayerHeader(String name, bool isWinner) {
    return Column(
      children: [
        Text(
          name,
          style: TextStyle(
            color: isWinner ? AppColors.gold : Colors.white70,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        if (isWinner)
          Icon(Icons.emoji_events, color: AppColors.gold, size: 18),
      ],
    );
  }

  Widget _buildMainScore(int score, bool isHuman) {
    return Text(
      '$score',
      style: TextStyle(
        fontSize: 48,
        fontWeight: FontWeight.w900,
        color: isHuman ? AppColors.gold : Colors.white,
        shadows: [
          Shadow(
            color: Colors.black.withAlpha(100),
            offset: const Offset(2, 2),
            blurRadius: 4,
          ),
        ],
      ),
    );
  }

  Widget _buildScoreRow(String label, int humanValue, int aiValue) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 35,
            child: Text(
              '$humanValue',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: humanValue > aiValue
                    ? AppColors.gold
                    : Colors.white70,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white54,
                fontSize: 11,
              ),
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 35,
            child: Text(
              '$aiValue',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: aiValue > humanValue
                    ? AppColors.gold
                    : Colors.white70,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGameEndButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildButton('Rejouer', Icons.replay, widget.onPlayAgain),
        const SizedBox(width: 12),
        _buildButton('Accueil', Icons.home, widget.onHome),
      ],
    );
  }

  Widget _buildButton(String label, IconData icon, VoidCallback? onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.gold,
              const Color(0xFFFFD54F),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.goldOpacity(0.3),
              blurRadius: 8,
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: AppColors.darkRed, size: 16),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: AppColors.darkRed,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
