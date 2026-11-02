import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../services/wave_physics.dart';
import '../../theme/wave_theme.dart';
import '../../widgets/sim_clock.dart';
import '../../widgets/ui_kit.dart';

/// MODULE 2 - Transverse and longitudinal waves.
///
/// Both halves of this screen are driven by the SAME displacement function,
///
///     s(x, t) = A sin(kx - wt)
///
/// and differ only in which direction that displacement is applied: across
/// the propagation axis, or along it. That is the entire distinction between
/// the two wave types, and building the screen this way makes it impossible
/// for the simulation to say otherwise.
///
/// The longitudinal row is drawn as particles whose POSITIONS shift along x.
/// The compressions and rarefactions are then a consequence of where the
/// particles end up, not a shaded band painted on to look convincing. A
/// transverse sine curve standing in for a longitudinal wave is the usual
/// shortcut here and it teaches the wrong thing.
class TransverseLongitudinalScreen extends StatefulWidget {
  const TransverseLongitudinalScreen({super.key});

  @override
  State<TransverseLongitudinalScreen> createState() =>
      _TransverseLongitudinalScreenState();
}

class _TransverseLongitudinalScreenState
    extends State<TransverseLongitudinalScreen> {
  static const double _defaultWavelength = 0.9;
  static const double _defaultAmplitude = 0.6;

  double _wavelength = _defaultWavelength;
  double _amplitude = _defaultAmplitude;
  int _view = 2; // 0 transverse, 1 longitudinal, 2 both
  bool _running = true;

  /// Width of the window in metres. Fixed, so changing the wavelength really
  /// does change how many waves fit on screen.
  static const double _viewWidthM = 3.0;

  double get _k => WavePhysics.waveNumber(_wavelength);
  double get _cyclesInView => _viewWidthM / _wavelength;

  void _resetAll() => setState(() {
        _wavelength = _defaultWavelength;
        _amplitude = _defaultAmplitude;
        _view = 2;
        _running = true;
      });

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final showT = _view == 0 || _view == 2;
    final showL = _view == 1 || _view == 2;

    return LabScaffold(
      title: 'Transverse and longitudinal',
      subtitle: 'One displacement, two directions to apply it',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: SizedBox(
              height: _view == 2 ? 320 : 190,
              width: double.infinity,
              child: ClockHost(
                hz: 0.4,
                running: _running,
                builder: (context, clock) => CustomPaint(
                  painter: _ParticlePainter(
                    clock: clock,
                    colors: c,
                    wavelength: _wavelength,
                    amplitude: _amplitude,
                    viewWidthM: _viewWidthM,
                    showTransverse: showT,
                    showLongitudinal: showL,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Body(
            'The amber particle is one piece of the medium. Pause and step '
            'the frequency around — it returns to the same place every cycle '
            'and never travels with the wave.',
            size: 13.5,
            color: c.textTertiary,
          ),
          const SizedBox(height: 14),
          Panel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const PanelTitle('Wave type', icon: Icons.compare_arrows),
                Segmented(
                  labels: const ['Transverse', 'Longitudinal', 'Both'],
                  selectedIndex: _view,
                  onSelect: (i) => setState(() => _view = i),
                ),
                const SizedBox(height: 12),
                Body(
                  _view == 0
                      ? 'Particles move perpendicular to the direction of '
                          'travel. Crests and troughs are places of maximum '
                          'displacement.'
                      : _view == 1
                          ? 'Particles move parallel to the direction of '
                              'travel. Where they crowd together is a '
                              'compression; where they spread apart, a '
                              'rarefaction.'
                          : 'Same displacement function, same instant in time. '
                              'Only the direction it is applied in differs.',
                  color: c.textSecondary,
                ),
              ],
            ),
          ),
          Panel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                StepSlider(
                  label: 'Wavelength',
                  value: _wavelength,
                  min: 0.25,
                  max: 2.0,
                  readout: '${_wavelength.toStringAsFixed(2)} m',
                  color: c.accent,
                  onChanged: (v) => setState(() => _wavelength = v),
                ),
                const SizedBox(height: 10),
                StepSlider(
                  label: 'Amplitude',
                  value: _amplitude,
                  min: 0.05,
                  max: 1.0,
                  readout: _amplitude.toStringAsFixed(2),
                  color: c.amber,
                  onChanged: (v) => setState(() => _amplitude = v),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ValueCard(
                        label: 'Wavelength',
                        value: _wavelength.toStringAsFixed(2),
                        unit: 'm',
                        color: c.accent,
                        compact: true,
                      ),
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: ValueCard(
                        label: 'Waves in view',
                        value: _cyclesInView.toStringAsFixed(2),
                        compact: true,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 9),
                Row(
                  children: [
                    Expanded(
                      child: ValueCard(
                        label: 'Wave number k',
                        value: _k.toStringAsFixed(2),
                        unit: 'rad/m',
                        compact: true,
                      ),
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: ValueCard(
                        label: 'Displacement',
                        value: _view == 1 ? '∥ travel' : '⊥ travel',
                        color: c.blue,
                        compact: true,
                      ),
                    ),
                  ],
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
            'In "Both", watch the two amber particles. They are at the same '
            'place along the wave and reach their extremes at the same moment '
            '— one moves up, the other along.',
            icon: Icons.lightbulb_outline,
          ),
          Panel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const PanelTitle('The physics', icon: Icons.functions),
                const SizedBox(height: 6),
                Body(
                  's(x,t) = A sin(kx − ωt) gives the displacement of the '
                  'particle whose rest position is x.\n\n'
                  'Transverse: that displacement is applied across the axis, '
                  'so the particle at x sits at height s.\n'
                  'Longitudinal: it is applied along the axis, so the particle '
                  'sits at position x + s.',
                  color: c.textSecondary,
                ),
                const SizedBox(height: 10),
                Body(
                  'Compression is where neighbouring particles crowd together, '
                  'which is where −∂s/∂x = Ak cos(kx − ωt) is positive. It is '
                  'a quarter of a cycle away from maximum displacement, not at '
                  'it — which is why a compression does not line up with a '
                  'crest of the displacement graph.',
                  color: c.textSecondary,
                  size: 13.5,
                ),
                const SizedBox(height: 10),
                Body(
                  'Sound in air is longitudinal: air has no stiffness against '
                  'sideways shear, so there is nothing to carry a transverse '
                  'wave. That is also why sound cannot be polarised.',
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
}

class _ParticlePainter extends CustomPainter {
  _ParticlePainter({
    required this.clock,
    required this.colors,
    required this.wavelength,
    required this.amplitude,
    required this.viewWidthM,
    required this.showTransverse,
    required this.showLongitudinal,
  }) : super(repaint: clock);

  final SimClock clock;
  final WaveColors colors;
  final double wavelength;
  final double amplitude;
  final double viewWidthM;
  final bool showTransverse;
  final bool showLongitudinal;

  /// Particles across the window. Enough to read as a medium, few enough that
  /// individual ones stay trackable.
  static const int _count = 64;

  /// Which particle gets the amber highlight, as a fraction across.
  static const double _trackedFrac = 0.34;

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

    final both = showTransverse && showLongitudinal;
    if (both) {
      _transverse(canvas, size, 0, size.height / 2);
      _divider(canvas, size, size.height / 2);
      _longitudinal(canvas, size, size.height / 2, size.height);
    } else if (showTransverse) {
      _transverse(canvas, size, 0, size.height);
    } else {
      _longitudinal(canvas, size, 0, size.height);
    }
  }

  /// s(x,t) = A sin(kx - wt), normalised to -1..1 and scaled by amplitude.
  double _s(double xMetres) {
    final k = 2 * math.pi / wavelength;
    return amplitude * math.sin(k * xMetres - clock.phase);
  }

  void _transverse(Canvas canvas, Size size, double top, double bottom) {
    final axisY = (top + bottom) / 2;
    final ampPx = (bottom - top) * 0.30;
    final tracked = (_count * _trackedFrac).round();

    _equilibriumLine(canvas, size, axisY);

    for (var i = 0; i < _count; i++) {
      final frac = i / (_count - 1);
      final xPx = frac * size.width;
      final xM = frac * viewWidthM;
      final y = axisY - ampPx * _s(xM);

      final isTracked = i == tracked;
      if (isTracked) {
        // The guide shows the path this particle is confined to.
        canvas.drawLine(
          Offset(xPx, axisY - ampPx * 1.15),
          Offset(xPx, axisY + ampPx * 1.15),
          Paint()
            ..color = fade(colors.amber, 0.35)
            ..strokeWidth = 1.2,
        );
      }
      canvas.drawCircle(
        Offset(xPx, y),
        isTracked ? 6 : 3.4,
        Paint()..color = isTracked ? colors.amber : colors.accent,
      );
    }

    _caption(canvas, 'TRANSVERSE', Offset(10, top + 8), colors.accent);
    _caption(
      canvas,
      'particles move ↕, wave moves →',
      Offset(10, top + 26),
      colors.textTertiary,
      size: 11.5,
    );
  }

  void _longitudinal(Canvas canvas, Size size, double top, double bottom) {
    final axisY = (top + bottom) / 2;
    final tracked = (_count * _trackedFrac).round();

    // Displacement in pixels. Capped below the particle spacing so particles
    // cannot pass through each other - the same A*k < 1 strain limit the
    // sound module uses.
    final spacing = size.width / (_count - 1);
    final maxShift = spacing * 0.9;

    for (var i = 0; i < _count; i++) {
      final frac = i / (_count - 1);
      final restPx = frac * size.width;
      final xM = frac * viewWidthM;
      final shift = maxShift * _s(xM);
      final x = restPx + shift;

      final isTracked = i == tracked;
      if (isTracked) {
        canvas.drawLine(
          Offset(restPx - maxShift * 1.3, axisY),
          Offset(restPx + maxShift * 1.3, axisY),
          Paint()
            ..color = fade(colors.amber, 0.35)
            ..strokeWidth = 1.2,
        );
        // Rest position, so the displacement is visible as an offset from it.
        canvas.drawCircle(
          Offset(restPx, axisY),
          2.2,
          Paint()..color = fade(colors.amber, 0.5),
        );
      }
      canvas.drawCircle(
        Offset(x, axisY),
        isTracked ? 6 : 3.4,
        Paint()..color = isTracked ? colors.amber : colors.compression,
      );
    }

    _caption(canvas, 'LONGITUDINAL', Offset(10, top + 8), colors.compression);
    _caption(
      canvas,
      'particles move ↔, wave moves →',
      Offset(10, top + 26),
      colors.textTertiary,
      size: 11.5,
    );
  }

  void _equilibriumLine(Canvas canvas, Size size, double axisY) {
    final p = Paint()
      ..color = fade(colors.textTertiary, 0.45)
      ..strokeWidth = 1;
    for (double x = 0; x < size.width; x += 10) {
      canvas.drawLine(Offset(x, axisY), Offset(x + 5, axisY), p);
    }
  }

  void _divider(Canvas canvas, Size size, double y) {
    canvas.drawLine(
      Offset(0, y),
      Offset(size.width, y),
      Paint()
        ..color = fade(colors.stroke, 0.9)
        ..strokeWidth = 1.2,
    );
  }

  void _caption(
    Canvas canvas,
    String s,
    Offset at,
    Color colour, {
    double size = 12.5,
  }) {
    final tp = TextPainter(
      text: TextSpan(
        text: s,
        style: TextStyle(
          color: colour,
          fontSize: size,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.4,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, at);
  }

  @override
  bool shouldRepaint(covariant _ParticlePainter old) =>
      old.wavelength != wavelength ||
      old.amplitude != amplitude ||
      old.showTransverse != showTransverse ||
      old.showLongitudinal != showLongitudinal ||
      old.colors != colors;
}
