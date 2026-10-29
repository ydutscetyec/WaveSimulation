import 'dart:math' as math;
import 'dart:typed_data';

/// Boundary condition at the far (right) end of the string.
enum StringBoundary {
  /// y = 0. A crest returns as a trough.
  fixed,

  /// dy/dx = 0. A crest returns as a crest.
  loose,

  /// One-way Mur condition. The wave leaves and nothing returns.
  absorbing,
}

/// Numerical solver for the damped wave equation on a string:
///
///   d2y/dt2 + gamma * dy/dt = c^2 * d2y/dx2,     c = sqrt(T / mu)
///
/// This REPLACES the old approach of animating y = A sin(kx - wt). A closed
/// form sine cannot reflect off a boundary, cannot superpose with its own
/// reflection, cannot carry a single pulse and cannot damp correctly. All four
/// are required behaviours, so the closed form is only used now to generate
/// expected values in the tests.
///
/// Explicit second-order finite difference, three state arrays rotated each
/// step:
///
///   y[i]^(n+1) = ( 2 y[i]^n - (1 - g) y[i]^(n-1)
///                  + C^2 ( y[i+1]^n - 2 y[i]^n + y[i-1]^n ) ) / (1 + g)
///
/// with g = gamma * dt and the Courant number C = c * dt / dx.
///
/// No Flutter imports. The solver knows nothing about rendering.
class StringSolver {
  StringSolver({
    this.length = 10.0,
    this.points = 400,
    this.maxSpeed = 100.0,
    double tension = 10.0,
    double density = 0.1,
    this.damping = 0.1,
    this.boundary = StringBoundary.fixed,
  })  : assert(points >= 16, 'too few grid points to resolve a wave'),
        assert(length > 0),
        assert(maxSpeed > 0),
        _tension = tension,
        _density = density {
    dx = length / (points - 1);
    // dt is fixed once, from the FASTEST wave the parameter ranges allow, so
    // that moving the tension or density sliders can never push the Courant
    // number above 1 and blow the solver up mid-run.
    dt = 0.9 * dx / maxSpeed;
    _prev = Float64List(points);
    _curr = Float64List(points);
    _next = Float64List(points);
  }

  /// Physical length of the string, metres.
  final double length;

  /// Number of grid points.
  final int points;

  /// Fastest wave speed the UI will ever request, m/s. Sets dt.
  final double maxSpeed;

  /// Grid spacing, metres.
  late final double dx;

  /// Fixed timestep, seconds. Never varies at runtime.
  late final double dt;

  double _tension;
  double _density;

  /// Velocity-proportional loss term, 1/s.
  double damping;

  StringBoundary boundary;

  late Float64List _prev;
  late Float64List _curr;
  late Float64List _next;

  double _time = 0;
  double _drive = 0;

  /// Simulated seconds since the last reset.
  double get time => _time;

  /// String tension, newtons. Named `tension`, never `T`, to keep it clearly
  /// distinct from the wave period.
  double get tension => _tension;
  set tension(double v) {
    _tension = v <= 0 ? 1e-6 : v;
  }

  /// Linear mass density, kg/m.
  double get density => _density;
  set density(double v) {
    _density = v <= 0 ? 1e-6 : v;
  }

  /// c = sqrt(T / mu), m/s. Derived, never set directly.
  double get speed => math.sqrt(_tension / _density);

  /// C = c * dt / dx. Must stay at or below 1 or the scheme is unstable.
  double get courant => speed * dt / dx;

  /// True when the current parameters are inside the stable region.
  bool get isStable => courant <= 1.0;

  /// Read-only view of the current displacement, metres.
  List<double> get displacement => _curr;

  /// Displacement at a grid index.
  double yAt(int i) => _curr[i.clamp(0, points - 1)];

  /// Displacement at a position in metres, linearly interpolated.
  double yAtMetres(double x) {
    final g = (x / dx).clamp(0.0, (points - 1).toDouble());
    final i = g.floor();
    if (i >= points - 1) return _curr[points - 1];
    final f = g - i;
    return _curr[i] * (1 - f) + _curr[i + 1] * f;
  }

