import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../models/simulation_state.dart';
import '../../services/wave_physics.dart';
import '../../theme/app_theme.dart';
import '../../widgets/sim_clock.dart';
import '../../widgets/ui_kit.dart';

class EchoScreen extends StatefulWidget {
  const EchoScreen({super.key});

  @override
  State<EchoScreen> createState() => _EchoScreenState();
}

class _EchoScreenState extends State<EchoScreen> {
  final GlobalKey<ClockHostState> _clockKey = GlobalKey<ClockHostState>();

  double _distance = 34.3;
  bool _running = false;

  double get _speed => 343;
  double get _delay => WavePhysics.echoDelay(_distance, _speed);

  /// The animation is slowed just enough to be watchable, and the factor is
  /// shown on screen rather than hidden.
  double get _slowFactor => (2.2 / _delay).clamp(1.0, 40.0);

  void _play() {
    _clockKey.currentState?.restart();
    setState(() => _running = true);
    final state = SimScope.read(context);
    if (state.awardBadge('ECHO EXPLORER')) {
      showBadge(context, 'ECHO EXPLORER');
    }
  }

  @override
  Widget build(BuildContext context) {
    final audible = _distance >= WavePhysics.minEchoDistance(_speed);

    return LabScaffold(
      title: 'Echo',
      subtitle: 'One reflection, timed',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 190,
            width: double.infinity,
            child: ClockHost(
              key: _clockKey,
              hz: 1,
              timeRate: 1 / _slowFactor, // simulated seconds per real second
              running: _running,
              maxSeconds: _delay * 1.15,
              onLimit: () {
                if (mounted) setState(() => _running = false);
              },
              builder: (context, clock) => CustomPaint(
                painter: _EchoPainter(
                  clock: clock,
                  distanceM: _distance,
                  speedMs: _speed,
                  delayS: _delay,
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Panel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const PanelTitle('Distance to the wall', icon: Icons.straighten),
                StepSlider(
                  label: 'Move further away and the gap grows',
                  value: _distance,
                  min: 5,
                  max: 200,
                  step: 1,
                  readout: '${_distance.toStringAsFixed(1)} m',
                  onChanged: (v) => setState(() {
                    _distance = v;
                    _running = false;
                  }),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: ValueCard(
                        label: 'Echo delay',
                        value: _delay.toStringAsFixed(2),
                        unit: 's',
                        color: AppColors.amber,
                        compact: true,
                      ),
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: ValueCard(
                        label: 'Round trip',
                        value: (2 * _distance).toStringAsFixed(0),
                        unit: 'm',
                        compact: true,
                      ),
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: ValueCard(
                        label: 'Shown at',
                        value: '1/${_slowFactor.toStringAsFixed(0)}',
                        unit: 'speed',
                        color: AppColors.textMuted,
                        compact: true,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(54),
                    backgroundColor: AppColors.cyan,
                    foregroundColor: const Color(0xFF042026),
                  ),
                  onPressed: _play,
                  icon: const Icon(Icons.campaign),
                  label: const Text('Shout'),
                ),
              ],
            ),
          ),
          Panel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const PanelTitle('The calculation', icon: Icons.functions),
                Text(
                  't = 2d / v\n'
                  't = 2 x ${_distance.toStringAsFixed(1)} m / 343 m/s\n'
                  't = ${(2 * _distance).toStringAsFixed(1)} m / 343 m/s\n'
                  't = ${_delay.toStringAsFixed(3)} s',
                  style: const TextStyle(
                    fontSize: 15.5,
                    height: 1.7,
                    color: AppColors.cyan,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'The 2 is the whole trick. The sound has to reach the wall '
                  'and come all the way back, so it covers twice the distance '
                  'you measured. Leaving the 2 out is the most common mistake '
                  'in echo problems.',
                  style: TextStyle(
                    fontSize: 14.5,
                    color: AppColors.textMuted,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          Panel(
            margin: EdgeInsets.zero,
            accent: audible ? null : AppColors.amber,
            child: Explain(
              audible
                  ? 'At ${_distance.toStringAsFixed(0)} m the return arrives '
                      '${_delay.toStringAsFixed(2)} s later, which is far enough '
                      'apart for your ear to hear it as a separate sound.'
                  : 'At ${_distance.toStringAsFixed(0)} m the delay is only '
                      '${(_delay * 1000).toStringAsFixed(0)} ms. Below about '
                      '${WavePhysics.minEchoDistance(_speed).toStringAsFixed(0)} m '
                      'the reflection arrives too soon to be heard separately - '
                      'you get reverberation, a smeared tail, instead of an echo.',
              icon: audible ? Icons.hearing : Icons.hearing_disabled,
              color: audible ? AppColors.blue : AppColors.amber,
            ),
          ),
        ],
      ),
    );
  }
}

class _EchoPainter extends CustomPainter {
  _EchoPainter({
    required this.clock,
    required this.distanceM,
    required this.speedMs,
    required this.delayS,
  }) : super(repaint: clock);

