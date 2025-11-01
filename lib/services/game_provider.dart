import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/game.dart';
import '../models/player.dart';
import '../models/card.dart';
import 'multiplayer_service.dart';

/// Provider for managing game state
class GameProvider extends ChangeNotifier {
  final MultiplayerService _multiplayerService = MultiplayerService();
  
  GameModel? _currentGame;
  String? _currentPlayerId;
  String? _errorMessage;
  bool _isConnected = false;
  Map<String, dynamic>? _revealData;
  // Timer to automatically clear reveal overlay if server doesn't send new state
  // (keeps UI robust even if server-side timing changes)
  Timer? _revealTimer;
  // Client-side locked forbidden bids for the current game/round (keeps the
  // 'forbidden' number disabled for the last bidder even after they place a bid)
  final Set<int> _lockedForbidden = {};

  GameModel? get currentGame => _currentGame;
  String? get currentPlayerId => _currentPlayerId;
  String? get errorMessage => _errorMessage;
  bool get isConnected => _isConnected;

  GameProvider() {
    _multiplayerService.gameStateStream.listen((game) {
      // Do not blindly clear reveal overlay on every game_state.
      // Only clear reveal if the game advanced beyond the revealed round
      // (for example, after the 10s reveal delay the server will advance the round).
      if (_revealData != null) {
        try {
          final revRound = _revealData!['roundNumber'] as int?;
          if (revRound != null && game.roundNumber > revRound) {
            _revealData = null;
            _revealTimer?.cancel();
          }
        } catch (_) {
          // if any parsing fails, keep previous reveal and rely on timer to clear it
        }
      }

      // if a new game instance arrived, reset locked forbidden bids
      if (_currentGame == null || _currentGame!.id != game.id) {
        _lockedForbidden.clear();
      }

      _currentGame = game;
      // Update current player id from the multiplayer service if available
      try {
        _currentPlayerId = _multiplayerService.currentPlayerId ?? _currentPlayerId;
      } catch (_) {}
      notifyListeners();
    });

    _multiplayerService.errorStream.listen((error) {
      _errorMessage = error;
      notifyListeners();
    });

    _multiplayerService.revealStream.listen((rev) {
      // cancel any previous reveal timer
      _revealTimer?.cancel();

      _revealData = rev;
      notifyListeners();

      // If the server provided a duration (seconds), respect it; otherwise
      // default to 4 seconds for trick reveals.
      int durationSec = 4;
      try {
        final d = rev['duration'];
        if (d is int) durationSec = d;
        if (d is double) durationSec = d.toInt();
      } catch (_) {}

      _revealTimer = Timer(Duration(seconds: durationSec), () {
        _revealData = null;
        notifyListeners();
      });
    });
  }

  /// Connect to the multiplayer server
  Future<bool> connect(String serverUrl) async {
    _isConnected = await _multiplayerService.connect(serverUrl);
    notifyListeners();
    return _isConnected;
  }

  /// Create a new game
  void createGame(String playerName, int maxPlayers) {
    _multiplayerService.createGame(playerName, maxPlayers);
  }

  /// Join an existing game
  void joinGame(String gameId, String playerName) {
    _multiplayerService.joinGame(gameId, playerName);
  }

  /// Leave the current game
  void leaveGame() {
    _multiplayerService.leaveGame();
    _currentGame = null;
    _currentPlayerId = null;
    notifyListeners();
  }

  /// Set player ready status
  void setReady(bool ready) {
    _multiplayerService.setReady(ready);
  }

  /// Start the game
  void startGame() {
    _multiplayerService.startGame();
  }

  /// Place a bid
  void placeBid(int bid) {
    // If this client is the last to bet (others have placed), lock the forbidden
    // bid number so it remains disabled in the UI even after placing a different bid.
    final game = _currentGame;
    final pid = _currentPlayerId;
    if (game != null && pid != null) {
      final bidsCount = game.bids.length;
      final playersCount = game.players.length;
      final amILastToBet = bidsCount == playersCount - 1 && !game.bids.containsKey(pid);
      if (amILastToBet) {
        final existingSum = game.bids.values.fold<int>(0, (a, b) => a + b);
        // Compute cards per round from roundNumber (1..10..1) rather than relying
        // on player's hand length which may be hidden (round 1). This prevents
        // erroneous forbidden values like negative numbers.
        final rn = game.roundNumber;
        final cardsPerRound = (rn <= 10) ? rn : (20 - rn + 1);
        final forbidden = cardsPerRound - existingSum;
        _lockedForbidden.add(forbidden);
      }
    }

    _multiplayerService.placeBid(bid);
  }

