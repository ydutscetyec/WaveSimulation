import 'package:flutter/material.dart';

/// Colour roles for the whole app. Nothing anywhere hard-codes a hex value:
/// widgets and painters read from the palette that matches the current
/// brightness, which is what makes a real light mode possible.
@immutable
class WaveColors extends ThemeExtension<WaveColors> {
  const WaveColors({
    required this.bg,
    required this.surface,
    required this.surfaceAlt,
    required this.stroke,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.accent,
    required this.onAccent,
    required this.blue,
    required this.amber,
    required this.red,
    required this.compression,
    required this.rarefaction,
    required this.canvasTop,
    required this.canvasBottom,
    required this.wood,
    required this.glass,
    required this.steel,
    required this.wall,
  });

  final Color bg;
  final Color surface;
  final Color surfaceAlt;
  final Color stroke;

  final Color textPrimary; // headings and values
  final Color textSecondary; // body text
  final Color textTertiary; // labels and captions - still AA at 14sp

  final Color accent;
  final Color onAccent;
  final Color blue;
  final Color amber;
  final Color red;

  final Color compression;
  final Color rarefaction;
  final Color canvasTop;
  final Color canvasBottom;

  final Color wood;
  final Color glass;
  final Color steel;
  final Color wall;

  /// Dark: deep navy, cyan wavefront.
  static const WaveColors dark = WaveColors(
    bg: Color(0xFF0A1020),
    surface: Color(0xFF131E36),
    surfaceAlt: Color(0xFF1C2946),
    stroke: Color(0xFF2B3C60),
    textPrimary: Color(0xFFF3F7FF),
    textSecondary: Color(0xFFB4C6DC),
    textTertiary: Color(0xFF8CA1BC),
    accent: Color(0xFF32E0E0),
    onAccent: Color(0xFF04222A),
    blue: Color(0xFF6BA8FF),
    amber: Color(0xFFFFBC5C),
    red: Color(0xFFFF7A7A),
    compression: Color(0xFF3FF0F0),
    rarefaction: Color(0xFF32487F),
    canvasTop: Color(0xFF0C1832),
    canvasBottom: Color(0xFF060C1A),
    wood: Color(0xFFD69A5C),
    glass: Color(0xFF9FDCEC),
    steel: Color(0xFFC2CEDC),
    wall: Color(0xFFAEB7C4),
  );

  /// Light: paper white, deep teal wavefront. The accent is darkened because
  /// the dark-mode cyan fails contrast on white.
  static const WaveColors light = WaveColors(
    bg: Color(0xFFF4F7FB),
    surface: Color(0xFFFFFFFF),
    surfaceAlt: Color(0xFFEAF0F8),
    stroke: Color(0xFFCFDAE8),
    textPrimary: Color(0xFF0B1628),
    textSecondary: Color(0xFF3C4F67),
    textTertiary: Color(0xFF5B6E86),
    accent: Color(0xFF0B7C8C),
    onAccent: Color(0xFFFFFFFF),
    blue: Color(0xFF1D5FD4),
    amber: Color(0xFF9A5B00),
    red: Color(0xFFC62828),
    compression: Color(0xFF0B6E7D),
    rarefaction: Color(0xFFA9C0D8),
    canvasTop: Color(0xFFE8F1F7),
    canvasBottom: Color(0xFFDCE8F2),
    wood: Color(0xFF9A6327),
    glass: Color(0xFF2A7E96),
    steel: Color(0xFF55657A),
    wall: Color(0xFF6E7A8A),
  );

  @override
  WaveColors copyWith({
    Color? bg,
    Color? surface,
    Color? surfaceAlt,
    Color? stroke,
    Color? textPrimary,
    Color? textSecondary,
    Color? textTertiary,
    Color? accent,
    Color? onAccent,
    Color? blue,
    Color? amber,
    Color? red,
    Color? compression,
    Color? rarefaction,
    Color? canvasTop,
    Color? canvasBottom,
    Color? wood,
    Color? glass,
    Color? steel,
    Color? wall,
  }) {
    return WaveColors(
      bg: bg ?? this.bg,
      surface: surface ?? this.surface,
      surfaceAlt: surfaceAlt ?? this.surfaceAlt,
      stroke: stroke ?? this.stroke,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textTertiary: textTertiary ?? this.textTertiary,
      accent: accent ?? this.accent,
      onAccent: onAccent ?? this.onAccent,
      blue: blue ?? this.blue,
      amber: amber ?? this.amber,
      red: red ?? this.red,
      compression: compression ?? this.compression,
      rarefaction: rarefaction ?? this.rarefaction,
      canvasTop: canvasTop ?? this.canvasTop,
      canvasBottom: canvasBottom ?? this.canvasBottom,
      wood: wood ?? this.wood,
      glass: glass ?? this.glass,
      steel: steel ?? this.steel,
      wall: wall ?? this.wall,
    );
  }

