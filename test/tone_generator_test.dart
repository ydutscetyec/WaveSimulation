import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:wave_lab/services/tone_generator.dart';

/// Frequencies chosen to be awkward: a slider never lands on round numbers,
/// and round numbers are exactly the ones that hide loop-seam bugs.
const List<double> _sweep = [
  20.0, 21.3, 23.7, 48.5, 97.2, 139.9, 220.4, 331.1, 439.6, 523.8,
  699.3, 881.7, 999.4, 1006.0, 1234.5, 2001.9, 3457.3, 4999.5,
  6311.2, 7310.0, 7981.1, 8000.0,
];

void main() {
  group('ToneGenerator - loop seam', () {
    test('the buffer holds a whole number of cycles at every frequency', () {
      for (final f in _sweep) {
        expect(
          ToneGenerator.seamPhaseError(f),
          closeTo(0, 1e-9),
          reason: '$f Hz would click once per loop',
        );
      }
    });

    test('the last sample joins the first continuously', () {
      // Extending the sine one sample past the end must land back on sample 0.
      for (final f in [23.7, 439.6, 7981.1]) {
        final cycles = ToneGenerator.cyclesFor(f);
        final n = ToneGenerator.sampleCountFor(f);
        final actual = cycles * ToneGenerator.sampleRate / n;
        final w = 2 * math.pi * actual / ToneGenerator.sampleRate;
        expect(math.sin(w * n), closeTo(math.sin(0), 1e-9), reason: '$f Hz');
      }
    });
  });

  group('ToneGenerator - pitch accuracy', () {
    test('the fitted frequency stays within 0.3% of the request', () {
      for (final f in _sweep) {
        expect(
          ToneGenerator.pitchError(f),
          lessThan(0.003),
          reason: '$f Hz is audibly off pitch',
        );
      }
    });

    test('the low branch keeps bass frequencies essentially exact', () {
      // The fixed-length branch would be 7.7% out at the bottom of the band,
      // which is why the layout switches strategy at 1 kHz.
      for (final f in [20.0, 21.3, 23.7, 48.5]) {
        expect(ToneGenerator.pitchError(f), lessThan(1e-4), reason: '$f Hz');
      }
    });

    test('buffer length stays near the target duration', () {
      for (final f in _sweep) {
        final seconds =
            ToneGenerator.sampleCountFor(f) / ToneGenerator.sampleRate;
        expect(seconds, greaterThan(0.1));
        expect(seconds, lessThan(0.6));
      }
    });
  });

  group('ToneGenerator - WAV container', () {
    String ascii(Uint8List b, int at, int len) =>
        String.fromCharCodes(b.sublist(at, at + len));

    test('writes a valid 16-bit mono PCM header', () {
      final b = ToneGenerator.build(frequencyHz: 440);
      final v = ByteData.view(b.buffer);

      expect(ascii(b, 0, 4), 'RIFF');
      expect(ascii(b, 8, 4), 'WAVE');
      expect(ascii(b, 12, 4), 'fmt ');
      expect(ascii(b, 36, 4), 'data');

      expect(v.getUint32(16, Endian.little), 16); // PCM chunk size
      expect(v.getUint16(20, Endian.little), 1); // format 1 = PCM
      expect(v.getUint16(22, Endian.little), ToneGenerator.channels);
      expect(v.getUint32(24, Endian.little), ToneGenerator.sampleRate);
      expect(v.getUint16(34, Endian.little), ToneGenerator.bitsPerSample);
    });

    test('declared sizes match the real byte count', () {
      for (final f in [23.7, 440.0, 7310.0]) {
        final b = ToneGenerator.build(frequencyHz: f);
        final v = ByteData.view(b.buffer);
        final dataBytes = ToneGenerator.sampleCountFor(f) * 2;

        expect(b.length, 44 + dataBytes, reason: '$f Hz total length');
        expect(v.getUint32(40, Endian.little), dataBytes, reason: 'data size');
        expect(v.getUint32(4, Endian.little), 36 + dataBytes, reason: 'RIFF');
      }
    });

    test('byte rate and block align follow from the format fields', () {
      final b = ToneGenerator.build(frequencyHz: 440);
      final v = ByteData.view(b.buffer);
      const blockAlign =
          ToneGenerator.channels * ToneGenerator.bitsPerSample ~/ 8;
      expect(v.getUint16(32, Endian.little), blockAlign);
      expect(
        v.getUint32(28, Endian.little),
        ToneGenerator.sampleRate * blockAlign,
      );
    });
  });

  group('ToneGenerator - samples', () {
    List<int> samplesOf(Uint8List b) {
      final v = ByteData.view(b.buffer);
      return [
        for (var i = 44; i < b.length; i += 2) v.getInt16(i, Endian.little),
      ];
    }

    test('zero amplitude is silence, not a quiet tone', () {
      final s = samplesOf(ToneGenerator.build(frequencyHz: 440, amplitude: 0));
      expect(s.every((v) => v == 0), isTrue);
    });

    test('peak amplitude leaves headroom below full scale', () {
      final s = samplesOf(ToneGenerator.build(frequencyHz: 440, amplitude: 1));
      final peak = s.map((v) => v.abs()).reduce(math.max);
      expect(peak, lessThan(32767));
      expect(peak, greaterThan(28000));
    });

    test('amplitude scales the peak roughly linearly', () {
      int peakAt(double a) => samplesOf(
            ToneGenerator.build(frequencyHz: 440, amplitude: a),
          ).map((v) => v.abs()).reduce(math.max);
      final half = peakAt(0.5);
      final full = peakAt(1.0);
      expect(half / full, closeTo(0.5, 0.02));
    });

    test('the waveform starts at the zero crossing', () {
      final s = samplesOf(ToneGenerator.build(frequencyHz: 440));
      expect(s.first, 0);
    });

    test('frequency outside the band is clamped, not rejected', () {
      expect(ToneGenerator.build(frequencyHz: 5).length, greaterThan(44));
      expect(ToneGenerator.build(frequencyHz: 40000).length, greaterThan(44));
    });
  });
}
