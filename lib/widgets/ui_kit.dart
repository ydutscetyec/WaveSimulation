import 'package:flutter/material.dart';

import '../theme/wave_theme.dart';

/// Standard screen shell.
class LabScaffold extends StatelessWidget {
  const LabScaffold({
    super.key,
    required this.title,
    required this.child,
    this.subtitle,
    this.actions,
    this.padding = const EdgeInsets.fromLTRB(16, 4, 16, 32),
  });

  final String title;
  final String? subtitle;
  final Widget child;
  final List<Widget>? actions;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Scaffold(
      backgroundColor: c.bg,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title),
            if (subtitle != null)
              Text(
                subtitle!,
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w500,
                  color: c.textTertiary,
                ),
              ),
          ],
        ),
        actions: actions,
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: padding,
          child: child,
        ),
      ),
    );
  }
}

/// Content card.
class Panel extends StatelessWidget {
  const Panel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin = const EdgeInsets.only(bottom: 14),
    this.accent,
  });

  final Widget child;
  final EdgeInsets padding;
  final EdgeInsets margin;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Container(
      width: double.infinity,
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: accent ?? c.stroke,
          width: accent == null ? 1 : 1.5,
        ),
      ),
      child: child,
    );
  }
}

class PanelTitle extends StatelessWidget {
  const PanelTitle(this.text, {super.key, this.icon, this.trailing});

  final String text;
  final IconData? icon;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 20, color: c.accent),
            const SizedBox(width: 9),
          ],
          Expanded(
            child: Text(text, style: Theme.of(context).textTheme.titleMedium),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

/// A live readout. Label quiet, number loud.
class ValueCard extends StatelessWidget {
  const ValueCard({
    super.key,
    required this.label,
    required this.value,
    this.unit,
    this.color,
    this.compact = false,
  });

  final String label;
  final String value;
  final String? unit;
  final Color? color;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final col = color ?? c.accent;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: compact ? 9 : 12),
      decoration: BoxDecoration(
        color: c.surfaceAlt,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: fade(col, 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: c.textTertiary,
            ),
          ),
          const SizedBox(height: 3),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: compact ? 19 : 22,
                    fontWeight: FontWeight.w800,
                    color: col,
                  ),
                ),
                if (unit != null) ...[
                  const SizedBox(width: 4),
                  Text(
                    unit!,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: c.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Home-screen navigation tile.
class BigButton extends StatelessWidget {
  const BigButton({
    super.key,
    required this.label,
    required this.detail,
    required this.icon,
    required this.onTap,
    this.primary = false,
  });

  final String label;
  final String detail;
  final IconData icon;
  final VoidCallback onTap;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Material(
      color: primary ? fade(c.accent, 0.12) : c.surface,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 70),
          padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: primary ? c.accent : c.stroke,
              width: primary ? 1.6 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(icon, size: 27, color: primary ? c.accent : c.blue),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 17.5,
                        fontWeight: FontWeight.w700,
                        color: primary ? c.accent : c.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      detail,
                      style: TextStyle(
                        fontSize: 13.5,
                        height: 1.3,
                        color: c.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: c.textTertiary),
            ],
          ),
        ),
      ),
    );
  }
}

/// One-line teaching note.
class Tip extends StatelessWidget {
  const Tip(this.text, {super.key, this.icon = Icons.lightbulb_outline, this.color});

  final String text;
  final IconData icon;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final col = color ?? c.blue;
    return Container(
      padding: const EdgeInsets.fromLTRB(13, 12, 13, 12),
      decoration: BoxDecoration(
        color: fade(col, 0.10),
        borderRadius: BorderRadius.circular(14),
        border: Border(left: BorderSide(color: col, width: 3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 19, color: col),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14.5,
                height: 1.45,
                color: c.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Slider with - and + buttons sized for thumbs.
class StepSlider extends StatelessWidget {
  const StepSlider({
    super.key,
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.readout,
    required this.onChanged,
    this.step,
    this.divisions,
    this.color,
  });

  final String label;
  final double value;
  final double min;
  final double max;
  final String readout;
  final ValueChanged<double> onChanged;
  final double? step;
  final int? divisions;
  final Color? color;

  void _nudge(double sign) {
    final s = step ?? (max - min) / 40;
    onChanged((value + sign * s).clamp(min, max));
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final col = color ?? c.accent;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: c.textSecondary,
                ),
              ),
            ),
            Text(
              readout,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: col,
              ),
            ),
          ],
        ),
        Row(
          children: [
            _RoundBtn(icon: Icons.remove, onTap: () => _nudge(-1)),
            Expanded(
              child: SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: col,
                  thumbColor: col,
                  overlayColor: fade(col, 0.16),
                ),
                child: Slider(
                  value: value.clamp(min, max),
                  min: min,
                  max: max,
                  divisions: divisions,
                  onChanged: onChanged,
                ),
              ),
            ),
            _RoundBtn(icon: Icons.add, onTap: () => _nudge(1)),
          ],
        ),
      ],
    );
  }
}

class _RoundBtn extends StatelessWidget {
  const _RoundBtn({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Material(
      color: c.surfaceAlt,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 46,
          height: 46,
          child: Icon(icon, size: 24, color: c.textPrimary),
        ),
      ),
    );
  }
}

/// Horizontal selector.
class ChipRow<T> extends StatelessWidget {
  const ChipRow({
    super.key,
    required this.items,
    required this.labelOf,
    required this.selected,
    required this.onSelect,
    this.colorOf,
  });

  final List<T> items;
  final String Function(T) labelOf;
  final T? selected;
  final ValueChanged<T> onSelect;
  final Color Function(T, WaveColors)? colorOf;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return SizedBox(
      height: 46,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 9),
        itemBuilder: (context, i) {
          final item = items[i];
          final isSel = item == selected;
          final col = colorOf?.call(item, c) ?? c.accent;
          return Material(
            color: isSel ? fade(col, 0.16) : c.surfaceAlt,
            borderRadius: BorderRadius.circular(13),
            child: InkWell(
              borderRadius: BorderRadius.circular(13),
              onTap: () => onSelect(item),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 17),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(13),
                  border: Border.all(
                    color: isSel ? col : c.stroke,
                    width: isSel ? 1.7 : 1,
                  ),
                ),
                child: Text(
                  labelOf(item),
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: isSel ? col : c.textSecondary,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Compact equal-width segmented control.
class Segmented extends StatelessWidget {
  const Segmented({
    super.key,
    required this.labels,
    required this.selectedIndex,
    required this.onSelect,
  });

  final List<String> labels;
  final int selectedIndex;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: c.surfaceAlt,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: c.stroke),
      ),
      child: Row(
        children: [
          for (var i = 0; i < labels.length; i++)
            Expanded(
              child: InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () => onSelect(i),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 11),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: i == selectedIndex
                        ? fade(c.accent, 0.18)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    labels[i],
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      color: i == selectedIndex ? c.accent : c.textTertiary,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Body copy at a guaranteed-readable size.
class Body extends StatelessWidget {
  const Body(this.text, {super.key, this.color, this.size = 14.5});

  final String text;
  final Color? color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: size,
        height: 1.5,
        color: color ?? context.c.textSecondary,
      ),
    );
  }
}

/// Theme switch for app bars.
class ThemeToggle extends StatelessWidget {
  const ThemeToggle({super.key, required this.isDark, required this.onTap});

  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: isDark ? 'Switch to light mode' : 'Switch to dark mode',
      icon: Icon(isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined),
      onPressed: onTap,
    );
  }
}
