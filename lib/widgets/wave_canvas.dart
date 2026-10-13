import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../services/wave_physics.dart';
import '../theme/wave_theme.dart';
import 'sim_clock.dart';

/// The main view of sound: particles displaced ALONG the direction of travel.
///
/// New in this version, and all three are there to make the thing worth
/// watching rather than merely correct:
///  * soft bands behind each compression, so you can see the pattern move
///    without having to track individual dots;
///  * one tracer particle in amber with its rest position marked, which shows
///    the particle oscillates in place while the compressions travel through
///    it - the single hardest idea in the topic;
///  * a wavefront marker that crosses the canvas at the scaled wave speed, so
///    switching air to water visibly speeds the wave up instead of only
///    changing a number.
///
/// The physics is unchanged: x = rest + A sin(kx - phase), and compression is
/// read from -ds/dx rather than painted in by hand.
class WavePainter extends CustomPainter {
  WavePainter({
    required this.clock,
    required this.colors,
    required this.amplitude,
    required this.wavelengthM,
    required this.viewWidthM,
    required this.accent,
    this.vacuum = false,
    this.showTracer = true,
    this.showFront = true,
    this.showSource = true,
    this.speedMs = 343,
  }) : super(repaint: clock);

  final SimClock clock;
  final WaveColors colors;
  final double amplitude; // 0..1
  final double wavelengthM;
  final double viewWidthM;
  final Color accent;
  final bool vacuum;
  final bool showTracer;
  final bool showFront;
  final bool showSource;
  final double speedMs;

