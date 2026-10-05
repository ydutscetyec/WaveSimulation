import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/simulation_state.dart';
import '../theme/app_theme.dart';
import '../widgets/sim_clock.dart';
import '../widgets/ui_kit.dart';
import 'about_screen.dart';
import 'challenge_screen.dart';
import 'concepts_screen.dart';
import 'experiments/experiments_screen.dart';
import 'material_lab_screen.dart';
import 'simulation_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  static const String route = '/';

  @override
  Widget build(BuildContext context) {
    final state = SimScope.of(context);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF071024), AppColors.bgDeep],
          ),
        ),
        child: Stack(
          children: [
            // Ambient background wave. One orchestrated motion, nothing else
            // on this screen animates.
            Positioned.fill(
              child: ClockHost(
                hz: 0.09,
                builder: (context, clock) => CustomPaint(
                  painter: _AmbientWavePainter(clock),
                ),
              ),
            ),
            SafeArea(
              child: LayoutBuilder(
                builder: (context, c) {
                  return SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 22, 20, 28),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: c.maxHeight - 50,
                        maxWidth: 560,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 26),
                          Text(
                            'WAVE LAB',
                            style: Theme.of(context)
                                .textTheme
                                .displaySmall
                                ?.copyWith(letterSpacing: 4),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Explore sound and acoustics',
                            style: TextStyle(
                              fontSize: 17,
                              color: AppColors.cyan,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            'Everything here is built from everyday materials '
                            'you can hold: a rubber band, a cup and string, a '
                            'spoon, a glass of water.',
                            style: TextStyle(
                              fontSize: 15,
                              height: 1.5,
                              color: AppColors.textMuted,
                            ),
                          ),
                          const SizedBox(height: 28),
                          BigButton(
                            label: 'Start simulation',
                            detail: 'Watch air particles make a sound wave',
                            icon: Icons.graphic_eq,
                            primary: true,
                            onTap: () => Navigator.pushNamed(
                              context,
                              SimulationScreen.route,
                            ),
                          ),
                          const SizedBox(height: 12),
                          BigButton(
                            label: 'Material lab',
                            detail: 'Media, speeds and everyday objects',
                            icon: Icons.science_outlined,
                            onTap: () => Navigator.pushNamed(
                              context,
                              MaterialLabScreen.route,
                            ),
                          ),
                          const SizedBox(height: 12),
                          BigButton(
                            label: 'Experiments',
                            detail:
                                'Reflection, echo, resonance, interference, '
                                'standing waves, vacuum',
                            icon: Icons.biotech_outlined,
                            onTap: () => Navigator.pushNamed(
                              context,
                              ExperimentsScreen.route,
                            ),
                          ),
                          const SizedBox(height: 12),
                          BigButton(
                            label: 'Wave concepts',
                            detail: 'The seven terms, each with its picture',
                            icon: Icons.menu_book_outlined,
                            onTap: () => Navigator.pushNamed(
                              context,
                              ConceptsScreen.route,
                            ),
                          ),
                          const SizedBox(height: 12),
                          BigButton(
                            label: 'Challenges',
                            detail: 'Ten questions, with the reasoning',
                            icon: Icons.emoji_events_outlined,
                            onTap: () => Navigator.pushNamed(
                              context,
                              ChallengeScreen.route,
                            ),
                          ),
                          const SizedBox(height: 12),
                          BigButton(
                            label: 'About',
                            detail: 'Values, assumptions and limits',
                            icon: Icons.info_outline,
                            onTap: () => Navigator.pushNamed(
                              context,
                              AboutScreen.route,
                            ),
                          ),
                          const SizedBox(height: 20),
                          AnimatedBuilder(
                            animation: state,
                            builder: (context, _) => _BadgeStrip(
                              badges: state.badges.toList(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BadgeStrip extends StatelessWidget {
  const _BadgeStrip({required this.badges});

  final List<String> badges;

  @override
  Widget build(BuildContext context) {
    if (badges.isEmpty) {
      return const Text(
        'No badges yet. Start the simulation to earn your first one.',
        style: TextStyle(fontSize: 14, color: AppColors.textDim),
      );
    }
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final b in badges)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: fade(AppColors.amber, 0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: fade(AppColors.amber, 0.5)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.military_tech, size: 16, color: AppColors.amber),
                const SizedBox(width: 6),
                Text(
                  b,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.amber,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// Slow, low-contrast background motion. Deliberately far from the content so
/// it never competes with text.
class _AmbientWavePainter extends CustomPainter {
  _AmbientWavePainter(this.clock) : super(repaint: clock);

  final SimClock clock;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final phase = clock.phase;

    for (var layer = 0; layer < 3; layer++) {
      final path = Path();
      final amp = 26.0 + layer * 14;
      final yBase = h * (0.62 + layer * 0.11);
      final k = 2 * math.pi / (w * (0.9 + layer * 0.35));
      path.moveTo(0, yBase);
      for (var x = 0.0; x <= w; x += 6) {
        path.lineTo(x, yBase + amp * math.sin(k * x - phase * (1 + layer * 0.4)));
      }
      path.lineTo(w, h);
      path.lineTo(0, h);
      path.close();
      canvas.drawPath(
        path,
        Paint()..color = fade(layer == 0 ? AppColors.cyan : AppColors.blue, 0.05),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _AmbientWavePainter oldDelegate) => false;
}
