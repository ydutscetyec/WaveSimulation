import 'package:flutter/material.dart';

import '../../models/acoustic_material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/longitudinal_wave.dart';
import '../../widgets/sim_clock.dart';
import '../../widgets/ui_kit.dart';

class VacuumScreen extends StatefulWidget {
  const VacuumScreen({super.key});

  @override
  State<VacuumScreen> createState() => _VacuumScreenState();
}

class _VacuumScreenState extends State<VacuumScreen> {
  bool _vacuum = false;

  @override
  Widget build(BuildContext context) {
    final medium = _vacuum ? Media.vacuum : Media.air;

    return LabScaffold(
      title: 'Vacuum chamber',
      subtitle: 'Can sound travel through space?',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: _vacuum ? AppColors.stroke : fade(AppColors.cyan, 0.4),
              ),
            ),
            child: Column(
              children: [
                const Row(
                  children: [
                    Icon(Icons.campaign, size: 20, color: AppColors.amber),
                    SizedBox(width: 8),
                    Text(
                      'Bell shaking inside the jar',
                      style: TextStyle(
                        fontSize: 14.5,
                        color: AppColors.textMuted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 190,
                  width: double.infinity,
                  child: ClockHost(
                    hz: 1,
                    builder: (context, clock) => CustomPaint(
                      painter: ParticleFieldPainter(
                        clock: clock,
                        amplitude: 0.6,
                        wavelengthM: 0.78,
                        viewWidthM: 2.0,
                        mediumColor: AppColors.cyan,
                        vacuum: _vacuum,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _Choice(
                  label: 'Air',
                  detail: 'Particles present',
                  selected: !_vacuum,
                  color: AppColors.cyan,
                  onTap: () => setState(() => _vacuum = false),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _Choice(
                  label: 'Vacuum',
                  detail: 'Particles removed',
                  selected: _vacuum,
                  color: AppColors.textMuted,
                  onTap: () => setState(() => _vacuum = true),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Panel(
            accent: _vacuum ? AppColors.amber : AppColors.cyan,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _vacuum
                      ? 'Sound requires a material medium.'
                      : 'The bell is heard.',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                    color: _vacuum ? AppColors.amber : AppColors.cyan,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  _vacuum
                      ? 'The bell is still shaking. There is simply nothing '
                          'next to it to push. A compression needs particles to '
                          'crowd together, and a rarefaction needs particles to '
                          'spread apart - with no particles there is no wave at '
                          'all. Not a faint one. None.'
                      : 'The shaking bell pushes the air beside it, that air '
                          'pushes the next layer, and the disturbance travels '
                          'outward at 343 m/s. The air itself stays where it is; '
                          'only the pattern of crowding moves.',
                  style: const TextStyle(
                    fontSize: 15,
                    color: AppColors.textMuted,
                    height: 1.55,
                  ),
                ),
              ],
            ),
          ),
          Panel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const PanelTitle('Mechanical vs electromagnetic',
                    icon: Icons.compare_arrows),
                const _Line(
                  left: 'Sound',
                  right: 'Mechanical wave. Needs matter. Dies in a vacuum.',
                  color: AppColors.cyan,
                ),
                const _Line(
                  left: 'Light',
                  right: 'Electromagnetic wave. Needs no medium. Crosses space '
                      'perfectly well.',
                  color: AppColors.amber,
                ),
                const SizedBox(height: 10),
                const Text(
                  'That is why you can see a distant explosion in space and '
                  'never hear it, and why film sound effects in space are a '
                  'storytelling choice rather than physics.',
                  style: TextStyle(
                    fontSize: 14.5,
                    color: AppColors.textMuted,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          Panel(
            margin: EdgeInsets.zero,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const PanelTitle('Current medium', icon: Icons.layers_outlined),
                Row(
                  children: [
                    Expanded(
                      child: ValueCard(
                        label: 'Sound speed',
                        value: medium.isVacuum
                            ? 'none'
                            : medium.speedMs.toStringAsFixed(0),
                        unit: medium.isVacuum ? null : 'm/s',
                        color: medium.color,
                        compact: true,
                      ),
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: ValueCard(
                        label: 'Density',
                        value: medium.isVacuum
                            ? '~0'
                            : medium.densityKgM3.toStringAsFixed(1),
                        unit: 'kg/m3',
                        color: AppColors.textMuted,
                        compact: true,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  medium.behaviour,
                  style: const TextStyle(
                    fontSize: 14.5,
                    color: AppColors.textMuted,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 8),
                const Explain(
                  'A real laboratory bell jar never reaches a perfect vacuum, '
                  'so a very faint sound usually remains - and some of it also '
                  'sneaks out through whatever the bell is resting on.',
                  icon: Icons.info_outline,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Choice extends StatelessWidget {
  const _Choice({
    required this.label,
    required this.detail,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  final String label;
  final String detail;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? fade(color, 0.18) : AppColors.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? color : AppColors.stroke,
              width: selected ? 1.8 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: selected ? color : AppColors.textMuted,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                detail,
                style: const TextStyle(fontSize: 13.5, color: AppColors.textDim),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Line extends StatelessWidget {
  const _Line({required this.left, required this.right, required this.color});

  final String left;
  final String right;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 62,
            child: Text(
              left,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ),
          Expanded(
            child: Text(
              right,
              style: const TextStyle(
                fontSize: 14.5,
                color: AppColors.textMuted,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
