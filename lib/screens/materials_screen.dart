import 'package:flutter/material.dart';

import '../models/acoustic_material.dart';
import '../models/everyday_object.dart';
import '../models/simulation_state.dart';
import '../services/wave_physics.dart';
import '../theme/wave_theme.dart';
import '../widgets/ui_kit.dart';
import 'simulation_screen.dart';

class MaterialsScreen extends StatelessWidget {
  const MaterialsScreen({super.key});

  static const String route = '/materials';

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: c.bg,
        appBar: AppBar(
          title: const Text('Materials'),
          bottom: TabBar(
            indicatorColor: c.accent,
            labelColor: c.accent,
            unselectedLabelColor: c.textTertiary,
            labelStyle: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
            tabs: const [Tab(text: 'Media'), Tab(text: 'Everyday objects')],
          ),
        ),
        body: const SafeArea(
          top: false,
          child: TabBarView(children: [_MediaTab(), _ObjectsTab()]),
        ),
      ),
    );
  }
}

class _MediaTab extends StatelessWidget {
  const _MediaTab();

  @override
  Widget build(BuildContext context) {
    final state = SimScope.of(context);
    final c = context.c;
    return AnimatedBuilder(
      animation: state,
      builder: (context, _) {
        final f = state.frequency;
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
          children: [
            Tip(
              'Every wavelength below is worked out at ${f.toStringAsFixed(0)} Hz, '
              'the frequency left in the simulator. Only v changes between rows.',
              icon: Icons.functions,
            ),
            const SizedBox(height: 14),
            for (final m in Media.all)
              _MediaCard(material: m, frequency: f, state: state),
            Panel(
              margin: EdgeInsets.zero,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const PanelTitle('Why the numbers vary',
                      icon: Icons.warning_amber),
                  Body(
                    'No material has one sound speed. It depends on '
                    'temperature, density, stiffness, moisture, grain '
                    'direction and alloy, and solids carry shear waves at a '
                    'different speed again. These are mid-range teaching '
                    'figures.',
                    color: c.textSecondary,
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _MediaCard extends StatelessWidget {
  const _MediaCard({
    required this.material,
    required this.frequency,
    required this.state,
  });

  final AcousticMaterial material;
  final double frequency;
  final SimulationState state;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final accent = material.accent.of(c);
    final lambda = WavePhysics.wavelength(material.speedMs, frequency);
    final selected = identical(state.medium, material);

    return Panel(
      accent: selected ? accent : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  material.name,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              if (selected)
                Text(
                  'in simulator',
                  style: TextStyle(fontSize: 13, color: accent),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ValueCard(
                  label: 'Speed',
                  value: material.speedMs.toStringAsFixed(0),
                  unit: 'm/s',
                  color: accent,
                  compact: true,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ValueCard(
                  label: 'Density',
                  value: material.densityKgM3 < 10
                      ? material.densityKgM3.toStringAsFixed(1)
                      : material.densityKgM3.toStringAsFixed(0),
                  unit: 'kg/m3',
                  color: c.textSecondary,
                  compact: true,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ValueCard(
                  label: 'Wavelength',
                  value: lambda < 1
                      ? (lambda * 100).toStringAsFixed(1)
                      : lambda.toStringAsFixed(2),
                  unit: lambda < 1 ? 'cm' : 'm',
                  color: c.amber,
                  compact: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Body('${material.note} Impedance Z = ${material.impedanceLabel}.',
              size: 13.5, color: c.textTertiary),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () {
                state.medium = material;
                Navigator.pushNamed(context, SimulationScreen.route);
              },
              child: const Text('Use in simulator'),
            ),
          ),
        ],
      ),
    );
  }
}

class _ObjectsTab extends StatelessWidget {
  const _ObjectsTab();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
      children: [
        const Tip(
          'Each object is something you can find at home, and each one maps '
          'onto a control in the simulator.',
          icon: Icons.handyman_outlined,
        ),
        const SizedBox(height: 14),
        for (final o in EverydayObjects.all) _ObjectTile(object: o),
      ],
    );
  }
}

class _ObjectTile extends StatelessWidget {
  const _ObjectTile({required this.object});

  final EverydayObject object;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Panel(
      padding: EdgeInsets.zero,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          iconColor: c.accent,
          collapsedIconColor: c.textTertiary,
          leading: Icon(object.icon, color: c.accent, size: 26),
          title: Text(
            object.name,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          subtitle: Text(
            object.linkedParameter,
            style: TextStyle(fontSize: 13.5, color: c.textTertiary),
          ),
          children: [
            Body(object.vibrates, color: c.textPrimary),
            const SizedBox(height: 10),
            Tip(object.observe, icon: Icons.visibility_outlined),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: c.surfaceAlt,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: c.stroke),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.science, size: 19, color: c.amber),
                      const SizedBox(width: 8),
                      Text(
                        'Try it yourself',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: c.amber,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _Heading('You need', color: c.textSecondary),
                  for (final m in object.materials)
                    Body('·  $m', size: 14.5, color: c.textPrimary),
                  const SizedBox(height: 10),
                  _Heading('Steps', color: c.textSecondary),
                  for (var i = 0; i < object.steps.length; i++)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 5),
                      child: Body('${i + 1}.  ${object.steps[i]}',
                          size: 14.5, color: c.textPrimary),
                    ),
                  const SizedBox(height: 10),
                  _Heading('Why it happens', color: c.textSecondary),
                  Body(object.why, color: c.textPrimary),
                  if (object.safety != null) ...[
                    const SizedBox(height: 10),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.shield_outlined, size: 18, color: c.red),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Body(object.safety!, size: 14, color: c.red),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {
                  final state = SimScope.read(context);
                  if (object.suggestedFrequency != null) {
                    state.frequency = object.suggestedFrequency!;
                  }
                  Navigator.pushNamed(context, SimulationScreen.route);
                },
                child: const Text('Open in simulator'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Heading extends StatelessWidget {
  const _Heading(this.text, {required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}
