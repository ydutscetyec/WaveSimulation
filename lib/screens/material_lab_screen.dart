import 'package:flutter/material.dart';

import '../models/acoustic_material.dart';
import '../models/everyday_object.dart';
import '../models/simulation_state.dart';
import '../services/wave_physics.dart';
import '../theme/app_theme.dart';
import '../widgets/ui_kit.dart';
import 'simulation_screen.dart';

class MaterialLabScreen extends StatelessWidget {
  const MaterialLabScreen({super.key});

  static const String route = '/materials';

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.bg, AppColors.bgDeep],
          ),
        ),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            title: const Text('Material lab'),
            bottom: const TabBar(
              indicatorColor: AppColors.cyan,
              labelColor: AppColors.cyan,
              unselectedLabelColor: AppColors.textDim,
              labelStyle: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
              tabs: [
                Tab(text: 'Media'),
                Tab(text: 'Everyday objects'),
              ],
            ),
          ),
          body: const SafeArea(
            top: false,
            child: TabBarView(
              children: [_MediaTab(), _ObjectsTab()],
            ),
          ),
        ),
      ),
    );
  }
}

// --------------------------------------------------------------- media tab
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
              'Every wavelength below is worked out for the frequency you left '
              'in the simulator, ${f.toStringAsFixed(0)} Hz. The source shakes '
              'at the same rate in all of them - only v changes.',
              icon: Icons.functions,
            ),
            const SizedBox(height: 14),
            for (final m in Media.all) _MediaCard(material: m, frequency: f),
            Panel(
              accent: AppColors.textDim,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const PanelTitle('Why the numbers vary', icon: Icons.warning_amber),
                  const Text(
                    'There is no single sound speed for a material. It depends '
                    'on temperature, density, stiffness, moisture, grain '
                    'direction and alloy, and in solids it differs for '
                    'longitudinal and shear waves. These are mid-range '
                    'teaching figures, not specifications.',
                    style: TextStyle(
                      fontSize: 14.5,
                      color: AppColors.textMuted,
                      height: 1.5,
                    ),
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
    final lambda = WavePhysics.wavelength(material.speedMs, frequency);
    final state = SimScope.of(context);
    final isSelected = identical(state.medium, material);

    return Panel(
      accent: isSelected ? material.color : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: material.color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  material.name,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              if (isSelected)
                const Text(
                  'in simulator',
                  style: TextStyle(fontSize: 13, color: AppColors.cyan),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ValueCard(
                  label: 'Sound speed',
                  value: material.speedMs.toStringAsFixed(0),
                  unit: 'm/s',
                  color: material.color,
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
                  color: AppColors.textMuted,
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
                  color: AppColors.amber,
                  compact: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            material.behaviour,
            style: const TextStyle(
              fontSize: 14.5,
              color: AppColors.textMuted,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Impedance Z = rho x v = ${material.impedanceLabel}. '
            '${material.note}',
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textDim,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 6),
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

// ------------------------------------------------------------- objects tab
class _ObjectsTab extends StatelessWidget {
  const _ObjectsTab();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
      children: [
        const Explain(
          'From real life to simulation. Each object is something you can find '
          'at home today, and each one maps onto a control in the simulator.',
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
    return Panel(
      padding: EdgeInsets.zero,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          iconColor: AppColors.cyan,
          collapsedIconColor: AppColors.textDim,
          leading: Icon(object.icon, color: AppColors.cyan, size: 26),
          title: Text(
            object.name,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          subtitle: Text(
            'Linked control: ${object.linkedParameter}',
            style: const TextStyle(fontSize: 13.5, color: AppColors.textDim),
          ),
          children: [
            _flow(),
            const SizedBox(height: 14),
            _TryItYourself(object: object),
            const SizedBox(height: 12),
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

  Widget _flow() {
    Widget step(String heading, String body, IconData icon) => Padding(
          padding: const EdgeInsets.only(bottom: 11),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 18, color: AppColors.blue),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      heading,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textDim,
                        letterSpacing: 0.4,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      body,
                      style: const TextStyle(
                        fontSize: 14.5,
                        color: AppColors.text,
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        step('HOW IT VIBRATES', object.howItVibrates, Icons.vibration),
        step('HOW SOUND IS PRODUCED', object.howSoundIsProduced, Icons.waves),
        step('WHAT TO OBSERVE', object.whatToObserve, Icons.visibility_outlined),
      ],
    );
  }
}

class _TryItYourself extends StatelessWidget {
  const _TryItYourself({required this.object});

  final EverydayObject object;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceHigh,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.stroke),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.science, size: 19, color: AppColors.amber),
              SizedBox(width: 8),
              Text(
                'Try it yourself',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.amber,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const _MiniHeading('Materials'),
          for (final m in object.materials)
            _Bullet(text: m, marker: Icons.circle, small: true),
          const SizedBox(height: 10),
          const _MiniHeading('Steps'),
          for (var i = 0; i < object.steps.length; i++)
            _Numbered(index: i + 1, text: object.steps[i]),
          const SizedBox(height: 10),
          const _MiniHeading('Why it happens'),
          Text(
            object.why,
            style: const TextStyle(
              fontSize: 14.5,
              color: AppColors.text,
              height: 1.5,
            ),
          ),
          if (object.safety != null) ...[
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.shield_outlined, size: 18, color: AppColors.red),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    object.safety!,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.red,
                      height: 1.4,
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
}

class _MiniHeading extends StatelessWidget {
  const _MiniHeading(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: AppColors.textMuted,
        ),
      ),
    );
  }
}

class _Bullet extends StatelessWidget {
  const _Bullet({required this.text, this.marker = Icons.circle, this.small = false});

  final String text;
  final IconData marker;
  final bool small;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 7),
            child: Icon(marker, size: small ? 6 : 10, color: AppColors.textDim),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 14.5,
                color: AppColors.text,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Numbered extends StatelessWidget {
  const _Numbered({required this.index, required this.text});

  final int index;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 22,
            height: 22,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: fade(AppColors.cyan, 0.15),
              borderRadius: BorderRadius.circular(7),
            ),
            child: Text(
              '$index',
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: AppColors.cyan,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 14.5,
                color: AppColors.text,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
