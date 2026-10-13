import 'package:flutter/material.dart';

import '../services/wave_physics.dart';
import '../theme/wave_theme.dart';

/// Which palette slot a material paints with. The actual Color is resolved at
/// build time so materials look right in both light and dark mode.
enum Accent { cyan, blue, wood, glass, steel, muted }

extension AccentColor on Accent {
  Color of(WaveColors c) => switch (this) {
        Accent.cyan => c.accent,
        Accent.blue => c.blue,
        Accent.wood => c.wood,
        Accent.glass => c.glass,
        Accent.steel => c.steel,
        Accent.muted => c.textTertiary,
      };
}

/// Room-temperature approximations for teaching. Real values move with
/// temperature, density, grain direction and alloy.
@immutable
class AcousticMaterial {
  const AcousticMaterial({
    required this.name,
    required this.speedMs,
    required this.densityKgM3,
    required this.note,
    required this.accent,
    this.isVacuum = false,
  });

  final String name;
  final double speedMs;
  final double densityKgM3;
  final String note;
  final Accent accent;
  final bool isVacuum;

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
    note: 'Dry air near 20 °C. Speed rises about 0.6 m/s per degree.',
    accent: Accent.cyan,
  );

  static const AcousticMaterial water = AcousticMaterial(
    name: 'Water',
    speedMs: 1480,
    densityKgM3: 1000,
    note: 'About 4x faster than air, so the wavelength is about 4x longer.',
    accent: Accent.blue,
  );

  static const AcousticMaterial wood = AcousticMaterial(
    name: 'Wood',
    speedMs: 3800,
    densityKgM3: 600,
    note: 'Along the grain. Across the grain it can be 3-5x slower.',
    accent: Accent.wood,
  );

  static const AcousticMaterial glass = AcousticMaterial(
    name: 'Glass',
    speedMs: 5600,
    densityKgM3: 2500,
    note: 'Stiff and dense, so it rings for a long time when struck.',
    accent: Accent.glass,
  );

  static const AcousticMaterial steel = AcousticMaterial(
    name: 'Steel',
    speedMs: 5960,
    densityKgM3: 7850,
    note: 'Very high impedance, so an air-steel boundary reflects nearly all '
        'the sound.',
    accent: Accent.steel,
  );

  static const AcousticMaterial vacuum = AcousticMaterial(
    name: 'Vacuum',
    speedMs: 0,
    densityKgM3: 0,
    note: 'No particles, so there is nothing to compress.',
    accent: Accent.muted,
    isVacuum: true,
  );

  static const List<AcousticMaterial> all = [air, water, wood, glass, steel];
}

/// alpha is the fraction of incident ENERGY absorbed at mid frequencies.
@immutable
class WallMaterial {
  const WallMaterial({
    required this.name,
    required this.alpha,
    required this.note,
  });

  final String name;
  final double alpha;
  final String note;

  double get reflectedRatio => WavePhysics.reflectedAmplitudeRatio(alpha);
  int get reflectedPercent => (reflectedRatio * 100).round();
  int get absorbedPercentEnergy => (alpha * 100).round();
}

class Walls {
  const Walls._();

  static const WallMaterial concrete = WallMaterial(
    name: 'Concrete',
    alpha: 0.02,
    note: 'Hard, heavy, sealed. Nearly all the energy comes back, which is why '
        'bare concrete rooms echo.',
  );
  static const WallMaterial wood = WallMaterial(
    name: 'Wood',
    alpha: 0.12,
    note: 'Mostly reflective, but thin panels flex and lose a little energy.',
  );
  static const WallMaterial cloth = WallMaterial(
    name: 'Cloth',
    alpha: 0.55,
    note: 'Air rubbing through the fibres loses energy. Good at high '
        'frequencies, weak at low ones.',
  );
  static const WallMaterial foam = WallMaterial(
    name: 'Foam',
    alpha: 0.80,
    note: 'Absorbs most mid and high frequencies. Bass passes through thin '
        'foam almost untouched.',
  );

  static const List<WallMaterial> all = [concrete, wood, cloth, foam];
}
