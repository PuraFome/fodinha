import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../services/game_provider.dart';
import '../services/localization_provider.dart';
import '../models/game.dart';
import 'game_screen.dart';

/// Lobby screen where players wait before game starts
class LobbyScreen extends StatelessWidget {
  const LobbyScreen({super.key});

  void _copyGameId(BuildContext context, String gameId) {
    Clipboard.setData(ClipboardData(text: gameId));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.read<LocalizationProvider>().t('copiedGameId'))),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.watch<LocalizationProvider>().t('lobby.title')),
        centerTitle: true,
      ),
      body: Consumer<GameProvider>(
        builder: (context, gameProvider, child) {
          final game = gameProvider.currentGame;

          if (game == null) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          // Navigate to game screen when game starts
          if (game.state == GameState.bidding || 
              game.state == GameState.playing) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const GameScreen()),
              );
            });
          }

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Text(
                          context.watch<LocalizationProvider>().t('label.gameId'),
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              game.id,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 2,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.copy),
                              onPressed: () => _copyGameId(context, game.id),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  '${context.watch<LocalizationProvider>().t('players')} (${game.players.length}/${game.maxPlayers})',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: ListView.builder(
                    itemCount: game.players.length,
                    itemBuilder: (context, index) {
                      final player = game.players[index];
                      return Card(
                        child: ListTile(
                          leading: CircleAvatar(
                            child: Text(
                              player.name[0].toUpperCase(),
                            ),
                          ),
                          title: Text(player.name),
              subtitle: player.isDealer
                ? Text(context.watch<LocalizationProvider>().t('dealer'))
                : null,
                          trailing: player.isReady
                              ? const Icon(
                                  Icons.check_circle,
                                  color: Colors.green,
                                )
                              : const Icon(
                                  Icons.schedule,
                                  color: Colors.orange,
                                ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
                if (game.players.length >= 2)
                  ElevatedButton(
                    onPressed: () {
                      // Toggle ready status
                      final currentPlayer = game.players.firstWhere(
                        (p) => p.id == gameProvider.currentPlayerId,
                        orElse: () => game.players.first,
                      );
                      gameProvider.setReady(!currentPlayer.isReady);
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.all(16),
                    ),
                    child: Consumer<GameProvider>(
                      builder: (context, provider, _) {
                        final currentPlayer = game.players.firstWhere(
                          (p) => p.id == provider.currentPlayerId,
                          orElse: () => game.players.first,
                        );
                        return Text(
                          currentPlayer.isReady
                              ? context.watch<LocalizationProvider>().t('notReady')
                              : context.watch<LocalizationProvider>().t('ready'),
                          style: const TextStyle(fontSize: 16),
                        );
                      },
                    ),
                  ),
                if (game.canStartGame())
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: ElevatedButton(
                      onPressed: () => gameProvider.startGame(),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.all(16),
                        backgroundColor: Colors.green,
                      ),
                      child: Text(
                        context.watch<LocalizationProvider>().t('startGame'),
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: () {
                    gameProvider.leaveGame();
                    Navigator.pop(context);
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.all(16),
                  ),
                  child: Text(
                    context.watch<LocalizationProvider>().t('leaveGame'),
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
