import 'package:flutter/material.dart';

// Farben laut Vorgaben
const Color kPrimary = Color(0xFF0384F4);
const Color kAccent = Color(0xFFFFA521);
const Color kNeutralGray = Color(0xFF4F4F4F);

ThemeData buildLightTheme() {
  final colorScheme = ColorScheme.fromSeed(seedColor: kPrimary).copyWith(
    primary: kPrimary,
    secondary: kAccent,
  );
  return ThemeData(
    colorScheme: colorScheme,
    useMaterial3: true,
    scaffoldBackgroundColor: Colors.white,
    appBarTheme: const AppBarTheme(centerTitle: true),
    textTheme: const TextTheme().apply(
      bodyColor: kNeutralGray,
      displayColor: kNeutralGray,
    ),
    cardTheme: CardTheme(
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: kPrimary,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    ),
  );
}

ThemeData buildDarkTheme() {
  final colorScheme = ColorScheme.fromSeed(
    seedColor: kPrimary,
    brightness: Brightness.dark,
  ).copyWith(primary: kPrimary, secondary: kAccent);
  return ThemeData(
    colorScheme: colorScheme,
    useMaterial3: true,
    cardTheme: CardTheme(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: kPrimary,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    ),
  );
}
