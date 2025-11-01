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
    bids: {},
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
  
  game.state = 'bidding';
  console.log(`Game ${client.gameId} started`);
  sendGameState(client.gameId);
}

function handlePlaceBid(ws, client, data) {
  const game = games.get(client.gameId);
  if (!game || game.state !== 'bidding') return;
  
  game.bids[client.playerId] = data.bid;
  
  if (Object.keys(game.bids).length === game.players.length) {
    game.state = 'playing';
  }
  
  sendGameState(client.gameId);
}

function handlePlayCard(ws, client, data) {
  const game = games.get(client.gameId);
  if (!game || game.state !== 'playing') return;
  
  const player = game.players.find(p => p.id === client.playerId);
  if (!player) return;
  
  // Simple validation - just accept the card for now
  game.currentTrick.push(data.card);
  game.playerIdsInTrick.push(client.playerId);
  
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
  
  const message = JSON.stringify({
    type: 'game_state',
    game: game
  });
  
  // Send to all clients in this game
  wss.clients.forEach(client => {
    const clientInfo = clients.get(client);
    if (clientInfo && clientInfo.gameId === gameId && client.readyState === WebSocket.OPEN) {
      client.send(message);
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
