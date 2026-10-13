import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../services/wave_physics.dart';
import '../../theme/wave_theme.dart';
import '../../widgets/sim_clock.dart';
import '../../widgets/ui_kit.dart';

/// y1 = A sin(kx - wt) travelling right
/// y2 = A sin(kx + wt) travelling left (the reflection)
/// sum  = 2A sin(kx) cos(wt)
/// The sum is drawn by adding the two components, so the nodes appear because
/// the components really cancel there.
class StandingWaveScreen extends StatefulWidget {
  const StandingWaveScreen({super.key});

  @override
  State<StandingWaveScreen> createState() => _StandingWaveScreenState();
}

class _StandingWaveScreenState extends State<StandingWaveScreen> {
  static const double _lengthM = 1.0;
  static const double _v = 343;

  int _harmonic = 3;
  bool _running = true;

  double get _lambda => 2 * _lengthM / _harmonic;
  double get _frequency => WavePhysics.frequencyFor(_v, _lambda);

  @override
  Widget build(BuildContext context) {
    final c = context.c;

    return LabScaffold(
      title: 'Standing waves',
      subtitle: 'A wave meeting its own reflection',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 280,
            width: double.infinity,
            child: ClockHost(
              hz: 0.55,
              running: _running,
              builder: (context, clock) => CustomPaint(
                painter: _StandingPainter(
                  clock: clock,
                  colors: c,
                  harmonic: _harmonic,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Body(
            'Graph representation: the vertical axis is displacement, not the '
            'shape of air. In a pipe the same pattern exists as compressions '
            'along the tube.',
            size: 13.5,
            color: c.textTertiary,
          ),
          const SizedBox(height: 14),
          Panel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                StepSlider(
                  label: 'Harmonic',
                  value: _harmonic.toDouble(),
                  min: 1,
                  max: 6,
                  step: 1,
                  divisions: 5,
                  readout: 'n = $_harmonic',
                  onChanged: (v) => setState(() => _harmonic = v.round()),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: ValueCard(
                        label: 'Wavelength',
                        value: _lambda.toStringAsFixed(2),
                        unit: 'm',
                        color: c.amber,
                        compact: true,
                      ),
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: ValueCard(
                        label: 'Frequency',
                        value: _frequency.toStringAsFixed(0),
                        unit: 'Hz',
                        compact: true,
                      ),
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: ValueCard(
                        label: 'Nodes',
                        value: '${_harmonic + 1}',
                        color: c.blue,
                        compact: true,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                    foregroundColor: c.textPrimary,
                    side: BorderSide(color: c.stroke),
                  ),
                  onPressed: () => setState(() => _running = !_running),
                  icon: Icon(_running ? Icons.pause : Icons.play_arrow),
                  label: Text(_running ? 'Freeze' : 'Resume'),
                ),
              ],
            ),
          ),
          Panel(
            margin: EdgeInsets.zero,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const PanelTitle('Reading it', icon: Icons.visibility),
                const Body(
                  'A node sits where sin(kx) = 0, every half wavelength. The '
                  'two waves always arrive there out of step, so that point '
                  'never moves. Antinodes sit halfway between.',
                ),
                const SizedBox(height: 10),
                Text(
                  'Fixed at both ends over L = 1.00 m: lambda = 2L / n = '
                  '${_lambda.toStringAsFixed(2)} m, f = v / lambda = '
                  '${_frequency.toStringAsFixed(0)} Hz.',
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: c.accent,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 10),
                const Body(
                  'This is what a guitar string, a flute and the resonance '
                  'experiment are all doing, and why a room has places where '
                  'the bass nearly disappears.',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StandingPainter extends CustomPainter {
  _StandingPainter({
    required this.clock,
    required this.colors,
    required this.harmonic,
  }) : super(repaint: clock);

  final SimClock clock;
  final WaveColors colors;
  final int harmonic;

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

    final laneH = h / 3;
    final phase = clock.phase;
    final k = harmonic * math.pi;
    final amp = laneH * 0.22; // the sum reaches 2*amp, still inside the lane

    Path curve(double midY, double Function(double u) f) {
      final p = Path();
      for (var i = 0; i <= w.toInt(); i += 2) {
        final y = midY - f(i / w) * amp;
        if (i == 0) {
          p.moveTo(0, y);
        } else {
          p.lineTo(i.toDouble(), y);
        }
      }
      return p;
    }

    void axis(double midY) => canvas.drawLine(
          Offset(0, midY),
          Offset(w, midY),
          Paint()
            ..color = fade(colors.stroke, 0.9)
            ..strokeWidth = 1,
        );

    Paint stroke(Color col, double width) => Paint()
      ..color = col
      ..style = PaintingStyle.stroke
      ..strokeWidth = width;

    final m1 = laneH * 0.5;
    axis(m1);
    canvas.drawPath(
        curve(m1, (u) => math.sin(k * u - phase)), stroke(colors.accent, 2.2));
    _text(canvas, 'TRAVELLING RIGHT', const Offset(10, 8), colors.accent);

    final m2 = laneH * 1.5;
    axis(m2);
    canvas.drawPath(
        curve(m2, (u) => math.sin(k * u + phase)), stroke(colors.blue, 2.2));
    _text(canvas, 'TRAVELLING LEFT', Offset(10, laneH + 8), colors.blue);

    final m3 = laneH * 2.5;
    axis(m3);
    canvas.drawPath(curve(m3, (u) => 2 * math.sin(k * u)),
        stroke(fade(colors.amber, 0.25), 1.4));
    canvas.drawPath(curve(m3, (u) => -2 * math.sin(k * u)),
        stroke(fade(colors.amber, 0.25), 1.4));
    canvas.drawPath(
      curve(m3, (u) => math.sin(k * u - phase) + math.sin(k * u + phase)),
      stroke(colors.amber, 2.8),
    );
    _text(canvas, 'SUM = STANDING WAVE', Offset(10, laneH * 2 + 8),
        colors.amber);

    for (var n = 0; n <= harmonic; n++) {
      canvas.drawCircle(
        Offset(n / harmonic * w, m3),
        4,
        Paint()..color = colors.blue,
      );
    }
    final antiX = (0.5 / harmonic) * w;
    canvas.drawCircle(Offset(antiX, m3), 4, Paint()..color = colors.amber);
    _text(canvas, 'NODE', Offset(w / harmonic - 16, m3 + 10), colors.blue);
    _text(canvas, 'ANTINODE', Offset(antiX - 18, m3 - laneH * 0.40),
        colors.amber);
    canvas.restore();
  }

  void _text(Canvas canvas, String s, Offset at, Color color) {
    final tp = TextPainter(
      text: TextSpan(
        text: s,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.6,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, at);
  }

  @override
  bool shouldRepaint(covariant _StandingPainter old) =>
      old.harmonic != harmonic || old.colors != colors;
}
