import 'package:flutter_test/flutter_test.dart';
import 'package:fodinha/models/card.dart';

void main() {
  group('GameCard', () {
    test('should create a card with suit and rank', () {
      final card = GameCard(suit: CardSuit.hearts, rank: CardRank.ace);
      
      expect(card.suit, CardSuit.hearts);
      expect(card.rank, CardRank.ace);
    });

    test('should display correct suit name', () {
      final hearts = GameCard(suit: CardSuit.hearts, rank: CardRank.ace);
      final diamonds = GameCard(suit: CardSuit.diamonds, rank: CardRank.ace);
      final clubs = GameCard(suit: CardSuit.clubs, rank: CardRank.ace);
      final spades = GameCard(suit: CardSuit.spades, rank: CardRank.ace);
      
      expect(hearts.suitName, '♥');
      expect(diamonds.suitName, '♦');
      expect(clubs.suitName, '♣');
      expect(spades.suitName, '♠');
    });

    test('should display correct rank name', () {
      final ace = GameCard(suit: CardSuit.hearts, rank: CardRank.ace);
      final king = GameCard(suit: CardSuit.hearts, rank: CardRank.king);
      final queen = GameCard(suit: CardSuit.hearts, rank: CardRank.queen);
      final jack = GameCard(suit: CardSuit.hearts, rank: CardRank.jack);
      
      expect(ace.rankName, 'A');
      expect(king.rankName, 'K');
      expect(queen.rankName, 'Q');
      expect(jack.rankName, 'J');
    });

    test('should identify red cards correctly', () {
      final hearts = GameCard(suit: CardSuit.hearts, rank: CardRank.ace);
      final diamonds = GameCard(suit: CardSuit.diamonds, rank: CardRank.ace);
      final clubs = GameCard(suit: CardSuit.clubs, rank: CardRank.ace);
      final spades = GameCard(suit: CardSuit.spades, rank: CardRank.ace);
      
      expect(hearts.isRed, true);
      expect(diamonds.isRed, true);
      expect(clubs.isRed, false);
      expect(spades.isRed, false);
    });

    test('should convert to and from JSON', () {
      final card = GameCard(suit: CardSuit.hearts, rank: CardRank.ace);
      final json = card.toJson();
      final fromJson = GameCard.fromJson(json);
      
      expect(fromJson.suit, card.suit);
      expect(fromJson.rank, card.rank);
    });

    test('should compare cards correctly', () {
      final card1 = GameCard(suit: CardSuit.hearts, rank: CardRank.ace);
      final card2 = GameCard(suit: CardSuit.hearts, rank: CardRank.ace);
      final card3 = GameCard(suit: CardSuit.spades, rank: CardRank.ace);
      
      expect(card1 == card2, true);
      expect(card1 == card3, false);
    });
  });
}
