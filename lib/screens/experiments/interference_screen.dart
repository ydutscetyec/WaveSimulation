import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../services/wave_physics.dart';
import '../../theme/wave_theme.dart';
import '../../widgets/ui_kit.dart';

/// Two coherent sources. The map is the RESULTANT AMPLITUDE at each point:
///   A_r = sqrt(A1^2 + A2^2 + 2 A1 A2 cos(delta)),  delta = k(r2-r1) - phi
/// That field is static for a given setting, so it is computed once into a
/// ui.Image rather than every frame.
class InterferenceScreen extends StatefulWidget {
  const InterferenceScreen({super.key});

  @override
  State<InterferenceScreen> createState() => _InterferenceScreenState();
}

class _InterferenceScreenState extends State<InterferenceScreen> {
  static const int _gw = 150;
  static const int _gh = 110;
  static const double _spanM = 4.0;
  static const double _speed = 343;

  double _frequency = 500;
  double _separationM = 1.2;
  double _phaseDeg = 0;

  ui.Image? _field;
  bool _busy = false;
  Offset _listen = const Offset(0.72, 0.5);

  // Colour ramp endpoints as plain RGB ints, so building the pixel buffer
  // needs no per-channel Color getters (those differ across Flutter versions).
  static const int _darkQuiet = 0x071024;
  static const int _darkLoud = 0x3FF0F0;
  static const int _lightQuiet = 0xDCE8F2;
  static const int _lightLoud = 0x0B6E7D;

  int _quiet = _darkQuiet;
  int _loud = _darkLoud;

  double get _lambda => WavePhysics.wavelength(_speed, _frequency);
  double get _spanY => _spanM * _gh / _gw;
  Offset get _s1 => Offset(0.35, _spanY / 2 - _separationM / 2);
  Offset get _s2 => Offset(0.35, _spanY / 2 + _separationM / 2);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final dark = Theme.of(context).brightness == Brightness.dark;
    final quiet = dark ? _darkQuiet : _lightQuiet;
    final loud = dark ? _darkLoud : _lightLoud;
    if (quiet != _quiet || loud != _loud || _field == null) {
      _quiet = quiet;
      _loud = loud;
      unawaited(_rebuildField());
    }
  }

  @override
  void dispose() {
    _field?.dispose();
    super.dispose();
  }

  double _amplitudeAt(double x, double y) {
    final k = WavePhysics.waveNumber(_lambda);
    final r1 = math.sqrt(
        math.pow(x - _s1.dx, 2).toDouble() + math.pow(y - _s1.dy, 2).toDouble());
    final r2 = math.sqrt(
        math.pow(x - _s2.dx, 2).toDouble() + math.pow(y - _s2.dy, 2).toDouble());
    return WavePhysics.interferenceAmplitude(
      a1: WavePhysics.spread(r1),
      a2: WavePhysics.spread(r2),
      waveNumberK: k,
      r1: r1,
      r2: r2,
      phaseOffset: _phaseDeg * math.pi / 180,
    );
  }

  Future<void> _rebuildField() async {
    if (_busy) return;
    _busy = true;

    final values = Float64List(_gw * _gh);
    final dx = _spanM / _gw;
    final dy = _spanY / _gh;
    var peak = 0.0;
    for (var j = 0; j < _gh; j++) {
      for (var i = 0; i < _gw; i++) {
        final a = _amplitudeAt(i * dx, j * dy);
        values[j * _gw + i] = a;
        if (a > peak) peak = a;
      }
    }
    if (peak <= 0) peak = 1;

    final pixels = Uint8List(_gw * _gh * 4);
    final quietR = (_quiet >> 16) & 0xFF;
    final quietG = (_quiet >> 8) & 0xFF;
    final quietB = _quiet & 0xFF;
    final loudR = (_loud >> 16) & 0xFF;
    final loudG = (_loud >> 8) & 0xFF;
    final loudB = _loud & 0xFF;

    for (var n = 0; n < values.length; n++) {
      // mild perceptual squash so the quiet lines stay visible far out
      final t = math.pow(values[n] / peak, 0.55).toDouble().clamp(0.0, 1.0);
      final o = n * 4;
      pixels[o] = (quietR + (loudR - quietR) * t).round();
      pixels[o + 1] = (quietG + (loudG - quietG) * t).round();
      pixels[o + 2] = (quietB + (loudB - quietB) * t).round();
      pixels[o + 3] = 255;
    }

    final completer = Completer<ui.Image>();
    ui.decodeImageFromPixels(
      pixels,
      _gw,
      _gh,
      ui.PixelFormat.rgba8888,
      completer.complete,
    );
    final img = await completer.future;
    _busy = false;
    if (!mounted) {
      img.dispose();
      return;
    }
    setState(() {
      _field?.dispose();
      _field = img;
    });
  }

  void _change(VoidCallback apply) {
    setState(apply);
    unawaited(_rebuildField());
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final lx = _listen.dx * _spanM;
    final ly = _listen.dy * _spanY;
    final r1 = math.sqrt(math.pow(lx - _s1.dx, 2).toDouble() +
        math.pow(ly - _s1.dy, 2).toDouble());
    final r2 = math.sqrt(math.pow(lx - _s2.dx, 2).toDouble() +
        math.pow(ly - _s2.dy, 2).toDouble());
    final pd = WavePhysics.pathDifferenceInWavelengths(r1, r2, _lambda);
    final frac = pd - pd.floor();
    final constructive = frac < 0.2 || frac > 0.8;
    final destructive = (frac - 0.5).abs() < 0.2;

    return LabScaffold(
      title: 'Interference',
      subtitle: 'Two sources, one field',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: _gw / _gh,
            child: LayoutBuilder(
              builder: (context, box) => GestureDetector(
                behavior: HitTestBehavior.opaque,
                onPanDown: (d) => _move(d.localPosition, box.biggest),
                onPanUpdate: (d) => _move(d.localPosition, box.biggest),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: CustomPaint(
                    size: box.biggest,
                    painter: _FieldPainter(
                      image: _field,
                      colors: c,
                      s1: Offset(_s1.dx / _spanM, _s1.dy / _spanY),
                      s2: Offset(_s2.dx / _spanM, _s2.dy / _spanY),
                      listen: _listen,
                      constructive: constructive,
                      destructive: destructive,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Body('Drag on the map to move the listening point.',
              size: 13.5, color: c.textTertiary),
          const SizedBox(height: 14),
          Panel(
            accent: constructive
                ? c.accent
                : (destructive ? c.red : null),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                PanelTitle(
                  constructive
                      ? 'Constructive - the waves reinforce'
                      : (destructive
                          ? 'Destructive - the waves cancel'
                          : 'In between'),
                  icon: constructive
                      ? Icons.add_circle_outline
                      : Icons.remove_circle_outline,
                ),
                Row(
                  children: [
                    Expanded(
                      child: ValueCard(
                        label: 'Path difference',
                        value: pd.toStringAsFixed(2),
                        unit: 'lambda',
                        color: c.amber,
                        compact: true,
                      ),
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: ValueCard(
                        label: 'In metres',
                        value: (r2 - r1).abs().toStringAsFixed(2),
                        unit: 'm',
                        compact: true,
                      ),
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: ValueCard(
                        label: 'Wavelength',
                        value: _lambda.toStringAsFixed(2),
                        unit: 'm',
                        color: c.blue,
                        compact: true,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 11),
                const Body(
                  'A whole number of wavelengths: crests meet crests and add. '
                  'Half a wavelength out: a crest meets a trough and they '
                  'subtract.',
                ),
              ],
            ),
          ),
          Panel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                StepSlider(
                  label: 'Frequency',
                  value: _frequency,
                  min: 100,
                  max: 1500,
                  step: 20,
                  readout: '${_frequency.toStringAsFixed(0)} Hz',
                  onChanged: (v) => _change(() => _frequency = v),
                ),
                StepSlider(
                  label: 'Source separation',
                  value: _separationM,
                  min: 0.2,
                  max: 2.4,
                  step: 0.1,
                  color: c.blue,
                  readout: '${_separationM.toStringAsFixed(2)} m',
                  onChanged: (v) => _change(() => _separationM = v),
                ),
                StepSlider(
                  label: 'Phase difference',
                  value: _phaseDeg,
                  min: 0,
                  max: 360,
                  step: 15,
                  color: c.amber,
                  readout: '${_phaseDeg.toStringAsFixed(0)} deg',
                  onChanged: (v) => _change(() => _phaseDeg = v),
                ),
                const SizedBox(height: 4),
                Body(
                  'About ${(_separationM / _lambda).toStringAsFixed(1)} '
                  'wavelengths now fit between the two sources.',
                  size: 13.5,
                  color: c.textTertiary,
                ),
              ],
            ),
          ),
          const Panel(
            margin: EdgeInsets.zero,
            child: Tip(
              'Nothing is destroyed in the dark bands. Interference only moves '
              'energy around: the bright bands carry more than either source '
              'would deliver there alone.',
              icon: Icons.bolt,
            ),
          ),
        ],
      ),
    );
  }

  void _move(Offset local, Size size) {
    setState(() {
      _listen = Offset(
        (local.dx / size.width).clamp(0.02, 0.98),
        (local.dy / size.height).clamp(0.02, 0.98),
      );
    });
  }
}