  static const double _edge = 26;
  static const double _topPad = 26;
  static const double _botPad = 32;
  static const int _lutSteps = 24;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, w, h),
      const Radius.circular(18),
    );

    canvas.drawRRect(
      rrect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [colors.canvasTop, colors.canvasBottom],
        ).createShader(Rect.fromLTWH(0, 0, w, h)),
    );
    canvas.save();
    canvas.clipRRect(rrect);

    if (vacuum) {
      _paintVacuum(canvas, size);
      canvas.restore();
      return;
    }

    final fieldLeft = _edge;
    final fieldW = w - _edge * 2;
    if (fieldW <= 10 || wavelengthM <= 0 || !wavelengthM.isFinite) {
      canvas.restore();
      return;
    }

    final bandTop = _topPad;
    final bandH = math.max(20.0, h - _botPad - bandTop);
    final k = WavePhysics.waveNumber(wavelengthM);
    final phase = clock.phase;
    final pxPerM = fieldW / viewWidthM;

    final cols = (fieldW / 6.5).clamp(40, 110).round();
    final rows = (bandH / 20).clamp(3, 9).round();
    final spacingM = viewWidthM / (cols - 1);
    final rowGap = bandH / (rows + 1);

    // A*k < 1, or neighbouring particles would pass through each other.
    final aM = amplitude *
        math.min(WavePhysics.maxPhysicalAmplitude(k), spacingM * 2.4);
    final strainScale = aM * k;

    // 1. soft bands behind the compressions
    _paintCompressionBands(
      canvas,
      k: k,
      phase: phase,
      fieldLeft: fieldLeft,
      pxPerM: pxPerM,
      top: bandTop - 6,
      height: bandH + 12,
    );

    // 2. the particles
    final lut = List<Color>.generate(_lutSteps, (i) {
      final t = i / (_lutSteps - 1);
      return fade(
        Color.lerp(colors.rarefaction, colors.compression, t) ??
            colors.compression,
        0.45 + 0.55 * t,
      );
    });

    final dot = Paint()..style = PaintingStyle.fill;
    final tracerRow = rows ~/ 2;
    final tracerCol = (cols * 0.34).round();
    double tracerRestPx = 0;
    double tracerPx = 0;
    double tracerY = 0;

    for (var r = 0; r < rows; r++) {
      final y = bandTop + rowGap * (r + 1);
      final rowOffset = r.isOdd ? 0.5 : 0.0;
      for (var col = 0; col < cols; col++) {
        final xm = (col + rowOffset) * spacingM;
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
        final t = strainScale <= 0 ? 0.5 : (strain / strainScale + 1) / 2;
        final px = fieldLeft + (xm + s) * pxPerM;

        if (showTracer && r == tracerRow && col == tracerCol) {
          tracerRestPx = fieldLeft + xm * pxPerM;
          tracerPx = px;
          tracerY = y;
          continue; // drawn separately, on top
        }

        dot.color = lut[(t * (_lutSteps - 1)).round().clamp(0, _lutSteps - 1)];
        canvas.drawCircle(Offset(px, y), 2.0 + 2.1 * t, dot);
      }
    }

    // 3. the wavefront, riding the leading compression
    if (showFront && amplitude > 0.02) {
      final frontM = (speedMs * clock.seconds) % viewWidthM;
      final fx = fieldLeft + frontM * pxPerM;
      canvas.drawLine(
        Offset(fx, bandTop - 4),
        Offset(fx, bandTop + bandH + 4),
        Paint()
          ..color = fade(colors.amber, 0.55)
          ..strokeWidth = 2,
      );
      final tri = Path()
        ..moveTo(fx - 5, bandTop - 6)
        ..lineTo(fx + 5, bandTop - 6)
        ..lineTo(fx, bandTop + 1)
        ..close();
      canvas.drawPath(tri, Paint()..color = colors.amber);
    }

    // 4. the tracer particle and its rest position
    if (showTracer && tracerPx > 0) {
      _paintTracer(canvas, tracerRestPx, tracerPx, tracerY, aM * pxPerM);
    }

    if (showSource) {
      _paintSource(
        canvas,
        aM: aM,
        k: k,
        phase: phase,
        pxPerM: pxPerM,
        top: bandTop,
        bandH: bandH,
      );
    }

    _paintScaleBar(canvas, size, pxPerM);
    canvas.restore();
  }

  void _paintCompressionBands(
    Canvas canvas, {
    required double k,
    required double phase,
    required double fieldLeft,
    required double pxPerM,
    required double top,
    required double height,
  }) {
    if (amplitude <= 0.02) return;
    final lambda = 2 * math.pi / k;
    final bandW = math.max(6.0, lambda * pxPerM * 0.34);
    // compressions sit at kx - phase = 2*pi*n
    final x0 = phase / k;
    var n = (-x0 / lambda).ceil();
    final paint = Paint()..color = fade(accent, 0.10);
    while (true) {
      final xm = x0 + n * lambda;
      if (xm > viewWidthM) break;
      if (xm >= 0) {
        final cx = fieldLeft + xm * pxPerM;
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(cx - bandW / 2, top, bandW, height),
            const Radius.circular(8),
          ),
          paint,
        );
      }
      n++;
      if (n > 400) break; // belt and braces against a pathological zoom
    }
  }

  void _paintTracer(
    Canvas canvas,
    double restPx,
    double px,
    double y,
    double ampPx,
  ) {
    // travel range
    if (ampPx > 1.5) {
      canvas.drawLine(
        Offset(restPx - ampPx, y),
        Offset(restPx + ampPx, y),
        Paint()
          ..color = fade(colors.amber, 0.40)
          ..strokeWidth = 1.6,
      );
    }
    // rest position
    canvas.drawCircle(
      Offset(restPx, y),
      3.5,
      Paint()
        ..color = fade(colors.amber, 0.65)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4,
    );
    // the particle itself
    canvas.drawCircle(Offset(px, y), 6.5, Paint()..color = colors.amber);
    _label(
      canvas,
      'one particle',
      Offset(restPx, y + 11),
      colors.amber,
      centered: true,
      size: 10.5,
    );
  }

  void _paintSource(
    Canvas canvas, {
    required double aM,
    required double k,
    required double phase,
    required double pxPerM,
    required double top,
    required double bandH,
  }) {
    final s0 = WavePhysics.displacement(
      amplitude: aM,
      waveNumberK: k,
      x: 0,
      phase: phase,
    );
    final shift = (s0 * pxPerM).clamp(-8.0, 8.0);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(4 + shift, top + bandH * 0.14, 10, bandH * 0.72),
        const Radius.circular(5),
      ),
      Paint()..color = fade(accent, 0.45 + 0.45 * amplitude),
    );
  }

  void _paintScaleBar(Canvas canvas, Size size, double pxPerM) {
    const steps = <double>[
      0.001, 0.002, 0.005, 0.01, 0.02, 0.05,
      0.1, 0.2, 0.5, 1, 2, 5, 10, 20, 50,
    ];
    final target = viewWidthM / 3;
    var nice = steps.first;
    for (final s in steps) {
      if (s <= target) nice = s;
    }
    final len = nice * pxPerM;
    final y = size.height - 17.0;
    final x0 = size.width / 2 - len / 2;
    final p = Paint()
      ..color = fade(colors.textTertiary, 0.85)
      ..strokeWidth = 1.6;
    canvas.drawLine(Offset(x0, y), Offset(x0 + len, y), p);
    canvas.drawLine(Offset(x0, y - 4), Offset(x0, y + 4), p);
    canvas.drawLine(Offset(x0 + len, y - 4), Offset(x0 + len, y + 4), p);
    final txt = nice >= 1
        ? '${nice.toStringAsFixed(0)} m'
        : '${(nice * 100).toStringAsFixed(nice < 0.01 ? 1 : 0)} cm';
    _label(canvas, txt, Offset(size.width / 2, y + 2), colors.textTertiary,
        centered: true);
  }

  void _paintVacuum(Canvas canvas, Size size) {
    final rnd = math.Random(7);
    final star = Paint()..color = fade(colors.textTertiary, 0.45);
    for (var i = 0; i < 40; i++) {
      canvas.drawCircle(
        Offset(rnd.nextDouble() * size.width, rnd.nextDouble() * size.height),
        0.9,
        star,
      );
    }
    _label(
      canvas,
      'no particles, no wave',
      Offset(size.width / 2, size.height / 2 - 9),
      colors.textSecondary,
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
    double size = 11.5,
  }) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: size,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.4,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(centered ? at.dx - tp.width / 2 : at.dx, at.dy));
  }

  @override
  bool shouldRepaint(covariant WavePainter old) =>
      old.amplitude != amplitude ||
      old.wavelengthM != wavelengthM ||
      old.viewWidthM != viewWidthM ||
      old.vacuum != vacuum ||
      old.accent != accent ||
      old.colors != colors ||
      old.speedMs != speedMs ||
      old.showTracer != showTracer;
}

