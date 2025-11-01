import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/game_provider.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const FodinhaApp());
}

class FodinhaApp extends StatelessWidget {
  const FodinhaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => GameProvider(),
      child: MaterialApp(
        title: 'Fodinha',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.red),
          useMaterial3: true,
        ),
        home: const HomeScreen(),
      ),
    );
  }
}
