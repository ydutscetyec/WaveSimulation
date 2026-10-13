import 'package:flutter/material.dart';

import '../../theme/wave_theme.dart';
import '../../widgets/sim_clock.dart';
import '../../widgets/ui_kit.dart';
import '../../widgets/wave_canvas.dart';

class VacuumScreen extends StatefulWidget {
  const VacuumScreen({super.key});

  @override
  State<VacuumScreen> createState() => _VacuumScreenState();
}

class _VacuumScreenState extends State<VacuumScreen> {
  bool _vacuum = false;

  @override
  Widget build(BuildContext context) {
    final c = context.c;

    return LabScaffold(
      title: 'Vacuum chamber',
      subtitle: 'Can sound travel through space?',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 190,
            width: double.infinity,
            child: ClockHost(
              hz: 1,
              timeRate: 1 / 440,
              builder: (context, clock) => CustomPaint(
                painter: WavePainter(
                  clock: clock,
                  colors: c,
                  amplitude: 0.65,
                  wavelengthM: 0.78,
                  viewWidthM: 2.0,
                  accent: c.accent,
                  vacuum: _vacuum,
                  showTracer: false,
                  showFront: false,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Body('The bell inside the jar keeps shaking either way.',
              size: 13.5, color: c.textTertiary),
          const SizedBox(height: 14),
          Segmented(
            labels: const ['Air', 'Vacuum'],
            selectedIndex: _vacuum ? 1 : 0,
            onSelect: (i) => setState(() => _vacuum = i == 1),
          ),
          const SizedBox(height: 16),
          Panel(
            accent: _vacuum ? c.amber : c.accent,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _vacuum
                      ? 'Sound requires a material medium.'
                      : 'The bell is heard.',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    color: _vacuum ? c.amber : c.accent,
                  ),
                ),
                const SizedBox(height: 10),
                Body(
                  _vacuum
                      ? 'There is nothing next to the bell to push. A '
                          'compression needs particles to crowd together and a '
                          'rarefaction needs them to spread apart, so with no '
                          'particles there is no wave at all. Not a faint one. '
                          'None.'
                      : 'The shaking bell pushes the air beside it, that air '
                          'pushes the next layer, and the disturbance travels '
                          'out at 343 m/s. The air itself stays put; only the '
                          'pattern of crowding moves.',
                  size: 15,
                ),
              ],
            ),
          ),
          Panel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const PanelTitle('Mechanical vs electromagnetic',
                    icon: Icons.compare_arrows),
                _Line(left: 'Sound', color: c.accent, right: 'Mechanical wave. Needs matter. Dies in a vacuum.'),
                _Line(left: 'Light', color: c.amber, right: 'Electromagnetic wave. Needs no medium. Crosses space.'),
                const SizedBox(height: 8),
                const Body(
                  'That is why you could see a distant explosion in space and '
                  'never hear it.',
                ),
              ],
            ),
          ),
          const Panel(
            margin: EdgeInsets.zero,
            child: Tip(
              'A real bell jar never reaches a perfect vacuum, so a very faint '
              'sound usually remains, and some also escapes through whatever '
              'the bell rests on.',
              icon: Icons.info_outline,
            ),
          ),
        ],
      ),
    );
  }
}

class _Line extends StatelessWidget {
  const _Line({required this.left, required this.right, required this.color});

  final String left;
  final String right;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 62,
            child: Text(
              left,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ),
          Expanded(child: Body(right)),
        ],
      ),
    );
  }
}
