import 'package:flutter/material.dart';

import 'portfolio_transitions.dart';

abstract final class PortfolioTheme {
  static const background = Color(0xFFE9EEF5);
  static const surface = background;
  static const surfaceRaised = Color(0xFFEEF2F8);
  static const border = Color(0xFFD5DEEB);
  static const text = Color(0xFF29354A);
  static const muted = Color(0xFF68778C);
  static const blue = Color(0xFF4D65D9);
  static const cyan = Color(0xFF25849B);
  static const purple = Color(0xFF795BC7);
  static const green = Color(0xFF2E8A68);
  static const raisedShadows = [
    BoxShadow(color: Color(0xBFFFFFFF), offset: Offset(-7, -7), blurRadius: 18),
    BoxShadow(color: Color(0x2673839A), offset: Offset(7, 7), blurRadius: 18),
  ];

  static ThemeData get light => ThemeData(
    useMaterial3: true,
    pageTransitionsTheme: PageTransitionsTheme(
      builders: {
        for (final platform in TargetPlatform.values)
          platform: PortfolioPageTransitionsBuilder(),
      },
    ),
    brightness: Brightness.light,
    scaffoldBackgroundColor: background,
    colorScheme: const ColorScheme.light(
      primary: blue,
      secondary: cyan,
      surface: surface,
      onSurface: text,
    ),
    fontFamily: 'Arial',
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: text, height: 1.65),
      bodyMedium: TextStyle(color: text, height: 1.6),
      bodySmall: TextStyle(color: muted, height: 1.5),
      titleLarge: TextStyle(
        color: text,
        fontSize: 32,
        fontWeight: FontWeight.w700,
      ),
      titleMedium: TextStyle(
        color: text,
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: background,
      hintStyle: const TextStyle(color: muted),
      labelStyle: const TextStyle(color: muted),
      contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 14),
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
      color: background,
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: text,
        side: const BorderSide(color: border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
      ),
    ),
  );
}
