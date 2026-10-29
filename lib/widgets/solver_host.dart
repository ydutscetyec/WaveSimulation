import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../services/string_solver.dart';

/// Repaint signal for solver-backed canvases. The solver arrays change every
/// step; this notifies painters without rebuilding any widgets.
class SolverTicker extends ChangeNotifier {
  void bump() => notifyListeners();
}

/// Owns a Ticker and advances a [StringSolver] in whole fixed steps.
///
/// The solver's dt is fixed. Frame time is not. Coupling them would make the
/// scheme unstable the moment the device stutters, so this accumulates real
/// elapsed time and runs as many whole steps as fit, keeping the remainder.
class SolverHost extends StatefulWidget {
  const SolverHost({
    super.key,
    required this.solver,
    required this.builder,
    this.running = true,
    this.speed = 1.0,
    this.onBeforeStep,
    this.maxStepsPerFrame = 400,
  });

  final StringSolver solver;

  /// Simulated seconds per real second. Playback speed only - it never
  /// touches the physical frequency.
  final double speed;

  final bool running;

  /// Called immediately before each solver step, so a continuous driver can
  /// set the boundary value at the correct simulated time rather than once
  /// per frame.
  final void Function(StringSolver solver)? onBeforeStep;

  final int maxStepsPerFrame;
  final Widget Function(BuildContext context, SolverTicker repaint) builder;

  @override
  State<SolverHost> createState() => SolverHostState();
}

class SolverHostState extends State<SolverHost>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  final SolverTicker repaint = SolverTicker();
  Duration _last = Duration.zero;
  double _accumulator = 0;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick)..start();
  }

  void _onTick(Duration elapsed) {
    var frame = (elapsed - _last).inMicroseconds / 1e6;
    _last = elapsed;
    if (!widget.running) return;
    // A huge first frame, or a return from the background, must not be
    // simulated in full.
    if (frame <= 0 || frame > 0.1) frame = 1 / 60;

    _accumulator += frame * widget.speed;
    final dt = widget.solver.dt;
    var steps = 0;
    while (_accumulator >= dt && steps < widget.maxStepsPerFrame) {
      widget.onBeforeStep?.call(widget.solver);
      widget.solver.step();
      _accumulator -= dt;
      steps++;
    }
    if (steps >= widget.maxStepsPerFrame) _accumulator = 0; // give up on catch-up
    if (steps > 0) repaint.bump();
  }

  /// Clears the string and the accumulator.
  void reset() {
    widget.solver.reset();
    _accumulator = 0;
    repaint.bump();
  }

  /// Runs exactly one step, for the step-through-time control.
  void stepOnce() {
    widget.onBeforeStep?.call(widget.solver);
    widget.solver.step();
    repaint.bump();
  }

  @override
  void dispose() {
    _ticker.dispose();
    repaint.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, repaint);
}
