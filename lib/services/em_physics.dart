import 'dart:math' as math;

import 'package:flutter/painting.dart' show Color;

/// Electromagnetic waves and polarisation.
///
/// Kept apart from [WavePhysics] on purpose. An electromagnetic wave needs no
/// medium, travels at a fixed speed in vacuum and carries its energy in two
/// perpendicular fields rather than in the motion of matter. Sharing a class
/// with the acoustic model would blur exactly the distinction this module
/// exists to teach.
class EmPhysics {
  const EmPhysics._();

  /// Speed of light in vacuum, m/s. Exact by definition of the metre.
  static const double c = 299792458.0;

  /// Planck constant, J s. Exact since the 2019 SI redefinition.
  static const double planckJs = 6.62607015e-34;

  /// Elementary charge, C. Exact, and the conversion factor to electronvolts.
  static const double electronVoltJ = 1.602176634e-19;

  /// f = c / lambda
  static double frequencyFor(double wavelengthM) {
    if (wavelengthM <= 0) return double.infinity;
    return c / wavelengthM;
  }

  /// lambda = c / f
  static double wavelengthFor(double frequencyHz) {
    if (frequencyHz <= 0) return double.infinity;
    return c / frequencyHz;
  }

  /// E = h f  [J]
  static double photonEnergyJ(double frequencyHz) => planckJs * frequencyHz;

  /// E = h f / e  [eV]. The unit the spectrum is normally discussed in.
  static double photonEnergyEv(double frequencyHz) =>
      photonEnergyJ(frequencyHz) / electronVoltJ;

  /// Wave speed in a transparent medium of refractive index n: v = c / n.
  /// Frequency is unchanged, so the wavelength shortens by the same factor.
  static double speedInMedium(double n) => n <= 0 ? c : c / n;

  // ---------------------------------------------------------------------
  // Polarisation
  // ---------------------------------------------------------------------

  /// Malus's law: I = I0 cos^2(theta), theta between the incoming
  /// polarisation axis and the polariser's transmission axis.
  ///
  /// It applies to light that is ALREADY polarised. Unpolarised light hitting
  /// a first polariser follows [unpolarisedThroughFirst] instead - a very
  /// common slip, and the reason the two are separate methods here.
  static double malus(double incidentIntensity, double thetaRad) {
    final c2 = math.cos(thetaRad);
    return incidentIntensity * c2 * c2;
  }

  /// Unpolarised light through its first polariser always loses exactly half
  /// its intensity, whatever the polariser angle, because the incoming
  /// polarisation directions are uniformly distributed and the average of
  /// cos^2 over all angles is 1/2. Rotating a single polariser in unpolarised
  /// light therefore changes nothing you can see.
  static double unpolarisedThroughFirst(double incidentIntensity) =>
      incidentIntensity * 0.5;

  /// Intensity after a stack of polarisers whose transmission axes are at
  /// [axesRad], for unpolarised light of intensity [i0].
  ///
  /// Half at the first, then Malus between each neighbouring pair. This is the
  /// model behind the three-polariser result: crossed polarisers pass nothing,
  /// yet inserting a third at 45 degrees BETWEEN them lets light through,
  /// because each stage only ever sees the angle to its immediate predecessor.
  static double throughStack(double i0, List<double> axesRad) {
    if (axesRad.isEmpty) return i0;
    var intensity = unpolarisedThroughFirst(i0);
    for (var i = 1; i < axesRad.length; i++) {
      intensity = malus(intensity, axesRad[i] - axesRad[i - 1]);
    }
    return intensity;
  }

  /// Amplitude ratio for a field component, cos(theta).
  ///
  /// Intensity goes as the square of this. Showing the amplitude projection
  /// alongside the intensity is what makes the cos^2 stop looking arbitrary:
  /// the polariser passes the component of E along its axis, and intensity is
  /// proportional to E^2.
  static double amplitudeProjection(double thetaRad) => math.cos(thetaRad);
}

/// A named region of the electromagnetic spectrum.
///
/// Boundaries between bands are conventions, not physics - the spectrum is
/// continuous and the published edges differ between sources. The values here
/// are the usual teaching figures.
class EmBand {
  const EmBand({
    required this.name,
    required this.shortName,
    required this.minWavelengthM,
    required this.maxWavelengthM,
    required this.color,
    required this.note,
  });

  final String name;
  final String shortName;
  final double minWavelengthM;
  final double maxWavelengthM;

  /// Display colour. Only the visible band's colour is physical; the rest are
  /// labels, and the UI says so.
  final Color color;

  /// One line on what it is used for or where it is met.
  final String note;

