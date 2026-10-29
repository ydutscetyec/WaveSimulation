import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../services/string_solver.dart';
import '../../theme/wave_theme.dart';
import '../../widgets/measure_tools.dart';
import '../../widgets/solver_host.dart';
import '../../widgets/ui_kit.dart';

/// The three drive modes PhET's Wave on a String offers, in its order.
/// Manual is the one that makes the simulation feel alive: you drag the end
/// of the string yourself and watch what you made travel away from you.
enum DriveMode { manual, oscillate, pulse }

/// Module 1 - Wave on a string.
///
/// Every displacement on screen comes from the finite-difference solver. The
/// reflection, the inversion at a fixed end and the damping are all emergent,
/// not drawn. Tension and mass density are the inputs; speed and wavelength
/// are computed and labelled as derived.
class StringWaveScreen extends StatefulWidget {
  const StringWaveScreen({super.key});

  @override
  State<StringWaveScreen> createState() => _StringWaveScreenState();
}

class _StringWaveScreenState extends State<StringWaveScreen> {
  final GlobalKey<SolverHostState> _hostKey = GlobalKey<SolverHostState>();
  late final StringSolver _solver = StringSolver(
    tension: 10,
    density: 0.1,
    damping: 0.1,
  );

  double _frequency = 1.0;
  double _amplitude = 0.2;
  double _playback = 1.0;
  DriveMode _mode = DriveMode.oscillate;
  bool _running = true;
  bool _showRuler = false;
  double _manualY = 0; // metres, set by dragging the left end
  double _pulseWidth = 1.0; // metres

  double get _speed => _solver.speed;
  double get _wavelength => _frequency <= 0 ? 0 : _speed / _frequency;
  double get _period => _frequency <= 0 ? 0 : 1 / _frequency;

  void _drive(StringSolver s) {
    if (_mode == DriveMode.oscillate) {
      s.driveSine(amplitude: _amplitude, frequency: _frequency);
    } else if (_mode == DriveMode.manual) {
      s.drive(_manualY);
    } else {
      s.drive(0);
    }
  }

  /// Manual drive: the vertical position of the finger becomes the
  /// displacement of the left end, in metres. Capped at the physical
  /// amplitude limit so a drag cannot push neighbouring points through each
  /// other.
  void _onDragStart(DragStartDetails d) => _setManual(d.localPosition);
  void _onDragUpdate(DragUpdateDetails d) => _setManual(d.localPosition);

  void _setManual(Offset local) {
    // The canvas maps +-0.6 m onto half its height, less 22 px of padding.
    // Same constants the painter uses, so the handle lands under the finger.
    final canvasH =
        (MediaQuery.of(context).size.height * 0.26).clamp(170.0, 280.0);
    final yScale = (canvasH / 2 - 22) / 0.6;
    final metres = ((canvasH / 2) - local.dy) / yScale;
    setState(() => _manualY = metres.clamp(-0.5, 0.5));
  }

  void _sendPulse() {
    setState(() => _mode = DriveMode.pulse);
    _solver.addPulse(
      centreM: math.max(1.2, _pulseWidth),
      widthM: _pulseWidth,
      amplitude: _amplitude,
    );
  }

  void _reset() {
    _hostKey.currentState?.reset();
    setState(() {
      _solver
        ..tension = 10
        ..density = 0.1
        ..damping = 0.1
        ..boundary = StringBoundary.fixed;
      _frequency = 1.0;
      _amplitude = 0.2;
      _playback = 1.0;
      _mode = DriveMode.oscillate;
      _manualY = 0;
      _running = true;
    });
  }

