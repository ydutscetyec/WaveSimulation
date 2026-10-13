import 'package:flutter/material.dart';

/// One palette object per brightness. Widgets and painters both read from the
/// same object, so a colour can never be right in one and wrong in the other.
///
/// Contrast targets: body text at least 4.5:1 against its own surface, muted
/// text at least 4.5:1, faint text at least 3.5:1. The old build used a dim
/// slate on near-black that measured about 2.6:1, which is why some labels were
/// unreadable on a phone in daylight.
@immutable
class Pal {
  const Pal({
    required this.isDark,
    required this.bg,
    required this.bgDeep,
    required this.surface,
    required this.surfaceHigh,
    required this.stroke,
    required this.canvasTop,
    required this.canvasBottom,
    required this.accent,
    required this.blue,
    required this.rare,
    required this.warm,
    required this.danger,
    required this.text,
    required this.textMuted,
    required this.textFaint,
    required this.onAccent,
    required this.mapLoRgb,
    required this.mapHiRgb,
  });

  final bool isDark;

  final Color bg;
  final Color bgDeep;
  final Color surface;
  final Color surfaceHigh;
  final Color stroke;

  /// Simulation canvas background gradient.
  final Color canvasTop;
  final Color canvasBottom;

  /// Compression / primary.
  final Color accent;
  final Color blue;

  /// Rarefaction. Must stay visible against the canvas in both themes - this
  /// was the single worst offender in the first build.
  final Color rare;

  /// Reserved for "something is happening now": resonance, echo return,
  /// the tracked particle. Nothing decorative is allowed to use it.
  final Color warm;
  final Color danger;

  final Color text;
  final Color textMuted;
  final Color textFaint;
  final Color onAccent;

  /// Endpoints of the interference amplitude map, as plain 0xRRGGBB integers.
  /// Kept as ints so the pixel buffer can be filled without reading colour
  /// channels off a Color, which is deprecated on newer Flutter.
  final int mapLoRgb;
  final int mapHiRgb;

  static const Pal dark = Pal(
    isDark: true,
    bg: Color(0xFF0A1322),
    bgDeep: Color(0xFF060D18),
    surface: Color(0xFF132033),
    surfaceHigh: Color(0xFF1B2B42),
    stroke: Color(0xFF32486A),
    canvasTop: Color(0xFF0D1B30),
    canvasBottom: Color(0xFF070F1D),
    accent: Color(0xFF3BE0E0),
    blue: Color(0xFF6FB2FF),
    rare: Color(0xFF7B8FC7),
    warm: Color(0xFFFFC166),
    danger: Color(0xFFFF8585),
    text: Color(0xFFEAF2FF),
    textMuted: Color(0xFFBECFE4),
    textFaint: Color(0xFF93A8C2),
    onAccent: Color(0xFF042026),
    mapLoRgb: 0x070F1D,
    mapHiRgb: 0x3BE0E0,
  );

  static const Pal light = Pal(
    isDark: false,
    bg: Color(0xFFEDF2F8),
    bgDeep: Color(0xFFE2EAF4),
    surface: Color(0xFFFFFFFF),
    surfaceHigh: Color(0xFFF1F6FC),
    stroke: Color(0xFFC6D5E8),
    canvasTop: Color(0xFFFFFFFF),
    canvasBottom: Color(0xFFE8F0F8),
    accent: Color(0xFF07808F),
    blue: Color(0xFF1C5FB0),
    rare: Color(0xFF8395B8),
    warm: Color(0xFFA85E00),
    danger: Color(0xFFBE3A2B),
    text: Color(0xFF0C1A2B),
    textMuted: Color(0xFF3C5068),
    textFaint: Color(0xFF5B7085),
    onAccent: Color(0xFFFFFFFF),
    mapLoRgb: 0xF2F7FC,
    mapHiRgb: 0x07808F,
  );
}

/// The palette for the current theme. One call at the top of a build method.
Pal pal(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark ? Pal.dark : Pal.light;

/// Opacity helper that avoids the deprecated withOpacity.
Color fade(Color c, double opacity) =>
    c.withAlpha((opacity.clamp(0.0, 1.0) * 255).round());
