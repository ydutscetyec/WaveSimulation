import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../services/wave_physics.dart';
import '../../theme/palette.dart';
import '../../theme/wave_theme.dart';
import '../../widgets/sim_clock.dart';
import '../../widgets/ui_kit.dart';

/// Properties of one string.
class _Medium {
  _Medium({required this.tension, required this.density});

  /// Tension T, newtons.
  double tension;

  /// Linear mass density mu, kg per metre.
  double density;

  /// v = sqrt(T / mu)
  double get speed => math.sqrt(tension / density);

  double wavelengthAt(double frequencyHz) =>
      WavePhysics.wavelength(speed, frequencyHz);

  /// Time for a pulse to cross a string of this length.
  double transitTime(double lengthM) => lengthM / speed;
}

/// MODULE 3 - Wave speed and the medium.
///
/// Two strings side by side, driven at the SAME frequency, with independent
/// tension and linear mass density. The point the comparison makes is the one
/// students most often get backwards: the source sets the frequency, the
/// medium sets the speed, and the wavelength is whatever those two force it
/// to be.
///
/// Pulse race mode is the direct version of the same claim - two pulses
/// released together, arriving apart.
class WaveSpeedScreen extends StatefulWidget {
  const WaveSpeedScreen({super.key});

  @override
  State<WaveSpeedScreen> createState() => _WaveSpeedScreenState();
}

class _WaveSpeedScreenState extends State<WaveSpeedScreen> {
  /// String length, metres. Both strings are the same length so the race is
  /// a fair test of speed alone.
  static const double _lengthM = 2.0;

  /// Simulated seconds per real second. A pulse crosses in well under a
  /// second at these speeds, which is too fast to watch at full rate.
  static const double _timeRate = 0.3;

  final _a = _Medium(tension: 8, density: 0.05);
  final _b = _Medium(tension: 8, density: 0.20);

  double _frequency = 8;
  bool _race = true;
  bool _running = true;

  /// Rebuilt on reset to restart the ClockHost's Ticker from zero.
  Key _clockKey = UniqueKey();

  void _restartRace() => setState(() => _clockKey = UniqueKey());

  void _resetAll() => setState(() {
        _a
          ..tension = 8
          ..density = 0.05;
        _b
          ..tension = 8
          ..density = 0.20;
        _frequency = 8;
        _race = true;
        _running = true;
        _clockKey = UniqueKey();
      });

  double get _speedRatio => _a.speed / _b.speed;

