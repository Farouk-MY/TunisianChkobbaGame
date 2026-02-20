// lib/features/game/presentation/widgets/card_dealing_animation.dart

import 'dart:math';
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/audio_service.dart';
import '../../domain/entities/card.dart' as game_card;

/// Premium animated card dealing overlay with multiple phases
class CardDealingAnimation extends StatefulWidget {
  final List<game_card.Card> playerCards;
  final List<game_card.Card> aiCards;
  final List<game_card.Card> tableCards;
  final VoidCallback onComplete;
  final bool isRedTheme;

  const CardDealingAnimation({
    super.key,
    required this.playerCards,
    required this.aiCards,
    required this.tableCards,
    required this.onComplete,
    required this.isRedTheme,
  });

  @override
  State<CardDealingAnimation> createState() => _CardDealingAnimationState();
}

class _CardDealingAnimationState extends State<CardDealingAnimation>
    with TickerProviderStateMixin {
  // Animation controllers for different phases
  late AnimationController _introController;
  late AnimationController _shuffleController;
  late AnimationController _dealController;
  late AnimationController _glowController;
  
  late Animation<double> _titleFade;
  late Animation<double> _titleScale;
  late Animation<double> _deckShake;
  
  late List<_DealingCard> _cards;
  final Random _random = Random();
  final AudioService _audioService = AudioService();
  
  int _animationPhase = 0; // 0=intro, 1=shuffle, 2=deal, 3=complete

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _setupCards();
    _startAnimationSequence();
  }

  void _setupAnimations() {
    // Phase 1: Intro title animation (1.5s)
    _introController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _titleFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _introController, curve: Curves.easeIn),
    );
    
    _titleScale = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _introController, curve: Curves.elasticOut),
    );
    
    // Phase 2: Deck shuffle animation (1s)
    _shuffleController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _deckShake = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _shuffleController, curve: Curves.easeInOut),
    );
    
    // Phase 3: Card dealing animation (3s)
    _dealController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    );
    
    // Continuous glow
    _glowController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
  }

  void _startAnimationSequence() async {
    // Phase 1: Show title
    setState(() => _animationPhase = 0);
    await _introController.forward();
    await Future.delayed(const Duration(milliseconds: 500));
    
    // Phase 2: Shuffle deck
    setState(() => _animationPhase = 1);
    _audioService.playCardDeal(); // Shuffle sound
    await _shuffleController.forward();
    await Future.delayed(const Duration(milliseconds: 300));
    
    // Phase 3: Deal cards
    setState(() => _animationPhase = 2);
    _playDealingSounds();
    await _dealController.forward();
    
    // Complete
    setState(() => _animationPhase = 3);
    await Future.delayed(const Duration(milliseconds: 600));
    widget.onComplete();
  }

  void _playDealingSounds() {
    final totalCards = widget.playerCards.length + widget.aiCards.length + widget.tableCards.length;
    final interval = 2800 ~/ totalCards;
    
    for (int i = 0; i < totalCards; i++) {
      Future.delayed(Duration(milliseconds: 100 + (i * interval)), () {
        if (mounted) {
          _audioService.playCardDeal();
        }
      });
    }
  }

  void _setupCards() {
    _cards = [];
    int delay = 0;

    // Table cards first
    for (var i = 0; i < widget.tableCards.length; i++) {
      _cards.add(_DealingCard(
        card: widget.tableCards[i],
        destination: _CardDestination.table,
        index: i,
        delay: delay / (_cards.length + widget.playerCards.length + widget.aiCards.length + widget.tableCards.length).clamp(1, 20),
      ));
      delay++;
    }

    // Player cards
    for (var i = 0; i < widget.playerCards.length; i++) {
      _cards.add(_DealingCard(
        card: widget.playerCards[i],
        destination: _CardDestination.player,
        index: i,
        delay: delay / (_cards.length + widget.playerCards.length + widget.aiCards.length).clamp(1, 20),
      ));
      delay++;
    }

    // AI cards
    for (var i = 0; i < widget.aiCards.length; i++) {
      _cards.add(_DealingCard(
        card: widget.aiCards[i],
        destination: _CardDestination.ai,
        index: i,
        delay: delay / (_cards.length + widget.aiCards.length).clamp(1, 20),
      ));
      delay++;
    }
    
    // Recalculate delays properly
    final total = _cards.length;
    for (int i = 0; i < _cards.length; i++) {
      _cards[i] = _DealingCard(
        card: _cards[i].card,
        destination: _cards[i].destination,
        index: _cards[i].index,
        delay: i / total * 0.7,
      );
    }
  }

  @override
  void dispose() {
    _introController.dispose();
    _shuffleController.dispose();
    _dealController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Container(
      decoration: BoxDecoration(
        gradient: widget.isRedTheme
            ? AppColors.primaryGradient
            : AppColors.whiteGradient,
      ),
      child: Stack(
        children: [
          // Animated background particles
          ..._buildParticles(size),
          
          // Phase-specific content
          if (_animationPhase <= 1) _buildIntroPhase(size),
          if (_animationPhase >= 1) _buildDeckPhase(size),
          if (_animationPhase >= 2) ..._cards.map((c) => _buildAnimatedCard(c, size)),
          
          // Ready text at the end
          if (_animationPhase == 3) _buildReadyText(size),
        ],
      ),
    );
  }

  List<Widget> _buildParticles(Size size) {
    return List.generate(20, (i) {
      final x = _random.nextDouble() * size.width;
      final y = _random.nextDouble() * size.height;
      final particleSize = 2.0 + _random.nextDouble() * 4;
      
      return AnimatedBuilder(
        animation: _glowController,
        builder: (context, child) {
          return Positioned(
            left: x,
            top: y + (_glowController.value * 20 - 10),
            child: Opacity(
              opacity: 0.3 + _glowController.value * 0.4,
              child: Container(
                width: particleSize,
                height: particleSize,
                decoration: BoxDecoration(
                  color: AppColors.gold,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.goldOpacity(0.5),
                      blurRadius: 8,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    });
  }

  Widget _buildIntroPhase(Size size) {
    return AnimatedBuilder(
      animation: _introController,
      builder: (context, child) {
        return Positioned(
          top: size.height * 0.35,
          left: 0,
          right: 0,
          child: Opacity(
            opacity: _titleFade.value * (_animationPhase == 0 ? 1 : (1 - _shuffleController.value)),
            child: Transform.scale(
              scale: _titleScale.value,
              child: Column(
                children: [
                  // Logo/Icon
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppColors.gold, const Color(0xFFE8B946)],
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.goldOpacity(0.5),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Text(
                        '🃏',
                        style: TextStyle(fontSize: 40),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Title
                  Text(
                    'CHKOBBA',
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.w900,
                      color: widget.isRedTheme ? Colors.white : AppColors.darkRed,
                      letterSpacing: 8,
                      shadows: [
                        Shadow(
                          color: AppColors.goldOpacity(0.5),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Préparation du jeu...',
                    style: TextStyle(
                      fontSize: 16,
                      color: widget.isRedTheme ? Colors.white70 : AppColors.grey600,
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

  Widget _buildDeckPhase(Size size) {
    return AnimatedBuilder(
      animation: Listenable.merge([_shuffleController, _dealController]),
      builder: (context, child) {
        final shakeOffset = sin(_shuffleController.value * pi * 8) * 5;
        final deckOpacity = _animationPhase == 2 ? (1 - _dealController.value).clamp(0.0, 1.0) : 1.0;
        
        return Positioned(
          top: size.height * 0.4,
          left: size.width / 2 - 45 + shakeOffset,
          child: Opacity(
            opacity: deckOpacity,
            child: Transform.rotate(
              angle: shakeOffset * 0.02,
              child: _buildDeck(),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDeck() {
    return Stack(
      children: List.generate(8, (i) {
        return Transform.translate(
          offset: Offset(i * 1.5, -i * 1.5),
          child: Container(
            width: 80,
            height: 110,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF8B1538),
                  AppColors.primaryRed,
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.gold, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(80),
                  blurRadius: 10,
                  offset: const Offset(3, 5),
                ),
              ],
            ),
            child: Stack(
              children: [
                // Pattern
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: CustomPaint(
                      painter: _CardBackPainter(),
                    ),
                  ),
                ),
                // Center emblem
                Center(
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.gold,
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: Text('🎴', style: TextStyle(fontSize: 20)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildAnimatedCard(_DealingCard dealingCard, Size size) {
    Offset getDestination() {
      switch (dealingCard.destination) {
        case _CardDestination.table:
          final spacing = 75.0;
          final totalWidth = widget.tableCards.length * spacing;
          final startX = (size.width - totalWidth) / 2;
          return Offset(startX + dealingCard.index * spacing, size.height * 0.42);
        case _CardDestination.player:
          final spacing = 85.0;
          final totalWidth = widget.playerCards.length * spacing;
          final startX = (size.width - totalWidth) / 2;
          return Offset(startX + dealingCard.index * spacing, size.height * 0.72);
        case _CardDestination.ai:
          final spacing = 55.0;
          final totalWidth = widget.aiCards.length * spacing;
          final startX = (size.width - totalWidth) / 2;
          return Offset(startX + dealingCard.index * spacing, size.height * 0.08);
      }
    }

    final startPos = Offset(size.width / 2 - 40, size.height * 0.4);
    final endPos = getDestination();

    return AnimatedBuilder(
      animation: _dealController,
      builder: (context, child) {
        final cardProgress = ((_dealController.value - dealingCard.delay) / 0.25).clamp(0.0, 1.0);

        if (cardProgress == 0) return const SizedBox.shrink();

        final curvedProgress = Curves.easeOutCubic.transform(cardProgress);
        final currentPos = Offset.lerp(startPos, endPos, curvedProgress)!;
        
        // Card flip animation
        final flipProgress = cardProgress < 0.5 ? 0.0 : (cardProgress - 0.5) * 2;
        final showFace = dealingCard.destination != _CardDestination.ai && flipProgress > 0.5;
        
        // Rotation during flight
        final rotation = (1 - curvedProgress) * 0.3 * (dealingCard.index.isEven ? 1 : -1);
        
        // Scale animation
        final scale = 0.6 + curvedProgress * 0.4;

        return Positioned(
          left: currentPos.dx,
          top: currentPos.dy,
          child: Transform.rotate(
            angle: rotation,
            child: Transform.scale(
              scale: scale,
              child: _buildCardWidget(dealingCard.card, showFace, cardProgress),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCardWidget(game_card.Card card, bool showFace, double progress) {
    return Container(
      width: 75,
      height: 105,
      decoration: BoxDecoration(
        color: showFace ? Colors.white : null,
        gradient: showFace ? null : LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [const Color(0xFF8B1538), AppColors.primaryRed],
        ),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: showFace ? AppColors.grey300 : AppColors.gold,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.goldOpacity(0.4 * progress),
            blurRadius: 15,
            spreadRadius: 2,
          ),
          BoxShadow(
            color: Colors.black.withAlpha(60),
            blurRadius: 8,
            offset: const Offset(2, 4),
          ),
        ],
      ),
      child: showFace
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _getRankDisplay(card.rank),
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: _getCardColor(card),
                    ),
                  ),
                  Text(
                    card.getSuitSymbol(),
                    style: TextStyle(
                      fontSize: 26,
                      color: _getCardColor(card),
                    ),
                  ),
                ],
              ),
            )
          : Stack(
              children: [
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: CustomPaint(painter: _CardBackPainter()),
                  ),
                ),
                Center(
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: AppColors.gold,
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: Text('🎴', style: TextStyle(fontSize: 14)),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildReadyText(Size size) {
    return Positioned(
      top: size.height * 0.5,
      left: 0,
      right: 0,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 400),
        builder: (context, value, child) {
          return Opacity(
            opacity: value,
            child: Transform.scale(
              scale: 0.8 + value * 0.2,
              child: Text(
                'PRÊT !',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  color: AppColors.gold,
                  letterSpacing: 4,
                  shadows: [
                    Shadow(
                      color: AppColors.goldOpacity(0.8),
                      blurRadius: 15,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Color _getCardColor(game_card.Card card) {
    if (card.suit == 'hearts' || card.suit == 'diamonds') {
      return AppColors.primaryRed;
    }
    return const Color(0xFF1A1A2E);
  }

  String _getRankDisplay(int rank) {
    switch (rank) {
      case 1: return 'A';
      case 11: return 'J';
      case 12: return 'Q';
      case 13: return 'K';
      default: return rank.toString();
    }
  }
}

enum _CardDestination { table, player, ai }

class _DealingCard {
  final game_card.Card card;
  final _CardDestination destination;
  final int index;
  final double delay;

  _DealingCard({
    required this.card,
    required this.destination,
    required this.index,
    required this.delay,
  });
}

/// Custom painter for card back pattern
class _CardBackPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withAlpha(20)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    // Diamond pattern
    const spacing = 12.0;
    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        final path = Path()
          ..moveTo(x + spacing / 2, y)
          ..lineTo(x + spacing, y + spacing / 2)
          ..lineTo(x + spacing / 2, y + spacing)
          ..lineTo(x, y + spacing / 2)
          ..close();
        canvas.drawPath(path, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
