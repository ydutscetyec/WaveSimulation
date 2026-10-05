import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../widgets/longitudinal_wave.dart';
import '../widgets/sim_clock.dart';
import '../widgets/ui_kit.dart';

class _Concept {
  const _Concept({
    required this.term,
    required this.definition,
    required this.example,
    required this.lambdaM,
    required this.amplitude,
    this.hz = 1.0,
  });

  final String term;
  final String definition;
  final String example;
  final double lambdaM;
  final double amplitude;
  final double hz;
}

const List<_Concept> _concepts = [
  _Concept(
    term: 'Frequency',
    definition: 'How many complete oscillations happen each second. Unit: '
        'hertz (Hz).',
    example: 'A 440 Hz tuning fork moves back and forth 440 times a second. '
        'Tighten a rubber band and its frequency goes up, so the pitch does too.',
    lambdaM: 0.5,
    amplitude: 0.55,
    hz: 1.8,
  ),
  _Concept(
    term: 'Amplitude',
    definition: 'The largest distance a particle moves away from its resting '
        'position.',
    example: 'Pluck the same rubber band harder. It swings further, so it is '
        'louder - but it still swings at the same rate, so the pitch is unchanged.',
    lambdaM: 0.9,
    amplitude: 1.0,
    hz: 0.8,
  ),
  _Concept(
    term: 'Wavelength',
    definition: 'The distance between two matching points on the wave - one '
        'compression to the next, for example. Symbol: lambda.',
    example: 'At 440 Hz in air, lambda = 343 / 440, about 0.78 m. Measure a '
        'compression, skip one, measure the next, and that is your lambda.',
    lambdaM: 0.65,
    amplitude: 0.6,
  ),
  _Concept(
    term: 'Wave speed',
    definition: 'How fast the disturbance moves through the medium. It is set '
        'by the medium, not by how hard you shout.',
    example: 'About 343 m/s in air, 1480 m/s in water, 5960 m/s in steel. '
        'Tapping a long metal rail reaches the far end long before the sound '
        'through the air does.',
    lambdaM: 1.1,
    amplitude: 0.6,
    hz: 1.4,
  ),
  _Concept(
    term: 'Compression',
    definition: 'A region where the particles are temporarily crowded closer '
        'together, so the pressure there is above normal.',
    example: 'The bright, tightly packed bands moving to the right in the '
        'picture above. They travel; the particles themselves do not.',
    lambdaM: 0.75,
    amplitude: 0.85,
  ),
  _Concept(
    term: 'Rarefaction',
    definition: 'A region where the particles are temporarily spread further '
        'apart, so the pressure there is below normal.',
    example: 'The dim, sparse bands between the compressions. Every push by '
        'the source is followed by a pull back, so the two always come in pairs.',
    lambdaM: 0.75,
    amplitude: 0.85,
  ),
  _Concept(
    term: 'Longitudinal wave',
    definition: 'A wave in which the particles move back and forth along the '
        'same line the wave travels.',
    example: 'Every particle above slides left and right, never up and down. '
        'Sound in air, water and solids is longitudinal. A rope you shake '
        'sideways is transverse, which is a different thing.',
    lambdaM: 0.8,
    amplitude: 0.9,
  ),
];

class ConceptsScreen extends StatefulWidget {
  const ConceptsScreen({super.key});

  static const String route = '/concepts';

  @override
  State<ConceptsScreen> createState() => _ConceptsScreenState();
}

class _ConceptsScreenState extends State<ConceptsScreen> {
  int _selected = 0;

  @override
  Widget build(BuildContext context) {
    final c = _concepts[_selected];

    return LabScaffold(
      title: 'Wave concepts',
      subtitle: 'Seven terms, each with its own picture',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 150,
            width: double.infinity,
            child: ClockHost(
              hz: c.hz,
              builder: (context, clock) => CustomPaint(
                painter: ParticleFieldPainter(
                  clock: clock,
                  amplitude: c.amplitude,
                  wavelengthM: c.lambdaM,
                  viewWidthM: 2.0,
                  mediumColor: AppColors.cyan,
                  showSourceReceiver: false,
                  showMarkers: _selected == 4 || _selected == 5,
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Showing: ${c.term.toLowerCase()}',
            style: const TextStyle(fontSize: 13.5, color: AppColors.textDim),
          ),
          const SizedBox(height: 14),
          for (var i = 0; i < _concepts.length; i++)
            _ConceptCard(
              concept: _concepts[i],
              selected: i == _selected,
              onTap: () => setState(() => _selected = i),
            ),
          const Panel(
            margin: EdgeInsets.zero,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                PanelTitle('The one equation that ties them together',
                    icon: Icons.functions),
                Text(
                  'v = f x lambda',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: AppColors.cyan,
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  'v is fixed by the medium. f is fixed by the source. '
                  'Wavelength is whatever those two leave over - which is why '
                  'you can never change lambda directly.',
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
      ),
    );
  }
}

class _ConceptCard extends StatelessWidget {
  const _ConceptCard({
    required this.concept,
    required this.selected,
    required this.onTap,
  });

  final _Concept concept;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: selected ? fade(AppColors.cyan, 0.08) : AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: selected ? AppColors.cyan : AppColors.stroke,
                width: selected ? 1.5 : 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        concept.term,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: selected ? AppColors.cyan : AppColors.text,
                        ),
                      ),
                    ),
                    if (!selected)
                      const Icon(Icons.play_circle_outline,
                          size: 20, color: AppColors.textDim),
                  ],
                ),
                const SizedBox(height: 7),
                Text(
                  concept.definition,
                  style: const TextStyle(
                    fontSize: 15,
                    color: AppColors.text,
                    height: 1.45,
                  ),
                ),
                if (selected) ...[
                  const SizedBox(height: 10),
                  Text(
                    concept.example,
                    style: const TextStyle(
                      fontSize: 14.5,
                      color: AppColors.textMuted,
                      height: 1.5,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