  /// Geometric mean of the band edges - the representative wavelength to jump
  /// to when the band is selected. Geometric rather than arithmetic because
  /// the bands span decades.
  double get centreWavelengthM =>
      math.sqrt(minWavelengthM * maxWavelengthM);

  bool contains(double wavelengthM) =>
      wavelengthM >= minWavelengthM && wavelengthM < maxWavelengthM;

  static const EmBand radio = EmBand(
    name: 'Radio waves',
    shortName: 'Radio',
    minWavelengthM: 1e-1,
    maxWavelengthM: 1e5,
    color: Color(0xFFE05A5A),
    note: 'Broadcast, mobile networks, Wi-Fi. Pass through walls easily.',
  );

  static const EmBand microwave = EmBand(
    name: 'Microwaves',
    shortName: 'Micro',
    minWavelengthM: 1e-3,
    maxWavelengthM: 1e-1,
    color: Color(0xFFE09A4A),
    note: 'Radar, satellite links, and heating water in food.',
  );

  static const EmBand infrared = EmBand(
    name: 'Infrared',
    shortName: 'IR',
    minWavelengthM: 7e-7,
    maxWavelengthM: 1e-3,
    color: Color(0xFFD4604A),
    note: 'Radiated heat, remote controls, thermal cameras.',
  );

  static const EmBand visible = EmBand(
    name: 'Visible light',
    shortName: 'Visible',
    minWavelengthM: 3.8e-7,
    maxWavelengthM: 7e-7,
    color: Color(0xFF5ACF7A),
    note: 'The narrow band the eye detects, 380 nm to 700 nm.',
  );

  static const EmBand ultraviolet = EmBand(
    name: 'Ultraviolet',
    shortName: 'UV',
    minWavelengthM: 1e-8,
    maxWavelengthM: 3.8e-7,
    color: Color(0xFF8B6FE0),
    note: 'Sunburn and fluorescence. Mostly blocked by the ozone layer.',
  );

  static const EmBand xray = EmBand(
    name: 'X-rays',
    shortName: 'X-ray',
    minWavelengthM: 1e-11,
    maxWavelengthM: 1e-8,
    color: Color(0xFF5A9AE0),
    note: 'Passes through soft tissue, absorbed by bone.',
  );

  static const EmBand gamma = EmBand(
    name: 'Gamma rays',
    shortName: 'Gamma',
    minWavelengthM: 1e-16,
    maxWavelengthM: 1e-11,
    color: Color(0xFFBF5AD0),
    note: 'From nuclear decay. Highest photon energy, most penetrating.',
  );

  /// Ordered from longest wavelength to shortest, which is also lowest
  /// frequency to highest. Keeping one order everywhere stops the spectrum
  /// strip and the chip row from disagreeing.
  static const List<EmBand> all = [
    radio,
    microwave,
    infrared,
    visible,
    ultraviolet,
    xray,
    gamma,
  ];

  /// The band a wavelength falls in, or the nearest end of the spectrum.
  static EmBand forWavelength(double wavelengthM) {
    for (final b in all) {
      if (b.contains(wavelengthM)) return b;
    }
    return wavelengthM >= radio.maxWavelengthM ? radio : gamma;
  }

  /// Approximate sRGB appearance of a visible wavelength, 380-700 nm.
  ///
  /// A piecewise linear fit, not a colorimetric conversion. Good enough to
  /// make the visible strip recognisable; it is not a calibrated spectrum and
  /// the UI should not pretend otherwise.
  static Color visibleColour(double wavelengthNm) {
    double r = 0, g = 0, b = 0;
    final w = wavelengthNm;
    if (w >= 380 && w < 440) {
      r = -(w - 440) / 60;
      b = 1;
    } else if (w < 490) {
      g = (w - 440) / 50;
      b = 1;
    } else if (w < 510) {
      g = 1;
      b = -(w - 510) / 20;
    } else if (w < 580) {
      r = (w - 510) / 70;
      g = 1;
    } else if (w < 645) {
      r = 1;
      g = -(w - 645) / 65;
    } else if (w <= 700) {
      r = 1;
    } else {
      return const Color(0xFF3A3A3A);
    }

    // Eye response falls away at both ends of the range.
    var fade = 1.0;
    if (w < 420) {
      fade = 0.3 + 0.7 * (w - 380) / 40;
    } else if (w > 645) {
      fade = 0.3 + 0.7 * (700 - w) / 55;
    }

    int ch(double v) => ((v * fade).clamp(0.0, 1.0) * 255).round();
    return Color.fromARGB(255, ch(r), ch(g), ch(b));
  }
}
