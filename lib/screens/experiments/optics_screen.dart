import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../services/optics_physics.dart';
import '../../theme/wave_theme.dart';
import '../../widgets/ui_kit.dart';

/// Module 5 - Geometric optics: refraction at a boundary.
///
/// Rays are geometric optics and are not a model of wave interference. The two
/// are kept apart deliberately: a ray diagram cannot explain diffraction, and
/// the interference module cannot tell you where an image forms.
class OpticsScreen extends StatefulWidget {
  const OpticsScreen({super.key});

  @override
  State<OpticsScreen> createState() => _OpticsScreenState();
}

class _OpticsScreenState extends State<OpticsScreen> {
  static const List<(String, double)> _media = [
    ('Vacuum', 1.0),
    ('Air', 1.0003),
    ('Water', 1.333),
    ('Glass', 1.52),
    ('Diamond', 2.417),
  ];

  double _incidenceDeg = 45;
  double _n1 = 1.0;
  double _n2 = 1.52;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final incRad = OpticsPhysics.degToRad(_incidenceDeg);
    final refracted =
        OpticsPhysics.refractionAngle(incidenceRad: incRad, n1: _n1, n2: _n2);
    final critical = OpticsPhysics.criticalAngle(n1: _n1, n2: _n2);
    final tir = refracted == null;
    final reflectance = OpticsPhysics.fresnelReflectance(
      incidenceRad: incRad,
      n1: _n1,
      n2: _n2,
    );

    return LabScaffold(
      title: 'Refraction',
      subtitle: "Snell's law at a boundary",
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 290,
            width: double.infinity,
            child: CustomPaint(
              painter: _RayPainter(
                colors: c,
                incidenceRad: incRad,
                refractedRad: refracted,
                n1: _n1,
                n2: _n2,
              ),
            ),
          ),
          const SizedBox(height: 14),

          Panel(
            accent: tir ? c.amber : null,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: ValueCard(
                        label: 'Incidence',
                        value: _incidenceDeg.toStringAsFixed(1),
                        unit: '°',
                        compact: true,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ValueCard(
                        label: 'Refraction',
                        value: refracted == null
                            ? '—'
                            : OpticsPhysics.radToDeg(refracted)
                                .toStringAsFixed(1),
                        unit: refracted == null ? null : '°',
                        color: c.amber,
                        compact: true,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ValueCard(
                        label: 'Reflected',
                        value: (reflectance * 100).toStringAsFixed(1),
                        unit: '%',
                        color: c.blue,
                        compact: true,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 11),
                if (!tir)
                  Text(
                    'n1 sin t1 = n2 sin t2\n'
                    '${_n1.toStringAsFixed(3)} x sin ${_incidenceDeg.toStringAsFixed(1)}° '
                    '= ${_n2.toStringAsFixed(3)} x sin '
                    '${OpticsPhysics.radToDeg(refracted).toStringAsFixed(1)}°\n'
                    '${(_n1 * math.sin(incRad)).toStringAsFixed(4)} = '
                    '${(_n2 * math.sin(refracted)).toStringAsFixed(4)}',
                    style: TextStyle(
                      fontSize: 14.5,
                      height: 1.65,
                      fontWeight: FontWeight.w700,
                      color: c.accent,
                    ),
                  )
                else
                  Body(
                    'Total internal reflection. Past the critical angle of '
                    '${OpticsPhysics.radToDeg(critical!).toStringAsFixed(1)}° '
                    'there is no refracted ray at all — every bit of the light '
                    'turns back into the denser medium. This is how optical '
                    'fibres keep light inside them.',
                    size: 14.5,
                    color: c.amber,
                  ),
                const SizedBox(height: 10),
                Body(
                  critical == null
                      ? 'Going from rarer to denser, so there is no critical '
                          'angle. The ray always crosses, bending towards the '
                          'normal.'
                      : 'Critical angle: '
                          '${OpticsPhysics.radToDeg(critical).toStringAsFixed(1)}°. '
                          'Beyond it, nothing crosses.',
                  size: 13.5,
                  color: c.textTertiary,
                ),
              ],
            ),
          ),

