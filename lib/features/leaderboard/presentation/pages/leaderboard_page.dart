// lib/features/leaderboard/presentation/pages/leaderboard_page.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/services/supabase_service.dart';

class LeaderboardPage extends StatefulWidget {
  const LeaderboardPage({super.key});

  @override
  State<LeaderboardPage> createState() => _LeaderboardPageState();
}

class _LeaderboardPageState extends State<LeaderboardPage> with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> _entries = [];
  bool _loading = true;
  String? _error;
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _loadLeaderboard();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadLeaderboard() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await SupabaseService.client
          .from('profiles')
          .select('id, display_name, avatar_url, elo_rating, games_played, games_won, total_chkobbas')
          .order('elo_rating', ascending: false)
          .limit(50);

      setState(() {
        _entries = List<Map<String, dynamic>>.from(data as List);
        _loading = false;
      });
      _controller.forward();
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        final currentUserId = context.watch<AuthService>().userId;
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
                    child: _loading
                        ? const Center(child: CircularProgressIndicator(color: AppColors.gold))
                        : _error != null
                            ? _buildError(themeProvider)
                            : _buildList(themeProvider, currentUserId),
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back_ios, color: themeProvider.textColor),
            onPressed: () => Navigator.pop(context),
          ),
          Expanded(
            child: Text(
              '🏆 Classement',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: themeProvider.textColor,
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.refresh, color: themeProvider.accentColor),
            onPressed: _loadLeaderboard,
            tooltip: 'Actualiser',
          ),
        ],
      ),
    );
  }

  Widget _buildError(ThemeProvider themeProvider) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.wifi_off, color: AppColors.grey400, size: 60),
          const SizedBox(height: 16),
          Text(
            'Impossible de charger le classement.',
            style: TextStyle(color: themeProvider.secondaryTextColor),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _loadLeaderboard,
            icon: const Icon(Icons.refresh),
            label: const Text('Réessayer'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryRed,
              foregroundColor: AppColors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildList(ThemeProvider themeProvider, String? currentUserId) {
    return RefreshIndicator(
      onRefresh: _loadLeaderboard,
      color: AppColors.gold,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: _entries.length,
        itemBuilder: (context, index) {
          final entry = _entries[index];
          final rank = index + 1;
          final isMe = entry['id'] == currentUserId;
          return _buildLeaderboardTile(themeProvider, entry, rank, isMe, index);
        },
      ),
    );
  }

  Widget _buildLeaderboardTile(
    ThemeProvider themeProvider,
    Map<String, dynamic> entry,
    int rank,
    bool isMe,
    int index,
  ) {
    final elo = entry['elo_rating'] as int? ?? 1000;
    final name = entry['display_name'] as String? ?? 'Joueur';
    final avatarUrl = entry['avatar_url'] as String?;
    final gamesPlayed = entry['games_played'] as int? ?? 0;
    final gamesWon = entry['games_won'] as int? ?? 0;
    final winRate = gamesPlayed == 0 ? 0 : (gamesWon / gamesPlayed * 100).toInt();

    Color rankColor;
    IconData? rankIcon;
    if (rank == 1) {
      rankColor = AppColors.gold;
      rankIcon = Icons.emoji_events;
    } else if (rank == 2) {
      rankColor = const Color(0xFFC0C0C0);
      rankIcon = Icons.emoji_events;
    } else if (rank == 3) {
      rankColor = const Color(0xFFCD7F32);
      rankIcon = Icons.emoji_events;
    } else {
      rankColor = themeProvider.secondaryTextColor;
      rankIcon = null;
    }

    final initials = name.length >= 2 ? name.substring(0, 2).toUpperCase() : name.toUpperCase();

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final delay = index * 0.04;
        final t = ((_controller.value - delay) / (1 - delay)).clamp(0.0, 1.0);
        return Transform.translate(
          offset: Offset(50 * (1 - t), 0),
          child: Opacity(opacity: t, child: child),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          gradient: isMe
              ? LinearGradient(colors: [AppColors.gold.withOpacity(0.2), AppColors.gold.withOpacity(0.05)])
              : LinearGradient(
                  colors: themeProvider.isRedTheme
                      ? [AppColors.whiteOpacity(0.12), AppColors.whiteOpacity(0.05)]
                      : [AppColors.white, AppColors.grey50],
                ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isMe ? AppColors.gold : themeProvider.borderColor,
            width: isMe ? 1.5 : 1,
          ),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          leading: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 32,
                child: rankIcon != null
                    ? Icon(rankIcon, color: rankColor, size: 22)
                    : Text(
                        '#$rank',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: rankColor,
                          fontSize: 14,
                        ),
                      ),
              ),
              const SizedBox(width: 8),
              CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.gold,
                backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
                child: avatarUrl == null
                    ? Text(
                        initials,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.darkRed,
                        ),
                      )
                    : null,
              ),
            ],
          ),
          title: Row(
            children: [
              Text(
                name,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: themeProvider.textColor,
                  fontSize: 14,
                ),
              ),
              if (isMe) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.gold,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'Moi',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: AppColors.darkRed,
                    ),
                  ),
                ),
              ],
            ],
          ),
          subtitle: Text(
            'Win rate: $winRate% · $gamesPlayed parties',
            style: TextStyle(
              color: themeProvider.secondaryTextColor,
              fontSize: 11,
            ),
          ),
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.gold.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.gold.withOpacity(0.4)),
            ),
            child: Text(
              '⚡ $elo',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.gold,
                fontSize: 13,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