class _FieldPainter extends CustomPainter {
  _FieldPainter({
    required this.image,
    required this.colors,
    required this.s1,
    required this.s2,
    required this.listen,
    required this.constructive,
    required this.destructive,
  });

  final ui.Image? image;
  final WaveColors colors;
  final Offset s1;
  final Offset s2;
  final Offset listen;
  final bool constructive;
  final bool destructive;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    if (image == null) {
      canvas.drawRect(rect, Paint()..color = colors.surface);
      return;
    }
    canvas.drawImageRect(
      image!,
      Rect.fromLTWH(0, 0, image!.width.toDouble(), image!.height.toDouble()),
      rect,
      Paint()..filterQuality = FilterQuality.medium,
    );

    Offset px(Offset n) => Offset(n.dx * size.width, n.dy * size.height);

    for (final entry in [(s1, 'A'), (s2, 'B')]) {
      final p = px(entry.$1);
      canvas.drawCircle(p, 9, Paint()..color = colors.canvasBottom);
      canvas.drawCircle(
        p,
        9,
        Paint()
          ..color = colors.amber
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
      final tp = TextPainter(
        text: TextSpan(
          text: entry.$2,
          style: TextStyle(
            color: colors.amber,
            fontSize: 11,
            fontWeight: FontWeight.w800,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, p - Offset(tp.width / 2, tp.height / 2));
    }

    final lp = px(listen);
    final col = constructive
        ? colors.compression
        : (destructive ? colors.red : colors.textPrimary);
    canvas.drawCircle(
      lp,
      13,
      Paint()
        ..color = col
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4,
    );
    canvas.drawCircle(lp, 3, Paint()..color = col);
  }

  @override
  bool shouldRepaint(covariant _FieldPainter old) =>
      old.image != image ||
      old.listen != listen ||
      old.s1 != s1 ||
      old.s2 != s2 ||
      old.colors != colors ||
      old.constructive != constructive ||
      old.destructive != destructive;
}
