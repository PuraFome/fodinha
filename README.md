# Fodinha - Multiplayer Card Game

A Flutter-based multiplayer card game implementation of Fodinha (also known as Truco), supporting 2-6 players.

## Features

- **Multiplayer Support**: Play with 2-6 players over WebSocket
- **Real-time Gameplay**: Live game state synchronization
- **Classic Fodinha Rules**: Traditional Brazilian card game mechanics
- **Modern UI**: Clean and intuitive Flutter interface
- **Cross-Platform**: Works on Android, iOS, and Web

## Game Structure

### Models
- **Card**: Represents playing cards with suits (♥♦♣♠) and ranks
- **Player**: Manages player state, hand, score, and tricks won
- **Deck**: Handles card shuffling and distribution
- **Game**: Core game logic including bidding, playing, and scoring

### Services
- **MultiplayerService**: WebSocket-based multiplayer communication
- **GameProvider**: State management using Provider pattern

### Screens
- **Home Screen**: Create or join games
- **Lobby Screen**: Wait for players and game start
- **Game Screen**: Main gameplay interface

## Getting Started

### Prerequisites
- Flutter SDK (3.0.0 or higher)
- Dart SDK (included with Flutter)

### Installation

1. Clone the repository:
```bash
git clone https://github.com/PuraFome/fodinha.git
cd fodinha
```

2. Install dependencies:
```bash
flutter pub get
```

3. Run the app:
```bash
flutter run
```

## Project Structure

```
lib/
├── main.dart              # App entry point
├── models/                # Data models
│   ├── card.dart         # Card model with suits and ranks
│   ├── deck.dart         # Deck management
│   ├── game.dart         # Game state and logic
│   └── player.dart       # Player model
├── screens/              # UI screens
│   ├── home_screen.dart  # Home/menu screen
│   ├── lobby_screen.dart # Game lobby
│   └── game_screen.dart  # Main game screen
├── services/             # Business logic
│   ├── game_provider.dart       # State management
│   └── multiplayer_service.dart # Network communication
└── widgets/              # Reusable UI components
    └── card_widget.dart  # Card display widget
```

## How to Play

1. **Create a Game**: Enter your name, choose max players (2-6), and create a game
2. **Share Game ID**: Share the generated game ID with other players
3. **Join Game**: Other players can join using the game ID
4. **Wait in Lobby**: All players must mark themselves as ready
5. **Start Game**: Once all players are ready, start the game
6. **Bidding**: Each round, players bid on tricks they expect to win
7. **Playing**: Play cards in turns, following suit when possible
8. **Scoring**: Points awarded based on meeting or missing bids
9. **Win**: Player with highest score after all rounds wins

## Multiplayer Setup

This app requires a WebSocket server for multiplayer functionality. The server should:
- Accept WebSocket connections
- Handle game creation, joining, and state management
- Broadcast game state updates to all players
- Process player actions (bids, card plays)

Default server URL: `ws://localhost:8080`

### Server Message Format

The app expects JSON messages with the following structure:

**Client to Server:**
```json
{
  "type": "create_game" | "join_game" | "start_game" | "place_bid" | "play_card",
  "gameId": "string",
  "playerName": "string",
  "bid": number,
  "card": {...}
}
```

**Server to Client:**
```json
{
  "type": "game_state" | "error",
  "game": {...},
  "message": "string"
}
```

## Development

### Running Tests
```bash
flutter test
```

### Building for Production

**Android:**
```bash
flutter build apk
```

**iOS:**
```bash
flutter build ios
```

**Web:**
```bash
flutter build web
```

## Technologies Used

- **Flutter**: UI framework
- **Provider**: State management
- **WebSocket**: Real-time communication
- **Dart**: Programming language

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

See LICENSE file for details.

## Future Enhancements

- [ ] AI opponents for single-player mode
- [ ] Tournament mode
- [ ] Player statistics and leaderboards
- [ ] Custom game rules
- [ ] Chat functionality
- [ ] Sound effects and animations
- [ ] Multiple language support