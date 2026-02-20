// lib/features/game/presentation/widgets/playing_card_widget.dart

import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../domain/entities/card.dart' as game_card;

/// Premium playing card widget with face card designs
class PlayingCardWidget extends StatelessWidget {
  final game_card.Card card;
  final bool isSelectable;
  final bool isSelected;
  final double width;
  final double height;
  final VoidCallback? onTap;

  const PlayingCardWidget({
    super.key,
    required this.card,
    this.isSelectable = false,
    this.isSelected = false,
    this.width = 70,
    this.height = 100,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cardColor = _getCardColor();
    final isSpecialCard = card.isSevenOfDiamonds;
    final isFaceCard = card.rank >= 11 && card.rank <= 13;
    
    return GestureDetector(
      onTap: isSelectable ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: width,
        height: height,
        transform: Matrix4.identity()
          ..translate(0.0, isSelected ? -10.0 : 0.0),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isSpecialCard
                  ? [const Color(0xFFFFF8E1), const Color(0xFFFFE082)]
                  : [const Color(0xFFFFFBF0), const Color(0xFFF5F0E6)],
            ),
            borderRadius: BorderRadius.circular(width * 0.12),
            border: Border.all(
              color: isSelected
                  ? AppColors.gold
                  : isSpecialCard
                      ? AppColors.gold.withAlpha(127)
                      : AppColors.grey300,
              width: isSelected ? 3 : 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: isSelected
                    ? AppColors.goldOpacity(0.5)
                    : AppColors.blackOpacity(0.2),
                offset: Offset(0, isSelected ? 6 : 3),
                blurRadius: isSelected ? 12 : 6,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(width * 0.1),
            child: Stack(
              children: [
                // Background for special cards
                if (isSpecialCard)
                  Positioned.fill(
                    child: CustomPaint(painter: _DiamondPatternPainter()),
                  ),
                
                // Main content
                if (isFaceCard)
                  _buildFaceCard(cardColor)
                else
                  _buildNumberCard(cardColor, isSpecialCard),
                
                // Selection indicator
                if (isSelected)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(width * 0.1),
                        border: Border.all(color: AppColors.gold, width: 2),
                      ),
                    ),
                  ),
                
                // Special star for 7 of diamonds
                if (isSpecialCard)
                  Positioned(
                    top: 2,
                    right: 2,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: AppColors.gold,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Icon(Icons.star, size: width * 0.1, color: Colors.white),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNumberCard(Color cardColor, bool isSpecial) {
    return Padding(
      padding: EdgeInsets.all(width * 0.06),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top corner
          _buildCorner(cardColor),
          
          // Center symbols
          Expanded(
            child: Center(
              child: _buildCenterSymbols(cardColor),
            ),
          ),
          
          // Bottom corner
          Align(
            alignment: Alignment.bottomRight,
            child: Transform.rotate(
              angle: 3.14159,
              child: _buildCorner(cardColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFaceCard(Color cardColor) {
    return Padding(
      padding: EdgeInsets.all(width * 0.04),
      child: Column(
        children: [
          // Top corner
          Align(
            alignment: Alignment.topLeft,
            child: _buildCorner(cardColor),
          ),
          
          // Face card illustration
          Expanded(
            child: Center(
              child: _buildFaceCardIllustration(cardColor),
            ),
          ),
          
          // Bottom corner
          Align(
            alignment: Alignment.bottomRight,
            child: Transform.rotate(
              angle: 3.14159,
              child: _buildCorner(cardColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFaceCardIllustration(Color cardColor) {
    // Decorative face card design
    return Container(
      width: width * 0.7,
      height: height * 0.5,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            cardColor.withAlpha(30),
            cardColor.withAlpha(60),
          ],
        ),
        borderRadius: BorderRadius.circular(width * 0.08),
        border: Border.all(color: cardColor.withAlpha(100), width: 1),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Decorative frame
          Positioned.fill(
            child: CustomPaint(
              painter: _FaceCardFramePainter(cardColor),
            ),
          ),
          
          // Crown or symbol
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (card.rank == 13) // King
                Icon(Icons.workspace_premium, color: cardColor, size: width * 0.25)
              else if (card.rank == 12) // Queen
                Icon(Icons.auto_awesome, color: cardColor, size: width * 0.25)
              else // Jack
                Icon(Icons.person, color: cardColor, size: width * 0.25),
              
              const SizedBox(height: 2),
              
              Text(
                _getFaceCardName(),
                style: TextStyle(
                  fontSize: width * 0.12,
                  fontWeight: FontWeight.bold,
                  color: cardColor,
                ),
              ),
            ],
          ),
          
          // Suit symbols on corners
          Positioned(
            top: 2,
            left: 2,
            child: Text(
              card.getSuitSymbol(),
              style: TextStyle(fontSize: width * 0.1, color: cardColor),
            ),
          ),
          Positioned(
            bottom: 2,
            right: 2,
            child: Transform.rotate(
              angle: 3.14159,
              child: Text(
                card.getSuitSymbol(),
                style: TextStyle(fontSize: width * 0.1, color: cardColor),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCenterSymbols(Color cardColor) {
    final symbol = card.getSuitSymbol();
    final rank = card.rank;
    
    if (rank == 1) {
      // Large Ace
      return Text(
        symbol,
        style: TextStyle(
          fontSize: width * 0.5,
          color: cardColor,
        ),
      );
    }
    
    // For 2-7, show pip pattern
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 4,
      runSpacing: 2,
      children: List.generate(
        rank > 7 ? 7 : rank,
        (i) => Text(
          symbol,
          style: TextStyle(fontSize: width * 0.18, color: cardColor),
        ),
      ),
    );
  }

  Widget _buildCorner(Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          _getRankDisplay(),
          style: TextStyle(
            fontSize: width * 0.16,
            fontWeight: FontWeight.w900,
            color: color,
            height: 1,
          ),
        ),
        Text(
          card.getSuitSymbol(),
          style: TextStyle(
            fontSize: width * 0.12,
            color: color,
            height: 1,
          ),
        ),
      ],
    );
  }

  Color _getCardColor() {
    if (card.suit == 'hearts' || card.suit == 'diamonds') {
      return const Color(0xFFB71C1C);
    }
    return const Color(0xFF1A1A2E);
  }

  String _getRankDisplay() {
    switch (card.rank) {
      case 1: return 'A';
      case 11: return 'J';
      case 12: return 'Q';
      case 13: return 'K';
      default: return card.rank.toString();
    }
  }

  String _getFaceCardName() {
    switch (card.rank) {
      case 11: return 'Fante';
      case 12: return 'Cavallo';
      case 13: return 'Re';
      default: return '';
    }
  }
}

/// Face card decorative frame painter
class _FaceCardFramePainter extends CustomPainter {
  final Color color;
  _FaceCardFramePainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withAlpha(40)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    // Draw decorative corners
    final cornerSize = size.width * 0.2;
    
    // Top-left
    canvas.drawLine(Offset(0, cornerSize), Offset(0, 0), paint);
    canvas.drawLine(const Offset(0, 0), Offset(cornerSize, 0), paint);
    
    // Top-right
    canvas.drawLine(Offset(size.width - cornerSize, 0), Offset(size.width, 0), paint);
    canvas.drawLine(Offset(size.width, 0), Offset(size.width, cornerSize), paint);
    
    // Bottom-left
    canvas.drawLine(Offset(0, size.height - cornerSize), Offset(0, size.height), paint);
    canvas.drawLine(Offset(0, size.height), Offset(cornerSize, size.height), paint);
    
    // Bottom-right
    canvas.drawLine(Offset(size.width - cornerSize, size.height), Offset(size.width, size.height), paint);
    canvas.drawLine(Offset(size.width, size.height - cornerSize), Offset(size.width, size.height), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Diamond pattern background painter
class _DiamondPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.goldOpacity(0.08)
      ..style = PaintingStyle.fill;

    final spacing = size.width / 5;
    
    for (var x = 0.0; x < size.width; x += spacing) {
      for (var y = 0.0; y < size.height; y += spacing) {
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