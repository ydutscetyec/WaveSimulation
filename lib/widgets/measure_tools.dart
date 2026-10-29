import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/wave_theme.dart';

/// A draggable ruler laid over a simulation canvas.
///
/// This is the difference between a demonstration and an experiment. A student
/// who measures crest-to-crest spacing with the ruler and then checks it
/// against the displayed wavelength has done physics. A student who reads the
/// wavelength off a panel has only read a number.
///
/// The parent says how many real metres the canvas spans; everything else is
/// geometry.
class RulerOverlay extends StatefulWidget {
  const RulerOverlay({
    super.key,
    required this.child,
    required this.metresAcross,
    this.enabled = true,
    this.insetFraction = 0.0,
  });

  final Widget child;

  /// Real width the canvas represents, metres.
  final double metresAcross;

  final bool enabled;

  /// Fraction of the width taken by canvas padding on each side, so the ruler
  /// measures against the same scale the wave is drawn on.
  final double insetFraction;

  @override
  State<RulerOverlay> createState() => _RulerOverlayState();
}

class _RulerOverlayState extends State<RulerOverlay> {
  // normalised 0..1 positions
  Offset _a = const Offset(0.25, 0.75);
  Offset _b = const Offset(0.55, 0.75);
  int _dragging = -1;

  void _onDown(Offset local, Size size) {
    final pa = Offset(_a.dx * size.width, _a.dy * size.height);
    final pb = Offset(_b.dx * size.width, _b.dy * size.height);
    final da = (local - pa).distance;
    final db = (local - pb).distance;
    // generous hit radius: fingers are not pixels
    if (da < 44 || db < 44) {
      _dragging = da <= db ? 0 : 1;
    } else {
      _dragging = -1;
    }
  }

  void _onMove(Offset local, Size size) {
    if (_dragging < 0) return;
    final n = Offset(
      (local.dx / size.width).clamp(0.0, 1.0),
      (local.dy / size.height).clamp(0.0, 1.0),
    );
    setState(() {
      if (_dragging == 0) {
        _a = n;
      } else {
        _b = n;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) return widget.child;
    final c = context.c;

    return LayoutBuilder(
      builder: (context, box) {
        final size = box.biggest;
        // the drawable span excludes the canvas padding
        final usable = 1 - 2 * widget.insetFraction;
        final metres =
            ((_b.dx - _a.dx).abs() / usable) * widget.metresAcross;

        return Stack(
          children: [
            widget.child,
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onPanDown: (d) => _onDown(d.localPosition, size),
                onPanUpdate: (d) => _onMove(d.localPosition, size),
                onPanEnd: (_) => _dragging = -1,
                child: CustomPaint(
                  painter: _RulerPainter(
                    a: _a,
                    b: _b,
                    colors: c,
                    metres: metres,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _RulerPainter extends CustomPainter {
  _RulerPainter({
    required this.a,
    required this.b,
    required this.colors,
    required this.metres,
  });

  final Offset a;
  final Offset b;
  final WaveColors colors;
  final double metres;

  @override
  void paint(Canvas canvas, Size size) {
    final pa = Offset(a.dx * size.width, a.dy * size.height);
    final pb = Offset(b.dx * size.width, b.dy * size.height);

    final line = Paint()
      ..color = colors.amber
      ..strokeWidth = 2;

    // vertical guides, so the student lines the handles up with crests
    final guide = Paint()
      ..color = fade(colors.amber, 0.35)
      ..strokeWidth = 1;
    for (final p in [pa, pb]) {
      canvas.drawLine(Offset(p.dx, 6), Offset(p.dx, size.height - 6), guide);
    }

    // the measured span
    canvas.drawLine(Offset(pa.dx, pa.dy), Offset(pb.dx, pa.dy), line);

    // end caps
    for (final p in [pa, pb]) {
      canvas.drawLine(
        Offset(p.dx, pa.dy - 8),
        Offset(p.dx, pa.dy + 8),
        line,
      );
      canvas.drawCircle(
        Offset(p.dx, p == pa ? pa.dy : pb.dy),
        9,
        Paint()
          ..color = colors.amber
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.4,
      );
      canvas.drawCircle(
        Offset(p.dx, p == pa ? pa.dy : pb.dy),
        3.5,
        Paint()..color = colors.amber,
      );
    }

    // readout, placed above the line and kept inside the canvas
    final label = metres < 1
        ? '${(metres * 100).toStringAsFixed(1)} cm'
        : '${metres.toStringAsFixed(2)} m';
    final tp = TextPainter(
      text: TextSpan(
        text: label,
        style: TextStyle(
          color: colors.amber,
          fontSize: 13,
          fontWeight: FontWeight.w800,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    final midX = (pa.dx + pb.dx) / 2;
    final boxW = tp.width + 14;
    final left = (midX - boxW / 2).clamp(2.0, size.width - boxW - 2);
    final top = math.max(2.0, pa.dy - 30);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(left, top, boxW, tp.height + 8),
        const Radius.circular(7),
      ),
      Paint()..color = fade(colors.canvasBottom, 0.92),
    );
    tp.paint(canvas, Offset(left + 7, top + 4));
  }

  @override
  bool shouldRepaint(covariant _RulerPainter old) =>
      old.a != a || old.b != b || old.metres != metres || old.colors != colors;
}

/// Stopwatch for timing a wavefront across the canvas, so wave speed can be
/// measured rather than read: v = distance / time.
class LabTimer extends StatefulWidget {
  const LabTimer({super.key, this.hint});

  final String? hint;

  @override
  State<LabTimer> createState() => _LabTimerState();
}

class _LabTimerState extends State<LabTimer> {
  final Stopwatch _watch = Stopwatch();
  Duration _shown = Duration.zero;
  bool _ticking = false;

  void _loop() async {
    while (_ticking && mounted) {
      await Future<void>.delayed(const Duration(milliseconds: 50));
      if (!mounted) return;
      setState(() => _shown = _watch.elapsed);
    }
  }

  void _toggle() {
    setState(() {
      if (_watch.isRunning) {
        _watch.stop();
        _ticking = false;
      } else {
        _watch.start();
        _ticking = true;
        _loop();
      }
      _shown = _watch.elapsed;
    });
  }

  void _reset() {
    setState(() {
      _watch
        ..stop()
        ..reset();
      _ticking = false;
      _shown = Duration.zero;
    });
  }

  @override
  void dispose() {
    _ticking = false;
    _watch.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final secs = _shown.inMilliseconds / 1000.0;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: c.surfaceAlt,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: c.stroke),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.timer_outlined, size: 19, color: c.blue),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  '${secs.toStringAsFixed(2)} s',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: c.blue,
                  ),
                ),
              ),
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(84, 44),
                  foregroundColor: c.textPrimary,
                  side: BorderSide(color: c.stroke),
                ),
                onPressed: _toggle,
                child: Text(_watch.isRunning ? 'Stop' : 'Start'),
              ),
              const SizedBox(width: 8),
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(56, 44),
                  foregroundColor: c.textPrimary,
                  side: BorderSide(color: c.stroke),
                ),
                onPressed: _reset,
                child: const Icon(Icons.refresh, size: 18),
              ),
            ],
          ),
          if (widget.hint != null) ...[
            const SizedBox(height: 8),
            Text(
              widget.hint!,
              style: TextStyle(
                fontSize: 13,
                height: 1.4,
                color: c.textTertiary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
