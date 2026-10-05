import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:wave_lab/services/wave_physics.dart';

void main() {
  group('v = f * lambda', () {
    test('440 Hz in air gives about 0.78 m', () {
      final lambda = WavePhysics.wavelength(343, 440);
      expect(lambda, closeTo(0.7795, 0.001));
    });

    test('doubling frequency halves wavelength', () {
      final a = WavePhysics.wavelength(343, 440);
      final b = WavePhysics.wavelength(343, 880);
      expect(b, closeTo(a / 2, 1e-9));
    });

    test('same frequency in water gives a longer wavelength', () {
      final air = WavePhysics.wavelength(343, 440);
      final water = WavePhysics.wavelength(1480, 440);
      expect(water / air, closeTo(1480 / 343, 1e-9));
    });

    test('round trip through frequencyFor', () {
      final lambda = WavePhysics.wavelength(343, 512);
      expect(WavePhysics.frequencyFor(343, lambda), closeTo(512, 1e-9));
    });
  });

  group('echo', () {
    test('34.3 m in air gives 0.20 s', () {
      expect(WavePhysics.echoDelay(34.3, 343), closeTo(0.2, 1e-9));
    });

    test('delay is linear in distance', () {
      expect(
        WavePhysics.echoDelay(200, 343),
        closeTo(2 * WavePhysics.echoDelay(100, 343), 1e-9),
      );
    });
  });

  group('particle motion', () {
    test('displacement is zero where strain is largest', () {
      const a = 0.01;
      final k = WavePhysics.waveNumber(0.78);
      // At kx - phase = 0: sin = 0 (no displacement), cos = 1 (max compression)
      final s = WavePhysics.displacement(
          amplitude: a, waveNumberK: k, x: 0, phase: 0);
      final c = WavePhysics.strain(
          amplitude: a, waveNumberK: k, x: 0, phase: 0);
      expect(s, closeTo(0, 1e-12));
      expect(c, closeTo(a * k, 1e-12));
    });

    test('compression and rarefaction are half a wavelength apart', () {
      const lambda = 0.78;
      final k = WavePhysics.waveNumber(lambda);
      final c = WavePhysics.strain(
          amplitude: 0.01, waveNumberK: k, x: 0, phase: 0);
      final r = WavePhysics.strain(
          amplitude: 0.01, waveNumberK: k, x: lambda / 2, phase: 0);
      expect(c, closeTo(-r, 1e-12));
    });

    test('amplitude cap keeps strain below one', () {
      final k = WavePhysics.waveNumber(0.1);
      final aMax = WavePhysics.maxPhysicalAmplitude(k);
      expect(aMax * k, lessThan(1.0));
    });
  });

  group('resonance', () {
    test('closed pipe fundamental is v/4L', () {
      expect(WavePhysics.closedPipeResonance(343, 0.17, 1),
          closeTo(343 / (4 * 0.17), 1e-9));
    });

    test('closed pipe has odd harmonics only', () {
      final f1 = WavePhysics.closedPipeResonance(343, 0.2, 1);
      final f2 = WavePhysics.closedPipeResonance(343, 0.2, 2);
      expect(f2 / f1, closeTo(3.0, 1e-9));
    });

    test('response peaks at f0 and falls away on both sides', () {
      const f0 = 500.0;
      final peak = WavePhysics.resonanceResponse(f0, f0, 18);
      final below = WavePhysics.resonanceResponse(400, f0, 18);
      final above = WavePhysics.resonanceResponse(600, f0, 18);
      expect(peak, closeTo(1.0, 0.02));
      expect(below, lessThan(peak * 0.5));
      expect(above, lessThan(peak * 0.5));
    });
  });

  group('reflection', () {
    test('a perfect reflector returns all of the amplitude', () {
      expect(WavePhysics.reflectedAmplitudeRatio(0), closeTo(1.0, 1e-12));
    });

    test('alpha 0.8 returns sqrt(0.2) of the amplitude, not 0.2', () {
      expect(WavePhysics.reflectedAmplitudeRatio(0.8),
          closeTo(math.sqrt(0.2), 1e-12));
    });

    test('impedance mismatch between air and steel is severe', () {
      final zAir = WavePhysics.impedance(1.2, 343);
      final zSteel = WavePhysics.impedance(7850, 5960);
      final r = WavePhysics.pressureReflection(zAir, zSteel);
      expect(r, greaterThan(0.999));
    });
  });

  group('interference', () {
    const k = 8.0;
    test('zero path difference is fully constructive', () {
      final a = WavePhysics.interferenceAmplitude(
          a1: 1, a2: 1, waveNumberK: k, r1: 2, r2: 2, phaseOffset: 0);
      expect(a, closeTo(2.0, 1e-9));
    });

    test('half a wavelength of path difference cancels', () {
      final lambda = 2 * math.pi / k;
      final a = WavePhysics.interferenceAmplitude(
        a1: 1,
        a2: 1,
        waveNumberK: k,
        r1: 0,
        r2: lambda / 2,
        phaseOffset: 0,
      );
      expect(a, closeTo(0.0, 1e-9));
    });

    test('a whole wavelength of path difference reinforces again', () {
      final lambda = 2 * math.pi / k;
      final a = WavePhysics.interferenceAmplitude(
        a1: 1,
        a2: 1,
        waveNumberK: k,
        r1: 0,
        r2: lambda,
        phaseOffset: 0,
      );
      expect(a, closeTo(2.0, 1e-9));
    });
  });

  group('standing waves', () {
    test('nodes sit every half wavelength', () {
      const lambda = 1.0;
      final k = WavePhysics.waveNumber(lambda);
      for (final x in [0.0, 0.5, 1.0, 1.5]) {
        final y = WavePhysics.standingWave(
            amplitude: 1, waveNumberK: k, x: x, phase: 0.7);
        expect(y.abs(), lessThan(1e-9));
      }
    });

    test('antinodes sit a quarter wavelength from a node', () {
      final k = WavePhysics.waveNumber(1.0);
      final y = WavePhysics.standingWave(
          amplitude: 1, waveNumberK: k, x: 0.25, phase: 0);
      expect(y.abs(), closeTo(2.0, 1e-9));
    });
  });

  test('pitch labels follow frequency', () {
    expect(WavePhysics.pitchLabel(40), 'LOW');
    expect(WavePhysics.pitchLabel(440), 'MEDIUM');
    expect(WavePhysics.pitchLabel(1800), 'HIGH');
  });
}
