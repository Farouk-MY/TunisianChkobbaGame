// lib/features/game/presentation/widgets/game_setup_dialog.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/game_constants.dart';
import '../../../../core/services/audio_service.dart';
import '../../../../core/theme/theme_provider.dart';

/// Game configuration result from the setup dialog.
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

// ─────────────────────────────────────────────────────────────────────────────
// Public entry point
// ─────────────────────────────────────────────────────────────────────────────
class GameSetupDialog extends StatelessWidget {
  const GameSetupDialog({super.key});

  static Future<GameConfig?> show(BuildContext context) {
    return showModalBottomSheet<GameConfig>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withAlpha(160),
      builder: (_) => const _GameSetupSheet(),
    );
  }

  @override
  Widget build(BuildContext context) => const _GameSetupSheet();
}

// ─────────────────────────────────────────────────────────────────────────────
// Sheet
// ─────────────────────────────────────────────────────────────────────────────
class _GameSetupSheet extends StatefulWidget {
  const _GameSetupSheet();

  @override
  State<_GameSetupSheet> createState() => _GameSetupSheetState();
}

class _GameSetupSheetState extends State<_GameSetupSheet>
    with SingleTickerProviderStateMixin {
  int _score = 21;
  String _difficulty = GameConstants.aiMedium;
  bool _isTeam = false;
  final _nameCtrl = TextEditingController(text: 'Joueur');
  final _audio = AudioService();
  late AnimationController _pulse;

  static const _scores = [11, 21];
  static const _diffs = [
    ('easy',   '🌿', 'Facile'),
    ('medium', '⚔️',  'Moyen'),
    ('hard',   '🔥', 'Pro'),
    ('expert', '👑', 'Expert'),
  ];

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _loadName();
  }

  Future<void> _loadName() async {
    final p = await SharedPreferences.getInstance();
    final v = p.getString('player_name');
    if (v != null && v.isNotEmpty && mounted) {
      setState(() => _nameCtrl.text = v);
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  void _tap() => _audio.playButtonTap();

  Future<void> _start() async {
    _tap();
    final name = _nameCtrl.text.trim().isEmpty ? 'Joueur' : _nameCtrl.text.trim();
    final p = await SharedPreferences.getInstance();
    await p.setString('player_name', name);
    if (!mounted) return;
    Navigator.pop(
      context,
      GameConfig(
        playerCount: _isTeam ? 4 : 2,
        targetScore: _score,
        aiDifficulty: _difficulty,
        playerName: name,
        isTeamMode: _isTeam,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context, listen: false);
    final isRed = theme.isRedTheme;

    final bg      = isRed ? const Color(0xFF0F0710) : Colors.white;
    final card    = isRed ? const Color(0xFF1C0D1A) : const Color(0xFFEAE5E8);
    final accent  = isRed ? AppColors.gold : AppColors.primaryRed;
    final onAcc   = isRed ? const Color(0xFF1A060E) : Colors.white;
    final txt     = isRed ? Colors.white : const Color(0xFF17101A);
    final sub     = isRed ? Colors.white38 : Colors.black38;
    final border  = isRed ? Colors.white.withAlpha(15) : Colors.black.withAlpha(10);

    final bottom = MediaQuery.of(context).padding.bottom;

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(color: accent.withAlpha(30), width: 1),
      ),
      padding: EdgeInsets.fromLTRB(16, 0, 16, bottom + 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [

          // ── Handle ──────────────────────────────────────────────────────
          const SizedBox(height: 8),
          Container(
            width: 36, height: 3,
            decoration: BoxDecoration(
              color: accent.withAlpha(70),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(height: 8),

          // ── HEADER ROW ──────────────────────────────────────────────────
          Row(
            children: [
              AnimatedBuilder(
                animation: _pulse,
                builder: (_, __) => Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    gradient: AppColors.goldGradient,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.gold.withAlpha(
                            (60 + (_pulse.value * 70)).toInt()),
                        blurRadius: 12,
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Text('🎴', style: TextStyle(fontSize: 20)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('NOUVELLE PARTIE',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          color: txt,
                          letterSpacing: 0.8,
                        )),
                    Text('Chkobba Tunisienne',
                        style: TextStyle(fontSize: 10, color: sub)),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 28, height: 28,
                  decoration: BoxDecoration(
                    color: accent.withAlpha(12),
                    shape: BoxShape.circle,
                    border: Border.all(color: accent.withAlpha(35)),
                  ),
                  child: Icon(Icons.close_rounded, size: 14, color: sub),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),
          Divider(height: 1, color: border),
          const SizedBox(height: 8),

          // ── BODY: 2-column layout ────────────────────────────────────────
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [

                // ── LEFT COLUMN ──────────────────────────────────────────
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      // Mode de jeu
                      _label('⚔️  MODE', accent),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Expanded(
                            child: _ModeChip(
                              emoji: '🤺',
                              title: '1 VS 1',
                              subLabel: 'vs IA',
                              selected: !_isTeam,
                              comingSoon: false,
                              accent: accent,
                              onAcc: onAcc,
                              card: card,
                              txt: txt,
                              subColor: sub,
                              onTap: () {
                                _tap();
                                setState(() => _isTeam = false);
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _ModeChip(
                              emoji: '👥',
                              title: '2 VS 2',
                              subLabel: 'Équipe',
                              selected: _isTeam,
                              comingSoon: true,
                              accent: accent,
                              onAcc: onAcc,
                              card: card,
                              txt: txt,
                              subColor: sub,
                              onTap: null,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      // Joueur
                      _label('👤  JOUEUR', accent),
                      const SizedBox(height: 6),
                      Container(
                        height: 44,
                        decoration: BoxDecoration(
                          color: card,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: border, width: 1),
                        ),
                        child: TextField(
                          controller: _nameCtrl,
                          style: TextStyle(
                            color: txt,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                          maxLength: 14,
                          cursorColor: accent,
                          decoration: InputDecoration(
                            counterText: '',
                            hintText: 'Votre nom',
                            hintStyle: TextStyle(
                              color: txt.withAlpha(50),
                              fontSize: 13,
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 12,
                            ),
                            prefixIcon: Icon(
                              Icons.person_outline_rounded,
                              color: accent,
                              size: 18,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 12),

                // ── RIGHT COLUMN ─────────────────────────────────────────
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      // Score
                      _label('🏆  SCORE CIBLE', accent),
                      const SizedBox(height: 6),
                      Row(
                        children: _scores.map((s) {
                          final sel = _score == s;
                          return Expanded(
                            child: Padding(
                              padding: EdgeInsets.only(
                                  right: s == _scores.last ? 0 : 7),
                              child: GestureDetector(
                                onTap: () {
                                  _tap();
                                  setState(() => _score = s);
                                },
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 160),
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 8),
                                  decoration: BoxDecoration(
                                    color: sel ? accent : card,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: sel
                                          ? accent
                                          : accent.withAlpha(20),
                                      width: 1.5,
                                    ),
                                    boxShadow: sel
                                        ? [
                                            BoxShadow(
                                              color: accent.withAlpha(60),
                                              blurRadius: 8,
                                            )
                                          ]
                                        : null,
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        '$s',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w900,
                                          color: sel ? onAcc : txt,
                                        ),
                                      ),
                                      Text(
                                        'pts',
                                        style: TextStyle(
                                          fontSize: 8,
                                          color: sel
                                              ? onAcc.withAlpha(150)
                                              : sub,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),

                      const SizedBox(height: 12),

                      // Difficulté — 2×2 grid
                      _label('🧠  DIFFICULTÉ IA', accent),
                      const SizedBox(height: 6),
                      Column(
                        children: [
                          // Row 1: Facile + Moyen
                          Row(
                            children: [0, 1].map((i) {
                              final d = _diffs[i];
                              final sel = _difficulty == d.$1;
                              return Expanded(
                                child: Padding(
                                  padding:
                                      EdgeInsets.only(right: i == 0 ? 7 : 0),
                                  child: _DiffTile(
                                    emoji: d.$2,
                                    label: d.$3,
                                    selected: sel,
                                    accent: accent,
                                    onAcc: onAcc,
                                    card: card,
                                    txt: txt,
                                    sub: sub,
                                    onTap: () {
                                      _tap();
                                      setState(() => _difficulty = d.$1);
                                    },
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 7),
                          // Row 2: Pro + Expert
                          Row(
                            children: [2, 3].map((i) {
                              final d = _diffs[i];
                              final sel = _difficulty == d.$1;
                              return Expanded(
                                child: Padding(
                                  padding:
                                      EdgeInsets.only(right: i == 2 ? 7 : 0),
                                  child: _DiffTile(
                                    emoji: d.$2,
                                    label: d.$3,
                                    selected: sel,
                                    accent: accent,
                                    onAcc: onAcc,
                                    card: card,
                                    txt: txt,
                                    sub: sub,
                                    onTap: () {
                                      _tap();
                                      setState(() => _difficulty = d.$1);
                                    },
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // ── JOUER button ────────────────────────────────────────────────
          AnimatedBuilder(
            animation: _pulse,
            builder: (_, __) => GestureDetector(
              onTap: _start,
              child: Container(
                width: double.infinity,
                height: 48,
                decoration: BoxDecoration(
                  gradient: isRed
                      ? AppColors.goldGradient
                      : AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: accent.withAlpha(
                          (80 + (_pulse.value * 90)).toInt()),
                      blurRadius: 18,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.play_arrow_rounded, color: onAcc, size: 22),
                    const SizedBox(width: 8),
                    Text(
                      'JOUER',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: onAcc,
                        letterSpacing: 3,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _label(String text, Color accent) => Text(
        text,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w800,
          color: accent,
          letterSpacing: 1.4,
        ),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// _ModeChip
// ─────────────────────────────────────────────────────────────────────────────
class _ModeChip extends StatelessWidget {
  final String emoji;
  final String title;
  final String subLabel;
  final bool selected;
  final bool comingSoon;
  final Color accent;
  final Color onAcc;
  final Color card;
  final Color txt;
  final Color subColor;
  final VoidCallback? onTap;

  const _ModeChip({
    required this.emoji,
    required this.title,
    required this.subLabel,
    required this.selected,
    required this.comingSoon,
    required this.accent,
    required this.onAcc,
    required this.card,
    required this.txt,
    required this.subColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          gradient: selected
              ? LinearGradient(
                  colors: [accent, Color.lerp(accent, Colors.black, 0.18)!],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: selected ? null : card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? accent : accent.withAlpha(30),
            width: selected ? 2 : 1,
          ),
          boxShadow: selected
              ? [BoxShadow(color: accent.withAlpha(70), blurRadius: 14)]
              : null,
        ),
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  emoji,
                  style: TextStyle(
                    fontSize: 26,
                    color: comingSoon ? txt.withAlpha(45) : null,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    color: selected
                        ? onAcc
                        : comingSoon
                            ? txt.withAlpha(70)
                            : txt,
                    letterSpacing: 0.6,
                  ),
                ),
                Text(
                  subLabel,
                  style: TextStyle(
                    fontSize: 9,
                    color: selected ? onAcc.withAlpha(170) : subColor,
                  ),
                ),
              ],
            ),
            if (comingSoon)
              Positioned(
                top: -8,
                right: -8,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    gradient: AppColors.goldGradient,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.gold.withAlpha(90),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: Text(
                    'BIENTÔT',
                    style: TextStyle(
                      fontSize: 7,
                      fontWeight: FontWeight.w900,
                      color: AppColors.darkRed,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _DiffTile — horizontal row diff chip for 2×2 grid
// ─────────────────────────────────────────────────────────────────────────────
class _DiffTile extends StatelessWidget {
  final String emoji;
  final String label;
  final bool selected;
  final Color accent;
  final Color onAcc;
  final Color card;
  final Color txt;
  final Color sub;
  final VoidCallback onTap;

  const _DiffTile({
    required this.emoji,
    required this.label,
    required this.selected,
    required this.accent,
    required this.onAcc,
    required this.card,
    required this.txt,
    required this.sub,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        decoration: BoxDecoration(
          color: selected ? accent : card,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? accent : accent.withAlpha(20),
            width: 1.5,
          ),
          boxShadow: selected
              ? [BoxShadow(color: accent.withAlpha(60), blurRadius: 8)]
              : null,
        ),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: selected ? onAcc : sub,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (selected)
              Container(
                width: 5,
                height: 5,
                decoration: BoxDecoration(
                  color: onAcc.withAlpha(180),
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }
}