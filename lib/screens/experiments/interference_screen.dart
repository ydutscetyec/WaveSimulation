import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../services/wave_physics.dart';
import '../../theme/app_theme.dart';
import '../../widgets/ui_kit.dart';

/// Two coherent sources. The map shows the RESULTANT AMPLITUDE at every point:
///
///   A_r = sqrt(A1^2 + A2^2 + 2*A1*A2*cos(delta)),  delta = k(r2-r1) - phi
///
/// That field is static for a given setting, so it is computed once into a
/// ui.Image instead of being recalculated every frame. Only the draggable
/// listening point updates on touch.
class InterferenceScreen extends StatefulWidget {
  const InterferenceScreen({super.key});

  @override
  State<InterferenceScreen> createState() => _InterferenceScreenState();
}

class _InterferenceScreenState extends State<InterferenceScreen> {
  static const int _gw = 150; // field resolution
  static const int _gh = 110;
  static const double _spanM = 4.0; // physical width of the map

  double _frequency = 500;
  double _separationM = 1.2;
  double _phaseDeg = 0;

  ui.Image? _field;
  bool _busy = false;
  Offset _listen = const Offset(0.72, 0.5); // normalised

  double get _speed => 343;
  double get _lambda => WavePhysics.wavelength(_speed, _frequency);

  @override
  void initState() {
    super.initState();
    unawaited(_rebuildField());
  }

  @override
  void dispose() {
    _field?.dispose();
    super.dispose();
  }

  // source positions in metres, in a map that spans _spanM across
  double get _spanY => _spanM * _gh / _gw;
  Offset get _s1 => Offset(0.35, _spanY / 2 - _separationM / 2);
  Offset get _s2 => Offset(0.35, _spanY / 2 + _separationM / 2);

  double _amplitudeAt(double x, double y) {
    final k = WavePhysics.waveNumber(_lambda);
    final r1 = math.sqrt(math.pow(x - _s1.dx, 2) + math.pow(y - _s1.dy, 2));
    final r2 = math.sqrt(math.pow(x - _s2.dx, 2) + math.pow(y - _s2.dy, 2));
    final a1 = WavePhysics.spread(r1);
    final a2 = WavePhysics.spread(r2);
    return WavePhysics.interferenceAmplitude(
      a1: a1,
      a2: a2,
      waveNumberK: k,
      r1: r1,
      r2: r2,
      phaseOffset: _phaseDeg * math.pi / 180,
    );
  }

