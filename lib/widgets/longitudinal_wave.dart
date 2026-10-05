import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../services/wave_physics.dart';
import '../theme/app_theme.dart';
import 'sim_clock.dart';

/// Draws the primary representation of sound: particles displaced ALONG the
/// propagation axis, forming travelling compressions and rarefactions.
///
/// Design decisions that matter physically:
///  * particle x = rest_x + A*sin(kx - phase).  The displacement is parallel
///    to travel, which is what makes the wave longitudinal.
///  * compression is taken from the spatial derivative (-ds/dx), not painted
///    in by hand, so the bright bands are genuinely where particles crowd.
///  * the amplitude in metres is capped at 0.9/k so neighbouring particles can
///    never pass through each other (strain < 1).
///  * the canvas represents a REAL width in metres, drawn as a scale bar. When
///    frequency rises at a fixed scale, more cycles appear - which is the
///    whole point of the exercise.
class ParticleFieldPainter extends CustomPainter {
  ParticleFieldPainter({
    required this.clock,
    required this.amplitude,
    required this.wavelengthM,
    required this.viewWidthM,
    required this.mediumColor,
    this.vacuum = false,
    this.showMarkers = true,
    this.showSourceReceiver = true,
  }) : super(repaint: clock);

  final SimClock clock;
  final double amplitude; // 0..1 (user control)
  final double wavelengthM;
  final double viewWidthM;
  final Color mediumColor;
  final bool vacuum;
  final bool showMarkers;
  final bool showSourceReceiver;

