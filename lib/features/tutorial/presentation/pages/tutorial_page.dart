// lib/features/tutorial/presentation/pages/tutorial_page.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;
import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/theme_provider.dart';

/// Premium interactive tutorial — card-table aesthetic.
class TutorialPage extends StatefulWidget {
  const TutorialPage({super.key});

  @override
  State<TutorialPage> createState() => _TutorialPageState();
}

class _TutorialPageState extends State<TutorialPage>
    with TickerProviderStateMixin {
  int _currentStep = 0;
  late AnimationController _slideController;
  late AnimationController _pulseController;
  late AnimationController _sparkleController;
  late PageController _pageController;

  static const _steps = <_TutorialStep>[
    _TutorialStep(
      icon: Icons.style,
      emoji: '🃏',
      title: 'Le Jeu de Cartes',
      subtitle: 'Découvrez les bases',
      description:
          'Le Chkobba se joue avec un jeu de 40 cartes tunisien. Les cartes vont de 1 (As) à 7, plus Valet (8), Dame (9) et Roi (10).',
      tips: [
        'Chaque carte a une valeur numérique',
        '4 familles : Épée, Bâton, Coupe, Denier',
        'Le 7 de Denier est la carte la plus précieuse',
      ],
      accentColor: Color(0xFFDBA936),
    ),
    _TutorialStep(
      icon: Icons.handshake,
      emoji: '🤝',
      title: 'Distribution',
      subtitle: 'Comment commence la partie',
      description:
          'Au début, 4 cartes sont posées sur la table et chaque joueur reçoit 3 cartes en main. Quand les mains sont vides, on redistribue 3 cartes.',
      tips: [
        '4 cartes sur la table au départ',
        '3 cartes en main par joueur',
        'Redistribution quand les mains sont vides',
      ],
      accentColor: Color(0xFF4ECDC4),
    ),
    _TutorialStep(
      icon: Icons.touch_app,
      emoji: '👆',
      title: 'Jouer une Carte',
      subtitle: 'Capturer ou déposer',
      description:
          'À votre tour, glissez une carte de votre main vers la table. Si elle correspond à une carte (même valeur) ou à une somme de cartes, vous les capturez toutes !',
      tips: [
        'Glissez votre carte vers la table',
        'Capturez une carte de même valeur',
        'Ou capturez une combinaison qui fait la somme',
        'Sinon, la carte est déposée sur la table',
      ],
      accentColor: Color(0xFF6C5CE7),
    ),
    _TutorialStep(
      icon: Icons.auto_awesome,
      emoji: '⭐',
      title: 'CHKOBBA !',
      subtitle: 'Le coup ultime',
      description:
          'Quand vous capturez TOUTES les cartes de la table en un seul coup, c\'est une CHKOBBA ! Vous gagnez 1 point bonus. C\'est le coup le plus excitant du jeu !',
      tips: [
        'Videz la table = CHKOBBA (+1 point)',
        'Impossible sur le dernier tour de la manche',
        'Cri de joie traditionnel !',
      ],
      accentColor: Color(0xFFFFD700),
    ),
    _TutorialStep(
      icon: Icons.calculate,
      emoji: '📊',
      title: 'Calcul des Points',
      subtitle: 'Fin de manche',
      description:
          'À la fin de chaque manche (quand le paquet est vide), on compte les points. Le dernier joueur à capturer récupère les cartes restantes sur la table.',
      tips: [
        'Plus de cartes capturées → +1 point',
        'Plus de Deniers capturés → +1 point',
        '7 de Denier (Bermila) → +1 point',
        'Chaque Chkobba → +1 point',
      ],
      accentColor: Color(0xFFE17055),
    ),
    _TutorialStep(
      icon: Icons.emoji_events,
      emoji: '🏆',
      title: 'Gagner la Partie',
      subtitle: 'Victoire !',
      description:
          'La partie se joue en plusieurs manches. Le premier joueur à atteindre le score cible (11, 21 ou 31 points) remporte la victoire !',
      tips: [
        'Score cible configurable : 11, 21 ou 31',
        'Le meneur doit avoir au moins 1 point d\'avance',
        'Stratégie : visez le 7 de Denier et les Chkobbas',
      ],
      accentColor: Color(0xFF00B894),
    ),
    _TutorialStep(
      icon: Icons.lightbulb,
      emoji: '💡',
      title: 'Astuces Pro',
      subtitle: 'Devenez un expert',
      description:
          'Maîtrisez ces techniques pour dominer vos adversaires et grimper dans les niveaux !',
      tips: [
        'Comptez les cartes jouées',
        'Protégez votre 7 de Denier',
        'Évitez de laisser des Chkobbas à l\'adversaire',
        'Capturez les Deniers en priorité',
        'Jouez stratégiquement en fin de manche',
      ],
      accentColor: Color(0xFFFDCB6E),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    )..forward();
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    _sparkleController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _slideController.dispose();
    _pulseController.dispose();
    _sparkleController.dispose();
    super.dispose();
  }

  void _goToStep(int step) {
    if (step < 0 || step >= _steps.length) return;
    _slideController.reset();
    _slideController.forward();
    _pageController.animateToPage(
      step,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
    setState(() => _currentStep = step);
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
                      _buildProgressBar(themeProvider),
                      Expanded(
                        child: PageView.builder(
                          controller: _pageController,
                          onPageChanged: (i) => setState(() => _currentStep = i),
                          itemCount: _steps.length,
                          itemBuilder: (context, index) {
                            return _buildStepContent(
                                _steps[index], index, themeProvider);
                          },
                        ),
                      ),
                      _buildNavigationBar(themeProvider),
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
          top: 60,
          right: 30,
          child: AnimatedBuilder(
            animation: _sparkleController,
            builder: (context, child) {
              return Transform.rotate(
                angle: _sparkleController.value * 2 * math.pi,
                child: Icon(
                  Icons.star,
                  color: themeProvider.isRedTheme
                      ? AppColors.goldOpacity(0.15)
                      : AppColors.primaryRedOpacity(0.1),
                  size: 24,
                ),
              );
            },
          ),
        ),
        Positioned(
          bottom: 120,
          left: 40,
          child: AnimatedBuilder(
            animation: _sparkleController,
            builder: (context, child) {
              return Transform.rotate(
                angle: -_sparkleController.value * 2 * math.pi,
                child: Icon(
                  Icons.auto_awesome,
                  color: themeProvider.isRedTheme
                      ? AppColors.goldOpacity(0.12)
                      : AppColors.primaryRedOpacity(0.08),
                  size: 20,
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
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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
            Icons.school_rounded,
            color: AppColors.gold,
            size: 28,
          ),
          const SizedBox(width: 12),
          Text(
            'Tutoriel',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: themeProvider.textColor,
            ),
          ),
          const Spacer(),
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
              '${_currentStep + 1} / ${_steps.length}',
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

  Widget _buildProgressBar(ThemeProvider themeProvider) {
    final isRed = themeProvider.isRedTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: List.generate(_steps.length, (i) {
          final isActive = i <= _currentStep;
          final isCurrent = i == _currentStep;
          return Expanded(
            child: Container(
              height: isCurrent ? 5 : 3,
              margin: const EdgeInsets.symmetric(horizontal: 2),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(3),
                gradient: isActive ? AppColors.goldGradient : null,
                color: isActive
                    ? null
                    : isRed
                        ? AppColors.whiteOpacity(0.12)
                        : AppColors.grey200,
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildStepContent(
      _TutorialStep step, int index, ThemeProvider themeProvider) {

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left: Hero card
          SizedBox(
            width: 200,
            child: _buildHeroCard(step, themeProvider),
          ),

          const SizedBox(width: 20),

          // Right: Tips list
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Section label
                Row(
                  children: [
                    Icon(Icons.tips_and_updates,
                        size: 16, color: step.accentColor),
                    const SizedBox(width: 6),
                    Text(
                      'POINTS CLÉS',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.5,
                        color: step.accentColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Tips
                ...step.tips.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final tip = entry.value;
                  return _buildTipItem(tip, idx, step.accentColor,
                      themeProvider);
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroCard(
      _TutorialStep step, ThemeProvider themeProvider) {
    final isRed = themeProvider.isRedTheme;

    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        final scale = 1.0 + 0.015 * _pulseController.value;
        return Transform.scale(
          scale: scale,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isRed
                    ? [
                        step.accentColor.withAlpha(25),
                        step.accentColor.withAlpha(8),
                      ]
                    : [
                        step.accentColor.withAlpha(18),
                        step.accentColor.withAlpha(5),
                      ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: step.accentColor.withAlpha(60),
                width: 1.5,
              ),
              boxShadow: isRed
                  ? null
                  : [
                      BoxShadow(
                        color: step.accentColor.withAlpha(20),
                        blurRadius: 20,
                        offset: const Offset(0, 4),
                      ),
                    ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Emoji + sparkle
                Stack(
                  alignment: Alignment.center,
                  children: [
                    AnimatedBuilder(
                      animation: _sparkleController,
                      builder: (context, child) {
                        return Transform.rotate(
                          angle: _sparkleController.value * 2 * math.pi,
                          child: Icon(
                            Icons.auto_awesome,
                            size: 48,
                            color: step.accentColor.withAlpha(30),
                          ),
                        );
                      },
                    ),
                    Text(
                      step.emoji,
                      style: const TextStyle(fontSize: 40),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Title
                Text(
                  step.title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: themeProvider.textColor,
                  ),
                ),
                const SizedBox(height: 4),

                // Subtitle chip
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: step.accentColor.withAlpha(30),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    step.subtitle,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: step.accentColor,
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // Description
                Text(
                  step.description,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.5,
                    color: isRed
                        ? Colors.white.withAlpha(180)
                        : AppColors.grey700,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTipItem(String tip, int index, Color accent,
      ThemeProvider themeProvider) {
    final isRed = themeProvider.isRedTheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isRed
              ? AppColors.whiteOpacity(0.06)
              : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isRed
                ? AppColors.whiteOpacity(0.08)
                : AppColors.grey200,
          ),
          boxShadow: isRed
              ? null
              : [
                  BoxShadow(
                    color: AppColors.blackOpacity(0.03),
                    blurRadius: 6,
                    offset: const Offset(0, 1),
                  ),
                ],
        ),
        child: Row(
          children: [
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: accent.withAlpha(25),
                borderRadius: BorderRadius.circular(7),
              ),
              child: Center(
                child: Text(
                  '${index + 1}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: accent,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                tip,
                style: TextStyle(
                  fontSize: 12,
                  height: 1.3,
                  color: themeProvider.textColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavigationBar(ThemeProvider themeProvider) {
    final isRed = themeProvider.isRedTheme;
    final isFirst = _currentStep == 0;
    final isLast = _currentStep == _steps.length - 1;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Row(
        children: [
          // Previous
          if (!isFirst)
            _buildNavButton(
              Icons.arrow_back_ios_rounded,
              'Précédent',
              () => _goToStep(_currentStep - 1),
              themeProvider,
              isPrimary: false,
            )
          else
            const SizedBox(width: 120),

          const Spacer(),

          // Step dots
          Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(_steps.length, (i) {
              return Container(
                width: i == _currentStep ? 16 : 6,
                height: 6,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(3),
                  color: i == _currentStep
                      ? AppColors.gold
                      : isRed
                          ? AppColors.whiteOpacity(0.15)
                          : AppColors.grey200,
                ),
              );
            }),
          ),

          const Spacer(),

          // Next / Finish
          _buildNavButton(
            isLast ? Icons.check_rounded : Icons.arrow_forward_ios_rounded,
            isLast ? 'Terminer' : 'Suivant',
            isLast
                ? () => Navigator.pop(context)
                : () => _goToStep(_currentStep + 1),
            themeProvider,
            isPrimary: true,
          ),
        ],
      ),
    );
  }

  Widget _buildNavButton(
    IconData icon,
    String label,
    VoidCallback onTap,
    ThemeProvider themeProvider, {
    required bool isPrimary,
  }) {
    final isRed = themeProvider.isRedTheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          gradient: isPrimary ? AppColors.goldGradient : null,
          color: isPrimary
              ? null
              : isRed
                  ? AppColors.whiteOpacity(0.08)
                  : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isPrimary
                ? AppColors.gold.withAlpha(60)
                : isRed
                    ? AppColors.whiteOpacity(0.1)
                    : AppColors.grey200,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!isPrimary) ...[
              Icon(icon, size: 14,
                  color: themeProvider.secondaryTextColor),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: isPrimary
                    ? AppColors.darkRed
                    : themeProvider.secondaryTextColor,
              ),
            ),
            if (isPrimary) ...[
              const SizedBox(width: 6),
              Icon(icon, size: 14, color: AppColors.darkRed),
            ],
          ],
        ),
      ),
    );
  }
}

class _TutorialStep {
  final IconData icon;
  final String emoji;
  final String title;
  final String subtitle;
  final String description;
  final List<String> tips;
  final Color accentColor;

  const _TutorialStep({
    required this.icon,
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.tips,
    required this.accentColor,
  });
}
