import 'package:flutter/material.dart';

import 'app_colors.dart';

/// "Vintage Touring Soul × Modern Navy Precision" theme for RoadMate India.
///
/// Supports both:
/// 1. Dark Touring HUD: Midnight navy / instrument black with heritage copper highlights.
/// 2. Warm Ivory Light Mode: Warm ivory reading surface with deep navy structure.
class AppTheme {
  AppTheme._();

  static const String fontFamily = 'Inter';

  /// Primary Dark Touring Theme (Cockpit-optimized for motorcycle mounts & visors)
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      fontFamily: fontFamily,

      colorScheme: const ColorScheme.dark(
        primary: AppColors.heritageCopper,
        onPrimary: AppColors.pureWhite,
        secondary: AppColors.touringAmber,
        onSecondary: AppColors.instrumentBlack,
        error: AppColors.alertRed,
        onError: AppColors.pureWhite,
        surface: AppColors.deepNavy,
        onSurface: AppColors.pureWhite,
        surfaceContainerHighest: AppColors.graphite,
      ),

      scaffoldBackgroundColor: AppColors.midnightNavy,
      dividerColor: AppColors.steelBlue.withValues(alpha: 0.35),

      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.w700,
          color: AppColors.pureWhite,
          letterSpacing: -0.5,
          fontFamily: fontFamily,
        ),
        headlineMedium: TextStyle(
          fontSize: 26,
          fontWeight: FontWeight.w700,
          color: AppColors.pureWhite,
          fontFamily: fontFamily,
        ),
        titleLarge: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: AppColors.pureWhite,
          fontFamily: fontFamily,
        ),
        titleMedium: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppColors.pureWhite,
          fontFamily: fontFamily,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: AppColors.pureWhite,
          fontFamily: fontFamily,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: AppColors.mutedText,
          fontFamily: fontFamily,
        ),
        bodySmall: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: AppColors.steelBlue,
          fontFamily: fontFamily,
        ),
        labelLarge: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: AppColors.pureWhite,
          fontFamily: fontFamily,
        ),
        labelMedium: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: AppColors.mutedText,
          fontFamily: fontFamily,
        ),
        labelSmall: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: AppColors.steelBlue,
          fontFamily: fontFamily,
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.heritageCopper,
          foregroundColor: AppColors.pureWhite,
          minimumSize: const Size(56, 52),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(26),
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            fontFamily: fontFamily,
          ),
          elevation: 0,
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.heritageCopper,
          minimumSize: const Size(56, 52),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          side: const BorderSide(color: AppColors.heritageCopper, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(26),
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            fontFamily: fontFamily,
          ),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.deepNavy,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        constraints: const BoxConstraints(minHeight: 52),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: AppColors.steelBlue.withValues(alpha: 0.3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: AppColors.steelBlue.withValues(alpha: 0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.heritageCopper, width: 1.5),
        ),
        hintStyle: const TextStyle(
          fontSize: 14,
          color: AppColors.steelBlue,
          fontFamily: fontFamily,
        ),
      ),

      cardTheme: CardTheme(
        color: AppColors.deepNavy,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: AppColors.steelBlue.withValues(alpha: 0.25), width: 1),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),

      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.midnightNavy,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: AppColors.pureWhite,
          fontFamily: fontFamily,
        ),
        iconTheme: IconThemeData(color: AppColors.pureWhite, size: 24),
      ),

      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.midnightNavy,
        selectedItemColor: AppColors.heritageCopper,
        unselectedItemColor: AppColors.steelBlue,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        selectedLabelStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          fontFamily: fontFamily,
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          fontFamily: fontFamily,
        ),
      ),
    );
  }

  /// Warm Ivory Light Theme
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      fontFamily: fontFamily,

      colorScheme: const ColorScheme.light(
        primary: AppColors.heritageCopper,
        onPrimary: AppColors.pureWhite,
        secondary: AppColors.deepNavy,
        onSecondary: AppColors.pureWhite,
        error: AppColors.alertRed,
        onError: AppColors.pureWhite,
        surface: AppColors.pureWhite,
        onSurface: AppColors.midnightNavy,
        surfaceContainerHighest: AppColors.warmIvory,
      ),

      scaffoldBackgroundColor: AppColors.warmIvory,
      dividerColor: AppColors.steelBlue.withValues(alpha: 0.2),

      cardTheme: CardTheme(
        color: AppColors.pureWhite,
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: AppColors.steelBlue.withValues(alpha: 0.2), width: 1),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    );
  }
}
