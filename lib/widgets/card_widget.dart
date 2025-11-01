import 'package:flutter/material.dart';
import '../models/card.dart';

/// Widget to display a playing card
class CardWidget extends StatelessWidget {
  final GameCard card;
  final double size;
  final bool isSelectable;

  const CardWidget({
    super.key,
    required this.card,
    this.size = 100,
    this.isSelectable = false,
  });

  Color get _suitColor {
    return card.isRed ? Colors.red : Colors.black;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size * 0.7,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isSelectable ? Colors.blue : Colors.grey[300]!,
          width: isSelectable ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 4,
            offset: const Offset(2, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                Text(
                  card.rankName,
                  style: TextStyle(
                    color: _suitColor,
                    fontSize: size * 0.2,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  card.suitName,
                  style: TextStyle(
                    color: _suitColor,
                    fontSize: size * 0.2,
                  ),
                ),
              ],
            ),
          ),
          Text(
            card.suitName,
            style: TextStyle(
              color: _suitColor,
              fontSize: size * 0.35,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                Text(
                  card.suitName,
                  style: TextStyle(
                    color: _suitColor,
                    fontSize: size * 0.2,
                  ),
                ),
                Text(
                  card.rankName,
                  style: TextStyle(
                    color: _suitColor,
                    fontSize: size * 0.2,
                    fontWeight: FontWeight.bold,
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

/// Widget to display the back of a card
class CardBackWidget extends StatelessWidget {
  final double size;

  const CardBackWidget({
    super.key,
    this.size = 100,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size * 0.7,
      height: size,
      decoration: BoxDecoration(
        color: Colors.blue[900],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 4,
            offset: const Offset(2, 2),
          ),
        ],
      ),
      child: Center(
        child: Icon(
          Icons.style,
          color: Colors.white,
          size: size * 0.4,
        ),
      ),
    );
  }
}
