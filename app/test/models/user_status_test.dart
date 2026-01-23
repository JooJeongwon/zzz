import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app/models/user_status.dart';
import 'package:app/theme/colors.dart';

void main() {
  group('UserStatus Tests', () {
    test('UserStatus.fromString returns correct enum for valid strings', () {
      expect(UserStatus.fromString('ONLINE'), UserStatus.ONLINE);
      expect(UserStatus.fromString('SLEEP'), UserStatus.SLEEP);
      expect(UserStatus.fromString('STUDY'), UserStatus.STUDY);
      expect(UserStatus.fromString('BUSY'), UserStatus.BUSY);
      expect(UserStatus.fromString('DISCHARGED'), UserStatus.DISCHARGED);
    });

    test('UserStatus.fromString returns UNKNOWN for invalid or null input', () {
      expect(UserStatus.fromString('INVALID_STATUS'), UserStatus.UNKNOWN);
      expect(UserStatus.fromString(null), UserStatus.UNKNOWN);
      expect(UserStatus.fromString(''), UserStatus.UNKNOWN);
    });

    test('UserStatus.label returns correct display text', () {
      expect(UserStatus.ONLINE.label, 'Online');
      expect(UserStatus.SLEEP.label, 'Sleeping');
      expect(UserStatus.STUDY.label, 'Studying');
      expect(UserStatus.UNKNOWN.label, 'Unknown');
    });

    test('UserStatus.color returns correct Color', () {
      expect(UserStatus.ONLINE.color, AppColors.statusOnline);
      expect(UserStatus.SLEEP.color, AppColors.statusSleep);
      expect(UserStatus.STUDY.color, AppColors.statusStudy);
      expect(UserStatus.BUSY.color, AppColors.statusBusy);
      expect(UserStatus.DISCHARGED.color, const Color(0xFF718096)); // Manually matching UserStatus.dart implementation
      expect(UserStatus.UNKNOWN.color, const Color(0xFFEEEEEE)); // Manually matching UserStatus.dart implementation
    });
  });
}
