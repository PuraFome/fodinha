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
  // Client-side locked forbidden bids for the current game/round (keeps the
  // 'forbidden' number disabled for the last bidder even after they place a bid)
  final Set<int> _lockedForbidden = {};

  GameModel? get currentGame => _currentGame;
  String? get currentPlayerId => _currentPlayerId;
  String? get errorMessage => _errorMessage;
  bool get isConnected => _isConnected;

  GameProvider() {
    _multiplayerService.gameStateStream.listen((game) {
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
        final totalCards = game.players.firstWhere((p) => p.id == pid, orElse: () => game.currentPlayer).hand.length;
        final forbidden = totalCards - existingSum;
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
    _multiplayerService.playCard(card);
  }

  /// Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _multiplayerService.dispose();
    super.dispose();
  }
}
