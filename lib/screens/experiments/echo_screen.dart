import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../services/wave_physics.dart';
import '../../theme/wave_theme.dart';
import '../../widgets/sim_clock.dart';
import '../../widgets/ui_kit.dart';

class EchoScreen extends StatefulWidget {
  const EchoScreen({super.key});

  @override
  State<EchoScreen> createState() => _EchoScreenState();
}

class _EchoScreenState extends State<EchoScreen> {
  final GlobalKey<ClockHostState> _clockKey = GlobalKey<ClockHostState>();

  static const double _v = 343;
  double _distance = 34.3;
  bool _running = false;

  double get _delay => WavePhysics.echoDelay(_distance, _v);

  /// Slowed just enough to watch, and the factor is printed on screen.
  double get _slow => (2.2 / _delay).clamp(1.0, 40.0);

  void _play() {
    _clockKey.currentState?.restart();
    setState(() => _running = true);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final audible = _distance >= WavePhysics.minEchoDistance(_v);

    return LabScaffold(
      title: 'Echo',
      subtitle: 'One reflection, timed',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 185,
            width: double.infinity,
            child: ClockHost(
              key: _clockKey,
              hz: 1,
              timeRate: 1 / _slow,
              running: _running,
              maxSeconds: _delay * 1.15,
              onLimit: () {
                if (mounted) setState(() => _running = false);
              },
              builder: (context, clock) => CustomPaint(
                painter: _EchoPainter(
                  clock: clock,
                  colors: c,
                  distanceM: _distance,
                  speedMs: _v,
                  delayS: _delay,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(54),
              backgroundColor: c.accent,
              foregroundColor: c.onAccent,
            ),
            onPressed: _play,
            icon: const Icon(Icons.campaign),
            label: const Text('Shout'),
          ),
          const SizedBox(height: 14),
          Panel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                StepSlider(
                  label: 'Distance to the wall',
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
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: ValueCard(
                        label: 'Echo delay',
                        value: _delay.toStringAsFixed(2),
                        unit: 's',
                        color: c.amber,
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
                        value: '1/${_slow.toStringAsFixed(0)}',
                        unit: 'speed',
                        color: c.textSecondary,
                        compact: true,
                      ),
                    ),
                  ],
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
                  't = 2 x ${_distance.toStringAsFixed(1)} / 343\n'
                  't = ${(2 * _distance).toStringAsFixed(1)} / 343\n'
                  't = ${_delay.toStringAsFixed(3)} s',
                  style: TextStyle(
                    fontSize: 15.5,
                    height: 1.7,
                    fontWeight: FontWeight.w700,
                    color: c.accent,
                  ),
                ),
                const SizedBox(height: 10),
                const Body(
                  'The 2 is the whole trick: the sound goes there and comes '
                  'back, so it covers twice the distance you measured.',
                ),
              ],
            ),
          ),
          Panel(
            margin: EdgeInsets.zero,
            child: Tip(
              audible
                  ? 'At ${_distance.toStringAsFixed(0)} m the return arrives '
                      '${_delay.toStringAsFixed(2)} s later, far enough apart to '
                      'hear as a separate sound.'
                  : 'At ${_distance.toStringAsFixed(0)} m the delay is only '
                      '${(_delay * 1000).toStringAsFixed(0)} ms. Below about '
                      '${WavePhysics.minEchoDistance(_v).toStringAsFixed(0)} m you '
                      'get reverberation, a smeared tail, instead of an echo.',
              icon: audible ? Icons.hearing : Icons.hearing_disabled,
              color: audible ? c.blue : c.amber,
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
    required this.colors,
    required this.distanceM,
    required this.speedMs,
    required this.delayS,
  }) : super(repaint: clock);

  final SimClock clock;
  final WaveColors colors;
  final double distanceM;
  final double speedMs;
  final double delayS;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final rr = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, w, h),
      const Radius.circular(18),
    );
    canvas.drawRRect(rr, Paint()..color = colors.canvasTop);
    canvas.save();
    canvas.clipRRect(rr);

    const personX = 32.0;
    final wallX = w - 30.0;
    final span = wallX - personX;
    final midY = h * 0.52;

    canvas.drawLine(
      Offset(0, h - 24),
      Offset(w, h - 24),
      Paint()
        ..color = fade(colors.stroke, 0.9)
        ..strokeWidth = 1.4,
    );
    canvas.drawRect(
      Rect.fromLTWH(wallX, h * 0.16, 22, h * 0.66),
      Paint()..color = colors.wall,
    );
    canvas.drawCircle(
        Offset(personX, midY - 22), 9, Paint()..color = colors.accent);
    canvas.drawLine(
      Offset(personX, midY - 13),
      Offset(personX, midY + 16),
      Paint()
        ..color = colors.accent
        ..strokeWidth = 3.4,
    );

    final t = clock.seconds;
    final travelled = speedMs * t;
    final done = travelled >= 2 * distanceM;
    final out = travelled <= distanceM;
    final posM = (out ? travelled : 2 * distanceM - travelled)
        .clamp(0.0, distanceM);
    final x = personX + (posM / distanceM) * span;

    if (!done && t > 0) {
      for (var i = 0; i < 3; i++) {
        canvas.drawArc(
          Rect.fromCircle(center: Offset(x, midY), radius: 8.0 + i * 9),
          out ? -math.pi / 2.4 : math.pi - math.pi / 2.4,
          math.pi / 1.2,
          false,
          Paint()
            ..color = fade(out ? colors.compression : colors.amber,
                (0.85 - i * 0.22) * (out ? 1.0 : 0.72))
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3.0 - i * 0.6,
        );
      }
    }

    _text(canvas, '${math.min(t, delayS).toStringAsFixed(2)} s',
        Offset(w / 2, 10), done ? colors.amber : colors.textPrimary,
        size: 17, centered: true);
    _text(
      canvas,
      done
          ? 'ECHO HEARD'
          : (t <= 0 ? 'READY' : (out ? 'TRAVELLING OUT' : 'COMING BACK')),
      Offset(w / 2, 32),
      done ? colors.amber : colors.textTertiary,
      centered: true,
    );
    _text(canvas, '${distanceM.toStringAsFixed(0)} m', Offset(w / 2, h - 20),
        colors.textSecondary, centered: true);
    canvas.restore();
  }

  void _text(Canvas canvas, String s, Offset at, Color color,
      {double size = 11.5, bool centered = false}) {
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
      old.distanceM != distanceM ||
      old.delayS != delayS ||
      old.colors != colors;
}
