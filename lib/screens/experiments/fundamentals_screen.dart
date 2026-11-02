import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../services/wave_physics.dart';
import '../../theme/palette.dart';
import '../../theme/wave_theme.dart';
import '../../widgets/sim_clock.dart';
import '../../widgets/ui_kit.dart';

/// Which quantity is calculated from the other two.
///
/// v = f lambda has three quantities and one equation, so exactly two can be
/// free. Letting all three be dragged independently is the single easiest way
/// to build a simulation that quietly contradicts its own physics, so the
/// choice of which one is derived is made explicit and put in front of the
/// student instead of being hidden.
enum DerivedQuantity { wavelength, frequency, speed }

/// MODULE 1 - Wave fundamentals.
///
/// The anatomy screen: crest, trough, amplitude, wavelength, equilibrium and
/// direction of travel, all labelled on a live wave, plus the relationship
/// that ties the numbers together.
class FundamentalsScreen extends StatefulWidget {
  const FundamentalsScreen({super.key});

  @override
  State<FundamentalsScreen> createState() => _FundamentalsScreenState();
}

class _FundamentalsScreenState extends State<FundamentalsScreen> {
  static const double _defaultAmplitude = 0.55;
  static const double _defaultFrequency = 2.0;
  static const double _defaultWavelength = 1.0;
  static const double _defaultSpeed = 2.0;

  double _amplitude = _defaultAmplitude;
  double _frequency = _defaultFrequency;
  double _wavelength = _defaultWavelength;
  double _speed = _defaultSpeed;

  DerivedQuantity _derived = DerivedQuantity.wavelength;
  bool _running = true;
  bool _labels = true;

  // The derived quantity is recomputed on read, never stored stale, so the
  // readouts and the drawing can never disagree with the equation.
  double get frequency => _derived == DerivedQuantity.frequency
      ? WavePhysics.frequencyFor(_speed, _wavelength)
      : _frequency;

  double get wavelength => _derived == DerivedQuantity.wavelength
      ? WavePhysics.wavelength(_speed, _frequency)
      : _wavelength;

  double get speed =>
      _derived == DerivedQuantity.speed ? _frequency * _wavelength : _speed;

  double get period => WavePhysics.period(frequency);
  double get waveNumber => WavePhysics.waveNumber(wavelength);
  double get angularFrequency => WavePhysics.omega(frequency);

  /// Always show the same number of wavelengths, so the wavelength marker
  /// stays measurable at every setting. The readouts carry the absolute size.
  double get viewWidthM => 2.6 * wavelength;

  void _resetAll() => setState(() {
        _amplitude = _defaultAmplitude;
        _frequency = _defaultFrequency;
        _wavelength = _defaultWavelength;
        _speed = _defaultSpeed;
        _derived = DerivedQuantity.wavelength;
        _running = true;
        _labels = true;
      });

