import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../widgets/ui_kit.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  static const String route = '/about';

  @override
  Widget build(BuildContext context) {
    return LabScaffold(
      title: 'About Wave Lab',
      subtitle: 'Sound and acoustics simulator',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Panel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                PanelTitle('What this app is', icon: Icons.waves),
                Text(
                  'An interactive laboratory for sound as a mechanical '
                  'longitudinal wave, built around objects you can pick up: a '
                  'rubber band, a cup and string, a spoon, a glass of water, a '
                  'cardboard box.\n\n'
                  'Everything runs offline. There are no accounts, no network '
                  'calls and no data leaves the phone.',
                  style: TextStyle(
                    fontSize: 15,
                    color: AppColors.textMuted,
                    height: 1.55,
                  ),
                ),
              ],
            ),
          ),
          const Panel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                PanelTitle('Equations used', icon: Icons.functions),
                _Eq('v = f x lambda', 'wave speed, frequency, wavelength'),
                _Eq('lambda = v / f', 'the form the simulator computes live'),
                _Eq('s(x,t) = A sin(kx - wt + phi)', 'particle displacement'),
                _Eq('k = 2pi / lambda,  w = 2pi f', 'wave number, angular frequency'),
                _Eq('t = 2d / v', 'echo delay for a round trip'),
                _Eq('f_n = (2n-1) v / 4L', 'air column closed at one end'),
                _Eq('f_n = n v / 2L', 'air column open at both ends'),
                _Eq('A_r = sqrt(A1^2 + A2^2 + 2 A1 A2 cos d)',
                    'two sources combining'),
                _Eq('Z = rho v', 'acoustic impedance'),
                _Eq('amplitude back = sqrt(1 - alpha)',
                    'reflection from an absorbing surface'),
              ],
            ),
          ),
          const Panel(
            accent: AppColors.amber,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                PanelTitle('Assumptions and limits', icon: Icons.warning_amber),
                _Bullet('Material speeds are mid-range values at about 20 °C. '
                    'Real figures move with temperature, humidity, density, '
                    'grain direction and alloy.'),
                _Bullet('Solids are given one longitudinal speed. Real solids '
                    'also carry shear waves at a different speed.'),
                _Bullet('Absorption coefficients are single mid-frequency '
                    'numbers. Real absorption changes a lot with frequency.'),
                _Bullet('The resonance model is a single driven damped '
                    'oscillator with Q = 18. It ignores end correction, so a '
                    'real cup resonates slightly lower than predicted.'),
                _Bullet('Amplitude is shown on a relative 0 to 1 scale. It is '
                    'not calibrated to decibels or to any real sound pressure.'),
                _Bullet('The animation runs in slow motion and the canvas '
                    'represents a chosen real width. Both factors are shown on '
                    'screen; the printed numbers are always the real ones.'),
                _Bullet('There is no audio output. The app shows what a wave '
                    'does; your ears and the real experiments supply the sound.'),
              ],
            ),
          ),
          const Panel(
            margin: EdgeInsets.zero,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                PanelTitle('How to use it in class', icon: Icons.school),
                Text(
                  'Pair every screen with the real object. Run the cup-and-'
                  'string telephone, then open the simulator and change the '
                  'medium. Clap in a bare room, then open the reflection '
                  'experiment and switch the wall to foam. The simulation is '
                  'there to explain what your hands already did.',
                  style: TextStyle(
                    fontSize: 15,
                    color: AppColors.textMuted,
                    height: 1.55,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Eq extends StatelessWidget {
  const _Eq(this.equation, this.meaning);

  final String equation;
  final String meaning;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 11),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            equation,
            style: const TextStyle(
              fontSize: 15.5,
              fontWeight: FontWeight.w700,
              color: AppColors.cyan,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            meaning,
            style: const TextStyle(fontSize: 13.5, color: AppColors.textDim),
          ),
        ],
      ),
    );
  }
}

class _Bullet extends StatelessWidget {
  const _Bullet(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 5,
            height: 5,
            margin: const EdgeInsets.only(top: 8, right: 10),
            decoration: const BoxDecoration(
              color: AppColors.amber,
              shape: BoxShape.circle,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 14.5,
                color: AppColors.textMuted,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
