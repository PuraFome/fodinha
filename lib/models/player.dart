import 'card.dart';

/// Model representing a player in the game
class Player {
  final String id;
  final String name;
  final List<GameCard> hand;
  int tricksWon;
  int score;
  bool isReady;
  bool isDealer;

  Player({
    required this.id,
    required this.name,
    List<GameCard>? hand,
    this.tricksWon = 0,
    this.score = 0,
    this.isReady = false,
    this.isDealer = false,
  }) : hand = hand ?? [];

  /// Add a card to the player's hand
  void addCard(GameCard card) {
    hand.add(card);
  }

  /// Remove a card from the player's hand
  bool removeCard(GameCard card) {
    return hand.remove(card);
  }

  /// Clear the player's hand
  void clearHand() {
    hand.clear();
  }

  /// Increment tricks won
  void wonTrick() {
    tricksWon++;
  }

  /// Reset tricks for new round
  void resetTricks() {
    tricksWon = 0;
  }

  /// Update score
  void addScore(int points) {
    score += points;
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'hand': hand.map((card) => card.toJson()).toList(),
        'tricksWon': tricksWon,
        'score': score,
        'isReady': isReady,
        'isDealer': isDealer,
      };

  /// Create from JSON
  factory Player.fromJson(Map<String, dynamic> json) {
    return Player(
      id: json['id'],
      name: json['name'],
      hand: (json['hand'] as List?)
              ?.map((cardJson) => GameCard.fromJson(cardJson))
              .toList() ??
          [],
      tricksWon: json['tricksWon'] ?? 0,
      score: json['score'] ?? 0,
      isReady: json['isReady'] ?? false,
      isDealer: json['isDealer'] ?? false,
    );
  }

  /// Create a copy with updated fields
  Player copyWith({
    String? id,
    String? name,
    List<GameCard>? hand,
    int? tricksWon,
    int? score,
    bool? isReady,
    bool? isDealer,
  }) {
    return Player(
      id: id ?? this.id,
      name: name ?? this.name,
      hand: hand ?? this.hand,
      tricksWon: tricksWon ?? this.tricksWon,
      score: score ?? this.score,
      isReady: isReady ?? this.isReady,
      isDealer: isDealer ?? this.isDealer,
    );
  }
}
