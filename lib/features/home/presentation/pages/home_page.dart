// lib/features/home/presentation/pages/home_page.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math' as math;
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../../../core/services/audio_service.dart';
import '../../../../core/services/game_history_service.dart';
import '../../../game/presentation/pages/game_board_page.dart';
import '../../../game/presentation/widgets/game_setup_dialog.dart';


class ChkobaHomePage extends StatefulWidget {
  const ChkobaHomePage({super.key});

  @override
  State<ChkobaHomePage> createState() => _ChkobaHomePageState();
}

class _ChkobaHomePageState extends State<ChkobaHomePage> with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _cardController;
  late AnimationController _sparkleController;
  late AnimationController _pulseController;
  final AudioService _audioService = AudioService();

  late Animation<double> _fadeAnimation;

  // Player stats
  String _playerName = 'Joueur';
  int _gamesPlayed = 0;
  int _gamesWon = 0;
  int _highestScore = 0;
  int _totalChkobbas = 0;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _initAudio();
    _loadPlayerData();
  }

  Future<void> _loadPlayerData() async {
    final prefs = await SharedPreferences.getInstance();
    final stats = await GameHistoryService.getPlayerStats();
    if (!mounted) return;
    setState(() {
      _playerName = prefs.getString('player_name') ?? 'Joueur';
      _gamesPlayed = stats.gamesPlayed;
      _gamesWon = stats.gamesWon;
      _highestScore = stats.highestScore;
      _totalChkobbas = stats.totalChkobbas;
    });
  }

  int get _playerLevel {
    if (_gamesPlayed == 0) return 1;
    return (_gamesPlayed ~/ 5) + 1;
  }

  String get _playerInitials {
    final parts = _playerName.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return _playerName.length >= 2
        ? _playerName.substring(0, 2).toUpperCase()
        : _playerName.toUpperCase();
  }

  void _initAudio() async {
    await _audioService.initialize();
    _audioService.startLobbyMusic();
  }

  void _initAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _cardController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    );

    _sparkleController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );

    _fadeController.forward();
    _cardController.repeat();
    _sparkleController.repeat();
    _pulseController.repeat();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _cardController.dispose();
    _sparkleController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _showFeatureSnackBar(String feature) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature en développement'),
        backgroundColor: themeProvider.isRedTheme ? AppColors.primaryRed : AppColors.grey900,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _startQuickGame() async {
    _audioService.playButtonTap();
    final config = await GameSetupDialog.show(context);
    
    if (config != null && mounted) {
      Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              GameBoardPage(config: config),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: animation,
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.95, end: 1.0).animate(
                  CurvedAnimation(parent: animation, curve: Curves.easeOut),
                ),
                child: child,
              ),
            );
          },
          transitionDuration: const Duration(milliseconds: 400),
        ),
      ).then((_) {
        // Refresh stats when returning from game
        if (mounted) _loadPlayerData();
      });
    }
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
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: _buildContent(themeProvider),
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
            animation: _sparkleController,
            builder: (context, child) {
              return Transform.rotate(
                angle: _sparkleController.value * 2 * math.pi,
                child: Icon(
                  Icons.star,
                  color: themeProvider.isRedTheme
                      ? AppColors.goldOpacity(0.3)
                      : AppColors.primaryRedOpacity(0.3),
                  size: 20,
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildContent(ThemeProvider themeProvider) {
    return Column(
      children: [
        // Header
        _buildHeader(themeProvider),

        const SizedBox(height: 12),

        // Main Content - Single Row
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Game Modes
                SizedBox(
                  width: 450,
                  child: _buildGameModesSection(themeProvider),
                ),

                const SizedBox(width: 16),

                // Profile/Stats
                SizedBox(
                  width: 280,
                  child: _buildStatsSection(themeProvider),
                ),

                const SizedBox(width: 16),

                // Quick Actions
                SizedBox(
                  width: 200,
                  child: _buildQuickActionsColumn(themeProvider),
                ),

                const SizedBox(width: 16),
              ],
            ),
          ),
        ),

        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildHeader(ThemeProvider themeProvider) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          // Logo
          SizedBox(
            width: 60,
            height: 45,
            child: Stack(
              alignment: Alignment.center,
              children: [
                AnimatedBuilder(
                  animation: _cardController,
                  builder: (context, child) {
                    return Transform.translate(
                      offset: Offset(
                        -12 + 2 * math.sin(_cardController.value * 2 * math.pi),
                        math.sin(_cardController.value * 2 * math.pi + 1),
                      ),
                      child: _buildMiniCard(AppStrings.heartSymbol, AppColors.primaryRed),
                    );
                  },
                ),
                AnimatedBuilder(
                  animation: _cardController,
                  builder: (context, child) {
                    return Transform.translate(
                      offset: Offset(
                        12 + 2 * math.sin(_cardController.value * 2 * math.pi + 2),
                        math.sin(_cardController.value * 2 * math.pi + 3),
                      ),
                      child: _buildMiniCard(AppStrings.diamondSymbol, AppColors.gold),
                    );
                  },
                ),
              ],
            ),
          ),

          const SizedBox(width: 12),

          ShaderMask(
            shaderCallback: (bounds) => LinearGradient(
              colors: themeProvider.isRedTheme
                  ? [AppColors.white, AppColors.gold]
                  : [AppColors.primaryRed, AppColors.gold],
            ).createShader(bounds),
            child: const Text(
              AppStrings.appName,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                color: AppColors.white,
              ),
            ),
          ),

          const Spacer(),

          // Theme Toggle
          IconButton(
            onPressed: () => themeProvider.toggleTheme(),
            icon: Icon(
              themeProvider.themeIconAlt,
              color: themeProvider.textColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniCard(String symbol, Color color) {
    return Container(
      width: 22,
      height: 32,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(4),
        boxShadow: [
          BoxShadow(
            color: AppColors.blackOpacity(0.2),
            offset: const Offset(0, 2),
            blurRadius: 4,
          ),
        ],
      ),
      child: Center(
        child: Text(
          symbol,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ),
    );
  }

  Widget _buildGameModesSection(ThemeProvider themeProvider) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: themeProvider.isRedTheme
              ? [AppColors.whiteOpacity(0.15), AppColors.whiteOpacity(0.05)]
              : [AppColors.white, AppColors.grey50],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: themeProvider.borderColor),
        boxShadow: themeProvider.isRedTheme ? null : [
          BoxShadow(
            color: AppColors.grey300.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.games,
                color: themeProvider.accentColor,
                size: 16,
              ),
              const SizedBox(width: 6),
              Text(
                'Modes de Jeu',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: themeProvider.textColor,
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return GridView.count(
                  crossAxisCount: 2,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  childAspectRatio: 2.0,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _buildGameModeCard(
                      'Partie Rapide',
                      'vs IA',
                      Icons.flash_on,
                      _startQuickGame,
                      themeProvider,
                      isPrimary: true,
                    ),
                    _buildGameModeCard(
                      'Multijoueur',
                      'En ligne',
                      Icons.people,
                          () => _showFeatureSnackBar('Multijoueur'),
                      themeProvider,
                      isComingSoon: true,
                    ),
                    _buildGameModeCard(
                      'Tournoi',
                      'Compétition',
                      Icons.emoji_events,
                          () => _showFeatureSnackBar('Tournoi'),
                      themeProvider,
                      isComingSoon: true,
                    ),
                    _buildGameModeCard(
                      'Tutoriel',
                      'Apprendre',
                      Icons.school,
                          () => Navigator.pushNamed(context, '/tutorial'),
                      themeProvider,
                    ),
                    _buildGameModeCard(
                      '2 vs 2',
                      'Équipe',
                      Icons.group,
                          () => _showFeatureSnackBar('Mode Équipe'),
                      themeProvider,
                      isComingSoon: true,
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGameModeCard(
      String title,
      String subtitle,
      IconData icon,
      VoidCallback onTap,
      ThemeProvider themeProvider, {
        bool isPrimary = false,
        bool isComingSoon = false,
      }) {
    return AnimatedBuilder(
      animation: isPrimary ? _pulseController : _fadeController,
      builder: (context, child) {
        final scale = isPrimary
            ? 1 + 0.02 * math.sin(_pulseController.value * 2 * math.pi)
            : 1.0;

        return Transform.scale(
          scale: scale,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                decoration: BoxDecoration(
                  gradient: isPrimary
                      ? AppColors.goldGradient
                      : LinearGradient(
                    colors: themeProvider.isRedTheme
                        ? [AppColors.whiteOpacity(0.15), AppColors.whiteOpacity(0.05)]
                        : [AppColors.white, AppColors.grey50],
                  ),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isPrimary
                        ? AppColors.whiteOpacity(0.3)
                        : themeProvider.borderColor,
                  ),
                ),
                child: Stack(
                  children: [
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            icon,
                            size: 18,
                            color: isPrimary
                                ? AppColors.darkRed
                                : isComingSoon
                                    ? themeProvider.secondaryTextColor
                                    : themeProvider.accentColor,
                          ),
                          const SizedBox(height: 3),
                          Text(
                            title,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: isPrimary
                                  ? AppColors.darkRed
                                  : themeProvider.textColor,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            subtitle,
                            style: TextStyle(
                              fontSize: 9,
                              color: isPrimary
                                  ? AppColors.darkRed.withOpacity(0.8)
                                  : themeProvider.secondaryTextColor,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    if (isComingSoon)
                      Positioned(
                        top: 4,
                        right: 4,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                          decoration: BoxDecoration(
                            color: AppColors.gold,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'Bientôt',
                            style: TextStyle(
                              fontSize: 7,
                              fontWeight: FontWeight.bold,
                              color: AppColors.darkRed,
                            ),
                          ),
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

  Widget _buildStatsSection(ThemeProvider themeProvider) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: themeProvider.isRedTheme
              ? [AppColors.whiteOpacity(0.1), AppColors.whiteOpacity(0.05)]
              : [AppColors.white, AppColors.grey50],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: themeProvider.borderColor),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
          Row(
            children: [
              Icon(
                Icons.person,
                color: AppColors.orangeSection,
                size: 16,
              ),
              const SizedBox(width: 6),
              Text(
                'Mon Profil',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: themeProvider.textColor,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Center(
            child: CircleAvatar(
              radius: 25,
              backgroundColor: AppColors.gold,
              child: Text(
                _playerInitials,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.darkRed,
                ),
              ),
            ),
          ),

          const SizedBox(height: 8),

          Center(
            child: Text(
              _playerName,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: themeProvider.textColor,
              ),
            ),
          ),

          const SizedBox(height: 4),

          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.gold,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Niveau $_playerLevel',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: AppColors.darkRed,
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),

          _buildStatItem('Parties', '$_gamesPlayed', Icons.games, themeProvider),
          const SizedBox(height: 4),
          _buildStatItem('Victoires', '$_gamesWon', Icons.star, themeProvider),
          const SizedBox(height: 4),
          _buildStatItem('Meilleur', '$_highestScore', Icons.emoji_events, themeProvider),
          const SizedBox(height: 4),
          _buildStatItem('Chkobbas', '$_totalChkobbas', Icons.auto_awesome, themeProvider),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, ThemeProvider themeProvider) {
    return Row(
      children: [
        Icon(icon, color: AppColors.orangeSection, size: 14),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: themeProvider.secondaryTextColor,
              fontSize: 11,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: themeProvider.textColor,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActionsColumn(ThemeProvider themeProvider) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: themeProvider.isRedTheme
              ? [AppColors.whiteOpacity(0.1), AppColors.whiteOpacity(0.05)]
              : [AppColors.white, AppColors.grey50],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: themeProvider.borderColor),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildQuickActionButton(
            Icons.history,
            'Historique',
            themeProvider,
                () => Navigator.pushNamed(context, '/history'),
          ),
          _buildQuickActionButton(
            Icons.settings,
            'Paramètres',
            themeProvider,
                () => Navigator.pushNamed(context, '/settings'),
          ),
          _buildQuickActionButton(
            Icons.help_outline,
            'Aide',
            themeProvider,
                () => Navigator.pushNamed(context, '/rules'),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionButton(
      IconData icon,
      String label,
      ThemeProvider themeProvider,
      VoidCallback onTap,
      ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: themeProvider.accentColor,
              size: 28,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: themeProvider.textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}