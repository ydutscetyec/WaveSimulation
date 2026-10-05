import 'package:flutter/material.dart';

import '../models/acoustic_material.dart';
import '../models/simulation_state.dart';
import '../theme/app_theme.dart';
import '../widgets/longitudinal_wave.dart';
import '../widgets/sim_clock.dart';
import '../widgets/ui_kit.dart';

class SimulationScreen extends StatefulWidget {
  const SimulationScreen({super.key});

  static const String route = '/simulation';

  @override
  State<SimulationScreen> createState() => _SimulationScreenState();
}

class _SimulationScreenState extends State<SimulationScreen> {
  // Progressive disclosure: one instruction at a time, in the order a student
  // should discover them. Showing v = f*lambda on arrival teaches nobody.
  int _stage = 0;

  static const List<(double, String)> _presets = [
    (20.0, '20 Hz'),
    (100.0, '100 Hz'),
    (440.0, '440 Hz'),
    (1000.0, '1 kHz'),
    (2000.0, '2 kHz'),
  ];

  void _advanceStage(int to) {
    if (_stage < to) setState(() => _stage = to);
  }

  @override
  Widget build(BuildContext context) {
    final state = SimScope.of(context);
    final mq = MediaQuery.of(context);
    final canvasHeight = (mq.size.height * 0.27).clamp(170.0, 280.0);

    return LabScaffold(
      title: 'Sound wave simulation',
      subtitle: 'Source  ->  medium  ->  receiver',
      actions: [
        IconButton(
          tooltip: 'Reset',
          icon: const Icon(Icons.restart_alt),
          onPressed: () {
            state.reset();
            setState(() => _stage = 0);
          },
        ),
      ],
      child: AnimatedBuilder(
        animation: state,
        builder: (context, _) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _canvas(state, canvasHeight),
              const SizedBox(height: 12),
              _hint(),
              const SizedBox(height: 12),
              _readouts(state),
              _frequencyPanel(state),
              _amplitudePanel(state),
              _mediumPanel(state),
              _viewPanel(state),
              _transportPanel(state),
            ],
          );
        },
      ),
    );
  }

  // ---------------------------------------------------------------- canvas
  Widget _canvas(SimulationState state, double height) {
    return Column(
      children: [
        SizedBox(
          height: height,
          width: double.infinity,
          child: ClockHost(
            hz: state.apparentHz,
            running: state.playing,
            builder: (context, clock) => CustomPaint(
              painter: ParticleFieldPainter(
                clock: clock,
                amplitude: state.amplitude,
                wavelengthM: state.wavelengthM,
                viewWidthM: state.viewWidthM,
                mediumColor: state.medium.color,
              ),
            ),
          ),
        ),
        if (state.showGraph) ...[
          const SizedBox(height: 10),
          SizedBox(
            height: 96,
            width: double.infinity,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Container(
                color: AppColors.surface,
                child: ClockHost(
                  hz: state.apparentHz,
                  running: state.playing,
                  builder: (context, clock) => CustomPaint(
                    painter: WaveGraphPainter(
                      clock: clock,
                      amplitude: state.amplitude,
                      wavelengthM: state.wavelengthM,
                      viewWidthM: state.viewWidthM,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Graph view only: cyan is particle displacement, amber is pressure. '
            'Air does not actually ripple up and down like this.',
            style: TextStyle(fontSize: 13, color: AppColors.textDim, height: 1.35),
          ),
        ],
      ],
    );
  }

  // ------------------------------------------------------------------ hint
  Widget _hint() {
    const texts = [
      'Drag the frequency slider and keep an eye on the particles.',
      'The wavelength readout is falling. Count the compressions - there are '
          'more of them in the same space now.',
      'That is lambda = v / f. The medium fixes v, so raising f can only '
          'shorten lambda.',
      'Now change the medium. The speed v jumps, so lambda jumps with it - '
          'even though the source is still shaking at the same rate.',
    ];
    return Explain(
      texts[_stage.clamp(0, texts.length - 1)],
      icon: _stage == 0 ? Icons.touch_app : Icons.lightbulb_outline,
      color: _stage >= 2 ? AppColors.amber : AppColors.blue,
    );
  }

  // -------------------------------------------------------------- readouts
  Widget _readouts(SimulationState state) {
    final m = state.medium;
    final lambda = state.wavelengthM;
    return Panel(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, c) {
              final cols = c.maxWidth > 420 ? 4 : 2;
              final w = (c.maxWidth - (cols - 1) * 10) / cols;
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
                      value: _fmtLength(lambda),
                      unit: lambda < 1 ? 'cm' : 'm',
                      color: AppColors.amber,
                    ),
                  ),
                  SizedBox(
                    width: w,
                    child: ValueCard(
                      label: 'Wave speed',
                      value: m.speedMs.toStringAsFixed(0),
                      unit: 'm/s',
                      color: m.color,
                    ),
                  ),
                  SizedBox(
                    width: w,
                    child: ValueCard(
                      label: 'Amplitude',
                      value: state.amplitude.toStringAsFixed(2),
                      color: AppColors.blue,
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 11),
          Row(
            children: [
              _MiniStat(label: 'Medium', value: m.name),
              _MiniStat(label: 'Pitch', value: state.pitch),
              _MiniStat(
                label: 'Period',
                value: '${state.periodMs.toStringAsFixed(2)} ms',
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'lambda = v / f  =  ${m.speedMs.toStringAsFixed(0)} / '
            '${state.frequency.toStringAsFixed(0)}  =  '
            '${lambda.toStringAsFixed(lambda < 1 ? 3 : 2)} m',
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textMuted,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  static String _fmtLength(double m) =>
      m < 1 ? (m * 100).toStringAsFixed(1) : m.toStringAsFixed(2);

  // ------------------------------------------------------------- frequency
  Widget _frequencyPanel(SimulationState state) {
    return Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const PanelTitle('Frequency', icon: Icons.speed),
          StepSlider(
            label: 'How many times per second the source shakes',
            value: state.frequency,
            min: SimulationState.minFrequency,
            max: SimulationState.maxFrequency,
            step: 10,
            readout: '${state.frequency.toStringAsFixed(0)} Hz',
            onChanged: (v) {
              state.frequency = v;
              _advanceStage(1);
              if (state.frequency > 900 || state.frequency < 80) {
                _advanceStage(2);
              }
            },
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
            onSelect: (v) {
              state.frequency = v;
              _advanceStage(2);
            },
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------- amplitude
  Widget _amplitudePanel(SimulationState state) {
    return Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const PanelTitle('Amplitude', icon: Icons.volume_up_outlined),
          StepSlider(
            label: 'How far each particle moves from its rest position',
            value: state.amplitude,
            min: 0,
            max: 1,
            step: 0.05,
            color: AppColors.blue,
            readout: state.amplitude.toStringAsFixed(2),
            onChanged: (v) => state.amplitude = v,
          ),
          const SizedBox(height: 6),
          const Text(
            'Amplitude sets loudness. The wavelength readout above does not '
            'move while you drag this - pitch belongs to frequency alone.',
            style: TextStyle(fontSize: 14, color: AppColors.textDim, height: 1.4),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------- medium
  Widget _mediumPanel(SimulationState state) {
    return Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const PanelTitle('Medium', icon: Icons.layers_outlined),
          ChipRow<AcousticMaterial>(
            items: Media.all,
            labelOf: (m) => m.name,
            colorOf: (m) => m.color,
            selected: state.medium,
            onSelect: (m) {
              state.medium = m;
              _advanceStage(3);
            },
          ),
          const SizedBox(height: 10),
          Text(
            state.medium.behaviour,
            style: const TextStyle(
              fontSize: 14.5,
              color: AppColors.textMuted,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Approximate teaching value. ${state.medium.note}',
            style: const TextStyle(fontSize: 13, color: AppColors.textDim, height: 1.4),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------------ view
  Widget _viewPanel(SimulationState state) {
    return Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PanelTitle(
            'View scale',
            icon: Icons.zoom_out_map,
            trailing: TextButton(
              onPressed: state.autoFitView,
              child: const Text('Fit 4 waves'),
            ),
          ),
          StepSlider(
            label: 'Real width the canvas represents',
            value: state.requestedViewWidthM.clamp(0.05, 20.0),
            min: 0.05,
            max: 20,
            step: 0.25,
            color: AppColors.textMuted,
            readout: '${state.viewWidthM.toStringAsFixed(2)} m',
            onChanged: (v) => state.viewWidthM = v,
          ),
          Text(
            '${state.cyclesInView.toStringAsFixed(1)} full waves across the '
            'screen.',
            style: const TextStyle(fontSize: 14, color: AppColors.textMuted),
          ),
          if (state.viewClamped) ...[
            const SizedBox(height: 8),
            const Explain(
              'The view auto-zoomed. Below half a wavelength there is nothing '
              'to see, and past ten wavelengths the dots are too dense to read. '
              'The scale bar under the canvas always shows the real distance.',
              icon: Icons.info_outline,
            ),
          ],
        ],
      ),
    );
  }

  // ------------------------------------------------------------- transport
  Widget _transportPanel(SimulationState state) {
    return Panel(
      margin: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const PanelTitle('Playback', icon: Icons.play_circle_outline),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                    backgroundColor: state.playing
                        ? fade(AppColors.cyan, 0.2)
                        : AppColors.cyan,
                    foregroundColor:
                        state.playing ? AppColors.cyan : const Color(0xFF042026),
                  ),
                  onPressed: () {
                    final had = state.badges.contains('FIRST WAVE');
                    state.togglePlay();
                    if (!had && state.badges.contains('FIRST WAVE')) {
                      showBadge(context, 'FIRST WAVE');
                    }
                  },
                  icon: Icon(state.playing ? Icons.pause : Icons.play_arrow),
                  label: Text(state.playing ? 'Pause' : 'Play'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                    foregroundColor: AppColors.text,
                    side: const BorderSide(color: AppColors.stroke),
                  ),
                  onPressed: () {
                    state.reset();
                    setState(() => _stage = 0);
                  },
                  icon: const Icon(Icons.restart_alt),
                  label: const Text('Reset'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Animation speed',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textMuted,
                  ),
                ),
              ),
              _Toggle(
                left: 'Auto',
                right: 'Manual',
                rightSelected: !state.autoSpeed,
                onChanged: (rightSel) => state.autoSpeed = !rightSel,
              ),
            ],
          ),
          if (!state.autoSpeed) ...[
            const SizedBox(height: 6),
            StepSlider(
              label: 'On-screen oscillation rate',
              value: state.apparentHz,
              min: 0.2,
              max: 4,
              step: 0.2,
              color: AppColors.textMuted,
              readout: '${state.apparentHz.toStringAsFixed(1)} /s',
              onChanged: (v) => state.apparentHz = v,
            ),
          ],
          const SizedBox(height: 8),
          Text(
            'Slow motion 1 : ${state.slowMotionFactor.toStringAsFixed(0)}. A '
            'real ${state.frequency.toStringAsFixed(0)} Hz vibration is far too '
            'fast for any screen, so time is stretched. Every number above is '
            'still the real-world value.',
            style: const TextStyle(
              fontSize: 13.5,
              color: AppColors.textDim,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 12),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            dense: true,
            value: state.showGraph,
            activeThumbColor: AppColors.cyan,
            onChanged: (v) => state.showGraph = v,
            title: const Text(
              'Show graph view',
              style: TextStyle(fontSize: 15, color: AppColors.text),
            ),
            subtitle: const Text(
              'Displacement and pressure plotted against position',
              style: TextStyle(fontSize: 13, color: AppColors.textDim),
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 13, color: AppColors.textDim),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.text,
            ),
          ),
        ],
      ),
    );
  }
}

class _Toggle extends StatelessWidget {
  const _Toggle({
    required this.left,
    required this.right,
    required this.rightSelected,
    required this.onChanged,
  });

  final String left;
  final String right;
  final bool rightSelected;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    Widget seg(String text, bool selected, VoidCallback onTap) => InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
            decoration: BoxDecoration(
              color: selected ? fade(AppColors.cyan, 0.2) : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.w600,
                color: selected ? AppColors.cyan : AppColors.textDim,
              ),
            ),
          ),
        );

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppColors.surfaceHigh,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: AppColors.stroke),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          seg(left, !rightSelected, () => onChanged(false)),
          seg(right, rightSelected, () => onChanged(true)),
        ],
      ),
    );
  }
}
