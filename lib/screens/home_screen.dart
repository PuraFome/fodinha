import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/game_provider.dart';
import 'lobby_screen.dart';

/// Home screen for the Fodinha game
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _nameController = TextEditingController();
  final _gameIdController = TextEditingController();
  final _serverUrlController = TextEditingController(
    text: 'ws://localhost:8080',
  );
  int _maxPlayers = 4;

  @override
  void dispose() {
    _nameController.dispose();
    _gameIdController.dispose();
    _serverUrlController.dispose();
    super.dispose();
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  Future<void> _createGame() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      _showError('Please enter your name');
      return;
    }

    final gameProvider = context.read<GameProvider>();
    
    // Connect to server if not connected
    if (!gameProvider.isConnected) {
      final connected = await gameProvider.connect(_serverUrlController.text);
      if (!connected) {
        _showError('Failed to connect to server');
        return;
      }
    }

    gameProvider.createGame(name, _maxPlayers);
    
    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const LobbyScreen()),
      );
    }
  }

  Future<void> _joinGame() async {
    final name = _nameController.text.trim();
    final gameId = _gameIdController.text.trim();
    
    if (name.isEmpty) {
      _showError('Please enter your name');
      return;
    }
    
    if (gameId.isEmpty) {
      _showError('Please enter game ID');
      return;
    }

    final gameProvider = context.read<GameProvider>();
    
    // Connect to server if not connected
    if (!gameProvider.isConnected) {
      final connected = await gameProvider.connect(_serverUrlController.text);
      if (!connected) {
        _showError('Failed to connect to server');
        return;
      }
    }

    gameProvider.joinGame(gameId, name);
    
    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const LobbyScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fodinha'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 40),
            const Icon(
              Icons.style,
              size: 80,
              color: Colors.red,
            ),
            const SizedBox(height: 20),
            const Text(
              'Fodinha',
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Multiplayer Card Game',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Your Name',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _serverUrlController,
              decoration: const InputDecoration(
                labelText: 'Server URL',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.dns),
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'Create New Game',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<int>(
              value: _maxPlayers,
              decoration: const InputDecoration(
                labelText: 'Max Players',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.groups),
              ),
              items: [2, 3, 4, 5, 6]
                  .map((n) => DropdownMenuItem(
                        value: n,
                        child: Text('$n Players'),
                      ))
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _maxPlayers = value);
                }
              },
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _createGame,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
              ),
              child: const Text(
                'Create Game',
                style: TextStyle(fontSize: 16),
              ),
            ),
            const SizedBox(height: 32),
            const Divider(),
            const SizedBox(height: 16),
            const Text(
              'Join Existing Game',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _gameIdController,
              decoration: const InputDecoration(
                labelText: 'Game ID',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.tag),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _joinGame,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
              ),
              child: const Text(
                'Join Game',
                style: TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
