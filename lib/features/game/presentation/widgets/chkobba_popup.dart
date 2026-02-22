// lib/features/game/presentation/widgets/chkobba_popup.dart

import 'dart:math' as math;
import 'package:flutter/material.dart';

/// ═══════════════════════════════════════════════════════════════════
///  CHKOBBA! — Premium celebration popup
/// ═══════════════════════════════════════════════════════════════════
///
/// Dramatic entrance with:
///   ▸ Golden/purple radial glow that expands behind
///   ▸ Confetti particles that explode outward
///   ▸ Bold badge with shimmer sweep across the text
///   ▸ Subtle floating sparkles
///   ▸ Bounce + shake entrance animation
class ChkobbaPopup extends StatefulWidget {
  final bool isAI;

  const ChkobbaPopup({super.key, this.isAI = false});

  @override
  State<ChkobbaPopup> createState() => _ChkobbaPopupState();
}

class _ChkobbaPopupState extends State<ChkobbaPopup>
    with TickerProviderStateMixin {
  late AnimationController _entranceCtrl;    // bounce + shake
  late AnimationController _confettiCtrl;    // particle burst
  late AnimationController _shimmerCtrl;     // text shimmer
  late AnimationController _glowCtrl;        // pulsing bg glow

  late Animation<double> _scaleAnim;
  late Animation<double> _shakeAnim;

  @override
  void initState() {
    super.initState();

    // ── Entrance: scale bounce ──────────────────────────
    _entranceCtrl = AnimationController(
      duration: const Duration(milliseconds: 700),
      vsync: this,
    );
    _scaleAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.3), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 1.3, end: 0.85), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 0.85, end: 1.1), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 1.1, end: 1.0), weight: 20),
    ]).animate(CurvedAnimation(
      parent: _entranceCtrl,
      curve: Curves.easeOut,
    ));

    // shake wiggle
    _shakeAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0, end: -0.06), weight: 15),
      TweenSequenceItem(tween: Tween(begin: -0.06, end: 0.06), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 0.06, end: -0.04), weight: 20),
      TweenSequenceItem(tween: Tween(begin: -0.04, end: 0.02), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 0.02, end: 0.0), weight: 25),
    ]).animate(CurvedAnimation(
      parent: _entranceCtrl,
      curve: const Interval(0.3, 1.0, curve: Curves.easeInOut),
    ));

    // ── Confetti burst ──────────────────────────────────
    _confettiCtrl = AnimationController(
      duration: const Duration(milliseconds: 1600),
      vsync: this,
    );

    // ── Text shimmer sweep ──────────────────────────────
    _shimmerCtrl = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    // ── Background glow pulse ───────────────────────────
    _glowCtrl = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);

    // Fire!
    _entranceCtrl.forward();
    _confettiCtrl.forward();
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) _shimmerCtrl.repeat();
    });
  }

  @override
  void dispose() {
    _entranceCtrl.dispose();
    _confettiCtrl.dispose();
    _shimmerCtrl.dispose();
    _glowCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isAI = widget.isAI;

    return Center(
      child: SizedBox(
        width: 360,
        height: 360,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // ── Layer 1: Pulsing radial glow ────────────
            AnimatedBuilder(
              animation: _glowCtrl,
              builder: (_, __) {
                final pulse = 0.6 + _glowCtrl.value * 0.4;
                return Container(
                  width: 280 * pulse,
                  height: 200 * pulse,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(100),
                    boxShadow: [
                      BoxShadow(
                        color: (isAI
                                ? const Color(0xFF7C6BC4)
                                : const Color(0xFFFFB300))
                            .withAlpha((60 + 40 * _glowCtrl.value).round()),
                        blurRadius: 80,
                        spreadRadius: 30,
                      ),
                    ],
                  ),
                );
              },
            ),

            // ── Layer 2: Confetti particles ─────────────
            AnimatedBuilder(
              animation: _confettiCtrl,
              builder: (_, __) => CustomPaint(
                painter: _ConfettiPainter(
                  progress: _confettiCtrl.value,
                  isAI: isAI,
                ),
                size: const Size(360, 360),
              ),
            ),

            // ── Layer 3: Main badge ─────────────────────
            AnimatedBuilder(
              animation: _entranceCtrl,
              builder: (_, __) => Transform.rotate(
                angle: _shakeAnim.value,
                child: Transform.scale(
                  scale: _scaleAnim.value,
                  child: _buildBadge(isAI),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBadge(bool isAI) {
    final primaryColor = isAI
        ? const Color(0xFF6C5BAE)
        : const Color(0xFFD4A017);
    final secondaryColor = isAI
        ? const Color(0xFF9B8DD0)
        : const Color(0xFFFFD54F);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [primaryColor, secondaryColor, primaryColor],
          stops: const [0.0, 0.5, 1.0],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: Colors.white.withAlpha(100),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withAlpha(180),
            blurRadius: 24,
            spreadRadius: 4,
          ),
          BoxShadow(
            color: Colors.black.withAlpha(100),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Emoji line ────────────────────────────
          Text(
            isAI ? '🤖' : '🔥',
            style: const TextStyle(fontSize: 32),
          ),
          const SizedBox(height: 4),

          // ── Shimmer text ──────────────────────────
          AnimatedBuilder(
            animation: _shimmerCtrl,
            builder: (_, __) => ShaderMask(
              shaderCallback: (bounds) {
                final shift = _shimmerCtrl.value * 2 - 0.5;
                return LinearGradient(
                  begin: Alignment(-1 + shift * 3, 0),
                  end: Alignment(shift * 3, 0),
                  colors: isAI
                      ? [
                          Colors.white,
                          const Color(0xFFE0D0FF),
                          Colors.white,
                        ]
                      : [
                          const Color(0xFF8B1A1A),
                          Colors.white,
                          const Color(0xFF8B1A1A),
                        ],
                  stops: const [0.0, 0.5, 1.0],
                ).createShader(bounds);
              },
              child: Text(
                'CHKOBBA!',
                style: TextStyle(
                  fontSize: 38,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: 3,
                  shadows: [
                    Shadow(
                      color: Colors.black.withAlpha(60),
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),

          // ── Subtitle ──────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.black.withAlpha(40),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withAlpha(30),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isAI ? Icons.smart_toy : Icons.emoji_events,
                  size: 16,
                  color: isAI ? Colors.white60 : const Color(0xFF8B4513),
                ),
                const SizedBox(width: 6),
                Text(
                  isAI ? 'IA  ·  +1 point' : 'Bravo !  ·  +1 point',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: isAI ? Colors.white70 : const Color(0xFF6D3008),
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  CONFETTI PAINTER — colorful pieces that explode outward with gravity
// ═══════════════════════════════════════════════════════════════════

class _ConfettiPainter extends CustomPainter {
  final double progress;
  final bool isAI;
  static const int _count = 24;

  _ConfettiPainter({required this.progress, required this.isAI});

  static final _rng = math.Random(42);
  static final List<_ConfettiPiece> _pieces = List.generate(_count, (i) {
    final angle = (i / _count) * 2 * math.pi + _rng.nextDouble() * 0.3;
    final speed = 0.6 + _rng.nextDouble() * 0.5;
    final rotSpeed = _rng.nextDouble() * 4 - 2;
    final size = 4.0 + _rng.nextDouble() * 5;
    final colorIdx = _rng.nextInt(5);
    return _ConfettiPiece(angle, speed, rotSpeed, size, colorIdx);
  });

  static const _playerColors = [
    Color(0xFFFFD700), // gold
    Color(0xFFFF6B35), // orange
    Color(0xFFE53935), // red
    Color(0xFFFFEB3B), // yellow
    Color(0xFFFF8F00), // amber
  ];

  static const _aiColors = [
    Color(0xFF9C27B0), // purple
    Color(0xFF7C4DFF), // deep purple
    Color(0xFF448AFF), // blue
    Color(0xFFE040FB), // pink
    Color(0xFFB388FF), // light purple
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxR = size.shortestSide / 2;
    final colors = isAI ? _aiColors : _playerColors;

    for (var i = 0; i < _count; i++) {
      final p = _pieces[i];
      final delay = (i / _count) * 0.15;
      final t = ((progress - delay) / 0.85).clamp(0.0, 1.0);
      if (t <= 0) continue;

      // Position: fly out with slight gravity
      final dist = maxR * t * p.speed;
      final gravity = 30 * t * t; // subtle downward drift
      final x = center.dx + math.cos(p.angle) * dist;
      final y = center.dy + math.sin(p.angle) * dist + gravity;

      // Fade out
      final opacity = (1.0 - t * t) * 0.9;
      if (opacity <= 0) continue;

      final color = colors[p.colorIdx].withAlpha((opacity * 255).round());
      final rotation = p.rotSpeed * t * math.pi;

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(rotation);

      // Draw a small rectangular confetti piece
      final rect = Rect.fromCenter(
        center: Offset.zero,
        width: p.size,
        height: p.size * 0.5,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(1)),
        Paint()..color = color,
      );

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => old.progress != progress;
}

class _ConfettiPiece {
  final double angle;
  final double speed;
  final double rotSpeed;
  final double size;
  final int colorIdx;
  const _ConfettiPiece(this.angle, this.speed, this.rotSpeed, this.size, this.colorIdx);
}