          Panel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const PanelTitle('Angle of incidence', icon: Icons.architecture),
                StepSlider(
                  label: 'Measured from the normal, not the surface',
                  value: _incidenceDeg,
                  min: 0,
                  max: 89,
                  step: 1,
                  readout: '${_incidenceDeg.toStringAsFixed(0)}°',
                  onChanged: (v) => setState(() => _incidenceDeg = v),
                ),
              ],
            ),
          ),

          Panel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const PanelTitle('Top medium (n1)', icon: Icons.water_drop_outlined),
                ChipRow<double>(
                  items: _media.map((m) => m.$2).toList(),
                  labelOf: (v) => _media.firstWhere((m) => m.$2 == v).$1,
                  selected: _n1,
                  onSelect: (v) => setState(() => _n1 = v),
                ),
                const SizedBox(height: 16),
                const PanelTitle('Bottom medium (n2)',
                    icon: Icons.layers_outlined),
                ChipRow<double>(
                  items: _media.map((m) => m.$2).toList(),
                  labelOf: (v) => _media.firstWhere((m) => m.$2 == v).$1,
                  colorOf: (v, cc) => cc.amber,
                  selected: _n2,
                  onSelect: (v) => setState(() => _n2 = v),
                ),
                const SizedBox(height: 12),
                Body(
                  'Light slows to c/n in a medium. Its frequency does not '
                  'change at the boundary, so the wavelength does — exactly as '
                  'happens to sound entering water.',
                  size: 13.5,
                ),
              ],
            ),
          ),

          Panel(
            margin: EdgeInsets.zero,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const PanelTitle('Model limits', icon: Icons.warning_amber),
                const Body(
                  'This is geometric optics: light as rays. It says nothing '
                  'about interference or diffraction, which need the wave '
                  'model in the interference module. Indices are quoted for '
                  'yellow light near 589 nm; real media bend blue light more '
                  'than red, which is why prisms make rainbows and this screen '
                  'does not.',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RayPainter extends CustomPainter {
  _RayPainter({
    required this.colors,
    required this.incidenceRad,
    required this.refractedRad,
    required this.n1,
    required this.n2,
  });

  final WaveColors colors;
  final double incidenceRad;
  final double? refractedRad;
  final double n1;
  final double n2;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final rr = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, w, h),
      const Radius.circular(18),
    );
    canvas.save();
    canvas.clipRRect(rr);

    final midY = h / 2;
    final cx = w / 2;
    final len = math.min(w, h) * 0.42;

    // media
    canvas.drawRect(
      Rect.fromLTWH(0, 0, w, midY),
      Paint()..color = colors.canvasTop,
    );
    canvas.drawRect(
      Rect.fromLTWH(0, midY, w, h - midY),
      Paint()..color = fade(colors.blue, n2 > n1 ? 0.22 : 0.10),
    );

    // boundary and normal
    canvas.drawLine(
      Offset(0, midY),
      Offset(w, midY),
      Paint()
        ..color = colors.textSecondary
        ..strokeWidth = 2,
    );
    final dash = Paint()
      ..color = fade(colors.textTertiary, 0.9)
      ..strokeWidth = 1.2;
    for (var y = 12.0; y < h - 12; y += 10) {
      canvas.drawLine(Offset(cx, y), Offset(cx, y + 5), dash);
    }

    Paint ray(Color col) => Paint()
      ..color = col
      ..strokeWidth = 2.8
      ..strokeCap = StrokeCap.round;

    // incident ray, arriving from the upper left
    final ix = cx - len * math.sin(incidenceRad);
    final iy = midY - len * math.cos(incidenceRad);
    canvas.drawLine(Offset(ix, iy), Offset(cx, midY), ray(colors.accent));
    _arrow(canvas, Offset(ix, iy), Offset(cx, midY), colors.accent);

    // reflected ray
    final rx = cx + len * math.sin(incidenceRad);
    final ry = midY - len * math.cos(incidenceRad);
    canvas.drawLine(
      Offset(cx, midY),
      Offset(rx, ry),
      ray(fade(colors.blue, refractedRad == null ? 1.0 : 0.45)),
    );

    // refracted ray, or nothing at all under TIR
    if (refractedRad != null) {
      final tx = cx + len * math.sin(refractedRad!);
      final ty = midY + len * math.cos(refractedRad!);
      canvas.drawLine(Offset(cx, midY), Offset(tx, ty), ray(colors.amber));
      _arrow(canvas, Offset(cx, midY), Offset(tx, ty), colors.amber);
      _label(canvas, 'refracted', Offset(tx + 6, ty), colors.amber);
    }

    _label(canvas, 'incident', Offset(ix - 56, iy), colors.accent);
    _label(canvas, 'reflected', Offset(rx + 6, ry), colors.blue);
    _label(canvas, 'normal', Offset(cx + 6, 10), colors.textTertiary);
    _label(canvas, 'n1 = ${n1.toStringAsFixed(3)}', Offset(10, midY - 20),
        colors.textSecondary);
    _label(canvas, 'n2 = ${n2.toStringAsFixed(3)}', Offset(10, midY + 10),
        colors.textSecondary);

    canvas.restore();
  }

  void _arrow(Canvas canvas, Offset from, Offset to, Color color) {
    final dx = to.dx - from.dx;
    final dy = to.dy - from.dy;
    final len = math.sqrt(dx * dx + dy * dy);
    if (len < 1) return;
    final ux = dx / len;
    final uy = dy / len;
    final tip = Offset(from.dx + ux * len * 0.55, from.dy + uy * len * 0.55);
    const s = 7.0;
    final p = Path()
      ..moveTo(tip.dx, tip.dy)
      ..lineTo(tip.dx - ux * s + uy * s * 0.6, tip.dy - uy * s - ux * s * 0.6)
      ..lineTo(tip.dx - ux * s - uy * s * 0.6, tip.dy - uy * s + ux * s * 0.6)
      ..close();
    canvas.drawPath(p, Paint()..color = color);
  }

  void _label(Canvas canvas, String s, Offset at, Color color) {
    final tp = TextPainter(
      text: TextSpan(
        text: s,
        style: TextStyle(
          color: color,
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, at);
  }

  @override
  bool shouldRepaint(covariant _RayPainter old) =>
      old.incidenceRad != incidenceRad ||
      old.refractedRad != refractedRad ||
      old.n1 != n1 ||
      old.n2 != n2 ||
      old.colors != colors;
}
