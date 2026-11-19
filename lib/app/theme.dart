import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Paleta "Rumbo": azul noche profundo con acentos menta (tú) y coral (destino).
class AppColors {
  AppColors._();

  static const ink = Color(0xFF080E1C);
  static const surface = Color(0xFF0F1729);
  static const card = Color(0xFF141E35);
  static const cardHigh = Color(0xFF1B2744);
  static const line = Color(0xFF26334F);

  static const mint = Color(0xFF34E5B0);
  static const sky = Color(0xFF5AA9FF);
  static const coral = Color(0xFFFF6B5B);
  static const amber = Color(0xFFFFC857);

  static const text = Color(0xFFEAF0FF);
  static const muted = Color(0xFF8D9AB8);
  static const faint = Color(0xFF5B6886);
}

ThemeData buildRumboTheme() {
  final base = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.mint,
      brightness: Brightness.dark,
      primary: AppColors.mint,
      onPrimary: AppColors.ink,
      secondary: AppColors.sky,
      error: AppColors.coral,
      surface: AppColors.surface,
    ),
  );

  final textTheme = GoogleFonts.spaceGroteskTextTheme(base.textTheme).apply(
    bodyColor: AppColors.text,
    displayColor: AppColors.text,
  );

  return base.copyWith(
    scaffoldBackgroundColor: AppColors.ink,
    textTheme: textTheme,
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: AppColors.cardHigh,
      contentTextStyle: textTheme.bodyMedium?.copyWith(color: AppColors.text),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.mint,
        foregroundColor: AppColors.ink,
        textStyle: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.text,
        side: const BorderSide(color: AppColors.line),
        textStyle: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      ),
    ),
  );
}

/// Tipografía monoespaciada para coordenadas y cifras técnicas.
TextStyle mono({
  double size = 13,
  Color color = AppColors.text,
  FontWeight weight = FontWeight.w500,
}) {
  return GoogleFonts.jetBrainsMono(
    fontSize: size,
    color: color,
    fontWeight: weight,
  );
}
