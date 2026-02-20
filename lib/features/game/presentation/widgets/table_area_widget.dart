import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../domain/entities/card.dart' as game_card;
import 'playing_card_widget.dart';

class TableAreaWidget extends StatelessWidget {
  final List<game_card.Card> tableCards;
  final List<game_card.Card> selectedCards;
  final Function(game_card.Card) onCardTap;
  final bool isRedTheme;

  const TableAreaWidget({
    super.key,
    required this.tableCards,
    required this.selectedCards,
    required this.onCardTap,
    required this.isRedTheme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isRedTheme
            ? AppColors.whiteOpacity(0.05)
            : AppColors.white.withOpacity(0.5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isRedTheme
              ? AppColors.whiteOpacity(0.2)
              : AppColors.grey300,
          width: 2,
        ),
      ),
      child: tableCards.isEmpty
          ? _buildEmptyTable()
          : _buildTableWithCards(),
    );
  }

  Widget _buildEmptyTable() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.style_outlined,
            size: 48,
            color: isRedTheme
                ? AppColors.whiteOpacity(0.3)
                : AppColors.grey400,
          ),
          const SizedBox(height: 8),
          Text(
            'Table vide',
            style: TextStyle(
              fontSize: 16,
              color: isRedTheme
                  ? AppColors.whiteOpacity(0.5)
                  : AppColors.grey500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableWithCards() {
    return Center(
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 12,
        runSpacing: 12,
        children: tableCards.map((card) {
          final isSelected = selectedCards.contains(card);

          return PlayingCardWidget(
            card: card,
            isSelectable: true,
            isSelected: isSelected,
            width: 65,
            height: 90,
            onTap: () => onCardTap(card),
          );
        }).toList(),
      ),
    );
  }
}