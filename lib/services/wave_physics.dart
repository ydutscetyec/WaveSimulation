import 'dart:math' as math;

/// Every physical relationship in the app lives here.
/// Nothing in the UI layer is allowed to hard-code a wavelength, a delay or a
/// resonant frequency - it must call one of these.
///
/// SI units throughout:
///   f  [Hz]      frequency
///   v  [m/s]     wave speed in the medium
///   lambda [m]   wavelength
///   A  [m]       displacement amplitude
///   t  [s]       time
///   x  [m]       position along the propagation axis
class WavePhysics {
  const WavePhysics._();

  /// v = f * lambda   ->   lambda = v / f
  static double wavelength(double speedMs, double frequencyHz) {
    if (frequencyHz <= 0) return double.infinity;
    return speedMs / frequencyHz;
  }

  /// f = v / lambda
  static double frequencyFor(double speedMs, double wavelengthM) {
    if (wavelengthM <= 0) return double.infinity;
    return speedMs / wavelengthM;
  }

  /// Angular frequency, omega = 2*pi*f  [rad/s]
  static double omega(double frequencyHz) => 2 * math.pi * frequencyHz;

  /// Wave number, k = 2*pi/lambda  [rad/m]
  static double waveNumber(double wavelengthM) {
    if (wavelengthM <= 0) return double.infinity;
    return 2 * math.pi / wavelengthM;
  }

  /// Period, T = 1/f  [s]
  static double period(double frequencyHz) =>
      frequencyHz <= 0 ? double.infinity : 1 / frequencyHz;

  /// Particle displacement for a travelling sinusoidal wave:
  ///   s(x,t) = A sin(kx - omega*t + phi)
  /// For a longitudinal wave this displacement is PARALLEL to x.
  static double displacement({
    required double amplitude,
    required double waveNumberK,
    required double x,
    required double phase,
  }) =>
      amplitude * math.sin(waveNumberK * x - phase);

  /// Local strain, -ds/dx = A*k*cos(kx - phase).
  /// Positive value = particles crowding together = COMPRESSION.
  /// Negative value = particles spreading apart  = RAREFACTION.
  /// This is why compression is drawn from the derivative and not faked.
  static double strain({
    required double amplitude,
    required double waveNumberK,
    required double x,
    required double phase,
  }) =>
      amplitude * waveNumberK * math.cos(waveNumberK * x - phase);

  /// Largest displacement amplitude that still keeps |strain| < 1, i.e. the
  /// point at which neighbouring particles would overtake each other.
  /// A*k = 1 is the physical ceiling; 0.9 keeps a margin.
  static double maxPhysicalAmplitude(double waveNumberK) =>
      waveNumberK <= 0 ? 0 : 0.9 / waveNumberK;

  /// Echo delay for a reflector at distance d:  t = 2d / v
  static double echoDelay(double distanceM, double speedMs) {
    if (speedMs <= 0) return double.infinity;
    return 2 * distanceM / speedMs;
  }

  /// Minimum distance for a human to resolve an echo as a separate sound
  /// (~0.1 s separation is the usual classroom figure).
  static double minEchoDistance(double speedMs) => 0.1 * speedMs / 2;

  /// Acoustic impedance, Z = rho * v  [rayl = kg/(m^2 s)]
  static double impedance(double densityKgM3, double speedMs) =>
      densityKgM3 * speedMs;

  /// Pressure reflection coefficient at a boundary between two media:
  ///   R = (Z2 - Z1) / (Z2 + Z1)
  static double pressureReflection(double z1, double z2) {
    if (z1 + z2 == 0) return 0;
    return (z2 - z1) / (z2 + z1);
  }

  /// Amplitude actually sent back by a surface with absorption coefficient
  /// alpha (energy fraction absorbed). Energy ratio (1-alpha) -> amplitude
  /// ratio sqrt(1-alpha).
  static double reflectedAmplitudeRatio(double alpha) =>
      math.sqrt((1 - alpha).clamp(0.0, 1.0));

