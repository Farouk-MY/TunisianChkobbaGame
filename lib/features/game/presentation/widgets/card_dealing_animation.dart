// lib/features/game/presentation/widgets/card_dealing_animation.dart

import 'dart:math';
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/audio_service.dart';
import '../../domain/entities/card.dart' as game_card;

/// Clean card-dealing animation.
///
/// Shows a deck of cards in the center of the screen, then deals them
/// one at a time to their destinations (table, player hand, AI hand).
/// Each card flies with a smooth arc, slight rotation, and scales up.
/// Player/table cards flip to reveal their face; AI cards stay face-down.
///
/// Used both for the initial deal and mid-game re-deals when hands are
/// empty.
class CardDealingAnimation extends StatefulWidget {
  final List<game_card.Card> playerCards;
  final List<game_card.Card> aiCards;
  final List<game_card.Card> tableCards;
  final VoidCallback onComplete;
  final bool isRedTheme;

  /// If true, this is a mid-round re-deal (shorter, no title).
  final bool isRedeal;

  const CardDealingAnimation({
    super.key,
    required this.playerCards,
    required this.aiCards,
    required this.tableCards,
    required this.onComplete,
    required this.isRedTheme,
    this.isRedeal = false,
  });

  @override
  State<CardDealingAnimation> createState() => _CardDealingAnimationState();
}

