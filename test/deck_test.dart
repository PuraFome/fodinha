import 'package:flutter_test/flutter_test.dart';
import 'package:fodinha/models/deck.dart';
import 'package:fodinha/models/card.dart';

void main() {
  group('Deck', () {
    test('should initialize with 40 cards', () {
      final deck = Deck();
      expect(deck.remainingCards, 40);
    });

    test('should shuffle cards', () {
      final deck1 = Deck();
      final deck2 = Deck();
      
      final card1 = deck1.drawCard();
      final card2 = deck2.drawCard();
      
      // Before shuffle, both decks draw the same card
      expect(card1, card2);
      
      // After shuffle, decks should be different (with very high probability)
      final deck3 = Deck();
      final deck4 = Deck();
      deck4.shuffle();
      
      final cards3 = deck3.drawCards(10);
      final cards4 = deck4.drawCards(10);
      
      // It's very unlikely all 10 cards match after shuffle
      expect(cards3, isNot(equals(cards4)));
    });

    test('should draw cards correctly', () {
      final deck = Deck();
      final initialCount = deck.remainingCards;
      
      final card = deck.drawCard();
      
      expect(card, isNotNull);
      expect(deck.remainingCards, initialCount - 1);
    });

    test('should draw multiple cards', () {
      final deck = Deck();
      final cards = deck.drawCards(5);
      
      expect(cards.length, 5);
      expect(deck.remainingCards, 35);
    });

    test('should return null when drawing from empty deck', () {
      final deck = Deck();
      deck.drawCards(40);
      
      expect(deck.isEmpty, true);
      expect(deck.drawCard(), isNull);
    });

    test('should reset deck', () {
      final deck = Deck();
      deck.drawCards(20);
      
      expect(deck.remainingCards, 20);
      
      deck.reset();
      
      expect(deck.remainingCards, 40);
    });

    test('should reset and shuffle', () {
      final deck = Deck();
      deck.drawCards(20);
      
      deck.resetAndShuffle();
      
      expect(deck.remainingCards, 40);
    });
  });
}
