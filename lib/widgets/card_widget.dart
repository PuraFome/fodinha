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
    // Apply a global scale so cards are 150% of the provided `size`.
    // Keep a portrait card shape: height = size * 1.5, width = size * 0.7 * 1.5
    const double scale = 1.5;
    final double finalHeight = size * scale;
    final double finalWidth = size * 0.7 * scale; // portrait ratio

    // Only use image assets for hearts (copas). For other suits, use the
    // existing drawn card UI as fallback. This avoids error logs when
    // other suit assets are not present.
    if (card.suit == CardSuit.hearts) {
      final assetPath = card.assetPath;
      // Use contain so the whole asset is visible (no cropping). The
      // SizedBox enforces a portrait rectangle and Image will scale to fit.
      return SizedBox(
        width: finalWidth,
        height: finalHeight,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.asset(
            assetPath,
            fit: BoxFit.contain,
            width: double.infinity,
            height: double.infinity,
            errorBuilder: (context, error, stackTrace) {
              // fallback: drawn card UI
              return _buildDrawnCard(context, finalWidth, finalHeight);
            },
          ),
        ),
      );
    }

    return _buildDrawnCard(context, finalWidth, finalHeight);
  }

  Widget _buildDrawnCard(BuildContext context, [double? finalWidth, double? finalHeight]) {
    final double h = finalHeight ?? size * 1.5;
    final double w = finalWidth ?? size * 0.7 * 1.5;

    return Container(
      width: w,
      height: h,
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
                    fontSize: h * 0.12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  card.suitName,
                  style: TextStyle(
                    color: _suitColor,
                    fontSize: h * 0.12,
                  ),
                ),
              ],
            ),
          ),
          Text(
            card.suitName,
            style: TextStyle(
              color: _suitColor,
              fontSize: h * 0.21,
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
                    fontSize: h * 0.12,
                  ),
                ),
                Text(
                  card.rankName,
                  style: TextStyle(
                    color: _suitColor,
                    fontSize: h * 0.12,
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
    final double finalSize = size * 1.5;

    return Container(
      width: finalSize,
      height: finalSize,
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
          size: finalSize * 0.4,
        ),
      ),
    );
  }
}
