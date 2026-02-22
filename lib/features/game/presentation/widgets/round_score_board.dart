// lib/features/game/presentation/widgets/round_score_board.dart

import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../domain/entities/player.dart';

/// Premium round / game-end score board with full score breakdown.
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
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    );
    _controller.forward();

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

  // ── Score data ────────────────────────────────────────────────────
  List<_ScoreItem> get _scoreItems => [
        _ScoreItem(
          icon: '📚',
          label: 'Cartes',
          humanVal: widget.humanPlayer.capturedCardCount,
          aiVal: widget.aiPlayer.capturedCardCount,
        ),
        _ScoreItem(
          icon: '💎',
          label: 'Dinari',
          humanVal: widget.humanPlayer.diamondsCount,
          aiVal: widget.aiPlayer.diamondsCount,
        ),
        _ScoreItem(
          icon: '⭐',
          label: 'Settebello',
          humanVal: widget.humanPlayer.hasSevenOfDiamonds ? 1 : 0,
          aiVal: widget.aiPlayer.hasSevenOfDiamonds ? 1 : 0,
        ),
        _ScoreItem(
          icon: '🏆',
          label: 'Chkobba',
          humanVal: widget.humanPlayer.chkobbas,
          aiVal: widget.aiPlayer.chkobbas,
        ),
      ];

  @override
  Widget build(BuildContext context) {
    final screenW = MediaQuery.of(context).size.width;
    final screenH = MediaQuery.of(context).size.height;
    final isSmall = screenH < 400;
    final dialogWidth = (screenW * 0.7).clamp(280.0, 480.0);

    return ScaleTransition(
      scale: _scaleAnimation,
      child: Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.symmetric(
          horizontal: 16,
          vertical: isSmall ? 8 : 16,
        ),
        child: Container(
          width: dialogWidth,
          constraints: BoxConstraints(
            maxHeight: screenH * (isSmall ? 0.92 : 0.85),
          ),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF1E1E2E),
                Color(0xFF141420),
              ],
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: AppColors.goldOpacity(0.25),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(140),
                blurRadius: 30,
                spreadRadius: 5,
              ),
              BoxShadow(
                color: AppColors.goldOpacity(0.08),
                blurRadius: 40,
                spreadRadius: 2,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16.5),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ── Header with result ──
                  _buildResultHeader(isSmall),

                  // ── Main scores ──
                  _buildMainScores(isSmall),

                  // ── Divider ──
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Divider(
                      color: Colors.white.withAlpha(15),
                      height: 1,
                    ),
                  ),

                  // ── Score breakdown ──
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: isSmall ? 10 : 16,
                      vertical: isSmall ? 6 : 8,
                    ),
                    child: Column(
                      children: _scoreItems.map((item) {
                        return _buildScoreRow(item, isSmall);
                      }).toList(),
                    ),
                  ),

                  // ── Action buttons ──
                  _buildActions(isSmall),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Result header ─────────────────────────────────────────────────

  Widget _buildResultHeader(bool isSmall) {
    final resultText = widget.isGameEnd
        ? (widget.isHumanWinner ? 'VICTOIRE ! 🎉' : 'DÉFAITE 😔')
        : 'FIN DU TOUR';
    final resultColor =
        widget.isHumanWinner ? AppColors.gold : const Color(0xFFFF6B6B);

    return Container(
      padding: EdgeInsets.fromLTRB(
        isSmall ? 12 : 20,
        isSmall ? 8 : 12,
        isSmall ? 12 : 20,
        isSmall ? 4 : 6,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            (widget.isGameEnd
                    ? (widget.isHumanWinner
                        ? AppColors.gold
                        : const Color(0xFFFF6B6B))
                    : AppColors.gold)
                .withAlpha(15),
            Colors.transparent,
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              resultText,
              style: TextStyle(
                fontSize: isSmall ? 13 : 15,
                fontWeight: FontWeight.w900,
                color: widget.isGameEnd ? resultColor : AppColors.gold,
                letterSpacing: 1.5,
              ),
            ),
          ),

          // Countdown or close
          if (!widget.isGameEnd) ...[
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(10),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '$_countdown',
                style: TextStyle(
                  color: Colors.white.withAlpha(100),
                  fontSize: isSmall ? 11 : 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          GestureDetector(
            onTap: widget.onContinue ?? widget.onHome,
            child: Container(
              width: isSmall ? 24 : 28,
              height: isSmall ? 24 : 28,
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(10),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withAlpha(20),
                ),
              ),
              child: Icon(Icons.close,
                  size: isSmall ? 13 : 15,
                  color: Colors.white.withAlpha(130)),
            ),
          ),
        ],
      ),
    );
  }

  // ── Main scores ───────────────────────────────────────────────────

  Widget _buildMainScores(bool isSmall) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isSmall ? 12 : 20,
        vertical: isSmall ? 6 : 10,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Human
          Expanded(
            child: _buildPlayerScore(
              name: 'VOUS',
              score: widget.humanPlayer.score,
              isWinner: widget.isHumanWinner,
              isSmall: isSmall,
            ),
          ),

          // VS
          Padding(
            padding: EdgeInsets.symmetric(horizontal: isSmall ? 8 : 14),
            child: Column(
              children: [
                Text(
                  'VS',
                  style: TextStyle(
                    fontSize: isSmall ? 10 : 11,
                    fontWeight: FontWeight.w800,
                    color: Colors.white.withAlpha(50),
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),
          ),

          // AI
          Expanded(
            child: _buildPlayerScore(
              name: 'IA',
              score: widget.aiPlayer.score,
              isWinner: !widget.isHumanWinner,
              isSmall: isSmall,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerScore({
    required String name,
    required int score,
    required bool isWinner,
    required bool isSmall,
  }) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isWinner)
              Icon(Icons.emoji_events_rounded,
                  size: isSmall ? 13 : 15, color: AppColors.gold),
            if (isWinner) const SizedBox(width: 4),
            Text(
              name,
              style: TextStyle(
                fontSize: isSmall ? 10 : 11,
                fontWeight: FontWeight.w800,
                color:
                    isWinner ? AppColors.gold : Colors.white.withAlpha(140),
                letterSpacing: 1,
              ),
            ),
          ],
        ),
        SizedBox(height: isSmall ? 2 : 4),
        Text(
          '$score',
          style: TextStyle(
            fontSize: isSmall ? 36 : 44,
            fontWeight: FontWeight.w900,
            color: isWinner ? AppColors.gold : Colors.white,
            height: 1,
            shadows: [
              Shadow(
                color: (isWinner ? AppColors.gold : Colors.white)
                    .withAlpha(30),
                blurRadius: 12,
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Score breakdown row ───────────────────────────────────────────

  Widget _buildScoreRow(_ScoreItem item, bool isSmall) {
    final humanWins = item.humanVal > item.aiVal;
    final aiWins = item.aiVal > item.humanVal;
    final isTie = item.humanVal == item.aiVal;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: isSmall ? 3 : 4),
      child: Row(
        children: [
          // Human value
          SizedBox(
            width: isSmall ? 30 : 38,
            child: Text(
              '${item.humanVal}',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: isSmall ? 14 : 16,
                fontWeight: FontWeight.w800,
                color: humanWins
                    ? AppColors.gold
                    : isTie
                        ? Colors.white.withAlpha(100)
                        : Colors.white.withAlpha(150),
              ),
            ),
          ),

          // Human indicator
          if (humanWins)
            Icon(Icons.arrow_left_rounded,
                size: isSmall ? 16 : 18, color: AppColors.goldOpacity(0.5))
          else
            SizedBox(width: isSmall ? 16 : 18),

          // Label
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(item.icon,
                    style: TextStyle(fontSize: isSmall ? 12 : 14)),
                const SizedBox(width: 6),
                Text(
                  item.label,
                  style: TextStyle(
                    fontSize: isSmall ? 10 : 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withAlpha(100),
                  ),
                ),
              ],
            ),
          ),

          // AI indicator
          if (aiWins)
            Icon(Icons.arrow_right_rounded,
                size: isSmall ? 16 : 18, color: AppColors.goldOpacity(0.5))
          else
            SizedBox(width: isSmall ? 16 : 18),

          // AI value
          SizedBox(
            width: isSmall ? 30 : 38,
            child: Text(
              '${item.aiVal}',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: isSmall ? 14 : 16,
                fontWeight: FontWeight.w800,
                color: aiWins
                    ? AppColors.gold
                    : isTie
                        ? Colors.white.withAlpha(100)
                        : Colors.white.withAlpha(150),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Actions ───────────────────────────────────────────────────────

  Widget _buildActions(bool isSmall) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        isSmall ? 12 : 20,
        0,
        isSmall ? 12 : 20,
        isSmall ? 8 : 14,
      ),
      child: widget.isGameEnd
          ? Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    label: 'Rejouer',
                    icon: Icons.replay_rounded,
                    onTap: widget.onPlayAgain,
                    isPrimary: true,
                    isSmall: isSmall,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildActionButton(
                    label: 'Accueil',
                    icon: Icons.home_rounded,
                    onTap: widget.onHome,
                    isPrimary: false,
                    isSmall: isSmall,
                  ),
                ),
              ],
            )
          : SizedBox(
              width: double.infinity,
              child: _buildActionButton(
                label: 'Continuer',
                icon: Icons.arrow_forward_rounded,
                onTap: widget.onContinue,
                isPrimary: true,
                isSmall: isSmall,
              ),
            ),
    );
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required VoidCallback? onTap,
    required bool isPrimary,
    required bool isSmall,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        splashColor: AppColors.goldOpacity(0.2),
        child: Container(
          padding: EdgeInsets.symmetric(
            vertical: isSmall ? 8 : 10,
          ),
          decoration: BoxDecoration(
            color: isPrimary ? AppColors.gold : Colors.white.withAlpha(10),
            borderRadius: BorderRadius.circular(12),
            border: isPrimary
                ? null
                : Border.all(color: Colors.white.withAlpha(20)),
            boxShadow: isPrimary
                ? [
                    BoxShadow(
                      color: AppColors.goldOpacity(0.3),
                      blurRadius: 10,
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  size: isSmall ? 14 : 16,
                  color: isPrimary
                      ? const Color(0xFF1A1A2E)
                      : Colors.white.withAlpha(180)),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: isSmall ? 11 : 13,
                  fontWeight: FontWeight.w800,
                  color: isPrimary
                      ? const Color(0xFF1A1A2E)
                      : Colors.white.withAlpha(180),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Data class ──────────────────────────────────────────────────────

class _ScoreItem {
  final String icon;
  final String label;
  final int humanVal;
  final int aiVal;

  const _ScoreItem({
    required this.icon,
    required this.label,
    required this.humanVal,
    required this.aiVal,
  });
}
