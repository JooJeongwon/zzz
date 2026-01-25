// ignore_for_file: constant_identifier_names

import 'package:flutter/material.dart';

enum UserStatus {
  ONLINE,
  SLEEP,
  STUDY,
  BUSY,
  UNKNOWN,
  DISCHARGED;

  String get label {
    switch (this) {
      case UserStatus.ONLINE: return '접속 중';
      case UserStatus.SLEEP: return '수면 중';
      case UserStatus.STUDY: return '열공 중';
      case UserStatus.BUSY: return '바쁨';
      case UserStatus.DISCHARGED: return '배터리 방전';
      default: return '상태 미설정';
    }
  }

  Color get color {
    switch (this) {
      case UserStatus.ONLINE: return const Color(0xFF74B9FF); // AppColors.statusOnline
      case UserStatus.SLEEP: return const Color(0xFFA29BFE); // AppColors.statusSleep
      case UserStatus.STUDY: return const Color(0xFF55EFC4); // AppColors.statusStudy
      case UserStatus.BUSY: return const Color(0xFFFF7675); // AppColors.statusBusy
      case UserStatus.DISCHARGED: return const Color(0xFF718096); // AppColors.textSecondaryNight
      case UserStatus.UNKNOWN: return const Color(0xFFB0BEC5); // Visible Gray
    }
  }

  IconData get icon {
    switch (this) {
      case UserStatus.ONLINE: return Icons.sentiment_satisfied_alt;
      case UserStatus.SLEEP: return Icons.bedtime;
      case UserStatus.STUDY: return Icons.menu_book;
      case UserStatus.BUSY: return Icons.work;
      case UserStatus.DISCHARGED: return Icons.battery_alert;
      case UserStatus.UNKNOWN: return Icons.question_mark;
    }
  }

  static UserStatus fromString(String? status) {
    if (status == null) return UserStatus.UNKNOWN;
    try {
      return UserStatus.values.firstWhere((e) => e.name == status);
    } catch (_) {
      return UserStatus.UNKNOWN;
    }
  }
}
