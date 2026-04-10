// lib/features/multiplayer/presentation/pages/lobby_page.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../../../core/services/audio_service.dart';
import '../../../../core/services/auth_service.dart';
import '../../data/services/matchmaking_service.dart';
import '../providers/online_game_provider.dart';

/// Online multiplayer lobby with 3 modes: Quick Match, Create, Join.
class LobbyPage extends StatefulWidget {
  const LobbyPage({super.key});

  @override
  State<LobbyPage> createState() => _LobbyPageState();
}

class _LobbyPageState extends State<LobbyPage>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _slideController;
  final AudioService _audioService = AudioService();
  final _codeController = TextEditingController();

  // State
  _LobbyMode _mode = _LobbyMode.menu;
  bool _isLoading = false;
  String? _errorMessage;
  int _targetScore = 21;
  MatchData? _createdMatch;
  StreamSubscription<MatchData>? _matchSub;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _slideController.dispose();
    _codeController.dispose();
    _matchSub?.cancel();
    MatchmakingService.instance.stopListening();
    super.dispose();
  }

  // ─── Actions ─────────────────────────────────────────────────────────────

  Future<void> _quickMatch() async {
    setState(() { _isLoading = true; _errorMessage = null; });
    try {
      final match = await MatchmakingService.instance.quickMatch(
        targetScore: _targetScore,
      );

      if (!mounted) return;

      if (match.isPlaying && match.guestId != null) {
        // Joined an existing match — go to waiting room then game
        _navigateToWaitingRoom(match, isHost: false);
      } else {
        // Created a new match — wait for opponent
        _createdMatch = match;
        setState(() { _mode = _LobbyMode.waitingForOpponent; _isLoading = false; });
        _listenForGuestJoin(match.id);
      }
    } catch (e) {
      if (mounted) setState(() { _errorMessage = e.toString(); _isLoading = false; });
    }
  }

  Future<void> _createMatch() async {
    setState(() { _isLoading = true; _errorMessage = null; });
    try {
      final match = await MatchmakingService.instance.createMatch(
        targetScore: _targetScore,
      );

      if (!mounted) return;
      _createdMatch = match;
      setState(() { _mode = _LobbyMode.waitingForOpponent; _isLoading = false; });
      _listenForGuestJoin(match.id);
    } catch (e) {
      if (mounted) setState(() { _errorMessage = e.toString(); _isLoading = false; });
    }
  }

  Future<void> _joinByCode() async {
    final code = _codeController.text.trim();
    if (code.length != 6) {
      setState(() { _errorMessage = 'Le code doit faire 6 caractères'; });
      return;
    }

    setState(() { _isLoading = true; _errorMessage = null; });
    try {
      final match = await MatchmakingService.instance.joinByCode(code);
      if (!mounted) return;
      _navigateToWaitingRoom(match, isHost: false);
    } catch (e) {
      if (mounted) setState(() { _errorMessage = _parseError(e.toString()); _isLoading = false; });
    }
  }

  void _listenForGuestJoin(String matchId) {
    _matchSub?.cancel();
    _matchSub = MatchmakingService.instance.listenToMatch(matchId).listen((updated) {
      if (updated.isPlaying && updated.guestId != null) {
        _matchSub?.cancel();
        MatchmakingService.instance.stopListening();
        if (mounted) _navigateToWaitingRoom(updated, isHost: true);
      }
    });
  }

  Future<void> _cancelMatch() async {
    _matchSub?.cancel();
    MatchmakingService.instance.stopListening();
    if (_createdMatch != null) {
      await MatchmakingService.instance.cancelMatch(_createdMatch!.id);
      _createdMatch = null;
    }
    if (mounted) setState(() { _mode = _LobbyMode.menu; });
  }

  void _navigateToWaitingRoom(MatchData match, {required bool isHost}) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => _WaitingRoomInline(
          matchData: match,
          isHost: isHost,
        ),
        transitionsBuilder: (_, anim, __, child) {
          return FadeTransition(opacity: anim, child: child);
        },
      ),
    );
  }

  String _parseError(String error) {
    if (error.contains('not found')) return 'Partie introuvable ou déjà commencée';
    if (error.contains('own match')) return 'Vous ne pouvez pas rejoindre votre propre partie';
    if (error.contains('Not authenticated')) return 'Connectez-vous d\'abord';
    return 'Erreur: $error';
  }

  // ─── Build ───────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context);
    final isRed = theme.isRedTheme;
    final size = MediaQuery.of(context).size;

    final bg = isRed ? const Color(0xFF0A0608) : Colors.grey.shade50;
    final accent = isRed ? AppColors.primaryRed : Colors.blue.shade700;
    final gold = AppColors.gold;
    final txt = isRed ? Colors.white : Colors.grey.shade900;
    final surface = isRed ? Colors.white.withAlpha(12) : Colors.white.withAlpha(220);
    final subtleGold = gold.withAlpha(30);

    return Scaffold(
      backgroundColor: bg,
      body: Stack(
        children: [
          // Background
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isRed
                    ? [const Color(0xFF1A0A14), const Color(0xFF0A0608), const Color(0xFF140A10)]
                    : [Colors.grey.shade100, Colors.white, Colors.grey.shade100],
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          _audioService.playButtonTap();
                          if (_mode != _LobbyMode.menu) {
                            _cancelMatch();
                          } else {
                            Navigator.pop(context);
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: surface,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: accent.withAlpha(30)),
                          ),
                          child: Icon(Icons.arrow_back_rounded, color: txt, size: 20),
                        ),
                      ),
                      const SizedBox(width: 16),
                      ShaderMask(
                        shaderCallback: (bounds) => AppColors.goldGradient.createShader(bounds),
                        child: const Text(
                          'MULTIJOUEUR EN LIGNE',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: 2,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Content
                Expanded(
                  child: _mode == _LobbyMode.waitingForOpponent
                      ? _buildWaitingView(gold, txt, surface, subtleGold, isRed)
                      : _buildMenuView(gold, txt, surface, subtleGold, accent, isRed, size),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Main Menu View ──────────────────────────────────────────────────────

  Widget _buildMenuView(
    Color gold, Color txt, Color surface, Color subtleGold,
    Color accent, bool isRed, Size size,
  ) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Error message
            if (_errorMessage != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withAlpha(30),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.withAlpha(60)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red, size: 18),
                    const SizedBox(width: 8),
                    Flexible(child: Text(_errorMessage!, style: const TextStyle(color: Colors.red, fontSize: 12))),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Target score selector
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Score cible:', style: TextStyle(color: txt.withAlpha(140), fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(width: 12),
                for (final score in [11, 16, 21])
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: GestureDetector(
                      onTap: () => setState(() => _targetScore = score),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: _targetScore == score ? gold.withAlpha(40) : surface,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: _targetScore == score ? gold : subtleGold,
                            width: _targetScore == score ? 2 : 1,
                          ),
                        ),
                        child: Text(
                          '$score',
                          style: TextStyle(
                            color: _targetScore == score ? gold : txt.withAlpha(120),
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 28),

            // Three mode buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildModeCard(
                  icon: Icons.flash_on_rounded,
                  title: 'MATCH RAPIDE',
                  subtitle: 'Trouver un adversaire',
                  gold: gold, txt: txt, surface: surface,
                  isRed: isRed,
                  onTap: _isLoading ? null : _quickMatch,
                ),
                const SizedBox(width: 16),
                _buildModeCard(
                  icon: Icons.add_circle_rounded,
                  title: 'CRÉER',
                  subtitle: 'Générer un code',
                  gold: gold, txt: txt, surface: surface,
                  isRed: isRed,
                  onTap: _isLoading ? null : _createMatch,
                ),
                const SizedBox(width: 16),
                _buildModeCard(
                  icon: Icons.login_rounded,
                  title: 'REJOINDRE',
                  subtitle: 'Entrer un code',
                  gold: gold, txt: txt, surface: surface,
                  isRed: isRed,
                  onTap: _isLoading ? null : () => setState(() => _mode = _LobbyMode.joinByCode),
                ),
              ],
            ),

            // Join by code input (shown when in joinByCode mode)
            if (_mode == _LobbyMode.joinByCode) ...[
              const SizedBox(height: 24),
              Container(
                width: 340,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: subtleGold),
                  boxShadow: [BoxShadow(color: gold.withAlpha(15), blurRadius: 20)],
                ),
                child: Column(
                  children: [
                    Text('Entrez le code à 6 caractères',
                      style: TextStyle(color: txt.withAlpha(160), fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _codeController,
                      maxLength: 6,
                      textCapitalization: TextCapitalization.characters,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: gold,
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 8,
                      ),
                      decoration: InputDecoration(
                        counterText: '',
                        hintText: '------',
                        hintStyle: TextStyle(color: txt.withAlpha(40), letterSpacing: 8),
                        filled: true,
                        fillColor: isRed ? Colors.white.withAlpha(8) : Colors.grey.shade100,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: subtleGold),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: subtleGold),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: gold, width: 2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() { _mode = _LobbyMode.menu; _codeController.clear(); }),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: Colors.red.withAlpha(20),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.red.withAlpha(40)),
                              ),
                              child: const Center(child: Text('Annuler', style: TextStyle(color: Colors.red, fontWeight: FontWeight.w700, fontSize: 13))),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: GestureDetector(
                            onTap: _isLoading ? null : _joinByCode,
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                gradient: AppColors.goldGradient,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Center(
                                child: _isLoading
                                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                    : const Text('REJOINDRE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13)),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],

            if (_isLoading && _mode == _LobbyMode.menu) ...[
              const SizedBox(height: 24),
              SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: gold, strokeWidth: 2)),
            ],
          ],
        ),
      ),
    );
  }

  // ─── Waiting for Opponent View ─────────────────────────────────────────

  Widget _buildWaitingView(Color gold, Color txt, Color surface, Color subtleGold, bool isRed) {
    return Center(
      child: AnimatedBuilder(
        animation: _pulseController,
        builder: (context, child) {
          final glow = 0.3 + _pulseController.value * 0.3;
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Match code display
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                decoration: BoxDecoration(
                  color: surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: gold.withAlpha((glow * 255).toInt()), width: 2),
                  boxShadow: [BoxShadow(color: gold.withAlpha((glow * 60).toInt()), blurRadius: 25)],
                ),
                child: Column(
                  children: [
                    Text('CODE DE LA PARTIE',
                      style: TextStyle(color: txt.withAlpha(120), fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 2),
                    ),
                    const SizedBox(height: 10),
                    GestureDetector(
                      onTap: () {
                        if (_createdMatch != null) {
                          Clipboard.setData(ClipboardData(text: _createdMatch!.matchCode));
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Code copié: ${_createdMatch!.matchCode}'), duration: const Duration(seconds: 2)),
                          );
                        }
                      },
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _createdMatch?.matchCode ?? '------',
                            style: TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.w900,
                              color: gold,
                              letterSpacing: 10,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Icon(Icons.copy_rounded, color: gold.withAlpha(140), size: 20),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // Pulsing waiting text
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 20, height: 20,
                    child: CircularProgressIndicator(color: gold, strokeWidth: 2),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'En attente d\'un adversaire...',
                    style: TextStyle(color: txt.withAlpha(160), fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                ],
              ),

              const SizedBox(height: 8),
              Text(
                'Partagez le code avec votre ami',
                style: TextStyle(color: txt.withAlpha(100), fontSize: 12),
              ),

              const SizedBox(height: 28),

              // Cancel button
              GestureDetector(
                onTap: _cancelMatch,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.red.withAlpha(20),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.red.withAlpha(50)),
                  ),
                  child: const Text('ANNULER', style: TextStyle(color: Colors.red, fontWeight: FontWeight.w800, fontSize: 13, letterSpacing: 1)),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ─── Mode Card Widget ────────────────────────────────────────────────────

  Widget _buildModeCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color gold,
    required Color txt,
    required Color surface,
    required bool isRed,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: () {
        _audioService.playButtonTap();
        onTap?.call();
      },
      child: Container(
        width: 150,
        padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 16),
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: gold.withAlpha(25)),
          boxShadow: [BoxShadow(color: gold.withAlpha(10), blurRadius: 15)],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ShaderMask(
              shaderCallback: (bounds) => AppColors.goldGradient.createShader(bounds),
              child: Icon(icon, size: 32, color: Colors.white),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                color: gold,
                fontWeight: FontWeight.w900,
                fontSize: 12,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                color: txt.withAlpha(120),
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Lobby Mode Enum ─────────────────────────────────────────────────────────

enum _LobbyMode { menu, joinByCode, waitingForOpponent }

// ─── Inline Waiting Room (navigated to after match is ready) ─────────────────

class _WaitingRoomInline extends StatefulWidget {
  final MatchData matchData;
  final bool isHost;

  const _WaitingRoomInline({required this.matchData, required this.isHost});

  @override
  State<_WaitingRoomInline> createState() => _WaitingRoomInlineState();
}

class _WaitingRoomInlineState extends State<_WaitingRoomInline>
    with TickerProviderStateMixin {
  late AnimationController _countdownController;
  int _countdown = 3;
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    _countdownController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
    _startCountdown();
  }

  void _startCountdown() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() { _countdown--; });
      if (_countdown <= 0) {
        timer.cancel();
        _startGame();
      }
    });
  }

  Future<void> _startGame() async {
    if (!mounted) return;

    final provider = Provider.of<OnlineGameProvider>(context, listen: false);
    final auth = Provider.of<AuthService>(context, listen: false);

    if (widget.isHost) {
      await provider.hostStartGame(
        match: widget.matchData,
        playerName: auth.displayName,
        playerAvatar: auth.avatarUrl,
      );
    } else {
      await provider.guestJoinGame(match: widget.matchData);
    }

    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/online-game');
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _countdownController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context);
    final isRed = theme.isRedTheme;
    final gold = AppColors.gold;
    final txt = isRed ? Colors.white : Colors.grey.shade900;
    final surface = isRed ? Colors.white.withAlpha(12) : Colors.white.withAlpha(220);

    return Scaffold(
      backgroundColor: isRed ? const Color(0xFF0A0608) : Colors.grey.shade50,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isRed
                ? [const Color(0xFF1A0A14), const Color(0xFF0A0608)]
                : [Colors.grey.shade100, Colors.white],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Player cards row
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Host card
                  _buildPlayerCard(
                    name: widget.matchData.hostName,
                    avatar: widget.matchData.hostAvatar,
                    gold: gold, txt: txt, surface: surface,
                    isRed: isRed,
                  ),

                  // VS
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 28),
                    child: Column(
                      children: [
                        ShaderMask(
                          shaderCallback: (bounds) => AppColors.goldGradient.createShader(bounds),
                          child: const Text(
                            'VS',
                            style: TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: 4,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Score cible: ${widget.matchData.targetScore}',
                          style: TextStyle(color: txt.withAlpha(100), fontSize: 11),
                        ),
                      ],
                    ),
                  ),

                  // Guest card
                  _buildPlayerCard(
                    name: widget.matchData.guestName ?? 'Adversaire',
                    avatar: widget.matchData.guestAvatar,
                    gold: gold, txt: txt, surface: surface,
                    isRed: isRed,
                  ),
                ],
              ),

              const SizedBox(height: 40),

              // Countdown
              Container(
                width: 80, height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppColors.goldGradient,
                  boxShadow: [BoxShadow(color: gold.withAlpha(80), blurRadius: 25)],
                ),
                child: Center(
                  child: Text(
                    _countdown > 0 ? '$_countdown' : '🎮',
                    style: const TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),
              Text(
                _countdown > 0 ? 'La partie commence dans...' : 'C\'est parti!',
                style: TextStyle(color: txt.withAlpha(140), fontSize: 14, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlayerCard({
    required String name,
    String? avatar,
    required Color gold,
    required Color txt,
    required Color surface,
    required bool isRed,
  }) {
    return Container(
      width: 160,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: gold.withAlpha(30)),
        boxShadow: [BoxShadow(color: gold.withAlpha(15), blurRadius: 15)],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: gold.withAlpha(30),
            backgroundImage: avatar != null ? NetworkImage(avatar) : null,
            child: avatar == null
                ? Icon(Icons.person_rounded, color: gold, size: 28)
                : null,
          ),
          const SizedBox(height: 12),
          Text(
            name,
            style: TextStyle(
              color: txt,
              fontWeight: FontWeight.w800,
              fontSize: 14,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
