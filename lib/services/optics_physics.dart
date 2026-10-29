import 'dart:math' as math;

/// Geometric optics. Angles are measured from the NORMAL, not the surface,
/// and are in radians internally. The UI converts for display.
///
/// Geometric optics and wave optics are kept apart on purpose: a ray diagram
/// is not a substitute for an interference model, and neither explains the
/// other.
class OpticsPhysics {
  const OpticsPhysics._();

  /// Common refractive indices at ~589 nm. Approximate teaching values.
  static const double nVacuum = 1.0;
  static const double nAir = 1.0003;
  static const double nWater = 1.333;
  static const double nGlass = 1.52;
  static const double nDiamond = 2.417;

  /// Snell's law: n1 sin(t1) = n2 sin(t2), solved for t2.
  ///
  /// Returns null when the ray cannot cross: total internal reflection, which
  /// happens only going from denser to rarer beyond the critical angle. A null
  /// is a physical result here, not an error, and the caller must draw the
  /// reflected ray instead of a refracted one.
  static double? refractionAngle({
    required double incidenceRad,
    required double n1,
    required double n2,
  }) {
    if (n1 <= 0 || n2 <= 0) return null;
    final s = n1 * math.sin(incidenceRad) / n2;
    if (s.abs() > 1) return null;
    return math.asin(s);
  }

  /// Critical angle, where refraction grazes the surface at 90 degrees:
  ///   sin(tc) = n2 / n1
  /// Exists only when n1 > n2.
  static double? criticalAngle({required double n1, required double n2}) {
    if (n1 <= n2 || n1 <= 0) return null;
    return math.asin(n2 / n1);
  }

  /// True when the ray is totally internally reflected.
  static bool isTotalInternalReflection({
    required double incidenceRad,
    required double n1,
    required double n2,
  }) {
    final tc = criticalAngle(n1: n1, n2: n2);
    return tc != null && incidenceRad.abs() >= tc;
  }

  /// Angle of reflection equals angle of incidence. Trivial, but having it
  /// named keeps the drawing code from hard-coding the relationship.
  static double reflectionAngle(double incidenceRad) => incidenceRad;

  /// Speed of light in a medium: v = c / n.
  static double speedInMedium(double n) => 299792458.0 / n;

  /// Wavelength in a medium. Frequency does not change when light crosses a
  /// boundary; the wavelength does. This is the optical twin of what happens
  /// to sound entering water, and worth showing side by side.
  static double wavelengthInMedium(double vacuumWavelength, double n) =>
      vacuumWavelength / n;

  /// Unpolarised Fresnel reflectance at the boundary, 0 to 1.
  /// Averages the s- and p-polarised coefficients. Returns 1.0 under total
  /// internal reflection.
  static double fresnelReflectance({
    required double incidenceRad,
    required double n1,
    required double n2,
  }) {
    final t2 = refractionAngle(incidenceRad: incidenceRad, n1: n1, n2: n2);
    if (t2 == null) return 1.0;
    final cos1 = math.cos(incidenceRad);
    final cos2 = math.cos(t2);
    final rs = math.pow((n1 * cos1 - n2 * cos2) / (n1 * cos1 + n2 * cos2), 2)
        .toDouble();
    final rp = math.pow((n1 * cos2 - n2 * cos1) / (n1 * cos2 + n2 * cos1), 2)
        .toDouble();
    return ((rs + rp) / 2).clamp(0.0, 1.0);
  }

  /// Thin lens equation: 1/f = 1/do + 1/di, solved for the image distance.
  /// Positive f is converging. Returns null when the object sits at the focal
  /// point, where the image goes to infinity.
  static double? imageDistance({
    required double objectDistance,
    required double focalLength,
  }) {
    final denom = objectDistance - focalLength;
    if (denom.abs() < 1e-9) return null;
    return objectDistance * focalLength / denom;
  }

  /// Magnification m = -di / do. Negative means inverted.
  static double? magnification({
    required double objectDistance,
    required double focalLength,
  }) {
    final di = imageDistance(
      objectDistance: objectDistance,
      focalLength: focalLength,
    );
    if (di == null || objectDistance == 0) return null;
    return -di / objectDistance;
  }

  /// True when the image is real (light actually converges there) rather than
  /// virtual (the rays only appear to come from it).
  static bool isRealImage({
    required double objectDistance,
    required double focalLength,
  }) {
    final di = imageDistance(
      objectDistance: objectDistance,
      focalLength: focalLength,
    );
    return di != null && di > 0;
  }

  static double degToRad(double deg) => deg * math.pi / 180;
  static double radToDeg(double rad) => rad * 180 / math.pi;
}
