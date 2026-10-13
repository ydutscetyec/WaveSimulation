import 'package:flutter/material.dart';

import '../models/challenge_model.dart';
import '../models/simulation_state.dart';
import '../theme/wave_theme.dart';
import '../widgets/ui_kit.dart';

class ChallengeScreen extends StatefulWidget {
  const ChallengeScreen({super.key});

  static const String route = '/challenges';

  @override
  State<ChallengeScreen> createState() => _ChallengeScreenState();
}

class _ChallengeScreenState extends State<ChallengeScreen> {
  int _index = 0;
  int? _picked;
  int _correct = 0;
  int _wrong = 0;
  bool _finished = false;

  Challenge get _q => Challenges.all[_index];
  bool get _answered => _picked != null;

  void _pick(int i) {
    if (_answered) return;
    setState(() {
      _picked = i;
      if (i == _q.correctIndex) {
        _correct++;
      } else {
        _wrong++;
      }
    });
  }

  void _next() {
    if (_index >= Challenges.all.length - 1) {
      setState(() => _finished = true);
      return;
    }
    setState(() {
      _index++;
      _picked = null;
    });
  }

  void _restart() => setState(() {
        _index = 0;
        _picked = null;
        _correct = 0;
        _wrong = 0;
        _finished = false;
      });

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final state = SimScope.of(context);
    final total = Challenges.all.length;

    return LabScaffold(
      title: 'Challenges',
      subtitle: _finished ? 'Finished' : 'Question ${_index + 1} of $total',
      actions: [
        ThemeToggle(
          isDark: state.themeMode == ThemeMode.dark,
          onTap: state.toggleTheme,
        ),
      ],
      child: _finished ? _results(c, total) : _question(c, total),
    );
  }

  Widget _question(WaveColors c, int total) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: ValueCard(
                label: 'Correct',
                value: '$_correct',
                compact: true,
              ),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: ValueCard(
                label: 'Incorrect',
                value: '$_wrong',
                color: c.red,
                compact: true,
              ),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: ValueCard(
                label: 'Progress',
                value: '${_index + 1}/$total',
                color: c.amber,
                compact: true,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: (_index + 1) / total,
            minHeight: 7,
            backgroundColor: c.stroke,
            valueColor: AlwaysStoppedAnimation<Color>(c.accent),
          ),
        ),
        const SizedBox(height: 16),
        Panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _q.question,
                style: TextStyle(
                  fontSize: 18,
                  height: 1.45,
                  fontWeight: FontWeight.w600,
                  color: c.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              for (var i = 0; i < _q.choices.length; i++)
                _Choice(
                  text: _q.choices[i],
                  letter: String.fromCharCode(65 + i),
                  state: !_answered
                      ? _CS.idle
                      : (i == _q.correctIndex
                          ? _CS.correct
                          : (i == _picked ? _CS.wrong : _CS.dim)),
                  onTap: () => _pick(i),
                ),
            ],
          ),
        ),
        if (_answered) ...[
          Panel(
            accent: _picked == _q.correctIndex ? c.accent : c.amber,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      _picked == _q.correctIndex
                          ? Icons.check_circle
                          : Icons.cancel,
                      color: _picked == _q.correctIndex ? c.accent : c.red,
                      size: 22,
                    ),
                    const SizedBox(width: 9),
                    Text(
                      _picked == _q.correctIndex ? 'Correct' : 'Not this time',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: _picked == _q.correctIndex ? c.accent : c.red,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Body(_q.explanation, size: 15),
              ],
            ),
          ),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(54),
              backgroundColor: c.accent,
              foregroundColor: c.onAccent,
            ),
            onPressed: _next,
            icon: const Icon(Icons.arrow_forward),
            label: Text(
              _index >= Challenges.all.length - 1 ? 'See result' : 'Next',
            ),
          ),
        ],
      ],
    );
  }

  Widget _results(WaveColors c, int total) {
    final pct = total == 0 ? 0 : (_correct / total * 100).round();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Panel(
          accent: c.amber,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$_correct of $total correct',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: c.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '$pct%',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: c.amber,
                ),
              ),
              const SizedBox(height: 12),
              Body(
                pct >= 80
                    ? 'Strong. You are using the relationships, not recalling '
                        'them.'
                    : pct >= 50
                        ? 'Good start. Go back to the simulator and watch the '
                            'wavelength readout while you move the frequency.'
                        : 'Worth another pass. Try the simulation and the echo '
                            'experiment first, then come back.',
              ),
            ],
          ),
        ),
        FilledButton.icon(
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(54),
            backgroundColor: fade(c.accent, 0.18),
            foregroundColor: c.accent,
          ),
          onPressed: _restart,
          icon: const Icon(Icons.restart_alt),
          label: const Text('Start over'),
        ),
      ],
    );
  }
}

enum _CS { idle, correct, wrong, dim }

class _Choice extends StatelessWidget {
  const _Choice({
    required this.text,
    required this.letter,
    required this.state,
    required this.onTap,
  });

  final String text;
  final String letter;
  final _CS state;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final (Color border, Color fg) = switch (state) {
      _CS.idle => (c.stroke, c.textPrimary),
      _CS.correct => (c.accent, c.accent),
      _CS.wrong => (c.red, c.red),
      _CS.dim => (c.stroke, c.textTertiary),
    };

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: state == _CS.idle ? c.surfaceAlt : fade(border, 0.10),
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: state == _CS.idle ? onTap : null,
          child: Container(
            constraints: const BoxConstraints(minHeight: 56),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: border),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 28,
                  height: 28,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: fade(border, 0.25),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Text(
                    letter,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: fg,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    text,
                    style: TextStyle(fontSize: 15.5, color: fg, height: 1.4),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