  @override
  Widget build(BuildContext context) {
    final c = context.c;

    return LabScaffold(
      title: 'Wave speed and the medium',
      subtitle: 'v = √(T/μ) — the string decides, not the source',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: SizedBox(
              height: 250,
              width: double.infinity,
              child: ClockHost(
                key: _clockKey,
                hz: 0.5,
                timeRate: _timeRate,
                running: _running,
                builder: (context, clock) => CustomPaint(
                  painter: _TwoStringPainter(
                    clock: clock,
                    colors: c,
                    a: _a,
                    b: _b,
                    frequency: _frequency,
                    lengthM: _lengthM,
                    race: _race,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Body(
            _race
                ? 'Both pulses leave the left end at the same instant.'
                : 'Both strings are driven at the same frequency. Count the '
                    'waves on each.',
            size: 13.5,
            color: c.textTertiary,
          ),
          const SizedBox(height: 14),
          Panel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const PanelTitle('Mode', icon: Icons.timeline),
                Segmented(
                  labels: const ['Pulse race', 'Continuous'],
                  selectedIndex: _race ? 0 : 1,
                  onSelect: (i) => setState(() => _race = i == 0),
                ),
                if (_race) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _restartRace,
                      icon: const Icon(Icons.replay),
                      label: const Text('Release both pulses'),
                    ),
                  ),
                ] else ...[
                  const SizedBox(height: 12),
                  StepSlider(
                    label: 'Driving frequency (both strings)',
                    value: _frequency,
                    min: 2,
                    max: 20,
                    readout: '${_frequency.toStringAsFixed(1)} Hz',
                    color: c.blue,
                    onChanged: (v) => setState(() => _frequency = v),
                  ),
                ],
              ],
            ),
          ),
          _stringPanel(c, 'String A', _a, c.accent),
          _stringPanel(c, 'String B', _b, c.amber),
          Panel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const PanelTitle('Comparison', icon: Icons.compare),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: ValueCard(
                        label: 'Speed ratio A : B',
                        value: '${_speedRatio.toStringAsFixed(2)} : 1',
                        color: c.blue,
                        compact: true,
                      ),
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: ValueCard(
                        label: _race ? 'Arrival gap' : 'Wavelength ratio',
                        value: _race
                            ? '${((_b.transitTime(_lengthM) - _a.transitTime(_lengthM)).abs() * 1000).toStringAsFixed(0)} ms'
                            : '${_speedRatio.toStringAsFixed(2)} : 1',
                        compact: true,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Body(
                  'The wavelength ratio equals the speed ratio exactly, '
                  'because the frequency is common to both. λ = v/f with f '
                  'fixed leaves λ proportional to v.',
                  color: c.textSecondary,
                  size: 13.5,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => setState(() => _running = !_running),
                        icon: Icon(_running ? Icons.pause : Icons.play_arrow),
                        label: Text(_running ? 'Pause' : 'Play'),
                      ),
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _resetAll,
                        icon: const Icon(Icons.restart_alt),
                        label: const Text('Reset all'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Tip(
            'Quadruple the tension and the speed only doubles — the square '
            'root means a big change in the string buys a modest change in '
            'speed. Mass per metre works the other way: heavier is slower.',
            icon: Icons.lightbulb_outline,
          ),
          Panel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const PanelTitle('The physics', icon: Icons.functions),
                const SizedBox(height: 6),
                Body(
                  'v = √(T/μ)\n'
                  '    T — tension in the string, newtons\n'
                  '    μ — mass per unit length, kg/m\n\n'
                  'Tension is the restoring force pulling a displaced piece of '
                  'string back; μ is the inertia resisting it. More restoring '
                  'force or less inertia means a faster wave, which is why one '
                  'is on top and the other underneath.',
                  color: c.textSecondary,
                ),
                const SizedBox(height: 10),
                Body(
                  'Nothing about the source appears in that equation. Driving '
                  'the string harder changes the amplitude, and driving it '
                  'faster changes the frequency, but neither changes v. Set '
                  'both strings to the same tension and density and the race '
                  'ends in a dead heat whatever you do with the frequency.',
                  color: c.textSecondary,
                  size: 13.5,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _stringPanel(
    WaveColors c,
    String title,
    _Medium m,
    Color colour,
  ) =>
      Panel(
        accent: colour,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PanelTitle(title, icon: Icons.linear_scale),
            const SizedBox(height: 4),
            StepSlider(
              label: 'Tension T',
              value: m.tension,
              min: 2,
              max: 20,
              readout: '${m.tension.toStringAsFixed(1)} N',
              color: colour,
              onChanged: (v) => setState(() => m.tension = v),
            ),
            const SizedBox(height: 10),
            StepSlider(
              label: 'Mass per metre μ',
              value: m.density,
              min: 0.02,
              max: 0.20,
              readout: '${m.density.toStringAsFixed(3)} kg/m',
              color: colour,
              onChanged: (v) => setState(() => m.density = v),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ValueCard(
                    label: 'Speed v',
                    value: m.speed.toStringAsFixed(2),
                    unit: 'm/s',
                    color: colour,
                    compact: true,
                  ),
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: ValueCard(
                    label: _race ? 'Crossing time' : 'Wavelength λ',
                    value: _race
                        ? '${(m.transitTime(_lengthM) * 1000).toStringAsFixed(0)} ms'
                        : m.wavelengthAt(_frequency).toStringAsFixed(2),
                    unit: _race ? null : 'm',
                    compact: true,
                  ),
                ),
              ],
            ),
          ],
        ),
      );
}

class _TwoStringPainter extends CustomPainter {
  _TwoStringPainter({
    required this.clock,
    required this.colors,
    required this.a,
    required this.b,
    required this.frequency,
    required this.lengthM,
    required this.race,
  }) : super(repaint: clock);

  final SimClock clock;
  final WaveColors colors;
  final _Medium a;
  final _Medium b;
  final double frequency;
  final double lengthM;
  final bool race;

