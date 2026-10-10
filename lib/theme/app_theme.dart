import 'package:flutter/material.dart';

import 'portfolio_transitions.dart';

abstract final class AppTheme {
  static const ink = Color(0xFF29354A);
  static const muted = Color(0xFF68778C);
  static const border = Color(0xFFD5DEEB);
  static const canvas = Color(0xFFE9EEF5);
  static const surfaceRaised = Color(0xFFEEF2F8);
  static const blue = Color(0xFF4D65D9);
  static const green = Color(0xFF2E8A68);
  static const raisedShadows = [
    BoxShadow(color: Color(0xBFFFFFFF), offset: Offset(-6, -6), blurRadius: 14),
    BoxShadow(color: Color(0x2673839A), offset: Offset(6, 6), blurRadius: 14),
  ];

  static ThemeData get light {
    final scheme = ColorScheme.fromSeed(
      seedColor: blue,
      primary: blue,
      surface: canvas,
    );

    return ThemeData(
      useMaterial3: true,
      pageTransitionsTheme: PageTransitionsTheme(
        builders: {
          for (final platform in TargetPlatform.values)
            platform: PortfolioPageTransitionsBuilder(),
        },
      ),
      colorScheme: scheme,
      scaffoldBackgroundColor: canvas,
      fontFamily: 'Arial',
      textTheme: const TextTheme(
        bodyMedium: TextStyle(color: ink, fontSize: 14),
        bodySmall: TextStyle(color: muted, fontSize: 12),
        titleLarge: TextStyle(
          color: ink,
          fontSize: 24,
          fontWeight: FontWeight.w600,
        ),
        titleMedium: TextStyle(
          color: ink,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: canvas,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 15,
          vertical: 13,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: const BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: const BorderSide(color: blue, width: 1.5),
        ),
      ),
      cardTheme: CardThemeData(
        color: canvas,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: Color(0x66FFFFFF)),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: blue,
          foregroundColor: Colors.white,
          elevation: 3,
          shadowColor: blue.withValues(alpha: .25),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(13),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: ink,
          side: const BorderSide(color: border),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(13),
          ),
        ),
      ),
    );
  }
}
