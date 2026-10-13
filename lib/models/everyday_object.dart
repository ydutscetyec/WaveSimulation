import 'package:flutter/material.dart';

/// The everyday-materials requirement: real objects, each linked to one
/// control in the simulator.
@immutable
class EverydayObject {
  const EverydayObject({
    required this.name,
    required this.icon,
    required this.linkedParameter,
    required this.vibrates,
    required this.observe,
    required this.materials,
    required this.steps,
    required this.why,
    this.safety,
    this.suggestedFrequency,
  });

  final String name;
  final IconData icon;
  final String linkedParameter;
  final String vibrates;
  final String observe;
  final List<String> materials;
  final List<String> steps;
  final String why;
  final String? safety;
  final double? suggestedFrequency;
}

class EverydayObjects {
  const EverydayObjects._();

  static const List<EverydayObject> all = [
    EverydayObject(
      name: 'Rubber band',
      icon: Icons.linear_scale,
      linkedParameter: 'Frequency',
      vibrates: 'Stretched between two fingers it is a string under tension. '
          'Pluck it and it swings about its resting line, pushing and pulling '
          'the air beside it.',
      observe: 'Stretch it tighter and the pitch rises. Pluck it harder and '
          'only the loudness changes.',
      materials: ['One rubber band'],
      steps: [
        'Stretch the band between thumb and finger and pluck the middle.',
        'Stretch it tighter and pluck again. Listen to the pitch.',
        'Go back to the loose tension and pluck harder instead.',
      ],
      why: 'Tension sets how fast the band springs back, so it sets frequency '
          'and pitch. Plucking harder only increases amplitude, which is '
          'loudness.',
      safety: 'Keep a stretched band away from faces and eyes.',
      suggestedFrequency: 220,
    ),
    EverydayObject(
      name: 'Cup and string telephone',
      icon: Icons.phone_in_talk,
      linkedParameter: 'Medium',
      vibrates: 'Your voice shakes the cup bottom like a drum skin, and that '
          'shaking runs along the taut string to the far cup.',
      observe: 'It works only when the string is tight. Let it go slack and '
          'the sound dies.',
      materials: [
        'Two plastic or paper cups',
        'About 5 m of thin string',
        'A paper clip',
        'A second person',
      ],
      steps: [
        'Make a small hole in each cup bottom and knot the string inside.',
        'Walk apart until the string is straight and touching nothing.',
        'One person speaks into a cup, the other listens.',
        'Let the string go slack and try again.',
      ],
      why: 'A solid string carries the wave with less spreading loss than open '
          'air. Tension is what lets one piece of string pull the next.',
      suggestedFrequency: 300,
    ),
    EverydayObject(
      name: 'Cardboard box',
      icon: Icons.inventory_2,
      linkedParameter: 'Reflection',
      vibrates: 'The flat walls flex and the air trapped inside bounces back '
          'and forth between them.',
      observe: 'An empty box sounds boxy and ringing. Line it with cloth and '
          'the ring disappears.',
      materials: ['A cardboard box', 'An old shirt or towel'],
      steps: [
        'Speak into the open box and listen to the tone.',
        'Line the inside with cloth and speak again at the same volume.',
      ],
      why: 'Hard walls reflect. Cloth makes air squeeze through fibres, which '
          'turns sound energy into a little heat. That is absorption.',
      suggestedFrequency: 400,
    ),
    EverydayObject(
      name: 'Metal spoon',
      icon: Icons.restaurant,
      linkedParameter: 'Medium',
      vibrates: 'Struck metal rings at its own natural frequencies, set by its '
          'size, shape and stiffness.',
      observe: 'Hang it on a string, press the string ends into your ears and '
          'tap it. The sound becomes huge.',
      materials: ['A metal spoon', 'About 1 m of string'],
      steps: [
        'Tap the spoon on a table and listen through the air.',
        'Tie the string to the spoon, press the ends into your ears.',
        'Swing the spoon against the table edge again.',
      ],
      why: 'Air has a far lower impedance than metal, so little of the spoon\'s '
          'energy crosses into it. The string is a much better match and '
          'delivers far more of that energy to you.',
      safety: 'Tap gently and keep the spoon away from your face.',
      suggestedFrequency: 1200,
    ),
    EverydayObject(
      name: 'Glass of water',
      icon: Icons.local_drink,
      linkedParameter: 'Resonance',
      vibrates: 'The glass wall and the air column above the water vibrate '
          'together as one system.',
      observe: 'More water gives a lower note, because the vibrating system '
          'got heavier.',
      materials: ['Several identical glasses', 'Water', 'A spoon'],
      steps: [
        'Fill the glasses to clearly different levels.',
        'Tap each one near the rim and listen along the row.',
        'Try rubbing a wet fingertip slowly round a rim until it sings.',
      ],
      why: 'Natural frequency falls as mass rises and rises as stiffness '
          'rises. Rubbing the rim adds tiny pushes at exactly the right rate, '
          'which is resonance.',
      safety: 'Use sturdy glasses and keep taps light.',
      suggestedFrequency: 500,
    ),
    EverydayObject(
      name: 'Wooden ruler',
      icon: Icons.straighten,
      linkedParameter: 'Frequency',
      vibrates: 'Clamped over a table edge, the free end swings at a rate set '
          'by how much of it hangs free.',
      observe: 'With a long overhang you can see the individual swings. '
          'Shorten it and the swings become a pitch.',
      materials: ['A ruler', 'A table edge'],
      steps: [
        'Hold most of the ruler flat on the table with a long end hanging off.',
        'Twang the free end and watch it while you listen.',
        'Slide it back so only a short piece overhangs, then twang again.',
      ],
      why: 'A shorter free length is stiffer and lighter, so it springs back '
          'faster and the frequency rises. This is the bridge between visible '
          'vibration and audible pitch.',
      suggestedFrequency: 100,
    ),
  ];
}
