import 'package:flutter/material.dart';

/// The everyday-materials requirement. Each entry links a real object the
/// student can hold to the quantity the simulator lets them change.
@immutable
class EverydayObject {
  const EverydayObject({
    required this.name,
    required this.icon,
    required this.howItVibrates,
    required this.howSoundIsProduced,
    required this.whatToObserve,
    required this.linkedParameter,
    required this.materials,
    required this.steps,
    required this.why,
    this.safety,
    this.suggestedFrequency,
  });

  final String name;
  final IconData icon;
  final String howItVibrates;
  final String howSoundIsProduced;
  final String whatToObserve;

  /// Which simulator control this object maps onto.
  final String linkedParameter;

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
      howItVibrates:
          'Stretched between two fingers it is a string under tension. Pluck '
          'it and it swings back and forth around its straight resting line.',
      howSoundIsProduced:
          'Each swing pushes the air next to it, then pulls away. That push '
          'makes a compression and the pull makes a rarefaction, and the pair '
          'travels outwards as a sound wave.',
      whatToObserve:
          'Stretch it tighter and the pitch rises. The band did not get '
          'louder, it got faster - that is frequency, not amplitude.',
      linkedParameter: 'Frequency',
      materials: ['One rubber band', 'Your two hands'],
      steps: [
        'Hook the band over your thumb and index finger and stretch it lightly.',
        'Pluck the middle of the band and listen to the pitch.',
        'Stretch it further so the band is tighter, then pluck again.',
        'Now go back to the loose tension and pluck harder instead.',
      ],
      why:
          'Tension changes how fast the band springs back, so it changes '
          'frequency and therefore pitch. Plucking harder only moves the band '
          'further from rest, which is amplitude - it changes loudness and '
          'leaves the pitch alone.',
      safety: 'Do not aim a stretched band near anyone\'s face or eyes.',
      suggestedFrequency: 220,
    ),
    EverydayObject(
      name: 'Plastic cup and string',
      icon: Icons.phone_in_talk,
      howItVibrates:
          'Your voice makes the cup bottom vibrate like a drum skin. The cup '
          'pulls the taut string, so the vibration runs along the string.',
      howSoundIsProduced:
          'Air vibration becomes cup vibration, becomes string vibration, '
          'becomes cup vibration again, becomes air vibration in the second '
          'cup. Sound changes medium four times on the way.',
      whatToObserve:
          'It only works when the string is tight. A slack string cannot pull '
          'the next piece of itself, so the wave dies instead of travelling.',
      linkedParameter: 'Medium',
      materials: [
        'Two plastic or paper cups',
        'About 5 m of thin non-stretchy string',
        'A paper clip or tape',
        'A second person',
      ],
      steps: [
        'Make a small hole in the centre of each cup bottom.',
        'Thread the string through and knot it round a paper clip inside.',
        'Walk apart until the string is straight and tight, not touching anything.',
        'One person talks into their cup, the other holds theirs to an ear.',
        'Now let the string go slack and try again.',
      ],
      why:
          'A solid string carries a mechanical wave faster and with less '
          'spreading loss than open air over the same distance. Tension is '
          'what lets one bit of string pull on the next bit.',
      suggestedFrequency: 300,
    ),
    EverydayObject(
      name: 'Cardboard box',
      icon: Icons.inventory_2,
      howItVibrates:
          'The flat walls flex slowly and the trapped air column inside '
          'bounces back and forth between them.',
      howSoundIsProduced:
          'Speaking into the box drives the air inside it. Some energy comes '
          'back out of the opening, some is reflected inside, some is lost in '
          'the soft cardboard fibres.',
      whatToObserve:
          'An empty box sounds boxy and ringing. Line it with cloth and the '
          'ring disappears, because the ringing was the reflections.',
      linkedParameter: 'Reflection',
      materials: ['A cardboard box', 'An old shirt or towel'],
      steps: [
        'Speak into the open box at a steady volume and listen to the tone.',
        'Line the inside with cloth and speak again at the same volume.',
        'Take the cloth out and compare once more.',
      ],
      why:
          'Hard, sealed walls send energy back. Soft, porous cloth makes air '
          'squeeze through fibres, turning sound energy into a little heat. '
          'That is absorption, and it kills the repeated reflections.',
      suggestedFrequency: 400,
    ),
    EverydayObject(
      name: 'Metal spoon',
      icon: Icons.restaurant,
      howItVibrates:
          'Struck metal flexes and rings at its own natural frequencies, '
          'decided by its size, shape and stiffness.',
      howSoundIsProduced:
          'The ringing metal pushes the surrounding air. Metal is stiff and '
          'dense, so it holds its vibration far longer than cardboard does.',
      whatToObserve:
          'Hang the spoon on a string, press the string ends into your ears '
          'and tap it. The sound becomes huge - because the string delivers '
          'the vibration to you directly instead of losing it to the air.',
      linkedParameter: 'Medium',
      materials: [
        'A metal spoon',
        'About 1 m of string',
      ],
      steps: [
        'Tap the spoon against a table and listen through the air.',
        'Tie the string to the spoon and press the two string ends into your ears.',
        'Let the spoon swing against the table edge again.',
      ],
      why:
          'Air has a very low acoustic impedance compared with metal, so only '
          'a small fraction of the spoon\'s energy crosses into it. The string '
          'is a far better match and carries much more of that energy to you.',
      safety: 'Tap gently. Do not swing a spoon near your face.',
      suggestedFrequency: 1200,
    ),
    EverydayObject(
      name: 'Glass of water',
      icon: Icons.local_drink,
      howItVibrates:
          'The glass wall and the air column above the water vibrate together '
          'as one system.',
      howSoundIsProduced:
          'Tapping the rim or rubbing it with a wet finger drives the glass at '
          'its natural frequency. Water changes the mass that has to move.',
      whatToObserve:
          'More water means a lower note. The vibrating system got heavier, so '
          'it moves more slowly.',
      linkedParameter: 'Resonance',
      materials: [
        'Several identical glasses',
        'Water',
        'A spoon or a wet finger',
      ],
      steps: [
        'Fill the glasses to clearly different levels.',
        'Tap each one near the rim with the spoon and listen along the row.',
        'Try rubbing a wet fingertip slowly round one rim until it sings.',
      ],
      why:
          'Natural frequency falls when the vibrating mass rises and rises '
          'when stiffness rises. Adding water adds mass, so the pitch drops. '
          'This is also a resonance demonstration - rubbing adds tiny pushes '
          'at exactly the right rate.',
      safety: 'Use sturdy glasses and keep taps light so nothing chips.',
      suggestedFrequency: 500,
    ),
    EverydayObject(
      name: 'Cloth and foam',
      icon: Icons.layers,
      howItVibrates:
          'They barely vibrate as a whole. Air is forced through narrow pores '
          'and loses energy to friction on the way.',
      howSoundIsProduced:
          'These materials are not sources. They are what you use when you '
          'want sound to stop coming back at you.',
      whatToObserve:
          'Clap in a bare tiled room, then in a room with curtains and a bed. '
          'The second clap stops almost instantly.',
      linkedParameter: 'Absorption',
      materials: ['A towel or thick curtain', 'A tiled or bare room'],
      steps: [
        'Clap once in a bare hard room and count how long the sound hangs on.',
        'Hold a thick towel near the wall and clap again in the same spot.',
        'Try it with a low hum as well as a sharp clap.',
      ],
      why:
          'Porous absorbers work on the air movement inside the pores, which '
          'needs the pore depth to be a real fraction of a wavelength. A thin '
          'towel handles high frequencies well and does little for bass.',
      suggestedFrequency: 1500,
    ),
    EverydayObject(
      name: 'Wooden ruler',
      icon: Icons.straighten,
      howItVibrates:
          'Clamped over a table edge, the free end swings up and down at a '
          'rate set by how much of it hangs free.',
      howSoundIsProduced:
          'The swinging end slaps the air above and below it, pushing out '
          'compressions on each pass.',
      whatToObserve:
          'Slide the ruler so less of it hangs over and the note rises. You '
          'can see the vibration slowly and hear the pitch at the same time.',
      linkedParameter: 'Frequency',
      materials: ['A wooden or plastic ruler', 'A table edge'],
      steps: [
        'Press most of the ruler flat on the table with a long end hanging off.',
        'Twang the free end and watch it while you listen.',
        'Slide the ruler back so only a short piece overhangs, then twang again.',
      ],
      why:
          'A shorter free length is stiffer and lighter, so it springs back '
          'faster. Frequency rises and the pitch goes up with it. At long '
          'overhangs you can see individual swings - that is the same motion '
          'that becomes an invisible 440 Hz vibration when it speeds up.',
      suggestedFrequency: 100,
    ),
  ];
}
