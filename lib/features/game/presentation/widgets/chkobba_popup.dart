// lib/features/game/presentation/widgets/chkobba_popup.dart

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/constants/app_colors.dart';

/// Animated popup shown when player clears the table (Chkobba)
class ChkobbaPopup extends StatefulWidget {
  const ChkobbaPopup({super.key});

  @override
  State<ChkobbaPopup> createState() => _ChkobbaPopupState();
}

class _ChkobbaPopupState extends State<ChkobbaPopup>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _rotateController;
  late AnimationController _starController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotateAnimation;

  @override
  void initState() {
    super.initState();
    
    // Scale animation
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.3), weight: 60),
      TweenSequenceItem(tween: Tween(begin: 1.3, end: 1.0), weight: 40),
    ]).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.easeOut,
    ));
    
    // Rotation animation
    _rotateController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _rotateAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: -0.1, end: 0.1), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 0.1, end: 0.0), weight: 50),
    ]).animate(CurvedAnimation(
      parent: _rotateController,
      curve: Curves.easeInOut,
    ));
    
    // Star burst controller
    _starController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    // Play sound and haptic
    _playFeedback();
    
    // Start animations
    _scaleController.forward();
    _rotateController.forward();
    _starController.forward();
    
    // Auto-close after 2 seconds
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) Navigator.of(context).pop();
    });
  }

  void _playFeedback() async {
    HapticFeedback.heavyImpact();
    await Future.delayed(const Duration(milliseconds: 150));
    HapticFeedback.mediumImpact();
    
    // TODO: Play actual audio file when added
    // AudioService().playChkobba();
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _rotateController.dispose();
    _starController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Star burst effect
          AnimatedBuilder(
            animation: _starController,
            builder: (context, child) {
              return CustomPaint(
                painter: _StarBurstPainter(
                  progress: _starController.value,
                  color: AppColors.gold,
                ),
                size: const Size(400, 400),
              );
            },
          ),
          
          // Main text
          AnimatedBuilder(
            animation: _scaleAnimation,
            builder: (context, child) {
              return Transform.rotate(
                angle: _rotateAnimation.value,
                child: Transform.scale(
                  scale: _scaleAnimation.value,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 40,
                      vertical: 20,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.gold,
                          const Color(0xFFFFD54F),
                          AppColors.gold,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.goldOpacity(0.6),
                          blurRadius: 30,
                          spreadRadius: 10,
                        ),
                        BoxShadow(
                          color: Colors.black.withAlpha(100),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Star icon
                        const Text('⭐', style: TextStyle(fontSize: 40)),
                        const SizedBox(height: 8),
                        // CHKOBBA text
                        ShaderMask(
                          shaderCallback: (bounds) => const LinearGradient(
                            colors: [
                              Color(0xFF8B0000),
                              Color(0xFFB71C1C),
                              Color(0xFF8B0000),
                            ],
                          ).createShader(bounds),
                          child: const Text(
                            'CHKOBBA!',
                            style: TextStyle(
                              fontSize: 42,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: 4,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '+1 Point',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.darkRed,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

/// Star burst animation painter
class _StarBurstPainter extends CustomPainter {
  final double progress;
  final Color color;
  final int starCount;

  _StarBurstPainter({
    required this.progress,
    required this.color,
    this.starCount = 12,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.shortestSide / 2;
    
    for (var i = 0; i < starCount; i++) {
      final angle = (i / starCount) * 2 * math.pi;
      final delay = i / starCount * 0.3;
      final adjustedProgress = (progress - delay).clamp(0.0, 1.0);
      
      if (adjustedProgress > 0) {
        final radius = maxRadius * adjustedProgress;
        final opacity = (1 - adjustedProgress) * 0.8;
        
        final starCenter = Offset(
          center.dx + math.cos(angle) * radius,
          center.dy + math.sin(angle) * radius,
        );
        
        final paint = Paint()
          ..color = color.withAlpha((opacity * 255).toInt())
          ..style = PaintingStyle.fill;
        
        // Draw star shape
        final starRadius = 10.0 * (1 - adjustedProgress * 0.5);
        _drawStar(canvas, starCenter, starRadius, paint);
      }
    }
  }

  void _drawStar(Canvas canvas, Offset center, double radius, Paint paint) {
    final path = Path();
    final points = 5;
    final innerRadius = radius * 0.4;
    
    for (var i = 0; i < points * 2; i++) {
      final r = i.isEven ? radius : innerRadius;
      final angle = (i * math.pi / points) - math.pi / 2;
      final point = Offset(
        center.dx + math.cos(angle) * r,
        center.dy + math.sin(angle) * r,
      );
      
      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _StarBurstPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