/// Optional graph strip. Clearly a graph, not the shape of air.
class GraphPainter extends CustomPainter {
  GraphPainter({
    required this.clock,
    required this.colors,
    required this.amplitude,
    required this.wavelengthM,
    required this.viewWidthM,
  }) : super(repaint: clock);

  final SimClock clock;
  final WaveColors colors;
  final double amplitude;
  final double wavelengthM;
  final double viewWidthM;

  @override
  void paint(Canvas canvas, Size size) {
    if (wavelengthM <= 0 || !wavelengthM.isFinite) return;
    final w = size.width;
    final mid = size.height / 2;
    final k = WavePhysics.waveNumber(wavelengthM);
    final phase = clock.phase;
    final amp = (size.height / 2 - 10) * amplitude;

    canvas.drawLine(
      Offset(0, mid),
      Offset(w, mid),
      Paint()
        ..color = fade(colors.stroke, 0.9)
        ..strokeWidth = 1,
    );

    final disp = Path();
    final pres = Path();
    for (var i = 0; i <= w.toInt(); i += 2) {
      final xm = i / w * viewWidthM;
      final yd = mid - math.sin(k * xm - phase) * amp;
      final yp = mid - math.cos(k * xm - phase) * amp * 0.7;
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
        ..color = fade(colors.amber, 0.75)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8,
    );
    canvas.drawPath(
      disp,
      Paint()
        ..color = colors.accent
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4,
    );
  }

  @override
  bool shouldRepaint(covariant GraphPainter old) =>
      old.amplitude != amplitude ||
      old.wavelengthM != wavelengthM ||
      old.viewWidthM != viewWidthM ||
      old.colors != colors;
}