  /// Sets the driven end for the next step, metres. The caller decides whether
  /// that is a continuous sine, a pulse or a finger drag.
  void drive(double y) => _drive = y;

  /// Continuous sinusoidal drive at the current simulated time.
  void driveSine({required double amplitude, required double frequency}) {
    _drive = amplitude * math.sin(2 * math.pi * frequency * _time);
  }

  /// Advances one fixed timestep.
  void step() {
    final c2 = courant * courant;
    final g = damping * dt;
    final last = points - 1;

    for (var i = 1; i < last; i++) {
      _next[i] = (2 * _curr[i] -
              (1 - g) * _prev[i] +
              c2 * (_curr[i + 1] - 2 * _curr[i] + _curr[i - 1])) /
          (1 + g);
    }

    _next[0] = _drive;

    // if/else rather than a switch: Dart 3 allows a switch without `break`,
    // but older analyzers do not, and this file must build on any 3.x.
    if (boundary == StringBoundary.fixed) {
      _next[last] = 0.0;
    } else if (boundary == StringBoundary.loose) {
      // dy/dx = 0 at the end
      _next[last] = _next[last - 1];
    } else {
      // First-order Mur: lets the wave leave instead of reflecting.
      final c = courant;
      _next[last] = _curr[last - 1] +
          ((c - 1) / (c + 1)) * (_next[last - 1] - _curr[last]);
    }

    final rotate = _prev;
    _prev = _curr;
    _curr = _next;
    _next = rotate;

    _time += dt;
  }

  /// Advances by a wall-clock interval using whole fixed steps.
  /// Returns the number of steps taken. The cap stops a backgrounded app from
  /// freezing on resume while it tries to catch up.
  int advance(double seconds, {int maxSteps = 400}) {
    if (seconds <= 0) return 0;
    var n = (seconds / dt).floor();
    if (n > maxSteps) n = maxSteps;
    for (var i = 0; i < n; i++) {
      step();
    }
    return n;
  }

  /// Injects a raised-cosine pulse centred at [centreM] of the given width.
  /// A square step is deliberately not offered: it carries frequencies the
  /// grid cannot resolve and shows up as visible ringing.
  void addPulse({
    required double centreM,
    required double widthM,
    required double amplitude,
  }) {
    for (var i = 0; i < points; i++) {
      final x = i * dx;
      final d = (x - centreM).abs();
      if (d < widthM / 2) {
        final bump = amplitude * 0.5 * (1 + math.cos(2 * math.pi * d / widthM));
        _curr[i] += bump;
        _prev[i] += bump; // starts at rest, so it splits both ways
      }
    }
  }

  /// Total energy, joules:
  ///   E = sum[ 0.5 mu (dy/dt)^2 + 0.5 T (dy/dx)^2 ] dx
  /// With damping 0 and no drive this should stay nearly constant. Drift is
  /// the fastest signal that the solver is broken.
  double energy() {
    var total = 0.0;
    for (var i = 0; i < points - 1; i++) {
      final vel = (_curr[i] - _prev[i]) / dt;
      final slope = (_curr[i + 1] - _curr[i]) / dx;
      total += 0.5 * _density * vel * vel + 0.5 * _tension * slope * slope;
    }
    return total * dx;
  }

  /// Largest absolute displacement on the string, metres.
  double peakDisplacement() {
    var peak = 0.0;
    for (var i = 0; i < points; i++) {
      final a = _curr[i].abs();
      if (a > peak) peak = a;
    }
    return peak;
  }

  /// Clears the string and the clock. Parameters are left alone.
  void reset() {
    _prev.fillRange(0, points, 0.0);
    _curr.fillRange(0, points, 0.0);
    _next.fillRange(0, points, 0.0);
    _time = 0;
    _drive = 0;
  }
}
