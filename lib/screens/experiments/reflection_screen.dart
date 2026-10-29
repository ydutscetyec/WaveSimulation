import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../models/acoustic_material.dart';
import '../../theme/wave_theme.dart';
import '../../widgets/sim_clock.dart';
import '../../widgets/ui_kit.dart';

class ReflectionScreen extends StatefulWidget {
  const ReflectionScreen({super.key});

  @override
  State<ReflectionScreen> createState() => _ReflectionScreenState();
}

class _ReflectionScreenState extends State<ReflectionScreen> {
  WallMaterial _wall = Walls.concrete;
  bool _running = true;

  @override
  Widget build(BuildContext context) {
    final c = context.c;

    return LabScaffold(
      title: 'Reflection',
      subtitle: 'Incident pulse, wall, return',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 200,
            width: double.infinity,
            child: ClockHost(
              hz: 1,
              timeRate: 0.42,
              running: _running,
              builder: (context, clock) => CustomPaint(
                painter: _ReflectionPainter(
                  clock: clock,
                  colors: c,
                  wall: _wall,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
              foregroundColor: c.textPrimary,
              side: BorderSide(color: c.stroke),
            ),
            onPressed: () => setState(() => _running = !_running),
            icon: Icon(_running ? Icons.pause : Icons.play_arrow),
            label: Text(_running ? 'Pause' : 'Play'),
          ),
          const SizedBox(height: 14),
          Panel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const PanelTitle('Wall material', icon: Icons.wallpaper),
                ChipRow<WallMaterial>(
                  items: Walls.all,
                  labelOf: (w) => w.name,
                  selected: _wall,
                  onSelect: (w) => setState(() => _wall = w),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: ValueCard(
                        label: 'Energy absorbed',
                        value: '${_wall.absorbedPercentEnergy}',
                        unit: '%',
                        color: c.red,
                        compact: true,
                      ),
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: ValueCard(
                        label: 'Energy back',
                        value: '${100 - _wall.absorbedPercentEnergy}',
                        unit: '%',
                        compact: true,
                      ),
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: ValueCard(
                        label: 'Amplitude back',
                        value: '${_wall.reflectedPercent}',
                        unit: '%',
                        color: c.amber,
                        compact: true,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Body(_wall.note),
              ],
            ),
          ),
          Panel(
            margin: EdgeInsets.zero,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const PanelTitle('Why those two numbers differ',
                    icon: Icons.calculate_outlined),
                const Body(
                  'Alpha is a fraction of ENERGY, and energy goes as amplitude '
                  'squared. So the amplitude that returns is sqrt(1 - alpha), '
                  'not 1 - alpha.',
                ),
                const SizedBox(height: 10),
                Text(
                  '${_wall.name}: alpha = ${_wall.alpha.toStringAsFixed(2)}, '
                  'so sqrt(1 - ${_wall.alpha.toStringAsFixed(2)}) = '
                  '${_wall.reflectedRatio.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: c.accent,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 12),
                const Tip(
                  'No everyday surface absorbs everything. Even foam lets low '
                  'frequencies straight through.',
                  icon: Icons.warning_amber,
                ),
                const SizedBox(height: 12),
                const PanelTitle('How this screen is modelled',
                    icon: Icons.info_outline),
                const Body(
                  'This is an energy-accounting demonstration, not a solved '
                  'wave. The packet is drawn travelling out and back, and its '
                  'returning amplitude is scaled by sqrt(1 - alpha) from the '
                  'table above. The numbers are real; the motion is scripted.',
                ),
                const SizedBox(height: 8),
                const Body(
                  'For reflection that genuinely emerges from the physics - '
                  'where the inversion at a fixed end falls out of the '
                  'boundary condition rather than being drawn - use Wave on a '
                  'string. Absorption by coefficient is not something that '
                  'solver models, which is why both screens exist.',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A localised wave packet: s(x) = A sin(k(x-xc)) * exp(-(x-xc)^2 / 2 sigma^2).
/// It travels right, hits the wall, and returns with its amplitude scaled by
/// sqrt(1 - alpha), so foam visibly comes back smaller than concrete.
class _ReflectionPainter extends CustomPainter {
  _ReflectionPainter({
    required this.clock,
    required this.colors,
    required this.wall,
  }) : super(repaint: clock);

  final SimClock clock;
  final WaveColors colors;
  final WallMaterial wall;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final rr = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, w, h),
      const Radius.circular(18),
    );
    canvas.drawRRect(rr, Paint()..color = colors.canvasTop);
    canvas.save();
    canvas.clipRRect(rr);

    const leftPad = 30.0;
    final wallX = w - 32.0;
    final span = wallX - leftPad;
    const top = 30.0;
    final bottom = h - 26.0;
    final bandH = bottom - top;

    canvas.drawRect(
      Rect.fromLTWH(wallX, top - 6, 26, bandH + 12),
      Paint()..color = colors.wall,
    );

    final u = clock.seconds % 2.0;
    final out = u <= 1.0;
    final pos = out ? u : 2.0 - u;
    final amp = out ? 1.0 : wall.reflectedRatio;
    final dir = out ? 1.0 : -1.0;

    final xc = pos * span;
    const sigma = 34.0;
    final k = 2 * math.pi / 42.0;
    final aPx = 7.5 * amp;

    final rows = (bandH / 20).clamp(3, 8).round();
    final rowGap = bandH / (rows + 1);
    final cols = (span / 6).round();
    final spacing = span / (cols - 1);

    final dot = Paint();
    for (var r = 0; r < rows; r++) {
      final y = top + rowGap * (r + 1);
      for (var i = 0; i < cols; i++) {
        final x = i * spacing;
        final d = x - xc;
        final env = math.exp(-(d * d) / (2 * sigma * sigma));
        final s = aPx * env * math.sin(dir * k * d);
        final t = (env * math.cos(dir * k * d) + 1) / 2;
        dot.color = fade(
          Color.lerp(colors.rarefaction, colors.compression, t) ??
              colors.compression,
          0.32 + 0.62 * env,
        );
        canvas.drawCircle(Offset(leftPad + x + s, y), 2.0 + 2.2 * env, dot);
      }
    }

    // absorbed energy flashes in the wall on contact
    if (!out && u < 1.25) {
      final heat = (1 - (u - 1) / 0.25).clamp(0.0, 1.0) * wall.alpha;
      canvas.drawRect(
        Rect.fromLTWH(wallX, top - 6, 26, bandH + 12),
        Paint()..color = fade(colors.red, 0.6 * heat),
      );
    }

    _text(canvas, out ? 'INCIDENT' : 'REFLECTED', const Offset(leftPad, 9),
        out ? colors.compression : colors.amber);
    _text(canvas, wall.name.toUpperCase(), Offset(w - 8, h - 19),
        colors.textSecondary, rightAligned: true);
    canvas.restore();
  }

  void _text(Canvas canvas, String s, Offset at, Color color,
      {bool rightAligned = false}) {
    final tp = TextPainter(
      text: TextSpan(
        text: s,
        style: TextStyle(
          color: color,
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.6,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(rightAligned ? at.dx - tp.width : at.dx, at.dy));
  }

  @override
  bool shouldRepaint(covariant _ReflectionPainter old) =>
      old.wall != wall || old.colors != colors;
}
