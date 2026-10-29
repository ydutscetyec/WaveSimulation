import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../services/wave_physics.dart';
import '../../theme/wave_theme.dart';
import '../../widgets/sim_clock.dart';
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

  ui.Image? _field;              // static RMS map
  List<ui.Image> _frames = [];   // one image per phase step, when animating
  bool _busy = false;
  bool _animate = false;
  bool _twoSources = true;

  static const int _frameCount = 24;
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
    for (final f in _frames) {
      f.dispose();
    }
    super.dispose();
  }

  Future<ui.Image> _toImage(Uint8List pixels) {
    final completer = Completer<ui.Image>();
    ui.decodeImageFromPixels(
      pixels,
      _gw,
      _gh,
      ui.PixelFormat.rgba8888,
      completer.complete,
    );
    return completer.future;
  }

  /// Builds the field.
  ///
  /// Each point gets the sum of two sine waves of the same frequency, so the
  /// whole time dependence collapses into two numbers per pixel:
  ///
  ///   sum = S cos(wt) - C sin(wt),
  ///   S = sum a_i sin(k r_i + phi_i),   C = sum a_i cos(k r_i + phi_i)
  ///
  /// The resultant amplitude is sqrt(S^2 + C^2), which is the static map, and
  /// any instant is two multiplies per pixel. That is what makes animation
  /// affordable: the frames are built once from S and C with no trig in the
  /// loop, instead of recomputing sines every frame.
  Future<void> _rebuildField() async {
    if (_busy) return;
    _busy = true;

    final count = _gw * _gh;
    final sArr = Float64List(count);
    final cArr = Float64List(count);
    final dx = _spanM / _gw;
    final dy = _spanY / _gh;
    final k = WavePhysics.waveNumber(_lambda);
    final phi = _phaseDeg * math.pi / 180;

    var peak = 0.0;
    for (var j = 0; j < _gh; j++) {
      for (var i = 0; i < _gw; i++) {
        final x = i * dx;
        final y = j * dy;

        final r1 = math.sqrt(math.pow(x - _s1.dx, 2).toDouble() +
            math.pow(y - _s1.dy, 2).toDouble());
        final a1 = WavePhysics.spread(r1);
        var sSum = a1 * math.sin(k * r1);
        var cSum = a1 * math.cos(k * r1);

        if (_twoSources) {
          final r2 = math.sqrt(math.pow(x - _s2.dx, 2).toDouble() +
              math.pow(y - _s2.dy, 2).toDouble());
          final a2 = WavePhysics.spread(r2);
          sSum += a2 * math.sin(k * r2 + phi);
          cSum += a2 * math.cos(k * r2 + phi);
        }

        final n = j * _gw + i;
        sArr[n] = sSum;
        cArr[n] = cSum;
        final amp = math.sqrt(sSum * sSum + cSum * cSum);
        if (amp > peak) peak = amp;
      }
    }
    if (peak <= 0) peak = 1;

    final quietR = (_quiet >> 16) & 0xFF;
    final quietG = (_quiet >> 8) & 0xFF;
    final quietB = _quiet & 0xFF;
    final loudR = (_loud >> 16) & 0xFF;
    final loudG = (_loud >> 8) & 0xFF;
    final loudB = _loud & 0xFF;

    if (!_animate) {
      final pixels = Uint8List(count * 4);
      for (var n = 0; n < count; n++) {
        final amp = math.sqrt(sArr[n] * sArr[n] + cArr[n] * cArr[n]);
        // mild perceptual squash so the quiet lines stay visible far out
        final t = math.pow(amp / peak, 0.55).toDouble().clamp(0.0, 1.0);
        final o = n * 4;
        pixels[o] = (quietR + (loudR - quietR) * t).round();
        pixels[o + 1] = (quietG + (loudG - quietG) * t).round();
        pixels[o + 2] = (quietB + (loudB - quietB) * t).round();
        pixels[o + 3] = 255;
      }
      final img = await _toImage(pixels);
      _busy = false;
      if (!mounted) {
        img.dispose();
        return;
      }
      setState(() {
        _field?.dispose();
        _field = img;
        for (final f in _frames) {
          f.dispose();
        }
        _frames = [];
      });
      return;
    }

    // Animated: one image per phase step. Positive swings run towards the
    // loud colour, negative ones towards the rarefaction colour, so a crest
    // and a trough are told apart rather than both reading as "loud".
    final built = <ui.Image>[];
    for (var f = 0; f < _frameCount; f++) {
      final wt = 2 * math.pi * f / _frameCount;
      final cosWt = math.cos(wt);
      final sinWt = math.sin(wt);
      final pixels = Uint8List(count * 4);
      for (var n = 0; n < count; n++) {
        final v = (sArr[n] * cosWt - cArr[n] * sinWt) / peak;
        final t = ((v + 1) / 2).clamp(0.0, 1.0);
        final o = n * 4;
        pixels[o] = (quietR + (loudR - quietR) * t).round();
        pixels[o + 1] = (quietG + (loudG - quietG) * t).round();
        pixels[o + 2] = (quietB + (loudB - quietB) * t).round();
        pixels[o + 3] = 255;
      }
      built.add(await _toImage(pixels));
    }

    _busy = false;
    if (!mounted) {
      for (final f in built) {
        f.dispose();
      }
      return;
    }
    setState(() {
      for (final f in _frames) {
        f.dispose();
      }
      _frames = built;
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
    final constructive = _twoSources && (frac < 0.2 || frac > 0.8);
    final destructive = _twoSources && (frac - 0.5).abs() < 0.2;

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
                  child: ClockHost(
                    hz: 0.4,
                    running: _animate,
                    builder: (context, clock) => CustomPaint(
                      size: box.biggest,
                      painter: _FieldPainter(
                        image: _field,
                        frames: _frames,
                        clock: clock,
                        colors: c,
                        s1: Offset(_s1.dx / _spanM, _s1.dy / _spanY),
                        s2: _twoSources
                            ? Offset(_s2.dx / _spanM, _s2.dy / _spanY)
                            : null,
                        listen: _listen,
                        constructive: constructive,
                        destructive: destructive,
                      ),
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
                  !_twoSources
                      ? 'One source - nothing to interfere with'
                      : constructive
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
                        value: _twoSources ? pd.toStringAsFixed(2) : '—',
                        unit: 'lambda',
                        color: c.amber,
                        compact: true,
                      ),
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: ValueCard(
                        label: 'In metres',
                        value: _twoSources
                            ? (r2 - r1).abs().toStringAsFixed(2)
                            : '—',
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
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Second source',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: c.textSecondary,
                        ),
                      ),
                    ),
                    Switch(
                      value: _twoSources,
                      activeThumbColor: c.accent,
                      onChanged: (v) => _change(() => _twoSources = v),
                    ),
                  ],
                ),
                Body(
                  _twoSources
                      ? 'Turn it off to see what one source alone does: plain '
                          'circles, no bands anywhere.'
                      : 'One source only. The bands appear the moment a second '
                          'one is added, which is the whole point.',
                  size: 13,
                  color: c.textTertiary,
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Animate the field',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: c.textSecondary,
                        ),
                      ),
                    ),
                    Switch(
                      value: _animate,
                      activeThumbColor: c.amber,
                      onChanged: (v) => _change(() => _animate = v),
                    ),
                  ],
                ),
                Body(
                  _animate
                      ? 'Crests and troughs now sweep outward. Watch a dark '
                          'band: it never brightens, because the two waves '
                          'arrive there out of step at every instant.'
                      : 'Showing resultant amplitude: how loud each point is, '
                          'averaged over time. Turn on animation to watch the '
                          'crests actually move.',
                  size: 13,
                  color: c.textTertiary,
                ),
                const SizedBox(height: 14),
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
    required this.frames,
    required this.clock,
    required this.colors,
    required this.s1,
    required this.s2,
    required this.listen,
    required this.constructive,
    required this.destructive,
  }) : super(repaint: clock);

  final ui.Image? image;
  final List<ui.Image> frames;
  final SimClock? clock;
  final WaveColors colors;
  final Offset s1;
  final Offset? s2;
  final Offset listen;
  final bool constructive;
  final bool destructive;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);

    // Pick the frame here rather than in a widget, so animating the field
    // repaints the canvas without rebuilding anything.
    ui.Image? shown = image;
    if (frames.isNotEmpty) {
      final c = clock;
      final turn = c == null ? 0.0 : c.phase / (2 * math.pi);
      var idx = (turn * frames.length).floor() % frames.length;
      if (idx < 0) idx += frames.length;
      shown = frames[idx];
    }
    if (shown == null) {
      canvas.drawRect(rect, Paint()..color = colors.surface);
      return;
    }
    canvas.drawImageRect(
      shown,
      Rect.fromLTWH(0, 0, shown.width.toDouble(), shown.height.toDouble()),
      rect,
      Paint()..filterQuality = FilterQuality.medium,
    );

    Offset px(Offset n) => Offset(n.dx * size.width, n.dy * size.height);

    final markers = <(Offset, String)>[
      (s1, 'A'),
      if (s2 != null) (s2!, 'B'),
    ];
    for (final entry in markers) {
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
      old.frames != frames ||
      old.listen != listen ||
      old.s1 != s1 ||
      old.s2 != s2 ||
      old.colors != colors ||
      old.constructive != constructive ||
      old.destructive != destructive;
}
