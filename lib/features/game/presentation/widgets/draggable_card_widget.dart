// lib/features/game/presentation/widgets/draggable_card_widget.dart

import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../domain/entities/card.dart' as game_card;
import 'playing_card_widget.dart';

/// A card widget that can be dragged for capture mechanics
class DraggableCardWidget extends StatefulWidget {
  final game_card.Card card;
  final bool isEnabled;
  final double width;
  final double height;
  final VoidCallback? onTap;

  const DraggableCardWidget({
    super.key,
    required this.card,
    required this.isEnabled,
    required this.width,
    required this.height,
    this.onTap,
  });

  @override
  State<DraggableCardWidget> createState() => _DraggableCardWidgetState();
}

class _DraggableCardWidgetState extends State<DraggableCardWidget>
    with SingleTickerProviderStateMixin {
  bool _isDragging = false;
  late AnimationController _hoverController;
  late Animation<double> _hoverAnimation;

  @override
  void initState() {
    super.initState();
    _hoverController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _hoverAnimation = Tween<double>(begin: 0, end: -15).animate(
      CurvedAnimation(parent: _hoverController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _hoverController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isEnabled) {
      return Opacity(
        opacity: 0.6,
        child: PlayingCardWidget(
          card: widget.card,
          isSelectable: false,
          isSelected: false,
          width: widget.width,
          height: widget.height,
        ),
      );
    }

    return MouseRegion(
      onEnter: (_) => _hoverController.forward(),
      onExit: (_) {
        if (!_isDragging) _hoverController.reverse();
      },
      child: GestureDetector(
        onTap: widget.onTap,
        child: LongPressDraggable<game_card.Card>(
          data: widget.card,
          delay: const Duration(milliseconds: 100),
          onDragStarted: () {
            setState(() => _isDragging = true);
            _hoverController.forward();
          },
          onDragEnd: (_) {
            setState(() => _isDragging = false);
            _hoverController.reverse();
          },
          onDraggableCanceled: (_, __) {
            setState(() => _isDragging = false);
            _hoverController.reverse();
          },
          feedback: Material(
            color: Colors.transparent,
            child: Transform.scale(
              scale: 1.15,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.goldOpacity(0.5),
                      blurRadius: 25,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: PlayingCardWidget(
                  card: widget.card,
                  isSelectable: true,
                  isSelected: true,
                  width: widget.width,
                  height: widget.height,
                ),
              ),
            ),
          ),
          childWhenDragging: Opacity(
            opacity: 0.3,
            child: PlayingCardWidget(
              card: widget.card,
              isSelectable: false,
              isSelected: false,
              width: widget.width,
              height: widget.height,
            ),
          ),
          child: AnimatedBuilder(
            animation: _hoverAnimation,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(0, _hoverAnimation.value),
                child: child,
              );
            },
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                boxShadow: _isDragging
                    ? [
                        BoxShadow(
                          color: AppColors.goldOpacity(0.4),
                          blurRadius: 20,
                          spreadRadius: 3,
                        ),
                      ]
                    : null,
              ),
              child: PlayingCardWidget(
                card: widget.card,
                isSelectable: true,
                isSelected: false,
                width: widget.width,
                height: widget.height,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
