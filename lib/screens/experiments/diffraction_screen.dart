import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../services/diffraction_physics.dart';
import '../../services/wave_physics.dart';
import '../../theme/palette.dart';
import '../../theme/wave_theme.dart';
import '../../widgets/sim_clock.dart';
import '../../widgets/ui_kit.dart';

/// MODULE 6 - Diffraction.
///
/// A plane wave arrives from the left and meets a barrier. What gets past is
/// drawn by Huygens' construction: every open point of the barrier is treated
/// as a secondary source, and the picture is built from those sources alone.
/// Nothing about the spreading is drawn by hand.
///
/// Two views, because they answer different questions:
///
///  * Wavefronts - the construction itself, animated. Arcs of radius
///    (v t mod lambda) + n lambda centred on each secondary source. Their
///    envelope IS the transmitted wavefront, so a wide opening produces a flat
///    front with curled edges and a narrow one produces a single circular
///    front, with no special-casing anywhere in the code.
///
///  * Intensity - the time-averaged |A|^2 from the same sources, summed as
///    phasors. This is the quantitative view and the one that shows the side
///    lobes.
class DiffractionScreen extends StatefulWidget {
  const DiffractionScreen({super.key});

  @override
  State<DiffractionScreen> createState() => _DiffractionScreenState();
}

class _DiffractionScreenState extends State<DiffractionScreen> {
  // Tank geometry in metres. The barrier sits at x = 0.
  static const double _xMin = -0.35;
  static const double _xMax = 0.85;
  static const double _yHalf = 0.45;
  static const double _barrierSpan = 2 * _yHalf;

  /// Ripple-tank wave speed. Any value works; this one makes the on-screen
  /// motion comfortable at the apparent rate set on the ClockHost.
  static const double _v = 0.35;

  double _wavelength = 0.10;
  double _opening = 0.16;
  bool _obstacle = false;
  bool _running = true;
  int _view = 0; // 0 wavefronts, 1 intensity

  ui.Image? _map;
  bool _mapPending = false;
  bool _mapDirty = false;

  List<double> get _sources => DiffractionPhysics.sourcePositions(
        openingM: _opening,
        wavelengthM: _wavelength,
        obstacle: _obstacle,
        barrierSpanM: _barrierSpan,
      );

  double get _k => WavePhysics.waveNumber(_wavelength);
  double get _frequency => WavePhysics.frequencyFor(_v, _wavelength);
  double get _ratio => DiffractionPhysics.spreadRatio(_wavelength, _opening);

  double? get _firstMinDeg {
    if (_obstacle) return null;
    final a = DiffractionPhysics.centralLobeHalfAngle(
      wavelengthM: _wavelength,
      slitWidthM: _opening,
    );
    return a == null ? null : a * 180 / math.pi;
  }

