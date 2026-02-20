// lib/features/game/presentation/pages/game_board_page.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/game_constants.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../../../core/services/audio_service.dart';
import '../providers/game_provider.dart';
import '../../domain/entities/card.dart' as game_card;
import '../widgets/game_setup_dialog.dart';
import '../widgets/playing_card_widget.dart';
import '../widgets/draggable_card_widget.dart';
import '../widgets/round_score_board.dart';
import '../widgets/chkobba_popup.dart';
import '../widgets/card_dealing_animation.dart';

class GameBoardPage extends StatefulWidget {
  final GameConfig? config;
  
  const GameBoardPage({super.key, this.config});

  @override
  State<GameBoardPage> createState() => _GameBoardPageState();
}

class _GameBoardPageState extends State<GameBoardPage>
    with TickerProviderStateMixin {
  Timer? _turnTimer;
  int _remainingSeconds = GameConstants.turnTimeout;
  Set<game_card.Card> _selectedTableCards = {};
  bool _showingScoreBoard = false;
  bool _showDealingAnimation = true;
  int _lastRoundNumber = 0;
  final AudioService _audioService = AudioService();

  @override
  void initState() {
    super.initState();
    _initAudioAndGame();
  }

  void _initAudioAndGame() async {
    await _audioService.initialize();
    _audioService.startBackgroundMusic();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeGame();
    });
  }

  void _initializeGame() {
    final gameProvider = context.read<GameProvider>();
    final config = widget.config;
    
    gameProvider.startQuickGameVsAI(
      playerName: config?.playerName ?? 'Vous',
      aiDifficulty: config?.aiDifficulty ?? GameConstants.aiMedium,
      targetScore: config?.targetScore ?? GameConstants.defaultTargetScore,
    );
    
    // Show dealing animation
    setState(() => _showDealingAnimation = true);
  }

  void _onDealingComplete() {
    setState(() => _showDealingAnimation = false);
    _startTurnTimer();
  }

  void _startTurnTimer() {
    _turnTimer?.cancel();
    _remainingSeconds = GameConstants.turnTimeout;
    
    final gameProvider = context.read<GameProvider>();
    if (gameProvider.gameState?.isHumanTurn == true) {
      _turnTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (mounted) {
          setState(() {
            _remainingSeconds--;
            
            // Play warning sound at 10 seconds
            if (_remainingSeconds == 10) {
              _audioService.playTimerWarning();
            }
            
            if (_remainingSeconds <= 0) {
              timer.cancel();
              _autoPlayCard();
            }
          });
        }
      });
    }
  }

  void _autoPlayCard() {
    final gameProvider = context.read<GameProvider>();
    final gameState = gameProvider.gameState;
    
    if (gameState != null && gameState.isHumanTurn) {
      final hand = gameState.currentPlayer.hand;
      if (hand.isNotEmpty) {
        _playCard(hand.first, gameProvider);
      }
    }
  }

  @override
  void dispose() {
    _turnTimer?.cancel();
    _audioService.stopBackgroundMusic();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<ThemeProvider, GameProvider>(
      builder: (context, themeProvider, gameProvider, child) {
        final gameState = gameProvider.gameState;

        if (gameState == null) {
          return _buildLoadingScreen();
        }

        // Check for round end (show score after each round)
        if (gameState.roundNumber > _lastRoundNumber && !_showingScoreBoard) {
          _lastRoundNumber = gameState.roundNumber;
          if (_lastRoundNumber > 1) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _showRoundEndScore(gameProvider);
            });
          }
        }

        // Check for game end
        if (gameState.isGameOver && !_showingScoreBoard) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _showGameEndDialog(gameProvider);
          });
        }

        return Scaffold(
          body: Stack(
            children: [
              // Main game
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xFF8B1538),
                      Color(0xFF5D0F28),
                      Color(0xFF3D0A1A),
                    ],
                  ),
                ),
                child: SafeArea(
                  child: Column(
                    children: [
                      // Top bar
                      _buildTopBar(gameState, gameProvider),
                      
                      // Main game area
                      Expanded(
                        child: Row(
                          children: [
                            const SizedBox(width: 8),
                            
                            // Center - Game table
                            Expanded(
                              flex: 4,
                              child: _buildGameTable(gameState, gameProvider),
                            ),
                            
                            // Right side - Capture area & timer
                            _buildRightPanel(gameState),
                          ],
                        ),
                      ),
                      
                      // Player hand
                      _buildPlayerHand(gameState, gameProvider),
                    ],
                  ),
                ),
              ),
              
              // Card dealing animation overlay
              if (_showDealingAnimation && gameState != null)
                CardDealingAnimation(
                  playerCards: gameState.players[0].hand,
                  aiCards: gameState.players[1].hand,
                  tableCards: gameState.tableCards,
                  isRedTheme: true,
                  onComplete: _onDealingComplete,
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLoadingScreen() {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF8B1538), Color(0xFF3D0A1A)],
          ),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('🎴', style: TextStyle(fontSize: 60)),
              SizedBox(height: 20),
              Text(
                'Préparation...',
                style: TextStyle(color: Colors.white70, fontSize: 18),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(dynamic gameState, GameProvider gameProvider) {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          // AI info - compact
          _buildCompactPlayerInfo(gameState.players[1], true),
          
          const Spacer(),
          
          // Turn indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              gradient: gameState.isHumanTurn
                  ? const LinearGradient(
                      colors: [Color(0xFFE85D04), Color(0xFFDC2F02)],
                    )
                  : LinearGradient(
                      colors: [Colors.grey.shade600, Colors.grey.shade700],
                    ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              gameState.isHumanTurn ? 'Votre tour' : 'Tour IA',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
          
          const Spacer(),
          
          // Score display - compact
          _buildCompactScoreDisplay(gameState),
          
          const SizedBox(width: 8),
          
          // Close button
          IconButton(
            onPressed: () => _showExitConfirmation(),
            icon: const Icon(Icons.close, color: Colors.white70, size: 22),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactPlayerInfo(dynamic player, bool isAI) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black26,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Timer
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.gold, width: 1.5),
            ),
            child: Center(
              child: Text(
                '${player.isCurrentTurn ? _remainingSeconds : 60}',
                style: TextStyle(color: AppColors.gold, fontSize: 10, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(width: 6),
          Text('IA', style: const TextStyle(color: Colors.white, fontSize: 11)),
          const SizedBox(width: 4),
          const Icon(Icons.smart_toy, color: Colors.white60, size: 12),
          const SizedBox(width: 6),
          Text('🃏${player.handSize} 📥${player.capturedCardCount}', 
            style: const TextStyle(fontSize: 10)),
          const SizedBox(width: 6),
          Text('${player.score}', 
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildCompactScoreDisplay(dynamic gameState) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black38,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('${gameState.players[0].score}',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.gold)),
          const Text(' - ', style: TextStyle(color: Colors.white38, fontSize: 14)),
          Text('${gameState.players[1].score}',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white)),
          const SizedBox(width: 8),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.emoji_events, size: 12, color: AppColors.gold),
              Text('${gameState.targetScore}',
                style: TextStyle(fontSize: 10, color: AppColors.gold)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGameTable(dynamic gameState, GameProvider gameProvider) {
    final tableCards = gameState.tableCards as List<game_card.Card>;
    
    return DragTarget<game_card.Card>(
      onWillAcceptWithDetails: (details) => true,
      onAcceptWithDetails: (details) => _playCard(details.data, gameProvider),
      builder: (context, candidateData, rejectedData) {
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
                BoxShadow(color: AppColors.goldOpacity(0.3), blurRadius: 10),
            ],
          ),
          child: Stack(
            children: [
              // Pattern
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: CustomPaint(painter: _TablePatternPainter()),
                ),
              ),
              
              // Cards
              Center(
                child: tableCards.isEmpty
                    ? _buildEmptyTableHint()
                    : Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 8,
                        runSpacing: 8,
                        children: tableCards.map((card) {
                          final isSelected = _selectedTableCards.contains(card);
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                if (_selectedTableCards.contains(card)) {
                                  _selectedTableCards.remove(card);
                                } else {
                                  _selectedTableCards.add(card);
                                }
                              });
                              gameProvider.toggleCardSelection(card);
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
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyTableHint() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.touch_app, size: 40, color: Colors.white.withAlpha(40)),
        const SizedBox(height: 4),
        Text('Table vide', style: TextStyle(color: Colors.white.withAlpha(80), fontSize: 14)),
      ],
    );
  }

  Widget _buildRightPanel(dynamic gameState) {
    final capturedCards = gameState.players[0].capturedCards as List<game_card.Card>;
    
    return Container(
      width: 80,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Timer
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _getTimerColor(),
              border: Border.all(color: Colors.white24, width: 2),
            ),
            child: Center(
              child: Text(
                '$_remainingSeconds',
                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          
          const SizedBox(height: 12),
          
          // Capture area with mini cards
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.black.withAlpha(60),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.goldOpacity(0.3)),
              ),
              child: Column(
                children: [
                  Text('Vos Cartes', textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.goldOpacity(0.7), fontSize: 9)),
                  Text('${capturedCards.length}',
                    style: TextStyle(color: AppColors.gold, fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  // Show mini captured cards
                  Expanded(
                    child: capturedCards.isEmpty
                        ? Center(child: Icon(Icons.inventory_2, color: Colors.white24, size: 20))
                        : SingleChildScrollView(
                            child: Wrap(
                              spacing: 2,
                              runSpacing: 2,
                              children: capturedCards.take(12).map((card) {
                                return Container(
                                  width: 16,
                                  height: 22,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(2),
                                    border: Border.all(color: Colors.grey.shade400, width: 0.5),
                                  ),
                                  child: Center(
                                    child: Text(
                                      card.getSuitSymbol(),
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: (card.suit == 'hearts' || card.suit == 'diamonds')
                                            ? Colors.red
                                            : Colors.black,
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                  ),
                  if (capturedCards.length > 12)
                    Text('+${capturedCards.length - 12}', 
                      style: const TextStyle(color: Colors.white54, fontSize: 9)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getTimerColor() {
    if (_remainingSeconds <= 10) return const Color(0xFFD32F2F);
    if (_remainingSeconds <= 20) return const Color(0xFFFF9800);
    return const Color(0xFF00897B);
  }

  Widget _buildPlayerHand(dynamic gameState, GameProvider gameProvider) {
    final humanPlayer = gameState.players[0];
    final isMyTurn = humanPlayer.isCurrentTurn;
    
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
            children: humanPlayer.hand.asMap().entries.map<Widget>((entry) {
              final index = entry.key;
              final card = entry.value;
              final totalCards = humanPlayer.hand.length;
              
              final angle = (index - (totalCards - 1) / 2) * 0.04;
              final yOffset = (index - (totalCards - 1) / 2).abs() * 3;
              
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
                    onTap: isMyTurn ? () => _playCard(card, gameProvider) : null,
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  void _playCard(game_card.Card card, GameProvider gameProvider) {
    final options = gameProvider.getPossibleCaptures(card);
    final gameState = gameProvider.gameState;
    final tableWasNotEmpty = gameState?.tableCards.isNotEmpty ?? false;
    final willCapture = options != null && options.canCapture;

    // Play appropriate sound
    if (willCapture) {
      _audioService.playCardCapture();
    } else {
      _audioService.playCardPlace();
    }

    if (willCapture) {
      if (_selectedTableCards.isEmpty) {
        if (options.singleMatches.isNotEmpty) {
          gameProvider.toggleCardSelection(options.singleMatches.first);
        } else if (options.sumCombinations.isNotEmpty) {
          for (final tableCard in options.sumCombinations.first) {
            gameProvider.toggleCardSelection(tableCard);
          }
        }
      }
    }

    gameProvider.playCard(card);
    
    // Check for Chkobba
    final newGameState = gameProvider.gameState;
    if (tableWasNotEmpty && 
        newGameState?.tableCards.isEmpty == true && 
        willCapture) {
      _showChkobbaCelebration();
    }
    
    setState(() => _selectedTableCards.clear());
    _handleAITurn(gameProvider);
  }

  void _showChkobbaCelebration() {
    _audioService.playChkobba();
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black54,
      builder: (context) => const ChkobbaPopup(),
    );
  }

  void _handleAITurn(GameProvider gameProvider) {
    _turnTimer?.cancel();
    
    final gameState = gameProvider.gameState;
    if (gameState != null && gameState.isAITurn && gameState.isPlaying) {
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (mounted) {
          final tableWasNotEmpty = gameProvider.gameState?.tableCards.isNotEmpty ?? false;
          gameProvider.playAITurn().then((_) {
            final newState = gameProvider.gameState;
            if (tableWasNotEmpty && newState?.tableCards.isEmpty == true) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('⭐ IA: Chkobba!'),
                  duration: Duration(seconds: 2),
                  backgroundColor: Color(0xFF6B5B95),
                ),
              );
            }
            
            if (mounted && gameProvider.gameState?.isHumanTurn == true) {
              _startTurnTimer();
            }
          });
        }
      });
    } else if (gameState?.isHumanTurn == true) {
      _startTurnTimer();
    }
  }

  void _showRoundEndScore(GameProvider gameProvider) {
    _showingScoreBoard = true;
    _audioService.playRoundEnd();
    final gameState = gameProvider.gameState!;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => RoundScoreBoard(
        humanPlayer: gameState.players[0],
        aiPlayer: gameState.players[1],
        isGameEnd: false,
        isHumanWinner: false,
        onContinue: () {
          Navigator.pop(context);
          _showingScoreBoard = false;
          // Show dealing animation for new round
          setState(() => _showDealingAnimation = true);
        },
      ),
    );
  }

  void _showExitConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2D1B4E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Quitter?', style: TextStyle(color: Colors.white)),
        content: const Text('Votre progression sera perdue.', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () { Navigator.pop(context); Navigator.pop(context); },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryRed),
            child: const Text('Quitter', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showGameEndDialog(GameProvider gameProvider) {
    _showingScoreBoard = true;
    final gameState = gameProvider.gameState!;
    final isHumanWinner = gameState.players[0].score >= gameState.targetScore;
    
    // Play victory or defeat sound
    if (isHumanWinner) {
      _audioService.playVictory();
    } else {
      _audioService.playDefeat();
    }
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => RoundScoreBoard(
        humanPlayer: gameState.players[0],
        aiPlayer: gameState.players[1],
        isGameEnd: true,
        isHumanWinner: isHumanWinner,
        onPlayAgain: () {
          Navigator.pop(context);
          _showingScoreBoard = false;
          _lastRoundNumber = 0;
          gameProvider.playAgain();
          setState(() => _showDealingAnimation = true);
        },
        onHome: () {
          Navigator.pop(context);
          Navigator.pop(context);
        },
      ),
    );
  }
}

/// Table pattern painter
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