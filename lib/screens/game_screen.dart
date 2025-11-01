import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/game_provider.dart';
import '../models/game.dart';
import '../models/card.dart';
import '../widgets/card_widget.dart';

/// Main game screen where the game is played
class GameScreen extends StatelessWidget {
  const GameScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fodinha'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            onPressed: () {
              context.read<GameProvider>().leaveGame();
              Navigator.popUntil(context, (route) => route.isFirst);
            },
          ),
        ],
      ),
      body: Consumer<GameProvider>(
        builder: (context, gameProvider, child) {
          final game = gameProvider.currentGame;

          if (game == null) {
            return const Center(child: CircularProgressIndicator());
          }

          return Column(
            children: [
              _buildGameInfo(game),
              const Divider(),
              Expanded(
                child: Column(
                  children: [
                    Expanded(child: _buildOtherPlayers(game, gameProvider)),
                    _buildTable(game, gameProvider),
                    _buildCurrentPlayerHand(game, gameProvider),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildGameInfo(GameModel game) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.grey[200],
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Column(
            children: [
              const Text('Round', style: TextStyle(fontSize: 12)),
              Text(
                '${game.roundNumber}',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          if (game.trumpCard != null)
            Column(
              children: [
                const Text('Trump', style: TextStyle(fontSize: 12)),
                Text(
                  game.trumpCard.toString(),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          Column(
            children: [
              const Text('State', style: TextStyle(fontSize: 12)),
              Text(
                game.state.name.toUpperCase(),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOtherPlayers(GameModel game, GameProvider provider) {
    final otherPlayers = game.players;
    return ListView.builder(
      itemCount: otherPlayers.length,
      itemBuilder: (context, index) {
        final player = otherPlayers[index];
        final isCurrentPlayer = player.id == provider.currentPlayerId ||
            (provider.currentPlayerId == null && index == game.currentPlayerIndex);

        return Card(
          color: isCurrentPlayer ? Colors.blue[50] : null,
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: isCurrentPlayer ? Colors.blue : Colors.grey,
              child: Text(player.name[0].toUpperCase()),
            ),
            title: Text(
              player.name,
              style: TextStyle(
                fontWeight: isCurrentPlayer ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            subtitle: Text('Score: ${player.score} | Tricks: ${player.tricksWon}'),
            trailing: Text(
              '${player.hand.length} cards',
              style: const TextStyle(fontSize: 16),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTable(GameModel game, GameProvider gameProvider) {
    return Container(
      height: 200,
      color: Colors.green[700],
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (game.currentTrick.isEmpty)
            const Text(
              'Waiting for cards...',
              style: TextStyle(color: Colors.white, fontSize: 18),
            )
          else
            Wrap(
              spacing: 8,
              children: game.currentTrick
                  .map((card) => CardWidget(card: card, size: 80))
                  .toList(),
            ),
          const SizedBox(height: 16),
          if (game.state == GameState.bidding)
            _buildBiddingControls(game, gameProvider),
        ],
      ),
    );
  }

  Widget _buildBiddingControls(GameModel game, GameProvider gameProvider) {
    final currentPlayer = game.players.firstWhere(
      (p) => p.id == gameProvider.currentPlayerId,
      orElse: () => game.currentPlayer,
    );
    final maxBid = currentPlayer.hand.length;
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const Text(
            'Place Your Bid',
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: List.generate(
              maxBid + 1,
              (i) => ElevatedButton(
                onPressed: () => gameProvider.placeBid(i),
                child: Text('$i'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentPlayerHand(GameModel game, GameProvider gameProvider) {
    final currentPlayer = game.players.firstWhere(
      (p) => p.id == gameProvider.currentPlayerId,
      orElse: () => game.currentPlayer,
    );

    return Container(
      height: 150,
      padding: const EdgeInsets.all(8),
      child: Column(
        children: [
          const Text(
            'Your Hand',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: currentPlayer.hand.length,
              itemBuilder: (context, index) {
                final card = currentPlayer.hand[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: GestureDetector(
                    onTap: game.state == GameState.playing
                        ? () => gameProvider.playCard(card)
                        : null,
                    child: CardWidget(
                      card: card,
                      size: 100,
                      isSelectable: game.state == GameState.playing,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