  bool _mapInitialised = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Theme.of() is unavailable in initState, and the map needs palette
    // colours, so the first build happens here instead.
    if (!_mapInitialised) {
      _mapInitialised = true;
      _rebuildMap();
    }
  }

  @override
  void dispose() {
    _map?.dispose();
    super.dispose();
  }

  void _onParamChanged(VoidCallback apply) {
    setState(apply);
    _rebuildMap();
  }

  /// Renders the time-averaged intensity to a small image, once per parameter
  /// change rather than once per frame. Intensity is time-independent, so
  /// nothing is lost by doing it this way and the per-frame cost drops to a
  /// single drawImageRect.
  void _rebuildMap() {
    // decodeImageFromPixels is asynchronous. Changes arriving mid-decode are
    // coalesced into one follow-up rebuild rather than dropped, which is what
    // keeps a continuous slider drag from leaving a stale map on screen.
    if (_mapPending) {
      _mapDirty = true;
      return;
    }
    _mapPending = true;
    _mapDirty = false;

    const w = 120;
    const h = 90;

    // Cap the sources used for the map. Beyond roughly 64 the pattern stops
    // changing visibly but the cost keeps climbing, and this runs on the UI
    // thread.
    final all = _sources;
    final step = (all.length / 64).ceil().clamp(1, 1 << 20);
    final srcs = <double>[];
    for (var i = 0; i < all.length; i += step) {
      srcs.add(all[i]);
    }

    final k = _k;
    final field = Float64List(w * h);
    var peak = 1e-12;

    for (var iy = 0; iy < h; iy++) {
      final y = _yHalf - 2 * _yHalf * (iy + 0.5) / h;
      for (var ix = 0; ix < w; ix++) {
        final x = _xMin + (_xMax - _xMin) * (ix + 0.5) / w;
        double value;
        if (x <= 0) {
          // Incident side: a plane wave of unit amplitude, blocked where the
          // barrier is solid. Shown flat so the eye compares "before" against
          // "after" rather than against black.
          value = _blockedAt(y) ? 0.0 : 0.45;
        } else {
          final p = DiffractionPhysics.huygensPhasor(
            x: x,
            y: y,
            sourceYs: srcs,
            waveNumberK: k,
          );
          value = DiffractionPhysics.intensityFromPhasor(p[0], p[1]);
        }
        field[iy * w + ix] = value;
        if (x > 0 && value > peak) peak = value;
      }
    }

    final p = pal(context);
    final lo = p.mapLoRgb;
    final hi = p.mapHiRgb;
    final pixels = Uint8List(w * h * 4);

    for (var i = 0; i < w * h; i++) {
      // sqrt compresses the dynamic range so the side lobes stay visible
      // beside a central maximum many times brighter. It is a display choice
      // and the panel text says so.
      final t = math.sqrt((field[i] / peak).clamp(0.0, 1.0));
      final o = i * 4;
      pixels[o] = _lerpChannel(lo >> 16 & 0xFF, hi >> 16 & 0xFF, t);
      pixels[o + 1] = _lerpChannel(lo >> 8 & 0xFF, hi >> 8 & 0xFF, t);
      pixels[o + 2] = _lerpChannel(lo & 0xFF, hi & 0xFF, t);
      pixels[o + 3] = 255;
    }

    ui.decodeImageFromPixels(pixels, w, h, ui.PixelFormat.rgba8888, (img) {
      if (!mounted) {
        img.dispose();
        _mapPending = false;
        return;
      }
      setState(() {
        _map?.dispose();
        _map = img;
        _mapPending = false;
      });
      if (_mapDirty) _rebuildMap();
    });
  }

  bool _blockedAt(double y) {
    if (_obstacle) return y.abs() <= _opening / 2;
    return y.abs() > _opening / 2;
  }

  static int _lerpChannel(int a, int b, double t) =>
      (a + (b - a) * t).round().clamp(0, 255);

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final minDeg = _firstMinDeg;

    return LabScaffold(
      title: 'Diffraction',
      subtitle: 'Waves spreading through a gap and around an edge',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: SizedBox(
              height: 300,
              width: double.infinity,
              child: ClockHost(
                hz: 0.45,
                running: _running && _view == 0,
                builder: (context, clock) => CustomPaint(
                  painter: _DiffractionPainter(
                    clock: clock,
                    colors: c,
                    sources: _sources,
                    wavelength: _wavelength,
                    opening: _opening,
                    obstacle: _obstacle,
                    showIntensity: _view == 1,
                    map: _map,
                    xMin: _xMin,
                    xMax: _xMax,
                    yHalf: _yHalf,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Body(
            _view == 0
                ? 'Each arc is a secondary wavelet from one open point of the '
                    'barrier. The transmitted wavefront is their envelope.'
                : 'Brightness is time-averaged intensity, on a square-root '
                    'scale so the side lobes stay visible.',
            size: 13.5,
            color: c.textTertiary,
          ),
          const SizedBox(height: 14),
          Panel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const PanelTitle('View', icon: Icons.visibility_outlined),
                Segmented(
                  labels: const ['Wavefronts', 'Intensity'],
                  selectedIndex: _view,
                  onSelect: (i) => setState(() => _view = i),
                ),
                const SizedBox(height: 14),
                const PanelTitle('Barrier', icon: Icons.crop_din),
                Segmented(
                  labels: const ['Opening', 'Obstacle'],
                  selectedIndex: _obstacle ? 1 : 0,
                  onSelect: (i) => _onParamChanged(() => _obstacle = i == 1),
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
                  min: 0.02,
                  max: 0.30,
                  readout: '${(_wavelength * 100).toStringAsFixed(1)} cm',
                  color: c.blue,
                  onChanged: (v) => _onParamChanged(() => _wavelength = v),
                ),
                const SizedBox(height: 10),
                StepSlider(
                  label: _obstacle ? 'Obstacle width' : 'Opening width',
                  value: _opening,
                  min: 0.02,
                  max: 0.60,
                  readout: '${(_opening * 100).toStringAsFixed(1)} cm',
                  color: c.amber,
                  onChanged: (v) => _onParamChanged(() => _opening = v),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ValueCard(
                        label: 'Ratio λ / a',
                        value: _ratio.toStringAsFixed(2),
                        color: c.accent,
                        compact: true,
                      ),
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: ValueCard(
                        label: 'Spreading',
                        value: DiffractionPhysics.spreadLabel(
                          _wavelength,
                          _opening,
                        ),
                        color: c.amber,
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
                        label: 'Frequency',
                        value: _frequency.toStringAsFixed(2),
                        unit: 'Hz',
                        compact: true,
                      ),
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: ValueCard(
                        label: 'First minimum',
                        value: minDeg == null
                            ? '—'
                            : '±${minDeg.toStringAsFixed(0)}°',
                        color: c.blue,
                        compact: true,
                      ),
                    ),
                  ],
                ),
                if (_view == 0) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () =>
                              setState(() => _running = !_running),
                          icon: Icon(
                            _running ? Icons.pause : Icons.play_arrow,
                          ),
                          label: Text(_running ? 'Pause' : 'Play'),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          Tip(
            minDeg == null && !_obstacle
                ? 'The opening is narrower than one wavelength, so there is no '
                    'first minimum at all: the gap behaves as a single point '
                    'source and the wave fills the whole space beyond it.'
                : 'Set the opening much wider than the wavelength and the wave '
                    'carries straight on as a beam. Shrink it towards λ and the '
                    'spreading takes over. Only the ratio λ/a matters.',
            icon: Icons.lightbulb_outline,
          ),
          Panel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const PanelTitle('The physics', icon: Icons.functions),
                const SizedBox(height: 6),
                Body(
                  'Huygens: every point of a wavefront is itself a source of '
                  'a spherical wavelet, and the next wavefront is the envelope '
                  'of those wavelets. A barrier removes most of the sources; '
                  'the few that survive have nothing either side to cancel '
                  'their sideways spread, so the wave bends.',
                  color: c.textSecondary,
                ),
                const SizedBox(height: 10),
                Body(
                  'Far-field intensity for a single slit of width a:\n'
                  '    I(θ) / I₀ = ( sin β / β )²,   β = π a sin θ / λ\n'
                  'Minima where a sin θ = m λ, for m = 1, 2, 3 …\n'
                  'If λ > a there is no solution, and no minimum exists.',
                  color: c.textSecondary,
                  size: 13.5,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DiffractionPainter extends CustomPainter {
  _DiffractionPainter({
    required this.clock,
    required this.colors,
    required this.sources,
    required this.wavelength,
    required this.opening,
    required this.obstacle,
    required this.showIntensity,
    required this.map,
    required this.xMin,
    required this.xMax,
    required this.yHalf,
  }) : super(repaint: clock);

  final SimClock clock;
  final WaveColors colors;
  final List<double> sources;
  final double wavelength;
  final double opening;
  final bool obstacle;
  final bool showIntensity;
  final ui.Image? map;
  final double xMin;
  final double xMax;
  final double yHalf;

  /// Arcs drawn per source. Enough to fill the tank at the longest wavelength.
  static const int _ringCount = 9;

  /// Sources actually drawn. The sum uses all of them; drawing every one of
  /// 200 arcs would be an unreadable smear and slow.
  static const int _maxDrawnSources = 22;

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

    double sx(double x) => (x - xMin) / (xMax - xMin) * size.width;
    double sy(double y) => (yHalf - y) / (2 * yHalf) * size.height;
    final pxPerM = size.width / (xMax - xMin);

    final barrierX = sx(0);

    if (showIntensity) {
      final img = map;
      if (img != null) {
        canvas.drawImageRect(
          img,
          Rect.fromLTWH(0, 0, img.width.toDouble(), img.height.toDouble()),
          rect,
          Paint()..filterQuality = FilterQuality.low,
        );
      }
    } else {
      _paintWavefronts(canvas, size, sx, sy, pxPerM, barrierX);
    }

    _paintBarrier(canvas, size, sy, barrierX);
    _paintAxis(canvas, size, barrierX);
  }

  void _paintWavefronts(
    Canvas canvas,
    Size size,
    double Function(double) sx,
    double Function(double) sy,
    double pxPerM,
    double barrierX,
  ) {
    // Distance the wave has moved since the last whole wavelength. The clock
    // integrates phase, so this never jumps when the rate changes.
    final frac = clock.phase / (2 * math.pi);
    final lagM = frac * wavelength;

    // --- incident plane wavefronts, left of the barrier ---
    final incident = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = fade(colors.blue, 0.75);

    for (var n = 0; n < 14; n++) {
      final x = -lagM - n * wavelength;
      if (x < xMin) break;
      final px = sx(x);
      canvas.drawLine(Offset(px, 0), Offset(px, size.height), incident);
    }

    // --- secondary wavelets, right of the barrier ---
    canvas.save();
    canvas.clipRect(
      Rect.fromLTWH(barrierX, 0, size.width - barrierX, size.height),
    );

    final drawn = <double>[];
    final stepN = (sources.length / _maxDrawnSources).ceil().clamp(1, 1 << 20);
    for (var i = 0; i < sources.length; i += stepN) {
      drawn.add(sources[i]);
    }
    // Always keep the extreme edges: they are what curl into the shadow.
    if (sources.isNotEmpty) {
      if (!drawn.contains(sources.first)) drawn.add(sources.first);
      if (!drawn.contains(sources.last)) drawn.add(sources.last);
    }

    // Opacity scaled so a densely sampled slit does not saturate to white.
    final alpha = (1.6 / math.max(1, drawn.length)).clamp(0.10, 0.70);
    final wavelet = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..color = fade(colors.accent, alpha);

    for (final sYm in drawn) {
      final centre = Offset(barrierX, sy(sYm));
      for (var n = 0; n < _ringCount; n++) {
        final rM = lagM + n * wavelength;
        if (rM <= 0) continue;
        final rPx = rM * pxPerM;
        if (rPx > size.width * 1.6) break;
        canvas.drawCircle(centre, rPx, wavelet);
      }
    }
    canvas.restore();
  }

  void _paintBarrier(
    Canvas canvas,
    Size size,
    double Function(double) sy,
    double barrierX,
  ) {
    final wall = Paint()..color = colors.wall;
    const t = 7.0;

    if (obstacle) {
      canvas.drawRect(
        Rect.fromLTRB(
          barrierX - t / 2,
          sy(opening / 2),
          barrierX + t / 2,
          sy(-opening / 2),
        ),
        wall,
      );
    } else {
      canvas.drawRect(
        Rect.fromLTRB(barrierX - t / 2, 0, barrierX + t / 2, sy(opening / 2)),
        wall,
      );
      canvas.drawRect(
        Rect.fromLTRB(
          barrierX - t / 2,
          sy(-opening / 2),
          barrierX + t / 2,
          size.height,
        ),
        wall,
      );
    }
  }

  /// A faint centre line, so the symmetry of the pattern is checkable.
  void _paintAxis(Canvas canvas, Size size, double barrierX) {
    final p = Paint()
      ..color = fade(colors.textTertiary, 0.28)
      ..strokeWidth = 1;
    final y = size.height / 2;
    for (double x = barrierX; x < size.width; x += 10) {
      canvas.drawLine(Offset(x, y), Offset(x + 5, y), p);
    }
  }

  @override
  bool shouldRepaint(covariant _DiffractionPainter old) =>
      old.wavelength != wavelength ||
      old.opening != opening ||
      old.obstacle != obstacle ||
      old.showIntensity != showIntensity ||
      old.map != map ||
      old.colors != colors ||
      old.sources.length != sources.length;
}