  Future<void> _rebuildField() async {
    if (_busy) return;
    _busy = true;
    final pixels = Uint8List(_gw * _gh * 4);
    final dx = _spanM / _gw;
    final dy = _spanY / _gh;

    var peak = 0.0;
    final values = Float64List(_gw * _gh);
    for (var j = 0; j < _gh; j++) {
      for (var i = 0; i < _gw; i++) {
        final a = _amplitudeAt(i * dx, j * dy);
        values[j * _gw + i] = a;
        if (a > peak) peak = a;
      }
    }
    if (peak <= 0) peak = 1;

    for (var n = 0; n < values.length; n++) {
      // Perceptual squash so the quiet lines stay visible away from the sources.
      final t = math.pow(values[n] / peak, 0.55).toDouble().clamp(0.0, 1.0);
      // dark navy (0x07,0x10,0x24) -> cyan (0x2E,0xE6,0xE6)
      final o = n * 4;
      pixels[o] = (0x07 + (0x2E - 0x07) * t).round();
      pixels[o + 1] = (0x10 + (0xE6 - 0x10) * t).round();
      pixels[o + 2] = (0x24 + (0xE6 - 0x24) * t).round();
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

  void _onParamChanged(VoidCallback apply) {
    setState(apply);
    unawaited(_rebuildField());
  }

  @override
  Widget build(BuildContext context) {
    // Readings at the listening point
    final lx = _listen.dx * _spanM;
    final ly = _listen.dy * _spanY;
    final r1 = math.sqrt(math.pow(lx - _s1.dx, 2) + math.pow(ly - _s1.dy, 2));
    final r2 = math.sqrt(math.pow(lx - _s2.dx, 2) + math.pow(ly - _s2.dy, 2));
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
              builder: (context, c) {
                return GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onPanDown: (d) => _moveListen(d.localPosition, c.biggest),
                  onPanUpdate: (d) => _moveListen(d.localPosition, c.biggest),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: CustomPaint(
                      size: c.biggest,
                      painter: _FieldPainter(
                        image: _field,
                        s1: Offset(_s1.dx / _spanM, _s1.dy / _spanY),
                        s2: Offset(_s2.dx / _spanM, _s2.dy / _spanY),
                        listen: _listen,
                        constructive: constructive,
                        destructive: destructive,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Drag anywhere on the map to move the listening point. Bright bands '
            'are loud, dark bands are quiet.',
            style: TextStyle(fontSize: 13.5, color: AppColors.textDim, height: 1.4),
          ),
          const SizedBox(height: 14),
          Panel(
            accent: constructive
                ? AppColors.cyan
                : (destructive ? AppColors.indigo : null),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                PanelTitle(
                  constructive
                      ? 'CONSTRUCTIVE - waves reinforce each other'
                      : (destructive
                          ? 'DESTRUCTIVE - waves partly cancel'
                          : 'In between'),
                  icon: constructive ? Icons.add_circle_outline : Icons.remove_circle_outline,
                ),
                Row(
                  children: [
                    Expanded(
                      child: ValueCard(
                        label: 'Path difference',
                        value: pd.toStringAsFixed(2),
                        unit: 'lambda',
                        color: AppColors.amber,
                        compact: true,
                      ),
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: ValueCard(
                        label: 'In metres',
                        value: ((r2 - r1).abs()).toStringAsFixed(2),
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
                        color: AppColors.blue,
                        compact: true,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 11),
                const Text(
                  'Whole number of wavelengths: crests meet crests and add. '
                  'Half a wavelength off: a crest meets a trough and they '
                  'subtract.',
                  style: TextStyle(
                    fontSize: 14.5,
                    color: AppColors.textMuted,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
          Panel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const PanelTitle('Controls', icon: Icons.tune),
                StepSlider(
                  label: 'Frequency of both sources',
                  value: _frequency,
                  min: 100,
                  max: 1500,
                  step: 20,
                  readout: '${_frequency.toStringAsFixed(0)} Hz',
                  onChanged: (v) => _onParamChanged(() => _frequency = v),
                ),
                StepSlider(
                  label: 'Separation between the sources',
                  value: _separationM,
                  min: 0.2,
                  max: 2.4,
                  step: 0.1,
                  color: AppColors.blue,
                  readout: '${_separationM.toStringAsFixed(2)} m',
                  onChanged: (v) => _onParamChanged(() => _separationM = v),
                ),
                StepSlider(
                  label: 'Phase difference between the sources',
                  value: _phaseDeg,
                  min: 0,
                  max: 360,
                  step: 15,
                  color: AppColors.amber,
                  readout: '${_phaseDeg.toStringAsFixed(0)} deg',
                  onChanged: (v) => _onParamChanged(() => _phaseDeg = v),
                ),
                const SizedBox(height: 4),
                Text(
                  'Wider separation or shorter wavelength both pack more bands '
                  'into the same space. Right now there are about '
                  '${(_separationM / _lambda).toStringAsFixed(1)} wavelengths '
                  'between the two sources.',
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textDim,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
          const Panel(
            margin: EdgeInsets.zero,
            child: Explain(
              'Nothing is destroyed in the dark bands. Interference only moves '
              'energy around: the bright bands carry more than either source '
              'alone would deliver there, and the total across the whole field '
              'still adds up.',
              icon: Icons.bolt,
              color: AppColors.amber,
            ),
          ),
        ],
      ),
    );
  }

  void _moveListen(Offset local, Size size) {
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
    required this.s1,
    required this.s2,
    required this.listen,
    required this.constructive,
    required this.destructive,
  });

  final ui.Image? image;
  final Offset s1;
  final Offset s2;
  final Offset listen;
  final bool constructive;
  final bool destructive;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    if (image == null) {
      canvas.drawRect(rect, Paint()..color = AppColors.surface);
      return;
    }
    canvas.drawImageRect(
      image!,
      Rect.fromLTWH(
        0,
        0,
        image!.width.toDouble(),
        image!.height.toDouble(),
      ),
      rect,
      Paint()..filterQuality = FilterQuality.medium,
    );

    Offset px(Offset norm) =>
        Offset(norm.dx * size.width, norm.dy * size.height);

    for (final (s, label) in [(s1, 'A'), (s2, 'B')]) {
      final p = px(s);
      canvas.drawCircle(p, 9, Paint()..color = AppColors.bgDeep);
      canvas.drawCircle(
        p,
        9,
        Paint()
          ..color = AppColors.amber
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
      final tp = TextPainter(
        text: TextSpan(
          text: label,
          style: const TextStyle(
            color: AppColors.amber,
            fontSize: 11,
            fontWeight: FontWeight.w800,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, p - Offset(tp.width / 2, tp.height / 2));
    }

    final lp = px(listen);
    final c = constructive
        ? AppColors.cyan
        : (destructive ? AppColors.red : AppColors.text);
    canvas.drawCircle(
      lp,
      13,
      Paint()
        ..color = c
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4,
    );
    canvas.drawCircle(lp, 3, Paint()..color = c);
  }

  @override
  bool shouldRepaint(covariant _FieldPainter old) =>
      old.image != image ||
      old.listen != listen ||
      old.s1 != s1 ||
      old.s2 != s2 ||
      old.constructive != constructive ||
      old.destructive != destructive;
}
