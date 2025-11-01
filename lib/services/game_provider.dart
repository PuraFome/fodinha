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

  GameModel? get currentGame => _currentGame;
  String? get currentPlayerId => _currentPlayerId;
  String? get errorMessage => _errorMessage;
  bool get isConnected => _isConnected;

  GameProvider() {
    _multiplayerService.gameStateStream.listen((game) {
      _currentGame = game;
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
    _multiplayerService.placeBid(bid);
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
