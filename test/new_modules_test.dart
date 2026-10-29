import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:wave_lab/services/doppler_physics.dart';
import 'package:wave_lab/services/optics_physics.dart';
import 'package:wave_lab/services/string_solver.dart';

void main() {
  group('StringSolver - stability and speed', () {
    test('the Courant number stays below 1 across the whole parameter range',
        () {
      final s = StringSolver(maxSpeed: 100);
      for (final t in [1.0, 10.0, 50.0, 100.0]) {
        for (final d in [0.01, 0.1, 0.5, 1.0]) {
          s
            ..tension = t
            ..density = d;
          expect(s.courant, lessThanOrEqualTo(1.0),
              reason: 'unstable at T=$t mu=$d');
        }
      }
    });

    test('c = sqrt(T/mu)', () {
      final s = StringSolver()
        ..tension = 10
        ..density = 0.1;
      expect(s.speed, closeTo(10.0, 1e-9));
    });

    test('quadrupling tension doubles the wave speed', () {
      final s = StringSolver()
        ..tension = 10
        ..density = 0.1;
      final before = s.speed;
      s.tension = 40;
      expect(s.speed, closeTo(2 * before, 1e-9));
    });

    test('quadrupling mass density halves the wave speed', () {
      final s = StringSolver()
        ..tension = 10
        ..density = 0.1;
      final before = s.speed;
      s.density = 0.4;
      expect(s.speed, closeTo(before / 2, 1e-9));
    });
  });

  group('StringSolver - a pulse actually travels at c', () {
    test('crest covers the expected distance in the expected time', () {
      final s = StringSolver(
        tension: 10,
        density: 0.1,
        damping: 0,
        boundary: StringBoundary.absorbing,
      );
      // speed is 10 m/s on a 10 m string
      s.addPulse(centreM: 2.0, widthM: 1.0, amplitude: 0.2);

      // run for 0.3 s; the two halves of the split pulse move +-3 m
      final steps = (0.3 / s.dt).round();
      for (var i = 0; i < steps; i++) {
        s.step();
      }

      // find the rightmost peak
      var peakIndex = 0;
      var peak = 0.0;
      for (var i = s.points ~/ 2; i < s.points; i++) {
        if (s.yAt(i).abs() > peak) {
          peak = s.yAt(i).abs();
          peakIndex = i;
        }
      }
      final travelled = peakIndex * s.dx - 2.0;
      expect(travelled, closeTo(3.0, 0.3),
          reason: 'a pulse must move at c = 10 m/s, not at a rate the '
              'renderer chose');
    });
  });

  group('StringSolver - boundaries', () {
    /// Sends a pulse at a wall and reports the sign of what comes back.
    double reflectedSign(StringBoundary boundary) {
      final s = StringSolver(
        tension: 10,
        density: 0.1,
        damping: 0,
        boundary: boundary,
      );
      s.addPulse(centreM: 7.0, widthM: 1.0, amplitude: 0.2);
      // right-moving half reaches the end at ~0.3 s, returns by ~0.75 s
      final steps = (0.75 / s.dt).round();
      for (var i = 0; i < steps; i++) {
        s.step();
      }
      // look in the right half, away from the left-moving half
      var extreme = 0.0;
      for (var i = s.points ~/ 2; i < s.points - 2; i++) {
        if (s.yAt(i).abs() > extreme.abs()) extreme = s.yAt(i);
      }
      return extreme;
    }

    test('a fixed end inverts the pulse', () {
      expect(reflectedSign(StringBoundary.fixed), lessThan(0),
          reason: 'a crest must return as a trough from a fixed end');
    });

    test('a loose end does not invert the pulse', () {
      expect(reflectedSign(StringBoundary.loose), greaterThan(0),
          reason: 'a crest must return as a crest from a loose end');
    });

    test('an absorbing end returns almost nothing', () {
      final s = StringSolver(
        tension: 10,
        density: 0.1,
        damping: 0,
        boundary: StringBoundary.absorbing,
      );
      s.addPulse(centreM: 7.0, widthM: 1.0, amplitude: 0.2);
      final steps = (0.9 / s.dt).round();
      for (var i = 0; i < steps; i++) {
        s.step();
      }
      var peakRight = 0.0;
      for (var i = s.points ~/ 2; i < s.points; i++) {
        if (s.yAt(i).abs() > peakRight) peakRight = s.yAt(i).abs();
      }
      expect(peakRight, lessThan(0.04),
          reason: 'an absorbing end should let the wave leave');
    });
  });

  group('StringSolver - energy and damping', () {
    test('energy is near-conserved with no damping', () {
      final s = StringSolver(
        tension: 10,
        density: 0.1,
        damping: 0,
        boundary: StringBoundary.fixed,
      );
      s.addPulse(centreM: 5.0, widthM: 1.5, amplitude: 0.2);
      s.step();
      final start = s.energy();
      final steps = (1.0 / s.dt).round();
      for (var i = 0; i < steps; i++) {
        s.step();
      }
      final end = s.energy();
      expect((end - start).abs() / start, lessThan(0.10),
          reason: 'more than 10 % energy drift means the solver is wrong');
    });

    test('damping removes energy', () {
      final s = StringSolver(
        tension: 10,
        density: 0.1,
        damping: 1.5,
        boundary: StringBoundary.fixed,
      );
      s.addPulse(centreM: 5.0, widthM: 1.5, amplitude: 0.2);
      s.step();
      final start = s.energy();
      final steps = (1.0 / s.dt).round();
      for (var i = 0; i < steps; i++) {
        s.step();
      }
      expect(s.energy(), lessThan(start * 0.5));
    });

    test('reset clears the string and the clock', () {
      final s = StringSolver()..addPulse(centreM: 5, widthM: 1, amplitude: 0.3);
      s.step();
      expect(s.peakDisplacement(), greaterThan(0));
      s.reset();
      expect(s.peakDisplacement(), 0);
      expect(s.time, 0);
    });
  });

  group('Optics - Snell', () {
    test('air to glass bends the ray towards the normal', () {
      final t2 = OpticsPhysics.refractionAngle(
        incidenceRad: OpticsPhysics.degToRad(45),
        n1: 1.0,
        n2: 1.52,
      );
      expect(t2, isNotNull);
      expect(OpticsPhysics.radToDeg(t2!), closeTo(27.7, 0.2));
    });

    test('normal incidence passes straight through', () {
      final t2 = OpticsPhysics.refractionAngle(
          incidenceRad: 0, n1: 1.0, n2: 1.52);
      expect(t2, closeTo(0, 1e-12));
    });

    test('critical angle for glass to air is about 41 degrees', () {
      final tc = OpticsPhysics.criticalAngle(n1: 1.52, n2: 1.0);
      expect(tc, isNotNull);
      expect(OpticsPhysics.radToDeg(tc!), closeTo(41.1, 0.2));
    });

    test('beyond the critical angle there is no refracted ray', () {
      final t2 = OpticsPhysics.refractionAngle(
        incidenceRad: OpticsPhysics.degToRad(60),
        n1: 1.52,
        n2: 1.0,
      );
      expect(t2, isNull);
      expect(
        OpticsPhysics.isTotalInternalReflection(
          incidenceRad: OpticsPhysics.degToRad(60),
          n1: 1.52,
          n2: 1.0,
        ),
        isTrue,
      );
    });

    test('there is no critical angle going from rarer to denser', () {
      expect(OpticsPhysics.criticalAngle(n1: 1.0, n2: 1.52), isNull);
    });

    test('total internal reflection reflects everything', () {
      expect(
        OpticsPhysics.fresnelReflectance(
          incidenceRad: OpticsPhysics.degToRad(60),
          n1: 1.52,
          n2: 1.0,
        ),
        1.0,
      );
    });

    test('a glass surface reflects only a few percent at normal incidence',
        () {
      final r = OpticsPhysics.fresnelReflectance(
          incidenceRad: 0, n1: 1.0, n2: 1.52);
      expect(r, closeTo(0.043, 0.005));
    });

    test('wavelength shortens in a denser medium, frequency does not change',
        () {
      expect(OpticsPhysics.wavelengthInMedium(500e-9, 1.333),
          closeTo(375.1e-9, 1e-9));
    });
  });

  group('Optics - thin lens', () {
    test('object at twice the focal length images at twice the focal length',
        () {
      final di =
          OpticsPhysics.imageDistance(objectDistance: 20, focalLength: 10);
      expect(di, closeTo(20, 1e-9));
      expect(
        OpticsPhysics.magnification(objectDistance: 20, focalLength: 10),
        closeTo(-1, 1e-9),
      );
    });

    test('an object at the focal point gives no image', () {
      expect(OpticsPhysics.imageDistance(objectDistance: 10, focalLength: 10),
          isNull);
    });

    test('inside the focal length the image is virtual and upright', () {
      expect(
        OpticsPhysics.isRealImage(objectDistance: 5, focalLength: 10),
        isFalse,
      );
      expect(
        OpticsPhysics.magnification(objectDistance: 5, focalLength: 10)!,
        greaterThan(0),
      );
    });
  });

  group('Doppler', () {
    const v = DopplerPhysics.speedOfSoundAir;

    test('a stationary source and observer gives no shift', () {
      expect(
        DopplerPhysics.observedFrequency(emittedHz: 440, waveSpeed: v),
        closeTo(440, 1e-9),
      );
    });

    test('a source approaching raises the pitch', () {
      final f = DopplerPhysics.observedFrequency(
        emittedHz: 440,
        waveSpeed: v,
        sourceSpeed: 30,
      );
      expect(f, closeTo(440 * v / (v - 30), 1e-9));
      expect(f, greaterThan(440));
    });

    test('a source receding lowers the pitch', () {
      final f = DopplerPhysics.observedFrequency(
        emittedHz: 440,
        waveSpeed: v,
        sourceSpeed: -30,
      );
      expect(f, lessThan(440));
    });

    test('an observer approaching raises the pitch', () {
      final f = DopplerPhysics.observedFrequency(
        emittedHz: 440,
        waveSpeed: v,
        observerSpeed: 30,
      );
      expect(f, closeTo(440 * (v + 30) / v, 1e-9));
    });

    test('a moving source and a moving observer are not equivalent', () {
      // the classic result: the sound case depends on which one moves,
      // unlike the relativistic case
      final sourceMoving = DopplerPhysics.observedFrequency(
          emittedHz: 440, waveSpeed: v, sourceSpeed: 30)!;
      final observerMoving = DopplerPhysics.observedFrequency(
          emittedHz: 440, waveSpeed: v, observerSpeed: 30)!;
      expect((sourceMoving - observerMoving).abs(), greaterThan(1.0));
    });

    test('the wavelength ahead of a moving source is compressed', () {
      final still =
          DopplerPhysics.observedWavelength(emittedHz: 440, waveSpeed: v)!;
      final moving = DopplerPhysics.observedWavelength(
          emittedHz: 440, waveSpeed: v, sourceSpeed: 100)!;
      expect(moving, lessThan(still));
      expect(moving, closeTo((v - 100) / 440, 1e-9));
    });

    test('at the speed of sound the formula has no answer', () {
      expect(
        DopplerPhysics.observedFrequency(
            emittedHz: 440, waveSpeed: v, sourceSpeed: v),
        isNull,
      );
      expect(
        DopplerPhysics.regime(waveSpeed: v, sourceSpeed: v),
        DopplerRegime.sonic,
      );
    });

    test('above the speed of sound a shock cone forms', () {
      expect(
        DopplerPhysics.regime(waveSpeed: v, sourceSpeed: 2 * v),
        DopplerRegime.supersonic,
      );
      final a = DopplerPhysics.machConeHalfAngle(
          waveSpeed: v, sourceSpeed: 2 * v);
      expect(a, isNotNull);
      expect(a!, closeTo(math.asin(0.5), 1e-9)); // 30 degrees at Mach 2
    });

    test('no cone below Mach 1', () {
      expect(
        DopplerPhysics.machConeHalfAngle(waveSpeed: v, sourceSpeed: 100),
        isNull,
      );
    });

    test('wavefronts stay centred where they were emitted', () {
      // a front emitted 2 s ago by a source now at 200 m moving at 50 m/s
      expect(
        DopplerPhysics.frontCentre(
            sourcePositionNow: 200, sourceVelocity: 50, age: 2),
        closeTo(100, 1e-9),
      );
      expect(
        DopplerPhysics.frontRadius(waveSpeed: v, age: 2),
        closeTo(686, 1e-9),
      );
    });
  });
}
