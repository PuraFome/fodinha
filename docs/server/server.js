const WebSocket = require('ws');
const { v4: uuidv4 } = require('uuid');

// Create WebSocket server
const wss = new WebSocket.Server({ port: 8080 });

// Store active games
const games = new Map();
// Map client WebSocket to player info
const clients = new Map();

console.log('Fodinha WebSocket Server running on ws://localhost:8080');

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

  // Prepare a deck and deal cards to players
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

  // Decide cards per player for initial round (use 10 as standard fodinha hand)
  const cardsPerPlayer = 10;

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
  // start bidding with player after dealer
  game.currentBidderIndex = (game.dealerIndex + 1) % game.players.length;

  game.state = 'bidding';
  console.log(`Game ${client.gameId} started and cards dealt`);

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

    // Clear trick
    game.currentTrick = [];
    game.playerIdsInTrick = [];
    game.trickStarterIndex = null;

    // Check if round is over (players have no cards)
    const anyCardsLeft = game.players.some(p => p.hand && p.hand.length > 0);
    if (!anyCardsLeft) {
      // For now mark round complete. Scoring and next round logic can be added later.
      game.state = 'round_over';
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
      // Build a public version of the game where players' hands are hidden
      const publicGame = JSON.parse(JSON.stringify(game));
      for (const p of publicGame.players) {
        p.hand = []; // hide actual cards
        p.handCount = game.players.find(gp => gp.id === p.id).hand.length;
      }

      const playerPrivateHand = game.players.find(gp => gp.id === clientInfo.playerId).hand || [];

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
