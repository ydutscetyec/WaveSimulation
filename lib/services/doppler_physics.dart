import 'dart:math' as math;

/// What happens to the emitted sound at the current speeds.
enum DopplerRegime {
  /// Source slower than sound. Ordinary Doppler shift.
  subsonic,

  /// Source exactly at the speed of sound. Wavefronts pile up at the source
  /// and the simple formula divides by zero.
  sonic,

  /// Source faster than sound. A cone forms behind it and no sound reaches a
  /// listener ahead of the source until the cone arrives.
  supersonic,
}

/// Doppler effect for sound in a still medium.
///
/// SIGN CONVENTION, applied everywhere in this file and in the UI:
///
///   observerSpeed  positive when the observer moves TOWARDS the source
///   sourceSpeed    positive when the source moves TOWARDS the observer
///
///   f' = f (v + v_o) / (v - v_s)
///
/// Both motions raise the pitch when positive, which is the behaviour students
/// expect, and both lower it when negative. Mixing conventions is the most
/// common error in Doppler problems, so the sign is stated with every method
/// rather than assumed.
///
/// This is the sound case: the medium is at rest and the speeds are relative
/// to it. It is NOT the relativistic formula, which depends only on relative
/// velocity and must not be used here.
class DopplerPhysics {
  const DopplerPhysics._();

  static const double speedOfSoundAir = 343.0;

  /// Observed frequency, Hz.
  ///
  /// Returns null when the source reaches or exceeds the wave speed while
  /// moving towards the observer: the denominator hits zero or flips sign and
  /// the formula stops describing anything physical. The caller must show the
  /// shock-cone case instead of printing a number.
  static double? observedFrequency({
    required double emittedHz,
    required double waveSpeed,
    double sourceSpeed = 0,
    double observerSpeed = 0,
  }) {
    if (waveSpeed <= 0 || emittedHz <= 0) return null;
    final denom = waveSpeed - sourceSpeed;
    if (denom <= 1e-9) return null;
    final f = emittedHz * (waveSpeed + observerSpeed) / denom;
    return f.isFinite && f > 0 ? f : null;
  }

  /// Observed wavelength ahead of or behind a moving source:
  ///   lambda' = (v - v_s) / f
  /// Compressed in front, stretched behind. This is what the wavefront
  /// drawing must match - the circles are not spaced by eye.
  static double? observedWavelength({
    required double emittedHz,
    required double waveSpeed,
    double sourceSpeed = 0,
  }) {
    if (emittedHz <= 0) return null;
    final lambda = (waveSpeed - sourceSpeed) / emittedHz;
    return lambda > 0 ? lambda : null;
  }

  static DopplerRegime regime({
    required double waveSpeed,
    required double sourceSpeed,
  }) {
    final ratio = sourceSpeed.abs() / waveSpeed;
    if (ratio < 0.999) return DopplerRegime.subsonic;
    if (ratio <= 1.001) return DopplerRegime.sonic;
    return DopplerRegime.supersonic;
  }

  /// Mach number, the source speed in units of the wave speed.
  static double machNumber({
    required double waveSpeed,
    required double sourceSpeed,
  }) =>
      waveSpeed <= 0 ? 0 : sourceSpeed.abs() / waveSpeed;

  /// Half-angle of the shock cone, sin(a) = v / v_s = 1 / M.
  /// Only defined above Mach 1.
  static double? machConeHalfAngle({
    required double waveSpeed,
    required double sourceSpeed,
  }) {
    final m = machNumber(waveSpeed: waveSpeed, sourceSpeed: sourceSpeed);
    if (m <= 1) return null;
    return math.asin(1 / m);
  }

  /// Radius of the wavefront emitted [age] seconds ago, metres.
  /// Every front expands at the wave speed regardless of how the source moved
  /// after emitting it, which is the whole reason the circles bunch up.
  static double frontRadius({required double waveSpeed, required double age}) =>
      age <= 0 ? 0 : waveSpeed * age;

  /// Where the source was when it emitted that front, given constant velocity
  /// along one axis. The fronts stay centred on these points, not on the
  /// source's current position.
  static double frontCentre({
    required double sourcePositionNow,
    required double sourceVelocity,
    required double age,
  }) =>
      sourcePositionNow - sourceVelocity * age;

  /// Fractional pitch shift, for a readout that means something to a student
  /// who has not met the formula yet. +0.15 reads as "15 % higher".
  static double? pitchShiftFraction({
    required double emittedHz,
    required double waveSpeed,
    double sourceSpeed = 0,
    double observerSpeed = 0,
  }) {
    final f = observedFrequency(
      emittedHz: emittedHz,
      waveSpeed: waveSpeed,
      sourceSpeed: sourceSpeed,
      observerSpeed: observerSpeed,
    );
    if (f == null) return null;
    return (f - emittedHz) / emittedHz;
  }
}
