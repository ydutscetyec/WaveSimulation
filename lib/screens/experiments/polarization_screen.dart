import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../services/em_physics.dart';
import '../../theme/wave_theme.dart';
import '../../widgets/sim_clock.dart';
import '../../widgets/ui_kit.dart';

/// MODULE 12 - Polarisation.
///
/// Unpolarised light passes through up to three polarisers. Every intensity
/// on screen comes from [EmPhysics.throughStack], so the numbers, the beam
/// thickness and the brightness patch can never disagree with each other.
///
/// The module is built around the result that surprises people: two crossed
/// polarisers pass nothing, but inserting a THIRD between them at 45 degrees
/// lets light through again. Nothing special is coded for that case - it
/// falls out of applying Malus's law to each neighbouring pair, which is why
/// the third polariser is a toggle rather than a separate demonstration.
class PolarizationScreen extends StatefulWidget {
  const PolarizationScreen({super.key});

  @override
  State<PolarizationScreen> createState() => _PolarizationScreenState();
}

class _PolarizationScreenState extends State<PolarizationScreen> {
  double _a1 = 0; // degrees
  double _a2 = 90;
  double _a3 = 45;
  bool _useThird = false;
  bool _running = true;

  /// Transmission axes in radians, in the order the light meets them.
  /// The middle polariser is physically between the other two, so when it is
  /// switched on it goes in the middle of the list, not on the end.
  List<double> get _axesRad {
    final deg = _useThird ? [_a1, _a3, _a2] : [_a1, _a2];
    return deg.map((d) => d * math.pi / 180).toList();
  }

  /// Intensity after each stage, starting with the incoming unpolarised beam.
  List<double> get _stages {
    final axes = _axesRad;
    final out = <double>[1.0];
    for (var i = 1; i <= axes.length; i++) {
      out.add(EmPhysics.throughStack(1.0, axes.sublist(0, i)));
    }
    return out;
  }

  double get _finalIntensity => _stages.last;

