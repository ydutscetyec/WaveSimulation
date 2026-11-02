import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../services/em_physics.dart';
import '../../services/wave_physics.dart';
import '../../theme/palette.dart';
import '../../theme/wave_theme.dart';
import '../../widgets/sim_clock.dart';
import '../../widgets/ui_kit.dart';

/// MODULE 11 - Light and electromagnetic waves.
///
/// Shows the electric and magnetic fields of a plane electromagnetic wave in
/// vacuum, drawn in an oblique projection so both planes are visible at once.
///
/// Three things the picture has to get right, because they are what students
/// usually have backwards:
///
///  * E and B are IN PHASE. Both peak at the same place and both vanish at the
///    same place. Drawing B shifted by a quarter cycle is a common textbook
///    error and would be visible here.
///  * E and B are PERPENDICULAR to each other and both are perpendicular to
///    the direction of travel.
///  * The wave needs no medium. The axis is empty - there are no particles
///    drawn, unlike every mechanical module in the app.
///
/// The wavelength spans 20 decades, so the slider works in log10(lambda).
class EmWaveScreen extends StatefulWidget {
  const EmWaveScreen({super.key});

  @override
  State<EmWaveScreen> createState() => _EmWaveScreenState();
}

class _EmWaveScreenState extends State<EmWaveScreen> {
  /// log10 of the wavelength in metres.
  double _logLambda = math.log(5.5e-7) / math.ln10; // green light

  bool _running = true;
  bool _showB = true;

  double get _lambda => math.pow(10, _logLambda).toDouble();
  double get _frequency => EmPhysics.frequencyFor(_lambda);
  double get _periodS => WavePhysics.period(_frequency);
  double get _photonEv => EmPhysics.photonEnergyEv(_frequency);
  EmBand get _band => EmBand.forWavelength(_lambda);

  /// Physical colour, but only inside the visible band. Everywhere else the
  /// colour is a label and the UI says as much rather than implying that
  /// X-rays are blue.
  Color get _waveColour => _band == EmBand.visible
      ? EmBand.visibleColour(_lambda * 1e9)
      : _band.color;

  void _selectBand(EmBand b) => setState(
        () => _logLambda = math.log(b.centreWavelengthM) / math.ln10,
      );

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final band = _band;

