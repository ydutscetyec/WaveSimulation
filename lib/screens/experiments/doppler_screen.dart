import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../services/doppler_physics.dart';
import '../../theme/wave_theme.dart';
import '../../widgets/sim_clock.dart';
import '../../widgets/ui_kit.dart';

/// Module 6 - Doppler effect.
///
/// The wavefronts are drawn as circles centred on the position the source
/// occupied when it emitted them, each expanding at the wave speed. The
/// bunching in front of a moving source is therefore a consequence of the
/// geometry rather than something stretched by hand, and the printed observed
/// frequency comes from the same numbers.
///
/// The view spans 400 m, so a 343 m/s front crosses it in about 1.2 s and the
/// whole thing runs in real time.
class DopplerScreen extends StatefulWidget {
  const DopplerScreen({super.key});

  @override
  State<DopplerScreen> createState() => _DopplerScreenState();
}

class _DopplerScreenState extends State<DopplerScreen> {
  static const double _v = DopplerPhysics.speedOfSoundAir;
  static const double _spanM = 400;

  double _emittedHz = 2.0; // low, so individual fronts are visible
  double _sourceSpeed = 60; // + means moving right, towards the observer
  double _observerSpeed = 0;
  bool _running = true;

  double? get _observed => DopplerPhysics.observedFrequency(
        emittedHz: _emittedHz,
        waveSpeed: _v,
        sourceSpeed: _sourceSpeed,
        observerSpeed: _observerSpeed,
      );

  DopplerRegime get _regime =>
      DopplerPhysics.regime(waveSpeed: _v, sourceSpeed: _sourceSpeed);

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final observed = _observed;
    final shift = DopplerPhysics.pitchShiftFraction(
      emittedHz: _emittedHz,
      waveSpeed: _v,
      sourceSpeed: _sourceSpeed,
      observerSpeed: _observerSpeed,
    );
    final mach = DopplerPhysics.machNumber(
        waveSpeed: _v, sourceSpeed: _sourceSpeed);

