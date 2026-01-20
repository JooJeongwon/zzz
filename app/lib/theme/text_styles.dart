import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'colors.dart';

class AppTextStyles {
  // static const String fontFamily = 'Pretendard Rounded'; // Removed in favor of Google Fonts

  static TextStyle get baseTextStyle => GoogleFonts.mPlusRounded1c(
    letterSpacing: -0.5,
    height: 1.4,
    color: AppColors.textPrimaryDay,
  );

  static TextStyle get titleLarge => baseTextStyle.copyWith(
    fontSize: 28,
    fontWeight: FontWeight.bold,
  );

  static TextStyle get titleMedium => baseTextStyle.copyWith(
    fontSize: 24,
    fontWeight: FontWeight.bold,
  );

  static TextStyle get bodyLarge => baseTextStyle.copyWith(
    fontSize: 18,
    fontWeight: FontWeight.w500,
  );

  static TextStyle get bodyMedium => baseTextStyle.copyWith(
    fontSize: 16,
    fontWeight: FontWeight.normal,
  );

  static TextStyle get bodySmall => baseTextStyle.copyWith(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: AppColors.textSecondaryDay,
  );
}
