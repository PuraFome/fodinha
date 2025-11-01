import 'card.dart';
import 'player.dart';
import 'deck.dart';
import 'dart:math';

/// Enum representing the current state of the game
enum GameState {
  waiting,
  bidding,
  playing,
  roundEnd,
  gameEnd,
}

/// Model representing the game state
class GameModel {
  final String id;
  final List<Player> players;
  final Deck deck;
  GameState state;
  int currentPlayerIndex;
  int dealerIndex;
  int roundNumber;
  GameCard? trumpCard;
  List<GameCard> currentTrick;
  List<String> playerIdsInTrick;
  Map<String, int> bids;
  Map<String, bool> bidConfirmed;
  int? currentBidderIndex;
  int maxPlayers;

  GameModel({
    required this.id,
    List<Player>? players,
    Deck? deck,
    this.state = GameState.waiting,
    this.currentPlayerIndex = 0,
    this.dealerIndex = 0,
    this.roundNumber = 1,
    this.trumpCard,
    List<GameCard>? currentTrick,
    List<String>? playerIdsInTrick,
    Map<String, int>? bids,
    Map<String, bool>? bidConfirmed,
    int? currentBidderIndex,
    this.maxPlayers = 6,
  })  : players = players ?? [],
        deck = deck ?? Deck(),
        currentTrick = currentTrick ?? [],
        playerIdsInTrick = playerIdsInTrick ?? [],
        bids = bids ?? {},
        bidConfirmed = bidConfirmed ?? {},
        currentBidderIndex = currentBidderIndex;

  /// Add a player to the game
  bool addPlayer(Player player) {
    if (players.length >= maxPlayers) return false;
    if (state != GameState.waiting) return false;

    players.add(player);
    return true;
  }

  /// Remove a player from the game
  bool removePlayer(String playerId) {
    if (state != GameState.waiting) return false;

    players.removeWhere((p) => p.id == playerId);
    return true;
  }

  /// Check if game can start
  bool canStartGame() {
    return players.length >= 2 && players.every((p) => p.isReady);
  }

  /// Start a new game
  void startGame() {
    if (!canStartGame()) return;

    state = GameState.bidding;
    dealerIndex = 0;
    roundNumber = 1;
    // Ensure the first bidder is randomized for each new game by resetting
    // currentBidderIndex here. _startNewRound() will detect null and pick a
    // random starter. This prevents reuse of the previous game's starter when
    // reusing the same GameModel instance.
    currentBidderIndex = null;
    _startNewRound();
  }

  /// Start a new round
  void _startNewRound() {
    // Clear previous round data
    for (var player in players) {
      player.clearHand();
      player.resetTricks();
    }
    bids.clear();
    currentTrick.clear();
    playerIdsInTrick.clear();

    // Shuffle and deal cards
    deck.resetAndShuffle();
    _dealCards();

    // Set trump card
    trumpCard = deck.drawCard();

    // Move to next dealer
    dealerIndex = (dealerIndex + 1) % players.length;
    currentPlayerIndex = (dealerIndex + 1) % players.length;

    // Determine who starts bidding this round.
    // - For the very first round (when currentBidderIndex is null) choose a
    //   random player to start bidding.
    // - For subsequent rounds, the player who starts bidding is the next
    //   player after the one who started the previous round.
    if (players.isNotEmpty) {
      if (currentBidderIndex == null) {
        // Randomize first bidder for the first round
        final rnd = Random();
        currentBidderIndex = rnd.nextInt(players.length);
      } else {
        // Advance first bidder by one position for the new round
        currentBidderIndex = (currentBidderIndex! + 1) % players.length;
      }
    }
  }

  /// Deal cards to players
  void _dealCards() {
    final cardsPerPlayer = _calculateCardsPerRound();
    for (var player in players) {
      final cards = deck.drawCards(cardsPerPlayer);
      for (var card in cards) {
        player.addCard(card);
      }
    }
  }

  /// Calculate cards per round based on round number
  int _calculateCardsPerRound() {
    // Fodinha typically goes from 1 to 10 cards and back
    if (roundNumber <= 10) {
      return roundNumber;
    } else {
      return 20 - roundNumber + 1;
    }
  }

  /// Place a bid for a player
  void placeBid(String playerId, int bid) {
    if (state != GameState.bidding) return;
    bids[playerId] = bid;

    // Check if all players have bid
    if (bids.length == players.length) {
      state = GameState.playing;
    }
  }

  /// Play a card
  void playCard(String playerId, GameCard card) {
    if (state != GameState.playing) return;

    final player = players.firstWhere((p) => p.id == playerId);
    if (player.removeCard(card)) {
      currentTrick.add(card);
      playerIdsInTrick.add(playerId);

      // Check if trick is complete
      if (currentTrick.length == players.length) {
        _evaluateTrick();
      } else {
        currentPlayerIndex = (currentPlayerIndex + 1) % players.length;
      }
    }
  }

