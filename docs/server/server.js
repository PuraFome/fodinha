const http = require('http');
const WebSocket = require('ws');
const { v4: uuidv4 } = require('uuid');

// Create HTTP server and attach WebSocket server (helps platforms that expect HTTP health)
const PORT = process.env.PORT || 8080;

const server = http.createServer((req, res) => {
  // Basic health/info endpoint for Render/Heroku etc.
  if (req.method === 'GET') {
    res.writeHead(200, { 'Content-Type': 'text/plain' });
    res.end('Fodinha WebSocket server is running. Use a WebSocket client (wss/ws).');
  } else {
    res.writeHead(405);
    res.end();
  }
});

// Bind to 0.0.0.0 for container environments and share the same HTTP server
const wss = new WebSocket.Server({ server });
server.listen(PORT, '0.0.0.0', () => {
  console.log(`Fodinha WebSocket Server running on ws://0.0.0.0:${PORT}`);
});

// Store active games
const games = new Map();
// Map client WebSocket to player info
const clients = new Map();

// Note: main log moved to server.listen callback above

wss.on('connection', (ws) => {
  console.log('New client connected');
  
  const playerId = uuidv4();
  clients.set(ws, { playerId, gameId: null });

  ws.on('message', (message) => {
    try {
      const data = JSON.parse(message.toString());
      console.log('Received:', data.type, data);
      
      handleMessage(ws, data);
    } catch (error) {
      console.error('Error handling message:', error);
      sendError(ws, 'Invalid message format');
    }
  });

  ws.on('close', () => {
    console.log('Client disconnected');
    handleDisconnect(ws);
  });

  ws.on('error', (error) => {
    console.error('WebSocket error:', error);
  });
});

function handleMessage(ws, data) {
  const client = clients.get(ws);
  
  switch (data.type) {
    case 'create_game':
      handleCreateGame(ws, client, data);
      break;
    case 'join_game':
      handleJoinGame(ws, client, data);
      break;
    case 'leave_game':
      handleLeaveGame(ws, client);
      break;
    case 'set_ready':
      handleSetReady(ws, client, data);
      break;
    case 'start_game':
      handleStartGame(ws, client);
      break;
    case 'place_bid':
      handlePlaceBid(ws, client, data);
      break;
    case 'confirm_bid':
      handleConfirmBid(ws, client, data);
      break;
    case 'play_card':
      handlePlayCard(ws, client, data);
      break;
    default:
      sendError(ws, 'Unknown message type');
  }
}

function handleCreateGame(ws, client, data) {
  const gameId = uuidv4().substring(0, 8).toUpperCase();
  
  const game = {
    id: gameId,
    players: [{
      id: client.playerId,
      name: data.playerName,
      hand: [],
      tricksWon: 0,
      score: 0,
      isReady: false,
      isDealer: true
    }],
    state: 'waiting',
    currentPlayerIndex: 0,
    dealerIndex: 0,
    roundNumber: 1,
    trumpCard: null,
  currentTrick: [],
  playerIdsInTrick: [],
  trickStarterIndex: null,
    // index of the player who started bidding this round (helps rotate starter)
    bidStarterIndex: null,
    bids: {},
    bidConfirmed: {},
    currentBidderIndex: null,
    maxPlayers: data.maxPlayers || 4
  };
  
  games.set(gameId, game);
  client.gameId = gameId;
  
  console.log(`Game ${gameId} created by ${data.playerName}`);
  sendGameState(gameId);
}

function handleJoinGame(ws, client, data) {
  const game = games.get(data.gameId);
  
  if (!game) {
    sendError(ws, 'Game not found');
    return;
  }
  
  if (game.state !== 'waiting') {
    sendError(ws, 'Game already started');
    return;
  }
  
  if (game.players.length >= game.maxPlayers) {
    sendError(ws, 'Game is full');
    return;
  }
  
  game.players.push({
    id: client.playerId,
    name: data.playerName,
    hand: [],
    tricksWon: 0,
    score: 0,
    isReady: false,
    isDealer: false
  });
  
  client.gameId = data.gameId;
  
  console.log(`${data.playerName} joined game ${data.gameId}`);
  sendGameState(data.gameId);
}

function handleLeaveGame(ws, client) {
  if (!client.gameId) return;
  
  const game = games.get(client.gameId);
  if (!game) return;
  
  game.players = game.players.filter(p => p.id !== client.playerId);
  
  if (game.players.length === 0) {
    games.delete(client.gameId);
    console.log(`Game ${client.gameId} deleted (no players)`);
  } else {
    sendGameState(client.gameId);
  }
  
  client.gameId = null;
}

