import 'package:flutter/material.dart';

import '../models/challenge_model.dart';
import '../models/simulation_state.dart';
import '../theme/app_theme.dart';
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
  bool _finished = false;

  Challenge get _q => Challenges.all[_index];
  bool get _answered => _picked != null;

  void _pick(int i) {
    if (_answered) return;
    final state = SimScope.read(context);
    final hadBadge = state.badges.contains('PHYSICS DETECTIVE');
    setState(() => _picked = i);
    state.recordAnswer(isCorrect: i == _q.correctIndex);
    if (!hadBadge && state.badges.contains('PHYSICS DETECTIVE')) {
      showBadge(context, 'PHYSICS DETECTIVE');
    }
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

  void _restart() {
    SimScope.read(context).resetScore();
    setState(() {
      _index = 0;
      _picked = null;
      _finished = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = SimScope.of(context);

    return LabScaffold(
      title: 'Challenges',
      subtitle: _finished
          ? 'Finished'
          : 'Question ${_index + 1} of ${Challenges.all.length}',
      child: AnimatedBuilder(
        animation: state,
        builder: (context, _) {
          if (_finished) return _results(state);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _scoreBar(state),
              const SizedBox(height: 16),
              Panel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _q.question,
                      style: const TextStyle(
                        fontSize: 18,
                        height: 1.45,
                        fontWeight: FontWeight.w600,
                        color: AppColors.text,
                      ),
                    ),
                    const SizedBox(height: 16),
                    for (var i = 0; i < _q.choices.length; i++)
                      _ChoiceTile(
                        text: _q.choices[i],
                        letter: String.fromCharCode(65 + i),
                        state: !_answered
                            ? _ChoiceState.idle
                            : (i == _q.correctIndex
                                ? _ChoiceState.correct
                                : (i == _picked
                                    ? _ChoiceState.wrong
                                    : _ChoiceState.dimmed)),
                        onTap: () => _pick(i),
                      ),
                  ],
                ),
              ),
              if (_answered) ...[
                Panel(
                  accent: _picked == _q.correctIndex
                      ? AppColors.cyan
                      : AppColors.amber,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            _picked == _q.correctIndex
                                ? Icons.check_circle
                                : Icons.cancel,
                            color: _picked == _q.correctIndex
                                ? AppColors.cyan
                                : AppColors.red,
                            size: 22,
                          ),
                          const SizedBox(width: 9),
                          Text(
                            _picked == _q.correctIndex
                                ? 'Correct'
                                : 'Not this time',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: _picked == _q.correctIndex
                                  ? AppColors.cyan
                                  : AppColors.red,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 11),
                      Text(
                        _q.explanation,
                        style: const TextStyle(
                          fontSize: 15,
                          color: AppColors.textMuted,
                          height: 1.55,
                        ),
                      ),
                    ],
                  ),
                ),
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(54),
                    backgroundColor: AppColors.cyan,
                    foregroundColor: const Color(0xFF042026),
                  ),
                  onPressed: _next,
                  icon: const Icon(Icons.arrow_forward),
                  label: Text(
                    _index >= Challenges.all.length - 1
                        ? 'See results'
                        : 'Next question',
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _scoreBar(SimulationState state) {
    final total = Challenges.all.length;
    return Panel(
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.all(14),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: ValueCard(
                  label: 'Correct',
                  value: '${state.correct}',
                  color: AppColors.cyan,
                  compact: true,
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: ValueCard(
                  label: 'Incorrect',
                  value: '${state.wrong}',
                  color: AppColors.red,
                  compact: true,
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: ValueCard(
                  label: 'Score',
                  value: state.answered == 0
                      ? '-'
                      : '${(state.correct / state.answered * 100).round()}%',
                  color: AppColors.amber,
                  compact: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: (_index + 1) / total,
              minHeight: 7,
              backgroundColor: AppColors.stroke,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.cyan),
            ),
          ),
        ],
      ),
    );
  }

  Widget _results(SimulationState state) {
    final total = Challenges.all.length;
    final pct = state.answered == 0
        ? 0
        : (state.correct / state.answered * 100).round();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Panel(
          accent: AppColors.amber,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${state.correct} of $total correct',
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: AppColors.text,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '$pct%',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.amber,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                pct >= 80
                    ? 'Strong. You are using the relationships rather than '
                        'recalling them.'
                    : pct >= 50
                        ? 'A good start. Go back to the simulator and watch the '
                            'wavelength readout while you move the frequency - '
                            'most of the remaining questions come from that one '
                            'relationship.'
                        : 'Worth another pass. Try the main simulation and the '
                            'echo experiment first, then come back.',
                style: const TextStyle(
                  fontSize: 15,
                  color: AppColors.textMuted,
                  height: 1.55,
                ),
              ),
            ],
          ),
        ),
        if (state.badges.isNotEmpty)
          Panel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const PanelTitle('Badges earned', icon: Icons.military_tech),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final b in state.badges)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 7),
                        decoration: BoxDecoration(
                          color: fade(AppColors.amber, 0.12),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: fade(AppColors.amber, 0.5)),
                        ),
                        child: Text(
                          b,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.amber,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        FilledButton.icon(
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(54),
            backgroundColor: fade(AppColors.cyan, 0.2),
            foregroundColor: AppColors.cyan,
          ),
          onPressed: _restart,
          icon: const Icon(Icons.restart_alt),
          label: const Text('Start over'),
        ),
      ],
    );
  }
}

enum _ChoiceState { idle, correct, wrong, dimmed }

class _ChoiceTile extends StatelessWidget {
  const _ChoiceTile({
    required this.text,
    required this.letter,
    required this.state,
    required this.onTap,
  });

  final String text;
  final String letter;
  final _ChoiceState state;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final (Color border, Color fg) = switch (state) {
      _ChoiceState.idle => (AppColors.stroke, AppColors.text),
      _ChoiceState.correct => (AppColors.cyan, AppColors.cyan),
      _ChoiceState.wrong => (AppColors.red, AppColors.red),
      _ChoiceState.dimmed => (AppColors.stroke, AppColors.textDim),
    };

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: state == _ChoiceState.idle
            ? AppColors.surfaceHigh
            : fade(border, 0.1),
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: state == _ChoiceState.idle ? onTap : null,
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