  /// Evaluate the current trick
  void _evaluateTrick() {
    if (currentTrick.isEmpty) return;

    // If there is a trumpCard (vira), determine the manilha rank
    CardRank? manilhaRank;
    if (trumpCard != null) {
      final ranks = CardRank.values;
      final viraIndex = ranks.indexOf(trumpCard!.rank);
      final manilhaIndex = (viraIndex + 1) % ranks.length;
      manilhaRank = ranks[manilhaIndex];
    }

    // Helper to get suit order for manilha tie-break: ouro < espadas < copas < paus
    final suitOrder = {
      CardSuit.diamonds: 0, // ouro
      CardSuit.spades: 1,   // espadas
      CardSuit.hearts: 2,   // copas
      CardSuit.clubs: 3,    // paus
    };

    int winnerIndex = 0;

    // If any manilha present, only manilhas compete and tiebreak by suit order
    if (manilhaRank != null && currentTrick.any((c) => c.rank == manilhaRank)) {
      var bestSuitOrder = -1;
      for (var i = 0; i < currentTrick.length; i++) {
        final c = currentTrick[i];
        if (c.rank == manilhaRank) {
          final so = suitOrder[c.suit] ?? 0;
          if (so > bestSuitOrder) {
            bestSuitOrder = so;
            winnerIndex = i;
          }
        }
      }
    } else {
      // No manilha: we must consider that equal-rank cards (ties) cancel each other.
      // Example: if two players play 2 and another plays A, the two 2s cancel and the A wins.
      // Approach:
      // 1. Group indices by rank.
      // 2. Remove ranks that appear more than once (they anulam).
      // 3. Among remaining singletons pick the highest rank (by enum index/value).
      // 4. If none remain (all ranks cancelled), fall back to first player as winner.

      final Map<CardRank, List<int>> rankToIndices = {};
      for (var i = 0; i < currentTrick.length; i++) {
        final r = currentTrick[i].rank;
        rankToIndices.putIfAbsent(r, () => []).add(i);
      }

      // Collect indices of ranks that are unique (not cancelled)
      final candidateIndices = <int>[];
      rankToIndices.forEach((rank, indices) {
        if (indices.length == 1) candidateIndices.add(indices.first);
      });

      if (candidateIndices.isNotEmpty) {
        // Choose the candidate with the highest rank (strongest)
        var bestIdx = candidateIndices.first;
        for (var idx in candidateIndices) {
          if (currentTrick[idx].value > currentTrick[bestIdx].value) {
            bestIdx = idx;
          }
        }
        winnerIndex = bestIdx;
      } else {
        // All ranks cancelled each other. This is a rare situation; to keep
        // game flow deterministic we award the trick to the first player.
        // NOTE: this is an implementation assumption — if you prefer a
        // different behavior (e.g. trick is draw), tell me and I can change it.
        winnerIndex = 0;
      }
    }

    // Award trick to winner
    final winnerId = playerIdsInTrick[winnerIndex];
    final winner = players.firstWhere((p) => p.id == winnerId);
    winner.wonTrick();

    // Clear trick
    currentTrick.clear();
    playerIdsInTrick.clear();

    // Set current player to winner
    currentPlayerIndex = players.indexWhere((p) => p.id == winnerId);

    // Check if round is over
    if (players.every((p) => p.hand.isEmpty)) {
      _endRound();
    }
  }

  /// End the current round
  void _endRound() {
    state = GameState.roundEnd;

    // Calculate scores
    for (var player in players) {
      final bid = bids[player.id] ?? 0;
      final tricks = player.tricksWon;

      if (tricks == bid) {
        // Made the bid
        player.addScore(10 + bid);
      } else {
        // Missed the bid
        player.addScore(-5 * (tricks - bid).abs());
      }
    }

    // Check if game is over
    roundNumber++;
    if (roundNumber > 20) {
      state = GameState.gameEnd;
    } else {
      _startNewRound();
    }
  }

  /// Get current player
  Player get currentPlayer => players[currentPlayerIndex];

  /// Convert to JSON
  Map<String, dynamic> toJson() => {
        'id': id,
        'players': players.map((p) => p.toJson()).toList(),
        'state': state.name,
        'currentPlayerIndex': currentPlayerIndex,
        'dealerIndex': dealerIndex,
        'roundNumber': roundNumber,
        'trumpCard': trumpCard?.toJson(),
        'currentTrick': currentTrick.map((c) => c.toJson()).toList(),
        'playerIdsInTrick': playerIdsInTrick,
    'bids': bids,
    'bidConfirmed': bidConfirmed,
    'currentBidderIndex': currentBidderIndex,
        'maxPlayers': maxPlayers,
      };

  /// Create from JSON
  factory GameModel.fromJson(Map<String, dynamic> json) {
    return GameModel(
      id: json['id'],
      players: (json['players'] as List?)
              ?.map((p) => Player.fromJson(p))
              .toList() ??
          [],
      state: GameState.values.firstWhere((s) => s.name == json['state']),
      currentPlayerIndex: json['currentPlayerIndex'] ?? 0,
      dealerIndex: json['dealerIndex'] ?? 0,
      roundNumber: json['roundNumber'] ?? 1,
      trumpCard: json['trumpCard'] != null
          ? GameCard.fromJson(json['trumpCard'])
          : null,
      currentTrick: (json['currentTrick'] as List?)
              ?.map((c) => GameCard.fromJson(c))
              .toList() ??
          [],
      playerIdsInTrick:
          (json['playerIdsInTrick'] as List?)?.cast<String>() ?? [],
      bids: (json['bids'] as Map?)?.cast<String, int>() ?? {},
      bidConfirmed: (json['bidConfirmed'] as Map?)?.cast<String, bool>() ?? {},
      currentBidderIndex: json['currentBidderIndex'],
      maxPlayers: json['maxPlayers'] ?? 6,
    );
  }
}
