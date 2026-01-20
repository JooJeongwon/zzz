import 'package:flutter/material.dart';
import 'colors.dart';
import 'text_styles.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.backgroundDay,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.statusOnline,
        surface: AppColors.surfaceDay,
        background: AppColors.backgroundDay,
        onSurface: AppColors.textPrimaryDay,
      ),
      // fontFamily: AppTextStyles.fontFamily, // Handled by GoogleFonts
      textTheme: TextTheme(
        displayLarge: AppTextStyles.titleLarge,
        titleLarge: AppTextStyles.titleMedium,
        bodyLarge: AppTextStyles.bodyLarge,
        bodyMedium: AppTextStyles.bodyMedium,
        bodySmall: AppTextStyles.bodySmall,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.backgroundDay,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold),
        iconTheme: const IconThemeData(color: AppColors.textPrimaryDay),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.surfaceDay,
          foregroundColor: AppColors.textPrimaryDay,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: const BorderSide(color: AppColors.borderDay),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.backgroundNight,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.statusSleep,
        brightness: Brightness.dark,
        surface: AppColors.surfaceNight,
        background: AppColors.backgroundNight,
        onSurface: AppColors.textPrimaryNight,
      ),
      textTheme: TextTheme(
        displayLarge: AppTextStyles.titleLarge.copyWith(color: AppColors.textPrimaryNight),
        titleLarge: AppTextStyles.titleMedium.copyWith(color: AppColors.textPrimaryNight),
        bodyLarge: AppTextStyles.bodyLarge.copyWith(color: AppColors.textPrimaryNight),
        bodyMedium: AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimaryNight),
        bodySmall: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondaryNight),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.backgroundNight,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold, color: AppColors.textPrimaryNight),
        iconTheme: const IconThemeData(color: AppColors.textPrimaryNight),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.surfaceNight,
          foregroundColor: AppColors.textPrimaryNight,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: const BorderSide(color: AppColors.borderNight),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),
    );
  }
}
