/// Enum representing the suit of a card
enum CardSuit {
  hearts,
  diamonds,
  clubs,
  spades,
}

/// Enum representing the rank of a card
enum CardRank {
  four,
  five,
  six,
  seven,
  queen,
  jack,
  king,
  ace,
  two,
  three,
}

/// Model representing a playing card in the Fodinha game
class GameCard {
  final CardSuit suit;
  final CardRank rank;

  const GameCard({
    required this.suit,
    required this.rank,
  });

  /// Get the display name of the suit
  String get suitName {
    switch (suit) {
      case CardSuit.hearts:
        return '♥';
      case CardSuit.diamonds:
        return '♦';
      case CardSuit.clubs:
        return '♣';
      case CardSuit.spades:
        return '♠';
    }
  }

  /// Get the display name of the rank
  String get rankName {
    switch (rank) {
      case CardRank.four:
        return '4';
      case CardRank.five:
        return '5';
      case CardRank.six:
        return '6';
      case CardRank.seven:
        return '7';
      case CardRank.queen:
        return 'Q';
      case CardRank.jack:
        return 'J';
      case CardRank.king:
        return 'K';
      case CardRank.ace:
        return 'A';
      case CardRank.two:
        return '2';
      case CardRank.three:
        return '3';
    }
  }

  /// Get the point value of the card (used for Fodinha rules)
  int get value {
    return rank.index;
  }

  /// Check if the card is red
  bool get isRed {
    return suit == CardSuit.hearts || suit == CardSuit.diamonds;
  }

  @override
  String toString() => '$rankName$suitName';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GameCard &&
          runtimeType == other.runtimeType &&
          suit == other.suit &&
          rank == other.rank;

  @override
  int get hashCode => suit.hashCode ^ rank.hashCode;

  /// Convert to JSON
  Map<String, dynamic> toJson() => {
        'suit': suit.name,
        'rank': rank.name,
      };

  /// Create from JSON
  factory GameCard.fromJson(Map<String, dynamic> json) {
    return GameCard(
      suit: CardSuit.values.firstWhere((s) => s.name == json['suit']),
      rank: CardRank.values.firstWhere((r) => r.name == json['rank']),
    );
  }
}
