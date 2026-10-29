import 'package:flutter/material.dart';

import '../../models/simulation_state.dart';
import '../../widgets/ui_kit.dart';
import 'doppler_screen.dart';
import 'echo_screen.dart';
import 'interference_screen.dart';
import 'optics_screen.dart';
import 'reflection_screen.dart';
import 'resonance_screen.dart';
import 'standing_wave_screen.dart';
import 'string_wave_screen.dart';
import 'vacuum_screen.dart';

class ExperimentsScreen extends StatelessWidget {
  const ExperimentsScreen({super.key});

  static const String route = '/experiments';

  @override
  Widget build(BuildContext context) {
    final state = SimScope.of(context);

    void open(Widget screen) => Navigator.push(
          context,
          MaterialPageRoute<void>(builder: (_) => screen),
        );

    return LabScaffold(
      title: 'Experiments',
      subtitle: 'Nine setups, one variable each',
      actions: [
        ThemeToggle(
          isDark: state.themeMode == ThemeMode.dark,
          onTap: state.toggleTheme,
        ),
      ],
      child: Column(
        children: [
          const Tip(
            'Work through them in order. Reflection explains echo, reflection '
            'in a tube explains resonance, and two reflections facing each '
            'other explain standing waves.',
            icon: Icons.route_outlined,
          ),
          const SizedBox(height: 16),
          BigButton(
            label: 'Wave on a string',
            detail: 'A real solver: pulses, reflection, damping, boundaries',
            icon: Icons.show_chart,
            primary: true,
            onTap: () => open(const StringWaveScreen()),
          ),
          const SizedBox(height: 11),
          BigButton(
            label: 'Reflection',
            detail: 'Fire a pulse at a wall and change the wall',
            icon: Icons.call_received,
            onTap: () => open(const ReflectionScreen()),
          ),
          const SizedBox(height: 11),
          BigButton(
            label: 'Echo',
            detail: 'Move the wall and time the return, t = 2d / v',
            icon: Icons.timer_outlined,
            onTap: () => open(const EchoScreen()),
          ),
          const SizedBox(height: 11),
          BigButton(
            label: 'Resonance',
            detail: 'Tune a tone to an air column and watch it build',
            icon: Icons.graphic_eq,
            onTap: () => open(const ResonanceScreen()),
          ),
          const SizedBox(height: 11),
          BigButton(
            label: 'Interference',
            detail: 'Two sources, a map of loud and quiet places',
            icon: Icons.blur_on,
            onTap: () => open(const InterferenceScreen()),
          ),
          const SizedBox(height: 11),
          BigButton(
            label: 'Standing waves',
            detail: 'Two waves head-on, with nodes that never move',
            icon: Icons.stacked_line_chart,
            onTap: () => open(const StandingWaveScreen()),
          ),
          const SizedBox(height: 11),
          BigButton(
            label: 'Doppler effect',
            detail: 'Move the source and watch the wavefronts bunch up',
            icon: Icons.graphic_eq,
            onTap: () => open(const DopplerScreen()),
          ),
          const SizedBox(height: 11),
          BigButton(
            label: 'Refraction',
            detail: "Snell's law, critical angle, total internal reflection",
            icon: Icons.highlight_outlined,
            onTap: () => open(const OpticsScreen()),
          ),
          const SizedBox(height: 11),
          BigButton(
            label: 'Vacuum chamber',
            detail: 'Remove the air and see what is left',
            icon: Icons.dark_mode_outlined,
            onTap: () => open(const VacuumScreen()),
          ),
        ],
      ),
    );
  }
}