  final SimClock clock;
  final double distanceM;
  final double speedMs;
  final double delayS;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, w, h),
        const Radius.circular(16),
      ),
      Paint()..color = const Color(0xFF081226),
    );

    const personX = 34.0;
    final wallX = w - 30.0;
    final span = wallX - personX;
    final midY = h * 0.52;

    // ground
    canvas.drawLine(
      Offset(0, h - 24),
      Offset(w, h - 24),
      Paint()
        ..color = fade(AppColors.stroke, 0.9)
        ..strokeWidth = 1.4,
    );

    // wall
    canvas.drawRect(
      Rect.fromLTWH(wallX, h * 0.16, 22, h * 0.68),
      Paint()..color = fade(const Color(0xFFA6AEBB), 0.8),
    );

    // person
    canvas.drawCircle(
      Offset(personX, midY - 22),
      9,
      Paint()..color = AppColors.cyan,
    );
    canvas.drawLine(
      Offset(personX, midY - 13),
      Offset(personX, midY + 16),
      Paint()
        ..color = AppColors.cyan
        ..strokeWidth = 3.4,
    );

    // The pulse travels at the real speed in simulated time: x = v*t.
    final t = clock.seconds;
    final travelled = speedMs * t; // metres covered so far
    final total = 2 * distanceM;
    final done = travelled >= total;

    double? xOf(double metresFromPerson) {
      if (metresFromPerson < 0 || metresFromPerson > distanceM) return null;
      return personX + (metresFromPerson / distanceM) * span;
    }

    final outbound = travelled <= distanceM;
    final posM = outbound ? travelled : total - travelled;
    final x = xOf(posM.clamp(0.0, distanceM));

    if (!done && x != null && t > 0) {
      // arc fronts, fading with spreading loss
      final amp = outbound ? 1.0 : 0.72;
      for (var i = 0; i < 3; i++) {
        final r = 8.0 + i * 9;
        canvas.drawArc(
          Rect.fromCircle(center: Offset(x, midY), radius: r),
          outbound ? -math.pi / 2.4 : math.pi - math.pi / 2.4,
          outbound ? math.pi / 1.2 : math.pi / 1.2,
          false,
          Paint()
            ..color = fade(outbound ? AppColors.cyan : AppColors.amber,
                (0.85 - i * 0.22) * amp)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3.0 - i * 0.6,
        );
      }
    }

    // timer readout
    final elapsed = math.min(t, delayS);
    _text(
      canvas,
      '${elapsed.toStringAsFixed(2)} s',
      Offset(w / 2, 8),
      done ? AppColors.amber : AppColors.text,
      size: 17,
      centered: true,
    );
    _text(
      canvas,
      done
          ? 'ECHO HEARD'
          : (t <= 0
              ? 'READY'
              : (outbound ? 'TRAVELLING OUT' : 'COMING BACK')),
      Offset(w / 2, 30),
      done ? AppColors.amber : AppColors.textDim,
      centered: true,
    );
    _text(canvas, '${distanceM.toStringAsFixed(0)} m',
        Offset(w / 2, h - 20), AppColors.textMuted, centered: true);

    // distance line
    final p = Paint()
      ..color = fade(AppColors.textDim, 0.6)
      ..strokeWidth = 1;
    canvas.drawLine(Offset(personX, h - 34), Offset(wallX, h - 34), p);
  }

  void _text(
    Canvas canvas,
    String s,
    Offset at,
    Color color, {
    double size = 11.5,
    bool centered = false,
  }) {
    final tp = TextPainter(
      text: TextSpan(
        text: s,
        style: TextStyle(
          color: color,
          fontSize: size,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(centered ? at.dx - tp.width / 2 : at.dx, at.dy));
  }

  @override
  bool shouldRepaint(covariant _EchoPainter old) =>
      old.distanceM != distanceM || old.delayS != delayS;
}
