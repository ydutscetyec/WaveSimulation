import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

import 'tone_generator.dart';

/// Loops a synthesised tone, following the simulation's frequency and
/// amplitude. The audio counterpart of PhET's "Play Tone" checkbox.
///
/// Design rules this follows:
///
///  * Everything is in a try/catch and failure degrades to silence. A phone
///    with the audio route busy, an emulator with no audio device, or a
///    plugin that failed to register must not take the simulation down with
///    it - the physics is the product, the tone is an aid. [available] goes
///    false and the UI greys the toggle out.
///
///  * Frequency changes are debounced. A slider drag emits dozens of values a
///    second; rebuilding and restarting the buffer on each one stutters badly.
///    Amplitude is NOT debounced because it maps to a volume call, which is
///    cheap and wants to feel immediate.
///
///  * Nothing is generated until the user actually turns the tone on, so an
///    app that is never asked for audio never touches the plugin.
class TonePlayer extends ChangeNotifier {
  TonePlayer();

  final AudioPlayer _player = AudioPlayer();

  Timer? _debounce;
  bool _enabled = false;
  bool _available = true;
  bool _started = false;
  bool _disposed = false;

  double _frequency = 440;
  double _amplitude = 0.6;

  /// False once a platform call has failed. The toggle should be disabled.
  bool get available => _available;

  bool get enabled => _enabled;
  double get frequency => _frequency;

  /// How long to wait after the last frequency change before rebuilding.
  static const Duration _debounceWindow = Duration(milliseconds: 90);

  Future<void> setEnabled(bool on) async {
    if (_enabled == on) return;
    _enabled = on;
    notifyListeners();
    if (on) {
      await _restart();
    } else {
      await _stop();
    }
  }

  /// Frequency in Hz. Debounced; the tone follows a moment after the slider
  /// settles.
  void setFrequency(double hz) {
    if ((hz - _frequency).abs() < 0.5) return;
    _frequency = hz;
    if (!_enabled) return;
    _debounce?.cancel();
    _debounce = Timer(_debounceWindow, _restart);
  }

  /// Amplitude 0..1. Applied immediately as a volume change.
  Future<void> setAmplitude(double a) async {
    final v = a.clamp(0.0, 1.0);
    if ((v - _amplitude).abs() < 0.01) return;
    _amplitude = v;
    if (!_enabled || !_started) return;
    await _guard(() => _player.setVolume(_amplitude));
  }

  Future<void> _restart() async {
    if (_disposed || !_enabled || !_available) return;

    // Outside the audible band there is nothing worth playing, and the
    // generator would clamp to an edge frequency that lies about what is on
    // screen. Silence is the honest output.
    if (_frequency < ToneGenerator.minFrequency ||
        _frequency > ToneGenerator.maxFrequency) {
      await _stop();
      return;
    }

    final bytes = ToneGenerator.build(
      frequencyHz: _frequency,
      amplitude: 1.0, // level is set by volume, so the buffer stays full-scale
    );

    await _guard(() async {
      await _player.stop();
      await _player.setReleaseMode(ReleaseMode.loop);
      await _player.setVolume(_amplitude);
      await _player.play(BytesSource(bytes));
      _started = true;
    });
  }

  Future<void> _stop() async {
    if (!_started) return;
    await _guard(() => _player.stop());
    _started = false;
  }

  /// Runs a platform call, and permanently marks audio unavailable if it
  /// throws. One failure is enough: the causes are all persistent.
  Future<void> _guard(Future<void> Function() action) async {
    try {
      await action();
    } catch (e) {
      _available = false;
      _enabled = false;
      _started = false;
      debugPrint('TonePlayer: audio unavailable ($e)');
      if (!_disposed) notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _debounce?.cancel();
    // Fire and forget: dispose must not be async, and a failure here is not
    // worth surfacing.
    _player.dispose().catchError((_) {});
    super.dispose();
  }
}
