import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

/// Animation clock for the simulations.
///
/// Why this exists instead of an AnimationController:
///  * [phase] is INTEGRATED (phase += 2*pi*hz*dt) rather than computed from an
///    absolute time. Changing the rate mid-flight therefore does not make the
///    wave jump - the derivative changes, the position does not.
///  * It wraps at 2*pi so the value never grows large enough to lose float
///    precision during a long session.
///  * It is kept out of SimulationState on purpose. Only CustomPainters listen
///    to it, so the widget tree is not rebuilt 60 times a second.
class SimClock extends ChangeNotifier {
  double phase = 0; // radians, 0..2pi
  double seconds = 0; // simulated seconds since last reset
  double hz = 1.0; // apparent oscillation rate on screen
  double timeRate = 1.0; // simulated seconds per real second
  bool running = true;

  void advance(double dtSeconds) {
    if (!running || dtSeconds <= 0) return;
    phase = (phase + 2 * math.pi * hz * dtSeconds) % (2 * math.pi);
    seconds += dtSeconds * timeRate;
    notifyListeners();
  }

  void reset() {
    phase = 0;
    seconds = 0;
    notifyListeners();
  }
}

/// Owns the Ticker and feeds a [SimClock]. The builder runs once, not per
/// frame: pass the clock down to a CustomPainter via `super(repaint: clock)`.
class ClockHost extends StatefulWidget {
  const ClockHost({
    super.key,
    required this.builder,
    this.hz = 1.0,
    this.timeRate = 1.0,
    this.running = true,
    this.maxSeconds,
    this.onLimit,
  });

  final Widget Function(BuildContext context, SimClock clock) builder;
  final double hz;
  final double timeRate;
  final bool running;

  /// Optional stop point, used by the one-shot experiments (echo).
  final double? maxSeconds;
  final VoidCallback? onLimit;

  @override
  State<ClockHost> createState() => ClockHostState();
}

class ClockHostState extends State<ClockHost>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  final SimClock clock = SimClock();
  Duration _last = Duration.zero;
  bool _limitFired = false;

  @override
  void initState() {
    super.initState();
    clock
      ..hz = widget.hz
      ..timeRate = widget.timeRate
      ..running = widget.running;
    _ticker = createTicker(_onTick)..start();
  }

  void _onTick(Duration elapsed) {
    var dt = (elapsed - _last).inMicroseconds / 1e6;
    _last = elapsed;
    // Guard against a huge first frame or a resumed-from-background jump.
    if (dt <= 0 || dt > 0.1) dt = 1 / 60;
    clock.advance(dt);

    final limit = widget.maxSeconds;
    if (limit != null && !_limitFired && clock.seconds >= limit) {
      _limitFired = true;
      widget.onLimit?.call();
    }
  }

  void restart() {
    _limitFired = false;
    clock.reset();
  }

  @override
  void didUpdateWidget(covariant ClockHost oldWidget) {
    super.didUpdateWidget(oldWidget);
    clock
      ..hz = widget.hz
      ..timeRate = widget.timeRate
      ..running = widget.running;
    if (widget.maxSeconds != oldWidget.maxSeconds) _limitFired = false;
  }

  @override
  void dispose() {
    _ticker.dispose();
    clock.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, clock);
}