  /// Gaussian pulse half-width, metres.
  static const double _pulseWidthM = 0.11;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.clipRect(rect);
    canvas.drawRect(
      rect,
      Paint()
        ..shader = ui.Gradient.linear(
          rect.topCenter,
          rect.bottomCenter,
          [colors.canvasTop, colors.canvasBottom],
        ),
    );

    _string(canvas, size, a, size.height * 0.30, colors.accent, 'A');
    _string(canvas, size, b, size.height * 0.72, colors.amber, 'B');

    if (race) {
      _finishLine(canvas, size);
      _clockReadout(canvas, size);
    }
  }

  void _string(
    Canvas canvas,
    Size size,
    _Medium m,
    double axisY,
    Color colour,
    String label,
  ) {
    final left = size.width * 0.07;
    final right = size.width * 0.94;
    final span = right - left;
    final pxPerM = span / lengthM;
    final ampPx = size.height * 0.15;

    canvas.drawLine(
      Offset(left, axisY),
      Offset(right, axisY),
      Paint()
        ..color = fade(colors.textTertiary, 0.3)
        ..strokeWidth = 1,
    );

    final path = Path();
    for (double px = left; px <= right; px += 1.5) {
      final xM = (px - left) / pxPerM;
      final y = axisY - ampPx * _displacement(m, xM);
      if (px == left) {
        path.moveTo(px, y);
      } else {
        path.lineTo(px, y);
      }
    }
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.6
        ..strokeCap = StrokeCap.round
        ..color = colour,
    );

    // Post at the driven end.
    canvas.drawRect(
      Rect.fromLTWH(left - 7, axisY - ampPx * 1.4, 5, ampPx * 2.8),
      Paint()..color = fade(colors.steel, 0.9),
    );

    _text(
      canvas,
      '$label   v = ${m.speed.toStringAsFixed(1)} m/s',
      Offset(left, axisY - ampPx * 1.5 - 16),
      colour,
    );
  }

  /// Normalised displacement, -1..1.
  double _displacement(_Medium m, double xM) {
    if (race) {
      // A single Gaussian travelling at this string's own speed. It stops at
      // the far end rather than wrapping, so the arrival is a clear event.
      final front = m.speed * clock.seconds;
      if (front > lengthM + 3 * _pulseWidthM) return 0;
      final u = (xM - front) / _pulseWidthM;
      if (u.abs() > 4) return 0;
      return math.exp(-u * u);
    }
    // Continuous drive: same frequency on both strings, wavelength set by the
    // medium through k = 2 pi f / v.
    final k = 2 * math.pi * frequency / m.speed;
    return math.sin(k * xM - clock.phase);
  }

  void _finishLine(Canvas canvas, Size size) {
    final x = size.width * 0.94;
    final p = Paint()
      ..color = fade(colors.red, 0.75)
      ..strokeWidth = 1.6;
    for (double y = 8; y < size.height - 8; y += 10) {
      canvas.drawLine(Offset(x, y), Offset(x, y + 5), p);
    }
  }

  void _clockReadout(Canvas canvas, Size size) {
    final aDone = a.speed * clock.seconds >= lengthM;
    final bDone = b.speed * clock.seconds >= lengthM;
    final label = aDone && bDone
        ? 'both arrived'
        : aDone
            ? 'A arrived'
            : bDone
                ? 'B arrived'
                : '${(clock.seconds * 1000).toStringAsFixed(0)} ms';
    _text(
      canvas,
      label,
      Offset(size.width * 0.07, size.height - 20),
      colors.textSecondary,
      size: 12.5,
    );
  }

  void _text(
    Canvas canvas,
    String s,
    Offset at,
    Color colour, {
    double size = 13,
  }) {
    final tp = TextPainter(
      text: TextSpan(
        text: s,
        style: TextStyle(
          color: colour,
          fontSize: size,
          fontWeight: FontWeight.w700,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, at);
  }

  @override
  bool shouldRepaint(covariant _TwoStringPainter old) =>
      old.race != race ||
      old.frequency != frequency ||
      old.a.speed != a.speed ||
      old.b.speed != b.speed ||
      old.colors != colors;
}
