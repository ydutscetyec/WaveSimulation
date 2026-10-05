import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../services/wave_physics.dart';
import 'acoustic_material.dart';

/// Shared, lightweight app state. Deliberately a plain ChangeNotifier - no
/// state-management package is justified at this size.
///
/// IMPORTANT: the per-frame animation clock is NOT in here. If it were, every
/// slider label and card would rebuild 60 times a second. See SimClock.
class SimulationState extends ChangeNotifier {
  static const double minFrequency = 20;
  static const double maxFrequency = 2000;

  double _frequency = 440;
  double _amplitude = 0.5;
  AcousticMaterial _medium = Media.air;
  bool _playing = true;
  bool _autoSpeed = true;
  double _apparentHz = 1.0; // on-screen oscillation rate
  double _viewWidthM = 2.0; // physical width the canvas represents
  bool _showGraph = false;

  // progress
  final Set<String> _badges = <String>{};
  double _lowestSeen = 440;
  double _highestSeen = 440;
  int _correct = 0;
  int _wrong = 0;

  // ---- getters ----
  double get frequency => _frequency;
  double get amplitude => _amplitude;
  AcousticMaterial get medium => _medium;
  bool get playing => _playing;
  bool get autoSpeed => _autoSpeed;
  double get apparentHz => _autoSpeed ? 1.0 : _apparentHz;
  bool get showGraph => _showGraph;
  Set<String> get badges => Set.unmodifiable(_badges);
  int get correct => _correct;
  int get wrong => _wrong;
  int get answered => _correct + _wrong;

  /// lambda = v / f, computed, never stored.
  double get wavelengthM => WavePhysics.wavelength(_medium.speedMs, _frequency);

  double get waveNumberK => WavePhysics.waveNumber(wavelengthM);

  double get periodMs => WavePhysics.period(_frequency) * 1000;

  /// Real time is slowed so a 440 Hz vibration is watchable.
  double get slowMotionFactor =>
      WavePhysics.slowMotionFactor(_frequency, apparentHz);

  String get pitch => WavePhysics.pitchLabel(_frequency);

  /// The canvas can only show a sensible picture when it spans between about
  /// half a wavelength and ten wavelengths. Outside that the view auto-zooms,
  /// and [viewClamped] tells the UI to say so instead of hiding it.
  double get viewWidthM {
    final lo = 0.5 * wavelengthM;
    final hi = 10.0 * wavelengthM;
    return _viewWidthM.clamp(lo, hi);
  }

  double get requestedViewWidthM => _viewWidthM;

  bool get viewClamped => (viewWidthM - _viewWidthM).abs() > 1e-6;

  double get cyclesInView => wavelengthM <= 0 ? 0 : viewWidthM / wavelengthM;

  // ---- setters ----
  set frequency(double v) {
    final nv = v.clamp(minFrequency, maxFrequency);
    if (nv == _frequency) return;
    _frequency = nv;
    _lowestSeen = math.min(_lowestSeen, nv);
    _highestSeen = math.max(_highestSeen, nv);
    if (_lowestSeen <= 60 && _highestSeen >= 1500) {
      awardBadge('FREQUENCY MASTER');
    }
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
    if (v) awardBadge('FIRST WAVE');
    notifyListeners();
  }

  set autoSpeed(bool v) {
    if (v == _autoSpeed) return;
    _autoSpeed = v;
    notifyListeners();
  }

  set apparentHz(double v) {
    final nv = v.clamp(0.2, 4.0);
    if (nv == _apparentHz) return;
    _apparentHz = nv;
    notifyListeners();
  }

  set viewWidthM(double v) {
    final nv = v.clamp(0.05, 60.0);
    if (nv == _viewWidthM) return;
    _viewWidthM = nv;
    notifyListeners();
  }

  set showGraph(bool v) {
    if (v == _showGraph) return;
    _showGraph = v;
    notifyListeners();
  }

  void togglePlay() => playing = !_playing;

  /// Fit about four wavelengths into the canvas.
  void autoFitView() {
    viewWidthM = (4 * wavelengthM).clamp(0.05, 60.0);
  }

  void reset() {
    _frequency = 440;
    _amplitude = 0.5;
    _medium = Media.air;
    _playing = true;
    _autoSpeed = true;
    _apparentHz = 1.0;
    _viewWidthM = 2.0;
    _showGraph = false;
    notifyListeners();
  }

  // ---- progress ----
  bool awardBadge(String id) {
    if (_badges.contains(id)) return false;
    _badges.add(id);
    notifyListeners();
    return true;
  }

  void recordAnswer({required bool isCorrect}) {
    if (isCorrect) {
      _correct++;
      if (_correct >= 4) awardBadge('PHYSICS DETECTIVE');
    } else {
      _wrong++;
    }
    notifyListeners();
  }

  void resetScore() {
    _correct = 0;
    _wrong = 0;
    notifyListeners();
  }
}

/// Makes the state available down the tree without a package.
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

  /// Read without subscribing - use inside callbacks.
  static SimulationState read(BuildContext context) {
    final scope = context.getInheritedWidgetOfExactType<SimScope>();
    assert(scope != null, 'SimScope is missing above this widget');
    return scope!.notifier!;
  }
}
