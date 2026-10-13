import 'package:flutter/material.dart';

import '../models/simulation_state.dart';
import '../theme/wave_theme.dart';
import '../widgets/sim_clock.dart';
import '../widgets/ui_kit.dart';
import '../widgets/wave_canvas.dart';

class _Concept {
  const _Concept({
    required this.term,
    required this.definition,
    required this.example,
    required this.lambdaM,
    required this.amplitude,
    this.hz = 1.0,
    this.tracer = false,
  });

  final String term;
  final String definition;
  final String example;
  final double lambdaM;
  final double amplitude;
  final double hz;
  final bool tracer;
}

const List<_Concept> _concepts = [
  _Concept(
    term: 'Frequency',
    definition: 'Complete oscillations per second. Unit: hertz (Hz).',
    example: 'A 440 Hz fork moves back and forth 440 times a second. Tighten a '
        'rubber band and its frequency rises, so the pitch does too.',
    lambdaM: 0.5,
    amplitude: 0.55,
    hz: 1.9,
  ),
  _Concept(
    term: 'Amplitude',
    definition: 'The furthest a particle moves from its resting position.',
    example: 'Pluck the same band harder. It swings further, so it is louder, '
        'but it still swings at the same rate, so the pitch is unchanged.',
    lambdaM: 0.9,
    amplitude: 1.0,
    hz: 0.8,
    tracer: true,
  ),
  _Concept(
    term: 'Wavelength',
    definition: 'The distance from one compression to the next. Symbol lambda.',
    example: 'At 440 Hz in air, lambda = 343 / 440, about 0.78 m.',
    lambdaM: 0.65,
    amplitude: 0.6,
  ),
  _Concept(
    term: 'Wave speed',
    definition: 'How fast the disturbance travels. Set by the medium, not by '
        'how hard you shout.',
    example: '343 m/s in air, 1480 in water, 5960 in steel. Tap a long metal '
        'rail and the sound arrives through the rail first.',
    lambdaM: 1.1,
    amplitude: 0.6,
    hz: 1.5,
  ),
  _Concept(
    term: 'Compression',
    definition: 'A region where particles are crowded together, so the '
        'pressure is above normal.',
    example: 'The bright bands travelling to the right. The bands move; the '
        'particles do not travel with them.',
    lambdaM: 0.75,
    amplitude: 0.85,
    tracer: true,
  ),
  _Concept(
    term: 'Rarefaction',
    definition: 'A region where particles are spread apart, so the pressure is '
        'below normal.',
    example: 'The dim gaps between compressions. Every push by the source is '
        'followed by a pull, so the two always come in pairs.',
    lambdaM: 0.75,
    amplitude: 0.85,
  ),
  _Concept(
    term: 'Longitudinal wave',
    definition: 'The particles move back and forth along the same line the '
        'wave travels.',
    example: 'Watch the amber particle: it slides left and right, never up and '
        'down, and it ends up where it started.',
    lambdaM: 0.8,
    amplitude: 0.9,
    tracer: true,
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
    final concept = _concepts[_selected];
    final c = context.c;
    final state = SimScope.of(context);

    return LabScaffold(
      title: 'Concepts',
      subtitle: 'Tap a term to see it',
      actions: [
        ThemeToggle(
          isDark: state.themeMode == ThemeMode.dark,
          onTap: state.toggleTheme,
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 148,
            width: double.infinity,
            child: ClockHost(
              hz: concept.hz,
              timeRate: 1 / 440,
              builder: (context, clock) => CustomPaint(
                painter: WavePainter(
                  clock: clock,
                  colors: c,
                  amplitude: concept.amplitude,
                  wavelengthM: concept.lambdaM,
                  viewWidthM: 2.0,
                  accent: c.accent,
                  showSource: false,
                  showFront: _selected == 3,
                  showTracer: concept.tracer,
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          for (var i = 0; i < _concepts.length; i++)
            _Card(
              concept: _concepts[i],
              selected: i == _selected,
              onTap: () => setState(() => _selected = i),
            ),
          Panel(
            margin: EdgeInsets.zero,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'v = f x lambda',
                  style: TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.w800,
                    color: c.accent,
                  ),
                ),
                const SizedBox(height: 10),
                const Body(
                  'v is fixed by the medium. f is fixed by the source. '
                  'Wavelength is whatever those two leave over, which is why '
                  'you can never set it directly.',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({
    required this.concept,
    required this.selected,
    required this.onTap,
  });

  final _Concept concept;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Padding(
      padding: const EdgeInsets.only(bottom: 11),
      child: Material(
        color: selected ? fade(c.accent, 0.08) : c.surface,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: selected ? c.accent : c.stroke,
                width: selected ? 1.5 : 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  concept.term,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: selected ? c.accent : c.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Body(concept.definition, size: 15, color: c.textPrimary),
                if (selected) ...[
                  const SizedBox(height: 9),
                  Body(concept.example),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
