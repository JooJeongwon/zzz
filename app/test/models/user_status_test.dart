import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app/models/user_status.dart';

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
      expect(UserStatus.ONLINE.color, Colors.green);
      expect(UserStatus.SLEEP.color, Colors.indigo);
      expect(UserStatus.BUSY.color, Colors.red);
      // Colors.grey.shade300 is harder to match exactly with const, checking type or specific value if needed, 
      // but simple equality usually works for Material colors.
      expect(UserStatus.UNKNOWN.color, Colors.grey.shade300);
    });
  });
}
