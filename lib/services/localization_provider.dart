import 'package:flutter/foundation.dart';

/// Simple localization provider supporting Portuguese (pt) and English (en).
class LocalizationProvider extends ChangeNotifier {
  bool _isEnglish = false; // default Português

  bool get isEnglish => _isEnglish;

  void toggleLanguage() {
    _isEnglish = !_isEnglish;
    notifyListeners();
  }

  String t(String key) {
    return _isEnglish ? _en[key] ?? key : _pt[key] ?? key;
  }

  static const Map<String, String> _pt = {
    'app.title': 'Fodinha',
    'home.subtitle': 'Jogo de cartas multiplayer',
    'label.yourName': 'Seu nome',
    'label.serverUrl': 'URL do servidor',
    'section.create': 'Criar nova partida',
    'label.maxPlayers': 'Máx. de jogadores',
    'button.create': 'Criar partida',
    'section.join': 'Entrar em partida existente',
    'label.gameId': 'ID da partida',
    'button.join': 'Entrar na partida',
  'error.enterName': 'Por favor informe seu nome',
  'error.failedConnect': 'Falha ao conectar ao servidor',
  'error.enterGameId': 'Por favor informe o ID da partida',
    'lobby.title': 'Sala de Jogo',
    'copiedGameId': 'ID da partida copiado para a área de transferência',
  'dealer': 'Anfitrião',
    'notReady': 'Não pronto',
    'ready': 'Pronto',
    'startGame': 'Iniciar partida',
    'leaveGame': 'Sair da partida',
    'waitingForCards': 'Aguardando cartas...',
    'round': 'Rodada',
    'trump': 'Vira',
    'state': 'Estado',
    'placeYourBid': 'Faça sua aposta',
    'yourHand': 'Sua mão',
    'button.bid': 'Apostar',
    'button.confirm': 'Confirmar',
    'players': 'Jogadores',
    'cards': 'cartas',
    'score': 'Pontuação',
    'tricks': 'Truques',
  };

  static const Map<String, String> _en = {
    'app.title': 'Fodinha',
    'home.subtitle': 'Multiplayer Card Game',
    'label.yourName': 'Your Name',
    'label.serverUrl': 'Server URL',
    'section.create': 'Create New Game',
    'label.maxPlayers': 'Max Players',
    'button.create': 'Create Game',
    'section.join': 'Join Existing Game',
    'label.gameId': 'Game ID',
    'button.join': 'Join Game',
  'error.enterName': 'Please enter your name',
  'error.failedConnect': 'Failed to connect to server',
  'error.enterGameId': 'Please enter game ID',
    'lobby.title': 'Game Lobby',
    'copiedGameId': 'Game ID copied to clipboard',
    'dealer': 'Dealer',
    'notReady': 'Not Ready',
    'ready': 'Ready',
    'startGame': 'Start Game',
    'leaveGame': 'Leave Game',
    'waitingForCards': 'Waiting for cards...',
    'round': 'Round',
    'trump': 'Trump',
    'state': 'State',
    'placeYourBid': 'Place Your Bid',
    'yourHand': 'Your Hand',
    'button.bid': 'Bid',
    'button.confirm': 'Confirm',
    'players': 'Players',
    'cards': 'cards',
    'score': 'Score',
    'tricks': 'Tricks',
  };
}
