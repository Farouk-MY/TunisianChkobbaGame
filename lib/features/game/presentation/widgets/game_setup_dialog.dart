// lib/features/game/presentation/widgets/game_setup_dialog.dart

import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/game_constants.dart';
import '../../../../core/services/audio_service.dart';

/// Game configuration result from the setup dialog
class GameConfig {
  final int playerCount;
  final int targetScore;
  final String aiDifficulty;
  final String playerName;
  final bool isTeamMode;

  const GameConfig({
    required this.playerCount,
    required this.targetScore,
    required this.aiDifficulty,
    required this.playerName,
    required this.isTeamMode,
  });
}

/// Premium game setup dialog - compact layout without scrolling
class GameSetupDialog extends StatefulWidget {
  const GameSetupDialog({super.key});

  static Future<GameConfig?> show(BuildContext context) {
    return showGeneralDialog<GameConfig>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      barrierColor: Colors.black87,
      transitionDuration: const Duration(milliseconds: 350),
      pageBuilder: (context, animation, secondaryAnimation) {
        return const GameSetupDialog();
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.1),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            )),
            child: child,
          ),
        );
      },
    );
  }

  @override
  State<GameSetupDialog> createState() => _GameSetupDialogState();
}

class _GameSetupDialogState extends State<GameSetupDialog>
    with SingleTickerProviderStateMixin {
  int _selectedMode = 0;
  int _selectedScore = 21;
  String _selectedDifficulty = GameConstants.aiMedium;
  final AudioService _audioService = AudioService();

  late AnimationController _glowController;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: MediaQuery.of(context).size.width * 0.92,
          height: MediaQuery.of(context).size.height * 0.85,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF8B1538),
                Color(0xFF5D0F28),
                Color(0xFF3D0A1A),
              ],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.goldOpacity(0.4), width: 2),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF8B1538).withAlpha(100),
                blurRadius: 40,
                spreadRadius: 10,
              ),
            ],
          ),
          child: Column(
            children: [
              // Header
              _buildHeader(),
              
              // Main content - no scrolling
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      // Left: Game Mode
                      Expanded(
                        flex: 2,
                        child: _buildGameModeSection(),
                      ),
                      
                      // Center divider
                      _buildVerticalDivider(),
                      
                      // Right: Score & Difficulty
                      Expanded(
                        flex: 3,
                        child: _buildOptionsSection(),
                      ),
                    ],
                  ),
                ),
              ),
              
              // Start button
              _buildStartButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.gold,
            const Color(0xFFE8B946),
            AppColors.gold,
          ],
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(22),
          topRight: Radius.circular(22),
        ),
      ),
      child: Row(
        children: [
          // Logo
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.darkRed.withAlpha(40),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: Text('🎴', style: TextStyle(fontSize: 24)),
            ),
          ),
          const SizedBox(width: 12),
          
          // Title
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'NOUVELLE PARTIE',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: AppColors.darkRed,
                    letterSpacing: 1,
                  ),
                ),
                Text(
                  'Choisissez votre mode de jeu',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.darkRed.withAlpha(180),
                  ),
                ),
              ],
            ),
          ),
          
          // Close button
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.darkRed.withAlpha(30),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.close, size: 18, color: AppColors.darkRed),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGameModeSection() {
    return SingleChildScrollView(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'MODE',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: AppColors.goldOpacity(0.7),
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 10),
          
          // 1v1 Card
          _buildModeCard(
            index: 0,
            emoji: '👤',
            title: '1 vs 1',
            desc: 'Solo contre l\'IA',
          ),
          
          const SizedBox(height: 8),
          
          // 2v2 Card
          _buildModeCard(
            index: 1,
            emoji: '👥',
            title: '2 vs 2',
            desc: 'Équipe (bientôt)',
            disabled: true,
          ),
        ],
      ),
    );
  }

  Widget _buildModeCard({
    required int index,
    required String emoji,
    required String title,
    required String desc,
    bool disabled = false,
  }) {
    final isSelected = _selectedMode == index && !disabled;

    return GestureDetector(
      onTap: disabled ? null : () => setState(() => _selectedMode = index),
      child: AnimatedBuilder(
        animation: _glowController,
        builder: (context, child) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
            decoration: BoxDecoration(
              gradient: isSelected
                  ? LinearGradient(
                      colors: [
                        AppColors.gold,
                        const Color(0xFFE8B946),
                      ],
                    )
                  : null,
              color: isSelected ? null : Colors.white.withAlpha(disabled ? 10 : 20),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                    ? AppColors.gold
                    : Colors.white.withAlpha(disabled ? 20 : 40),
                width: isSelected ? 2 : 1,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: AppColors.goldOpacity(0.3 + _glowController.value * 0.2),
                        blurRadius: 12,
                        spreadRadius: 2,
                      ),
                    ]
                  : null,
            ),
            child: Row(
              children: [
                Text(emoji, style: TextStyle(fontSize: 22, color: disabled ? Colors.white38 : null)),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isSelected
                              ? AppColors.darkRed
                              : disabled
                                  ? Colors.white38
                                  : Colors.white,
                        ),
                      ),
                      Text(
                        desc,
                        style: TextStyle(
                          fontSize: 10,
                          color: isSelected
                              ? AppColors.darkRed.withAlpha(180)
                              : disabled
                                  ? Colors.white24
                                  : Colors.white60,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isSelected)
                  Icon(Icons.check_circle, color: AppColors.darkRed, size: 22),
                if (disabled)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(20),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'SOON',
                      style: TextStyle(fontSize: 8, color: Colors.white38, fontWeight: FontWeight.bold),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildVerticalDivider() {
    return Container(
      width: 1,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.white.withAlpha(0),
            Colors.white.withAlpha(30),
            Colors.white.withAlpha(0),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionsSection() {
    return SingleChildScrollView(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Score section
          _buildScoreSection(),
          
          const SizedBox(height: 14),
          
          // Difficulty section
          _buildDifficultySection(),
        ],
      ),
    );
  }

  Widget _buildScoreSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.emoji_events, size: 16, color: AppColors.gold),
            const SizedBox(width: 6),
            Text(
              'SCORE CIBLE',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: AppColors.goldOpacity(0.7),
                letterSpacing: 1,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [11, 21, 31].map((score) {
            final isSelected = _selectedScore == score;
            return Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _selectedScore = score),
                child: Container(
                  margin: EdgeInsets.only(right: score != 31 ? 8 : 0),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    gradient: isSelected
                        ? LinearGradient(colors: [AppColors.gold, const Color(0xFFE8B946)])
                        : null,
                    color: isSelected ? null : Colors.white.withAlpha(15),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSelected ? AppColors.gold : Colors.white.withAlpha(30),
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      '$score',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: isSelected ? AppColors.darkRed : Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildDifficultySection() {
    final difficulties = [
      (GameConstants.aiEasy, 'Facile', '🌱'),
      (GameConstants.aiMedium, 'Moyen', '⚔️'),
      (GameConstants.aiHard, 'Difficile', '🔥'),
      (GameConstants.aiExpert, 'Expert', '👑'),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.psychology, size: 16, color: AppColors.gold),
            const SizedBox(width: 6),
            Text(
              'DIFFICULTÉ IA',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: AppColors.goldOpacity(0.7),
                letterSpacing: 1,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: difficulties.map((diff) {
            final isSelected = _selectedDifficulty == diff.$1;
            return Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _selectedDifficulty = diff.$1),
                child: Container(
                  margin: EdgeInsets.only(right: diff.$1 != GameConstants.aiExpert ? 6 : 0),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    gradient: isSelected
                        ? LinearGradient(colors: [AppColors.gold, const Color(0xFFE8B946)])
                        : null,
                    color: isSelected ? null : Colors.white.withAlpha(15),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSelected ? AppColors.gold : Colors.white.withAlpha(30),
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(diff.$3, style: const TextStyle(fontSize: 18)),
                      const SizedBox(height: 2),
                      Text(
                        diff.$2,
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? AppColors.darkRed : Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildStartButton() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      child: AnimatedBuilder(
        animation: _glowController,
        builder: (context, child) {
          return GestureDetector(
            onTap: _startGame,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.gold, const Color(0xFFE8B946)],
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.goldOpacity(0.4 + _glowController.value * 0.2),
                    blurRadius: 16,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.play_arrow_rounded, size: 28, color: AppColors.darkRed),
                  const SizedBox(width: 8),
                  Text(
                    'JOUER',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: AppColors.darkRed,
                      letterSpacing: 2,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _startGame() {
    _audioService.playButtonTap();
    final config = GameConfig(
      playerCount: _selectedMode == 0 ? 2 : 4,
      targetScore: _selectedScore,
      aiDifficulty: _selectedDifficulty,
      playerName: 'Vous',
      isTeamMode: _selectedMode == 1,
    );
    Navigator.pop(context, config);
  }
}