  /// Returns the set of locked forbidden bid numbers for UI purposes.
  Set<int> get lockedForbidden => _lockedForbidden;

  /// Confirm the current player's bid
  void confirmBid() {
    _multiplayerService.confirmBid();
  }

  /// Play a card
  void playCard(GameCard card) {
    // Send play to server
    _multiplayerService.playCard(card);

    // Also create a local reveal overlay immediately so players see the
    // played cards and the winner highlighted for 4 seconds, even if the
    // server hasn't emitted the reveal event yet. The server reveal (if any)
    // will override this when it arrives.
    final game = _currentGame;
    final localPid = _currentPlayerId;
    if (game == null || localPid == null) return;

    // Build entries from already-played cards in the current trick plus
    // the card this client just played.
    final entries = <Map<String, dynamic>>[];
    for (var i = 0; i < game.currentTrick.length; i++) {
      final c = game.currentTrick[i];
      final pid = (i < game.playerIdsInTrick.length) ? game.playerIdsInTrick[i] : null;
      final player = pid != null
          ? game.players.firstWhere((p) => p.id == pid, orElse: () => Player(id: pid, name: pid, hand: []))
          : Player(id: 'unknown', name: 'Player', hand: []);
      entries.add({'playerId': player.id, 'playerName': player.name, 'card': c.toJson()});
    }

    final localPlayer = game.players.firstWhere((p) => p.id == localPid, orElse: () => Player(id: localPid, name: 'Player', hand: []));
    entries.add({'playerId': localPlayer.id, 'playerName': localPlayer.name, 'card': card.toJson()});

    // Compute winner locally using same rules as GameModel._evaluateTrick
    final cards = <GameCard>[...game.currentTrick, card];
    final pids = <String>[];
    pids.addAll(game.playerIdsInTrick);
    pids.add(localPid);

    CardRank? manilhaRank;
    if (game.trumpCard != null) {
      final ranks = CardRank.values;
      final viraIndex = ranks.indexOf(game.trumpCard!.rank);
      final manilhaIndex = (viraIndex + 1) % ranks.length;
      manilhaRank = ranks[manilhaIndex];
    }

    final suitOrder = {
      CardSuit.diamonds: 0,
      CardSuit.spades: 1,
      CardSuit.hearts: 2,
      CardSuit.clubs: 3,
    };

    int winnerIndex = 0;
    if (manilhaRank != null && cards.any((c) => c.rank == manilhaRank)) {
      var bestSuitOrder = -1;
      for (var i = 0; i < cards.length; i++) {
        final c = cards[i];
        if (c.rank == manilhaRank) {
          final so = suitOrder[c.suit] ?? 0;
          if (so > bestSuitOrder) {
            bestSuitOrder = so;
            winnerIndex = i;
          }
        }
      }
    } else {
      // Non-manilha: apply cancellation rule for tied ranks.
      final Map<CardRank, List<int>> rankToIndices = {};
      for (var i = 0; i < cards.length; i++) {
        final r = cards[i].rank;
        rankToIndices.putIfAbsent(r, () => []).add(i);
      }

      final candidateIndices = <int>[];
      rankToIndices.forEach((rank, indices) {
        if (indices.length == 1) candidateIndices.add(indices.first);
      });

      if (candidateIndices.isNotEmpty) {
        var bestIdx = candidateIndices.first;
        for (var idx in candidateIndices) {
          if (cards[idx].value > cards[bestIdx].value) {
            bestIdx = idx;
          }
        }
        winnerIndex = bestIdx;
      } else {
        // If all cancelled, choose first player as fallback (implementation choice)
        winnerIndex = 0;
      }
    }

    final winnerId = (winnerIndex >= 0 && winnerIndex < pids.length) ? pids[winnerIndex] : localPid;

    // Set client-side reveal overlay with default 4s duration
    _revealTimer?.cancel();
    _revealData = {
      'entries': entries,
      'winnerId': winnerId,
      'roundNumber': game.roundNumber,
      'duration': 4,
    };
    notifyListeners();

    _revealTimer = Timer(const Duration(seconds: 4), () {
      _revealData = null;
      notifyListeners();
    });
  }

  /// Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _multiplayerService.dispose();
    _revealTimer?.cancel();
    super.dispose();
  }

  /// Reveal data from server while showing round result overlay
  Map<String, dynamic>? get revealData => _revealData;
}
