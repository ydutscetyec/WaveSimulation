import 'package:flutter/material.dart';

import '../models/simulation_state.dart';
import '../theme/wave_theme.dart';
import '../widgets/ui_kit.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  static const String route = '/about';

  static const List<(String, String)> _equations = [
    ('v = f x lambda', 'speed, frequency, wavelength'),
    ('s(x,t) = A sin(kx - wt)', 'particle displacement'),
    ('-ds/dx = Ak cos(kx - wt)', 'compression and rarefaction'),
    ('t = 2d / v', 'echo delay'),
    ('f_n = (2n-1) v / 4L', 'air column closed at one end'),
    ('A_r = sqrt(A1^2+A2^2+2A1A2 cos d)', 'two sources combining'),
    ('amplitude back = sqrt(1 - alpha)', 'reflection from a surface'),
    ('Z = rho v', 'acoustic impedance'),
  ];

  static const List<String> _limits = [
    'Material speeds are mid-range values near 20 °C.',
    'Solids are given one longitudinal speed; they also carry shear waves.',
    'Absorption coefficients are single mid-frequency figures.',
    'The resonance model ignores end correction, so a real cup rings slightly '
        'lower than predicted.',
    'Amplitude is a relative 0 to 1 scale, not decibels.',
    'The animation is slowed and the canvas spans a chosen width. Both are '
        'shown on screen; the printed numbers are the real ones.',
    'There is no audio output. The real experiments supply the sound.',
  ];

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final state = SimScope.of(context);

    return LabScaffold(
      title: 'About',
      subtitle: 'Wave Lab, offline',
      actions: [
        ThemeToggle(
          isDark: state.themeMode == ThemeMode.dark,
          onTap: state.toggleTheme,
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Panel(
            child: Body(
              'An interactive laboratory for sound as a mechanical '
              'longitudinal wave, built around objects you can pick up. '
              'Everything runs offline: no accounts, no network, no data '
              'leaves the phone.',
              size: 15,
            ),
          ),
          Panel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const PanelTitle('Equations used', icon: Icons.functions),
                for (final (eq, meaning) in _equations)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          eq,
                          style: TextStyle(
                            fontSize: 15.5,
                            fontWeight: FontWeight.w700,
                            color: c.accent,
                          ),
                        ),
                        Body(meaning, size: 13.5, color: c.textTertiary),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          Panel(
            margin: EdgeInsets.zero,
            accent: c.amber,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const PanelTitle('Assumptions and limits',
                    icon: Icons.warning_amber),
                for (final l in _limits)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Body('·  $l'),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
