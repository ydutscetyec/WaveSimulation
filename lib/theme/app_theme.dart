import 'package:flutter/material.dart';

/// Single source of truth for colour and type.
/// Dark navy base, cyan wavefront, amber only for "something is happening now"
/// (resonance peak, correct answer). Nothing else is allowed to be amber, so
/// amber keeps its meaning.
class AppColors {
  static const Color bg = Color(0xFF060B18);
  static const Color bgDeep = Color(0xFF030713);
  static const Color surface = Color(0xFF0F1A30);
  static const Color surfaceHigh = Color(0xFF16233F);
  static const Color stroke = Color(0xFF24365C);

  static const Color cyan = Color(0xFF2EE6E6); // compression / primary
  static const Color blue = Color(0xFF4C9BFF); // propagation
  static const Color indigo = Color(0xFF3B4D9E); // rarefaction
  static const Color amber = Color(0xFFFFB547); // resonance, alerts, correct
  static const Color red = Color(0xFFFF6B6B); // wrong answer, absorbed energy

  static const Color text = Color(0xFFF2F7FF);
  static const Color textMuted = Color(0xFF9AAFC9);
  static const Color textDim = Color(0xFF6E829E);
}

/// Opacity helper. Uses withAlpha instead of withOpacity so the project does
/// not emit deprecation warnings on Flutter 3.27+.
Color fade(Color c, double opacity) =>
    c.withAlpha((opacity.clamp(0.0, 1.0) * 255).round());

class AppTheme {
  static ThemeData build() {
    const base = ColorScheme.dark(
      primary: AppColors.cyan,
      onPrimary: Color(0xFF042026),
      secondary: AppColors.blue,
      surface: AppColors.surface,
      onSurface: AppColors.text,
      error: AppColors.red,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: base,
      scaffoldBackgroundColor: AppColors.bg,
      canvasColor: AppColors.bg,
      // Minimum body size is 15sp. Nothing in the app is allowed below 13sp.
      textTheme: const TextTheme(
        displaySmall: TextStyle(
          fontSize: 34,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
          color: AppColors.text,
        ),
        headlineSmall: TextStyle(
          fontSize: 23,
          fontWeight: FontWeight.w700,
          color: AppColors.text,
        ),
        titleMedium: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppColors.text,
        ),
        bodyLarge: TextStyle(fontSize: 16.5, height: 1.45, color: AppColors.text),
        bodyMedium: TextStyle(
          fontSize: 15,
          height: 1.45,
          color: AppColors.textMuted,
        ),
        labelLarge: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: AppColors.text,
        ),
        labelSmall: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.8,
          color: AppColors.textDim,
        ),
      ),
      sliderTheme: SliderThemeData(
        trackHeight: 8,
        activeTrackColor: AppColors.cyan,
        inactiveTrackColor: AppColors.stroke,
        thumbColor: AppColors.cyan,
        overlayColor: fade(AppColors.cyan, 0.18),
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 13),
        overlayShape: const RoundSliderOverlayShape(overlayRadius: 26),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: AppColors.text,
        ),
        iconTheme: IconThemeData(color: AppColors.text, size: 26),
      ),
    );
  }
}
