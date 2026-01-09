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
      case UserStatus.ONLINE: return Colors.green;
      case UserStatus.SLEEP: return Colors.indigo;
      case UserStatus.STUDY: return Colors.orange;
      case UserStatus.BUSY: return Colors.red;
      case UserStatus.DISCHARGED: return Colors.grey;
      case UserStatus.UNKNOWN: return Colors.grey.shade300;
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