  @override
  WaveColors lerp(ThemeExtension<WaveColors>? other, double t) {
    if (other is! WaveColors) return this;
    Color c(Color a, Color b) => Color.lerp(a, b, t) ?? a;
    return WaveColors(
      bg: c(bg, other.bg),
      surface: c(surface, other.surface),
      surfaceAlt: c(surfaceAlt, other.surfaceAlt),
      stroke: c(stroke, other.stroke),
      textPrimary: c(textPrimary, other.textPrimary),
      textSecondary: c(textSecondary, other.textSecondary),
      textTertiary: c(textTertiary, other.textTertiary),
      accent: c(accent, other.accent),
      onAccent: c(onAccent, other.onAccent),
      blue: c(blue, other.blue),
      amber: c(amber, other.amber),
      red: c(red, other.red),
      compression: c(compression, other.compression),
      rarefaction: c(rarefaction, other.rarefaction),
      canvasTop: c(canvasTop, other.canvasTop),
      canvasBottom: c(canvasBottom, other.canvasBottom),
      wood: c(wood, other.wood),
      glass: c(glass, other.glass),
      steel: c(steel, other.steel),
      wall: c(wall, other.wall),
    );
  }
}

/// Short reach for the palette: `context.c.accent`.
extension WaveColorsContext on BuildContext {
  WaveColors get c =>
      Theme.of(this).extension<WaveColors>() ?? WaveColors.dark;
}

/// Opacity without the deprecated withOpacity.
Color fade(Color color, double opacity) =>
    color.withAlpha((opacity.clamp(0.0, 1.0) * 255).round());

class WaveTheme {
  const WaveTheme._();

  static ThemeData dark() => _build(Brightness.dark, WaveColors.dark);
  static ThemeData light() => _build(Brightness.light, WaveColors.light);

  static ThemeData _build(Brightness brightness, WaveColors c) {
    // Body text is never smaller than 15sp and never lighter than
    // textTertiary, which is the invisible-text fix from v1.
    final text = TextTheme(
      displaySmall: TextStyle(
        fontSize: 34,
        fontWeight: FontWeight.w800,
        letterSpacing: 2.5,
        color: c.textPrimary,
      ),
      headlineSmall: TextStyle(
        fontSize: 23,
        fontWeight: FontWeight.w700,
        color: c.textPrimary,
      ),
      titleMedium: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: c.textPrimary,
      ),
      bodyLarge: TextStyle(fontSize: 16, height: 1.45, color: c.textPrimary),
      bodyMedium: TextStyle(fontSize: 15, height: 1.45, color: c.textSecondary),
      labelLarge: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: c.textPrimary,
      ),
      labelSmall: TextStyle(fontSize: 13.5, color: c.textTertiary),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      scaffoldBackgroundColor: c.bg,
      canvasColor: c.bg,
      colorScheme: ColorScheme.fromSeed(
        seedColor: c.accent,
        brightness: brightness,
      ).copyWith(
        primary: c.accent,
        onPrimary: c.onAccent,
        surface: c.surface,
        onSurface: c.textPrimary,
        error: c.red,
      ),
      textTheme: text,
      iconTheme: IconThemeData(color: c.textSecondary),
      dividerColor: c.stroke,
      appBarTheme: AppBarTheme(
        backgroundColor: c.bg,
        surfaceTintColor: Colors.transparent,
        foregroundColor: c.textPrimary,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: c.textPrimary,
        ),
        iconTheme: IconThemeData(color: c.textPrimary, size: 26),
      ),
      sliderTheme: SliderThemeData(
        trackHeight: 9,
        activeTrackColor: c.accent,
        inactiveTrackColor: c.stroke,
        thumbColor: c.accent,
        overlayColor: fade(c.accent, 0.16),
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 13),
        overlayShape: const RoundSliderOverlayShape(overlayRadius: 26),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: c.surfaceAlt,
        contentTextStyle: TextStyle(color: c.textPrimary, fontSize: 15),
        behavior: SnackBarBehavior.floating,
      ),
      extensions: <ThemeExtension<dynamic>>[c],
    );
  }
}
