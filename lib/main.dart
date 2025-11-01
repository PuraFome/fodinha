import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/game_provider.dart';
import 'services/localization_provider.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const FodinhaApp());
}

class FodinhaApp extends StatelessWidget {
  const FodinhaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => GameProvider()),
        ChangeNotifierProvider(create: (_) => LocalizationProvider()),
      ],
      child: Builder(builder: (context) {
        final loc = context.watch<LocalizationProvider>();
        return MaterialApp(
          title: loc.t('app.title'),
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.red),
            useMaterial3: true,
          ),
          home: const HomeScreen(),
        );
      }),
    );
  }
}