function handleSetReady(ws, client, data) {
  const game = games.get(client.gameId);
  if (!game) return;
  
  const player = game.players.find(p => p.id === client.playerId);
  if (player) {
    player.isReady = data.ready;
    sendGameState(client.gameId);
  }
}

function handleStartGame(ws, client) {
  const game = games.get(client.gameId);
  if (!game) return;
  
  if (game.players.length < 2) {
    sendError(ws, 'Need at least 2 players');
    return;
  }
  
  if (!game.players.every(p => p.isReady)) {
    sendError(ws, 'Not all players are ready');
    return;
  }

  // Prepare a deck and set up the first round based on roundNumber
  const suits = ['hearts', 'diamonds', 'clubs', 'spades'];
  const ranks = ['four','five','six','seven','queen','jack','king','ace','two','three'];

  // Build deck
  let deck = [];
  for (const suit of suits) {
    for (const rank of ranks) {
      deck.push({ suit, rank });
    }
  }

  // Shuffle deck
  for (let i = deck.length - 1; i > 0; i--) {
    const j = Math.floor(Math.random() * (i + 1));
    [deck[i], deck[j]] = [deck[j], deck[i]];
  }

  // Start at round 1
  game.roundNumber = 1;

  // Helper to compute cards per round (1..10..1)
  const cardsForRound = (roundNum) => {
    if (roundNum <= 10) return roundNum;
    return 20 - roundNum + 1;
  };

  const cardsPerPlayer = cardsForRound(game.roundNumber);

  // Deal
  for (const player of game.players) {
    player.hand = [];
    for (let c = 0; c < cardsPerPlayer && deck.length > 0; c++) {
      player.hand.push(deck.pop());
    }
  }

  // Set trump card (next card from deck if available)
  game.trumpCard = deck.length > 0 ? deck.pop() : null;

  // Initialize bidding state
  game.bids = {};
  game.bidConfirmed = {};
  // Choose a randomized starter for bidding for this new game
  game.bidStarterIndex = Math.floor(Math.random() * game.players.length);
  game.currentBidderIndex = game.bidStarterIndex;

  game.state = 'bidding';
  console.log(`Game ${client.gameId} started and cards dealt for round ${game.roundNumber}`);

  sendGameState(client.gameId);
}