  /// Resonant frequencies of a pipe closed at one end (a cup, a bottle):
  ///   f_n = (2n-1) v / (4L),  n = 1,2,3...  (odd harmonics only)
  static double closedPipeResonance(double speedMs, double lengthM, int n) {
    if (lengthM <= 0) return double.infinity;
    return (2 * n - 1) * speedMs / (4 * lengthM);
  }

  /// Resonant frequencies of a pipe open at both ends:
  ///   f_n = n v / (2L)
  static double openPipeResonance(double speedMs, double lengthM, int n) {
    if (lengthM <= 0) return double.infinity;
    return n * speedMs / (2 * lengthM);
  }

  /// Normalised steady-state response of a driven damped oscillator:
  ///
  ///   A(f) / A_max = 1 / ( Q * sqrt( (1-r^2)^2 + (r/Q)^2 ) ),  r = f/f0
  ///
  /// Returns ~1.0 exactly at resonance and falls away on both sides, so the
  /// "RESONANCE!" state is produced by the physics, not by a colour change.
  static double resonanceResponse(double f, double f0, double q) {
    if (f0 <= 0 || q <= 0) return 0;
    final r = f / f0;
    final denom = math.sqrt(
      math.pow(1 - r * r, 2).toDouble() + math.pow(r / q, 2).toDouble(),
    );
    if (denom == 0) return 1;
    return (1 / (q * denom)).clamp(0.0, 1.0);
  }

  /// Standing wave from two identical waves travelling in opposite directions:
  ///   y1 = A sin(kx - wt),  y2 = A sin(kx + wt)
  ///   y1 + y2 = 2A sin(kx) cos(wt)
  /// The envelope 2A*sin(kx) is fixed in space -> nodes and antinodes.
  static double standingWave({
    required double amplitude,
    required double waveNumberK,
    required double x,
    required double phase,
  }) =>
      2 * amplitude * math.sin(waveNumberK * x) * math.cos(phase);

  /// Node positions of a standing wave: x = n * lambda / 2
  static List<double> nodePositions(double wavelengthM, double spanM) {
    final out = <double>[];
    if (wavelengthM <= 0) return out;
    for (double x = 0; x <= spanM; x += wavelengthM / 2) {
      out.add(x);
    }
    return out;
  }

  /// Resultant amplitude where two coherent sources overlap.
  ///   A_r = sqrt(A1^2 + A2^2 + 2*A1*A2*cos(delta))
  ///   delta = k*(r2 - r1) - phaseOffset
  /// delta = 0, 2pi...  -> constructive
  /// delta = pi, 3pi... -> destructive
  static double interferenceAmplitude({
    required double a1,
    required double a2,
    required double waveNumberK,
    required double r1,
    required double r2,
    required double phaseOffset,
  }) {
    final delta = waveNumberK * (r2 - r1) - phaseOffset;
    final sq = a1 * a1 + a2 * a2 + 2 * a1 * a2 * math.cos(delta);
    return math.sqrt(math.max(0, sq));
  }

  /// Path difference in wavelengths - the number students actually check.
  static double pathDifferenceInWavelengths(
    double r1,
    double r2,
    double wavelengthM,
  ) {
    if (wavelengthM <= 0) return 0;
    return (r2 - r1).abs() / wavelengthM;
  }

  /// Geometric spreading of amplitude from a point source, with a floor so the
  /// value does not blow up at r -> 0.
  static double spread(double r, {double rMin = 0.25}) =>
      1 / math.max(r, rMin);

  /// Sound pressure level relative to a reference amplitude.
  ///   L = 20 log10(A/A_ref)  [dB]
  static double relativeDb(double amplitude, {double reference = 1.0}) {
    if (amplitude <= 0 || reference <= 0) return -120;
    return 20 * (math.log(amplitude / reference) / math.ln10);
  }

  /// Human pitch band label.
  static String pitchLabel(double f) {
    if (f < 120) return 'LOW';
    if (f < 700) return 'MEDIUM';
    return 'HIGH';
  }

  /// Slow-motion factor needed to make a real f Hz vibration visible at an
  /// apparent fApparent Hz on screen. 440 Hz shown at 1 Hz -> 1/440 real time.
  static double slowMotionFactor(double f, double fApparent) {
    if (fApparent <= 0) return 1;
    return f / fApparent;
  }
}
