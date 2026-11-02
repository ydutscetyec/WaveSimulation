import 'package:flutter/material.dart';

import '../services/tone_generator.dart';
import '../services/tone_player.dart';
import '../theme/wave_theme.dart';
import 'ui_kit.dart';

/// PhET's "Play Tone" checkbox: a switch that sounds the frequency currently
/// set in the simulation.
///
/// It owns its own [TonePlayer] so it can be dropped into any screen with one
/// line and disposes cleanly when that screen is popped. Nothing else needs to
/// know audio exists.
class ToneToggle extends StatefulWidget {
  const ToneToggle({
    super.key,
    required this.frequencyHz,
    required this.amplitude,
  });

  /// The simulation's physical frequency. Fed straight to the synthesiser, so
  /// what is heard is what the readout says.
  final double frequencyHz;

  /// 0..1, mapped to playback volume.
  final double amplitude;

  @override
  State<ToneToggle> createState() => _ToneToggleState();
}

class _ToneToggleState extends State<ToneToggle> {
  final TonePlayer _player = TonePlayer();

  @override
  void initState() {
    super.initState();
    _player.addListener(_onPlayerChanged);
    _player.setFrequency(widget.frequencyHz);
  }

  void _onPlayerChanged() {
    if (mounted) setState(() {});
  }

  @override
  void didUpdateWidget(covariant ToneToggle old) {
    super.didUpdateWidget(old);
    _player.setFrequency(widget.frequencyHz);
    _player.setAmplitude(widget.amplitude);
  }

  @override
  void dispose() {
    _player.removeListener(_onPlayerChanged);
    _player.dispose();
    super.dispose();
  }

  bool get _inBand =>
      widget.frequencyHz >= ToneGenerator.minFrequency &&
      widget.frequencyHz <= ToneGenerator.maxFrequency;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final usable = _player.available && _inBand;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              _player.enabled ? Icons.volume_up : Icons.volume_off,
              size: 20,
              color: usable ? c.accent : c.textTertiary,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Play tone',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: usable ? c.textSecondary : c.textTertiary,
                ),
              ),
            ),
            Switch(
              value: _player.enabled,
              onChanged: usable ? (v) => _player.setEnabled(v) : null,
            ),
          ],
        ),
        if (!_player.available)
          Body(
            'This device did not provide an audio output, so the tone is '
            'unavailable. Everything else still works.',
            size: 12.5,
            color: c.textTertiary,
          )
        else if (!_inBand)
          Body(
            'Outside the range this speaker can reproduce '
            '(${ToneGenerator.minFrequency.toStringAsFixed(0)}–'
            '${(ToneGenerator.maxFrequency / 1000).toStringAsFixed(0)} kHz), '
            'so nothing is played rather than playing the wrong pitch.',
            size: 12.5,
            color: c.textTertiary,
          )
        else
          Body(
            'A pure sine at the frequency above. Raise the frequency for a '
            'higher pitch; raise the amplitude for a louder one.',
            size: 12.5,
            color: c.textTertiary,
          ),
      ],
    );
  }
}
