// lib/features/profile/presentation/pages/profile_page.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/services/profile_service.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade;
  late Animation<Offset> _slide;

  bool _isEditingName = false;
  late TextEditingController _nameCtrl;
  bool _isSavingName = false;
  bool _isLoggingOut = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        duration: const Duration(milliseconds: 700), vsync: this)
      ..forward();
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide =
        Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _nameCtrl = TextEditingController(
          text: context.read<ProfileService>().displayName);
    });
    _nameCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  // ─── Logout ──────────────────────────────────────────────────────────────

  Future<void> _logout() async {
    final theme = context.read<ThemeProvider>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor:
            theme.isRedTheme ? AppColors.darkRed : AppColors.white,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Déconnexion',
            style: TextStyle(
                color: theme.textColor, fontWeight: FontWeight.bold)),
        content: Text('Voulez-vous vraiment vous déconnecter ?',
            style: TextStyle(color: theme.secondaryTextColor)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Annuler',
                style: TextStyle(color: theme.secondaryTextColor)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryRed,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Déconnecter'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final profileService = context.read<ProfileService>();
    final authService = context.read<AuthService>();

    setState(() => _isLoggingOut = true);
    try {
      await profileService.clear();
      await authService.signOut();
      if (mounted) Navigator.pushReplacementNamed(context, '/login');
    } catch (e) {
      if (mounted) {
        setState(() => _isLoggingOut = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text('Erreur: ${e.toString().split(']').last.trim()}')),
        );
      }
    }
  }

  // ─── Save name ───────────────────────────────────────────────────────────

  Future<void> _saveName() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;
    setState(() => _isSavingName = true);
    final auth = context.read<AuthService>();
    final profile = context.read<ProfileService>();
    if (auth.userId != null) {
      await profile.updateDisplayName(auth.userId!, name);
    }
    if (mounted) setState(() => _isEditingName = _isSavingName = false);
  }

  // ─── Build ───────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Consumer2<ThemeProvider, ProfileService>(
      builder: (context, theme, profile, _) {
        return Scaffold(
          body: Container(
            decoration: BoxDecoration(
              gradient: theme.isRedTheme
                  ? AppColors.primaryGradient
                  : AppColors.whiteGradient,
            ),
            child: SafeArea(
              child: FadeTransition(
                opacity: _fade,
                child: SlideTransition(
                  position: _slide,
                  child: CustomScrollView(
                    slivers: [
                      _buildHeroSliver(theme, profile),
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                        sliver: SliverList(
                          delegate: SliverChildListDelegate([
                            const SizedBox(height: 20),
                            _buildStatsRow(theme, profile),
                            const SizedBox(height: 20),
                            _buildNameCard(theme, profile),
                            const SizedBox(height: 16),
                            _buildGenderCard(theme, profile),
                            const SizedBox(height: 24),
                            _buildLogoutButton(theme),
                            const SizedBox(height: 16),
                          ]),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // ─── Hero sliver (avatar + name + ELO) ─────────────────────────────────

  Widget _buildHeroSliver(ThemeProvider theme, ProfileService profile) {
    return SliverToBoxAdapter(
      child: Stack(
        children: [
          // Decorative gradient banner
          Container(
            height: 200,
            decoration: BoxDecoration(
              gradient: theme.isRedTheme
                  ? LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.primaryRed.withAlpha(180),
                        AppColors.darkRed,
                      ],
                    )
                  : LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.primaryRed,
                        AppColors.darkRed,
                      ],
                    ),
            ),
            child: Stack(
              children: [
                // Subtle pattern circles
                Positioned(
                  top: -30,
                  right: -30,
                  child: Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withAlpha(15),
                    ),
                  ),
                ),
                Positioned(
                  bottom: -20,
                  left: -20,
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withAlpha(10),
                    ),
                  ),
                ),
                // Back button
                Positioned(
                  top: 8,
                  left: 4,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back_ios,
                        color: Colors.white, size: 22),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                // "Mon Profil" label top center
                Positioned(
                  top: 16,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Text(
                      'Mon Profil',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Avatar centered on the fold
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Column(
              children: [
                // Avatar with shadow
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(60),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: CircleAvatar(
                    radius: 52,
                    backgroundColor: AppColors.gold,
                    backgroundImage: profile.avatarUrl != null
                        ? NetworkImage(profile.avatarUrl!)
                        : null,
                    child: profile.avatarUrl == null
                        ? Text(
                            profile.initials,
                            style: const TextStyle(
                              fontSize: 34,
                              fontWeight: FontWeight.bold,
                              color: AppColors.darkRed,
                            ),
                          )
                        : null,
                  ),
                ),
                const SizedBox(height: 12),

                // Name + ELO
                Text(
                  profile.displayName,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: theme.textColor,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                  decoration: BoxDecoration(
                    gradient: AppColors.goldGradient,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '⚡ ${profile.eloRating} ELO  ·  Niveau ${profile.level}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.darkRed,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Stats Row ────────────────────────────────────────────────────────────

  Widget _buildStatsRow(ThemeProvider theme, ProfileService profile) {
    final stats = [
      _StatItem('Parties', '${profile.gamesPlayed}', Icons.sports_esports,
          AppColors.blueSection),
      _StatItem('Victoires', '${profile.gamesWon}', Icons.emoji_events,
          AppColors.gold),
      _StatItem('Chkobbas', '${profile.totalChkobbas}', Icons.auto_awesome,
          AppColors.primaryRed),
      _StatItem(
          'Win %',
          '${profile.winRate.toStringAsFixed(0)}%',
          Icons.trending_up,
          AppColors.success),
    ];

    return Row(
      children: stats.map((s) {
        return Expanded(
          child: Container(
            margin: EdgeInsets.only(
              right: s == stats.last ? 0 : 8,
            ),
            padding:
                const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
            decoration: BoxDecoration(
              color: theme.isRedTheme
                  ? AppColors.whiteOpacity(0.08)
                  : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: theme.borderColor),
              boxShadow: theme.isRedTheme
                  ? null
                  : [
                      BoxShadow(
                        color: AppColors.blackOpacity(0.06),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      )
                    ],
            ),
            child: Column(
              children: [
                Icon(s.icon, color: s.color, size: 20),
                const SizedBox(height: 6),
                Text(
                  s.value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: theme.textColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  s.label,
                  style: TextStyle(
                    fontSize: 9,
                    color: theme.secondaryTextColor,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  // ─── Name Card ────────────────────────────────────────────────────────────

  Widget _buildNameCard(ThemeProvider theme, ProfileService profile) {
    return _buildCard(
      theme,
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color:
                  AppColors.primaryRed.withAlpha(20),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.person, color: AppColors.primaryRed,
                size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: _isEditingName
                ? TextField(
                    controller: _nameCtrl,
                    autofocus: true,
                    style: TextStyle(
                        fontSize: 16,
                        color: theme.textColor,
                        fontWeight: FontWeight.w600),
                    decoration: InputDecoration(
                      hintText: 'Entrez votre pseudo',
                      hintStyle:
                          TextStyle(color: theme.secondaryTextColor),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    onSubmitted: (_) => _saveName(),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Pseudo',
                          style: TextStyle(
                              fontSize: 11,
                              color: theme.secondaryTextColor)),
                      const SizedBox(height: 2),
                      Text(
                        profile.displayName,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: theme.textColor,
                        ),
                      ),
                    ],
                  ),
          ),
          if (_isEditingName)
            _isSavingName
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(
                            AppColors.primaryRed)),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.close,
                            color: Colors.grey, size: 20),
                        onPressed: () =>
                            setState(() => _isEditingName = false),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.check_circle,
                            color: AppColors.success, size: 22),
                        onPressed: _saveName,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  )
          else
            GestureDetector(
              onTap: () {
                _nameCtrl.text = profile.displayName;
                setState(() => _isEditingName = true);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primaryRed.withAlpha(18),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Modifier',
                  style: TextStyle(
                    color: AppColors.primaryRed,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ─── Gender Card ─────────────────────────────────────────────────────────

  Widget _buildGenderCard(ThemeProvider theme, ProfileService profile) {
    final auth = context.watch<AuthService>();
    return _buildCard(
      theme,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.purpleSection.withAlpha(25),
                  borderRadius: BorderRadius.circular(12),
                ),
                child:
                    Icon(Icons.record_voice_over,
                        color: AppColors.purpleSection, size: 20),
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Voix du jeu',
                      style: TextStyle(
                          fontSize: 11,
                          color: theme.secondaryTextColor)),
                  const SizedBox(height: 2),
                  Text('Choisissez la voix de l\'annonceur',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: theme.textColor)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _genderOption(
                  theme: theme,
                  label: 'Masculin',
                  icon: '♂',
                  color: AppColors.blueSection,
                  selected: profile.gender == 'male',
                  onTap: () {
                    if (auth.userId != null) {
                      profile.updateGender(auth.userId!, 'male');
                    }
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _genderOption(
                  theme: theme,
                  label: 'Féminin',
                  icon: '♀',
                  color: AppColors.purpleSection,
                  selected: profile.gender == 'female',
                  onTap: () {
                    if (auth.userId != null) {
                      profile.updateGender(auth.userId!, 'female');
                    }
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _genderOption({
    required ThemeProvider theme,
    required String label,
    required String icon,
    required Color color,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? color.withAlpha(30) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? color : theme.borderColor,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(icon,
                style: TextStyle(
                    fontSize: 18,
                    color: selected ? color : theme.secondaryTextColor)),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontWeight:
                    selected ? FontWeight.bold : FontWeight.normal,
                color: selected ? color : theme.secondaryTextColor,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Logout Button ───────────────────────────────────────────────────────

  Widget _buildLogoutButton(ThemeProvider theme) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton.icon(
        onPressed: _isLoggingOut ? null : _logout,
        icon: _isLoggingOut
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white),
              )
            : const Icon(Icons.logout_rounded, color: Colors.white, size: 20),
        label: Text(
          _isLoggingOut ? 'Déconnexion...' : 'Se déconnecter',
          style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryRed,
          disabledBackgroundColor: AppColors.primaryRed.withAlpha(120),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 3,
          shadowColor: AppColors.primaryRed.withAlpha(80),
        ),
      ),
    );
  }

  // ─── Helper: card container ───────────────────────────────────────────────

  Widget _buildCard(ThemeProvider theme, {required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color:
            theme.isRedTheme ? AppColors.whiteOpacity(0.08) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: theme.borderColor),
        boxShadow: theme.isRedTheme
            ? null
            : [
                BoxShadow(
                  color: AppColors.blackOpacity(0.06),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: child,
    );
  }
}

class _StatItem {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _StatItem(this.label, this.value, this.icon, this.color);
}
