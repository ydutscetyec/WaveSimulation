import 'package:flutter/material.dart';

import '../services/wave_physics.dart';
import '../theme/app_theme.dart';

/// A propagation medium. All figures are ROOM-TEMPERATURE APPROXIMATIONS for
/// teaching. Real values depend on temperature, humidity, grain direction,
/// alloy, porosity and frequency - the UI says so wherever these are shown.
@immutable
class AcousticMaterial {
  const AcousticMaterial({
    required this.name,
    required this.speedMs,
    required this.densityKgM3,
    required this.behaviour,
    required this.note,
    required this.color,
    this.isVacuum = false,
  });

  final String name;
  final double speedMs;
  final double densityKgM3;
  final String behaviour;
  final String note;
  final Color color;
  final bool isVacuum;

  /// Z = rho * v
  double get impedance => WavePhysics.impedance(densityKgM3, speedMs);

  String get impedanceLabel {
    final z = impedance;
    if (z >= 1e6) return '${(z / 1e6).toStringAsFixed(1)} Mrayl';
    if (z >= 1e3) return '${(z / 1e3).toStringAsFixed(1)} krayl';
    return '${z.toStringAsFixed(0)} rayl';
  }
}

class Media {
  const Media._();

  static const AcousticMaterial air = AcousticMaterial(
    name: 'Air',
    speedMs: 343,
    densityKgM3: 1.2,
    behaviour: 'Carries sound well over distance but transfers little energy '
        'into solids, because its impedance is tiny compared with theirs.',
    note: 'Dry air at about 20 °C. Speed rises roughly 0.6 m/s per °C.',
    color: AppColors.cyan,
  );

  static const AcousticMaterial water = AcousticMaterial(
    name: 'Water',
    speedMs: 1480,
    densityKgM3: 1000,
    behaviour: 'Sound travels about 4x faster than in air, so at the same '
        'frequency the wavelength is about 4x longer.',
    note: 'Fresh water near 20 °C. Sea water is slightly faster.',
    color: AppColors.blue,
  );

  static const AcousticMaterial wood = AcousticMaterial(
    name: 'Wood',
    speedMs: 3800,
    densityKgM3: 600,
    behaviour: 'Strongly direction dependent. Sound runs much faster along the '
        'grain than across it.',
    note: 'Along the grain, typical softwood. Across the grain it can be '
        '3-5x slower, so treat this as one number from a wide range.',
    color: Color(0xFFC98A4B),
  );

  static const AcousticMaterial glass = AcousticMaterial(
    name: 'Glass',
    speedMs: 5600,
    densityKgM3: 2500,
    behaviour: 'Stiff and dense. It rings for a long time when struck because '
        'it loses energy slowly.',
    note: 'Longitudinal bulk value for common soda-lime glass.',
    color: Color(0xFF8FD4E8),
  );

  static const AcousticMaterial steel = AcousticMaterial(
    name: 'Steel',
    speedMs: 5960,
    densityKgM3: 7850,
    behaviour: 'Among the fastest everyday materials. Very high impedance, so '
        'an air-steel boundary reflects almost all incoming sound.',
    note: 'Longitudinal bulk value for mild steel.',
    color: Color(0xFFB9C6D6),
  );

  static const AcousticMaterial vacuum = AcousticMaterial(
    name: 'Vacuum',
    speedMs: 0,
    densityKgM3: 0,
    behaviour: 'No particles, so there is nothing to compress. A mechanical '
        'wave cannot exist here at all.',
    note: 'Sound is a mechanical wave: it needs matter. Light does not.',
    color: AppColors.textDim,
    isVacuum: true,
  );

  static const List<AcousticMaterial> all = [air, water, wood, glass, steel];
  static const List<AcousticMaterial> allWithVacuum = [
    air,
    water,
    wood,
    glass,
    steel,
    vacuum,
  ];
}

/// A surface the wave can hit. alpha is the absorption coefficient: the
/// fraction of incident ENERGY absorbed, 0 = perfect reflector, 1 = perfect
/// absorber. Mid-frequency classroom figures.
@immutable
class WallMaterial {
  const WallMaterial({
    required this.name,
    required this.alpha,
    required this.color,
    required this.note,
  });

  final String name;
  final double alpha;
  final Color color;
  final String note;

  /// Amplitude that comes back = sqrt(1 - alpha)
  double get reflectedRatio => WavePhysics.reflectedAmplitudeRatio(alpha);

  int get reflectedPercent => (reflectedRatio * 100).round();
  int get absorbedPercentEnergy => (alpha * 100).round();
}

class Walls {
  const Walls._();

  static const WallMaterial concrete = WallMaterial(
    name: 'Concrete',
    alpha: 0.02,
    color: Color(0xFFA6AEBB),
    note: 'Hard, heavy and sealed. Almost all the energy comes straight back, '
        'which is why empty concrete rooms echo.',
  );
  static const WallMaterial wood = WallMaterial(
    name: 'Wood panel',
    alpha: 0.12,
    color: Color(0xFFC98A4B),
    note: 'Mostly reflective, but thin panels flex and turn a little sound '
        'energy into heat and panel vibration.',
  );
  static const WallMaterial cloth = WallMaterial(
    name: 'Heavy cloth',
    alpha: 0.55,
    color: Color(0xFF7E6BB5),
    note: 'Air moving through the fibres loses energy to friction. Good at '
        'high frequencies, much weaker at low ones.',
  );
  static const WallMaterial foam = WallMaterial(
    name: 'Acoustic foam',
    alpha: 0.80,
    color: Color(0xFF4E7F6B),
    note: 'Open pores absorb most mid and high frequencies - but never all of '
        'it, and bass passes through thin foam almost untouched.',
  );

  static const List<WallMaterial> all = [concrete, wood, cloth, foam];
}