function handleConfirmBid(ws, client, data) {
  const game = games.get(client.gameId);
  if (!game || game.state !== 'bidding') return;

  // Only current bidder may confirm
  const currentBidderIdx = game.currentBidderIndex;
  if (currentBidderIdx == null) return;
  const currentBidderId = game.players[currentBidderIdx].id;
  if (client.playerId !== currentBidderId) return;

  // mark confirmed only if bid exists
  if (game.bids.hasOwnProperty(client.playerId)) {
    game.bidConfirmed[client.playerId] = true;

    // find next unconfirmed player
    let next = (currentBidderIdx + 1) % game.players.length;
    let found = false;
    for (let i = 0; i < game.players.length; i++) {
      const idx = (currentBidderIdx + 1 + i) % game.players.length;
      const pid = game.players[idx].id;
      if (!game.bidConfirmed[pid]) {
        next = idx;
        found = true;
        break;
      }
    }

    if (found) {
      game.currentBidderIndex = next;
    } else {
      // all confirmed -> start playing
      game.state = 'playing';
      // first player to play is the one after the dealer
      game.currentPlayerIndex = (game.dealerIndex + 1) % game.players.length;
      game.currentBidderIndex = null;
      game.currentTrick = [];
      game.playerIdsInTrick = [];
      game.trickStarterIndex = null;

      // Special-case: if this round uses only 1 card per player (round 1 and similar),
      // auto-play all players' top card immediately and reveal the result.
      const cardsForRound = (roundNum) => {
        if (roundNum <= 10) return roundNum;
        return 20 - roundNum + 1;
      };
      const cardsThisRound = cardsForRound(game.roundNumber || 1);
      if (cardsThisRound === 1) {
        // Auto-play each player's first card starting from currentPlayerIndex
        for (let i = 0; i < game.players.length; i++) {
          const idx = (game.currentPlayerIndex + i) % game.players.length;
          const p = game.players[idx];
          if (p.hand && p.hand.length > 0) {
            const played = p.hand.shift();
            game.currentTrick.push(played);
            game.playerIdsInTrick.push(p.id);
            // if this was the first card, record the starter
            if (game.currentTrick.length === 1) {
              game.trickStarterIndex = idx;
            }
          }
        }

        // Evaluate trick winner using rank order and annul-on-tie as in handlePlayCard
        const ranks = ['four','five','six','seven','queen','jack','king','ace','two','three'];
        let entries = game.currentTrick.map((c, idx) => ({
          card: c,
          playerId: game.playerIdsInTrick[idx],
          rankIndex: ranks.indexOf(c.rank)
        }));

        let winnerPlayerId = null;
        while (entries.length > 0) {
          let maxRank = Math.max(...entries.map(e => e.rankIndex));
          const top = entries.filter(e => e.rankIndex === maxRank);
          if (top.length === 1) {
            winnerPlayerId = top[0].playerId;
            break;
          } else {
            const topIds = new Set(top.map(t => t.playerId));
            entries = entries.filter(e => !topIds.has(e.playerId));
          }
        }

        if (winnerPlayerId) {
          const winnerIdx = game.players.findIndex(p => p.id === winnerPlayerId);
          if (winnerIdx !== -1) {
            game.players[winnerIdx].tricksWon = (game.players[winnerIdx].tricksWon || 0) + 1;
            game.currentPlayerIndex = winnerIdx;
          }
        } else {
          if (game.trickStarterIndex != null) {
            game.currentPlayerIndex = (game.trickStarterIndex + 1) % game.players.length;
          }
        }

        const revealEntries = game.currentTrick.map((c, idx) => ({
          playerId: game.playerIdsInTrick[idx],
          playerName: (game.players.find(p => p.id === game.playerIdsInTrick[idx]) || {}).name || 'Player',
          card: c
        }));

        // Clear trick storage
        game.currentTrick = [];
        game.playerIdsInTrick = [];
        game.trickStarterIndex = null;

        // Send reveal immediately to all sockets in this game
        const revealMsg = {
          type: 'reveal',
          reveal: {
            entries: revealEntries,
            winnerId: winnerPlayerId || null,
            roundNumber: game.roundNumber,
            duration: 10
          }
        };

        wss.clients.forEach(socket => {
          const clientInfo = clients.get(socket);
          if (clientInfo && clientInfo.gameId === game.id && socket.readyState === WebSocket.OPEN) {
            socket.send(JSON.stringify(revealMsg));
          }
        });

        // After 10 seconds, apply scoring and advance to next round (reuse logic used elsewhere)
        setTimeout(() => {
          for (const p of game.players) {
            const pid = p.id;
            const bid = game.bids[pid] || 0;
            const tricks = p.tricksWon || 0;
            if (tricks !== bid) {
              p.score = (p.score || 0) + 1;
            }
            p.tricksWon = 0;
          }

          // Advance round
          game.roundNumber = (game.roundNumber || 1) + 1;
          const cardsForRoundNext = (roundNum) => {
            if (roundNum <= 10) return roundNum;
            return 20 - roundNum + 1;
          };
          const cardsPerPlayerNext = cardsForRoundNext(game.roundNumber);

          // Rebuild deck and deal next round
          let newDeck = [];
          for (const suit of ['hearts','diamonds','clubs','spades']) {
            for (const rank of ['four','five','six','seven','queen','jack','king','ace','two','three']) {
              newDeck.push({ suit, rank });
            }
          }
          for (let i = newDeck.length - 1; i > 0; i--) {
            const j = Math.floor(Math.random() * (i + 1));
            [newDeck[i], newDeck[j]] = [newDeck[j], newDeck[i]];
          }

          for (const p of game.players) {
            p.hand = [];
            for (let c = 0; c < cardsPerPlayerNext && newDeck.length > 0; c++) {
              p.hand.push(newDeck.pop());
            }
            p.tricksWon = 0;
          }

          game.trumpCard = newDeck.length > 0 ? newDeck.pop() : null;
          game.bids = {};
          game.bidConfirmed = {};
          // Advance the bidStarterIndex by one for the next round (if defined),
          // otherwise fall back to player after dealer for backward compatibility.
          if (game.bidStarterIndex != null) {
            game.bidStarterIndex = (game.bidStarterIndex + 1) % game.players.length;
          } else {
            game.bidStarterIndex = (game.dealerIndex + 1) % game.players.length;
          }
          game.currentBidderIndex = game.bidStarterIndex;
          game.state = 'bidding';

          // Send updated game state after advancing
          sendGameState(game.id);
        }, 10000);
      }
    }

    sendGameState(client.gameId);
  }
}

