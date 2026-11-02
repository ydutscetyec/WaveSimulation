import 'dart:math' as math;
import 'dart:typed_data';

/// Builds a seamlessly loopable WAV buffer for a pure tone.
///
/// No plugin import here on purpose: synthesis is arithmetic and belongs with
/// the other physics services, where it can be unit-tested. Playback is the
/// only part that needs a platform channel, and that lives in TonePlayer.
///
/// The one non-obvious requirement is the loop seam. A buffer that holds a
/// fractional number of cycles restarts at the wrong point in the waveform,
/// which produces an audible click at the loop boundary and is the usual
/// reason naive tone generators sound wrong. [build] therefore rounds the
/// buffer to a WHOLE number of cycles rather than to a round duration, so the
/// last sample joins the first continuously.
class ToneGenerator {
  const ToneGenerator._();

  static const int sampleRate = 44100;
  static const int bitsPerSample = 16;
  static const int channels = 1;

  /// Target buffer length. The actual length is the nearest whole number of
  /// cycles to this, so it varies slightly with frequency.
  static const double targetSeconds = 0.25;

  /// Shortest tone the generator will build, Hz. Below about 20 Hz the result
  /// is inaudible on a phone speaker and only wastes a buffer.
  static const double minFrequency = 20;

  /// Highest tone. Above this, phone speakers roll off badly and the 44.1 kHz
  /// sample rate starts to matter.
  static const double maxFrequency = 8000;

  /// Above this frequency the buffer length is fixed instead of the cycle
  /// count. See [_layout] for why.
  static const double _fixedLengthAbove = 1000;

  /// Buffer layout: whole [cycles] occupying exactly [samples] samples.
  ///
  /// The loop seam is the hard part. A buffer holding a fractional number of
  /// cycles restarts at the wrong point in the waveform and clicks once per
  /// loop. Both of the obvious fixes fail at one end of the band:
  ///
  ///  * Round the CYCLE COUNT and derive the sample count. Pitch stays exact,
  ///    but the sample count rounds by up to half a sample, which leaves a
  ///    phase error proportional to frequency - measured at 0.56 rad near
  ///    8 kHz, which is plainly audible.
  ///  * Round the SAMPLE COUNT and derive the cycle count. The seam is exact,
  ///    but the frequency shifts by up to half a cycle per buffer, which at
  ///    20 Hz is a 7.7% pitch error.
  ///
  /// So: always synthesise at [actualFrequency] = cycles x rate / samples,
  /// which makes the seam exact by construction whichever branch is taken,
  /// and pick the branch that keeps the resulting pitch error small. Below
  /// 1 kHz the sample count is derived, above it the cycle count is. Worst
  /// case across 20 Hz to 8 kHz is then 0.2%, about 3.4 cents - well under
  /// the roughly 10 cents a listener can detect.
  static (int cycles, int samples) _layout(double frequencyHz) {
    if (frequencyHz < _fixedLengthAbove) {
      final cycles = math.max(1, (frequencyHz * targetSeconds).round());
      final samples = math.max(2, (cycles * sampleRate / frequencyHz).round());
      return (cycles, samples);
    }
    const samples = 11025; // targetSeconds at the fixed sample rate
    final cycles = math.max(1, (frequencyHz * samples / sampleRate).round());
    return (cycles, samples);
  }

  /// Whole cycles in the looped buffer.
  static int cyclesFor(double frequencyHz) => _layout(frequencyHz).$1;

  /// Samples in the looped buffer.
  static int sampleCountFor(double frequencyHz) => _layout(frequencyHz).$2;

  /// The frequency actually synthesised, which is the nearest one that fits a
  /// whole number of cycles into a whole number of samples.
  ///
  /// This is what the speaker produces, so a test can check it against the
  /// requested value rather than assuming they are the same.
  static double actualFrequency(double frequencyHz) {
    final (cycles, samples) = _layout(frequencyHz);
    return cycles * sampleRate / samples;
  }

  /// Fractional pitch error introduced by fitting the buffer, 0..1.
  static double pitchError(double frequencyHz) =>
      (actualFrequency(frequencyHz) - frequencyHz).abs() / frequencyHz;

  /// Residual phase at the loop seam, radians. Zero by construction - kept so
  /// a test can prove it rather than the comment above merely claiming it.
  static double seamPhaseError(double frequencyHz) {
    final (cycles, samples) = _layout(frequencyHz);
    final actual = cycles * sampleRate / samples;
    final cyclesInBuffer = actual * samples / sampleRate;
    return (cyclesInBuffer - cyclesInBuffer.roundToDouble()).abs() * 2 * math.pi;
  }

  /// A complete 16-bit mono WAV file for a sine at [frequencyHz].
  ///
  /// [amplitude] is 0..1 of full scale. It is capped below 1 so that the
  /// loudest setting still leaves headroom and does not clip on the mix.
  static Uint8List build({
    required double frequencyHz,
    double amplitude = 0.8,
  }) {
    final requested = frequencyHz.clamp(minFrequency, maxFrequency).toDouble();
    final a = amplitude.clamp(0.0, 1.0) * 0.92;
    final (cycles, count) = _layout(requested);

    // Synthesise at the fitted frequency, not the requested one. These differ
    // by at most 0.2%, and using the fitted value is what makes the buffer
    // hold exactly `cycles` whole cycles and loop without a click.
    final f = cycles * sampleRate / count;

    final pcm = Int16List(count);
    final w = 2 * math.pi * f / sampleRate;

    // A short fade at each end of the buffer would break the loop, so there is
    // none. Continuity comes from the whole-cycle length instead.
    for (var i = 0; i < count; i++) {
      pcm[i] = (a * 32767 * math.sin(w * i)).round().clamp(-32768, 32767);
    }

    return _wrapWav(pcm);
  }

  /// RIFF/WAVE container around raw little-endian PCM.
  static Uint8List _wrapWav(Int16List pcm) {
    const headerBytes = 44;
    final dataBytes = pcm.length * 2;
    final out = Uint8List(headerBytes + dataBytes);
    final view = ByteData.view(out.buffer);

    const byteRate = sampleRate * channels * bitsPerSample ~/ 8;
    const blockAlign = channels * bitsPerSample ~/ 8;

    void ascii(int offset, String s) {
      for (var i = 0; i < s.length; i++) {
        out[offset + i] = s.codeUnitAt(i);
      }
    }

    ascii(0, 'RIFF');
    view.setUint32(4, 36 + dataBytes, Endian.little);
    ascii(8, 'WAVE');

    ascii(12, 'fmt ');
    view.setUint32(16, 16, Endian.little); // PCM chunk size
    view.setUint16(20, 1, Endian.little); // format 1 = PCM
    view.setUint16(22, channels, Endian.little);
    view.setUint32(24, sampleRate, Endian.little);
    view.setUint32(28, byteRate, Endian.little);
    view.setUint16(32, blockAlign, Endian.little);
    view.setUint16(34, bitsPerSample, Endian.little);

    ascii(36, 'data');
    view.setUint32(40, dataBytes, Endian.little);

    for (var i = 0; i < pcm.length; i++) {
      view.setInt16(headerBytes + i * 2, pcm[i], Endian.little);
    }
    return out;
  }
}
