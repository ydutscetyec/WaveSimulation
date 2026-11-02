import 'dart:math' as math;

/// Diffraction of a plane wave at an aperture or an obstacle.
///
/// Two models live here and they are deliberately separate:
///
///  * [huygensField] is the honest one. Every open point of the barrier is a
///    secondary source and the field anywhere is the sum of their
///    contributions. It is valid in the near field, it produces the bending
///    around an obstacle, and it needs no small-angle assumption.
///
///  * [singleSlitIntensity] is the closed-form far-field (Fraunhofer) result.
///    It is used for the graph, for the minima markers and for the tests,
///    because it gives an exact value to check the numerical sum against.
///
/// SI units throughout. Angles in radians, measured from the forward normal.
class DiffractionPhysics {
  const DiffractionPhysics._();

  /// Secondary sources per wavelength of open aperture.
  ///
  /// Huygens' construction is exact only in the limit of a continuous
  /// wavefront. Sampling it coarsely creates a grating, not a slit: discrete
  /// sources spaced further apart than about lambda/2 produce spurious orders.
  /// Eight per wavelength keeps the sampling error well below the line width
  /// on screen without making the sum needlessly expensive.
  static const int samplesPerWavelength = 8;

  /// Number of secondary sources to use across an opening of [widthM].
  /// Clamped so a very wide slit at a short wavelength stays affordable.
  static int sourceCount(double widthM, double wavelengthM) {
    if (widthM <= 0 || wavelengthM <= 0) return 1;
    final n = (samplesPerWavelength * widthM / wavelengthM).ceil();
    return n.clamp(3, 220);
  }

  /// Positions of the secondary sources along the barrier, in metres,
  /// measured from the axis. An aperture is a single open band centred on
  /// zero; an obstacle is the complement, two open bands either side.
  ///
  /// [barrierSpanM] is the full height of the barrier that the incoming plane
  /// wave illuminates, needed only for the obstacle case.
  static List<double> sourcePositions({
    required double openingM,
    required double wavelengthM,
    bool obstacle = false,
    double barrierSpanM = 1.0,
  }) {
    final out = <double>[];
    if (wavelengthM <= 0) return out;

    if (!obstacle) {
      final n = sourceCount(openingM, wavelengthM);
      if (n == 1) return [0];
      final step = openingM / (n - 1);
      for (var i = 0; i < n; i++) {
        out.add(-openingM / 2 + i * step);
      }
      return out;
    }

    // Obstacle of width [openingM] centred on the axis: the wave gets through
    // everywhere EXCEPT there. The light that bends into the geometric shadow
    // behind it is the whole point of the demonstration.
    final openEach = (barrierSpanM - openingM) / 2;
    if (openEach <= 0) return out;
    final n = sourceCount(openEach, wavelengthM);
    final step = openEach / math.max(1, n - 1);
    for (var i = 0; i < n; i++) {
      final offset = openingM / 2 + i * step;
      out..add(offset)..add(-offset);
    }
    return out;
  }

  /// Steady-state complex amplitude at (x, y) from a set of secondary sources
  /// sitting on the barrier plane at x = 0.
  ///
  /// Returns [real, imag] of the phasor sum of
  ///
  ///   A_i = e^(i k r) / sqrt(r)
  ///
  /// The 1/sqrt(r) is cylindrical spreading, correct for the line sources of a
  /// 2D ripple tank. Using 1/r here (spherical) would make the pattern fade
  /// too fast and is the usual mistake.
  ///
  /// Splitting the time-independent phasor out like this is what makes the
  /// animation affordable: the expensive sum runs once when a parameter
  /// changes, and each frame only needs
  ///
  ///   y(x,y,t) = real*cos(wt) + imag*sin(wt)
  static List<double> huygensPhasor({
    required double x,
    required double y,
    required List<double> sourceYs,
    required double waveNumberK,
  }) {
    var re = 0.0;
    var im = 0.0;
    for (var i = 0; i < sourceYs.length; i++) {
      final dy = y - sourceYs[i];
      final r = math.sqrt(x * x + dy * dy);
      if (r < 1e-6) continue;
      final amp = 1 / math.sqrt(r);
      final ph = waveNumberK * r;
      re += amp * math.cos(ph);
      im += amp * math.sin(ph);
    }
    return [re, im];
  }

  /// Instantaneous displacement from a phasor produced by [huygensPhasor].
  static double fieldFromPhasor(double re, double im, double phase) =>
      re * math.cos(phase) + im * math.sin(phase);

  /// |A|^2, the time-averaged intensity. Does not animate, which is why the
  /// intensity view can be rendered once per parameter change.
  static double intensityFromPhasor(double re, double im) => re * re + im * im;

  /// Fraunhofer single-slit intensity, normalised to 1 on the axis:
  ///
  ///   I(theta)/I0 = ( sin(beta) / beta )^2,   beta = pi a sin(theta) / lambda
  ///
  /// a = slit width, theta measured from the forward normal.
  static double singleSlitIntensity({
    required double thetaRad,
    required double wavelengthM,
    required double slitWidthM,
  }) {
    if (wavelengthM <= 0 || slitWidthM <= 0) return 0;
    final beta = math.pi * slitWidthM * math.sin(thetaRad) / wavelengthM;
    if (beta.abs() < 1e-9) return 1; // limit of (sin b / b)^2 as b -> 0
    final s = math.sin(beta) / beta;
    return s * s;
  }

  /// Angle of the m-th intensity minimum: sin(theta) = m * lambda / a.
  ///
  /// Returns null when no such minimum exists. That happens whenever
  /// m*lambda > a, and for m = 1 it is the physically important case: an
  /// opening narrower than one wavelength has NO minimum at all, so the
  /// transmitted wave spreads into a single smooth lobe filling the whole
  /// half-space. This is the behaviour the module has to show.
  static double? minimumAngle({
    required int order,
    required double wavelengthM,
    required double slitWidthM,
  }) {
    if (order < 1 || slitWidthM <= 0 || wavelengthM <= 0) return null;
    final s = order * wavelengthM / slitWidthM;
    if (s > 1) return null;
    return math.asin(s);
  }

  /// Half-width of the central maximum, in radians. Null when the opening is
  /// narrower than a wavelength and the lobe is unbounded.
  static double? centralLobeHalfAngle({
    required double wavelengthM,
    required double slitWidthM,
  }) =>
      minimumAngle(order: 1, wavelengthM: wavelengthM, slitWidthM: slitWidthM);

  /// lambda / a. The only number that decides how much a slit spreads a wave.
  ///
  ///   << 1  the wave carries on as a beam, edges barely disturbed
  ///   ~ 1   strong spreading, one broad lobe
  ///   > 1   the opening behaves as a single point source
  static double spreadRatio(double wavelengthM, double slitWidthM) {
    if (slitWidthM <= 0) return double.infinity;
    return wavelengthM / slitWidthM;
  }

  /// Plain-language verdict for the readout, driven by the ratio above so the
  /// label can never disagree with the picture.
  static String spreadLabel(double wavelengthM, double slitWidthM) {
    final r = spreadRatio(wavelengthM, slitWidthM);
    if (r >= 1) return 'POINT SOURCE';
    if (r >= 0.5) return 'STRONG';
    if (r >= 0.2) return 'CLEAR';
    if (r >= 0.05) return 'SLIGHT';
    return 'NEGLIGIBLE';
  }
}
