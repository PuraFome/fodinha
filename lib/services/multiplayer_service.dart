import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../models/game.dart';
import '../models/player.dart';
import '../models/card.dart';

/// Service for managing multiplayer game connections
class MultiplayerService {
  WebSocketChannel? _channel;
  final StreamController<GameModel> _gameStateController =
      StreamController<GameModel>.broadcast();
  final StreamController<String> _errorController =
      StreamController<String>.broadcast();
  final StreamController<Map<String, dynamic>> _revealController =
    StreamController<Map<String, dynamic>>.broadcast();

  String? _serverUrl;
  String? _currentGameId;
  String? _currentPlayerId;

  /// The id assigned by server for this client (if provided)
  String? get currentPlayerId => _currentPlayerId;

  /// Stream of game state updates
  Stream<GameModel> get gameStateStream => _gameStateController.stream;

  /// Stream of error messages
  Stream<String> get errorStream => _errorController.stream;
  /// Stream of reveal events (server announces round reveals)
  Stream<Map<String, dynamic>> get revealStream => _revealController.stream;

  /// Connect to the game server
  Future<bool> connect(String serverUrl) async {
    try {
      _serverUrl = serverUrl;
      _channel = WebSocketChannel.connect(Uri.parse(serverUrl));

      _channel!.stream.listen(
        _handleMessage,
        onError: (error) {
          _errorController.add('Connection error: $error');
        },
        onDone: () {
          _errorController.add('Connection closed');
        },
      );

      return true;
    } catch (e) {
      _errorController.add('Failed to connect: $e');
      return false;
    }
  }

  /// Disconnect from the server
  void disconnect() {
    _channel?.sink.close();
    _channel = null;
  }

  /// Handle incoming messages
  void _handleMessage(dynamic message) {
    try {
      final data = jsonDecode(message as String);
      final type = data['type'] as String;

      switch (type) {
        case 'game_state':
          // If server provided a playerId, capture it
          if (data is Map && data.containsKey('playerId')) {
            final pid = data['playerId'];
            if (pid is String) {
              _currentPlayerId = pid;
            }
          }

          // If server included a privateHand for this client, merge it into the
          // game JSON so GameModel.fromJson receives the client's actual hand
          // for the matching player while public players' hands remain hidden.
          if (data is Map && data.containsKey('privateHand') && data.containsKey('game')) {
            final gameJson = Map<String, dynamic>.from(data['game']);
            final privateHand = data['privateHand'];
            final pid = data['playerId'];
            if (pid is String && privateHand is List) {
              final players = (gameJson['players'] as List?) ?? [];
              for (var i = 0; i < players.length; i++) {
                final p = Map<String, dynamic>.from(players[i]);
                if (p['id'] == pid) {
                  p['hand'] = privateHand;
                  players[i] = p;
                  break;
                }
              }
              gameJson['players'] = players;
              final gameState = GameModel.fromJson(gameJson);
              _currentGameId = gameState.id;
              _gameStateController.add(gameState);
              break;
            }
          }

          final gameState = GameModel.fromJson(data['game']);
          // Ensure we track the current game id when the server sends the game state.
          // This fixes cases where the client (creator) hasn't yet set _currentGameId
          // and later actions like setReady() would be ignored.
          try {
            _currentGameId = gameState.id;
          } catch (_) {}

          // If server ever starts sending a playerId field identifying this client,
          // capture it so UI can map the local player correctly. Keep it optional.
          if (data is Map && data.containsKey('playerId')) {
            final pid = data['playerId'];
            if (pid is String) {
              _currentPlayerId = pid;
            }
          }

          _gameStateController.add(gameState);
          break;
        case 'reveal':
          if (data is Map && data.containsKey('reveal')) {
            final rev = Map<String, dynamic>.from(data['reveal']);
            _revealController.add(rev);
          }
          break;
        case 'error':
          _errorController.add(data['message'] as String);
          break;
        default:
          break;
      }
    } catch (e) {
      _errorController.add('Failed to parse message: $e');
    }
  }

  /// Send a message to the server
  void _sendMessage(Map<String, dynamic> message) {
    if (_channel == null) {
      _errorController.add('Not connected to server');
      return;
    }

    try {
      _channel!.sink.add(jsonEncode(message));
    } catch (e) {
      _errorController.add('Failed to send message: $e');
    }
  }

  /// Create a new game
  void createGame(String playerName, int maxPlayers) {
    _sendMessage({
      'type': 'create_game',
      'playerName': playerName,
      'maxPlayers': maxPlayers,
    });
  }

  /// Join an existing game
  void joinGame(String gameId, String playerName) {
    _currentGameId = gameId;
    _sendMessage({
      'type': 'join_game',
      'gameId': gameId,
      'playerName': playerName,
    });
  }

  /// Leave the current game
  void leaveGame() {
    if (_currentGameId == null) return;

    _sendMessage({
      'type': 'leave_game',
      'gameId': _currentGameId,
    });

    _currentGameId = null;
    _currentPlayerId = null;
  }

  /// Mark player as ready
  void setReady(bool ready) {
    if (_currentGameId == null) return;

    _sendMessage({
      'type': 'set_ready',
      'gameId': _currentGameId,
      'ready': ready,
    });
  }

  /// Start the game
  void startGame() {
    if (_currentGameId == null) return;

    _sendMessage({
      'type': 'start_game',
      'gameId': _currentGameId,
    });
  }

  /// Place a bid
  void placeBid(int bid) {
    if (_currentGameId == null) return;

    _sendMessage({
      'type': 'place_bid',
      'gameId': _currentGameId,
      'bid': bid,
    });
  }

  /// Confirm the bid (lock it and move to next bidder)
  void confirmBid() {
    if (_currentGameId == null) return;

    _sendMessage({
      'type': 'confirm_bid',
      'gameId': _currentGameId,
    });
  }

  /// Play a card
  void playCard(GameCard card) {
    if (_currentGameId == null) return;

    _sendMessage({
      'type': 'play_card',
      'gameId': _currentGameId,
      'card': card.toJson(),
    });
  }

  /// Clean up resources
  void dispose() {
    disconnect();
    _gameStateController.close();
    _errorController.close();
    _revealController.close();
  }
}
