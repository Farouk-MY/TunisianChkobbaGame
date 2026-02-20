// lib/features/game/presentation/widgets/chkobba_celebration.dart

import 'dart:math';
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

/// Chkobba celebration overlay when player clears the table
class ChkobbaCelebration extends StatefulWidget {
  final VoidCallback onComplete;

  const ChkobbaCelebration({
    super.key,
    required this.onComplete,
  });

  static Future<void> show(BuildContext context) async {
    return showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation, secondaryAnimation) {
        return ChkobbaCelebration(
          onComplete: () => Navigator.pop(context),
        );
      },
    );
  }

  @override
  State<ChkobbaCelebration> createState() => _ChkobbaCelebrationState();
}

class _ChkobbaCelebrationState extends State<ChkobbaCelebration>
    with TickerProviderStateMixin {
  late AnimationController _mainController;
  late AnimationController _starsController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotateAnimation;
  late Animation<double> _fadeAnimation;
  final Random _random = Random();
  List<_Star> _stars = [];

  @override
  void initState() {
    super.initState();

    _mainController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _starsController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0, end: 1.3), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 1.3, end: 0.9), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 0.9, end: 1.0), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.0), weight: 20),
    ]).animate(CurvedAnimation(parent: _mainController, curve: Curves.easeOut));

    _rotateAnimation = Tween<double>(begin: -0.1, end: 0.1).animate(
      CurvedAnimation(parent: _mainController, curve: Curves.elasticOut),
    );

    _fadeAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0, end: 1), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 1, end: 1), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1, end: 0), weight: 20),
    ]).animate(_mainController);

    // Generate stars
    _generateStars();

    _mainController.forward().then((_) {
      Future.delayed(const Duration(milliseconds: 300), widget.onComplete);
    });
    _starsController.repeat();
  }

  void _generateStars() {
    _stars = List.generate(25, (i) {
      return _Star(
        angle: _random.nextDouble() * 2 * pi,
        distance: 80 + _random.nextDouble() * 150,
        size: 10 + _random.nextDouble() * 20,
        delay: _random.nextDouble() * 0.5,
        color: [
          AppColors.gold,
          Colors.yellow,
          Colors.orange,
          Colors.white,
        ][i % 4],
      );
    });
  }

  @override
  void dispose() {
    _mainController.dispose();
    _starsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _mainController,
      builder: (context, child) {
        return Opacity(
          opacity: _fadeAnimation.value,
          child: Center(
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Stars burst
                ..._buildStars(),

                // Main badge
                Transform.rotate(
                  angle: _rotateAnimation.value,
                  child: Transform.scale(
                    scale: _scaleAnimation.value,
                    child: _buildBadge(),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  List<Widget> _buildStars() {
    return _stars.map((star) {
      final progress = ((_starsController.value + star.delay) % 1.0);
      final expandProgress = (_mainController.value * 2).clamp(0.0, 1.0);
      final currentDistance = star.distance * expandProgress;
      final opacity = (1 - progress).clamp(0.0, 1.0) * expandProgress;

      return Positioned(
        left: MediaQuery.of(context).size.width / 2 +
            cos(star.angle + progress * pi) * currentDistance -
            star.size / 2,
        top: MediaQuery.of(context).size.height / 2 +
            sin(star.angle + progress * pi) * currentDistance -
            star.size / 2,
        child: Opacity(
          opacity: opacity,
          child: Transform.rotate(
            angle: progress * pi * 2,
            child: Icon(
              Icons.star,
              size: star.size * (1 - progress * 0.5),
              color: star.color,
            ),
          ),
        ),
      );
    }).toList();
  }

  Widget _buildBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFFFFD700),
            const Color(0xFFFFA500),
            const Color(0xFFFFD700),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.goldOpacity(0.6),
            blurRadius: 30,
            spreadRadius: 10,
          ),
        ],
        border: Border.all(
          color: Colors.white.withAlpha(179),
          width: 3,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('⭐', style: TextStyle(fontSize: 32)),
              const SizedBox(width: 12),
              ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  colors: [Color(0xFF8B0000), Color(0xFF4A0000)],
                ).createShader(bounds),
                child: const Text(
                  'CHKOBBA!',
                  style: TextStyle(
                    fontSize: 42,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 4,
                    shadows: [
                      Shadow(
                        color: Colors.black26,
                        offset: Offset(2, 2),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              const Text('⭐', style: TextStyle(fontSize: 32)),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(77),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              '+1 Point',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF8B0000),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Star {
  final double angle;
  final double distance;
  final double size;
  final double delay;
  final Color color;

  _Star({
    required this.angle,
    required this.distance,
    required this.size,
    required this.delay,
    required this.color,
  });
}
