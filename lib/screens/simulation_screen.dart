import 'package:flutter/material.dart';

import '../models/acoustic_material.dart';
import '../models/simulation_state.dart';
import '../theme/wave_theme.dart';
import '../widgets/sim_clock.dart';
import '../widgets/ui_kit.dart';
import '../widgets/wave_canvas.dart';

class SimulationScreen extends StatelessWidget {
  const SimulationScreen({super.key});

  static const String route = '/simulation';

  static const List<(double, String)> _presets = [
    (20.0, '20 Hz'),
    (100.0, '100'),
    (440.0, '440'),
    (1000.0, '1 kHz'),
    (2000.0, '2 kHz'),
  ];

  @override
  Widget build(BuildContext context) {
    final state = SimScope.of(context);
    final c = context.c;
    final mq = MediaQuery.of(context);
    final canvasH = (mq.size.height * 0.30).clamp(190.0, 320.0);

    return AnimatedBuilder(
      animation: state,
      builder: (context, _) {
        final accent = state.medium.accent.of(c);
        final lambda = state.wavelengthM;

        return LabScaffold(
          title: 'Simulation',
          subtitle: '${state.medium.name} · '
              '${state.cyclesInView.toStringAsFixed(1)} waves on screen',
          actions: [
            IconButton(
              tooltip: state.showGraph ? 'Hide graph' : 'Show graph',
              icon: Icon(state.showGraph
                  ? Icons.show_chart
                  : Icons.show_chart_outlined),
              onPressed: () => state.showGraph = !state.showGraph,
            ),
            ThemeToggle(
              isDark: state.themeMode == ThemeMode.dark,
              onTap: state.toggleTheme,
            ),
          ],
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ---- canvas ----
              SizedBox(
                height: canvasH,
                width: double.infinity,
                child: ClockHost(
                  hz: state.apparentHz,
                  timeRate: 1 / state.slowMotionFactor,
                  running: state.playing,
                  builder: (context, clock) => CustomPaint(
                    painter: WavePainter(
                      clock: clock,
                      colors: c,
                      amplitude: state.amplitude,
                      wavelengthM: lambda,
                      viewWidthM: state.viewWidthM,
                      accent: accent,
                      speedMs: state.medium.speedMs,
                    ),
                  ),
                ),
              ),
              if (state.showGraph) ...[
                const SizedBox(height: 10),
                Container(
                  height: 86,
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  decoration: BoxDecoration(
                    color: c.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: c.stroke),
                  ),
                  child: ClockHost(
                    hz: state.apparentHz,
                    running: state.playing,
                    builder: (context, clock) => CustomPaint(
                      painter: GraphPainter(
                        clock: clock,
                        colors: c,
                        amplitude: state.amplitude,
                        wavelengthM: lambda,
                        viewWidthM: state.viewWidthM,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Body(
                  'Graph only. Cyan is displacement, amber is pressure. Air '
                  'does not ripple up and down like this.',
                  size: 13.5,
                  color: c.textTertiary,
                ),
              ],
              const SizedBox(height: 12),

              // ---- transport ----
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(52),
                        backgroundColor:
                            state.playing ? fade(c.accent, 0.18) : c.accent,
                        foregroundColor:
                            state.playing ? c.accent : c.onAccent,
                      ),
                      onPressed: state.togglePlay,
                      icon: Icon(
                          state.playing ? Icons.pause : Icons.play_arrow),
                      label: Text(state.playing ? 'Pause' : 'Play'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(52),
                        foregroundColor: c.textPrimary,
                        side: BorderSide(color: c.stroke),
                      ),
                      onPressed: state.reset,
                      child: const Icon(Icons.restart_alt),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // ---- readouts ----
              Panel(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 13),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    LayoutBuilder(
                      builder: (context, box) {
                        final cols = box.maxWidth > 430 ? 4 : 2;
                        final w = (box.maxWidth - (cols - 1) * 10) / cols;
                        return Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            SizedBox(
                              width: w,
                              child: ValueCard(
                                label: 'Frequency',
                                value: state.frequency.toStringAsFixed(0),
                                unit: 'Hz',
                              ),
                            ),
                            SizedBox(
                              width: w,
                              child: ValueCard(
                                label: 'Wavelength',
                                value: lambda < 1
                                    ? (lambda * 100).toStringAsFixed(1)
                                    : lambda.toStringAsFixed(2),
                                unit: lambda < 1 ? 'cm' : 'm',
                                color: c.amber,
                              ),
                            ),
                            SizedBox(
                              width: w,
                              child: ValueCard(
                                label: 'Wave speed',
                                value: state.medium.speedMs.toStringAsFixed(0),
                                unit: 'm/s',
                                color: accent,
                              ),
                            ),
                            SizedBox(
                              width: w,
                              child: ValueCard(
                                label: 'Pitch',
                                value: state.pitch,
                                color: c.blue,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'lambda = v / f = ${state.medium.speedMs.toStringAsFixed(0)}'
                      ' / ${state.frequency.toStringAsFixed(0)}'
                      ' = ${lambda.toStringAsFixed(lambda < 1 ? 3 : 2)} m',
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        color: c.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Body(
                      'Slow motion 1 : ${state.slowMotionFactor.toStringAsFixed(0)}. '
                      'The amber marker is a wavefront and crosses the screen '
                      'in ${state.crossingSeconds.toStringAsFixed(1)} s.',
                      size: 13.5,
                      color: c.textTertiary,
                    ),
                  ],
                ),
              ),

              // ---- controls ----
              Panel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    StepSlider(
                      label: 'Frequency',
                      value: state.frequency,
                      min: SimulationState.minFrequency,
                      max: SimulationState.maxFrequency,
                      step: 10,
                      readout: '${state.frequency.toStringAsFixed(0)} Hz',
                      onChanged: (v) => state.frequency = v,
                    ),
                    const SizedBox(height: 4),
                    ChipRow<double>(
                      items: _presets.map((p) => p.$1).toList(),
                      labelOf: (v) =>
                          _presets.firstWhere((p) => p.$1 == v).$2,
                      selected: _presets
                              .map((p) => p.$1)
                              .contains(state.frequency.roundToDouble())
                          ? state.frequency.roundToDouble()
                          : null,
                      onSelect: (v) => state.frequency = v,
                    ),
                    const SizedBox(height: 16),
                    StepSlider(
                      label: 'Amplitude',
                      value: state.amplitude,
                      min: 0,
                      max: 1,
                      step: 0.05,
                      color: c.blue,
                      readout: state.amplitude.toStringAsFixed(2),
                      onChanged: (v) => state.amplitude = v,
                    ),
                    const SizedBox(height: 6),
                    Body(
                      'Amplitude is loudness. The wavelength above does not '
                      'move while you drag it.',
                      size: 13.5,
                      color: c.textTertiary,
                    ),
                  ],
                ),
              ),

              Panel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const PanelTitle('Medium', icon: Icons.layers_outlined),
                    ChipRow<AcousticMaterial>(
                      items: Media.all,
                      labelOf: (m) => m.name,
                      colorOf: (m, cc) => m.accent.of(cc),
                      selected: state.medium,
                      onSelect: (m) => state.medium = m,
                    ),
                    const SizedBox(height: 11),
                    Body(state.medium.note, size: 13.5, color: c.textTertiary),
                  ],
                ),
              ),

              Panel(
                margin: EdgeInsets.zero,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const PanelTitle('Zoom', icon: Icons.zoom_out_map),
                    Segmented(
                      labels: const ['Close', 'Normal', 'Wide'],
                      selectedIndex: state.cyclesInView < 2.5
                          ? 0
                          : (state.cyclesInView < 6.5 ? 1 : 2),
                      onSelect: (i) =>
                          state.zoomTo(i == 0 ? 1.5 : (i == 1 ? 4 : 9)),
                    ),
                    const SizedBox(height: 10),
                    Body(
                      'Zoom fixes a real width in metres, shown by the scale '
                      'bar. Raise the frequency afterwards and more waves fit '
                      'into the same space.',
                      size: 13.5,
                      color: c.textTertiary,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
