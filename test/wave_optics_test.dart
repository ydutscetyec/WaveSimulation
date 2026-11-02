import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:wave_lab/services/diffraction_physics.dart';
import 'package:wave_lab/services/em_physics.dart';
import 'package:wave_lab/services/wave_physics.dart';

void main() {
  group('Diffraction - closed form', () {
    test('intensity on the axis is the maximum, normalised to 1', () {
      expect(
        DiffractionPhysics.singleSlitIntensity(
          thetaRad: 0,
          wavelengthM: 0.01,
          slitWidthM: 0.1,
        ),
        closeTo(1.0, 1e-12),
      );
    });

    test('intensity vanishes where a sin(theta) = m lambda', () {
      const lambda = 0.01;
      const a = 0.1;
      for (var m = 1; m <= 4; m++) {
        final theta = DiffractionPhysics.minimumAngle(
          order: m,
          wavelengthM: lambda,
          slitWidthM: a,
        );
        expect(theta, isNotNull, reason: 'order $m should exist for a/l = 10');
        final i = DiffractionPhysics.singleSlitIntensity(
          thetaRad: theta!,
          wavelengthM: lambda,
          slitWidthM: a,
        );
        expect(i, closeTo(0, 1e-12), reason: 'minimum of order $m');
      }
    });

    test('an opening narrower than a wavelength has no minimum at all', () {
      final theta = DiffractionPhysics.minimumAngle(
        order: 1,
        wavelengthM: 0.05,
        slitWidthM: 0.03,
      );
      expect(theta, isNull);
      expect(
        DiffractionPhysics.centralLobeHalfAngle(
          wavelengthM: 0.05,
          slitWidthM: 0.03,
        ),
        isNull,
      );
    });

    test('the central lobe widens as the opening narrows', () {
      double half(double a) =>
          DiffractionPhysics.centralLobeHalfAngle(
            wavelengthM: 0.01,
            slitWidthM: a,
          )!;
      expect(half(0.02), greaterThan(half(0.05)));
      expect(half(0.05), greaterThan(half(0.20)));
    });

    test('spread depends only on lambda/a, not on either one alone', () {
      // Double both and nothing about the pattern changes.
      final r1 = DiffractionPhysics.spreadRatio(0.01, 0.05);
      final r2 = DiffractionPhysics.spreadRatio(0.02, 0.10);
      expect(r1, closeTo(r2, 1e-12));

      final t1 = DiffractionPhysics.minimumAngle(
        order: 1,
        wavelengthM: 0.01,
        slitWidthM: 0.05,
      )!;
      final t2 = DiffractionPhysics.minimumAngle(
        order: 1,
        wavelengthM: 0.02,
        slitWidthM: 0.10,
      )!;
      expect(t1, closeTo(t2, 1e-12));
    });
  });

  group('Diffraction - Huygens sources', () {
    test('aperture sources span the opening and are centred on the axis', () {
      final s = DiffractionPhysics.sourcePositions(
        openingM: 0.20,
        wavelengthM: 0.05,
      );
      expect(s.length, greaterThan(2));
      expect(s.first, closeTo(-0.10, 1e-12));
      expect(s.last, closeTo(0.10, 1e-12));
      // Symmetric about the axis.
      expect(s.reduce((a, b) => a + b) / s.length, closeTo(0, 1e-12));
    });

    test('sampling stays finer than half a wavelength', () {
      // Coarser than lambda/2 and the slit would behave as a grating.
      const lambda = 0.04;
      final s = DiffractionPhysics.sourcePositions(
        openingM: 0.5,
        wavelengthM: lambda,
      );
      final step = (s[1] - s[0]).abs();
      expect(step, lessThan(lambda / 2));
    });

    test('an obstacle opens the barrier everywhere except behind itself', () {
      final s = DiffractionPhysics.sourcePositions(
        openingM: 0.2,
        wavelengthM: 0.05,
        obstacle: true,
        barrierSpanM: 0.9,
      );
      expect(s, isNotEmpty);
      // Nothing inside the shadow of the obstacle.
      expect(s.every((y) => y.abs() >= 0.2 / 2 - 1e-12), isTrue);
      // Reaches the edges of the illuminated barrier.
      expect(s.map((y) => y.abs()).reduce(math.max), closeTo(0.45, 1e-9));
    });
  });

  group('Diffraction - numerical sum against the closed form', () {
    // The Huygens sum and the Fraunhofer formula are independent routes to the
    // same pattern. Agreeing in the far field is the real check that the
    // phasor sum is right, since nothing else in the app can verify it.
    const lambda = 0.01;
    const a = 0.10; // a^2/lambda = 1 m, so R = 30 m is comfortably far field
    const r = 30.0;

    double numericalIntensityAt(double thetaRad) {
      final sources = DiffractionPhysics.sourcePositions(
        openingM: a,
        wavelengthM: lambda,
      );
      final p = DiffractionPhysics.huygensPhasor(
        x: r * math.cos(thetaRad),
        y: r * math.sin(thetaRad),
        sourceYs: sources,
        waveNumberK: WavePhysics.waveNumber(lambda),
      );
      return DiffractionPhysics.intensityFromPhasor(p[0], p[1]);
    }

    test('the first minimum predicted by the formula really is dark', () {
      final onAxis = numericalIntensityAt(0);
      final theta = DiffractionPhysics.minimumAngle(
        order: 1,
        wavelengthM: lambda,
        slitWidthM: a,
      )!;
      final atMin = numericalIntensityAt(theta);
      expect(atMin / onAxis, lessThan(0.01));
    });

    test('the numerical lobe shape tracks (sin b / b)^2', () {
      final onAxis = numericalIntensityAt(0);
      final firstMin = DiffractionPhysics.minimumAngle(
        order: 1,
        wavelengthM: lambda,
        slitWidthM: a,
      )!;

      for (final frac in [0.25, 0.5, 0.75]) {
        final theta = firstMin * frac;
        final numeric = numericalIntensityAt(theta) / onAxis;
        final analytic = DiffractionPhysics.singleSlitIntensity(
          thetaRad: theta,
          wavelengthM: lambda,
          slitWidthM: a,
        );
        // Loose, because the sum keeps the exact 1/sqrt(r) spreading that the
        // far-field formula drops.
        expect(numeric, closeTo(analytic, 0.05), reason: 'at $frac of minimum');
      }
    });

    test('the secondary maximum is far weaker than the central one', () {
      final onAxis = numericalIntensityAt(0);
      final m1 = DiffractionPhysics.minimumAngle(
        order: 1,
        wavelengthM: lambda,
        slitWidthM: a,
      )!;
      final m2 = DiffractionPhysics.minimumAngle(
        order: 2,
        wavelengthM: lambda,
        slitWidthM: a,
      )!;
      final between = numericalIntensityAt((m1 + m2) / 2) / onAxis;
      // Textbook value for the first side lobe is about 4.7%.
      expect(between, lessThan(0.09));
      expect(between, greaterThan(0.01));
    });
  });

  group('Electromagnetic waves', () {
    test('c = f lambda round trips', () {
      const lambda = 5.5e-7;
      final f = EmPhysics.frequencyFor(lambda);
      expect(EmPhysics.wavelengthFor(f), closeTo(lambda, 1e-20));
      expect(f * lambda, closeTo(EmPhysics.c, 1e-3));
    });

    test('green light carries about 2.25 eV per photon', () {
      final f = EmPhysics.frequencyFor(5.5e-7);
      expect(EmPhysics.photonEnergyEv(f), closeTo(2.25, 0.05));
    });

    test('photon energy rises with frequency across the spectrum', () {
      double ev(double lambda) =>
          EmPhysics.photonEnergyEv(EmPhysics.frequencyFor(lambda));
      expect(ev(1e-12), greaterThan(ev(1e-9)));
      expect(ev(1e-9), greaterThan(ev(5e-7)));
      expect(ev(5e-7), greaterThan(ev(1e-2)));
    });

    test('a medium slows light and shortens the wavelength, f unchanged', () {
      const n = 1.333;
      final v = EmPhysics.speedInMedium(n);
      expect(v, closeTo(EmPhysics.c / n, 1e-6));
      // Same frequency, so lambda must shrink by the same factor as v.
      expect(v / EmPhysics.c, closeTo(1 / n, 1e-12));
    });

    test('bands classify their own representative wavelength', () {
      for (final b in EmBand.all) {
        expect(
          EmBand.forWavelength(b.centreWavelengthM).name,
          b.name,
          reason: b.name,
        );
      }
    });

    test('the band list runs from long wavelength to short, with no gaps', () {
      for (var i = 0; i < EmBand.all.length - 1; i++) {
        final a = EmBand.all[i];
        final b = EmBand.all[i + 1];
        expect(a.minWavelengthM, greaterThan(b.minWavelengthM));
        expect(b.maxWavelengthM, closeTo(a.minWavelengthM, 1e-30));
      }
    });

    test('visible colours stay inside the visible band', () {
      expect(EmBand.forWavelength(5.5e-7).name, EmBand.visible.name);
      expect(EmBand.forWavelength(4.0e-7).name, EmBand.visible.name);
      expect(EmBand.forWavelength(8.0e-7).name, EmBand.infrared.name);
    });
  });

  group('Polarisation', () {
    test('Malus at 0, 45 and 90 degrees', () {
      expect(EmPhysics.malus(1, 0), closeTo(1.0, 1e-12));
      expect(EmPhysics.malus(1, math.pi / 4), closeTo(0.5, 1e-12));
      expect(EmPhysics.malus(1, math.pi / 2), closeTo(0.0, 1e-12));
      expect(EmPhysics.malus(1, math.pi), closeTo(1.0, 1e-12));
    });

    test('unpolarised light always loses exactly half at the first filter',
        () {
      // The angle of a lone polariser cannot matter.
      for (final angle in [0.0, 0.3, 1.0, math.pi / 2, 2.9]) {
        expect(EmPhysics.throughStack(1, [angle]), closeTo(0.5, 1e-12));
      }
    });

    test('crossed polarisers pass nothing', () {
      expect(
        EmPhysics.throughStack(1, [0, math.pi / 2]),
        closeTo(0.0, 1e-12),
      );
    });

    test('a third polariser at 45 degrees between crossed ones gives 12.5%',
        () {
      final crossed = EmPhysics.throughStack(1, [0, math.pi / 2]);
      final withMiddle =
          EmPhysics.throughStack(1, [0, math.pi / 4, math.pi / 2]);
      expect(crossed, closeTo(0.0, 1e-12));
      expect(withMiddle, closeTo(0.125, 1e-12));
      expect(withMiddle, greaterThan(crossed));
    });

    test('45 degrees is the best place for the middle polariser', () {
      double withMiddleAt(double deg) => EmPhysics.throughStack(
            1,
            [0, deg * math.pi / 180, math.pi / 2],
          );
      final best = withMiddleAt(45);
      for (final d in [10.0, 25.0, 40.0, 50.0, 65.0, 80.0]) {
        expect(withMiddleAt(d), lessThan(best + 1e-12), reason: '$d deg');
      }
    });

    test('only the angle between neighbours matters, not the absolute axes',
        () {
      final a = EmPhysics.throughStack(1, [0, math.pi / 3]);
      final b = EmPhysics.throughStack(1, [1.1, 1.1 + math.pi / 3]);
      expect(a, closeTo(b, 1e-12));
    });

    test('intensity is the square of the amplitude projection', () {
      for (final t in [0.0, 0.4, 1.0, 1.5]) {
        final amp = EmPhysics.amplitudeProjection(t);
        expect(EmPhysics.malus(1, t), closeTo(amp * amp, 1e-12));
      }
    });
  });
}
