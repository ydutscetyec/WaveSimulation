import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../services/wave_physics.dart';
import '../../theme/app_theme.dart';
import '../../widgets/sim_clock.dart';
import '../../widgets/ui_kit.dart';

/// y1 = A sin(kx - wt)   travelling right
/// y2 = A sin(kx + wt)   travelling left (the reflection)
/// y1 + y2 = 2A sin(kx) cos(wt)
///
/// The sum is drawn from the two components, not from the closed form, so the
/// nodes appear because the components really do cancel there.
class StandingWaveScreen extends StatefulWidget {
  const StandingWaveScreen({super.key});

  @override
  State<StandingWaveScreen> createState() => _StandingWaveScreenState();
}

class _StandingWaveScreenState extends State<StandingWaveScreen> {
  int _harmonic = 3;
  bool _running = true;
  static const double _lengthM = 1.0;
  static const double _v = 343;

  /// String fixed at both ends: L = n*lambda/2  ->  lambda = 2L/n
  double get _lambda => 2 * _lengthM / _harmonic;
  double get _frequency => WavePhysics.frequencyFor(_v, _lambda);

  @override
  Widget build(BuildContext context) {
    return LabScaffold(
      title: 'Standing waves',
      subtitle: 'What happens when a wave meets its own reflection',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 300,
            width: double.infinity,
            child: ClockHost(
              hz: 0.55,
              running: _running,
              builder: (context, clock) => CustomPaint(
                painter: _StandingPainter(
                  clock: clock,
                  harmonic: _harmonic,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Graph representation: the vertical axis is displacement, not the '
            'physical shape of air. In a real pipe the same pattern exists as '
            'compressions and rarefactions along the tube.',
            style: TextStyle(fontSize: 13.5, color: AppColors.textDim, height: 1.4),
          ),
          const SizedBox(height: 14),
          Panel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const PanelTitle('Harmonic', icon: Icons.tune),
                StepSlider(
                  label: 'How many half-wavelengths fit in the length',
                  value: _harmonic.toDouble(),
                  min: 1,
                  max: 6,
                  step: 1,
                  divisions: 5,
                  readout: 'n = $_harmonic',
                  onChanged: (v) => setState(() => _harmonic = v.round()),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: ValueCard(
                        label: 'Wavelength',
                        value: _lambda.toStringAsFixed(2),
                        unit: 'm',
                        color: AppColors.amber,
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
                        color: AppColors.indigo,
                        compact: true,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(50),
                    foregroundColor: AppColors.text,
                    side: const BorderSide(color: AppColors.stroke),
                  ),
                  onPressed: () => setState(() => _running = !_running),
                  icon: Icon(_running ? Icons.pause : Icons.play_arrow),
                  label: Text(_running ? 'Freeze' : 'Resume'),
                ),
              ],
            ),
          ),
          Panel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const PanelTitle('Reading the picture', icon: Icons.visibility),
                const _Row(
                  color: AppColors.cyan,
                  title: 'Travelling right',
                  text: 'y1 = A sin(kx - wt). Watch one crest: it moves.',
                ),
                const _Row(
                  color: AppColors.blue,
                  title: 'Travelling left',
                  text: 'y2 = A sin(kx + wt). The reflection coming back.',
                ),
                const _Row(
                  color: AppColors.amber,
                  title: 'The sum',
                  text: 'y = 2A sin(kx) cos(wt). Crests no longer travel - '
                      'they grow and shrink in place.',
                ),
                const SizedBox(height: 6),
                const Text(
                  'A node sits where sin(kx) = 0, which happens every half '
                  'wavelength. The two waves arrive there permanently out of '
                  'step, so that point never moves at all. Antinodes sit '
                  'halfway between the nodes.',
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const PanelTitle('Where you meet this', icon: Icons.piano),
                Text(
                  'Fixed at both ends over L = 1.00 m: lambda = 2L / n = '
                  '${_lambda.toStringAsFixed(2)} m, so f = v / lambda = '
                  '${_frequency.toStringAsFixed(0)} Hz.',
                  style: const TextStyle(
                    fontSize: 14.5,
                    color: AppColors.cyan,
                    fontWeight: FontWeight.w600,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'This is what a guitar string, a flute and the air column in '
                  'the resonance experiment are all doing. It is also why a '
                  'room has places where the bass is strong and places where '
                  'it nearly disappears.',
                  style: TextStyle(
                    fontSize: 14.5,
                    color: AppColors.textMuted,
                    height: 1.5,
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

class _Row extends StatelessWidget {
  const _Row({required this.color, required this.title, required this.text});

  final Color color;
  final String title;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 11),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 18,
            height: 3,
            margin: const EdgeInsets.only(top: 8),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  text,
                  style: const TextStyle(
                    fontSize: 14.5,
                    color: AppColors.textMuted,
                    height: 1.4,
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

class _StandingPainter extends CustomPainter {
  _StandingPainter({required this.clock, required this.harmonic})
      : super(repaint: clock);

  final SimClock clock;
  final int harmonic;

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

    final laneH = h / 3;
    final phase = clock.phase;
    final k = harmonic * math.pi; // over a normalised length of 1
    final amp = laneH * 0.22; // sum reaches 2*amp, which must stay inside the lane

    Path curve(double midY, double Function(double u) f) {
      final p = Path();
      for (var i = 0; i <= w.toInt(); i += 2) {
        final u = i / w;
        final y = midY - f(u) * amp;
        if (i == 0) {
          p.moveTo(0, y);
        } else {
          p.lineTo(i.toDouble(), y);
        }
      }
      return p;
    }

    void axis(double midY) {
      canvas.drawLine(
        Offset(0, midY),
        Offset(w, midY),
        Paint()
          ..color = fade(AppColors.stroke, 0.8)
          ..strokeWidth = 1,
      );
    }

    // lane 1 - right-moving
    final m1 = laneH * 0.5;
    axis(m1);
    canvas.drawPath(
      curve(m1, (u) => math.sin(k * u - phase)),
      Paint()
        ..color = AppColors.cyan
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2,
    );
    _text(canvas, 'TRAVELLING RIGHT', const Offset(8, 6), AppColors.cyan);

    // lane 2 - left-moving
    final m2 = laneH * 1.5;
    axis(m2);
    canvas.drawPath(
      curve(m2, (u) => math.sin(k * u + phase)),
      Paint()
        ..color = AppColors.blue
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2,
    );
    _text(canvas, 'TRAVELLING LEFT', Offset(8, laneH + 6), AppColors.blue);

    // lane 3 - superposition
    final m3 = laneH * 2.5;
    axis(m3);

    // envelope
    canvas.drawPath(
      curve(m3, (u) => 2 * math.sin(k * u)),
      Paint()
        ..color = fade(AppColors.amber, 0.22)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4,
    );
    canvas.drawPath(
      curve(m3, (u) => -2 * math.sin(k * u)),
      Paint()
        ..color = fade(AppColors.amber, 0.22)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4,
    );
    canvas.drawPath(
      curve(m3, (u) => math.sin(k * u - phase) + math.sin(k * u + phase)),
      Paint()
        ..color = AppColors.amber
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.8,
    );
    _text(canvas, 'SUM = STANDING WAVE', Offset(8, laneH * 2 + 6),
        AppColors.amber);

    // node and antinode markers
    for (var n = 0; n <= harmonic; n++) {
      final x = n / harmonic * w;
      canvas.drawCircle(Offset(x, m3), 4, Paint()..color = AppColors.indigo);
      if (n == 0 || n == harmonic) continue;
    }
    _text(canvas, 'NODE', Offset(w / harmonic - 14, m3 + 10), AppColors.indigo);
    final antiX = (0.5 / harmonic) * w;
    canvas.drawCircle(
      Offset(antiX, m3),
      4,
      Paint()..color = AppColors.amber,
    );
    _text(canvas, 'ANTINODE', Offset(antiX - 16, m3 - laneH * 0.42),
        AppColors.amber);
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
      old.harmonic != harmonic;
}