function handlePlaceBid(ws, client, data) {
  const game = games.get(client.gameId);
  if (!game || game.state !== 'bidding') return;

  // Enforce turn: only current bidder can place bid
  const currentIdx = game.currentBidderIndex;
  if (currentIdx == null) return;
  const expectedPid = game.players[currentIdx].id;
  if (client.playerId !== expectedPid) return;

  game.bids[client.playerId] = data.bid;
  // reset any previous confirmation for safety
  game.bidConfirmed[client.playerId] = false;

  sendGameState(client.gameId);
}

function handlePlayCard(ws, client, data) {
  const game = games.get(client.gameId);
  if (!game || game.state !== 'playing') return;
  
  const player = game.players.find(p => p.id === client.playerId);
  if (!player) return;
  
  // Enforce turn: only current player may play
  const currentIdx = game.currentPlayerIndex;
  if (currentIdx == null) return;
  const expectedPid = game.players[currentIdx].id;
  if (client.playerId !== expectedPid) return;

  // Validate the card exists in player's hand (match suit+rank)
  const card = data.card;
  const cardIdx = player.hand.findIndex(c => c.suit === card.suit && c.rank === card.rank);
  if (cardIdx === -1) return; // player doesn't have this card

  // Remove card from player's hand and add to current trick
  const playedCard = player.hand.splice(cardIdx, 1)[0];
  game.currentTrick.push(playedCard);
  game.playerIdsInTrick.push(client.playerId);

  // If this was the first card of the trick, record who started
  if (game.currentTrick.length === 1) {
    game.trickStarterIndex = currentIdx;
  }

  // Advance to next player (circular)
  game.currentPlayerIndex = (currentIdx + 1) % game.players.length;

  // If everyone has played, evaluate trick
  if (game.currentTrick.length >= game.players.length) {
    // Determine winner using rank order; in case of ties, tied cards annul and we consider remaining
    const ranks = ['four','five','six','seven','queen','jack','king','ace','two','three'];

    // Prepare list of entries
    let entries = game.currentTrick.map((c, idx) => ({
      card: c,
      playerId: game.playerIdsInTrick[idx],
      rankIndex: ranks.indexOf(c.rank)
    }));

    let winnerPlayerId = null;

    while (entries.length > 0) {
      // find highest rankIndex among remaining
      let maxRank = Math.max(...entries.map(e => e.rankIndex));
      const top = entries.filter(e => e.rankIndex === maxRank);

      if (top.length === 1) {
        winnerPlayerId = top[0].playerId;
        break;
      } else {
        // annul all top entries and continue
        const topIds = new Set(top.map(t => t.playerId));
        entries = entries.filter(e => !topIds.has(e.playerId));
      }
    }

    if (winnerPlayerId) {
      const winnerIdx = game.players.findIndex(p => p.id === winnerPlayerId);
      if (winnerIdx !== -1) {
        game.players[winnerIdx].tricksWon = (game.players[winnerIdx].tricksWon || 0) + 1;
        // next trick starter is the winner
        game.currentPlayerIndex = winnerIdx;
      }
    } else {
      // No winner (fully annulled) -> move starter to next player after trick starter
      if (game.trickStarterIndex != null) {
        game.currentPlayerIndex = (game.trickStarterIndex + 1) % game.players.length;
      }
    }

    // Prepare reveal info for this trick (before clearing)
    const revealEntries = game.currentTrick.map((c, idx) => ({
      playerId: game.playerIdsInTrick[idx],
      // include player name for convenience on client side
      playerName: (game.players.find(p => p.id === game.playerIdsInTrick[idx]) || {}).name || 'Player',
      card: c
    }));

    // Clear trick
    game.currentTrick = [];
    game.playerIdsInTrick = [];
    game.trickStarterIndex = null;

    // Check if round is over (players have no cards)
    const anyCardsLeft = game.players.some(p => p.hand && p.hand.length > 0);
    if (!anyCardsLeft) {
      // Reveal the trick to all clients and highlight the winning card for 10s
      const revealMsg = {
        type: 'reveal',
        reveal: {
          entries: revealEntries,
          winnerId: winnerPlayerId || null,
          roundNumber: game.roundNumber
        }
      };

      // Send reveal immediately to all sockets in this game
      wss.clients.forEach(socket => {
        const clientInfo = clients.get(socket);
        if (clientInfo && clientInfo.gameId === game.id && socket.readyState === WebSocket.OPEN) {
          socket.send(JSON.stringify(revealMsg));
        }
      });

      // After 10 seconds, apply scoring for this round and advance to the next
      setTimeout(() => {
        // Simple scoring: award a point (increment score) to players who missed their bid
        for (const p of game.players) {
          const pid = p.id;
          const bid = game.bids[pid] || 0;
          const tricks = p.tricksWon || 0;
          if (tricks !== bid) {
            p.score = (p.score || 0) + 1; // mark a point for missing the bid
          }
          // reset tricks for next round
          p.tricksWon = 0;
        }

        // Advance to next round
        game.roundNumber = (game.roundNumber || 1) + 1;
        // compute cards per round
        const cardsForRound = (roundNum) => {
          if (roundNum <= 10) return roundNum;
          return 20 - roundNum + 1;
        };
        const cardsPerPlayerNext = cardsForRound(game.roundNumber);

        // Rebuild deck and deal next round
        let newDeck = [];
        for (const suit of ['hearts','diamonds','clubs','spades']) {
          for (const rank of ['four','five','six','seven','queen','jack','king','ace','two','three']) {
            newDeck.push({ suit, rank });
          }
        }
        for (let i = newDeck.length - 1; i > 0; i--) {
          const j = Math.floor(Math.random() * (i + 1));
          [newDeck[i], newDeck[j]] = [newDeck[j], newDeck[i]];
        }

        for (const p of game.players) {
          p.hand = [];
          for (let c = 0; c < cardsPerPlayerNext && newDeck.length > 0; c++) {
            p.hand.push(newDeck.pop());
          }
          p.tricksWon = 0;
        }

        game.trumpCard = newDeck.length > 0 ? newDeck.pop() : null;
        game.bids = {};
        game.bidConfirmed = {};
        // Advance the bidStarterIndex by one for the next round (if defined),
        // otherwise fall back to player after dealer for backward compatibility.
        if (game.bidStarterIndex != null) {
          game.bidStarterIndex = (game.bidStarterIndex + 1) % game.players.length;
        } else {
          game.bidStarterIndex = (game.dealerIndex + 1) % game.players.length;
        }
        game.currentBidderIndex = game.bidStarterIndex;
        game.state = 'bidding';

  // Send updated game state after advancing
  sendGameState(game.id);
      }, 10000);
    }
  }

  sendGameState(client.gameId);
}

