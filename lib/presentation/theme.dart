import 'package:flutter/material.dart';

/// Product-level visual tokens for Personal OS.
///
/// Blue carries navigation and primary actions, teal communicates healthy
/// progress, while the neutral surfaces keep dense planning screens calm.
abstract final class PersonalColors {
  static const primary = Color(0xff3566d6);
  static const primaryDark = Color(0xff8eafff);
  static const success = Color(0xff167c63);
  static const warning = Color(0xffa96810);
  static const ownership = Color(0xff7456b8);
  static const capital = Color(0xffa96810);
}

ThemeData personalTheme(Brightness brightness) {
  final dark = brightness == Brightness.dark;
  final scheme =
      ColorScheme.fromSeed(
        seedColor: dark ? PersonalColors.primaryDark : PersonalColors.primary,
        brightness: brightness,
      ).copyWith(
        primary: dark ? PersonalColors.primaryDark : PersonalColors.primary,
        onPrimary: dark ? const Color(0xff102452) : Colors.white,
        primaryContainer: dark
            ? const Color(0xff203661)
            : const Color(0xffe8efff),
        onPrimaryContainer: dark
            ? const Color(0xffdce6ff)
            : const Color(0xff16305f),
        secondary: dark ? const Color(0xff65d1b4) : PersonalColors.success,
        secondaryContainer: dark
            ? const Color(0xff153e35)
            : const Color(0xffddf5ee),
        onSecondaryContainer: dark
            ? const Color(0xffc9f7e9)
            : const Color(0xff0d4d3e),
        surface: dark ? const Color(0xff171c25) : const Color(0xfffffefe),
        surfaceContainerLowest: dark
            ? const Color(0xff131820)
            : const Color(0xffffffff),
        surfaceContainerLow: dark
            ? const Color(0xff1c222d)
            : const Color(0xfff6f7fa),
        surfaceContainer: dark
            ? const Color(0xff222936)
            : const Color(0xffeff1f5),
        surfaceContainerHigh: dark
            ? const Color(0xff29313f)
            : const Color(0xffe7eaf0),
        onSurface: dark ? const Color(0xfff1f3f8) : const Color(0xff172033),
        onSurfaceVariant: dark
            ? const Color(0xffadb7c7)
            : const Color(0xff5e6879),
        outline: dark ? const Color(0xff667184) : const Color(0xff8993a5),
        outlineVariant: dark
            ? const Color(0xff333c4a)
            : const Color(0xffdce1e9),
        error: dark ? const Color(0xffffb4ab) : const Color(0xffba1a1a),
      );
  final radius = BorderRadius.circular(14);
  final controlShape = RoundedRectangleBorder(borderRadius: radius);

  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: scheme,
    scaffoldBackgroundColor: dark
        ? const Color(0xff10141b)
        : const Color(0xfff4f6f9),
    fontFamily: 'Segoe UI',
    visualDensity: VisualDensity.standard,
    focusColor: scheme.primary.withValues(alpha: .18),
    hoverColor: scheme.primary.withValues(alpha: dark ? .10 : .06),
    splashColor: scheme.primary.withValues(alpha: .12),
    textTheme: TextTheme(
      displaySmall: TextStyle(
        fontSize: 34,
        height: 1.12,
        fontWeight: FontWeight.w700,
        letterSpacing: -1.15,
        color: scheme.onSurface,
      ),
      headlineMedium: TextStyle(
        fontSize: 29,
        height: 1.18,
        fontWeight: FontWeight.w700,
        letterSpacing: -.75,
        color: scheme.onSurface,
      ),
      titleLarge: TextStyle(
        fontSize: 20,
        height: 1.3,
        fontWeight: FontWeight.w600,
        letterSpacing: -.25,
        color: scheme.onSurface,
      ),
      titleMedium: TextStyle(
        fontSize: 16,
        height: 1.35,
        fontWeight: FontWeight.w600,
        color: scheme.onSurface,
      ),
      bodyLarge: TextStyle(fontSize: 16, height: 1.55, color: scheme.onSurface),
      bodyMedium: TextStyle(fontSize: 14, height: 1.5, color: scheme.onSurface),
      bodySmall: TextStyle(
        fontSize: 12.5,
        height: 1.45,
        color: scheme.onSurfaceVariant,
      ),
      labelLarge: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
    ),
    iconTheme: IconThemeData(color: scheme.onSurfaceVariant, size: 20),
    cardTheme: CardThemeData(
      elevation: 0,
      color: scheme.surface,
      surfaceTintColor: Colors.transparent,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: scheme.outlineVariant.withValues(alpha: .82)),
      ),
    ),
    appBarTheme: AppBarTheme(
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      backgroundColor: scheme.surface,
      surfaceTintColor: Colors.transparent,
      foregroundColor: scheme.onSurface,
      titleTextStyle: TextStyle(
        color: scheme.onSurface,
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: scheme.surfaceContainerLow,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: radius,
        borderSide: BorderSide(color: scheme.outlineVariant),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: radius,
        borderSide: BorderSide(color: scheme.outlineVariant),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: radius,
        borderSide: BorderSide(color: scheme.primary, width: 1.8),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: radius,
        borderSide: BorderSide(color: scheme.error),
      ),
      labelStyle: TextStyle(color: scheme.onSurfaceVariant),
      floatingLabelStyle: TextStyle(
        color: scheme.primary,
        fontWeight: FontWeight.w600,
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(44, 46),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        shape: controlShape,
        textStyle: const TextStyle(fontWeight: FontWeight.w600),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(44, 46),
        foregroundColor: scheme.onSurface,
        side: BorderSide(color: scheme.outlineVariant),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
        shape: controlShape,
        textStyle: const TextStyle(fontWeight: FontWeight.w600),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        minimumSize: const Size(44, 44),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
        textStyle: const TextStyle(fontWeight: FontWeight.w600),
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(
        minimumSize: const Size(44, 44),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    listTileTheme: ListTileThemeData(
      iconColor: scheme.onSurfaceVariant,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    dividerTheme: DividerThemeData(
      color: scheme.outlineVariant,
      space: 24,
      thickness: 1,
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: scheme.primary,
      linearTrackColor: scheme.surfaceContainerHigh,
      circularTrackColor: scheme.surfaceContainerHigh,
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: dark ? const Color(0xffe7eaf0) : const Color(0xff202938),
      contentTextStyle: TextStyle(
        color: dark ? const Color(0xff202938) : Colors.white,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: scheme.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: scheme.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
    navigationRailTheme: NavigationRailThemeData(
      indicatorColor: scheme.primaryContainer,
      selectedIconTheme: IconThemeData(color: scheme.primary),
      unselectedIconTheme: IconThemeData(color: scheme.onSurfaceVariant),
      selectedLabelTextStyle: TextStyle(
        color: scheme.primary,
        fontWeight: FontWeight.w700,
      ),
    ),
    scrollbarTheme: ScrollbarThemeData(
      thumbColor: WidgetStatePropertyAll(
        scheme.outline.withValues(alpha: dark ? .62 : .42),
      ),
      radius: const Radius.circular(10),
      thickness: const WidgetStatePropertyAll(6),
    ),
  );
}
