import 'package:flutter/material.dart';

class AppColors {
  // Theme Colors
  static const Color backgroundDay = Color(0xFFFAFAFA);
  static const Color backgroundNight = Color(0xFF2D3436);
  
  static const Color surfaceDay = Color(0xFFFFFFFF);
  static const Color surfaceNight = Color(0xFF353B48);
  
  static const Color borderDay = Color(0xFFEEEEEE);
  static const Color borderNight = Color(0xFF4A5568);
  
  static const Color textPrimaryDay = Color(0xFF2D3436);
  static const Color textPrimaryNight = Color(0xFFFAFAFA);
  
  static const Color textSecondaryDay = Color(0xFFA0AEC0);
  static const Color textSecondaryNight = Color(0xFF718096);

  // Status Colors
  static const Color statusSleep = Color(0xFFA29BFE); // Lavender
  static const Color statusStudy = Color(0xFF55EFC4); // Mint
  static const Color statusBusy = Color(0xFFFF7675); // Pastel Pink
  static const Color statusOnline = Color(0xFF74B9FF); // Soft Sky

  // Chat Semantic Colors - Day
  static const Color myBubbleDay = Color(0xFF353B48);
  static const Color myBubbleTextDay = Colors.white;
  static const Color partnerBubbleDay = Colors.white;
  static const Color partnerBubbleTextDay = Colors.black87;
  static const Color aiBubbleDay = Color(0xFFF3E5F5); // Lavender Light
  static const Color aiBubbleTextDay = Colors.deepPurple;
  
  // Chat Semantic Colors - Night
  static const Color myBubbleNight = Color(0xFF74B9FF); // Soft Blue for contrast
  static const Color myBubbleTextNight = Color(0xFF2D3436);
  static const Color partnerBubbleNight = Color(0xFF2D3436); // Darker Grey
  static const Color partnerBubbleTextNight = Color(0xFFFAFAFA);
  static const Color aiBubbleNight = Color(0xFF6C5CE7); // Deep Purple
  static const Color aiBubbleTextNight = Colors.white;

  // Input Field
  static const Color inputBackgroundDay = Colors.white;
  static const Color inputBackgroundNight = Color(0xFF2D3436);
}
