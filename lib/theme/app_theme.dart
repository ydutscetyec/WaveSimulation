import 'package:flutter/material.dart';

import 'palette.dart';

class AppTheme {
  const AppTheme._();

  static ThemeData dark() => _build(Pal.dark, Brightness.dark);
  static ThemeData light() => _build(Pal.light, Brightness.light);

  static ThemeData _build(Pal p, Brightness brightness) {
    // Minimum font size anywhere in the app is 13.5. Body copy is 15.5.
    final text = TextTheme(
      displaySmall: TextStyle(
        fontSize: 33,
        fontWeight: FontWeight.w700,
        letterSpacing: 2.5,
        color: p.text,
      ),
      headlineSmall: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: p.text,
      ),
      titleMedium: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: p.text,
      ),
      bodyLarge: TextStyle(fontSize: 16, height: 1.45, color: p.text),
      bodyMedium: TextStyle(fontSize: 15.5, height: 1.5, color: p.textMuted),
      labelLarge: TextStyle(
        fontSize: 15.5,
        fontWeight: FontWeight.w600,
        color: p.text,
      ),
      labelSmall: TextStyle(fontSize: 13.5, color: p.textFaint),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: ColorScheme.fromSeed(
        seedColor: p.accent,
        brightness: brightness,
        primary: p.accent,
        onPrimary: p.onAccent,
        surface: p.surface,
        onSurface: p.text,
        error: p.danger,
      ),
      scaffoldBackgroundColor: p.bg,
      canvasColor: p.bg,
      textTheme: text,
      dividerColor: p.stroke,
      sliderTheme: SliderThemeData(
        trackHeight: 8,
        activeTrackColor: p.accent,
        inactiveTrackColor: p.stroke,
        thumbColor: p.accent,
        overlayColor: fade(p.accent, 0.18),
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 13),
        overlayShape: const RoundSliderOverlayShape(overlayRadius: 26),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: p.text,
        ),
        iconTheme: IconThemeData(color: p.text, size: 26),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: p.surfaceHigh,
        contentTextStyle: TextStyle(color: p.text, fontSize: 15),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
