// lib/features/settings/presentation/pages/settings_page.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/game_constants.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../../../core/services/audio_service.dart';

/// Settings page for game preferences
class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final AudioService _audioService = AudioService();
  bool _soundEnabled = true;
  bool _musicEnabled = true;
  bool _timerEnabled = true;
  bool _vibrationEnabled = true;
  int _timerDuration = 60;
  String _defaultDifficulty = GameConstants.aiMedium;

  @override
  void initState() {
    super.initState();
    _loadAudioSettings();
  }

  void _loadAudioSettings() async {
    await _audioService.initialize();
    setState(() {
      _soundEnabled = _audioService.isSoundEnabled;
      _musicEnabled = _audioService.isMusicEnabled;
      _vibrationEnabled = _audioService.isVibrationEnabled;
    });
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
              child: Column(
                children: [
                  _buildHeader(themeProvider),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSection(
                            'Apparence',
                            Icons.palette,
                            [
                              _buildThemeToggle(themeProvider),
                            ],
                            themeProvider,
                          ),
                          const SizedBox(height: 24),
                          _buildSection(
                            'Audio',
                            Icons.volume_up,
                            [
                              _buildSwitchTile(
                                'Effets sonores',
                                'Sons des cartes et actions',
                                Icons.music_note,
                                _soundEnabled,
                                (val) {
                                  setState(() => _soundEnabled = val);
                                  _audioService.setSoundEnabled(val);
                                },
                                themeProvider,
                              ),
                              _buildSwitchTile(
                                'Musique de fond',
                                'Ambiance musicale pendant le jeu',
                                Icons.library_music,
                                _musicEnabled,
                                (val) {
                                  setState(() => _musicEnabled = val);
                                  _audioService.setMusicEnabled(val);
                                },
                                themeProvider,
                              ),
                              _buildSwitchTile(
                                'Vibrations',
                                'Retour haptique sur les actions',
                                Icons.vibration,
                                _vibrationEnabled,
                                (val) {
                                  setState(() => _vibrationEnabled = val);
                                  _audioService.setVibrationEnabled(val);
                                },
                                themeProvider,
                              ),
                            ],
                            themeProvider,
                          ),
                          const SizedBox(height: 24),
                          _buildSection(
                            'Jeu',
                            Icons.games,
                            [
                              _buildSwitchTile(
                                'Timer par tour',
                                'Limite de temps pour chaque tour',
                                Icons.timer,
                                _timerEnabled,
                                (val) => setState(() => _timerEnabled = val),
                                themeProvider,
                              ),
                              if (_timerEnabled)
                                _buildTimerSlider(themeProvider),
                              _buildDifficultySelector(themeProvider),
                            ],
                            themeProvider,
                          ),
                          const SizedBox(height: 24),
                          _buildSection(
                            'À propos',
                            Icons.info_outline,
                            [
                              _buildInfoTile(
                                'Version',
                                '1.0.0',
                                Icons.code,
                                themeProvider,
                              ),
                              _buildInfoTile(
                                'Développeur',
                                'Chkobba Team',
                                Icons.person,
                                themeProvider,
                              ),
                            ],
                            themeProvider,
                          ),
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

  Widget _buildHeader(ThemeProvider themeProvider) {
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
          Text(
            'Paramètres',
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
    IconData icon,
    List<Widget> children,
    ThemeProvider themeProvider,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: themeProvider.isRedTheme ? AppColors.gold : AppColors.primaryRed,
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: themeProvider.textColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: themeProvider.isRedTheme
                ? AppColors.whiteOpacity(0.08)
                : Colors.white,
            borderRadius: BorderRadius.circular(16),
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
            children: children,
          ),
        ),
      ],
    );
  }

  Widget _buildThemeToggle(ThemeProvider themeProvider) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Icon(
            Icons.brightness_6,
            color: themeProvider.isRedTheme ? AppColors.gold : AppColors.grey600,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Thème',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: themeProvider.textColor,
                  ),
                ),
                Text(
                  themeProvider.isRedTheme ? 'Mode sombre rouge' : 'Mode clair',
                  style: TextStyle(
                    fontSize: 12,
                    color: themeProvider.secondaryTextColor,
                  ),
                ),
              ],
            ),
          ),
          _buildThemeSwitcher(themeProvider),
        ],
      ),
    );
  }

  Widget _buildThemeSwitcher(ThemeProvider themeProvider) {
    return GestureDetector(
      onTap: () => themeProvider.toggleTheme(),
      child: Container(
        width: 70,
        height: 36,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: themeProvider.isRedTheme
              ? AppColors.goldGradient
              : LinearGradient(colors: [AppColors.grey200, AppColors.grey300]),
        ),
        child: Stack(
          children: [
            AnimatedPositioned(
              duration: const Duration(milliseconds: 200),
              left: themeProvider.isRedTheme ? 36 : 4,
              top: 4,
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.blackOpacity(0.2),
                      blurRadius: 4,
                    ),
                  ],
                ),
                child: Icon(
                  themeProvider.isRedTheme ? Icons.dark_mode : Icons.light_mode,
                  size: 16,
                  color: themeProvider.isRedTheme
                      ? AppColors.primaryRed
                      : AppColors.gold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchTile(
    String title,
    String subtitle,
    IconData icon,
    bool value,
    ValueChanged<bool> onChanged,
    ThemeProvider themeProvider,
  ) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Icon(
            icon,
            color: themeProvider.isRedTheme
                ? (value ? AppColors.gold : Colors.white54)
                : (value ? AppColors.primaryRed : AppColors.grey400),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: themeProvider.textColor,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: themeProvider.secondaryTextColor,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.gold,
          ),
        ],
      ),
    );
  }

  Widget _buildTimerSlider(ThemeProvider themeProvider) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Durée du timer',
                style: TextStyle(
                  fontSize: 13,
                  color: themeProvider.secondaryTextColor,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.goldOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${_timerDuration}s',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.gold,
                  ),
                ),
              ),
            ],
          ),
          Slider(
            value: _timerDuration.toDouble(),
            min: 30,
            max: 120,
            divisions: 6,
            activeColor: AppColors.gold,
            inactiveColor: themeProvider.isRedTheme
                ? Colors.white24
                : AppColors.grey200,
            onChanged: (val) => setState(() => _timerDuration = val.round()),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('30s', style: TextStyle(fontSize: 11, color: themeProvider.secondaryTextColor)),
              Text('120s', style: TextStyle(fontSize: 11, color: themeProvider.secondaryTextColor)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDifficultySelector(ThemeProvider themeProvider) {
    final difficulties = [
      (GameConstants.aiEasy, 'Facile', '🌱'),
      (GameConstants.aiMedium, 'Moyen', '🎯'),
      (GameConstants.aiHard, 'Difficile', '🔥'),
      (GameConstants.aiExpert, 'Expert', '👑'),
    ];

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.psychology,
                color: themeProvider.isRedTheme ? AppColors.gold : AppColors.grey600,
              ),
              const SizedBox(width: 16),
              Text(
                'Difficulté IA par défaut',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: themeProvider.textColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: difficulties.map((diff) {
              final isSelected = _defaultDifficulty == diff.$1;
              return GestureDetector(
                onTap: () => setState(() => _defaultDifficulty = diff.$1),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.gold
                        : themeProvider.isRedTheme
                            ? Colors.white.withAlpha(26)
                            : AppColors.grey100,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.gold
                          : themeProvider.isRedTheme
                              ? Colors.white.withAlpha(51)
                              : AppColors.grey300,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(diff.$3, style: const TextStyle(fontSize: 14)),
                      const SizedBox(width: 6),
                      Text(
                        diff.$2,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: isSelected
                              ? AppColors.darkRed
                              : themeProvider.textColor,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoTile(
    String title,
    String value,
    IconData icon,
    ThemeProvider themeProvider,
  ) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Icon(
            icon,
            color: themeProvider.isRedTheme ? Colors.white54 : AppColors.grey500,
          ),
          const SizedBox(width: 16),
          Text(
            title,
            style: TextStyle(
              fontSize: 15,
              color: themeProvider.textColor,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              color: themeProvider.secondaryTextColor,
            ),
          ),
        ],
      ),
    );
  }
}
