import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../services/wave_physics.dart';
import '../../theme/wave_theme.dart';
import '../../widgets/sim_clock.dart';
import '../../widgets/ui_kit.dart';

/// Air column closed at one end - a cup, a bottle, a test tube.
/// f_n = (2n-1) v / 4L, and the amplitude is a real driven damped response.
class ResonanceScreen extends StatefulWidget {
  const ResonanceScreen({super.key});

  @override
  State<ResonanceScreen> createState() => _ResonanceScreenState();
}

class _ResonanceScreenState extends State<ResonanceScreen> {
  static const double _v = 343;
  static const double _q = 18;

  double _lengthCm = 17;
  double _driveHz = 380;

  double get _lengthM => _lengthCm / 100;
  double get _f0 => WavePhysics.closedPipeResonance(_v, _lengthM, 1);
  double get _response => WavePhysics.resonanceResponse(_driveHz, _f0, _q);
  bool get _atResonance => _response > 0.85;

  @override
  Widget build(BuildContext context) {
    final c = context.c;

    return LabScaffold(
      title: 'Resonance',
      subtitle: 'Find the natural frequency of an air column',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 200,
            width: double.infinity,
            child: ClockHost(
              hz: 1.1,
              builder: (context, clock) => CustomPaint(
                painter: _TubePainter(
                  clock: clock,
                  colors: c,
                  response: _response,
                  lengthCm: _lengthCm,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: _atResonance ? fade(c.amber, 0.16) : c.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: _atResonance ? c.amber : c.stroke,
                width: _atResonance ? 1.6 : 1,
              ),
            ),
            child: Center(
              child: Text(
                _atResonance
                    ? 'RESONANCE  ·  ${(_response * 100).toStringAsFixed(0)}%'
                    : 'Response ${(_response * 100).toStringAsFixed(0)}% of maximum',
                style: TextStyle(
                  fontSize: 16.5,
                  fontWeight: FontWeight.w800,
                  color: _atResonance ? c.amber : c.textSecondary,
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Panel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                StepSlider(
                  label: 'Air column length',
                  value: _lengthCm,
                  min: 4,
                  max: 60,
                  step: 0.5,
                  readout: '${_lengthCm.toStringAsFixed(1)} cm',
                  onChanged: (v) => setState(() => _lengthCm = v),
                ),
                const SizedBox(height: 12),
                StepSlider(
                  label: 'Driving frequency',
                  value: _driveHz,
                  min: 20,
                  max: 2000,
                  step: 5,
                  color: c.amber,
                  readout: '${_driveHz.toStringAsFixed(0)} Hz',
                  onChanged: (v) => setState(() => _driveHz = v),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(50),
                    foregroundColor: c.amber,
                    side: BorderSide(color: c.amber),
                  ),
                  onPressed: () => setState(
                      () => _driveHz = _f0.clamp(20.0, 2000.0)),
                  label: Text('Jump to f1 = ${_f0.toStringAsFixed(0)} Hz'),
                  icon: const Icon(Icons.my_location),
                ),
              ],
            ),
          ),
          Panel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const PanelTitle('Response curve', icon: Icons.show_chart),
                SizedBox(
                  height: 116,
                  width: double.infinity,
                  child: CustomPaint(
                    painter: _CurvePainter(
                      colors: c,
                      f0: _f0,
                      drive: _driveHz,
                      q: _q,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Body(
                  'The peak is narrow. Move a little off f1 and the response '
                  'collapses, which is why a glass sings at one pitch only.',
                  size: 13.5,
                  color: c.textTertiary,
                ),
              ],
            ),
          ),
          Panel(
            margin: EdgeInsets.zero,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const PanelTitle('The calculation', icon: Icons.functions),
                Text(
                  'L = lambda / 4   ->   lambda = 4L\n'
                  'f1 = v / 4L = 343 / (4 x ${_lengthM.toStringAsFixed(3)})\n'
                  'f1 = ${_f0.toStringAsFixed(0)} Hz',
                  style: TextStyle(
                    fontSize: 15,
                    height: 1.7,
                    fontWeight: FontWeight.w700,
                    color: c.accent,
                  ),
                ),
                const SizedBox(height: 10),
                Body(
                  'Odd harmonics only: f3 = '
                  '${WavePhysics.closedPipeResonance(_v, _lengthM, 2).toStringAsFixed(0)} Hz, '
                  'f5 = ${WavePhysics.closedPipeResonance(_v, _lengthM, 3).toStringAsFixed(0)} Hz. '
                  'A tube open at both ends gets all of them: f_n = n v / 2L.',
                ),
                const SizedBox(height: 10),
                const Tip(
                  'Real cups ring slightly lower. An open end does not reflect '
                  'exactly at the rim, so the column behaves as if it were a '
                  'little longer.',
                  icon: Icons.warning_amber,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TubePainter extends CustomPainter {
  _TubePainter({
    required this.clock,
    required this.colors,
    required this.response,
    required this.lengthCm,
  }) : super(repaint: clock);

  final SimClock clock;
  final WaveColors colors;
  final double response;
  final double lengthCm;

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

    const pad = 40.0;
    final tubeW = w - pad * 2;
    final midY = h / 2;
    final tubeH = math.min(92.0, h * 0.5);

    final wallPaint = Paint()
      ..color = colors.textSecondary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawLine(Offset(pad, midY - tubeH / 2),
        Offset(pad + tubeW, midY - tubeH / 2), wallPaint);
    canvas.drawLine(Offset(pad, midY + tubeH / 2),
        Offset(pad + tubeW, midY + tubeH / 2), wallPaint);
    canvas.drawLine(Offset(pad + tubeW, midY - tubeH / 2),
        Offset(pad + tubeW, midY + tubeH / 2), wallPaint);

    // quarter wave: displacement antinode at the open end, node at the closed
    final drive = math.cos(clock.phase) * (0.12 + 0.88 * response);
    final cols = (tubeW / 7).round();
    final rows = (tubeH / 17).clamp(3, 6).round();
    final rowGap = tubeH / (rows + 1);
    final dot = Paint();
    for (var r = 0; r < rows; r++) {
      final y = midY - tubeH / 2 + rowGap * (r + 1);
      for (var i = 0; i <= cols; i++) {
        final frac = i / cols;
        final s = math.cos(math.pi * frac / 2) * drive * 13;
        final crowd =
            (math.sin(math.pi * frac / 2) * drive).abs().clamp(0.0, 1.0);
        dot.color = fade(
          Color.lerp(colors.rarefaction, colors.compression, crowd) ??
              colors.compression,
          0.35 + 0.6 * response,
        );
        canvas.drawCircle(
            Offset(pad + frac * tubeW + s, y), 2.0 + 2.0 * crowd, dot);
      }
    }

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(pad - 19 + drive * 5, midY - tubeH / 3, 9, tubeH / 1.5),
        const Radius.circular(4),
      ),
      Paint()..color = colors.amber,
    );

    _text(canvas, 'ANTINODE', Offset(pad, midY - tubeH / 2 - 18),
        colors.compression);
    _text(canvas, 'NODE', Offset(pad + tubeW, midY - tubeH / 2 - 18),
        colors.textTertiary, rightAligned: true);
    _text(canvas, 'OPEN', Offset(pad - 20, midY + tubeH / 2 + 11),
        colors.textTertiary);
    _text(canvas, 'CLOSED', Offset(pad + tubeW, midY + tubeH / 2 + 11),
        colors.textTertiary, rightAligned: true);
    _text(canvas, 'L = ${lengthCm.toStringAsFixed(1)} cm',
        Offset(w / 2, h - 19), colors.textSecondary, centered: true);
    canvas.restore();
  }

  void _text(Canvas canvas, String s, Offset at, Color color,
      {bool rightAligned = false, bool centered = false}) {
    final tp = TextPainter(
      text: TextSpan(
        text: s,
        style: TextStyle(
          color: color,
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    var dx = at.dx;
    if (rightAligned) dx -= tp.width;
    if (centered) dx -= tp.width / 2;
    tp.paint(canvas, Offset(dx, at.dy));
  }

  @override
  bool shouldRepaint(covariant _TubePainter old) =>
      old.response != response ||
      old.lengthCm != lengthCm ||
      old.colors != colors;
}

class _CurvePainter extends CustomPainter {
  _CurvePainter({
    required this.colors,
    required this.f0,
    required this.drive,
    required this.q,
  });

  final WaveColors colors;
  final double f0;
  final double drive;
  final double q;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, w, h),
        const Radius.circular(12),
      ),
      Paint()..color = colors.surfaceAlt,
    );

    const fMin = 20.0;
    const fMax = 2000.0;
    double xOf(double f) => ((f - fMin) / (fMax - fMin)) * w;

    final path = Path();
    for (var i = 0; i <= w.toInt(); i += 2) {
      final f = fMin + (i / w) * (fMax - fMin);
      final y = h - 10 - WavePhysics.resonanceResponse(f, f0, q) * (h - 24);
      if (i == 0) {
        path.moveTo(0, y);
      } else {
        path.lineTo(i.toDouble(), y);
      }
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = colors.accent
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.3,
    );

    final dx = xOf(drive);
    canvas.drawLine(
      Offset(dx, 6),
      Offset(dx, h - 8),
      Paint()
        ..color = fade(colors.amber, 0.9)
        ..strokeWidth = 1.8,
    );
    canvas.drawCircle(
      Offset(
        dx,
        h - 10 - WavePhysics.resonanceResponse(drive, f0, q) * (h - 24),
      ),
      4.5,
      Paint()..color = colors.amber,
    );
  }

  @override
  bool shouldRepaint(covariant _CurvePainter old) =>
      old.f0 != f0 || old.drive != drive || old.colors != colors;
}