  /// Angle between the first and last polariser, which is what the classic
  /// two-polariser form of Malus's law uses.
  double get _crossAngleDeg {
    final d = (_a2 - _a1).abs() % 180;
    return d > 90 ? 180 - d : d;
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final stages = _stages;
    final pct = _finalIntensity * 100;

    return LabScaffold(
      title: 'Polarisation',
      subtitle: 'Malus\'s law, and the three-polariser surprise',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: SizedBox(
              height: 230,
              width: double.infinity,
              child: ClockHost(
                hz: 0.5,
                running: _running,
                builder: (context, clock) => CustomPaint(
                  painter: _BenchPainter(
                    clock: clock,
                    colors: c,
                    anglesDeg: _useThird ? [_a1, _a3, _a2] : [_a1, _a2],
                    stages: stages,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Body(
            'Beam thickness is amplitude, which goes as √I. The patch on the '
            'right is what reaches the screen.',
            size: 13.5,
            color: c.textTertiary,
          ),
          const SizedBox(height: 14),
          Panel(
            accent: pct < 0.5 ? c.red : null,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const PanelTitle('Transmitted', icon: Icons.light_mode_outlined),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: ValueCard(
                        label: 'Final intensity',
                        value: pct < 0.01 && pct > 0
                            ? '<0.01'
                            : pct.toStringAsFixed(2),
                        unit: '% of I₀',
                        color: pct < 0.5 ? c.red : c.accent,
                      ),
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: ValueCard(
                        label: 'First to last',
                        value: '${_crossAngleDeg.toStringAsFixed(0)}°',
                        color: c.amber,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Body(
                  _verdict(),
                  color: c.textSecondary,
                  size: 13.5,
                ),
              ],
            ),
          ),
          Panel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const PanelTitle('Polarisers', icon: Icons.tune),
                const SizedBox(height: 4),
                StepSlider(
                  label: 'First polariser',
                  value: _a1,
                  min: 0,
                  max: 180,
                  step: 1,
                  divisions: 180,
                  readout: '${_a1.toStringAsFixed(0)}°',
                  color: c.blue,
                  onChanged: (v) => setState(() => _a1 = v),
                ),
                const SizedBox(height: 10),
                StepSlider(
                  label: 'Last polariser',
                  value: _a2,
                  min: 0,
                  max: 180,
                  step: 1,
                  divisions: 180,
                  readout: '${_a2.toStringAsFixed(0)}°',
                  color: c.accent,
                  onChanged: (v) => setState(() => _a2 = v),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: Body(
                        'Middle polariser',
                        color: c.textSecondary,
                      ),
                    ),
                    Switch(
                      value: _useThird,
                      onChanged: (v) => setState(() => _useThird = v),
                    ),
                  ],
                ),
                if (_useThird) ...[
                  const SizedBox(height: 4),
                  StepSlider(
                    label: 'Middle polariser',
                    value: _a3,
                    min: 0,
                    max: 180,
                    step: 1,
                    divisions: 180,
                    readout: '${_a3.toStringAsFixed(0)}°',
                    color: c.amber,
                    onChanged: (v) => setState(() => _a3 = v),
                  ),
                ],
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => setState(() {
                          _a1 = 0;
                          _a2 = 90;
                          _a3 = 45;
                          _useThird = false;
                        }),
                        icon: const Icon(Icons.restart_alt),
                        label: const Text('Cross them'),
                      ),
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => setState(() => _running = !_running),
                        icon: Icon(_running ? Icons.pause : Icons.play_arrow),
                        label: Text(_running ? 'Pause' : 'Play'),
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
                const PanelTitle('I = I₀ cos²θ', icon: Icons.show_chart),
                const SizedBox(height: 10),
                SizedBox(
                  height: 130,
                  width: double.infinity,
                  child: CustomPaint(
                    painter: _MalusPainter(
                      colors: c,
                      angleDeg: _crossAngleDeg,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Body(
                  'Angle between the two outer axes, 0° to 90°.',
                  color: c.textTertiary,
                  size: 12.5,
                ),
              ],
            ),
          ),
          Tip(
            _useThird
                ? 'Cross the outer pair at 0° and 90°, then sweep the middle '
                    'one. It peaks at 45°, passing 12.5% of the original. '
                    'Adding a filter made the beam brighter.'
                : 'Set 0° and 90° to extinguish the beam, then switch on the '
                    'middle polariser and set it to 45°.',
            icon: Icons.science_outlined,
          ),
          Panel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const PanelTitle('The physics', icon: Icons.functions),
                const SizedBox(height: 6),
                Body(
                  'A polariser passes only the component of E along its own '
                  'axis, so the amplitude that survives is E₀cosθ. Intensity '
                  'goes as the square of amplitude, which is where the square '
                  'in cos²θ comes from — it is not an extra assumption.',
                  color: c.textSecondary,
                ),
                const SizedBox(height: 10),
                Body(
                  'Unpolarised light at the FIRST polariser is different: its '
                  'polarisation directions are spread evenly over all angles, '
                  'the average of cos² is ½, and exactly half the intensity '
                  'gets through whatever angle you set. Rotating a single '
                  'polariser on its own changes nothing you can see.',
                  color: c.textSecondary,
                ),
                const SizedBox(height: 10),
                Body(
                  'Three polarisers: each stage only ever sees the angle to '
                  'the one immediately before it. 0° → 45° → 90° gives\n'
                  '    ½ × cos²45° × cos²45° = ½ × ½ × ½ = 12.5%\n'
                  'while 0° → 90° alone gives cos²90° = 0.',
                  color: c.textSecondary,
                  size: 13.5,
                ),
                const SizedBox(height: 10),
                Body(
                  'Only transverse waves can be polarised. Sound is '
                  'longitudinal — its oscillation is along the direction of '
                  'travel, so there is no sideways direction to filter, and no '
                  'polariser for sound exists.',
                  color: c.textTertiary,
                  size: 13,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _verdict() {
    final pct = _finalIntensity * 100;
    if (pct < 0.01) {
      return 'Extinguished. The axes are perpendicular, so no component of E '
          'survives the last filter.';
    }
    if (_useThird && _crossAngleDeg > 85) {
      return 'The outer pair is crossed, yet light is getting through. The '
          'middle polariser rotated the surviving component part of the way, '
          'so the last filter no longer sees a perpendicular field.';
    }
    if (pct > 49) {
      return 'Maximum for unpolarised input. The axes are aligned, so the '
          'only loss is the unavoidable half at the first filter.';
    }
    return 'Each filter passes the projection of E onto its own axis.';
  }
}

/// Side view of the optical bench: source, polariser discs, and the beam
/// between them drawn with amplitude proportional to sqrt(intensity).
class _BenchPainter extends CustomPainter {
  _BenchPainter({
    required this.clock,
    required this.colors,
    required this.anglesDeg,
    required this.stages,
  }) : super(repaint: clock);

  final SimClock clock;
  final WaveColors colors;
  final List<double> anglesDeg;

  /// stages[0] is the incoming beam, stages[i] the intensity after filter i.
  final List<double> stages;

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

    final axisY = size.height * 0.46;
    final startX = size.width * 0.07;
    final screenX = size.width * 0.93;
    final n = anglesDeg.length;

    // Evenly space the filters between the source and the screen.
    final slotWidth = (screenX - startX) / (n + 1);
    final filterXs = [
      for (var i = 0; i < n; i++) startX + slotWidth * (i + 1),
    ];

    final maxAmp = size.height * 0.17;
    final phase = clock.phase;

    // Beam segments: source -> f1 -> f2 ... -> screen.
    final bounds = [startX, ...filterXs, screenX];
    for (var i = 0; i < bounds.length - 1; i++) {
      final intensity = stages[i].clamp(0.0, 1.0);
      final amp = maxAmp * math.sqrt(intensity);
      _beam(
        canvas,
        x0: bounds[i],
        x1: bounds[i + 1],
        axisY: axisY,
        amp: amp,
        phase: phase,
        colour: i == 0 ? colors.textTertiary : colors.amber,
        intensity: intensity,
      );
    }

    for (var i = 0; i < n; i++) {
      _filter(canvas, filterXs[i], axisY, anglesDeg[i], size.height * 0.30);
      _caption(
        canvas,
        '${anglesDeg[i].toStringAsFixed(0)}°',
        Offset(filterXs[i], axisY + size.height * 0.30 * 0.5 + 8),
        colors.textSecondary,
      );
    }

    _screen(canvas, screenX, axisY, size, stages.last.clamp(0.0, 1.0));
    _caption(
      canvas,
      'unpolarised',
      Offset(startX + 4, axisY - size.height * 0.30),
      colors.textTertiary,
      size: 11.5,
      centred: false,
    );
  }

  /// A sinusoid whose peak-to-peak height carries the amplitude. At zero
  /// intensity it collapses to the axis, which is the correct picture for an
  /// extinguished beam.
  void _beam(
    Canvas canvas, {
    required double x0,
    required double x1,
    required double axisY,
    required double amp,
    required double phase,
    required Color colour,
    required double intensity,
  }) {
    if (x1 <= x0) return;
    final path = Path();
    const k = 0.12;
    for (double x = x0; x <= x1; x += 2) {
      final y = axisY - amp * math.sin(k * x - phase);
      if (x == x0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2
        ..strokeCap = StrokeCap.round
        ..color = fade(colour, 0.35 + 0.6 * intensity),
    );

    if (amp < 1.2) {
      // Draw the dead beam explicitly rather than leaving a gap.
      canvas.drawLine(
        Offset(x0, axisY),
        Offset(x1, axisY),
        Paint()
          ..strokeWidth = 1.4
          ..color = fade(colors.textTertiary, 0.4),
      );
    }
  }

  /// A polariser drawn end-on-ish: a tall rounded plate with slots at the
  /// transmission angle. The slots are the readable part - they rotate with
  /// the slider, so the angle is visible without reading the number.
  void _filter(
    Canvas canvas,
    double x,
    double axisY,
    double angleDeg,
    double height,
  ) {
    const w = 15.0;
    final r = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(x, axisY), width: w, height: height),
      const Radius.circular(4),
    );
    canvas.drawRRect(r, Paint()..color = fade(colors.glass, 0.55));
    canvas.drawRRect(
      r,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4
        ..color = colors.stroke,
    );

    canvas.save();
    canvas.clipRRect(r);
    canvas.translate(x, axisY);
    canvas.rotate(-angleDeg * math.pi / 180);

    final slot = Paint()
      ..strokeWidth = 1.5
      ..color = fade(colors.accent, 0.85);
    final half = height;
    for (double o = -half; o <= half; o += 5) {
      canvas.drawLine(Offset(o, -half), Offset(o, half), slot);
    }
    canvas.restore();
  }

  void _screen(
    Canvas canvas,
    double x,
    double axisY,
    Size size,
    double intensity,
  ) {
    final box = Rect.fromCenter(
      center: Offset(x, axisY),
      width: 26,
      height: size.height * 0.30,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(box, const Radius.circular(5)),
      Paint()..color = colors.surfaceAlt,
    );
    // Brightness is linear in intensity, with a floor so the plate edge stays
    // visible when the beam is fully extinguished.
    canvas.drawRRect(
      RRect.fromRectAndRadius(box.deflate(3), const Radius.circular(4)),
      Paint()..color = fade(colors.amber, intensity.clamp(0.0, 1.0)),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(box, const Radius.circular(5)),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.3
        ..color = colors.stroke,
    );
  }

  void _caption(
    Canvas canvas,
    String text,
    Offset at,
    Color colour, {
    double size = 12.5,
    bool centred = true,
  }) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: colour,
          fontSize: size,
          fontWeight: FontWeight.w600,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(centred ? at.dx - tp.width / 2 : at.dx, at.dy));
  }

  @override
  bool shouldRepaint(covariant _BenchPainter old) =>
      old.colors != colors ||
      old.stages.length != stages.length ||
      !_sameList(old.stages, stages) ||
      !_sameList(old.anglesDeg, anglesDeg);

  static bool _sameList(List<double> a, List<double> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

/// I/I0 = cos^2(theta) with the current angle marked.
class _MalusPainter extends CustomPainter {
  _MalusPainter({required this.colors, required this.angleDeg});

  final WaveColors colors;
  final double angleDeg;

  @override
  void paint(Canvas canvas, Size size) {
    const padL = 30.0;
    const padB = 18.0;
    final plot = Rect.fromLTRB(padL, 6, size.width - 6, size.height - padB);

    final grid = Paint()
      ..strokeWidth = 1
      ..color = fade(colors.stroke, 0.8);
    for (var i = 0; i <= 4; i++) {
      final y = plot.top + plot.height * i / 4;
      canvas.drawLine(Offset(plot.left, y), Offset(plot.right, y), grid);
    }
    for (var i = 0; i <= 3; i++) {
      final x = plot.left + plot.width * i / 3;
      canvas.drawLine(Offset(x, plot.top), Offset(x, plot.bottom), grid);
    }

    double xOf(double deg) => plot.left + plot.width * deg / 90;
    double yOf(double v) => plot.bottom - plot.height * v;

    final path = Path();
    for (double d = 0; d <= 90; d += 1) {
      final v = EmPhysics.malus(1.0, d * math.pi / 180);
      final p = Offset(xOf(d), yOf(v));
      if (d == 0) {
        path.moveTo(p.dx, p.dy);
      } else {
        path.lineTo(p.dx, p.dy);
      }
    }
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4
        ..color = colors.accent,
    );

    final v = EmPhysics.malus(1.0, angleDeg * math.pi / 180);
    final marker = Offset(xOf(angleDeg.clamp(0, 90)), yOf(v));
    canvas.drawLine(
      Offset(marker.dx, plot.bottom),
      marker,
      Paint()
        ..strokeWidth = 1.4
        ..color = fade(colors.amber, 0.7),
    );
    canvas.drawCircle(marker, 5, Paint()..color = colors.amber);

    _text(canvas, '1.0', Offset(4, plot.top - 4));
    _text(canvas, '0.5', Offset(4, plot.top + plot.height / 2 - 7));
    _text(canvas, '0', Offset(12, plot.bottom - 7));
    _text(canvas, '0°', Offset(plot.left - 6, plot.bottom + 3));
    _text(canvas, '45°', Offset(xOf(45) - 9, plot.bottom + 3));
    _text(canvas, '90°', Offset(plot.right - 18, plot.bottom + 3));
  }

  void _text(Canvas canvas, String s, Offset at) {
    final tp = TextPainter(
      text: TextSpan(
        text: s,
        style: TextStyle(color: colors.textTertiary, fontSize: 10.5),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, at);
  }

  @override
  bool shouldRepaint(covariant _MalusPainter old) =>
      old.angleDeg != angleDeg || old.colors != colors;
}
