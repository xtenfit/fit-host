import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTheme {
  static ThemeData get darkTheme {
    final colorScheme = ColorScheme(
      brightness: Brightness.dark,
      primary: AppColors.electricBlue,
      onPrimary: Colors.white,
      primaryContainer: AppColors.electricBlueSurface,
      onPrimaryContainer: AppColors.electricBlueLight,
      secondary: AppColors.limeGreen,
      onSecondary: Colors.black,
      secondaryContainer: const Color(0xFF0F3822),
      onSecondaryContainer: AppColors.limeGreen,
      surface: AppColors.darkSurface,
      onSurface: AppColors.darkTextPrimary,
      surfaceContainerHighest: AppColors.darkSurfaceElevated,
      error: AppColors.error,
      onError: Colors.white,
      outline: AppColors.darkSurfaceBorder,
      outlineVariant: const Color(0xFF384352),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      fontFamily: 'Arial',
      fontFamilyFallback: const ['Roboto', 'SF Pro Display', 'SF Pro Text', '-apple-system', 'sans-serif'],
      scaffoldBackgroundColor: AppColors.darkBackground,
      colorScheme: colorScheme,
      cardTheme: CardThemeData(
        color: AppColors.darkSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: AppColors.darkSurfaceBorder, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(fontFamily: 'Arial', fontSize: 32, fontWeight: FontWeight.w800, letterSpacing: -0.6, height: 1.2, color: AppColors.darkTextPrimary),
        headlineMedium: TextStyle(fontFamily: 'Arial', fontSize: 26, fontWeight: FontWeight.w800, letterSpacing: -0.5, height: 1.2, color: AppColors.darkTextPrimary),
        headlineSmall: TextStyle(fontFamily: 'Arial', fontSize: 22, fontWeight: FontWeight.w700, letterSpacing: -0.4, height: 1.25, color: AppColors.darkTextPrimary),
        titleLarge: TextStyle(fontFamily: 'Arial', fontSize: 20, fontWeight: FontWeight.w800, letterSpacing: -0.4, height: 1.3, color: AppColors.darkTextPrimary),
        titleMedium: TextStyle(fontFamily: 'Arial', fontSize: 17, fontWeight: FontWeight.w700, letterSpacing: -0.3, height: 1.3, color: AppColors.darkTextPrimary),
        titleSmall: TextStyle(fontFamily: 'Arial', fontSize: 15, fontWeight: FontWeight.w700, letterSpacing: -0.2, height: 1.3, color: AppColors.darkTextPrimary),
        bodyLarge: TextStyle(fontFamily: 'Arial', fontSize: 16, fontWeight: FontWeight.w400, height: 1.4, letterSpacing: -0.2, color: AppColors.darkTextPrimary),
        bodyMedium: TextStyle(fontFamily: 'Arial', fontSize: 15, fontWeight: FontWeight.w400, height: 1.4, letterSpacing: -0.1, color: AppColors.darkTextPrimary),
        bodySmall: TextStyle(fontFamily: 'Arial', fontSize: 13, fontWeight: FontWeight.w400, height: 1.35, color: AppColors.darkTextSecondary),
        labelLarge: TextStyle(fontFamily: 'Arial', fontSize: 14, fontWeight: FontWeight.w700, letterSpacing: -0.1, color: AppColors.darkTextPrimary),
        labelMedium: TextStyle(fontFamily: 'Arial', fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.darkTextSecondary),
        labelSmall: TextStyle(fontFamily: 'Arial', fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.darkTextTertiary),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.darkBackground,
        foregroundColor: AppColors.darkTextPrimary,
        elevation: 0,
        centerTitle: false,
        scrolledUnderElevation: 0,
        titleTextStyle: TextStyle(
          fontFamily: 'Arial',
          fontSize: 20,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.5,
          color: AppColors.darkTextPrimary,
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.darkSurface,
        selectedItemColor: AppColors.electricBlue,
        unselectedItemColor: AppColors.darkTextSecondary,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.darkSurface,
        indicatorColor: AppColors.electricBlue.withValues(alpha: 0.18),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: AppColors.electricBlue);
          }
          return const IconThemeData(color: AppColors.darkTextSecondary);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(
              fontFamily: 'Arial',
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.electricBlue,
            );
          }
          return const TextStyle(
            fontFamily: 'Arial',
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppColors.darkTextSecondary,
          );
        }),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.electricBlue,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(
            fontFamily: 'Arial',
            fontSize: 15,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.2,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.electricBlueLight,
          side: const BorderSide(color: AppColors.electricBlue, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(
            fontFamily: 'Arial',
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.darkSurfaceElevated,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.darkSurfaceBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.darkSurfaceBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.electricBlue, width: 1.8),
        ),
        hintStyle: const TextStyle(color: AppColors.darkTextTertiary, fontSize: 14),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  static ThemeData get lightTheme {
    final colorScheme = ColorScheme(
      brightness: Brightness.light,
      primary: AppColors.electricBlue,
      onPrimary: Colors.white,
      primaryContainer: AppColors.electricBlueSurfaceLight,
      onPrimaryContainer: AppColors.electricBlueDark,
      secondary: AppColors.limeGreenDark,
      onSecondary: Colors.white,
      secondaryContainer: const Color(0xFFD1FAE5),
      onSecondaryContainer: const Color(0xFF065F46),
      surface: AppColors.lightSurface,
      onSurface: AppColors.lightTextPrimary,
      surfaceContainerHighest: AppColors.lightSurfaceElevated,
      error: AppColors.error,
      onError: Colors.white,
      outline: AppColors.lightSurfaceBorder,
      outlineVariant: const Color(0xFFCBD5E1),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      fontFamily: 'Arial',
      fontFamilyFallback: const ['Roboto', 'SF Pro Display', 'SF Pro Text', '-apple-system', 'sans-serif'],
      scaffoldBackgroundColor: AppColors.lightBackground,
      colorScheme: colorScheme,
      cardTheme: CardThemeData(
        color: AppColors.lightSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: AppColors.lightSurfaceBorder, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(fontFamily: 'Arial', fontSize: 32, fontWeight: FontWeight.w800, letterSpacing: -0.6, height: 1.2, color: AppColors.lightTextPrimary),
        headlineMedium: TextStyle(fontFamily: 'Arial', fontSize: 26, fontWeight: FontWeight.w800, letterSpacing: -0.5, height: 1.2, color: AppColors.lightTextPrimary),
        headlineSmall: TextStyle(fontFamily: 'Arial', fontSize: 22, fontWeight: FontWeight.w700, letterSpacing: -0.4, height: 1.25, color: AppColors.lightTextPrimary),
        titleLarge: TextStyle(fontFamily: 'Arial', fontSize: 20, fontWeight: FontWeight.w800, letterSpacing: -0.4, height: 1.3, color: AppColors.lightTextPrimary),
        titleMedium: TextStyle(fontFamily: 'Arial', fontSize: 17, fontWeight: FontWeight.w700, letterSpacing: -0.3, height: 1.3, color: AppColors.lightTextPrimary),
        titleSmall: TextStyle(fontFamily: 'Arial', fontSize: 15, fontWeight: FontWeight.w700, letterSpacing: -0.2, height: 1.3, color: AppColors.lightTextPrimary),
        bodyLarge: TextStyle(fontFamily: 'Arial', fontSize: 16, fontWeight: FontWeight.w400, height: 1.4, letterSpacing: -0.2, color: AppColors.lightTextPrimary),
        bodyMedium: TextStyle(fontFamily: 'Arial', fontSize: 15, fontWeight: FontWeight.w400, height: 1.4, letterSpacing: -0.1, color: AppColors.lightTextPrimary),
        bodySmall: TextStyle(fontFamily: 'Arial', fontSize: 13, fontWeight: FontWeight.w400, height: 1.35, color: AppColors.lightTextSecondary),
        labelLarge: TextStyle(fontFamily: 'Arial', fontSize: 14, fontWeight: FontWeight.w700, letterSpacing: -0.1, color: AppColors.lightTextPrimary),
        labelMedium: TextStyle(fontFamily: 'Arial', fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.lightTextSecondary),
        labelSmall: TextStyle(fontFamily: 'Arial', fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.lightTextTertiary),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.lightBackground,
        foregroundColor: AppColors.lightTextPrimary,
        elevation: 0,
        centerTitle: false,
        scrolledUnderElevation: 0,
        titleTextStyle: TextStyle(
          fontFamily: 'Arial',
          fontSize: 20,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.5,
          color: AppColors.lightTextPrimary,
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.lightSurface,
        selectedItemColor: AppColors.electricBlue,
        unselectedItemColor: AppColors.lightTextSecondary,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.lightSurface,
        indicatorColor: AppColors.electricBlue.withValues(alpha: 0.12),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: AppColors.electricBlue);
          }
          return const IconThemeData(color: AppColors.lightTextSecondary);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(
              fontFamily: 'Arial',
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.electricBlue,
            );
          }
          return const TextStyle(
            fontFamily: 'Arial',
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppColors.lightTextSecondary,
          );
        }),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.electricBlue,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(
            fontFamily: 'Arial',
            fontSize: 15,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.2,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.electricBlue,
          side: const BorderSide(color: AppColors.electricBlue, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(
            fontFamily: 'Arial',
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.lightSurfaceBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.lightSurfaceBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.electricBlue, width: 1.8),
        ),
        hintStyle: const TextStyle(color: AppColors.lightTextTertiary, fontSize: 14),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }
}
