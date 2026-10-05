import 'package:flutter/foundation.dart';

@immutable
class Challenge {
  const Challenge({
    required this.question,
    required this.choices,
    required this.correctIndex,
    required this.explanation,
  });

  final String question;
  final List<String> choices;
  final int correctIndex;
  final String explanation;
}

class Challenges {
  const Challenges._();

  static const List<Challenge> all = [
    Challenge(
      question:
          'Frequency increases while the medium stays the same. What happens '
          'to the wavelength?',
      choices: ['It increases', 'It decreases', 'It stays the same', 'It becomes zero'],
      correctIndex: 1,
      explanation:
          'From v = f·λ, the wavelength is λ = v/f. The medium is unchanged so '
          'v is fixed, and f is in the denominator: double the frequency and '
          'the wavelength halves.',
    ),
    Challenge(
      question: 'Which quantity determines the pitch you hear?',
      choices: ['Amplitude', 'Frequency', 'Density', 'Distance'],
      correctIndex: 1,
      explanation:
          'Pitch follows frequency. Amplitude changes how loud the sound is, '
          'not how high it is. Move the amplitude slider in the simulator and '
          'watch the wavelength readout stay exactly where it was.',
    ),
    Challenge(
      question: 'Which surface generally reflects the most sound?',
      choices: ['Acoustic foam', 'A thick curtain', 'A concrete wall', 'Soft cloth'],
      correctIndex: 2,
      explanation:
          'Hard, heavy, sealed surfaces reflect most of the energy that hits '
          'them. Concrete absorbs only a few percent. Porous materials let air '
          'move inside them and lose energy to friction, but none of them '
          'absorbs everything.',
    ),
    Challenge(
      question: 'Can sound travel through a vacuum?',
      choices: ['Yes', 'No'],
      correctIndex: 1,
      explanation:
          'Sound is a mechanical wave: it is particles pushing on neighbouring '
          'particles. With no particles there is nothing to compress, so there '
          'is no wave at all - not even a very quiet one.',
    ),
    Challenge(
      question:
          'The same 440 Hz source is moved from air into water. What happens '
          'to the wavelength?',
      choices: [
        'It stays at about 0.78 m',
        'It gets about 4x shorter',
        'It gets about 4x longer',
        'It drops to zero',
      ],
      correctIndex: 2,
      explanation:
          'The source still shakes 440 times a second, so f does not change. '
          'Water carries the wave at about 1480 m/s instead of 343 m/s, so '
          'λ = v/f goes from about 0.78 m to about 3.4 m.',
    ),
    Challenge(
      question:
          'Two identical speakers play the same tone. At one point the path '
          'difference from the two speakers is exactly one wavelength. What do '
          'you hear there?',
      choices: [
        'Silence',
        'A louder sound',
        'The same as from one speaker',
        'A higher pitch',
      ],
      correctIndex: 1,
      explanation:
          'A whole-wavelength path difference puts the two waves back in step, '
          'so the crests line up and the amplitudes add. That is constructive '
          'interference. Half a wavelength would give the quiet spots instead.',
    ),
    Challenge(
      question:
          'You stand 100 m from a cliff and shout. Roughly how long until you '
          'hear the echo? (speed of sound ≈ 343 m/s)',
      choices: ['0.15 s', '0.29 s', '0.58 s', '1.2 s'],
      correctIndex: 2,
      explanation:
          'The sound has to go there and come back, so t = 2d/v = 200/343 ≈ '
          '0.58 s. Forgetting to double the distance is the single most common '
          'mistake in echo problems.',
    ),
    Challenge(
      question:
          'In a standing wave, what is a node?',
      choices: [
        'A point of maximum movement',
        'A point that barely moves at all',
        'The point where the wave starts',
        'A point where energy disappears',
      ],
      correctIndex: 1,
      explanation:
          'At a node the two counter-travelling waves always arrive out of '
          'step, so they cancel there permanently. Antinodes, halfway between '
          'nodes, are where the movement is largest.',
    ),
    Challenge(
      question:
          'Destructive interference makes a quiet spot. Where did that sound '
          'energy go?',
      choices: [
        'It was destroyed',
        'It turned into heat at that point',
        'It is somewhere else, in the loud spots',
        'It was absorbed by the air',
      ],
      correctIndex: 2,
      explanation:
          'Energy is conserved. Interference only rearranges where the energy '
          'ends up: the quiet regions are paid for by the loud regions, which '
          'carry more than either source would alone.',
    ),
    Challenge(
      question:
          'Why do we say sound in air is a longitudinal wave?',
      choices: [
        'Because it travels in a straight line',
        'Because air particles move along the same direction the wave travels',
        'Because it moves up and down like a water wave',
        'Because it has a long wavelength',
      ],
      correctIndex: 1,
      explanation:
          'Longitudinal means the particle motion is parallel to the direction '
          'of travel. Air particles jiggle back and forth along the wave path, '
          'making compressions and rarefactions. They do not travel with the '
          'wave - only the disturbance does.',
    ),
  ];
}
