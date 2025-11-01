import 'package:flutter_test/flutter_test.dart';
import 'package:fodinha/models/player.dart';
import 'package:fodinha/models/card.dart';

void main() {
  group('Player', () {
    test('should create a player with required fields', () {
      final player = Player(id: '1', name: 'Test Player');
      
      expect(player.id, '1');
      expect(player.name, 'Test Player');
      expect(player.hand, isEmpty);
      expect(player.tricksWon, 0);
      expect(player.score, 0);
      expect(player.isReady, false);
      expect(player.isDealer, false);
    });

    test('should add cards to hand', () {
      final player = Player(id: '1', name: 'Test Player');
      final card = GameCard(suit: CardSuit.hearts, rank: CardRank.ace);
      
      player.addCard(card);
      
      expect(player.hand.length, 1);
      expect(player.hand.contains(card), true);
    });

    test('should remove cards from hand', () {
      final player = Player(id: '1', name: 'Test Player');
      final card = GameCard(suit: CardSuit.hearts, rank: CardRank.ace);
      
      player.addCard(card);
      final removed = player.removeCard(card);
      
      expect(removed, true);
      expect(player.hand, isEmpty);
    });

    test('should not remove non-existent card', () {
      final player = Player(id: '1', name: 'Test Player');
      final card1 = GameCard(suit: CardSuit.hearts, rank: CardRank.ace);
      final card2 = GameCard(suit: CardSuit.spades, rank: CardRank.king);
      
      player.addCard(card1);
      final removed = player.removeCard(card2);
      
      expect(removed, false);
      expect(player.hand.length, 1);
    });

    test('should clear hand', () {
      final player = Player(id: '1', name: 'Test Player');
      player.addCard(GameCard(suit: CardSuit.hearts, rank: CardRank.ace));
      player.addCard(GameCard(suit: CardSuit.spades, rank: CardRank.king));
      
      player.clearHand();
      
      expect(player.hand, isEmpty);
    });

    test('should track tricks won', () {
      final player = Player(id: '1', name: 'Test Player');
      
      player.wonTrick();
      player.wonTrick();
      
      expect(player.tricksWon, 2);
    });

    test('should reset tricks', () {
      final player = Player(id: '1', name: 'Test Player');
      
      player.wonTrick();
      player.wonTrick();
      player.resetTricks();
      
      expect(player.tricksWon, 0);
    });

    test('should add score', () {
      final player = Player(id: '1', name: 'Test Player');
      
      player.addScore(10);
      player.addScore(5);
      
      expect(player.score, 15);
    });

    test('should handle negative scores', () {
      final player = Player(id: '1', name: 'Test Player');
      
      player.addScore(10);
      player.addScore(-5);
      
      expect(player.score, 5);
    });

    test('should convert to and from JSON', () {
      final player = Player(
        id: '1',
        name: 'Test Player',
        tricksWon: 2,
        score: 15,
        isReady: true,
        isDealer: true,
      );
      
      final json = player.toJson();
      final fromJson = Player.fromJson(json);
      
      expect(fromJson.id, player.id);
      expect(fromJson.name, player.name);
      expect(fromJson.tricksWon, player.tricksWon);
      expect(fromJson.score, player.score);
      expect(fromJson.isReady, player.isReady);
      expect(fromJson.isDealer, player.isDealer);
    });

    test('should create copy with updated fields', () {
      final player = Player(id: '1', name: 'Test Player');
      final updated = player.copyWith(name: 'Updated Name', score: 20);
      
      expect(updated.id, player.id);
      expect(updated.name, 'Updated Name');
      expect(updated.score, 20);
    });
  });
}
