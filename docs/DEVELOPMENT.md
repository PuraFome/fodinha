# Development Guide

This guide will help you set up and start developing the Fodinha multiplayer card game.

## Prerequisites

Before you begin, ensure you have the following installed:

- **Flutter SDK** (3.0.0 or higher): [Install Flutter](https://flutter.dev/docs/get-started/install)
- **Dart SDK** (included with Flutter)
- **Android Studio** or **VS Code** with Flutter extensions
- **Git** for version control

For mobile development:
- **Android SDK** (for Android development)
- **Xcode** (for iOS development, macOS only)

## Initial Setup

### 1. Clone the Repository

```bash
git clone https://github.com/PuraFome/fodinha.git
cd fodinha
```

### 2. Install Dependencies

```bash
flutter pub get
```

### 3. Verify Installation

```bash
flutter doctor
```

This command checks your environment and displays a report of the status of your Flutter installation.

## Project Structure

```
fodinha/
├── lib/
│   ├── main.dart                    # App entry point
│   ├── models/                      # Data models
│   │   ├── card.dart               # Card model
│   │   ├── deck.dart               # Deck management
│   │   ├── game.dart               # Game state
│   │   └── player.dart             # Player model
│   ├── screens/                     # UI screens
│   │   ├── home_screen.dart        # Home/menu
│   │   ├── lobby_screen.dart       # Game lobby
│   │   └── game_screen.dart        # Main game
│   ├── services/                    # Business logic
│   │   ├── game_provider.dart      # State management
│   │   └── multiplayer_service.dart # Network layer
│   └── widgets/                     # Reusable components
│       └── card_widget.dart        # Card display
├── test/                            # Unit tests
├── docs/                            # Documentation
├── pubspec.yaml                     # Dependencies
└── README.md                        # Project overview
```

## Running the App

### Development Mode

```bash
flutter run
```

This will launch the app on your connected device or emulator.

### Hot Reload

While the app is running, you can make changes to the code and press:
- `r` in the terminal to hot reload
- `R` to hot restart

### Select a Device

```bash
# List all connected devices
flutter devices

# Run on a specific device
flutter run -d <device-id>
```

## Development Workflow

### 1. Code Style

Follow the official [Dart Style Guide](https://dart.dev/guides/language/effective-dart/style).

Run the linter:
```bash
flutter analyze
```

Format code:
```bash
flutter format lib/ test/
```

### 2. Testing

Run all tests:
```bash
flutter test
```

Run specific test file:
```bash
flutter test test/card_test.dart
```

Run tests with coverage:
```bash
flutter test --coverage
```

### 3. Building

Build for Android:
```bash
flutter build apk --release
```

Build for iOS:
```bash
flutter build ios --release
```

Build for Web:
```bash
flutter build web
```

## Key Dependencies

### Production Dependencies

- **flutter**: UI framework
- **provider**: State management (^6.0.5)
- **uuid**: Generate unique IDs (^4.0.0)
- **web_socket_channel**: WebSocket client (^2.4.0)
- **http**: HTTP requests (^1.1.0)

### Development Dependencies

- **flutter_test**: Testing framework
- **flutter_lints**: Linting rules (^2.0.0)

## State Management

This project uses the **Provider** pattern for state management.

### GameProvider

The `GameProvider` class manages the global game state:

```dart
// Access the provider
final gameProvider = context.read<GameProvider>();

// Watch for changes
final gameProvider = context.watch<GameProvider>();

// Use Consumer widget
Consumer<GameProvider>(
  builder: (context, gameProvider, child) {
    return Text('Score: ${gameProvider.currentGame?.score}');
  },
)
```

## Adding New Features

### 1. Adding a New Model

Create a new file in `lib/models/`:

```dart
class MyModel {
  final String id;
  final String name;
  
  MyModel({required this.id, required this.name});
  
  Map<String, dynamic> toJson() => {'id': id, 'name': name};
  
  factory MyModel.fromJson(Map<String, dynamic> json) {
    return MyModel(id: json['id'], name: json['name']);
  }
}
```

### 2. Adding a New Screen

Create a new file in `lib/screens/`:

```dart
import 'package:flutter/material.dart';

class MyScreen extends StatelessWidget {
  const MyScreen({super.key});
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Screen')),
      body: Center(child: Text('Hello World')),
    );
  }
}
```

### 3. Adding a New Service

Create a new file in `lib/services/`:

```dart
class MyService {
  Future<void> doSomething() async {
    // Implementation
  }
}
```

## Debugging

### Enable Debug Mode

Debug mode is enabled by default when running with `flutter run`.

### Flutter DevTools

Launch DevTools:
```bash
flutter pub global activate devtools
flutter pub global run devtools
```

### Common Issues

**Issue**: "Package not found"
```bash
flutter pub get
```

**Issue**: Build errors after pulling changes
```bash
flutter clean
flutter pub get
```

**Issue**: Hot reload not working
- Use hot restart (R) instead
- Sometimes requires a full restart

## Multiplayer Development

For local multiplayer testing, you'll need to set up a WebSocket server. See `docs/server/README.md` for server implementation guide.

### Quick Test Server

You can use a simple Node.js server for testing:

1. Create `server.js`:
```javascript
const WebSocket = require('ws');
const wss = new WebSocket.Server({ port: 8080 });

wss.on('connection', (ws) => {
  ws.on('message', (message) => {
    console.log('Received:', message);
    // Echo back for testing
    ws.send(message);
  });
});

console.log('WebSocket server running on ws://localhost:8080');
```

2. Run the server:
```bash
node server.js
```

## Contributing Guidelines

1. **Fork** the repository
2. **Create** a feature branch (`git checkout -b feature/amazing-feature`)
3. **Commit** your changes (`git commit -m 'Add some amazing feature'`)
4. **Push** to the branch (`git push origin feature/amazing-feature`)
5. **Open** a Pull Request

### Commit Message Convention

- `feat:` New feature
- `fix:` Bug fix
- `docs:` Documentation changes
- `style:` Code style changes (formatting)
- `refactor:` Code refactoring
- `test:` Adding or updating tests
- `chore:` Maintenance tasks

## Resources

- [Flutter Documentation](https://flutter.dev/docs)
- [Dart Language Tour](https://dart.dev/guides/language/language-tour)
- [Provider Documentation](https://pub.dev/packages/provider)
- [WebSocket API](https://developer.mozilla.org/en-US/docs/Web/API/WebSocket)

## Getting Help

- Check the [documentation](../README.md)
- Review [game rules](GAME_RULES.md)
- Check existing [issues](https://github.com/PuraFome/fodinha/issues)
- Create a new issue for bugs or feature requests

## Performance Tips

1. Use `const` constructors where possible
2. Avoid rebuilding widgets unnecessarily
3. Use `ListView.builder` for long lists
4. Profile with Flutter DevTools
5. Minimize network requests

## Next Steps

After setting up the development environment:

1. Review the game rules in `docs/GAME_RULES.md`
2. Read the server implementation guide in `docs/server/README.md`
3. Run the existing tests to ensure everything works
4. Start building new features!

Happy coding! 🎮
