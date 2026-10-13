# Wave Lab v2 — Sound & Acoustics Simulator

Offline Flutter app treating sound as a mechanical longitudinal wave. Particles
move **along** the direction of travel, compression is read from the spatial
derivative of displacement, and every number comes from an equation.

---

## What changed from v1

### Light and dark mode
Colours now live in a `WaveColors` `ThemeExtension` with two complete palettes.
Nothing hard-codes a hex value; widgets and painters read `context.c`. The
toggle is the sun/moon icon in the app bar of every screen.

The light palette is not the dark one inverted. The cyan accent fails contrast
on white, so light mode uses a deep teal (`#0B7C8C`) instead.

### Text visibility
This was the real bug in v1. The old `textDim` (`#6E829E`) was used for body
copy, not just captions, and on the dark navy it sat around 3.9:1 — below the
4.5:1 minimum. Fixes:

- three text roles with enforced contrast: `textPrimary`, `textSecondary`,
  `textTertiary`, the lightest of which still passes AA at 14sp
- body copy never below 14.5sp, and it uses `textSecondary`, never `textTertiary`
- `textTertiary` is now only for captions and labels sitting next to a loud value
- canvas labels take their colour from the palette instead of a fixed grey, so
  they stay readable in light mode

### The simulation is worth watching now
Three additions, all physically honest:

1. **Tracer particle.** One amber particle with its rest position ringed and
   its travel range drawn. It slides back and forth and ends where it started
   while compressions pass through it — the hardest idea in the topic, now
   visible instead of asserted.
2. **Compression bands.** Soft accent bands behind each compression, so the
   pattern is trackable without staring at individual dots. Band positions come
   from `kx − φ = 2πn`, not from decoration.
3. **Wavefront marker.** An amber front crossing the canvas at the scaled wave
   speed. Switching air → water now visibly speeds the wave up instead of only
   changing a number. It rides a real compression: both move at `v/S`.

### Removed
- the badge system and its snackbars
- the auto/manual animation-speed toggle and its slider
- the free-floating view-width slider (now three zoom presets)
- the four-stage progressive-disclosure hint
- the long "about" screens and repeated caveat paragraphs

Four screens' worth of controls became one. 7,000 lines → 5,400.

### CI fixes
`analysis_options.yaml` demotes style lints to info, and the workflow runs
`flutter analyze --no-fatal-infos`. Those two together were what broke build #1.

---

## Build

Push to GitHub and open the Actions tab. The workflow runs analyze → test →
build and uploads `app-release.apk` as an artifact.

Locally (Flutter 3.16+, 3.24+ recommended):

```bash
cp -r lib /tmp/lib_backup && cp -r test /tmp/test_backup
flutter create --platforms=android --project-name wave_lab --org com.wavelab .
rm -rf lib test && cp -r /tmp/lib_backup lib && cp -r /tmp/test_backup test
flutter pub get
flutter analyze --no-fatal-infos
flutter test
flutter build apk --release
```

Output: `build/app/outputs/flutter-apk/app-release.apk`

**Not compiled here.** This machine has no Flutter, Dart or Android SDK and
blocks pub.dev, so the source is unverified by a compiler. CI is the check.

---

## Layout

```
lib/
  main.dart                     entry, theme mode, routes
  theme/wave_theme.dart         WaveColors palettes + ThemeData
  services/wave_physics.dart    every equation (unchanged, still tested)
  models/                       state, materials, objects, quiz
  widgets/
    sim_clock.dart              Ticker clock, repaints only canvases
    wave_canvas.dart            particle painter + graph painter
    ui_kit.dart                 panels, cards, sliders, segmented control
  screens/                      home, simulation, materials, concepts,
                                challenges, about, experiments/ (6)
test/wave_physics_test.dart     28 assertions against the equations
```

## Physics (unchanged)

| Quantity | Equation |
|---|---|
| Wavelength | `λ = v / f` |
| Displacement | `s(x,t) = A sin(kx − ωt)` |
| Compression | `−∂s/∂x = Ak cos(kx − ωt)` |
| Echo | `t = 2d / v` |
| Closed air column | `fₙ = (2n−1)v / 4L` |
| Driven response | `1 / (Q√((1−r²)² + (r/Q)²))` |
| Reflected amplitude | `√(1 − α)` |
| Interference | `Aᵣ = √(A₁² + A₂² + 2A₁A₂cos δ)` |
| Standing wave | `y = 2A sin(kx) cos(ωt)` |

Amplitude is capped at `0.9/k` so strain stays below 1 — beyond that,
neighbouring particles would pass through each other.
