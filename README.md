# Wave Lab — Sound & Acoustics Simulator

An offline Flutter app that treats sound as what it is: a mechanical longitudinal
wave. Particles move **along** the direction of travel, compressions and
rarefactions are read off the spatial derivative of the displacement, and every
displayed number comes from an equation rather than a lookup table.

Built around everyday materials — rubber band, cup and string, metal spoon,
glass of water, cardboard box, cloth and foam.

---

## Build status, stated honestly

The Dart source is complete. **It has not been compiled**, because the machine it
was written on has no Flutter SDK, no Dart SDK and no Android SDK, and its
network blocks `pub.dev`, `storage.googleapis.com` and `dl.google.com`. No APK
was produced here and none is claimed.

Two ways to get an APK:

### Option A — GitHub Actions (no installs on your machine)

1. Create a new GitHub repository.
2. Upload this whole folder, including `.github/workflows/build-apk.yml`.
3. Open the **Actions** tab. The build starts on push, or press **Run workflow**.
4. When the job goes green, download `wave-lab-release-apk` from the run's
   **Artifacts** section and install it on the phone.

The workflow runs `flutter analyze`, `flutter test` and
`flutter build apk --release`. If any of them fails, the log names the file and
line.

### Option B — Local build

Requires Flutter **3.16 or newer** (3.24+ recommended) and the Android SDK.

```bash
# 1. Generate the android/ scaffolding for your Flutter version
cd wave_lab
cp -r lib /tmp/lib_backup && cp -r test /tmp/test_backup
flutter create --platforms=android --project-name wave_lab --org com.wavelab .
rm -rf lib test && cp -r /tmp/lib_backup lib && cp -r /tmp/test_backup test

# 2. Build
flutter pub get
flutter analyze
flutter test
flutter build apk --release
```

Output: `build/app/outputs/flutter-apk/app-release.apk`

`android/` is generated rather than committed on purpose. A hand-written Gradle
project pins Gradle, AGP and Kotlin versions that go stale within months and then
fail in ways that have nothing to do with this app.

---

## Why there are no third-party packages

`pubspec.yaml` depends on the Flutter SDK and nothing else.

- The app is guaranteed offline.
- Nothing breaks when a package publishes a breaking version.
- Smaller APK, faster cold start.
- State is a plain `ChangeNotifier` plus `InheritedNotifier`, which is all a
  project this size needs.

---

## Project layout

```
lib/
  main.dart                      app entry, state ownership, routes
  models/
    simulation_state.dart        ChangeNotifier + SimScope (InheritedNotifier)
    acoustic_material.dart       media and wall surfaces with their constants
    everyday_object.dart         real objects, experiments, safety notes
    challenge_model.dart         quiz bank
  services/
    wave_physics.dart            every equation, in one testable place
  widgets/
    sim_clock.dart               Ticker-driven clock, repaints only canvases
    longitudinal_wave.dart       particle field painter + graph painter
    ui_kit.dart                  panels, value cards, sliders, buttons
  screens/
    home_screen.dart
    simulation_screen.dart       the main laboratory
    material_lab_screen.dart     media tab + everyday objects tab
    concepts_screen.dart
    challenge_screen.dart
    about_screen.dart
    experiments/
      experiments_screen.dart    hub
      reflection_screen.dart
      echo_screen.dart
      resonance_screen.dart
      interference_screen.dart
      standing_wave_screen.dart
      vacuum_screen.dart
test/
  wave_physics_test.dart         28 assertions against the equations
branding/
  wave_lab_icon_*.png            app icon concept
```

---

## Physics implemented

| Quantity | Equation | Where |
|---|---|---|
| Wavelength | `λ = v / f` | every screen, computed live |
| Particle displacement | `s(x,t) = A sin(kx − ωt + φ)` | particle field |
| Compression / rarefaction | `−∂s/∂x = Ak cos(kx − ωt)` | particle colour and size |
| Wave number, angular frequency | `k = 2π/λ`, `ω = 2πf` | all painters |
| Echo delay | `t = 2d / v` | echo experiment |
| Closed air column | `fₙ = (2n−1)v / 4L` | resonance |
| Open air column | `fₙ = n v / 2L` | resonance notes |
| Driven damped response | `A(f)/Aₘₐₓ = 1 / (Q√((1−r²)² + (r/Q)²))` | resonance |
| Reflected amplitude | `√(1 − α)` | reflection |
| Acoustic impedance | `Z = ρv` | material lab |
| Two-source interference | `Aᵣ = √(A₁² + A₂² + 2A₁A₂cos δ)` | interference map |
| Standing wave | `y = 2A sin(kx) cos(ωt)` | standing waves |

### Two deliberate scaling decisions, both shown on screen

1. **Slow motion.** A 440 Hz vibration cannot be drawn at 60 fps. Time is
   stretched and the factor is printed (`Slow motion 1 : 440`). Every physical
   value displayed is the real one.
2. **View scale.** The canvas represents a real width in metres, drawn as a
   scale bar. It auto-zooms only outside 0.5λ–10λ, and the app says when it
   does. Raising the frequency at a fixed scale therefore really does pack more
   compressions into the same space.

### Amplitude is capped by physics, not by taste

Displacement amplitude is limited to `0.9/k`, i.e. strain < 1. Beyond that,
neighbouring particles would pass through each other, which is physically
meaningless.

---

## Performance notes

- All drawing is `CustomPainter` on `Canvas`. There is no widget per particle.
- The animation clock is a separate `ChangeNotifier` passed to painters as
  `super(repaint: clock)`. The widget tree is **not** rebuilt per frame — only
  the canvas repaints.
- Phase is integrated (`phase += 2πf·dt`), so changing the speed mid-animation
  does not make the wave jump.
- The interference field is a static amplitude map, so it is computed once into a
  `ui.Image` on parameter change rather than per frame.
- Particle counts are capped (≤ 120 columns × 9 rows) regardless of screen size.

---

## What this app does not do

- No audio output. It shows what a wave does; your ears and the real experiments
  supply the sound.
- Material speeds are mid-range values near 20 °C, labelled as approximate.
- Solids are given one longitudinal speed; real solids also carry shear waves.
- Absorption coefficients are single mid-frequency figures.
- The resonance model ignores end correction, so a real cup rings slightly lower
  than predicted.
- Amplitude is a relative 0–1 scale, not calibrated to decibels.

---

## App icon

`branding/wave_lab_icon_1024.png` is the concept art: a vibrating plate and
wavefronts whose spacing is uneven, because that spacing is the compression.

To apply it, open the generated project in Android Studio and use
**File → New → Image Asset**, or add `flutter_launcher_icons` to
`dev_dependencies` — note that the second option requires network access to
pub.dev at build time.
