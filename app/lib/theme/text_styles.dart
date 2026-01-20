import 'package:flutter/material.dart';
import 'colors.dart';

class AppTextStyles {
  static const String fontFamily = 'Pretendard Rounded'; // Fallback to system if not available

  static TextStyle get baseTextStyle => const TextStyle(
    fontFamily: fontFamily,
    letterSpacing: -0.5,
    height: 1.4,
  );

  static TextStyle get titleLarge => baseTextStyle.copyWith(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimaryDay,
  );

  static TextStyle get titleMedium => baseTextStyle.copyWith(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimaryDay,
  );

  static TextStyle get bodyLarge => baseTextStyle.copyWith(
    fontSize: 18,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimaryDay,
  );

  static TextStyle get bodyMedium => baseTextStyle.copyWith(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: AppColors.textPrimaryDay,
  );

  static TextStyle get bodySmall => baseTextStyle.copyWith(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: AppColors.textSecondaryDay,
  );
}
