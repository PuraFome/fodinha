import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/game_provider.dart';
import '../services/localization_provider.dart';
import '../models/game.dart';
// import '../models/card.dart';
import '../widgets/card_widget.dart';

/// Main game screen where the game is played
class GameScreen extends StatelessWidget {
  const GameScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.watch<LocalizationProvider>().t('app.title')),
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
              _buildGameInfo(context, game),
              const Divider(),
              Expanded(
                child: Column(
                  children: [
                    Expanded(child: _buildOtherPlayers(game, gameProvider)),
                    _buildTable(context, game, gameProvider),
                    _buildCurrentPlayerHand(context, game, gameProvider),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildGameInfo(BuildContext context, GameModel game) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.grey[200],
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Column(
            children: [
              Text(context.watch<LocalizationProvider>().t('round'), style: const TextStyle(fontSize: 12)),
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
                Text(context.watch<LocalizationProvider>().t('trump'), style: const TextStyle(fontSize: 12)),
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
              Text(context.watch<LocalizationProvider>().t('state'), style: const TextStyle(fontSize: 12)),
              Builder(builder: (ctx) {
                String stateLabel;
                if (game.state == GameState.playing) {
                  final idx = game.currentPlayerIndex;
                  final playerName = (idx >= 0 && idx < game.players.length) ? game.players[idx].name : '';
                  stateLabel = '$playerName jogando';
                } else {
                  stateLabel = game.state.name.toUpperCase();
                }

                return Text(
                  stateLabel,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                );
              }),
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
            subtitle: Text(
                '${context.watch<LocalizationProvider>().t('score')}: ${player.score} | ${context.watch<LocalizationProvider>().t('tricks')}: ${player.tricksWon}'),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${player.hand.length} ${context.watch<LocalizationProvider>().t('cards')}',
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 4),
                if (game.bids.containsKey(player.id))
                  Text(
                    '${context.watch<LocalizationProvider>().t('button.bid')}: ${game.bids[player.id]}',
                    style: const TextStyle(fontSize: 14, color: Colors.black, fontWeight: FontWeight.bold),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTable(BuildContext context, GameModel game, GameProvider gameProvider) {
    return Container(
      height: 200,
      color: Colors.green[700],
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (game.currentTrick.isEmpty)
            Text(
              context.watch<LocalizationProvider>().t('waitingForCards'),
              style: const TextStyle(color: Colors.white, fontSize: 18),
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
            _buildBiddingControls(context, game, gameProvider),
        ],
      ),
    );
  }

  Widget _buildBiddingControls(BuildContext context, GameModel game, GameProvider gameProvider) {
    final currentPlayer = game.players.firstWhere(
      (p) => p.id == gameProvider.currentPlayerId,
      orElse: () => game.currentPlayer,
    );
    final maxBid = currentPlayer.hand.length;
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Text(
            context.watch<LocalizationProvider>().t('placeYourBid'),
            style: const TextStyle(color: Colors.white, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: List.generate(
              maxBid + 1,
              (i) {
                final localPlayerId = gameProvider.currentPlayerId;
                final isMyTurn = (game.currentBidderIndex != null &&
                    game.currentBidderIndex! >= 0 &&
                    game.currentBidderIndex! < game.players.length &&
                    game.players[game.currentBidderIndex!].id == localPlayerId);

                // Determine if this is the last bidder who still has to bet
                final bidsCount = game.bids.length;
                final playersCount = game.players.length;
                final amILastToBet = localPlayerId != null &&
                    bidsCount == playersCount - 1 &&
                    !game.bids.containsKey(localPlayerId);

                // Total cards per player (e.g., 10). Using current player's hand length.
                final totalCards = maxBid;
                final existingSum = game.bids.values.fold<int>(0, (a, b) => a + b);

                // If I'm the last bidder, disallow any bid 'i' that would make
                // existingSum + i == totalCards (closing the total number of cards).
                // Also respect any client-side locked forbidden numbers (they remain
                // disabled even after placing a different bid).
                final disabledByLastRule = amILastToBet && (existingSum + i == totalCards);
                final lockedForbidden = gameProvider.lockedForbidden.contains(i);

                // Also disable if it's not my turn to bet (prevent clicking out of turn)
                final disabledByTurn = !isMyTurn;

                final disabled = disabledByLastRule || lockedForbidden || disabledByTurn;

                return ElevatedButton(
                  onPressed: disabled ? null : () => gameProvider.placeBid(i),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: disabledByLastRule || lockedForbidden ? Colors.red : null,
                  ),
                  child: Text('$i'),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          // Confirm button area: only the current bidder (server-controlled) may confirm
          Builder(builder: (ctx) {
            final localPlayerId = gameProvider.currentPlayerId;
            final isMyTurn = (game.currentBidderIndex != null &&
                game.currentBidderIndex! >= 0 &&
                game.currentBidderIndex! < game.players.length &&
                game.players[game.currentBidderIndex!].id == localPlayerId);
            final hasBid = localPlayerId != null && game.bids.containsKey(localPlayerId);
            final confirmed = localPlayerId != null && (game.bidConfirmed[localPlayerId] == true);

            if (game.state == GameState.bidding && isMyTurn && hasBid && !confirmed) {
              return ElevatedButton(
                onPressed: () => gameProvider.confirmBid(),
                child: Text(context.watch<LocalizationProvider>().t('button.confirm')),
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(12)),
              );
            } else if (hasBid && confirmed) {
              return Text(
                context.watch<LocalizationProvider>().t('button.confirm'),
                style: const TextStyle(color: Colors.green),
              );
            } else if (isMyTurn && !hasBid) {
              // Prompt to place a bid first
              return Text(
                context.watch<LocalizationProvider>().t('placeYourBid'),
                style: const TextStyle(color: Colors.white70),
              );
            }

            return const SizedBox.shrink();
          }),
        ],
      ),
    );
  }

  Widget _buildCurrentPlayerHand(BuildContext context, GameModel game, GameProvider gameProvider) {
    final currentPlayer = game.players.firstWhere(
      (p) => p.id == gameProvider.currentPlayerId,
      orElse: () => game.currentPlayer,
    );

    return Container(
      height: 150,
      padding: const EdgeInsets.all(8),
      child: Column(
        children: [
          Text(
            context.watch<LocalizationProvider>().t('yourHand'),
            style: const TextStyle(fontWeight: FontWeight.bold),
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