  /// Switching which quantity is derived must not make the wave jump: the
  /// value that is about to become free is seeded from what it currently is.
  void _setDerived(DerivedQuantity d) {
    setState(() {
      final f = frequency, l = wavelength, v = speed;
      _frequency = f;
      _wavelength = l;
      _speed = v;
      _derived = d;
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;

    return LabScaffold(
      title: 'Wave fundamentals',
      subtitle: 'The parts of a wave, and the one equation linking them',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: SizedBox(
              height: 290,
              width: double.infinity,
              child: ClockHost(
                // On-screen rate is fixed so the labels stay readable; the
                // physical frequency lives in the readouts.
                hz: 0.35,
                running: _running,
                builder: (context, clock) => CustomPaint(
                  painter: _AnatomyPainter(
                    clock: clock,
                    colors: c,
                    amplitude: _amplitude,
                    wavelength: wavelength,
                    viewWidthM: viewWidthM,
                    showLabels: _labels,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Body(
            'Pause and the labels stay put, so each part can be read off a '
            'still wave.',
            size: 13.5,
            color: c.textTertiary,
          ),
          const SizedBox(height: 14),
          Panel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const PanelTitle('v = f λ', icon: Icons.functions),
                const SizedBox(height: 4),
                Body(
                  'Three quantities, one equation. Pick which one the other '
                  'two decide — it cannot be dragged while it is derived.',
                  color: c.textSecondary,
                  size: 13.5,
                ),
                const SizedBox(height: 10),
                Segmented(
                  labels: const ['Derive λ', 'Derive f', 'Derive v'],
                  selectedIndex: _derived.index,
                  onSelect: (i) => _setDerived(DerivedQuantity.values[i]),
                ),
              ],
            ),
          ),
          Panel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                StepSlider(
                  label: 'Amplitude',
                  value: _amplitude,
                  min: 0.05,
                  max: 1.0,
                  readout: '${_amplitude.toStringAsFixed(2)} m',
                  color: c.amber,
                  onChanged: (v) => setState(() => _amplitude = v),
                ),
                if (_derived != DerivedQuantity.frequency) ...[
                  const SizedBox(height: 10),
                  StepSlider(
                    label: 'Frequency',
                    value: _frequency,
                    min: 0.2,
                    max: 8.0,
                    readout: '${_frequency.toStringAsFixed(2)} Hz',
                    color: c.blue,
                    onChanged: (v) => setState(() => _frequency = v),
                  ),
                ],
                if (_derived != DerivedQuantity.wavelength) ...[
                  const SizedBox(height: 10),
                  StepSlider(
                    label: 'Wavelength',
                    value: _wavelength,
                    min: 0.1,
                    max: 4.0,
                    readout: '${_wavelength.toStringAsFixed(2)} m',
                    color: c.accent,
                    onChanged: (v) => setState(() => _wavelength = v),
                  ),
                ],
                if (_derived != DerivedQuantity.speed) ...[
                  const SizedBox(height: 10),
                  StepSlider(
                    label: 'Wave speed',
                    value: _speed,
                    min: 0.2,
                    max: 12.0,
                    readout: '${_speed.toStringAsFixed(2)} m/s',
                    color: c.textSecondary,
                    onChanged: (v) => setState(() => _speed = v),
                  ),
                ],
              ],
            ),
          ),
          Panel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const PanelTitle('Measurements', icon: Icons.straighten),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _derivedCard(
                        c,
                        label: 'Wavelength λ',
                        value: wavelength.toStringAsFixed(2),
                        unit: 'm',
                        isDerived: _derived == DerivedQuantity.wavelength,
                        colour: c.accent,
                      ),
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: _derivedCard(
                        c,
                        label: 'Frequency f',
                        value: frequency.toStringAsFixed(2),
                        unit: 'Hz',
                        isDerived: _derived == DerivedQuantity.frequency,
                        colour: c.blue,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 9),
                Row(
                  children: [
                    Expanded(
                      child: _derivedCard(
                        c,
                        label: 'Speed v',
                        value: speed.toStringAsFixed(2),
                        unit: 'm/s',
                        isDerived: _derived == DerivedQuantity.speed,
                        colour: c.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: ValueCard(
                        label: 'Period T',
                        value: period.toStringAsFixed(3),
                        unit: 's',
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
                        value: waveNumber.toStringAsFixed(2),
                        unit: 'rad/m',
                        compact: true,
                      ),
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: ValueCard(
                        label: 'Angular ω',
                        value: angularFrequency.toStringAsFixed(2),
                        unit: 'rad/s',
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
                        onPressed: () => setState(() => _labels = !_labels),
                        icon: const Icon(Icons.label_outline),
                        label: Text(_labels ? 'Hide labels' : 'Show labels'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 9),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _resetAll,
                    icon: const Icon(Icons.restart_alt),
                    label: const Text('Reset all'),
                  ),
                ),
              ],
            ),
          ),
          const Tip(
            'Derive λ, then raise the frequency. The wave speed never moves, '
            'so the wavelength has to shrink — higher frequency and shorter '
            'wavelength are the same fact, not two.',
            icon: Icons.lightbulb_outline,
          ),
          Panel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const PanelTitle('Definitions', icon: Icons.menu_book_outlined),
                const SizedBox(height: 6),
                Body(
                  'Amplitude A — greatest displacement from the equilibrium '
                  'line. It sets how much energy the wave carries, and is '
                  'independent of everything else on this screen.\n\n'
                  'Wavelength λ — distance between two matching points, crest '
                  'to crest or trough to trough.\n\n'
                  'Period T — time for one full cycle to pass a fixed point. '
                  'T = 1/f.\n\n'
                  'Wave speed v — how fast the pattern travels. In a real '
                  'medium this is set by the medium, not by the source, which '
                  'is why "Derive λ" is the honest default.',
                  color: c.textSecondary,
                ),
                const SizedBox(height: 10),
                Body(
                  'k = 2π/λ  and  ω = 2πf  are the same two quantities in '
                  'radians, which is the form y(x,t) = A sin(kx − ωt) needs.',
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

  Widget _derivedCard(
    WaveColors c, {
    required String label,
    required String value,
    required String unit,
    required bool isDerived,
    required Color colour,
  }) =>
      ValueCard(
        label: isDerived ? '$label  (derived)' : label,
        value: value,
        unit: unit,
        color: isDerived ? colour : c.textPrimary,
        compact: true,
      );
}

/// Draws the wave with its parts marked.
///
/// The markers are positioned from the wave's own geometry - the crest marker
/// sits where the drawn curve peaks, the wavelength arrow spans one real
/// period of it - so they cannot drift out of agreement with the curve.
class _AnatomyPainter extends CustomPainter {
  _AnatomyPainter({
    required this.clock,
    required this.colors,
    required this.amplitude,
    required this.wavelength,
    required this.viewWidthM,
    required this.showLabels,
  }) : super(repaint: clock);

  final SimClock clock;
  final WaveColors colors;
  final double amplitude;
  final double wavelength;
  final double viewWidthM;
  final bool showLabels;

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

    final axisY = size.height * 0.5;
    // The amplitude slider has to move the drawn height, or the control is
    // decorative and the labelled "A" arrow would be a fixed-length lie.
    final ampPx = size.height * 0.30 * amplitude.clamp(0.05, 1.0);
    final pxPerM = size.width / viewWidthM;
    final lambdaPx = wavelength * pxPerM;
    final phase = clock.phase;

    // y(x,t) = A sin(kx - wt), with k from the real wavelength.
    final k = 2 * math.pi / math.max(lambdaPx, 1e-6);
    double yAt(double px) => axisY - ampPx * math.sin(k * px - phase);

    _equilibrium(canvas, size, axisY);

    final path = Path();
    for (double x = 0; x <= size.width; x += 1.5) {
      final y = yAt(x);
      if (x == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round
        ..color = colors.accent,
    );

    if (!showLabels) {
      _propagation(canvas, size, axisY);
      return;
    }

    // Crest: kx - phase = pi/2.  Trough: kx - phase = 3pi/2.
    final firstCrest = (math.pi / 2 + phase) / k;
    final firstTrough = (3 * math.pi / 2 + phase) / k;

    final crestX = _wrapInto(firstCrest, lambdaPx, size.width, 0.12);
    final troughX = _wrapInto(firstTrough, lambdaPx, size.width, 0.12);

    if (crestX != null) {
      _dot(canvas, Offset(crestX, yAt(crestX)), colors.amber);
      _text(canvas, 'crest', Offset(crestX, yAt(crestX) - 26), colors.amber);
      _amplitudeArrow(canvas, crestX, axisY, yAt(crestX));
    }
    if (troughX != null) {
      _dot(canvas, Offset(troughX, yAt(troughX)), colors.blue);
      _text(canvas, 'trough', Offset(troughX, yAt(troughX) + 12), colors.blue);
    }

    // Wavelength spans crest to the next crest, measured on the drawn curve.
    if (crestX != null && crestX + lambdaPx < size.width - 4) {
      _wavelengthArrow(canvas, crestX, crestX + lambdaPx, size.height * 0.10);
    }

    _propagation(canvas, size, axisY);
  }

  /// Returns the first position of a repeating feature that lands far enough
  /// inside the canvas for its label to fit, or null if none does.
  double? _wrapInto(double x, double period, double width, double marginFrac) {
    if (period <= 0) return null;
    final margin = width * marginFrac;
    var v = x % period;
    while (v < margin) {
      v += period;
    }
    return v > width - margin ? null : v;
  }

  void _equilibrium(Canvas canvas, Size size, double axisY) {
    final p = Paint()
      ..color = fade(colors.textTertiary, 0.6)
      ..strokeWidth = 1.2;
    for (double x = 0; x < size.width; x += 11) {
      canvas.drawLine(Offset(x, axisY), Offset(x + 6, axisY), p);
    }
    if (showLabels) {
      _text(
        canvas,
        'equilibrium',
        Offset(size.width - 44, axisY + 5),
        colors.textTertiary,
        size: 11.5,
      );
    }
  }

  void _amplitudeArrow(Canvas canvas, double x, double axisY, double crestY) {
    final p = Paint()
      ..color = colors.amber
      ..strokeWidth = 1.8;
    canvas.drawLine(Offset(x, axisY), Offset(x, crestY), p);
    _arrowHead(canvas, Offset(x, crestY), up: true, colour: colors.amber);
    _arrowHead(canvas, Offset(x, axisY), up: false, colour: colors.amber);
    _text(
      canvas,
      'A',
      Offset(x + 9, (axisY + crestY) / 2 - 8),
      colors.amber,
      centred: false,
    );
  }

  void _wavelengthArrow(Canvas canvas, double x1, double x2, double y) {
    final p = Paint()
      ..color = colors.accent
      ..strokeWidth = 1.8;
    canvas.drawLine(Offset(x1, y), Offset(x2, y), p);
    for (final x in [x1, x2]) {
      canvas.drawLine(Offset(x, y - 5), Offset(x, y + 5), p);
    }
    _text(canvas, 'λ', Offset((x1 + x2) / 2, y - 20), colors.accent);
  }

  void _propagation(Canvas canvas, Size size, double axisY) {
    final y = size.height - 16;
    final p = Paint()
      ..color = fade(colors.textTertiary, 0.8)
      ..strokeWidth = 1.6;
    final x1 = size.width * 0.40;
    final x2 = size.width * 0.60;
    canvas.drawLine(Offset(x1, y), Offset(x2, y), p);
    canvas.drawPath(
      Path()
        ..moveTo(x2 + 7, y)
        ..lineTo(x2 - 1, y - 4)
        ..lineTo(x2 - 1, y + 4)
        ..close(),
      Paint()..color = fade(colors.textTertiary, 0.8),
    );
    _text(
      canvas,
      'travels this way',
      Offset(size.width * 0.5, y - 20),
      colors.textTertiary,
      size: 11.5,
    );
  }

  void _dot(Canvas canvas, Offset at, Color colour) {
    canvas.drawCircle(at, 5.5, Paint()..color = colour);
    canvas.drawCircle(
      at,
      5.5,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4
        ..color = fade(colors.canvasBottom, 0.9),
    );
  }

  void _arrowHead(
    Canvas canvas,
    Offset at, {
    required bool up,
    required Color colour,
  }) {
    final d = up ? 1.0 : -1.0;
    canvas.drawPath(
      Path()
        ..moveTo(at.dx, at.dy)
        ..lineTo(at.dx - 4, at.dy + 7 * d)
        ..lineTo(at.dx + 4, at.dy + 7 * d)
        ..close(),
      Paint()..color = colour,
    );
  }

  void _text(
    Canvas canvas,
    String s,
    Offset at,
    Color colour, {
    double size = 13,
    bool centred = true,
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
    tp.paint(canvas, Offset(centred ? at.dx - tp.width / 2 : at.dx, at.dy));
  }

  @override
  bool shouldRepaint(covariant _AnatomyPainter old) =>
      old.amplitude != amplitude ||
      old.wavelength != wavelength ||
      old.viewWidthM != viewWidthM ||
      old.showLabels != showLabels ||
      old.colors != colors;
}
