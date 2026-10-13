import 'package:flutter/material.dart';

import '../models/acoustic_material.dart';
import '../models/everyday_object.dart';
import '../models/simulation_state.dart';
import '../services/wave_physics.dart';
import '../theme/palette.dart';
import '../widgets/ui_kit.dart';
import 'simulation_screen.dart';

class MaterialLabScreen extends StatelessWidget {
  const MaterialLabScreen({super.key});

  static const String route = '/materials';

  @override
  Widget build(BuildContext context) {
    final p = pal(context);
    return DefaultTabController(
      length: 2,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [p.bg, p.bgDeep],
          ),
        ),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            title: const Text('Materials'),
            actions: const [ThemeToggle(), SizedBox(width: 4)],
            bottom: TabBar(
              indicatorColor: p.accent,
              labelColor: p.accent,
              unselectedLabelColor: p.textMuted,
              labelStyle:
                  const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w700),
              tabs: const [
                Tab(text: 'Media'),
                Tab(text: 'Everyday objects'),
              ],
            ),
          ),
          body: const SafeArea(
            top: false,
            child: TabBarView(children: [_MediaTab(), _ObjectsTab()]),
          ),
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
    return AnimatedBuilder(
      animation: state,
      builder: (context, _) {
        final f = state.frequency;
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
          children: [
            Explain(
              'Each wavelength below is worked out at '
              '${f.toStringAsFixed(0)} Hz, the frequency left in the '
              'simulator. The source shakes the same in all of them; only v '
              'changes.',
              icon: Icons.functions,
            ),
            const SizedBox(height: 14),
            for (final m in Media.all) _MediaCard(material: m, frequency: f),
            const Panel(
              margin: EdgeInsets.zero,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  PanelTitle('Why these are approximate',
                      icon: Icons.warning_amber),
                  Body(
                    'No material has one sound speed. It shifts with '
                    'temperature, density, stiffness, moisture, grain '
                    'direction and alloy, and in solids it differs for '
                    'longitudinal and shear waves.',
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
  const _MediaCard({required this.material, required this.frequency});

  final AcousticMaterial material;
  final double frequency;

  @override
  Widget build(BuildContext context) {
    final p = pal(context);
    final state = SimScope.of(context);
    final lambda = WavePhysics.wavelength(material.speedMs, frequency);
    final selected = identical(state.medium, material);
    final c = material.color(p);

    return Panel(
      accent: selected ? c : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(color: c, shape: BoxShape.circle),
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
                  style: TextStyle(fontSize: 13.5, color: c),
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
                  color: c,
                  compact: true,
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: ValueCard(
                  label: 'Density',
                  value: material.densityKgM3 < 10
                      ? material.densityKgM3.toStringAsFixed(1)
                      : material.densityKgM3.toStringAsFixed(0),
                  unit: 'kg/m3',
                  color: p.textMuted,
                  compact: true,
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: ValueCard(
                  label: 'Wavelength',
                  value: lambda < 1
                      ? (lambda * 100).toStringAsFixed(1)
                      : lambda.toStringAsFixed(2),
                  unit: lambda < 1 ? 'cm' : 'm',
                  color: p.warm,
                  compact: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Body(material.behaviour),
          const SizedBox(height: 8),
          Body(
            'Impedance Z = rho x v = ${material.impedanceLabel}. '
            '${material.note}',
            size: 13.5,
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () {
                state.medium = material;
                Navigator.pushNamed(context, SimulationScreen.route);
              },
              icon: const Icon(Icons.graphic_eq, size: 18),
              label: const Text('Use in simulator'),
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
        const Explain(
          'From real life to simulation. Everything here is in your house '
          'today, and each one maps onto a control in the simulator.',
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
    final p = pal(context);
    return Panel(
      padding: EdgeInsets.zero,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          iconColor: p.accent,
          collapsedIconColor: p.textMuted,
          leading: Icon(object.icon, color: p.accent, size: 26),
          title:
              Text(object.name, style: Theme.of(context).textTheme.titleMedium),
          subtitle: Text(
            'Linked control: ${object.linkedParameter}',
            style: TextStyle(fontSize: 14, color: p.textFaint),
          ),
          children: [
            _step(p, 'How it vibrates', object.howItVibrates, Icons.vibration),
            _step(p, 'How sound is produced', object.howSoundIsProduced,
                Icons.waves),
            _step(p, 'What to look for', object.whatToObserve,
                Icons.visibility_outlined),
            const SizedBox(height: 12),
            _tryIt(context, p),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () {
                  final state = SimScope.read(context);
                  if (object.suggestedFrequency != null) {
                    state.frequency = object.suggestedFrequency!;
                  }
                  Navigator.pushNamed(context, SimulationScreen.route);
                },
                icon: const Icon(Icons.graphic_eq, size: 18),
                label: const Text('Open in simulator'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _step(Pal p, String heading, String body, IconData icon) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 18, color: p.blue),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    heading,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: p.textFaint,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    body,
                    style:
                        TextStyle(fontSize: 15, height: 1.45, color: p.text),
                  ),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _tryIt(BuildContext context, Pal p) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: p.surfaceHigh,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: p.stroke),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.science, size: 19, color: p.warm),
              const SizedBox(width: 8),
              Text(
                'Try it yourself',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: p.warm,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _heading(p, 'Materials'),
          for (final m in object.materials)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 5,
                    height: 5,
                    margin: const EdgeInsets.only(top: 9, right: 10),
                    decoration:
                        BoxDecoration(color: p.textFaint, shape: BoxShape.circle),
                  ),
                  Expanded(
                    child: Text(
                      m,
                      style: TextStyle(
                          fontSize: 15, height: 1.45, color: p.text),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 10),
          _heading(p, 'Steps'),
          for (var i = 0; i < object.steps.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 7),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 23,
                    height: 23,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: fade(p.accent, p.isDark ? 0.2 : 0.14),
                      borderRadius: BorderRadius.circular(7),
                    ),
                    child: Text(
                      '${i + 1}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: p.accent,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      object.steps[i],
                      style:
                          TextStyle(fontSize: 15, height: 1.45, color: p.text),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 10),
          _heading(p, 'Why it happens'),
          Body(object.why, muted: false),
          if (object.safety != null) ...[
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.shield_outlined, size: 18, color: p.danger),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    object.safety!,
                    style: TextStyle(
                      fontSize: 14.5,
                      height: 1.45,
                      color: p.danger,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _heading(Pal p, String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 14.5,
            fontWeight: FontWeight.w700,
            color: p.textMuted,
          ),
        ),
      );
}
