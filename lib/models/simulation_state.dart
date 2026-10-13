import 'package:flutter/material.dart';

import '../services/wave_physics.dart';
import 'acoustic_material.dart';

/// App state. Trimmed from v1: the badge system, the auto/manual speed toggle
/// and the free-floating view-width slider are gone. Every control that
/// survived changes something you can see.
///
/// The per-frame animation clock is deliberately NOT here - see SimClock.
class SimulationState extends ChangeNotifier {
  static const double minFrequency = 20;
  static const double maxFrequency = 2000;

  double _frequency = 440;
  double _amplitude = 0.55;
  AcousticMaterial _medium = Media.air;
  bool _playing = true;
  bool _showGraph = false;
  double _viewWidthM = 2.0;
  ThemeMode _themeMode = ThemeMode.dark;

  double get frequency => _frequency;
  double get amplitude => _amplitude;
  AcousticMaterial get medium => _medium;
  bool get playing => _playing;
  bool get showGraph => _showGraph;
  ThemeMode get themeMode => _themeMode;

  /// lambda = v / f, always computed
  double get wavelengthM => WavePhysics.wavelength(_medium.speedMs, _frequency);

  double get periodMs => WavePhysics.period(_frequency) * 1000;

  String get pitch => WavePhysics.pitchLabel(_frequency);

  /// On-screen oscillation is pinned at 1 Hz, so the slow-motion factor is
  /// just the frequency. 440 Hz plays at 1/440 real time.
  double get apparentHz => 1.0;
  double get slowMotionFactor => _frequency;

  /// Below half a wavelength there is nothing to see; past ten the dots alias.
  double get viewWidthM =>
      _viewWidthM.clamp(0.5 * wavelengthM, 10.0 * wavelengthM);

  double get cyclesInView => wavelengthM <= 0 ? 0 : viewWidthM / wavelengthM;

  /// Wall-clock seconds for a wavefront to cross the canvas, which is what
  /// makes a change of medium visible rather than merely numeric.
  double get crossingSeconds => cyclesInView;

  set frequency(double v) {
    final nv = v.clamp(minFrequency, maxFrequency);
    if (nv == _frequency) return;
    _frequency = nv;
    notifyListeners();
  }

  set amplitude(double v) {
    final nv = v.clamp(0.0, 1.0);
    if (nv == _amplitude) return;
    _amplitude = nv;
    notifyListeners();
  }

  set medium(AcousticMaterial m) {
    if (identical(m, _medium)) return;
    _medium = m;
    notifyListeners();
  }

  set playing(bool v) {
    if (v == _playing) return;
    _playing = v;
    notifyListeners();
  }

  set showGraph(bool v) {
    if (v == _showGraph) return;
    _showGraph = v;
    notifyListeners();
  }

  set themeMode(ThemeMode m) {
    if (m == _themeMode) return;
    _themeMode = m;
    notifyListeners();
  }

  void toggleTheme() {
    themeMode =
        _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
  }

  void togglePlay() => playing = !_playing;

  /// Zoom presets snapshot the current wavelength, so afterwards changing the
  /// frequency really does pack more waves into the same width.
  void zoomTo(double wavelengths) {
    _viewWidthM = (wavelengths * wavelengthM).clamp(0.02, 80.0);
    notifyListeners();
  }

  void reset() {
    _frequency = 440;
    _amplitude = 0.55;
    _medium = Media.air;
    _playing = true;
    _showGraph = false;
    _viewWidthM = 2.0;
    notifyListeners();
  }
}

/// State access without a package.
class SimScope extends InheritedNotifier<SimulationState> {
  const SimScope({
    super.key,
    required SimulationState super.notifier,
    required super.child,
  });

  static SimulationState of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<SimScope>();
    assert(scope != null, 'SimScope is missing above this widget');
    return scope!.notifier!;
  }

  static SimulationState read(BuildContext context) {
    final scope = context.getInheritedWidgetOfExactType<SimScope>();
    assert(scope != null, 'SimScope is missing above this widget');
    return scope!.notifier!;
  }
}
