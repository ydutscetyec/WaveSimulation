import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../../widgets/ui_kit.dart';
import 'echo_screen.dart';
import 'interference_screen.dart';
import 'reflection_screen.dart';
import 'resonance_screen.dart';
import 'standing_wave_screen.dart';
import 'vacuum_screen.dart';

class ExperimentsScreen extends StatelessWidget {
  const ExperimentsScreen({super.key});

  static const String route = '/experiments';

  @override
  Widget build(BuildContext context) {
    return LabScaffold(
      title: 'Experiments',
      subtitle: 'Six setups, each with one thing to change',
      child: Column(
        children: [
          const Explain(
            'Work through these in order if you can. Reflection explains echo, '
            'reflection plus a tube explains resonance, and two reflections '
            'facing each other explain standing waves.',
            icon: Icons.route_outlined,
          ),
          const SizedBox(height: 16),
          BigButton(
            label: 'Reflection',
            detail: 'Send a pulse at a wall and change what the wall is made of',
            icon: Icons.call_received,
            primary: true,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute<void>(builder: (_) => const ReflectionScreen()),
            ),
          ),
          const SizedBox(height: 12),
          BigButton(
            label: 'Echo',
            detail: 'Move the wall and time the return with t = 2d / v',
            icon: Icons.timer_outlined,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute<void>(builder: (_) => const EchoScreen()),
            ),
          ),
          const SizedBox(height: 12),
          BigButton(
            label: 'Resonance',
            detail: 'Tune a driving frequency to an air column and watch it build',
            icon: Icons.graphic_eq,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute<void>(builder: (_) => const ResonanceScreen()),
            ),
          ),
          const SizedBox(height: 12),
          BigButton(
            label: 'Interference',
            detail: 'Two sources, one map of loud and quiet places',
            icon: Icons.blur_on,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute<void>(builder: (_) => const InterferenceScreen()),
            ),
          ),
          const SizedBox(height: 12),
          BigButton(
            label: 'Standing waves',
            detail: 'Two waves meeting head-on, with nodes that never move',
            icon: Icons.stacked_line_chart,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute<void>(builder: (_) => const StandingWaveScreen()),
            ),
          ),
          const SizedBox(height: 12),
          BigButton(
            label: 'Vacuum chamber',
            detail: 'Remove the air and see what is left of the sound',
            icon: Icons.dark_mode_outlined,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute<void>(builder: (_) => const VacuumScreen()),
            ),
          ),
          const SizedBox(height: 18),
          const Panel(
            margin: EdgeInsets.zero,
            child: Text(
              'Every experiment shares one equation set: v = f x lambda for the '
              'wave itself, t = 2d / v for a round trip, and a sum of two '
              'sine waves for anything where two waves meet.',
              style: TextStyle(
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
