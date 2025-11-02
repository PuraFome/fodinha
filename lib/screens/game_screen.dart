import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/game_provider.dart';
import '../services/localization_provider.dart';
import '../models/game.dart';
import '../models/card.dart';
import '../models/player.dart';
import '../widgets/card_widget.dart';

/// Main game screen where the game is played
class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  // Tracks which players have their profile expanded
  final Map<String, bool> _expandedPlayers = {};
  // Compact players bar is always visible; no global collapse state needed

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
      body: Container(
        // Use the provided room image as the background for the game screen
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/sala.jpg'),
            fit: BoxFit.cover,
          ),
        ),
        child: Consumer<GameProvider>(
          builder: (context, gameProvider, child) {
            final game = gameProvider.currentGame;

            if (game == null) {
              return const Center(child: CircularProgressIndicator());
            }

            // Make content background semi-transparent so the room image shows
            return Column(
              children: [
                _buildGameInfo(context, game),
                const Divider(),
                Expanded(
                  child: Column(
                    children: [
                      // Show compact tiles bar (small cards with name, #cards and score)
                      SizedBox(
                        height: 140,
                        child: _buildCompactTilesBar(game, gameProvider),
                      ),
                      // Make table and hand flexible so they share remaining space
                      Expanded(
                        flex: 3,
                        child: Container(
                          color: Colors.transparent,
                          child: _buildTable(context, game, gameProvider),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: _buildCurrentPlayerHand(context, game, gameProvider),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
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
                  String playerName = '';
                  if (idx >= 0 && idx < game.players.length) {
                    playerName = game.players[idx].name;
                  }
                  stateLabel = '$playerName jogando';
                } else if (game.state == GameState.bidding) {
                  final idx = game.currentBidderIndex;
                  String playerName = '';
                  if (idx != null && idx >= 0 && idx < game.players.length) {
                    playerName = game.players[idx].name;
                  }
                  stateLabel = '$playerName apostando';
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

  // keep full list builder available for future use (not used by default now)
  // ignore: unused_element
  Widget _buildOtherPlayers(GameModel game, GameProvider provider) {
    final otherPlayers = game.players;
    return ListView.builder(
      itemCount: otherPlayers.length,
      itemBuilder: (context, index) {
        final player = otherPlayers[index];
        final isCurrentPlayer = player.id == provider.currentPlayerId ||
            (provider.currentPlayerId == null && index == game.currentPlayerIndex);

        final expanded = _expandedPlayers[player.id] ?? false;

        return Card(
          color: isCurrentPlayer ? Colors.blue[50] : null,
          child: Column(
            children: [
              ListTile(
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
                // compact when collapsed; full details shown in the expanding area below
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    IconButton(
                      icon: Icon(expanded ? Icons.expand_less : Icons.expand_more),
                      onPressed: () {
                        setState(() {
                          _expandedPlayers[player.id] = !expanded;
                        });
                      },
                    ),
                    const SizedBox(height: 4),
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
              // Animated expansion area with details (score, tricks, preview card)
              AnimatedCrossFade(
                duration: const Duration(milliseconds: 200),
                firstChild: const SizedBox.shrink(),
                secondChild: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${context.watch<LocalizationProvider>().t('score')}: ${player.score} | ${context.watch<LocalizationProvider>().t('tricks')}: ${player.tricksWon}',
                      ),
                      const SizedBox(height: 6),
                      // During round 1 nobody may see their OWN cards, but may
                      // see other players' cards. From round 2 on, everyone
                      // sees their own hand as usual.
                      if (player.hand.isNotEmpty && !(game.roundNumber == 1 && player.id == provider.currentPlayerId))
                        SizedBox(
                          height: 60,
                          child: CardWidget(card: player.hand[0], size: 60),
                        ),
                    ],
                  ),
                ),
                crossFadeState: expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCompactTilesBar(GameModel game, GameProvider provider) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      scrollDirection: Axis.horizontal,
      itemCount: game.players.length,
      separatorBuilder: (_, __) => const SizedBox(width: 12),
      itemBuilder: (context, index) {
        final player = game.players[index];
        final isCurrentPlayer = player.id == provider.currentPlayerId ||
            (provider.currentPlayerId == null && index == game.currentPlayerIndex);

        return SizedBox(
          width: 220,
          child: Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            color: isCurrentPlayer ? Colors.blue[50] : Colors.white,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: isCurrentPlayer ? Colors.blue : Colors.grey,
                        child: Text(player.name.isNotEmpty ? player.name[0].toUpperCase() : '?', style: const TextStyle(fontSize: 14)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          player.name,
                          style: TextStyle(fontSize: 16, fontWeight: isCurrentPlayer ? FontWeight.bold : FontWeight.w600),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // Always show counts and score; never show card face in round 1
                  Text('${player.hand.length} ${context.watch<LocalizationProvider>().t('cards')}', style: const TextStyle(fontSize: 14)),
                  const SizedBox(height: 6),
                  Text('${context.watch<LocalizationProvider>().t('score')}: ${player.score}', style: const TextStyle(fontSize: 14)),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTable(BuildContext context, GameModel game, GameProvider gameProvider) {
    // Use the expanded height provided by the parent. Make the image the
    // background of this container and use BoxFit.contain so the full image
    // scales to fit inside the container without being cropped.
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/images/mesa.png'),
          fit: BoxFit.contain,
          alignment: Alignment.center,
        ),
      ),
      // Overlay container to improve contrast for white text and card borders
      child: Container(
        color: Colors.black26,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
          if (gameProvider.revealData != null) ...[
            // Show reveal inside the green table area
            Builder(builder: (ctx) {
              final rev = gameProvider.revealData!;
              final entries = (rev['entries'] as List).cast<dynamic>();
              final winnerId = rev['winnerId'];
              return Column(
                children: [
                    Wrap(
                    spacing: 12,
                    alignment: WrapAlignment.center,
                    children: entries.map((e) {
                      final pid = e['playerId'] as String;
                      final cardJson = Map<String, dynamic>.from(e['card']);
                      final card = GameCard.fromJson(cardJson);
                      final player = game.players.firstWhere((p) => p.id == pid, orElse: () => Player(id: pid, name: 'Player', hand: []));
                      // prefer a name provided by the server in the reveal entry
                      final name = (e['playerName'] as String?) ?? player.name;
                      final isWinner = (winnerId != null && winnerId == pid);
                      return Column(
                        children: [
                          Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 6),
                          Container(
                            decoration: BoxDecoration(
                              border: Border.all(color: isWinner ? Colors.red : Colors.transparent, width: isWinner ? 3 : 0),
                            ),
                            child: CardWidget(card: card, size: 100),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ],
              );
            }),
          ] else if (game.currentTrick.isEmpty)
            Text(
              context.watch<LocalizationProvider>().t('waitingForCards'),
              style: const TextStyle(color: Colors.white, fontSize: 18),
            )
          else
            Wrap(
              spacing: 8,
              children: game.currentTrick
                  .map((card) => CardWidget(card: card, size: 100))
                  .toList(),
            ),
          const SizedBox(height: 16),
          if (game.state == GameState.bidding)
            _buildBiddingControls(context, game, gameProvider),
        ],
      ),
    ),
  );
}

  Widget _buildBiddingControls(BuildContext context, GameModel game, GameProvider gameProvider) {
    // Calculate cards per round (1..10..1) from roundNumber so bidding range
    // doesn't depend on the public visibility of the local hand (round 1 hides it).
    final roundNum = game.roundNumber;
    final cardsPerRound = (roundNum <= 10) ? roundNum : (20 - roundNum + 1);
    final maxBid = cardsPerRound;
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

                final totalCards = maxBid;
                final existingSum = game.bids.values.fold<int>(0, (a, b) => a + b);

                final disabledByLastRule = amILastToBet && (existingSum + i == totalCards);
                final lockedForbidden = gameProvider.lockedForbidden.contains(i);
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
      padding: const EdgeInsets.all(8),
      child: Column(
        children: [
          Text(
            game.roundNumber == 1
                ? context.watch<LocalizationProvider>().t('opponentsHand')
                : context.watch<LocalizationProvider>().t('yourHand'),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          // Center the player's hand horizontally and increase card size
          Expanded(
            child: Builder(builder: (ctx) {
              // Special case for round 1: each player should NOT see their
              // own cards, but should see the other players' hands. So when
              // roundNumber == 1 show the opponents' hands here (scrollable).
              if (game.roundNumber == 1) {
                // Constrain the opponents view to a fixed height to avoid
                // bottom overflow on small screens. Use smaller card size so
                // multiple opponent hands fit comfortably.
                final otherPlayers = game.players.where((p) => p.id != gameProvider.currentPlayerId).toList();
                return SizedBox(
                  // reduced by 11px per request (was 140)
                  height: 129,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: otherPlayers.map((p) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                width: 69,
                                child: Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white), textAlign: TextAlign.center, overflow: TextOverflow.ellipsis),
                              ),
                              const SizedBox(height: 6),
                              SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  children: List.generate(p.hand.length, (i) {
                                    final card = p.hand[i];
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                                      child: CardWidget(card: card, size: 69),
                                    );
                                  }),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                );
              }

              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(currentPlayer.hand.length, (index) {
                    final card = currentPlayer.hand[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: GestureDetector(
                        onTap: game.state == GameState.playing
                            ? () => gameProvider.playCard(card)
                            : null,
                        child: CardWidget(
                          card: card,
                          size: 140,
                          isSelectable: game.state == GameState.playing,
                        ),
                      ),
                    );
                  }),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  
}
