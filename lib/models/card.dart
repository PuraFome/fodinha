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

  /// Returns the expected asset path for this card following the project's
  /// convention: assets/images/cards/<suitFolder>/<fileName>.png
  ///
  /// Suit folders (Portuguese):
  /// - hearts -> copas
  /// - diamonds -> ouros
  /// - clubs -> paus
  /// - spades -> espadas
  ///
  /// File names (as requested): As.png, 2.png, 3.png, 4.png, 5.png, 6.png,
  /// 7.png, Dama.png, Valete.png, Rei.png
  String get assetPath {
    String suitFolder;
    switch (suit) {
      case CardSuit.hearts:
        suitFolder = 'copas';
        break;
      case CardSuit.diamonds:
        suitFolder = 'ouros';
        break;
      case CardSuit.clubs:
        suitFolder = 'paus';
        break;
      case CardSuit.spades:
        suitFolder = 'espadas';
        break;
    }

    String fileName;
    switch (rank) {
      case CardRank.ace:
        fileName = 'As.png';
        break;
      case CardRank.two:
        fileName = '2.png';
        break;
      case CardRank.three:
        fileName = '3.png';
        break;
      case CardRank.four:
        fileName = '4.png';
        break;
      case CardRank.five:
        fileName = '5.png';
        break;
      case CardRank.six:
        fileName = '6.png';
        break;
      case CardRank.seven:
        fileName = '7.png';
        break;
      case CardRank.queen:
        fileName = 'Dama.png';
        break;
      case CardRank.jack:
        fileName = 'Valete.png';
        break;
      case CardRank.king:
        fileName = 'Rei.png';
        break;
    }

    // Return the path relative to the asset bundle root WITHOUT a leading
    // 'assets/' so Flutter web will resolve to 'assets/images/...' (it
    // prefixes 'assets/' itself). This avoids duplicated 'assets/assets/...' URLs.
    return 'images/cards/$suitFolder/$fileName';
  }

  /// Create from JSON
  factory GameCard.fromJson(Map<String, dynamic> json) {
    return GameCard(
      suit: CardSuit.values.firstWhere((s) => s.name == json['suit']),
      rank: CardRank.values.firstWhere((r) => r.name == json['rank']),
    );
  }
}
