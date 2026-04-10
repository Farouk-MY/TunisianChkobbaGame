// lib/features/settings/presentation/pages/settings_page.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/game_constants.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../../../core/services/audio_service.dart';
import '../../../../core/services/game_history_service.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/services/profile_service.dart';

/// Settings page — audio, visuals, and game preferences.
class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final AudioService _audioService = AudioService();
  bool _soundEnabled = true;
  bool _musicEnabled = true;
  bool _vibrationEnabled = true;
  double _musicVolume = 0.55;
  double _sfxVolume = 0.80;
  bool _timerEnabled = true;
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
      _musicVolume = _audioService.musicVolume;
      _sfxVolume = _audioService.sfxVolume;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        final isRed = themeProvider.isRedTheme;
        final accent = isRed ? AppColors.gold : AppColors.primaryRed;

        return Scaffold(
          body: Container(
            decoration: BoxDecoration(
              gradient: isRed ? AppColors.primaryGradient : AppColors.whiteGradient,
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
                          // ── Appearance ──
                          _buildSection(
                            'Apparence',
                            Icons.palette,
                            [_buildThemeToggle(themeProvider)],
                            themeProvider,
                          ),

                          const SizedBox(height: 24),

                          // ── Compte (shown only when authenticated) ──
                          _buildAccountSection(themeProvider),

                          const SizedBox(height: 24),

                          // ── Audio ──
                          _buildSection(
                            'Audio',
                            Icons.volume_up,
                            [
                              _buildSwitchTile(
                                'Musique de fond',
                                'Ambiance musicale',
                                Icons.library_music,
                                _musicEnabled,
                                (val) {
                                  setState(() => _musicEnabled = val);
                                  _audioService.setMusicEnabled(val);
                                },
                                themeProvider,
                              ),
                              if (_musicEnabled)
                                _buildVolumeSlider(
                                  'Volume musique',
                                  Icons.music_note,
                                  _musicVolume,
                                  (val) {
                                    setState(() => _musicVolume = val);
                                    _audioService.setMusicVolume(val);
                                  },
                                  themeProvider,
                                  accent,
                                ),
                              _buildSwitchTile(
                                'Effets sonores',
                                'Sons des cartes et actions',
                                Icons.surround_sound,
                                _soundEnabled,
                                (val) {
                                  setState(() => _soundEnabled = val);
                                  _audioService.setSoundEnabled(val);
                                },
                                themeProvider,
                              ),
                              if (_soundEnabled)
                                _buildVolumeSlider(
                                  'Volume effets',
                                  Icons.graphic_eq,
                                  _sfxVolume,
                                  (val) {
                                    setState(() => _sfxVolume = val);
                                    _audioService.setSfxVolume(val);
                                  },
                                  themeProvider,
                                  accent,
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

                          // ── Game ──
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

                          // ── Data ──
                          _buildSection(
                            'Données',
                            Icons.storage,
                            [
                              _buildResetStatsButton(themeProvider),
                            ],
                            themeProvider,
                          ),

                          const SizedBox(height: 24),

                          // ── About ──
                          _buildSection(
                            'À propos',
                            Icons.info_outline,
                            [
                              _buildInfoTile('Version', '1.0.0', Icons.code, themeProvider),
                              _buildInfoTile('Développeur', 'Chkobba Team', Icons.person, themeProvider),
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

  // ┌─────────────────────────────────────────────────────────────────┐
  //  HEADER
  // └─────────────────────────────────────────────────────────────────┘

  Widget _buildHeader(ThemeProvider themeProvider) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(Icons.arrow_back_ios, color: themeProvider.textColor),
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

  // ┌─────────────────────────────────────────────────────────────────┐
  //  SECTION
  // └─────────────────────────────────────────────────────────────────┘

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
          child: Column(children: children),
        ),
      ],
    );
  }

  // ┌─────────────────────────────────────────────────────────────────┐
  //  THEME TOGGLE
  // └─────────────────────────────────────────────────────────────────┘

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
                  color: themeProvider.isRedTheme ? AppColors.primaryRed : AppColors.gold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ┌─────────────────────────────────────────────────────────────────┐
  //  SWITCH TILE
  // └─────────────────────────────────────────────────────────────────┘

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

  // ┌─────────────────────────────────────────────────────────────────┐
  //  VOLUME SLIDER
  // └─────────────────────────────────────────────────────────────────┘

  Widget _buildVolumeSlider(
    String label,
    IconData icon,
    double value,
    ValueChanged<double> onChanged,
    ThemeProvider themeProvider,
    Color accent,
  ) {
    final isRed = themeProvider.isRedTheme;
    final percent = (value * 100).round();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: isRed ? Colors.white38 : AppColors.grey500,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 4,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
                activeTrackColor: accent,
                inactiveTrackColor: isRed ? Colors.white12 : AppColors.grey200,
                thumbColor: accent,
                overlayColor: accent.withAlpha(40),
              ),
              child: Slider(
                value: value,
                min: 0.0,
                max: 1.0,
                onChanged: onChanged,
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 38,
            child: Text(
              '$percent%',
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isRed ? Colors.white54 : AppColors.grey600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ┌─────────────────────────────────────────────────────────────────┐
  //  TIMER SLIDER
  // └─────────────────────────────────────────────────────────────────┘

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
            inactiveColor:
                themeProvider.isRedTheme ? Colors.white24 : AppColors.grey200,
            onChanged: (val) => setState(() => _timerDuration = val.round()),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('30s',
                  style: TextStyle(
                      fontSize: 11,
                      color: themeProvider.secondaryTextColor)),
              Text('120s',
                  style: TextStyle(
                      fontSize: 11,
                      color: themeProvider.secondaryTextColor)),
            ],
          ),
        ],
      ),
    );
  }

  // ┌─────────────────────────────────────────────────────────────────┐
  //  DIFFICULTY SELECTOR
  // └─────────────────────────────────────────────────────────────────┘

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
                onTap: () {
                  _audioService.playButtonTap();
                  setState(() => _defaultDifficulty = diff.$1);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 8),
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
                      Text(diff.$3,
                          style: const TextStyle(fontSize: 14)),
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

  // ┌─────────────────────────────────────────────────────────────────┐
  //  INFO TILE
  // └─────────────────────────────────────────────────────────────────┘

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

  Widget _buildResetStatsButton(ThemeProvider themeProvider) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: InkWell(
        onTap: () => _confirmResetStats(themeProvider),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.red.withAlpha(20),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.red.withAlpha(40)),
          ),
          child: Row(
            children: [
              const Icon(Icons.delete_outline, color: Colors.redAccent, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Réinitialiser les statistiques',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: themeProvider.textColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Supprimer l\'historique et remettre les stats à zéro',
                      style: TextStyle(
                        fontSize: 11,
                        color: themeProvider.secondaryTextColor,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.redAccent, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmResetStats(ThemeProvider themeProvider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: themeProvider.isRedTheme
            ? const Color(0xFF1A0A12)
            : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Réinitialiser ?',
          style: TextStyle(color: themeProvider.textColor),
        ),
        content: Text(
          'Toutes vos statistiques et votre historique de parties seront supprimés. Cette action est irréversible.',
          style: TextStyle(color: themeProvider.secondaryTextColor, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Annuler',
              style: TextStyle(color: themeProvider.secondaryTextColor),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await GameHistoryService.clearHistory();
              await GameHistoryService.resetStats();
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Statistiques reinitialisees'),
                  backgroundColor: themeProvider.isRedTheme
                      ? AppColors.primaryRed
                      : AppColors.grey900,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
              );
            },
            child: const Text(
              'Supprimer',
              style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  // Account section
  Widget _buildAccountSection(ThemeProvider themeProvider) {
    final auth = context.watch<AuthService>();
    if (!auth.isAuthenticated) return const SizedBox.shrink();

    final profile = context.watch<ProfileService>();
    final isRed = themeProvider.isRedTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.account_circle_outlined,
              size: 20,
              color: isRed ? AppColors.gold : AppColors.primaryRed,
            ),
            const SizedBox(width: 8),
            Text(
              'Compte',
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
            color: isRed ? AppColors.whiteOpacity(0.08) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isRed ? AppColors.whiteOpacity(0.1) : AppColors.grey200,
            ),
          ),
          child: Column(
            children: [
              ListTile(
                leading: CircleAvatar(
                  radius: 20,
                  backgroundColor: AppColors.gold,
                  backgroundImage: profile.avatarUrl != null
                      ? NetworkImage(profile.avatarUrl!)
                      : null,
                  child: profile.avatarUrl == null
                      ? Text(
                          profile.initials,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: AppColors.darkRed,
                          ),
                        )
                      : null,
                ),
                title: Text(
                  profile.displayName,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: themeProvider.textColor,
                  ),
                ),
                subtitle: Text(
                  auth.email.isNotEmpty ? auth.email : 'Compte anonyme',
                  style: TextStyle(
                    color: themeProvider.secondaryTextColor,
                    fontSize: 12,
                  ),
                ),
                trailing: Icon(Icons.chevron_right, color: themeProvider.secondaryTextColor),
                onTap: () => Navigator.pushNamed(context, '/profile'),
              ),
              Divider(
                height: 1,
                color: isRed ? AppColors.whiteOpacity(0.1) : AppColors.grey200,
                indent: 16,
                endIndent: 16,
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                child: SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: () => _confirmLogout(themeProvider),
                    icon: const Icon(Icons.logout_rounded,
                        color: Colors.white, size: 20),
                    label: const Text(
                      'Se déconnecter',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryRed,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      elevation: 3,
                      shadowColor:
                          AppColors.primaryRed.withValues(alpha: 0.5),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _confirmLogout(ThemeProvider themeProvider) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: themeProvider.isRedTheme ? AppColors.darkRed : AppColors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Deconnexion',
            style: TextStyle(
                color: themeProvider.textColor, fontWeight: FontWeight.bold)),
        content: Text(
          'Voulez-vous vraiment vous deconnecter ?',
          style: TextStyle(color: themeProvider.secondaryTextColor),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryRed,
              foregroundColor: AppColors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Deconnecter'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final profileService = context.read<ProfileService>();
    final authService = context.read<AuthService>();

    try {
      await profileService.clear();
      await authService.signOut();
      if (mounted) Navigator.pushReplacementNamed(context, '/login');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: ${e.toString().split(']').last.trim()}')),
        );
      }
    }
  }
}
