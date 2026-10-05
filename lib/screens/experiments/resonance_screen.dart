import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../models/simulation_state.dart';
import '../../services/wave_physics.dart';
import '../../theme/app_theme.dart';
import '../../widgets/sim_clock.dart';
import '../../widgets/ui_kit.dart';

/// Air column closed at one end - a cup, a bottle, a test tube.
///   f_n = (2n-1) v / (4L)
/// The response is a driven damped oscillator, so the amplitude really does
/// depend on how far the driving frequency is from f0. Nothing here is a
/// colour change standing in for physics.
class ResonanceScreen extends StatefulWidget {
  const ResonanceScreen({super.key});

  @override
  State<ResonanceScreen> createState() => _ResonanceScreenState();
}

class _ResonanceScreenState extends State<ResonanceScreen> {
  static const double _v = 343;
  static const double _q = 18; // quality factor of a cup-sized air column

  double _lengthCm = 17.0;
  double _driveHz = 380;

  double get _lengthM => _lengthCm / 100;
  double get _f0 => WavePhysics.closedPipeResonance(_v, _lengthM, 1);
  double get _response => WavePhysics.resonanceResponse(_driveHz, _f0, _q);
  bool get _atResonance => _response > 0.85;

  void _snapToResonance() {
    setState(() => _driveHz = _f0.clamp(20.0, 2000.0));
    final state = SimScope.read(context);
    if (state.awardBadge('RESONANCE FINDER')) {
      showBadge(context, 'RESONANCE FINDER');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_atResonance) {
      final state = SimScope.read(context);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (state.awardBadge('RESONANCE FINDER')) {
          showBadge(context, 'RESONANCE FINDER');
        }
      });
    }

    return LabScaffold(
      title: 'Resonance',
      subtitle: 'Drive an air column and find its natural frequency',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 220,
            width: double.infinity,
            child: ClockHost(
              hz: 1.1,
              builder: (context, clock) => CustomPaint(
                painter: _TubePainter(
                  clock: clock,
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
            padding: const EdgeInsets.symmetric(vertical: 13),
            decoration: BoxDecoration(
              color: _atResonance
                  ? fade(AppColors.amber, 0.18)
                  : AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: _atResonance ? AppColors.amber : AppColors.stroke,
                width: _atResonance ? 1.6 : 1,
              ),
            ),
            child: Center(
              child: Text(
                _atResonance
                    ? 'RESONANCE  -  response ${(_response * 100).toStringAsFixed(0)}%'
                    : 'Response ${(_response * 100).toStringAsFixed(0)}% of maximum',
                style: TextStyle(
                  fontSize: 16.5,
                  fontWeight: FontWeight.w700,
                  color: _atResonance ? AppColors.amber : AppColors.textMuted,
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Panel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const PanelTitle('Air column length', icon: Icons.height),
                StepSlider(
                  label: 'A short cup, a tall glass, a bottle',
                  value: _lengthCm,
                  min: 4,
                  max: 60,
                  step: 0.5,
                  readout: '${_lengthCm.toStringAsFixed(1)} cm',
                  onChanged: (v) => setState(() => _lengthCm = v),
                ),
                const SizedBox(height: 10),
                const PanelTitle('Driving frequency', icon: Icons.speed),
                StepSlider(
                  label: 'The tone you play at the opening',
                  value: _driveHz,
                  min: 20,
                  max: 2000,
                  step: 5,
                  color: AppColors.amber,
                  readout: '${_driveHz.toStringAsFixed(0)} Hz',
                  onChanged: (v) => setState(() => _driveHz = v),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(50),
                    foregroundColor: AppColors.amber,
                    side: const BorderSide(color: AppColors.amber),
                  ),
                  onPressed: _snapToResonance,
                  icon: const Icon(Icons.my_location),
                  label: Text('Jump to f1 = ${_f0.toStringAsFixed(0)} Hz'),
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
                  height: 120,
                  width: double.infinity,
                  child: CustomPaint(
                    painter: _ResponseCurvePainter(
                      f0: _f0,
                      drive: _driveHz,
                      q: _q,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Amplitude against driving frequency. The peak is narrow: '
                  'move a little off f1 and the response collapses. That is '
                  'why a glass only sings at one particular pitch.',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textDim,
                    height: 1.45,
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
                const PanelTitle('The calculation', icon: Icons.functions),
                Text(
                  'Closed at one end, so the fundamental fits a quarter '
                  'wavelength:\n\n'
                  'L = lambda / 4   ->   lambda = 4L\n'
                  'f1 = v / lambda = v / (4L)\n'
                  'f1 = 343 / (4 x ${_lengthM.toStringAsFixed(3)})\n'
                  'f1 = ${_f0.toStringAsFixed(0)} Hz',
                  style: const TextStyle(
                    fontSize: 15,
                    height: 1.65,
                    color: AppColors.cyan,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Odd harmonics only: f3 = ${WavePhysics.closedPipeResonance(_v, _lengthM, 2).toStringAsFixed(0)} Hz, '
                  'f5 = ${WavePhysics.closedPipeResonance(_v, _lengthM, 3).toStringAsFixed(0)} Hz. '
                  'A tube open at both ends behaves differently: f_n = n v / 2L, '
                  'and it gets all the harmonics.',
                  style: const TextStyle(
                    fontSize: 14.5,
                    color: AppColors.textMuted,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 12),
                const Explain(
                  'Real cups sit a little below this prediction. An open end '
                  'does not reflect exactly at the rim, so the column behaves '
                  'as if it were slightly longer - the end correction, roughly '
                  '0.6 x radius.',
                  icon: Icons.warning_amber,
                  color: AppColors.amber,
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
    required this.response,
    required this.lengthCm,
  }) : super(repaint: clock);

  final SimClock clock;
  final double response;
  final double lengthCm;

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

    // Tube drawn horizontally: open end left (antinode), closed end right.
    const pad = 36.0;
    final tubeW = w - pad * 2;
    final midY = h / 2;
    final tubeH = math.min(96.0, h * 0.5);

    final wall = Paint()
      ..color = fade(AppColors.textMuted, 0.75)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawLine(Offset(pad, midY - tubeH / 2), Offset(pad + tubeW, midY - tubeH / 2), wall);
    canvas.drawLine(Offset(pad, midY + tubeH / 2), Offset(pad + tubeW, midY + tubeH / 2), wall);
    canvas.drawLine(
      Offset(pad + tubeW, midY - tubeH / 2),
      Offset(pad + tubeW, midY + tubeH / 2),
      wall,
    );

    // Quarter-wave standing pattern: displacement antinode at the open end,
    // node at the closed end.  s(x) = cos(pi*x / 2L) * cos(wt)
    final env = clock.phase;
    final drive = math.cos(env) * (0.12 + 0.88 * response);

    final cols = (tubeW / 7).round();
    final rows = (tubeH / 17).clamp(3, 6).round();
    final rowGap = tubeH / (rows + 1);
    final dot = Paint();
    for (var r = 0; r < rows; r++) {
      final y = midY - tubeH / 2 + rowGap * (r + 1);
      for (var c = 0; c <= cols; c++) {
        final frac = c / cols; // 0 at open end, 1 at closed end
        final shape = math.cos(math.pi * frac / 2);
        final s = shape * drive * 13;
        final crowd = (math.sin(math.pi * frac / 2) * drive).abs();
        dot.color = fade(
          Color.lerp(AppColors.indigo, AppColors.cyan, crowd.clamp(0.0, 1.0)) ??
              AppColors.cyan,
          0.35 + 0.6 * response,
        );
        canvas.drawCircle(
          Offset(pad + frac * tubeW + s, y),
          1.9 + 2.0 * crowd,
          dot,
        );
      }
    }

    // driver at the open end
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(pad - 18 + drive * 5, midY - tubeH / 3, 9, tubeH / 1.5),
        const Radius.circular(4),
      ),
      Paint()..color = fade(AppColors.amber, 0.85),
    );

    _text(canvas, 'OPEN END', Offset(pad - 18, midY + tubeH / 2 + 10),
        AppColors.textDim);
    _text(canvas, 'CLOSED END', Offset(pad + tubeW, midY + tubeH / 2 + 10),
        AppColors.textDim, rightAligned: true);
    _text(canvas, 'ANTINODE', Offset(pad, midY - tubeH / 2 - 17), AppColors.cyan);
    _text(canvas, 'NODE', Offset(pad + tubeW, midY - tubeH / 2 - 17),
        AppColors.indigo,
        rightAligned: true);
    _text(canvas, 'L = ${lengthCm.toStringAsFixed(1)} cm',
        Offset(w / 2, h - 18), AppColors.textMuted, centered: true);
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
      old.response != response || old.lengthCm != lengthCm;
}

class _ResponseCurvePainter extends CustomPainter {
  _ResponseCurvePainter({
    required this.f0,
    required this.drive,
    required this.q,
  });

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
      Paint()..color = AppColors.surfaceHigh,
    );

    const fMin = 20.0;
    const fMax = 2000.0;
    double xOf(double f) => ((f - fMin) / (fMax - fMin)) * w;

    final path = Path();
    for (var i = 0; i <= w.toInt(); i += 2) {
      final f = fMin + (i / w) * (fMax - fMin);
      final a = WavePhysics.resonanceResponse(f, f0, q);
      final y = h - 10 - a * (h - 24);
      if (i == 0) {
        path.moveTo(0, y);
      } else {
        path.lineTo(i.toDouble(), y);
      }
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = AppColors.cyan
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2,
    );

    // f0 marker
    if (f0 >= fMin && f0 <= fMax) {
      canvas.drawLine(
        Offset(xOf(f0), 6),
        Offset(xOf(f0), h - 8),
        Paint()
          ..color = fade(AppColors.textDim, 0.8)
          ..strokeWidth = 1,
      );
    }
    // current drive marker
    final dx = xOf(drive);
    final a = WavePhysics.resonanceResponse(drive, f0, q);
    canvas.drawLine(
      Offset(dx, 6),
      Offset(dx, h - 8),
      Paint()
        ..color = fade(AppColors.amber, 0.9)
        ..strokeWidth = 1.8,
    );
    canvas.drawCircle(
      Offset(dx, h - 10 - a * (h - 24)),
      4.5,
      Paint()..color = AppColors.amber,
    );
  }

  @override
  bool shouldRepaint(covariant _ResponseCurvePainter old) =>
      old.f0 != f0 || old.drive != drive;
}
