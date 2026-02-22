// lib/features/home/presentation/pages/game_history_page.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;
import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../../../core/services/game_history_service.dart';

/// Premium match history screen — card-table aesthetic.
class GameHistoryPage extends StatefulWidget {
  const GameHistoryPage({super.key});

  @override
  State<GameHistoryPage> createState() => _GameHistoryPageState();
}

class _GameHistoryPageState extends State<GameHistoryPage>
    with SingleTickerProviderStateMixin {
  List<GameResult> _history = [];
  bool _loading = true;
  late AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();
    _loadHistory();
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    final history = await GameHistoryService.getGameHistory();
    if (!mounted) return;
    setState(() {
      _history = history;
      _loading = false;
    });
  }

  String _difficultyLabel(String d) {
    switch (d) {
      case 'easy':
        return '🌿 Facile';
      case 'medium':
        return '⚔️ Moyen';
      case 'hard':
        return '🔥 Pro';
      case 'expert':
        return '👑 Expert';
      default:
        return d;
    }
  }

  String _timeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return "À l'instant";
    if (diff.inMinutes < 60) return 'Il y a ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'Il y a ${diff.inHours}h';
    if (diff.inDays < 7) return 'Il y a ${diff.inDays}j';
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return Scaffold(
          body: Container(
            decoration: BoxDecoration(
              gradient: themeProvider.isRedTheme
                  ? AppColors.primaryGradient
                  : AppColors.whiteGradient,
            ),
            child: SafeArea(
              child: Stack(
                children: [
                  _buildBackground(themeProvider),
                  Column(
                    children: [
                      _buildHeader(context, themeProvider),
                      if (!_loading && _history.isNotEmpty)
                        _buildSummaryBar(themeProvider),
                      Expanded(
                        child: _loading
                            ? _buildLoadingState(themeProvider)
                            : _history.isEmpty
                                ? _buildEmptyState(themeProvider)
                                : _buildHistoryList(themeProvider),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBackground(ThemeProvider themeProvider) {
    return Stack(
      children: [
        Positioned(
          top: 40,
          left: 30,
          child: AnimatedBuilder(
            animation: _shimmerController,
            builder: (context, child) {
              return Transform.rotate(
                angle: _shimmerController.value * 2 * math.pi,
                child: Icon(
                  Icons.star,
                  color: themeProvider.isRedTheme
                      ? AppColors.goldOpacity(0.15)
                      : AppColors.primaryRedOpacity(0.1),
                  size: 20,
                ),
              );
            },
          ),
        ),
        Positioned(
          bottom: 100,
          right: 40,
          child: AnimatedBuilder(
            animation: _shimmerController,
            builder: (context, child) {
              return Transform.rotate(
                angle: -_shimmerController.value * 2 * math.pi,
                child: Icon(
                  Icons.auto_awesome,
                  color: themeProvider.isRedTheme
                      ? AppColors.goldOpacity(0.12)
                      : AppColors.primaryRedOpacity(0.08),
                  size: 24,
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context, ThemeProvider themeProvider) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(
              Icons.arrow_back_ios,
              color: themeProvider.textColor,
            ),
          ),
          const SizedBox(width: 8),
          Icon(
            Icons.history_rounded,
            color: AppColors.gold,
            size: 28,
          ),
          const SizedBox(width: 12),
          Text(
            'Historique',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: themeProvider.textColor,
            ),
          ),
          const Spacer(),
          if (_history.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: themeProvider.isRedTheme
                    ? AppColors.whiteOpacity(0.08)
                    : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: themeProvider.isRedTheme
                      ? AppColors.whiteOpacity(0.1)
                      : AppColors.grey200,
                ),
              ),
              child: Text(
                '${_history.length} parties',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: themeProvider.secondaryTextColor,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSummaryBar(ThemeProvider themeProvider) {
    final wins = _history.where((g) => g.isHumanWinner).length;
    final losses = _history.length - wins;
    final winRate = _history.isNotEmpty
        ? (wins / _history.length * 100).round()
        : 0;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: themeProvider.isRedTheme
              ? [AppColors.goldOpacity(0.15), AppColors.goldOpacity(0.05)]
              : [AppColors.goldOpacity(0.12), AppColors.goldOpacity(0.04)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.gold.withAlpha(60)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildSummaryStat('🏆', '$wins', 'Victoires', themeProvider),
          Container(
            width: 1,
            height: 28,
            color: themeProvider.isRedTheme
                ? AppColors.whiteOpacity(0.1)
                : AppColors.grey200,
          ),
          _buildSummaryStat('💔', '$losses', 'Défaites', themeProvider),
          Container(
            width: 1,
            height: 28,
            color: themeProvider.isRedTheme
                ? AppColors.whiteOpacity(0.1)
                : AppColors.grey200,
          ),
          _buildSummaryStat('📊', '$winRate%', 'Taux', themeProvider),
        ],
      ),
    );
  }

  Widget _buildSummaryStat(
      String emoji, String value, String label, ThemeProvider themeProvider) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 14)),
            const SizedBox(width: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.gold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: themeProvider.secondaryTextColor,
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingState(ThemeProvider themeProvider) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedBuilder(
            animation: _shimmerController,
            builder: (context, child) {
              return Transform.rotate(
                angle: _shimmerController.value * 2 * math.pi,
                child: Icon(
                  Icons.auto_awesome,
                  size: 32,
                  color: AppColors.gold,
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          Text(
            'Chargement...',
            style: TextStyle(
              fontSize: 14,
              color: themeProvider.secondaryTextColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ThemeProvider themeProvider) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Compact mode if height is tight
        final compact = constraints.maxHeight < 250;
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Center(
              child: Container(
                padding: EdgeInsets.all(compact ? 16 : 24),
                margin: EdgeInsets.symmetric(
                    horizontal: 28, vertical: compact ? 12 : 20),
                decoration: BoxDecoration(
                  color: themeProvider.isRedTheme
                      ? AppColors.whiteOpacity(0.08)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: themeProvider.isRedTheme
                        ? AppColors.whiteOpacity(0.1)
                        : AppColors.grey200,
                  ),
                  boxShadow: themeProvider.isRedTheme
                      ? null
                      : [
                          BoxShadow(
                            color: AppColors.blackOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!compact)
                      Icon(
                        Icons.style_outlined,
                        size: 40,
                        color: AppColors.gold.withAlpha(150),
                      ),
                    if (!compact) const SizedBox(height: 10),
                    Text(
                      'Aucune partie jouée',
                      style: TextStyle(
                        fontSize: compact ? 15 : 18,
                        fontWeight: FontWeight.bold,
                        color: themeProvider.textColor,
                      ),
                    ),
                    SizedBox(height: compact ? 4 : 6),
                    Text(
                      compact
                          ? 'Lancez une partie pour commencer !'
                          : 'Lancez une partie rapide pour\ncommencer votre historique !',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: compact ? 11 : 13,
                        height: 1.4,
                        color: themeProvider.isRedTheme
                            ? Colors.white.withAlpha(160)
                            : AppColors.grey700,
                      ),
                    ),
                    SizedBox(height: compact ? 10 : 14),
                    Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: 18, vertical: compact ? 7 : 10),
                      decoration: BoxDecoration(
                        gradient: AppColors.goldGradient,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.flash_on,
                              color: AppColors.darkRed,
                              size: compact ? 14 : 16),
                          const SizedBox(width: 6),
                          Text(
                            'Jouer maintenant',
                            style: TextStyle(
                              fontSize: compact ? 12 : 13,
                              fontWeight: FontWeight.bold,
                              color: AppColors.darkRed,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }


  Widget _buildHistoryList(ThemeProvider themeProvider) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      itemCount: _history.length,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: _buildGameCard(_history[index], index, themeProvider),
        );
      },
    );
  }

  Widget _buildGameCard(
      GameResult game, int index, ThemeProvider themeProvider) {
    final won = game.isHumanWinner;
    final isRed = themeProvider.isRedTheme;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: won
            ? LinearGradient(
                colors: isRed
                    ? [AppColors.goldOpacity(0.12), AppColors.goldOpacity(0.04)]
                    : [AppColors.goldOpacity(0.08), AppColors.goldOpacity(0.02)],
              )
            : null,
        color: won
            ? null
            : isRed
                ? AppColors.whiteOpacity(0.08)
                : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: won
              ? AppColors.gold.withAlpha(80)
              : isRed
                  ? AppColors.whiteOpacity(0.1)
                  : AppColors.grey200,
          width: won ? 1.5 : 1,
        ),
        boxShadow: isRed
            ? null
            : [
                BoxShadow(
                  color: AppColors.blackOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Row(
        children: [
          // Result badge
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: won
                  ? AppColors.goldGradient
                  : LinearGradient(
                      colors: [
                        Colors.redAccent.withAlpha(30),
                        Colors.redAccent.withAlpha(10),
                      ],
                    ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: won
                    ? AppColors.gold.withAlpha(60)
                    : Colors.redAccent.withAlpha(40),
              ),
            ),
            child: Icon(
              won ? Icons.emoji_events : Icons.close_rounded,
              color: won ? AppColors.darkRed : Colors.redAccent,
              size: 22,
            ),
          ),

          const SizedBox(width: 14),

          // Score details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      won ? 'Victoire' : 'Défaite',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: won ? AppColors.gold : Colors.redAccent,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: isRed
                            ? AppColors.whiteOpacity(0.08)
                            : AppColors.grey200.withAlpha(140),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _difficultyLabel(game.aiDifficulty),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: themeProvider.secondaryTextColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    // Score
                    Text(
                      '${game.humanScore}',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: themeProvider.textColor,
                      ),
                    ),
                    Text(
                      ' - ',
                      style: TextStyle(
                        fontSize: 14,
                        color: themeProvider.secondaryTextColor,
                      ),
                    ),
                    Text(
                      '${game.aiScore}',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: themeProvider.secondaryTextColor,
                      ),
                    ),
                    const SizedBox(width: 14),

                    // Chkobbas
                    if (game.humanChkobbas > 0) ...[
                      Icon(Icons.auto_awesome,
                          size: 13, color: AppColors.gold),
                      const SizedBox(width: 3),
                      Text(
                        '${game.humanChkobbas}',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.gold,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 10),
                    ],

                    // Rounds
                    Icon(Icons.loop, size: 12,
                        color: themeProvider.secondaryTextColor),
                    const SizedBox(width: 3),
                    Text(
                      '${game.roundsPlayed} manches',
                      style: TextStyle(
                        fontSize: 11,
                        color: themeProvider.secondaryTextColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Time
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _timeAgo(game.date),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: themeProvider.secondaryTextColor,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Cible: ${game.targetScore}',
                style: TextStyle(
                  fontSize: 9,
                  color: themeProvider.secondaryTextColor.withAlpha(120),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