    return LabScaffold(
      title: 'Electromagnetic waves',
      subtitle: 'Two fields, no medium, one speed',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: SizedBox(
              height: 270,
              width: double.infinity,
              child: ClockHost(
                hz: 0.4,
                running: _running,
                builder: (context, clock) => CustomPaint(
                  painter: _EmPainter(
                    clock: clock,
                    colors: c,
                    waveColour: _waveColour,
                    showB: _showB,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Body(
            'E (vertical) and B (horizontal, drawn going into the page) peak '
            'together and vanish together. The axis itself is empty: there is '
            'nothing here to vibrate.',
            size: 13.5,
            color: c.textTertiary,
          ),
          const SizedBox(height: 14),
          Panel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const PanelTitle('Spectrum', icon: Icons.gradient),
                const SizedBox(height: 8),
                SizedBox(
                  height: 46,
                  width: double.infinity,
                  child: CustomPaint(
                    painter: _SpectrumPainter(
                      colors: c,
                      logLambda: _logLambda,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                ChipRow<EmBand>(
                  items: EmBand.all,
                  labelOf: (b) => b.shortName,
                  selected: band,
                  onSelect: _selectBand,
                  colorOf: (b, _) => b.color,
                ),
                const SizedBox(height: 10),
                Body(band.note, color: c.textSecondary, size: 13.5),
              ],
            ),
          ),
          Panel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                StepSlider(
                  label: 'Wavelength (log scale)',
                  value: _logLambda,
                  min: -16,
                  max: 5,
                  readout: _formatMetres(_lambda),
                  color: _waveColour,
                  onChanged: (v) => setState(() => _logLambda = v),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ValueCard(
                        label: 'Frequency',
                        value: _formatHz(_frequency),
                        compact: true,
                        color: c.blue,
                      ),
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: ValueCard(
                        label: 'Period',
                        value: _formatSeconds(_periodS),
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
                        label: 'Photon energy',
                        value: _formatEv(_photonEv),
                        compact: true,
                        color: c.amber,
                      ),
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: ValueCard(
                        label: 'Speed in vacuum',
                        value: '2.998×10⁸',
                        unit: 'm/s',
                        compact: true,
                        color: c.accent,
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
                        onPressed: () => setState(() => _showB = !_showB),
                        icon: const Icon(Icons.swap_calls),
                        label: Text(_showB ? 'Hide B' : 'Show B'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Tip(
            'Drag across 20 decades and the speed readout never moves. In a '
            'vacuum every electromagnetic wave travels at exactly c, so '
            'raising the frequency can only shorten the wavelength.',
            icon: Icons.speed,
          ),
          Panel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const PanelTitle('The physics', icon: Icons.functions),
                const SizedBox(height: 6),
                Body(
                  'c = f λ  with c = 299 792 458 m/s exactly, by definition of '
                  'the metre.\n'
                  'E = h f  gives the photon energy, h = 6.626×10⁻³⁴ J s.\n\n'
                  'A changing electric field creates a magnetic field and a '
                  'changing magnetic field creates an electric field. Each '
                  'sustains the other, so the pair propagates on its own with '
                  'nothing to travel through. That is why light crosses space '
                  'and sound does not.',
                  color: c.textSecondary,
                ),
                const SizedBox(height: 10),
                Body(
                  'Colour above is physical only inside the visible band. '
                  'Elsewhere it is a label — infrared and radio have no colour.',
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

  // --- readout formatting -------------------------------------------------

  static String _formatMetres(double m) {
    if (m >= 1e3) return '${(m / 1e3).toStringAsFixed(2)} km';
    if (m >= 1) return '${m.toStringAsFixed(2)} m';
    if (m >= 1e-2) return '${(m * 1e2).toStringAsFixed(2)} cm';
    if (m >= 1e-3) return '${(m * 1e3).toStringAsFixed(2)} mm';
    if (m >= 1e-6) return '${(m * 1e6).toStringAsFixed(2)} µm';
    if (m >= 1e-9) return '${(m * 1e9).toStringAsFixed(1)} nm';
    if (m >= 1e-12) return '${(m * 1e12).toStringAsFixed(1)} pm';
    return '${(m * 1e15).toStringAsFixed(2)} fm';
  }

  static String _formatHz(double f) {
    if (f >= 1e21) return '${(f / 1e21).toStringAsFixed(1)} ZHz';
    if (f >= 1e18) return '${(f / 1e18).toStringAsFixed(1)} EHz';
    if (f >= 1e15) return '${(f / 1e15).toStringAsFixed(1)} PHz';
    if (f >= 1e12) return '${(f / 1e12).toStringAsFixed(1)} THz';
    if (f >= 1e9) return '${(f / 1e9).toStringAsFixed(1)} GHz';
    if (f >= 1e6) return '${(f / 1e6).toStringAsFixed(1)} MHz';
    if (f >= 1e3) return '${(f / 1e3).toStringAsFixed(1)} kHz';
    return '${f.toStringAsFixed(1)} Hz';
  }

  static String _formatSeconds(double s) {
    if (s >= 1e-3) return '${(s * 1e3).toStringAsFixed(2)} ms';
    if (s >= 1e-6) return '${(s * 1e6).toStringAsFixed(2)} µs';
    if (s >= 1e-9) return '${(s * 1e9).toStringAsFixed(2)} ns';
    if (s >= 1e-12) return '${(s * 1e12).toStringAsFixed(2)} ps';
    if (s >= 1e-15) return '${(s * 1e15).toStringAsFixed(2)} fs';
    return '${(s * 1e18).toStringAsFixed(2)} as';
  }

  static String _formatEv(double ev) {
    if (ev >= 1e6) return '${(ev / 1e6).toStringAsFixed(2)} MeV';
    if (ev >= 1e3) return '${(ev / 1e3).toStringAsFixed(2)} keV';
    if (ev >= 1) return '${ev.toStringAsFixed(2)} eV';
    if (ev >= 1e-3) return '${(ev * 1e3).toStringAsFixed(2)} meV';
    if (ev >= 1e-6) return '${(ev * 1e6).toStringAsFixed(2)} µeV';
    return '${(ev * 1e9).toStringAsFixed(2)} neV';
  }
}

/// Oblique projection of the two field planes.
///
/// Screen x is the propagation axis. The E field is drawn straight up the
/// screen. The B field is drawn along a skewed direction to suggest a plane
/// going into the page. The skew is a drawing convention only - the two
/// fields are genuinely perpendicular in the model.
class _EmPainter extends CustomPainter {
  _EmPainter({
    required this.clock,
    required this.colors,
    required this.waveColour,
    required this.showB,
  }) : super(repaint: clock);

  final SimClock clock;
  final WaveColors colors;
  final Color waveColour;
  final bool showB;

  /// Cycles shown across the canvas. Fixed on purpose: the wavelength spans
  /// 20 decades, so drawing it to scale is impossible and meaningless. The
  /// picture shows the SHAPE; the readouts carry the numbers.
  static const double _cycles = 2.0;

  /// Unit vector of the B axis in screen space.
  static const Offset _bDir = Offset(0.52, 0.34);

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

    final axisY = size.height * 0.52;
    final left = size.width * 0.08;
    final right = size.width * 0.92;
    final span = right - left;
    final eScale = size.height * 0.23;
    final bScale = size.height * 0.20;

    final phase = clock.phase;
    final k = 2 * math.pi * _cycles / span;

    _paintAxis(canvas, size, left, right, axisY);

    // y(x) = A sin(kx - wt). The SAME value drives both fields, which is what
    // keeps them exactly in phase.
    double field(double px) => math.sin(k * (px - left) - phase);

    if (showB) {
      _paintLobes(
        canvas,
        left: left,
        right: right,
        axisY: axisY,
        scale: bScale,
        dir: _bDir,
        field: field,
        colour: colors.blue,
        alpha: 0.75,
      );
    }
    _paintLobes(
      canvas,
      left: left,
      right: right,
      axisY: axisY,
      scale: eScale,
      dir: const Offset(0, -1),
      field: field,
      colour: waveColour,
      alpha: 1.0,
    );

    _label(canvas, 'E', Offset(left - 2, axisY - eScale - 20), waveColour);
    if (showB) {
      _label(
        canvas,
        'B',
        Offset(left + _bDir.dx * bScale + 6, axisY + _bDir.dy * bScale + 4),
        colors.blue,
      );
    }
    _label(
      canvas,
      'direction of travel →',
      Offset(right - 132, axisY + 14),
      colors.textTertiary,
      size: 12,
    );
  }

  /// Draws one field as a curve plus periodic vectors from the axis.
  void _paintLobes(
    Canvas canvas, {
    required double left,
    required double right,
    required double axisY,
    required double scale,
    required Offset dir,
    required double Function(double) field,
    required Color colour,
    required double alpha,
  }) {
    final path = Path();
    for (double px = left; px <= right; px += 2) {
      final v = field(px) * scale;
      final p = Offset(px + dir.dx * v, axisY + dir.dy * v);
      if (px == left) {
        path.moveTo(p.dx, p.dy);
      } else {
        path.lineTo(p.dx, p.dy);
      }
    }
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.6
        ..strokeCap = StrokeCap.round
        ..color = fade(colour, alpha),
    );

    final stem = Paint()
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round
      ..color = fade(colour, alpha * 0.55);

    for (double px = left; px <= right; px += 11) {
      final v = field(px) * scale;
      if (v.abs() < 0.8) continue;
      canvas.drawLine(
        Offset(px, axisY),
        Offset(px + dir.dx * v, axisY + dir.dy * v),
        stem,
      );
    }
  }

  void _paintAxis(
    Canvas canvas,
    Size size,
    double left,
    double right,
    double axisY,
  ) {
    final p = Paint()
      ..color = fade(colors.textTertiary, 0.45)
      ..strokeWidth = 1.3;
    canvas.drawLine(Offset(left - 14, axisY), Offset(right + 10, axisY), p);

    // Arrow head on the propagation axis.
    final head = Path()
      ..moveTo(right + 10, axisY)
      ..lineTo(right + 2, axisY - 4)
      ..lineTo(right + 2, axisY + 4)
      ..close();
    canvas.drawPath(head, Paint()..color = fade(colors.textTertiary, 0.6));
  }

  void _label(
    Canvas canvas,
    String text,
    Offset at,
    Color colour, {
    double size = 15,
  }) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
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
  bool shouldRepaint(covariant _EmPainter old) =>
      old.waveColour != waveColour ||
      old.showB != showB ||
      old.colors != colors;
}

/// The spectrum strip, log10(lambda) from 1e5 m down to 1e-16 m.
///
/// Drawn shortest-wavelength-on-the-right so it matches the slider, and
/// carries a marker at the current wavelength.
class _SpectrumPainter extends CustomPainter {
  _SpectrumPainter({required this.colors, required this.logLambda});

  final WaveColors colors;
  final double logLambda;

  static const double _logMin = -16;
  static const double _logMax = 5;

  @override
  void paint(Canvas canvas, Size size) {
    // Long wavelength on the LEFT, so the strip reads the same way as the
    // slider underneath it.
    double xOf(double logL) =>
        (_logMax - logL) / (_logMax - _logMin) * size.width;

    final r = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height - 14),
      const Radius.circular(6),
    );
    canvas.save();
    canvas.clipRRect(r);

    for (final b in EmBand.all) {
      final x1 = xOf(math.log(b.maxWavelengthM) / math.ln10);
      final x2 = xOf(math.log(b.minWavelengthM) / math.ln10);
      canvas.drawRect(
        Rect.fromLTRB(x1, 0, x2, size.height - 14),
        Paint()..color = fade(b.color, 0.75),
      );
    }
    canvas.restore();

    final x = xOf(logLambda).clamp(0.0, size.width);

    // Marker.
    canvas.drawLine(
      Offset(x, -2),
      Offset(x, size.height - 12),
      Paint()
        ..color = colors.textPrimary
        ..strokeWidth = 2.4,
    );
    final tri = Path()
      ..moveTo(x, size.height - 12)
      ..lineTo(x - 5, size.height - 3)
      ..lineTo(x + 5, size.height - 3)
      ..close();
    canvas.drawPath(tri, Paint()..color = colors.textPrimary);

    _tick(canvas, 'long λ', 0, size.height - 12, TextAlign.left);
    _tick(canvas, 'short λ', size.width, size.height - 12, TextAlign.right);
  }

  void _tick(Canvas canvas, String text, double x, double y, TextAlign align) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(color: colors.textTertiary, fontSize: 10.5),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    final dx = align == TextAlign.right ? x - tp.width : x;
    tp.paint(canvas, Offset(dx, y + 1));
  }

  @override
  bool shouldRepaint(covariant _SpectrumPainter old) =>
      old.logLambda != logLambda || old.colors != colors;
}