class _CardDealingAnimationState extends State<CardDealingAnimation>
    with TickerProviderStateMixin {
  late AnimationController _dealController;
  late List<_DealingCard> _cards;
  final AudioService _audioService = AudioService();

  // Deterministic "random" offsets seeded once to avoid jitter on rebuild.
  late List<double> _rotationSeeds;

  @override
  void initState() {
    super.initState();

    // Build the list of cards to deal.
    _setupCards();

    // Seed rotation offsets.
    final rng = Random(42);
    _rotationSeeds =
        List.generate(_cards.length, (_) => (rng.nextDouble() - 0.5) * 0.4);

    // Total duration depends on card count:
    //   initial deal (~10 cards) → 2.5 s
    //   re-deal   (~6 cards)    → 1.8 s
    final durationMs = widget.isRedeal ? 1800 : 2500;
    _dealController = AnimationController(
      duration: Duration(milliseconds: durationMs),
      vsync: this,
    );

    // Schedule one sound effect per card.
    _scheduleSounds();

    // Start the animation and call back when done.
    _dealController.forward().then((_) {
      // Short pause so the player can see all cards in place.
      Future.delayed(const Duration(milliseconds: 400), () {
        if (mounted) widget.onComplete();
      });
    });
  }

  // ─── Card setup ──────────────────────────────────────────────────

  void _setupCards() {
    _cards = [];
    int order = 0;

    // Deal order: table → player → AI (like a real dealer).
    for (var i = 0; i < widget.tableCards.length; i++) {
      _cards.add(_DealingCard(
        card: widget.tableCards[i],
        destination: _Dest.table,
        index: i,
        totalInGroup: widget.tableCards.length,
        order: order++,
      ));
    }
    for (var i = 0; i < widget.playerCards.length; i++) {
      _cards.add(_DealingCard(
        card: widget.playerCards[i],
        destination: _Dest.player,
        index: i,
        totalInGroup: widget.playerCards.length,
        order: order++,
      ));
    }
    for (var i = 0; i < widget.aiCards.length; i++) {
      _cards.add(_DealingCard(
        card: widget.aiCards[i],
        destination: _Dest.ai,
        index: i,
        totalInGroup: widget.aiCards.length,
        order: order++,
      ));
    }

    // Compute normalised delay for each card (0.0 – 0.65).
    final total = _cards.length.clamp(1, 100);
    for (int i = 0; i < _cards.length; i++) {
      _cards[i] = _cards[i].withDelay(i / total * 0.65);
    }
  }

  // ─── Sounds ──────────────────────────────────────────────────────

  void _scheduleSounds() {
    final totalMs = _dealController.duration!.inMilliseconds;
    // Play one sound per group (player, AI, table) — not per card
    final groupStarts = <double>{};
    for (final card in _cards) {
      // Round delay to nearest 0.1 to group nearby cards
      final group = (card.delay * 10).roundToDouble() / 10;
      groupStarts.add(group);
    }
    for (final delay in groupStarts) {
      final ms = (delay * totalMs).round() + 50;
      Future.delayed(Duration(milliseconds: ms), () {
        if (mounted) _audioService.playCardDeal();
      });
    }
  }

  // ─── Lifecycle ───────────────────────────────────────────────────

  @override
  void dispose() {
    _dealController.dispose();
    super.dispose();
  }

  // ─── Build ───────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final deckCenter = Offset(size.width / 2 - 35, size.height * 0.38);

    return Container(
      decoration: BoxDecoration(
        gradient: widget.isRedTheme
            ? AppColors.primaryGradient
            : AppColors.whiteGradient,
      ),
      child: AnimatedBuilder(
        animation: _dealController,
        builder: (context, _) {
          return Stack(
            children: [
              // ── Deck (shrinks as cards are dealt) ──
              _buildDeck(deckCenter),

              // ── Title text ──
              if (!widget.isRedeal) _buildTitle(size),

              // ── Animated cards ──
              for (int i = 0; i < _cards.length; i++)
                _buildFlyingCard(_cards[i], i, deckCenter, size),
            ],
          );
        },
      ),
    );
  }

  // ─── Deck widget ─────────────────────────────────────────────────

  Widget _buildDeck(Offset center) {
    // How many cards are still "in" the deck?
    int remaining = 0;
    for (final c in _cards) {
      final t = ((_dealController.value - c.delay) / 0.30).clamp(0.0, 1.0);
      if (t < 0.05) remaining++;
    }
    remaining = remaining.clamp(0, 6);

    return Positioned(
      left: center.dx,
      top: center.dy,
      child: Opacity(
        opacity: remaining == 0 ? 0.0 : 1.0,
        child: Stack(
          children: List.generate(remaining, (i) {
            return Transform.translate(
              offset: Offset(i * 1.2, -i * 1.2),
              child: _cardBack(70, 100),
            );
          }),
        ),
      ),
    );
  }

  // ─── Title ───────────────────────────────────────────────────────

  Widget _buildTitle(Size size) {
    // Fade out as dealing starts.
    final opacity = (1.0 - _dealController.value * 3).clamp(0.0, 1.0);
    if (opacity <= 0) return const SizedBox.shrink();

    return Positioned(
      top: size.height * 0.20,
      left: 0,
      right: 0,
      child: Opacity(
        opacity: opacity,
        child: Text(
          'Distribution...',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
            color: widget.isRedTheme ? Colors.white : AppColors.grey800,
          ),
        ),
      ),
    );
  }

  // ─── Flying card ─────────────────────────────────────────────────

  Widget _buildFlyingCard(
      _DealingCard card, int idx, Offset deckCenter, Size size) {
    // Normalised progress for this specific card (0 → 1).
    final raw =
        ((_dealController.value - card.delay) / 0.30).clamp(0.0, 1.0);
    if (raw <= 0) return const SizedBox.shrink();

    final t = Curves.easeOutCubic.transform(raw);

    // Destination.
    final dest = _destination(card, size);
    final pos = Offset.lerp(deckCenter, dest, t)!;

    // Slight rotation that settles to 0.
    final angle = _rotationSeeds[idx] * (1 - t);

    // Scale: start small, grow to full.
    final scale = 0.65 + t * 0.35;

    // Flip: reveal face after 50 % of this card's flight (AI stays hidden).
    final showFace =
        card.destination != _Dest.ai && raw > 0.50;

    // Glow intensity peaks mid-flight.
    final glowAlpha = (sin(raw * pi) * 0.5).clamp(0.0, 1.0);

    return Positioned(
      left: pos.dx,
      top: pos.dy,
      child: Transform.rotate(
        angle: angle,
        child: Transform.scale(
          scale: scale,
          child: showFace
              ? _cardFace(card.card, glowAlpha)
              : _cardBack(70, 100, glowAlpha: glowAlpha),
        ),
      ),
    );
  }

  // ─── Destination helpers ─────────────────────────────────────────

  Offset _destination(_DealingCard c, Size size) {
    switch (c.destination) {
      case _Dest.table:
        final spacing = 72.0;
        final totalW = c.totalInGroup * spacing;
        final startX = (size.width - totalW) / 2;
        return Offset(startX + c.index * spacing, size.height * 0.40);
      case _Dest.player:
        final spacing = 82.0;
        final totalW = c.totalInGroup * spacing;
        final startX = (size.width - totalW) / 2;
        return Offset(startX + c.index * spacing, size.height * 0.72);
      case _Dest.ai:
        final spacing = 52.0;
        final totalW = c.totalInGroup * spacing;
        final startX = (size.width - totalW) / 2;
        return Offset(startX + c.index * spacing, size.height * 0.06);
    }
  }

  // ─── Card widgets ────────────────────────────────────────────────

  Widget _cardFace(game_card.Card card, double glowAlpha) {
    final color = (card.suit == 'hearts' || card.suit == 'diamonds')
        ? AppColors.primaryRed
        : const Color(0xFF1A1A2E);

    return Container(
      width: 70,
      height: 100,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.grey300, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.goldOpacity(0.4 * glowAlpha),
            blurRadius: 14,
            spreadRadius: 1,
          ),
          BoxShadow(
            color: Colors.black.withAlpha(50),
            blurRadius: 6,
            offset: const Offset(2, 3),
          ),
        ],
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _rankDisplay(card.rank),
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              card.getSuitSymbol(),
              style: TextStyle(fontSize: 22, color: color),
            ),
          ],
        ),
      ),
    );
  }

  Widget _cardBack(double w, double h, {double glowAlpha = 0}) {
    return Container(
      width: w,
      height: h,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF8B1538), Color(0xFF5D0F28)],
        ),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.gold, width: 1.5),
        boxShadow: [
          if (glowAlpha > 0)
            BoxShadow(
              color: AppColors.goldOpacity(0.35 * glowAlpha),
              blurRadius: 12,
              spreadRadius: 1,
            ),
          BoxShadow(
            color: Colors.black.withAlpha(50),
            blurRadius: 6,
            offset: const Offset(2, 3),
          ),
        ],
      ),
      child: Center(
        child: Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: AppColors.gold,
            shape: BoxShape.circle,
          ),
          child: const Center(
            child: Text('🎴', style: TextStyle(fontSize: 14)),
          ),
        ),
      ),
    );
  }

  // ─── Helpers ─────────────────────────────────────────────────────

  static String _rankDisplay(int rank) {
    switch (rank) {
      case 1:  return 'A';
      case 11: return 'J';
      case 12: return 'Q';
      case 13: return 'K';
      default: return rank.toString();
    }
  }
}

// ─── Data classes ────────────────────────────────────────────────────

enum _Dest { table, player, ai }

class _DealingCard {
  final game_card.Card card;
  final _Dest destination;
  final int index;
  final int totalInGroup;
  final int order;
  final double delay;

  const _DealingCard({
    required this.card,
    required this.destination,
    required this.index,
    required this.totalInGroup,
    required this.order,
    this.delay = 0,
  });

  _DealingCard withDelay(double d) => _DealingCard(
        card: card,
        destination: destination,
        index: index,
        totalInGroup: totalInGroup,
        order: order,
        delay: d,
      );
}
