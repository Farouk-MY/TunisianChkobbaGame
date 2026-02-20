// lib/features/game/presentation/pages/rules_page.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/theme_provider.dart';

/// Game rules and help page
class RulesPage extends StatelessWidget {
  const RulesPage({super.key});

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
              child: Column(
                children: [
                  _buildHeader(context, themeProvider),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSection(
                            '🎯 Objectif',
                            'Le but du jeu est d\'atteindre le score cible (11, 21 ou 31 points) en capturant des cartes sur la table.',
                            themeProvider,
                          ),
                          _buildSection(
                            '🃏 Le Jeu de Cartes',
                            'Le jeu utilise un jeu de 40 cartes (As à 7, Valet, Dame, Roi).\n\n'
                            '• As = 1 point\n'
                            '• 2 à 7 = valeur nominale\n'
                            '• Valet = 8\n'
                            '• Dame = 9\n'
                            '• Roi = 10',
                            themeProvider,
                          ),
                          _buildSection(
                            '👆 Comment Jouer',
                            '1. Chaque joueur reçoit 3 cartes\n'
                            '2. 4 cartes sont placées sur la table\n'
                            '3. À votre tour, jouez une carte:\n'
                            '   • Si elle correspond à une carte sur la table, capturez-la\n'
                            '   • Si elle correspond à une somme, capturez toutes les cartes\n'
                            '   • Sinon, déposez la carte sur la table',
                            themeProvider,
                          ),
                          _buildSection(
                            '⭐ CHKOBBA!',
                            'Quand vous videz la table en capturant toutes les cartes, '
                            'vous marquez une CHKOBBA (+1 point bonus)!\n\n'
                            'C\'est le coup le plus excitant du jeu!',
                            themeProvider,
                            isHighlight: true,
                          ),
                          _buildSection(
                            '📊 Calcul des Points',
                            '• Plus de cartes capturées: +1 point\n'
                            '• Plus de carreaux: +1 point\n'
                            '• 7 de Carreau (Bermila): +1 point\n'
                            '• Chaque Chkobba: +1 point',
                            themeProvider,
                          ),
                          _buildSection(
                            '💎 Le 7 de Carreau',
                            'La carte la plus précieuse! Celui qui capture le 7 de carreau '
                            'gagne automatiquement 1 point.\n\n'
                            'On l\'appelle aussi "Bermila" ou "Setta".',
                            themeProvider,
                            isHighlight: true,
                          ),
                          _buildSection(
                            '🎮 Contrôles',
                            '• Glissez-déposez vos cartes sur la table\n'
                            '• Tapez sur les cartes de table pour les sélectionner\n'
                            '• Le timer vous donne 60 secondes par tour\n'
                            '• L\'IA joue automatiquement après vous',
                            themeProvider,
                          ),
                          _buildSection(
                            '🏆 Stratégies',
                            '• Gardez le compte des cartes jouées\n'
                            '• Priorité au 7 de carreau\n'
                            '• Évitez de laisser des opportunités de Chkobba\n'
                            '• Essayez de vider la table quand possible',
                            themeProvider,
                          ),
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
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
            Icons.menu_book,
            color: AppColors.gold,
            size: 28,
          ),
          const SizedBox(width: 12),
          Text(
            'Règles du Jeu',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: themeProvider.textColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(
    String title,
    String content,
    ThemeProvider themeProvider, {
    bool isHighlight = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: isHighlight
            ? LinearGradient(
                colors: themeProvider.isRedTheme
                    ? [AppColors.goldOpacity(0.2), AppColors.goldOpacity(0.1)]
                    : [AppColors.goldOpacity(0.15), AppColors.goldOpacity(0.05)],
              )
            : null,
        color: isHighlight
            ? null
            : themeProvider.isRedTheme
                ? AppColors.whiteOpacity(0.08)
                : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isHighlight
              ? AppColors.gold
              : themeProvider.isRedTheme
                  ? AppColors.whiteOpacity(0.1)
                  : AppColors.grey200,
          width: isHighlight ? 2 : 1,
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isHighlight
                  ? AppColors.gold
                  : themeProvider.textColor,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            content,
            style: TextStyle(
              fontSize: 14,
              height: 1.5,
              color: themeProvider.isRedTheme
                  ? Colors.white.withAlpha(204)
                  : AppColors.grey700,
            ),
          ),
        ],
      ),
    );
  }
}