function handleDisconnect(ws) {
  const client = clients.get(ws);
  if (client) {
    handleLeaveGame(ws, client);
    clients.delete(ws);
  }
}

function sendGameState(gameId) {
  const game = games.get(gameId);
  if (!game) return;
  
  // Send to all clients in this game. Include the player's own id so the client
  // can map itself to the correct Player object locally.
  wss.clients.forEach(socket => {
    const clientInfo = clients.get(socket);
    if (clientInfo && clientInfo.gameId === gameId && socket.readyState === WebSocket.OPEN) {
      // Build a public version of the game. By default we'll hide players' hands
      // in the public view and provide each socket its privateHand. However, for
      // the special first round (roundNumber == 1) we show other players' hands
      // publicly but keep the recipient's own hand hidden.
      const publicGame = JSON.parse(JSON.stringify(game));
      for (const p of publicGame.players) {
        // Default: hide
        p.hand = [];
        p.handCount = game.players.find(gp => gp.id === p.id).hand.length;
      }

      // If this is the special first round, reveal other players' hands publicly
      if (game.roundNumber === 1) {
        for (const p of publicGame.players) {
          if (p.id !== clientInfo.playerId) {
            // find the real player's hand and expose it
            const real = game.players.find(gp => gp.id === p.id);
            p.hand = real ? JSON.parse(JSON.stringify(real.hand)) : [];
          } else {
            // keep recipient's own hand hidden in private for round 1
            p.hand = [];
          }
        }
      }

      // privateHand: normally the player's actual hand, but in round 1 we keep
      // the recipient's own hand hidden (empty) because they must not see it.
      const playerReal = game.players.find(gp => gp.id === clientInfo.playerId);
      const playerPrivateHand = (game.roundNumber === 1) ? [] : (playerReal ? playerReal.hand : []);

      const messageObj = {
        type: 'game_state',
        game: publicGame,
        playerId: clientInfo.playerId,
        privateHand: playerPrivateHand,
      };

      socket.send(JSON.stringify(messageObj));
    }
  });
}

function sendError(ws, errorMessage) {
  const message = JSON.stringify({
    type: 'error',
    message: errorMessage
  });
  
  if (ws.readyState === WebSocket.OPEN) {
    ws.send(message);
  }
}

// Graceful shutdown
process.on('SIGINT', () => {
  console.log('Shutting down server...');
  wss.close(() => {
    console.log('Server closed');
    process.exit(0);
  });
});
