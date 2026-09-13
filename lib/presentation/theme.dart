import 'package:flutter/material.dart';

ThemeData personalTheme(Brightness brightness) {
  final dark = brightness == Brightness.dark;
  final scheme = ColorScheme.fromSeed(
    seedColor: const Color(0xff3978e6),
    brightness: brightness,
    surface: dark ? const Color(0xff191d25) : const Color(0xffffffff),
  );
  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: scheme,
    scaffoldBackgroundColor: dark
        ? const Color(0xff12151b)
        : const Color(0xfff5f7fb),
    fontFamily: 'Segoe UI',
    textTheme: TextTheme(
      headlineMedium: TextStyle(
        fontSize: 30,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.8,
        color: scheme.onSurface,
      ),
      displaySmall: TextStyle(
        fontSize: 34,
        fontWeight: FontWeight.w700,
        letterSpacing: -1.1,
        color: scheme.onSurface,
      ),
      titleLarge: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
      titleMedium: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      bodyMedium: const TextStyle(fontSize: 14, height: 1.5),
    ),
    cardTheme: CardThemeData(
      elevation: dark ? 0 : 1,
      color: scheme.surface,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: scheme.outlineVariant.withValues(alpha: .45)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: scheme.outlineVariant),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: scheme.outlineVariant.withValues(alpha: .7),
        ),
      ),
      filled: true,
      fillColor: scheme.surface,
      contentPadding: const EdgeInsets.all(14),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 17),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
      ),
    ),
    navigationRailTheme: NavigationRailThemeData(
      indicatorColor: scheme.primaryContainer,
      selectedIconTheme: IconThemeData(color: scheme.primary),
      selectedLabelTextStyle: TextStyle(
        color: scheme.primary,
        fontWeight: FontWeight.w700,
      ),
    ),
    dividerTheme: DividerThemeData(
      color: scheme.outlineVariant.withValues(alpha: .6),
      space: 24,
    ),
  );
}
