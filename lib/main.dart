import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'models/simulation_state.dart';
import 'screens/about_screen.dart';
import 'screens/challenge_screen.dart';
import 'screens/concepts_screen.dart';
import 'screens/experiments/experiments_screen.dart';
import 'screens/home_screen.dart';
import 'screens/material_lab_screen.dart';
import 'screens/simulation_screen.dart';
import 'theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: AppColors.bgDeep,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );
  runApp(const WaveLabApp());
}

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
      child: MaterialApp(
        title: 'Wave Lab',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.build(),
        // Keep text legible but never let a huge system font break layouts.
        builder: (context, child) {
          final scale = MediaQuery.of(context).textScaler.clamp(
                minScaleFactor: 0.9,
                maxScaleFactor: 1.3,
              );
          return MediaQuery(
            data: MediaQuery.of(context).copyWith(textScaler: scale),
            child: child ?? const SizedBox.shrink(),
          );
        },
        initialRoute: HomeScreen.route,
        routes: {
          HomeScreen.route: (_) => const HomeScreen(),
          SimulationScreen.route: (_) => const SimulationScreen(),
          MaterialLabScreen.route: (_) => const MaterialLabScreen(),
          ExperimentsScreen.route: (_) => const ExperimentsScreen(),
          ConceptsScreen.route: (_) => const ConceptsScreen(),
          ChallengeScreen.route: (_) => const ChallengeScreen(),
          AboutScreen.route: (_) => const AboutScreen(),
        },
      ),
    );
  }
}