  void _preset({
    required double tension,
    required double density,
    required double frequency,
    required double amplitude,
    required double damping,
    required StringBoundary boundary,
  }) {
    _hostKey.currentState?.reset();
    setState(() {
      _solver
        ..tension = tension
        ..density = density
        ..damping = damping
        ..boundary = boundary;
      _frequency = frequency;
      _amplitude = amplitude;
      _mode = DriveMode.oscillate;
      _running = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final canvasH = (MediaQuery.of(context).size.height * 0.26)
        .clamp(170.0, 280.0);

    return LabScaffold(
      title: 'Wave on a string',
      subtitle: 'Solved, not animated',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: canvasH,
            width: double.infinity,
            child: RulerOverlay(
              enabled: _showRuler,
              metresAcross: _solver.length,
              // matches the 18 px padding the painter uses on each side
              insetFraction: 0.03,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onPanStart:
                    _mode == DriveMode.manual ? _onDragStart : null,
                onPanUpdate:
                    _mode == DriveMode.manual ? _onDragUpdate : null,
                onPanEnd: _mode == DriveMode.manual
                    ? (_) => setState(() => _manualY = 0)
                    : null,
                child: SolverHost(
                key: _hostKey,
                solver: _solver,
                running: _running,
                speed: _playback,
                onBeforeStep: _drive,
                builder: (context, repaint) => CustomPaint(
                  painter: _StringPainter(
                    repaint: repaint,
                    solver: _solver,
                    colors: c,
                    manualMode: _mode == DriveMode.manual,
                  ),
                ),
              ),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // transport
          Row(
            children: [
              Expanded(
                flex: 2,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(50),
                    backgroundColor:
                        _running ? fade(c.accent, 0.18) : c.accent,
                    foregroundColor: _running ? c.accent : c.onAccent,
                  ),
                  onPressed: () => setState(() => _running = !_running),
                  icon: Icon(_running ? Icons.pause : Icons.play_arrow),
                  label: Text(_running ? 'Pause' : 'Play'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(50),
                    foregroundColor: c.textPrimary,
                    side: BorderSide(color: c.stroke),
                  ),
                  onPressed: _running
                      ? null
                      : () => _hostKey.currentState?.stepOnce(),
                  child: const Icon(Icons.skip_next),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(50),
                    foregroundColor: c.textPrimary,
                    side: BorderSide(color: c.stroke),
                  ),
                  onPressed: _reset,
                  child: const Icon(Icons.restart_alt),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Body(
            _running
                ? 'Pause to enable single-step.'
                : 'Paused. Step advances one solver timestep '
                    '(${(_solver.dt * 1000).toStringAsFixed(2)} ms).',
            size: 13,
            color: c.textTertiary,
          ),
          const SizedBox(height: 14),

          // readouts
          Panel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: ValueCard(
                        label: 'Frequency (set)',
                        value: _frequency.toStringAsFixed(2),
                        unit: 'Hz',
                        compact: true,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ValueCard(
                        label: 'Speed (derived)',
                        value: _speed.toStringAsFixed(1),
                        unit: 'm/s',
                        color: c.amber,
                        compact: true,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ValueCard(
                        label: 'Wavelength (derived)',
                        value: _mode == DriveMode.oscillate
                            ? _wavelength.toStringAsFixed(2)
                            : '—',
                        unit: _mode == DriveMode.oscillate ? 'm' : null,
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
                        label: 'Period',
                        value: _period.toStringAsFixed(2),
                        unit: 's',
                        color: c.blue,
                        compact: true,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ValueCard(
                        label: 'Peak now',
                        value: _solver.peakDisplacement().toStringAsFixed(3),
                        unit: 'm',
                        color: c.blue,
                        compact: true,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ValueCard(
                        label: 'Courant',
                        value: _solver.courant.toStringAsFixed(2),
                        color: _solver.isStable ? c.textSecondary : c.red,
                        compact: true,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  'c = sqrt(T/mu) = sqrt(${_solver.tension.toStringAsFixed(0)}'
                  '/${_solver.density.toStringAsFixed(2)}) = '
                  '${_speed.toStringAsFixed(1)} m/s',
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: c.accent,
                  ),
                ),
                const SizedBox(height: 4),
                Body(
                  _mode == DriveMode.oscillate
                      ? 'Wavelength is computed from c / f. There is no '
                          'wavelength slider, because setting it independently '
                          'would contradict v = f lambda.'
                      : 'A single pulse has no single wavelength, so that '
                          'readout shows a dash rather than a made-up number.',
                  size: 13,
                  color: c.textTertiary,
                ),
              ],
            ),
          ),

          // drive
          Panel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const PanelTitle('Driver', icon: Icons.vibration),
                Segmented(
                  labels: const ['Manual', 'Oscillate', 'Pulse'],
                  selectedIndex: _mode.index,
                  onSelect: (i) {
                    if (i == 2) {
                      _sendPulse();
                    } else {
                      setState(() {
                        _mode = DriveMode.values[i];
                        if (_mode == DriveMode.manual) _manualY = 0;
                      });
                    }
                  },
                ),
                if (_mode == DriveMode.manual) ...[
                  const SizedBox(height: 10),
                  Tip(
                    'Drag the amber handle on the left end of the string up '
                    'and down. Whatever shape you make travels away from you. '
                    'Shake it quickly for a short wavelength, slowly for a '
                    'long one.',
                    icon: Icons.touch_app,
                    color: c.amber,
                  ),
                ],
                const SizedBox(height: 12),
                StepSlider(
                  label: 'Frequency',
                  value: _frequency,
                  min: 0.2,
                  max: 5,
                  step: 0.1,
                  readout: '${_frequency.toStringAsFixed(1)} Hz',
                  onChanged: (v) => setState(() => _frequency = v),
                ),
                StepSlider(
                  label: 'Amplitude',
                  value: _amplitude,
                  min: 0,
                  max: 0.5,
                  step: 0.02,
                  color: c.blue,
                  readout: '${_amplitude.toStringAsFixed(2)} m',
                  onChanged: (v) => setState(() => _amplitude = v),
                ),
                if (_mode == DriveMode.pulse) ...[
                  const SizedBox(height: 10),
                  StepSlider(
                    label: 'Pulse width',
                    value: _pulseWidth,
                    min: 0.3,
                    max: 3.0,
                    step: 0.1,
                    color: c.amber,
                    readout: '${_pulseWidth.toStringAsFixed(1)} m',
                    onChanged: (v) => setState(() => _pulseWidth = v),
                  ),
                  const SizedBox(height: 6),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                      foregroundColor: c.amber,
                      side: BorderSide(color: c.amber),
                    ),
                    onPressed: _sendPulse,
                    icon: const Icon(Icons.send),
                    label: const Text('Send another pulse'),
                  ),
                ],
              ],
            ),
          ),

          // string properties
          Panel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const PanelTitle('String', icon: Icons.tune),
                StepSlider(
                  label: 'Tension',
                  value: _solver.tension,
                  min: 1,
                  max: 100,
                  step: 1,
                  readout: '${_solver.tension.toStringAsFixed(0)} N',
                  onChanged: (v) => setState(() => _solver.tension = v),
                ),
                StepSlider(
                  label: 'Mass per metre',
                  value: _solver.density,
                  min: 0.01,
                  max: 1.0,
                  step: 0.01,
                  color: c.blue,
                  readout: '${_solver.density.toStringAsFixed(2)} kg/m',
                  onChanged: (v) => setState(() => _solver.density = v),
                ),
                StepSlider(
                  label: 'Damping',
                  value: _solver.damping,
                  min: 0,
                  max: 2,
                  step: 0.1,
                  color: c.amber,
                  readout: _solver.damping.toStringAsFixed(1),
                  onChanged: (v) => setState(() => _solver.damping = v),
                ),
                const SizedBox(height: 12),
                const PanelTitle('Far end', icon: Icons.vertical_align_center),
                Segmented(
                  labels: const ['Fixed', 'Loose', 'Absorbing'],
                  selectedIndex: _solver.boundary.index,
                  onSelect: (i) => setState(
                      () => _solver.boundary = StringBoundary.values[i]),
                ),
                const SizedBox(height: 10),
                Body(
                  _solver.boundary == StringBoundary.fixed
                      ? 'A crest comes back as a trough. The inversion is not '
                          'drawn in; it falls out of y = 0 at the end.'
                      : _solver.boundary == StringBoundary.loose
                          ? 'A crest comes back as a crest, because the end is '
                              'free to move.'
                          : 'The wave leaves and nothing returns.',
                  size: 13.5,
                  color: c.textTertiary,
                ),
              ],
            ),
          ),

          // playback speed, kept separate from frequency
          Panel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const PanelTitle('Playback speed', icon: Icons.slow_motion_video),
                StepSlider(
                  label: 'Simulated seconds per real second',
                  value: _playback,
                  min: 0.1,
                  max: 2,
                  step: 0.1,
                  color: c.textSecondary,
                  readout: '${_playback.toStringAsFixed(1)}x',
                  onChanged: (v) => setState(() => _playback = v),
                ),
                Body(
                  'This changes how fast you watch, never what the string '
                  'does. The frequency readout above stays where you set it.',
                  size: 13,
                  color: c.textTertiary,
                ),
              ],
            ),
          ),

          // measurement
          Panel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                PanelTitle(
                  'Measure it yourself',
                  icon: Icons.straighten,
                  trailing: Switch(
                    value: _showRuler,
                    activeThumbColor: c.amber,
                    onChanged: (v) => setState(() => _showRuler = v),
                  ),
                ),
                Body(
                  'Turn on the ruler and drag its two handles onto successive '
                  'crests. That distance is the wavelength. Compare it with '
                  'the derived readout above - they should agree.',
                  size: 13.5,
                ),
                const SizedBox(height: 12),
                LabTimer(
                  hint: 'Send a pulse, start the timer as it leaves, stop it '
                      'as it reaches the far end. The string is '
                      '${_solver.length.toStringAsFixed(0)} m, so '
                      'v = ${_solver.length.toStringAsFixed(0)} / t. Check it '
                      'against sqrt(T/mu). Remember the playback slider '
                      'changes your measured time but not the real speed.',
                ),
              ],
            ),
          ),

          // presets
          Panel(
            margin: EdgeInsets.zero,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const PanelTitle('Presets', icon: Icons.bookmark_outline),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _PresetChip(
                      label: 'Default',
                      onTap: () => _preset(
                        tension: 10,
                        density: 0.1,
                        frequency: 1,
                        amplitude: 0.2,
                        damping: 0.1,
                        boundary: StringBoundary.fixed,
                      ),
                    ),
                    _PresetChip(
                      label: 'High tension',
                      onTap: () => _preset(
                        tension: 40,
                        density: 0.1,
                        frequency: 1,
                        amplitude: 0.2,
                        damping: 0.1,
                        boundary: StringBoundary.fixed,
                      ),
                    ),
                    _PresetChip(
                      label: 'Heavy string',
                      onTap: () => _preset(
                        tension: 10,
                        density: 0.4,
                        frequency: 1,
                        amplitude: 0.2,
                        damping: 0.1,
                        boundary: StringBoundary.fixed,
                      ),
                    ),
                    _PresetChip(
                      label: 'Short wavelength',
                      onTap: () => _preset(
                        tension: 10,
                        density: 0.1,
                        frequency: 4,
                        amplitude: 0.15,
                        damping: 0.1,
                        boundary: StringBoundary.fixed,
                      ),
                    ),
                    _PresetChip(
                      label: 'Standing wave',
                      onTap: () => _preset(
                        tension: 10,
                        density: 0.1,
                        frequency: 1,
                        amplitude: 0.2,
                        damping: 0,
                        boundary: StringBoundary.fixed,
                      ),
                    ),
                    _PresetChip(
                      label: 'No reflection',
                      onTap: () => _preset(
                        tension: 10,
                        density: 0.1,
                        frequency: 1,
                        amplitude: 0.2,
                        damping: 0,
                        boundary: StringBoundary.absorbing,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PresetChip extends StatelessWidget {
  const _PresetChip({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Material(
      color: c.surfaceAlt,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: c.stroke),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.w600,
              color: c.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}

class _StringPainter extends CustomPainter {
  _StringPainter({
    required this.repaint,
    required this.solver,
    required this.colors,
    required this.manualMode,
  }) : super(repaint: repaint);

  final SolverTicker repaint;
  final StringSolver solver;
  final WaveColors colors;
  final bool manualMode;

  static const double _maxDisplay = 0.6; // metres mapped to half the height

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

    const pad = 18.0;
    final mid = h / 2;
    final usable = w - pad * 2;
    final yScale = (h / 2 - 22) / _maxDisplay;

    // equilibrium
    canvas.drawLine(
      Offset(pad, mid),
      Offset(w - pad, mid),
      Paint()
        ..color = fade(colors.stroke, 0.9)
        ..strokeWidth = 1,
    );

    // the string itself, straight from the solver arrays
    // A faint line through the beads, so the shape reads at a glance.
    final path = Path();
    final n = solver.points;
    for (var i = 0; i < n; i++) {
      final x = pad + (i / (n - 1)) * usable;
      final y = mid - solver.yAt(i) * yScale;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = fade(colors.accent, 0.45)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..strokeJoin = StrokeJoin.round,
    );

    // The string as beads. Discrete beads are what let a student answer the
    // question that matters: do the beads travel with the wave, or does only
    // the disturbance travel? A continuous line hides it.
    const beadCount = 64;
    final beadPaint = Paint()..color = colors.accent;
    final markIndex = (beadCount * 0.55).round();
    double markX = 0;
    double markY = mid;

    for (var b = 0; b <= beadCount; b++) {
      final f = b / beadCount;
      final i = (f * (n - 1)).round();
      final x = pad + f * usable;
      final y = mid - solver.yAt(i) * yScale;
      if (b == markIndex) {
        markX = x;
        markY = y;
        continue; // drawn last, on top
      }
      canvas.drawCircle(Offset(x, y), 3.2, beadPaint);
    }

    // One bead picked out, with the vertical track it is confined to. It
    // never moves sideways: the wave does.
    canvas.drawLine(
      Offset(markX, mid - 0.5 * yScale * 0.9),
      Offset(markX, mid + 0.5 * yScale * 0.9),
      Paint()
        ..color = fade(colors.amber, 0.30)
        ..strokeWidth = 1.2,
    );
    canvas.drawCircle(
      Offset(markX, mid),
      3,
      Paint()
        ..color = fade(colors.amber, 0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );
    canvas.drawCircle(Offset(markX, markY), 6.5, Paint()..color = colors.amber);
    _label(canvas, 'watch this bead', Offset(markX, markY + 11), colors.amber,
        centered: true);

    // The driven end: a grab handle in manual mode, a plain anchor otherwise.
    final driveY = mid - solver.yAt(0) * yScale;
    if (manualMode) {
      canvas.drawCircle(
        Offset(pad, driveY),
        16,
        Paint()..color = fade(colors.amber, 0.22),
      );
      canvas.drawCircle(
        Offset(pad, driveY),
        16,
        Paint()
          ..color = colors.amber
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
      _label(canvas, 'drag', Offset(pad, driveY - 30), colors.amber,
          centered: true);
    }
    canvas.drawCircle(Offset(pad, driveY), 7, Paint()..color = colors.amber);

    // far end marker
    final endPaint = Paint()
      ..color = solver.boundary == StringBoundary.absorbing
          ? fade(colors.textTertiary, 0.5)
          : colors.wall
      ..strokeWidth = 4;
    if (solver.boundary == StringBoundary.fixed) {
      canvas.drawLine(
        Offset(w - pad, mid - 26),
        Offset(w - pad, mid + 26),
        endPaint,
      );
    } else if (solver.boundary == StringBoundary.loose) {
      canvas.drawCircle(
        Offset(w - pad, mid - solver.yAt(solver.points - 1) * yScale),
        6,
        Paint()..color = colors.wall,
      );
    }

    _label(canvas, 'x = 0', Offset(pad, h - 20), colors.textTertiary);
    _label(
      canvas,
      '${solver.length.toStringAsFixed(0)} m',
      Offset(w - pad, h - 20),
      colors.textTertiary,
      rightAligned: true,
    );
    _label(
      canvas,
      't = ${solver.time.toStringAsFixed(2)} s',
      Offset(w / 2, 8),
      colors.textSecondary,
      centered: true,
    );
    canvas.restore();
  }

  void _label(
    Canvas canvas,
    String text,
    Offset at,
    Color color, {
    bool centered = false,
    bool rightAligned = false,
  }) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
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
  bool shouldRepaint(covariant _StringPainter old) =>
      old.colors != colors || old.manualMode != manualMode;
}
