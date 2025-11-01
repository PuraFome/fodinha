# Server Implementation Guide

This document provides guidance for implementing a WebSocket server for the Fodinha multiplayer game.

## Overview

The Fodinha Flutter app requires a WebSocket server to manage multiplayer game sessions. The server is responsible for:

- Managing game sessions and player connections
- Broadcasting game state updates to all players
- Processing player actions (creating games, joining, bidding, playing cards)
- Enforcing game rules and turn order

## WebSocket Connection

The app connects to the server via WebSocket at the URL specified by the user (default: `ws://localhost:8080`).

## Message Protocol

All messages are sent as JSON strings with a `type` field indicating the message type.

### Client to Server Messages

#### 1. Create Game
```json
{
  "type": "create_game",
  "playerName": "John",
  "maxPlayers": 4
}
```

**Expected Response:**
```json
{
  "type": "game_state",
  "game": {
    "id": "game-123",
    "players": [...],
    "state": "waiting",
    ...
  }
}
```

#### 2. Join Game
```json
{
  "type": "join_game",
  "gameId": "game-123",
  "playerName": "Jane"
}
```

**Expected Response:**
```json
{
  "type": "game_state",
  "game": { ... }
}
```

#### 3. Leave Game
```json
{
  "type": "leave_game",
  "gameId": "game-123"
}
```

#### 4. Set Ready Status
```json
{
  "type": "set_ready",
  "gameId": "game-123",
  "ready": true
}
```

**Expected Response:**
```json
{
  "type": "game_state",
  "game": { ... }
}
```

#### 5. Start Game
```json
{
  "type": "start_game",
  "gameId": "game-123"
}
```

**Expected Response:**
```json
{
  "type": "game_state",
  "game": {
    "state": "bidding",
    ...
  }
}
```

#### 6. Place Bid
```json
{
  "type": "place_bid",
  "gameId": "game-123",
  "bid": 3
}
```

**Expected Response:**
```json
{
  "type": "game_state",
  "game": {
    "bids": {
      "player-1": 3
    },
    ...
  }
}
```

#### 7. Play Card
```json
{
  "type": "play_card",
  "gameId": "game-123",
  "card": {
    "suit": "hearts",
    "rank": "ace"
  }
}
```

**Expected Response:**
```json
{
  "type": "game_state",
  "game": {
    "currentTrick": [...],
    ...
  }
}
```

### Server to Client Messages

#### 1. Game State Update
```json
{
  "type": "game_state",
  "game": {
    "id": "game-123",
    "players": [
      {
        "id": "player-1",
        "name": "John",
        "hand": [...],
        "tricksWon": 2,
        "score": 15,
        "isReady": true,
        "isDealer": false
      }
    ],
    "state": "playing",
    "currentPlayerIndex": 0,
    "dealerIndex": 0,
    "roundNumber": 1,
    "trumpCard": {
      "suit": "hearts",
      "rank": "ace"
    },
    "currentTrick": [],
    "playerIdsInTrick": [],
    "bids": {},
    "maxPlayers": 4
  }
}
```

#### 2. Error Message
```json
{
  "type": "error",
  "message": "Game not found"
}
```

## Game State Model

### Card Suits
- `hearts` (♥)
- `diamonds` (♦)
- `clubs` (♣)
- `spades` (♠)

### Card Ranks (in order of value)
- `four` (4)
- `five` (5)
- `six` (6)
- `seven` (7)
- `queen` (Q)
- `jack` (J)
- `king` (K)
- `ace` (A)
- `two` (2)
- `three` (3)

### Game States
- `waiting`: Waiting for players to join
- `bidding`: Players are placing bids
- `playing`: Game in progress
- `roundEnd`: Round has ended, calculating scores
- `gameEnd`: Game has ended

## Server Implementation Example (Node.js)

Here's a basic example using Node.js and the `ws` library:

```javascript
const WebSocket = require('ws');
const { v4: uuidv4 } = require('uuid');

const wss = new WebSocket.Server({ port: 8080 });
const games = new Map();

wss.on('connection', (ws) => {
  let currentGameId = null;
  let playerId = uuidv4();

  ws.on('message', (message) => {
    const data = JSON.parse(message);
    
    switch (data.type) {
      case 'create_game':
        const gameId = uuidv4();
        const game = {
          id: gameId,
          players: [{
            id: playerId,
            name: data.playerName,
            hand: [],
            tricksWon: 0,
            score: 0,
            isReady: false,
            isDealer: true
          }],
          state: 'waiting',
          maxPlayers: data.maxPlayers,
          // ... other game properties
        };
        
        games.set(gameId, game);
        currentGameId = gameId;
        
        ws.send(JSON.stringify({
          type: 'game_state',
          game: game
        }));
        break;
        
      case 'join_game':
        // Handle joining existing game
        break;
        
      // ... handle other message types
    }
  });

  ws.on('close', () => {
    // Handle disconnection
    if (currentGameId) {
      const game = games.get(currentGameId);
      if (game) {
        game.players = game.players.filter(p => p.id !== playerId);
        // Broadcast updated state to remaining players
      }
    }
  });
});

console.log('WebSocket server running on ws://localhost:8080');
```

## Server Requirements

The server should:

1. **Maintain game sessions**: Store active games in memory or a database
2. **Validate actions**: Ensure players can only perform valid actions
3. **Enforce turn order**: Only allow the current player to play cards
4. **Calculate scores**: Implement Fodinha scoring rules
5. **Handle disconnections**: Remove players who disconnect
6. **Broadcast updates**: Send game state to all players in a game when it changes

## Deployment Considerations

- Use a production-grade WebSocket server
- Implement authentication/authorization if needed
- Add rate limiting to prevent abuse
- Consider using Redis for session storage in distributed systems
- Implement reconnection logic for dropped connections
- Add logging and monitoring

## Example Server Implementation

A basic Node.js server implementation is provided in this directory.

### Running the Example Server

1. Navigate to the server directory:
```bash
cd docs/server
```

2. Install dependencies:
```bash
npm install
```

3. Start the server:
```bash
npm start
```

The server will run on `ws://localhost:8080`.

### Files

- `server.js`: Main server implementation
- `package.json`: Node.js dependencies
- `README.md`: This file

**Note**: This is a basic example server. For production use, you should add:
- Input validation
- Error handling
- Authentication
- Persistence (database)
- Rate limiting
- Logging
- Tests

## Testing the Server

You can test the server using tools like:
- `wscat`: Command-line WebSocket client
- Postman: Has WebSocket support
- Custom test scripts
- The Fodinha Flutter app itself

Example using wscat:
```bash
npm install -g wscat
wscat -c ws://localhost:8080
> {"type":"create_game","playerName":"Test","maxPlayers":4}
```

## Additional Resources

- [WebSocket Protocol (RFC 6455)](https://tools.ietf.org/html/rfc6455)
- [ws - Node.js WebSocket library](https://github.com/websockets/ws)
- [Socket.IO](https://socket.io/) (alternative with fallbacks)
- [Node.js Documentation](https://nodejs.org/docs/)
