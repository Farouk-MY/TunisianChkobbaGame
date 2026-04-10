// lib/features/multiplayer/presentation/pages/online_game_page.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/audio_service.dart';
import '../providers/online_game_provider.dart';
import '../../../game/domain/entities/card.dart' as game_card;
import '../../../game/domain/entities/game_state.dart';
import '../../../game/presentation/widgets/playing_card_widget.dart';
import '../../../game/presentation/widgets/draggable_card_widget.dart';
import '../../../game/presentation/widgets/round_score_board.dart';
import '../../../game/presentation/widgets/chkobba_popup.dart';
import '../../../game/presentation/widgets/card_dealing_animation.dart';

class OnlineGamePage extends StatefulWidget {
  const OnlineGamePage({super.key});

  @override
  State<OnlineGamePage> createState() => _OnlineGamePageState();
}

class _OnlineGamePageState extends State<OnlineGamePage>
    with TickerProviderStateMixin {

  // ── Local state ─────────────────────────────────────────────────────────────
  Set<game_card.Card> _selectedTableCards = {};
  bool _showDealingAnimation = false;
  bool _isRedeal = false;
  int _lastHandCount = 0;

  // Chkobba popup
  bool _showChkobbaPopup = false;
  bool _isChkobbaForMe = false;
  Timer? _chkobbaTimer;

  // Reconnecting banner pulse
  late final AnimationController _pulseCtrl;

  // Score board guard
  bool _showingScoreBoard = false;
  bool _roundEndScheduled = false;
  bool _gameEndScheduled = false;
  bool _redealScheduled = false;

  // Opponent left dialog guard
  bool _showingOpponentLeft = false;

  final AudioService _audioService = AudioService();

  // ── Init ────────────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);

    _audioService.initialize().then((_) => _audioService.startGameMusic());

    // Trigger dealing animation once state arrives
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<OnlineGameProvider>();
      if (provider.gameState != null && mounted) {
        setState(() => _showDealingAnimation = true);
      }
    });
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _chkobbaTimer?.cancel();
    _audioService.startLobbyMusic();
    super.dispose();
  }

  // ── Provider change listener ─────────────────────────────────────────────────

  void _onProviderChange(OnlineGameProvider provider) {
    final gs = provider.gameState;
    if (gs == null) return;

    // Opponent left
    if (provider.opponentForfeited && !_showingOpponentLeft) {
      _showingOpponentLeft = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _showOpponentLeftDialog(provider);
      });
      return;
    }

    // Round end
    if (gs.isRoundOver && !_showingScoreBoard && !_roundEndScheduled) {
      _roundEndScheduled = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _roundEndScheduled = false;
        if (mounted && !_showingScoreBoard) _showRoundEndScore(provider);
      });
    }

    // Game end
    if (gs.isGameOver && !_showingScoreBoard && !_gameEndScheduled) {
      _gameEndScheduled = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _gameEndScheduled = false;
        if (mounted && !_showingScoreBoard) _showGameEndScore(provider);
      });
    }

    // Mid-round redeal: hand went from 0 → cards
    final myHandCount = provider.myPlayer?.hand.length ?? 0;
    if (_lastHandCount == 0 &&
        myHandCount > 0 &&
        !_showDealingAnimation &&
        !_showingScoreBoard &&
        gs.isPlaying &&
        !_redealScheduled) {
      _redealScheduled = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _redealScheduled = false;
        if (mounted && !_showDealingAnimation) {
          setState(() {
            _isRedeal = true;
            _showDealingAnimation = true;
          });
        }
      });
    }
    _lastHandCount = myHandCount;
  }

  // ── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Consumer<OnlineGameProvider>(
      builder: (context, provider, _) {
        // React to changes
        _onProviderChange(provider);

        // Connecting screen
        if (provider.connectionStatus == ConnectionStatus.connecting &&
            !provider.hasGame) {
          return Scaffold(body: _buildConnectingScreen());
        }

        // No game yet
        final gs = provider.gameState;
        if (gs == null) {
          return Scaffold(body: _buildConnectingScreen());
        }

        final myPlayer = provider.myPlayer;
        final opponent = provider.opponentPlayer;
        final isRed = true; // Red theme always

        return Scaffold(
          body: Stack(
            children: [
              // Background
              _buildBackground(),

              // Main layout
              SafeArea(
                child: Column(
                  children: [
                    _buildTopBar(gs, provider, opponent),

                    // Opponent hand (face-down)
                    if (!_showDealingAnimation)
                      _buildOpponentHand(opponent),

                    // Game table (DragTarget)
                    Expanded(
                      child: Row(
                        children: [
                          const SizedBox(width: 8),
                          Expanded(
                            flex: 4,
                            child: _buildGameTable(gs, provider),
                          ),
                          _buildRightPanel(gs, myPlayer),
                        ],
                      ),
                    ),

                    // My hand (DraggableCardWidget)
                    if (!_showDealingAnimation)
                      _buildPlayerHand(gs, provider, myPlayer),
                  ],
                ),
              ),

              // Dealing animation overlay
              if (_showDealingAnimation && myPlayer != null && opponent != null)
                Positioned.fill(
                  child: CardDealingAnimation(
                    playerCards: myPlayer.hand,
                    aiCards: List.generate(
                      opponent.hand.length,
                      (_) => const game_card.Card(rank: 0, suit: 'hidden', id: 'hidden'),
                    ),
                    tableCards: gs.tableCards,
                    onComplete: _onDealingComplete,
                    isRedTheme: isRed,
                    isRedeal: _isRedeal,
                  ),
                ),

              // Chkobba popup
              if (_showChkobbaPopup)
                Positioned.fill(
                  child: GestureDetector(
                    onTap: _dismissChkobbaPopup,
                    child: Container(
                      color: Colors.black54,
                      child: Center(
                        child: ChkobbaPopup(isAI: !_isChkobbaForMe),
                      ),
                    ),
                  ),
                ),

              // Reconnecting banner
              if (provider.connectionStatus == ConnectionStatus.reconnecting)
                _buildReconnectingBanner(),

              // Disconnected overlay
              if (provider.connectionStatus == ConnectionStatus.disconnected &&
                  !provider.opponentForfeited)
                _buildDisconnectedOverlay(provider),
            ],
          ),
        );
      },
    );
  }

  // ── Background ───────────────────────────────────────────────────────────────

  Widget _buildBackground() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF8B1538), Color(0xFF5D0F28), Color(0xFF3D0A1A)],
        ),
      ),
    );
  }

  // ── Dealing animation callbacks ──────────────────────────────────────────────

  void _onDealingComplete() {
    setState(() {
      _showDealingAnimation = false;
      _isRedeal = false;
    });
  }

  // ── Top Bar ──────────────────────────────────────────────────────────────────

  Widget _buildTopBar(GameState gs, OnlineGameProvider provider, dynamic opponent) {
    final isMyTurn = provider.isMyTurn;

    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Row(
        children: [
          // Exit button
          GestureDetector(
            onTap: _showExitDialog,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(20),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.close, color: Colors.white70, size: 18),
            ),
          ),
          const SizedBox(width: 8),

          // Opponent chip
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black26,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    radius: 13,
                    backgroundColor: AppColors.gold.withAlpha(30),
                    backgroundImage: opponent?.avatarUrl != null
                        ? NetworkImage(opponent!.avatarUrl!) : null,
                    child: opponent?.avatarUrl == null
                        ? const Icon(Icons.person, color: Colors.white70, size: 13)
                        : null,
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      opponent?.name ?? 'Adversaire',
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w700),
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text('🃏${opponent?.hand.length ?? 0}',
                      style: const TextStyle(fontSize: 10, color: Colors.white60)),
                ],
              ),
            ),
          ),

          const SizedBox(width: 8),

          // Score
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.black38,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${provider.myPlayer?.score ?? 0} - ${opponent?.score ?? 0}',
              style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                  color: AppColors.gold),
            ),
          ),

          const SizedBox(width: 8),

          // Turn badge
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              gradient: isMyTurn
                  ? const LinearGradient(
                      colors: [Color(0xFFE85D04), Color(0xFFDC2F02)])
                  : LinearGradient(colors: [
                      Colors.grey.shade700,
                      Colors.grey.shade800
                    ]),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              isMyTurn ? 'TON TOUR' : 'ATTENTE',
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 10),
            ),
          ),
        ],
      ),
    );
  }

  // ── Opponent Hand (face-down, fanned) ────────────────────────────────────────

  Widget _buildOpponentHand(dynamic opponent) {
    final count = opponent?.hand.length ?? 0;
    if (count == 0) return const SizedBox(height: 6);

    return SizedBox(
      height: 72,
      child: Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: List.generate(count, (i) {
            final angle = (i - (count - 1) / 2) * 0.04;
            final yOff = (i - (count - 1) / 2).abs() * 3.0;
            return Transform(
              transform: Matrix4.identity()
                ..rotateZ(angle)
                ..translate(0.0, yOff),
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: Container(
                  width: 44,
                  height: 62,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(7),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Colors.indigo.shade700, Colors.indigo.shade900],
                    ),
                    border: Border.all(color: Colors.white24, width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(80),
                        blurRadius: 4,
                        offset: const Offset(1, 2),
                      )
                    ],
                  ),
                  child: Center(
                    child: Icon(Icons.style,
                        size: 18, color: Colors.white.withAlpha(60)),
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  // ── Game Table (DragTarget) ───────────────────────────────────────────────────

  Widget _buildGameTable(GameState gs, OnlineGameProvider provider) {
    final tableCards = gs.tableCards;
    final isMyTurn = provider.isMyTurn;

    return DragTarget<game_card.Card>(
      onWillAcceptWithDetails: (_) => isMyTurn && !provider.isProcessing,
      onAcceptWithDetails: (details) => _playCard(details.data, provider),
      builder: (context, candidateData, _) {
        final isDragOver = candidateData.isNotEmpty;

        return Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            gradient: const RadialGradient(
              center: Alignment.center,
              radius: 0.8,
              colors: [Color(0xFF1B5E20), Color(0xFF0D3B10)],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDragOver ? AppColors.gold : const Color(0xFF8B4513),
              width: isDragOver ? 3 : 4,
            ),
            boxShadow: [
              BoxShadow(color: Colors.black.withAlpha(100), blurRadius: 15),
              if (isDragOver)
                BoxShadow(
                    color: AppColors.gold.withAlpha(76), blurRadius: 10),
            ],
          ),
          child: Stack(
            children: [
              // Felt pattern
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: CustomPaint(painter: _TablePatternPainter()),
                ),
              ),

              // Cards
              Center(
                child: tableCards.isEmpty
                    ? Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.touch_app,
                              size: 40,
                              color: Colors.white.withAlpha(40)),
                          const SizedBox(height: 4),
                          Text(
                            isDragOver
                                ? 'Déposer pour jouer'
                                : 'Table vide — glissez une carte',
                            style: TextStyle(
                                color: isDragOver
                                    ? AppColors.gold
                                    : Colors.white.withAlpha(80),
                                fontSize: 13),
                          ),
                        ],
                      )
                    : Padding(
                        padding: const EdgeInsets.all(8),
                        child: Wrap(
                          alignment: WrapAlignment.center,
                          spacing: 8,
                          runSpacing: 8,
                          children: tableCards.map((card) {
                            final isSelected =
                                _selectedTableCards.contains(card);
                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  if (_selectedTableCards.contains(card)) {
                                    _selectedTableCards.remove(card);
                                    provider.toggleCardSelection(card);
                                  } else {
                                    _selectedTableCards.add(card);
                                    provider.toggleCardSelection(card);
                                  }
                                });
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 150),
                                transform: Matrix4.identity()
                                  ..translate(0.0, isSelected ? -6.0 : 0.0),
                                child: PlayingCardWidget(
                                  card: card,
                                  isSelectable: true,
                                  isSelected: isSelected,
                                  width: 55,
                                  height: 80,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
              ),

              // Drag-over hint text
              if (isDragOver && tableCards.isNotEmpty)
                Positioned(
                  bottom: 8,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _selectedTableCards.isEmpty
                            ? 'Déposer = jeu sans capture'
                            : 'Déposer = capturer ${_selectedTableCards.length} carte(s)',
                        style:
                            TextStyle(color: AppColors.gold, fontSize: 11),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  // ── Right Panel ───────────────────────────────────────────────────────────────

  Widget _buildRightPanel(GameState gs, dynamic myPlayer) {
    final secs = context.read<OnlineGameProvider>().turnTimeRemaining;
    final capturedCards = myPlayer?.capturedCards ?? [];

    return Container(
      width: 80,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Timer circle
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _timerColor(secs),
              border: Border.all(color: Colors.white24, width: 2),
            ),
            child: Center(
              child: Text(
                '$secs',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Captured cards panel
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.black.withAlpha(60),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.gold.withAlpha(76)),
              ),
              child: Column(
                children: [
                  Text('Prises',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: AppColors.gold.withAlpha(178),
                          fontSize: 9)),
                  Text('${capturedCards.length}',
                      style: TextStyle(
                          color: AppColors.gold,
                          fontSize: 16,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text('⭐ ${myPlayer?.chkobbas ?? 0}',
                      style: const TextStyle(
                          color: Colors.amber,
                          fontSize: 11,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 3),
                  Text('R${gs.roundNumber}',
                      style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 3),
                  Text('🃏${gs.deck.length}',
                      style: const TextStyle(
                          color: Colors.white60, fontSize: 10)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _timerColor(int secs) {
    if (secs <= 10) return const Color(0xFFD32F2F);
    if (secs <= 20) return const Color(0xFFFF9800);
    return const Color(0xFF00897B);
  }

  // ── Player Hand (DraggableCardWidget) ────────────────────────────────────────

  Widget _buildPlayerHand(
      GameState gs, OnlineGameProvider provider, dynamic myPlayer) {
    final isMyTurn = provider.isMyTurn;
    final hand = (myPlayer?.hand ?? <game_card.Card>[]) as List<game_card.Card>;

    return Container(
      height: 110,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.black.withAlpha(0), Colors.black.withAlpha(100)],
        ),
      ),
      child: Center(
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: hand.asMap().entries.map<Widget>((entry) {
              final i = entry.key;
              final card = entry.value;
              final total = hand.length;
              final angle = (i - (total - 1) / 2) * 0.04;
              final yOffset = (i - (total - 1) / 2).abs() * 3.0;

              return Transform(
                transform: Matrix4.identity()
                  ..rotateZ(angle)
                  ..translate(0.0, yOffset),
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: DraggableCardWidget(
                    card: card,
                    isEnabled: isMyTurn,
                    width: 60,
                    height: 88,
                    onTap: isMyTurn
                        ? () => _playCard(card, provider)
                        : null,
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  // ── Play Card Logic ───────────────────────────────────────────────────────────

  void _playCard(game_card.Card card, OnlineGameProvider provider) {
    if (!provider.isMyTurn || provider.isProcessing) return;

    final gs = provider.gameState;
    if (gs == null) return;

    final options = provider.getPossibleCaptures(card);
    final tableWasNotEmpty = gs.tableCards.isNotEmpty;
    final willCapture = options != null && options.canCapture;

    if (willCapture) {
      _audioService.playCardCapture();
      // If no table cards manually selected, auto-select best capture
      if (_selectedTableCards.isEmpty) {
        if (options.singleMatches.isNotEmpty) {
          provider.toggleCardSelection(options.singleMatches.first);
        } else if (options.sumCombinations.isNotEmpty) {
          for (final tc in options.sumCombinations.first) {
            provider.toggleCardSelection(tc);
          }
        }
      }
    } else {
      _audioService.playCardPlace();
    }

    provider.playCard(card);

    // Check chkobba: table was non-empty, now empty after capture
    if (tableWasNotEmpty && willCapture) {
      final newGs = provider.gameState;
      if (newGs != null && newGs.tableCards.isEmpty) {
        _showChkobbaCelebration(forMe: true);
      }
    }

    setState(() => _selectedTableCards.clear());
  }

  // ── Chkobba ───────────────────────────────────────────────────────────────────

  void _showChkobbaCelebration({required bool forMe}) {
    _audioService.playChkobba();
    _chkobbaTimer?.cancel();
    setState(() {
      _showChkobbaPopup = true;
      _isChkobbaForMe = forMe;
    });
    _chkobbaTimer = Timer(const Duration(milliseconds: 2500), _dismissChkobbaPopup);
  }

  void _dismissChkobbaPopup() {
    _chkobbaTimer?.cancel();
    if (mounted && _showChkobbaPopup) {
      setState(() => _showChkobbaPopup = false);
    }
  }

  // ── Score Boards ──────────────────────────────────────────────────────────────

  void _showRoundEndScore(OnlineGameProvider provider) {
    _showingScoreBoard = true;
    _audioService.playRoundEnd();
    final gs = provider.gameState!;
    final myPlayer = provider.myPlayer!;
    final opponent = provider.opponentPlayer!;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => RoundScoreBoard(
        humanPlayer: myPlayer,
        aiPlayer: opponent,
        isGameEnd: false,
        isHumanWinner: myPlayer.score >= opponent.score,
        onContinue: () {
          Navigator.pop(context);
          _showingScoreBoard = false;
          if (provider.isHost) {
            // Host starts next round and triggers redeal animation
            provider.startNextRound();
            setState(() {
              _isRedeal = true;
              _showDealingAnimation = true;
            });
          }
          // Guest waits for host state broadcast → redeal detected in _onProviderChange
        },
      ),
    );
  }

  void _showGameEndScore(OnlineGameProvider provider) {
    _showingScoreBoard = true;
    final gs = provider.gameState!;
    final myPlayer = provider.myPlayer!;
    final opponent = provider.opponentPlayer!;
    final iWon = gs.winnerPlayerId == provider.myId;

    if (iWon) {
      _audioService.playVictory();
    } else {
      _audioService.playDefeat();
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => RoundScoreBoard(
        humanPlayer: myPlayer,
        aiPlayer: opponent,
        isGameEnd: true,
        isHumanWinner: iWon,
        onPlayAgain: () {
          Navigator.pop(context);
          _showingScoreBoard = false;
          provider.requestRematch();
        },
        onHome: () {
          _audioService.startLobbyMusic();
          Navigator.pop(context);
          provider.leaveGame();
          Navigator.of(context).pop();
        },
      ),
    );
  }

  // ── Opponent Left ─────────────────────────────────────────────────────────────

  void _showOpponentLeftDialog(OnlineGameProvider provider) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.exit_to_app, color: Colors.red, size: 28),
            SizedBox(width: 10),
            Text('Adversaire parti',
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18)),
          ],
        ),
        content: const Text(
          'Votre adversaire a quitté la partie. Vous remportez la victoire !',
          style: TextStyle(color: Colors.white70, fontSize: 14),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.gold,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10))),
            onPressed: () {
              _audioService.startLobbyMusic();
              Navigator.pop(context);
              provider.leaveGame();
              Navigator.of(context).pop();
            },
            child: const Text('Retour au lobby',
                style: TextStyle(
                    color: Colors.black, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // ── Dialogs ───────────────────────────────────────────────────────────────────

  void _showExitDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Quitter la partie?',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: const Text('Vous perdrez la partie en cours.',
            style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler',
                style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade700,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10))),
            onPressed: () {
              Navigator.pop(context);
              _audioService.startLobbyMusic();
              context.read<OnlineGameProvider>().forfeit();
              Navigator.of(context).pop();
            },
            child:
                const Text('Quitter', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ── Connection Overlays ───────────────────────────────────────────────────────

  Widget _buildConnectingScreen() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF8B1538), Color(0xFF3D0A1A)],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: AppColors.gold),
            const SizedBox(height: 20),
            const Text('Connexion en cours…',
                style: TextStyle(color: Colors.white70, fontSize: 16)),
          ],
        ),
      ),
    );
  }

  Widget _buildReconnectingBanner() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: AnimatedBuilder(
        animation: _pulseCtrl,
        builder: (_, __) => Container(
          color: Colors.orange
              .withAlpha((140 + (_pulseCtrl.value * 60)).toInt()),
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: const Text(
            'Reconnexion…',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  Widget _buildDisconnectedOverlay(OnlineGameProvider provider) {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withAlpha(180),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.wifi_off, color: Colors.red, size: 48),
              const SizedBox(height: 12),
              const Text('Connexion perdue',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  provider.leaveGame();
                  Navigator.of(context).pop();
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('Quitter'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Table pattern painter ─────────────────────────────────────────────────────

class _TablePatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.shortestSide * 0.35;
    final paint = Paint()
      ..color = Colors.white.withAlpha(8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    for (var i = 1; i <= 3; i++) {
      canvas.drawCircle(center, radius * i * 0.4, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
