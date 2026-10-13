import 'package:flutter/material.dart';

import 'models/simulation_state.dart';
import 'screens/about_screen.dart';
import 'screens/challenge_screen.dart';
import 'screens/concepts_screen.dart';
import 'screens/experiments/experiments_screen.dart';
import 'screens/home_screen.dart';
import 'screens/materials_screen.dart';
import 'screens/simulation_screen.dart';
import 'theme/wave_theme.dart';

void main() => runApp(const WaveLabApp());

class WaveLabApp extends StatefulWidget {
  const WaveLabApp({super.key});

  @override
  State<WaveLabApp> createState() => _WaveLabAppState();
}

class _WaveLabAppState extends State<WaveLabApp> {
  final SimulationState _state = SimulationState();

  @override
  void dispose() {
    _state.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SimScope(
      notifier: _state,
      child: AnimatedBuilder(
        animation: _state,
        builder: (context, _) => MaterialApp(
          title: 'Wave Lab',
          debugShowCheckedModeBanner: false,
          theme: WaveTheme.light(),
          darkTheme: WaveTheme.dark(),
          themeMode: _state.themeMode,
          builder: (context, child) {
            // Respect the system font size, but never enough to break a layout.
            final scaler = MediaQuery.of(context).textScaler.clamp(
                  minScaleFactor: 0.9,
                  maxScaleFactor: 1.25,
                );
            return MediaQuery(
              data: MediaQuery.of(context).copyWith(textScaler: scaler),
              child: child ?? const SizedBox.shrink(),
            );
          },
          initialRoute: HomeScreen.route,
          routes: {
            HomeScreen.route: (_) => const HomeScreen(),
            SimulationScreen.route: (_) => const SimulationScreen(),
            MaterialsScreen.route: (_) => const MaterialsScreen(),
            ExperimentsScreen.route: (_) => const ExperimentsScreen(),
            ConceptsScreen.route: (_) => const ConceptsScreen(),
            ChallengeScreen.route: (_) => const ChallengeScreen(),
            AboutScreen.route: (_) => const AboutScreen(),
          },
        ),
      ),
    );
  }
}
