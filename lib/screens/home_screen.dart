import 'package:flutter/material.dart';

import '../models/simulation_state.dart';
import '../theme/wave_theme.dart';
import '../widgets/sim_clock.dart';
import '../widgets/ui_kit.dart';
import '../widgets/wave_canvas.dart';
import 'about_screen.dart';
import 'challenge_screen.dart';
import 'concepts_screen.dart';
import 'experiments/experiments_screen.dart';
import 'materials_screen.dart';
import 'simulation_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  static const String route = '/';

  @override
  Widget build(BuildContext context) {
    final state = SimScope.of(context);
    final c = context.c;

    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(18, 10, 18, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'WAVE LAB',
                              style: Theme.of(context).textTheme.displaySmall,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Sound and acoustics, from things you can hold',
                              style: TextStyle(
                                fontSize: 15.5,
                                color: c.accent,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      ThemeToggle(
                        isDark: state.themeMode == ThemeMode.dark,
                        onTap: state.toggleTheme,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // A real, running simulation as the hero - not decoration.
                  SizedBox(
                    height: 132,
                    width: double.infinity,
                    child: ClockHost(
                      hz: 0.9,
                      timeRate: 1 / 440,
                      builder: (context, clock) => CustomPaint(
                        painter: WavePainter(
                          clock: clock,
                          colors: c,
                          amplitude: 0.7,
                          wavelengthM: 0.78,
                          viewWidthM: 2.0,
                          accent: c.accent,
                          showTracer: false,
                          showSource: false,
                          showFront: false,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  BigButton(
                    label: 'Simulation',
                    detail: 'Change frequency, amplitude and medium',
                    icon: Icons.graphic_eq,
                    primary: true,
                    onTap: () =>
                        Navigator.pushNamed(context, SimulationScreen.route),
                  ),
                  const SizedBox(height: 11),
                  BigButton(
                    label: 'Experiments',
                    detail: 'Reflection, echo, resonance, interference, '
                        'standing waves, vacuum',
                    icon: Icons.science_outlined,
                    onTap: () =>
                        Navigator.pushNamed(context, ExperimentsScreen.route),
                  ),
                  const SizedBox(height: 11),
                  BigButton(
                    label: 'Materials',
                    detail: 'Media speeds, and everyday objects to try',
                    icon: Icons.layers_outlined,
                    onTap: () =>
                        Navigator.pushNamed(context, MaterialsScreen.route),
                  ),
                  const SizedBox(height: 11),
                  BigButton(
                    label: 'Concepts',
                    detail: 'Seven terms, each with its picture',
                    icon: Icons.menu_book_outlined,
                    onTap: () =>
                        Navigator.pushNamed(context, ConceptsScreen.route),
                  ),
                  const SizedBox(height: 11),
                  BigButton(
                    label: 'Challenges',
                    detail: 'Ten questions with the reasoning',
                    icon: Icons.emoji_events_outlined,
                    onTap: () =>
                        Navigator.pushNamed(context, ChallengeScreen.route),
                  ),
                  const SizedBox(height: 18),
                  Center(
                    child: TextButton(
                      onPressed: () =>
                          Navigator.pushNamed(context, AboutScreen.route),
                      child: Text(
                        'About and assumptions',
                        style: TextStyle(fontSize: 14.5, color: c.textTertiary),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
