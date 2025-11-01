import 'dart:math';
import 'card.dart';

/// Class representing a deck of cards for the Fodinha game
class Deck {
  final List<GameCard> _cards = [];
  final Random _random = Random();

  Deck() {
    _initializeDeck();
  }

  /// Initialize the deck with all cards
  void _initializeDeck() {
    _cards.clear();
    for (var suit in CardSuit.values) {
      for (var rank in CardRank.values) {
        _cards.add(GameCard(suit: suit, rank: rank));
      }
    }
  }

  /// Shuffle the deck
  void shuffle() {
    for (var i = _cards.length - 1; i > 0; i--) {
      final j = _random.nextInt(i + 1);
      final temp = _cards[i];
      _cards[i] = _cards[j];
      _cards[j] = temp;
    }
  }

  /// Draw a card from the deck
  GameCard? drawCard() {
    if (_cards.isEmpty) return null;
    return _cards.removeLast();
  }

  /// Draw multiple cards
  List<GameCard> drawCards(int count) {
    final cards = <GameCard>[];
    for (var i = 0; i < count && _cards.isNotEmpty; i++) {
      cards.add(_cards.removeLast());
    }
    return cards;
  }

  /// Get remaining cards count
  int get remainingCards => _cards.length;

  /// Check if deck is empty
  bool get isEmpty => _cards.isEmpty;

  /// Reset the deck
  void reset() {
    _initializeDeck();
  }

  /// Reset and shuffle
  void resetAndShuffle() {
    reset();
    shuffle();
  }
}