    return LabScaffold(
      title: 'Doppler effect',
      subtitle: 'Moving source, moving listener',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 230,
            width: double.infinity,
            child: ClockHost(
              hz: 1,
              running: _running,
              builder: (context, clock) => CustomPaint(
                painter: _DopplerPainter(
                  clock: clock,
                  colors: c,
                  emittedHz: _emittedHz,
                  sourceSpeed: _sourceSpeed,
                  observerSpeed: _observerSpeed,
                  spanM: _spanM,
                  waveSpeed: _v,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                    backgroundColor:
                        _running ? fade(c.accent, 0.18) : c.accent,
                    foregroundColor: _running ? c.accent : c.onAccent,
                  ),
                  onPressed: () => setState(() => _running = !_running),
                  icon: Icon(_running ? Icons.pause : Icons.play_arrow),
                  label: Text(_running ? 'Pause' : 'Play'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                    foregroundColor: c.textPrimary,
                    side: BorderSide(color: c.stroke),
                  ),
                  onPressed: () => setState(() {
                    _emittedHz = 2;
                    _sourceSpeed = 60;
                    _observerSpeed = 0;
                    _running = true;
                  }),
                  icon: const Icon(Icons.restart_alt),
                  label: const Text('Reset'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          Panel(
            accent: _regime == DopplerRegime.subsonic ? null : c.amber,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: ValueCard(
                        label: 'Emitted',
                        value: _emittedHz.toStringAsFixed(1),
                        unit: 'Hz',
                        compact: true,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ValueCard(
                        label: 'Heard',
                        value: observed?.toStringAsFixed(2) ?? '—',
                        unit: observed == null ? null : 'Hz',
                        color: c.amber,
                        compact: true,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ValueCard(
                        label: 'Mach',
                        value: mach.toStringAsFixed(2),
                        color: mach >= 1 ? c.red : c.blue,
                        compact: true,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                if (observed != null) ...[
                  Text(
                    "f' = f (v + v_o) / (v - v_s)\n"
                    "f' = ${_emittedHz.toStringAsFixed(1)} x "
                    "(343 ${_observerSpeed >= 0 ? '+' : '-'} "
                    "${_observerSpeed.abs().toStringAsFixed(0)}) / "
                    "(343 ${_sourceSpeed >= 0 ? '-' : '+'} "
                    "${_sourceSpeed.abs().toStringAsFixed(0)})\n"
                    "f' = ${observed.toStringAsFixed(2)} Hz",
                    style: TextStyle(
                      fontSize: 14.5,
                      height: 1.65,
                      fontWeight: FontWeight.w700,
                      color: c.accent,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Body(
                    'A pitch shift of ${(shift! * 100).toStringAsFixed(1)} %. '
                    'A 440 Hz horn would be heard at '
                    '${(440 * (1 + shift)).toStringAsFixed(0)} Hz, because the '
                    'ratio does not depend on the frequency.',
                    size: 13.5,
                  ),
                ] else
                  Body(
                    _regime == DopplerRegime.sonic
                        ? 'At exactly the speed of sound the formula divides '
                            'by zero. The fronts pile up on the source itself, '
                            'and there is no single frequency to report.'
                        : 'Above the speed of sound the source outruns its own '
                            'wavefronts. A cone forms behind it, and a listener '
                            'ahead hears nothing at all until the cone arrives. '
                            'The simple formula no longer applies.',
                    size: 14.5,
                    color: c.amber,
                  ),
              ],
            ),
          ),

          Panel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const PanelTitle('Motion', icon: Icons.swap_horiz),
                StepSlider(
                  label: 'Source speed (+ towards the listener)',
                  value: _sourceSpeed,
                  min: -300,
                  max: 600,
                  step: 10,
                  readout: '${_sourceSpeed.toStringAsFixed(0)} m/s',
                  onChanged: (v) => setState(() => _sourceSpeed = v),
                ),
                StepSlider(
                  label: 'Listener speed (+ towards the source)',
                  value: _observerSpeed,
                  min: -150,
                  max: 150,
                  step: 10,
                  color: c.blue,
                  readout: '${_observerSpeed.toStringAsFixed(0)} m/s',
                  onChanged: (v) => setState(() => _observerSpeed = v),
                ),
                StepSlider(
                  label: 'Emitted frequency',
                  value: _emittedHz,
                  min: 1,
                  max: 5,
                  step: 0.5,
                  color: c.amber,
                  readout: '${_emittedHz.toStringAsFixed(1)} Hz',
                  onChanged: (v) => setState(() => _emittedHz = v),
                ),
                const SizedBox(height: 6),
                Body(
                  'The frequency is deliberately low so you can see individual '
                  'wavefronts. Real sound is hundreds of hertz, but the shift '
                  'ratio is identical at any frequency.',
                  size: 13,
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
                const PanelTitle('Sign convention', icon: Icons.rule),
                const Body(
                  'Positive means moving towards the other party, for both '
                  'source and listener. Both raise the pitch when positive. '
                  'Mixing conventions is the usual way Doppler problems go '
                  'wrong, so it is stated here and used everywhere.',
                ),
                const SizedBox(height: 10),
                const Body(
                  'Moving the source and moving the listener are not '
                  'equivalent, even at the same speed. The medium is at rest '
                  'and the speeds are measured against it. Try 30 m/s on each '
                  'slider in turn and compare the two readings.',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DopplerPainter extends CustomPainter {
  _DopplerPainter({
    required this.clock,
    required this.colors,
    required this.emittedHz,
    required this.sourceSpeed,
    required this.observerSpeed,
    required this.spanM,
    required this.waveSpeed,
  }) : super(repaint: clock);

  final SimClock clock;
  final WaveColors colors;
  final double emittedHz;
  final double sourceSpeed;
  final double observerSpeed;
  final double spanM;
  final double waveSpeed;

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

    final pxPerM = w / spanM;
    final midY = h * 0.55;
    final t = clock.seconds;

    // The source loops across the view so the demonstration repeats.
    final period = spanM / math.max(sourceSpeed.abs(), 1);
    final loop = sourceSpeed.abs() < 1 ? 0.0 : (t % (period * 1.4));
    final sourceX = sourceSpeed >= 0
        ? (sourceSpeed.abs() < 1 ? spanM * 0.25 : loop * sourceSpeed)
        : spanM - loop * sourceSpeed.abs();

    final observerX = spanM * 0.82 - observerSpeed * t * 0.0;

    // Wavefronts: one per emission interval, each centred where the source
    // was at that moment and expanded by v * age.
    final interval = 1 / emittedHz;
    final newest = (t / interval).floor();
    for (var n = newest; n >= 0 && n > newest - 14; n--) {
      final emitTime = n * interval;
      final age = t - emitTime;
      if (age <= 0) continue;
      final radius = DopplerPhysics.frontRadius(
        waveSpeed: waveSpeed,
        age: age,
      );
      if (radius > spanM * 1.6) continue;

      final emitLoop = sourceSpeed.abs() < 1
          ? 0.0
          : (emitTime % (period * 1.4));
      final emitX = sourceSpeed >= 0
          ? (sourceSpeed.abs() < 1 ? spanM * 0.25 : emitLoop * sourceSpeed)
          : spanM - emitLoop * sourceSpeed.abs();

      final fade0 = (1 - radius / (spanM * 1.6)).clamp(0.0, 1.0);
      canvas.drawCircle(
        Offset(emitX * pxPerM, midY),
        radius * pxPerM,
        Paint()
          ..color = fade(colors.compression, 0.55 * fade0)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.8,
      );
    }

    // ground
    canvas.drawLine(
      Offset(0, h - 26),
      Offset(w, h - 26),
      Paint()
        ..color = fade(colors.stroke, 0.9)
        ..strokeWidth = 1.2,
    );

    // listener
    canvas.drawCircle(
      Offset(observerX * pxPerM, midY),
      9,
      Paint()..color = colors.blue,
    );
    _label(canvas, 'LISTENER', Offset(observerX * pxPerM, midY + 16),
        colors.blue, centered: true);

    // source
    canvas.drawCircle(
      Offset(sourceX * pxPerM, midY),
      8,
      Paint()..color = colors.amber,
    );
    if (sourceSpeed.abs() >= 1) {
      final dir = sourceSpeed > 0 ? 1 : -1;
      canvas.drawLine(
        Offset(sourceX * pxPerM, midY),
        Offset(sourceX * pxPerM + dir * 24, midY),
        Paint()
          ..color = colors.amber
          ..strokeWidth = 2.4,
      );
    }
    _label(canvas, 'SOURCE', Offset(sourceX * pxPerM, midY - 28), colors.amber,
        centered: true);

    _label(canvas, '${spanM.toStringAsFixed(0)} m across',
        Offset(w / 2, h - 20), colors.textTertiary, centered: true);
    _label(canvas, 'v = ${waveSpeed.toStringAsFixed(0)} m/s',
        const Offset(10, 8), colors.textSecondary);
    canvas.restore();
  }

  void _label(Canvas canvas, String s, Offset at, Color color,
      {bool centered = false}) {
    final tp = TextPainter(
      text: TextSpan(
        text: s,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(centered ? at.dx - tp.width / 2 : at.dx, at.dy));
  }

  @override
  bool shouldRepaint(covariant _DopplerPainter old) =>
      old.emittedHz != emittedHz ||
      old.sourceSpeed != sourceSpeed ||
      old.observerSpeed != observerSpeed ||
      old.colors != colors;
}
