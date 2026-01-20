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
      fontFamily: AppTextStyles.fontFamily,
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
}
