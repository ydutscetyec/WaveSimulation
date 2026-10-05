import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../models/acoustic_material.dart';
import '../../theme/app_theme.dart';
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
    return LabScaffold(
      title: 'Reflection',
      subtitle: 'Incident pulse, wall, returning pulse',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 210,
            width: double.infinity,
            child: ClockHost(
              hz: 1,
              timeRate: 0.42, // one round trip takes a few seconds
              running: _running,
              builder: (context, clock) => CustomPaint(
                painter: _ReflectionPainter(clock: clock, wall: _wall),
              ),
            ),
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
                  colorOf: (w) => w.color,
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
                        color: AppColors.red,
                        compact: true,
                      ),
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: ValueCard(
                        label: 'Energy reflected',
                        value: '${100 - _wall.absorbedPercentEnergy}',
                        unit: '%',
                        color: AppColors.cyan,
                        compact: true,
                      ),
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: ValueCard(
                        label: 'Amplitude back',
                        value: '${_wall.reflectedPercent}',
                        unit: '%',
                        color: AppColors.amber,
                        compact: true,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  _wall.note,
                  style: const TextStyle(
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
                const PanelTitle('Why amplitude and energy differ',
                    icon: Icons.calculate_outlined),
                const Text(
                  'Absorption coefficient alpha is a fraction of ENERGY, and '
                  'energy goes as amplitude squared. So the amplitude that '
                  'comes back is sqrt(1 - alpha), not 1 - alpha.',
                  style: TextStyle(
                    fontSize: 14.5,
                    color: AppColors.textMuted,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'For ${_wall.name}: alpha = ${_wall.alpha.toStringAsFixed(2)}, '
                  'so amplitude ratio = sqrt(1 - ${_wall.alpha.toStringAsFixed(2)}) '
                  '= ${_wall.reflectedRatio.toStringAsFixed(2)}.',
                  style: const TextStyle(
                    fontSize: 14.5,
                    color: AppColors.cyan,
                    fontWeight: FontWeight.w600,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 12),
                const Explain(
                  'No everyday surface absorbs everything. Even acoustic foam '
                  'lets low frequencies straight through, because a porous '
                  'absorber only works when its thickness is a real fraction '
                  'of the wavelength.',
                  icon: Icons.warning_amber,
                  color: AppColors.amber,
                ),
              ],
            ),
          ),
          Panel(
            margin: EdgeInsets.zero,
            child: Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(50),
                      backgroundColor: fade(AppColors.cyan, 0.2),
                      foregroundColor: AppColors.cyan,
                    ),
                    onPressed: () => setState(() => _running = !_running),
                    icon: Icon(_running ? Icons.pause : Icons.play_arrow),
                    label: Text(_running ? 'Pause' : 'Play'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A localised longitudinal wave packet:
///   s(x) = A sin(k(x - xc)) * exp( -(x-xc)^2 / 2*sigma^2 )
/// It travels right, hits the wall, and comes back with its amplitude scaled
/// by sqrt(1 - alpha). The returning packet is genuinely smaller for foam.
class _ReflectionPainter extends CustomPainter {
  _ReflectionPainter({required this.clock, required this.wall})
      : super(repaint: clock);

  final SimClock clock;
  final WallMaterial wall;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, w, h),
        const Radius.circular(16),
      ),
      Paint()..color = const Color(0xFF081226),
    );

    const leftPad = 34.0;
    final wallX = w - 34.0;
    final span = wallX - leftPad;
    final top = 30.0;
    final bottom = h - 26.0;
    final bandH = bottom - top;

    // wall
    canvas.drawRect(
      Rect.fromLTWH(wallX, top - 6, 26, bandH + 12),
      Paint()..color = fade(wall.color, 0.85),
    );

    // packet position, 0 -> 1 -> 0
    final u = clock.seconds % 2.0;
    final goingOut = u <= 1.0;
    final pos = goingOut ? u : 2.0 - u;
    final amp = goingOut ? 1.0 : wall.reflectedRatio;
    final dir = goingOut ? 1.0 : -1.0;

    final xc = pos * span; // px from leftPad
    const sigma = 34.0;
    final k = 2 * math.pi / 42.0; // px wavelength inside the packet
    final aPx = 7.5 * amp;

    final rows = (bandH / 20).clamp(3, 8).round();
    final rowGap = bandH / (rows + 1);
    final cols = (span / 6).round();
    final spacing = span / (cols - 1);

    final dot = Paint();
    for (var r = 0; r < rows; r++) {
      final y = top + rowGap * (r + 1);
      for (var c = 0; c < cols; c++) {
        final x = c * spacing;
        final d = x - xc;
        final env = math.exp(-(d * d) / (2 * sigma * sigma));
        final s = aPx * env * math.sin(dir * k * d);
        final strainish = env * math.cos(dir * k * d);
        final t = (strainish + 1) / 2;
        dot.color = fade(
          Color.lerp(AppColors.indigo, AppColors.cyan, t) ?? AppColors.cyan,
          0.30 + 0.65 * env,
        );
        canvas.drawCircle(Offset(leftPad + x + s, y), 1.9 + 2.2 * env, dot);
      }
    }

    // absorbed energy glows in the wall on contact
    if (!goingOut && u < 1.25) {
      final heat = (1 - (u - 1) / 0.25).clamp(0.0, 1.0) * wall.alpha;
      canvas.drawRect(
        Rect.fromLTWH(wallX, top - 6, 26, bandH + 12),
        Paint()..color = fade(AppColors.red, 0.55 * heat),
      );
    }

    _text(canvas, goingOut ? 'INCIDENT WAVE' : 'REFLECTED WAVE',
        Offset(leftPad, 8), goingOut ? AppColors.cyan : AppColors.amber);
    _text(canvas, wall.name.toUpperCase(), Offset(w - 6, h - 18),
        AppColors.textMuted, rightAligned: true);
    _text(canvas, 'SOURCE', Offset(4, h - 18), AppColors.textDim);
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
  bool shouldRepaint(covariant _ReflectionPainter old) => old.wall != wall;
}
