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
      case UserStatus.ONLINE: return 'Online';
      case UserStatus.SLEEP: return 'Sleeping';
      case UserStatus.STUDY: return 'Studying';
      case UserStatus.BUSY: return 'Busy';
      case UserStatus.DISCHARGED: return 'Battery Dead';
      default: return 'Unknown';
    }
  }

  Color get color {
    switch (this) {
      case UserStatus.ONLINE: return const Color(0xFF74B9FF); // AppColors.statusOnline
      case UserStatus.SLEEP: return const Color(0xFFA29BFE); // AppColors.statusSleep
      case UserStatus.STUDY: return const Color(0xFF55EFC4); // AppColors.statusStudy
      case UserStatus.BUSY: return const Color(0xFFFF7675); // AppColors.statusBusy
      case UserStatus.DISCHARGED: return const Color(0xFF718096); // AppColors.textSecondaryNight
      case UserStatus.UNKNOWN: return const Color(0xFFEEEEEE); // AppColors.borderDay
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