  static const double _edge = 30;
  static const double _topPad = 24;
  static const double _botPad = 30;
  static const int _lutSteps = 24;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // backdrop
    final bgPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF0A1428), Color(0xFF050A16)],
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(0, 0, w, h), const Radius.circular(16)),
      bgPaint,
    );

    if (vacuum) {
      _paintVacuum(canvas, size);
      return;
    }

    final fieldLeft = _edge;
    final fieldRight = w - _edge;
    final fieldW = fieldRight - fieldLeft;
    if (fieldW <= 10 || wavelengthM <= 0 || !wavelengthM.isFinite) return;

    final bandTop = _topPad;
    final bandBottom = h - _botPad;
    final bandH = math.max(20.0, bandBottom - bandTop);

    final k = WavePhysics.waveNumber(wavelengthM);
    final phase = clock.phase;
    final pxPerM = fieldW / viewWidthM;

    final cols = (fieldW / 6.5).clamp(40, 110).round();
    final rows = (bandH / 22).clamp(3, 9).round();
    final spacingM = viewWidthM / (cols - 1);
    final rowGap = bandH / (rows + 1);

    // Physical ceiling: A*k < 1 or particles would overtake each other.
    final aMax = WavePhysics.maxPhysicalAmplitude(k);
    final aM = amplitude * math.min(aMax, spacingM * 2.4);
    final strainScale = aM * k; // peak |strain|

    // Colour depends only on local strain, so it is tabulated once per frame
    // instead of allocating a Color per particle. At 110x9 particles and 60 fps
    // the naive version would allocate about 60k Colors a second.
    final lut = List<Color>.generate(_lutSteps, (i) {
      final tt = i / (_lutSteps - 1);
      return fade(
        Color.lerp(AppColors.indigo, mediumColor, tt) ?? mediumColor,
        0.42 + 0.58 * tt,
      );
    });

    final dot = Paint()..style = PaintingStyle.fill;

    for (var r = 0; r < rows; r++) {
      final y = bandTop + rowGap * (r + 1);
      final rowOffset = r.isOdd ? 0.5 : 0.0;
      for (var c = 0; c < cols; c++) {
        final xm = (c + rowOffset) * spacingM;
        if (xm > viewWidthM) continue;

        final s = WavePhysics.displacement(
          amplitude: aM,
          waveNumberK: k,
          x: xm,
          phase: phase,
        );
        final strain = WavePhysics.strain(
          amplitude: aM,
          waveNumberK: k,
          x: xm,
          phase: phase,
        );

        // 0 = full rarefaction, 1 = full compression
        final t = strainScale <= 0 ? 0.5 : (strain / strainScale + 1) / 2;

        final px = fieldLeft + (xm + s) * pxPerM;
        if (px < fieldLeft - 6 || px > fieldRight + 6) continue;

        dot.color = lut[(t * (_lutSteps - 1)).round().clamp(0, _lutSteps - 1)];
        canvas.drawCircle(Offset(px, y), 1.9 + 2.0 * t, dot);
      }
    }

    if (showMarkers && amplitude > 0.02) {
      _paintMarkers(canvas, size, k, phase, fieldLeft, pxPerM);
    }
    if (showSourceReceiver) {
      _paintSourceAndReceiver(
        canvas,
        size,
        aM: aM,
        k: k,
        phase: phase,
        pxPerM: pxPerM,
        bandTop: bandTop,
        bandH: bandH,
      );
    }
    _paintScaleBar(canvas, size, pxPerM);
  }

  /// Marks the nearest compression and the nearest rarefaction, and lets the
  /// student watch them travel to the right.
  void _paintMarkers(
    Canvas canvas,
    Size size,
    double k,
    double phase,
    double fieldLeft,
    double pxPerM,
  ) {
    // compression: kx - phase = 2*pi*n   ->   x = (phase + 2*pi*n)/k
    final lambda = 2 * math.pi / k;
    double? firstAt(double offsetRad) {
      final x0 = (phase + offsetRad) / k;
      final n = ((0.18 * viewWidthM - x0) / lambda).ceil();
      final x = x0 + n * lambda;
      return (x >= 0 && x <= viewWidthM * 0.92) ? x : null;
    }

    final xc = firstAt(0);
    final xr = firstAt(math.pi);

    if (xc != null) {
      _label(canvas, 'COMPRESSION', Offset(fieldLeft + xc * pxPerM, 4),
          AppColors.cyan, centered: true);
    }
    if (xr != null) {
      _label(canvas, 'RAREFACTION', Offset(fieldLeft + xr * pxPerM, 4),
          AppColors.indigo, centered: true);
    }
  }

  void _paintSourceAndReceiver(
    Canvas canvas,
    Size size, {
    required double aM,
    required double k,
    required double phase,
    required double pxPerM,
    required double bandTop,
    required double bandH,
  }) {
    final h = size.height;
    final w = size.width;

    // Source: a vibrating plate at x = 0. Its motion IS s(0,t).
    final s0 = WavePhysics.displacement(
      amplitude: aM,
      waveNumberK: k,
      x: 0,
      phase: phase,
    );
    final sourceShift = (s0 * pxPerM).clamp(-9.0, 9.0);
    final srcRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(6 + sourceShift, bandTop + bandH * 0.12, 11,
          bandH * 0.76),
      const Radius.circular(5),
    );
    canvas.drawRRect(
      srcRect,
      Paint()..color = fade(AppColors.cyan, 0.35 + 0.5 * amplitude),
    );

    // Receiver: level follows the local pressure at the far edge.
    final pressureAtEnd = WavePhysics.strain(
      amplitude: aM,
      waveNumberK: k,
      x: viewWidthM,
      phase: phase,
    );
    final peak = aM * k;
    final level = peak <= 0 ? 0.0 : ((pressureAtEnd / peak) + 1) / 2;
    final barH = bandH * 0.76;
    final rx = w - 17.0;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(rx, bandTop + bandH * 0.12, 11, barH),
        const Radius.circular(5),
      ),
      Paint()..color = fade(AppColors.stroke, 0.9),
    );
    final lit = barH * level * amplitude;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(rx, bandTop + bandH * 0.12 + (barH - lit), 11, lit),
        const Radius.circular(5),
      ),
      Paint()..color = fade(AppColors.amber, 0.85),
    );

    _label(canvas, 'SOURCE', Offset(4, h - 17), AppColors.textDim);
    _label(canvas, 'RECEIVER', Offset(w - 4, h - 17), AppColors.textDim,
        rightAligned: true);
  }

  void _paintScaleBar(Canvas canvas, Size size, double pxPerM) {
    final target = viewWidthM / 3;
    const steps = <double>[
      0.001, 0.002, 0.005, 0.01, 0.02, 0.05,
      0.1, 0.2, 0.5, 1, 2, 5, 10, 20, 50,
    ];
    var nice = steps.first;
    for (final s in steps) {
      if (s <= target) nice = s;
    }
    final len = nice * pxPerM;
    final y = size.height - 16.0;
    final x0 = size.width / 2 - len / 2;
    final p = Paint()
      ..color = fade(AppColors.textMuted, 0.75)
      ..strokeWidth = 1.6;
    canvas.drawLine(Offset(x0, y), Offset(x0 + len, y), p);
    canvas.drawLine(Offset(x0, y - 4), Offset(x0, y + 4), p);
    canvas.drawLine(Offset(x0 + len, y - 4), Offset(x0 + len, y + 4), p);
    final text = nice >= 1
        ? '${nice.toStringAsFixed(0)} m'
        : '${(nice * 100).toStringAsFixed(nice < 0.01 ? 1 : 0)} cm';
    _label(canvas, text, Offset(size.width / 2, y + 2), AppColors.textMuted,
        centered: true);
  }

  void _paintVacuum(Canvas canvas, Size size) {
    final rnd = math.Random(7);
    final star = Paint()..color = fade(AppColors.textDim, 0.5);
    for (var i = 0; i < 40; i++) {
      canvas.drawCircle(
        Offset(rnd.nextDouble() * size.width, rnd.nextDouble() * size.height),
        0.8,
        star,
      );
    }
    _label(
      canvas,
      'NO MEDIUM - NO WAVE',
      Offset(size.width / 2, size.height / 2 - 9),
      AppColors.textMuted,
      centered: true,
      size: 15,
    );
  }

  void _label(
    Canvas canvas,
    String text,
    Offset at,
    Color color, {
    bool centered = false,
    bool rightAligned = false,
    double size = 11.5,
  }) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: size,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.6,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    var dx = at.dx;
    if (centered) dx -= tp.width / 2;
    if (rightAligned) dx -= tp.width;
    tp.paint(canvas, Offset(dx, at.dy));
  }

  @override
  bool shouldRepaint(covariant ParticleFieldPainter old) =>
      old.amplitude != amplitude ||
      old.wavelengthM != wavelengthM ||
      old.viewWidthM != viewWidthM ||
      old.vacuum != vacuum ||
      old.mediumColor != mediumColor ||
      old.showMarkers != showMarkers;
}

