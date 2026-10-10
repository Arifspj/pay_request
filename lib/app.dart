import 'package:flutter/material.dart';

export 'screens/main_shell.dart';

class AppTheme {
  static const Color primary = Color(0xFF004AC6);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color primaryContainer = Color(0xFF2563EB);
  static const Color onPrimaryContainer = Color(0xFFEEEFFF);
  static const Color secondary = Color(0xFF006E2D);
  static const Color onSecondary = Color(0xFFFFFFFF);
  static const Color secondaryContainer = Color(0xFF7CF994);
  static const Color onSecondaryContainer = Color(0xFF007230);
  static const Color secondaryFixedDim = Color(0xFF62DF7D);
  static const Color tertiary = Color(0xFFAE0010);
  static const Color background = Color(0xFFF7F9FB);
  static const Color surface = Color(0xFFF7F9FB);
  static const Color surfaceBright = Color(0xFFF7F9FB);
  static const Color surfaceDim = Color(0xFFD8DADC);
  static const Color surfaceContainerLowest = Color(0xFFFFFFFF);
  static const Color surfaceContainerLow = Color(0xFFF2F4F6);
  static const Color surfaceContainer = Color(0xFFECEEF0);
  static const Color surfaceContainerHigh = Color(0xFFE6E8EA);
  static const Color surfaceContainerHighest = Color(0xFFE0E3E5);
  static const Color onBackground = Color(0xFF191C1E);
  static const Color onSurface = Color(0xFF191C1E);
  static const Color onSurfaceVariant = Color(0xFF434655);
  static const Color outline = Color(0xFF737686);
  static const Color outlineVariant = Color(0xFFC3C6D7);
  static const Color error = Color(0xFFBA1A1A);
  static const Color errorContainer = Color(0xFFFFDAD6);
  static const Color onError = Color(0xFFFFFFFF);
  static const Color onErrorContainer = Color(0xFF93000A);
  static const Color inversePrimary = Color(0xFFB4C5FF);
  static const Color inverseSurface = Color(0xFF2D3133);
  static const Color inverseOnSurface = Color(0xFFEFF1F3);
  static const Color amber = Color(0xFFD97706);

  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: const ColorScheme.light(
      primary: primary,
      onPrimary: onPrimary,
      primaryContainer: primaryContainer,
      onPrimaryContainer: onPrimaryContainer,
      secondary: secondary,
      onSecondary: onSecondary,
      secondaryContainer: secondaryContainer,
      onSecondaryContainer: onSecondaryContainer,
      tertiary: tertiary,
      surface: surface,
      onSurface: onSurface,
      outline: outline,
      outlineVariant: outlineVariant,
      error: error,
      onError: onError,
      errorContainer: errorContainer,
      inversePrimary: inversePrimary,
      inverseSurface: inverseSurface,
      surfaceContainerLowest: surfaceContainerLowest,
      surfaceContainerLow: surfaceContainerLow,
      surfaceContainer: surfaceContainer,
      surfaceContainerHigh: surfaceContainerHigh,
    ),
    scaffoldBackgroundColor: background,
    fontFamily: 'Inter',
    appBarTheme: const AppBarTheme(
      backgroundColor: surface,
      foregroundColor: primary,
      elevation: 0,
      centerTitle: true,
      scrolledUnderElevation: 0,
      titleTextStyle: TextStyle(
        fontFamily: 'Inter',
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: primary,
      ),
    ),
    cardTheme: CardThemeData(
      color: surfaceContainerLowest,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: onPrimary,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(vertical: 16),
        textStyle: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: surfaceContainerLowest,
      selectedItemColor: secondary,
      unselectedItemColor: onSurfaceVariant,
      type: BottomNavigationBarType.fixed,
      elevation: 8,
      selectedLabelStyle: const TextStyle(
        fontFamily: 'Inter',
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
      unselectedLabelStyle: const TextStyle(
        fontFamily: 'Inter',
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
    ),
  );

  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: const ColorScheme.dark(
      primary: Color(0xFF3B82F6),
      onPrimary: Colors.white,
      primaryContainer: Color(0xFF1E3A8A),
      onPrimaryContainer: Color(0xFFDBE1FF),
      secondary: Color(0xFF4ADE80),
      onSecondary: Color(0xFF064E3B),
      secondaryContainer: Color(0xFF065F46),
      onSecondaryContainer: Color(0xFFD1FAE5),
      tertiary: Color(0xFFFDA4AF),
      surface: Color(0xFF020617),
      onSurface: Color(0xFFF1F5F9),
      outline: Color(0xFF94A3B8),
      outlineVariant: Color(0xFF334155),
      error: Color(0xFFF87171),
      onError: Color(0xFF450A0A),
      errorContainer: Color(0xFF7F1D1D),
      inversePrimary: Color(0xFF2563EB),
      inverseSurface: Color(0xFFE2E2E6),
      surfaceContainerLowest: Color(0xFF0F172A),
      surfaceContainerLow: Color(0xFF172554),
      surfaceContainer: Color(0xFF1E3A8A),
      surfaceContainerHigh: Color(0xFF1E3A8A),
    ),
    scaffoldBackgroundColor: const Color(0xFF020617),
    fontFamily: 'Inter',
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF020617),
      foregroundColor: Color(0xFF60A5FA),
      elevation: 0,
      centerTitle: true,
      scrolledUnderElevation: 0,
      titleTextStyle: TextStyle(
        fontFamily: 'Inter',
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: Color(0xFF60A5FA),
      ),
    ),
    drawerTheme: const DrawerThemeData(
      backgroundColor: Color(0xFF0F172A),
      elevation: 0,
    ),
    cardTheme: CardThemeData(
      color: const Color(0xFF1E293B),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF2563EB),
        foregroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(vertical: 16),
        textStyle: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: const Color(0xFF2563EB),
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: Color(0xFF2563EB),
      foregroundColor: Colors.white,
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: const Color(0xFF0F172A),
      selectedItemColor: const Color(0xFF4ADE80),
      unselectedItemColor: const Color(0xFF94A3B8),
      type: BottomNavigationBarType.fixed,
      elevation: 8,
      selectedLabelStyle: const TextStyle(
        fontFamily: 'Inter',
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
      unselectedLabelStyle: const TextStyle(
        fontFamily: 'Inter',
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
    ),
  );
}