/// Secondary, clearly-labelled GRAPH view. This is the one place a wavy line
/// is allowed, and the caption says it is a graph rather than the shape of the
/// wave in air.
class WaveGraphPainter extends CustomPainter {
  WaveGraphPainter({
    required this.clock,
    required this.amplitude,
    required this.wavelengthM,
    required this.viewWidthM,
  }) : super(repaint: clock);

  final SimClock clock;
  final double amplitude;
  final double wavelengthM;
  final double viewWidthM;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final mid = h / 2;
    if (wavelengthM <= 0 || !wavelengthM.isFinite) return;

    final k = WavePhysics.waveNumber(wavelengthM);
    final phase = clock.phase;
    final amp = (h / 2 - 12) * amplitude;

    canvas.drawLine(
      Offset(0, mid),
      Offset(w, mid),
      Paint()
        ..color = fade(AppColors.stroke, 0.9)
        ..strokeWidth = 1,
    );

    final disp = Path();
    final pres = Path();
    for (var i = 0; i <= w.toInt(); i += 2) {
      final xm = i / w * viewWidthM;
      final s = math.sin(k * xm - phase);
      final p = math.cos(k * xm - phase); // pressure leads displacement by 90 deg
      final yd = mid - s * amp;
      final yp = mid - p * amp * 0.72;
      if (i == 0) {
        disp.moveTo(0, yd);
        pres.moveTo(0, yp);
      } else {
        disp.lineTo(i.toDouble(), yd);
        pres.lineTo(i.toDouble(), yp);
      }
    }

    canvas.drawPath(
      pres,
      Paint()
        ..color = fade(AppColors.amber, 0.65)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6,
    );
    canvas.drawPath(
      disp,
      Paint()
        ..color = AppColors.cyan
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4,
    );
  }

  @override
  bool shouldRepaint(covariant WaveGraphPainter old) =>
      old.amplitude != amplitude ||
      old.wavelengthM != wavelengthM ||
      old.viewWidthM != viewWidthM;
}
