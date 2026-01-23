import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app/screens/login_screen.dart';

void main() {
  testWidgets('LoginScreen smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      const MaterialApp(
        home: LoginScreen(),
      ),
    );

    // Verify that Login text exists
    expect(find.text('환영합니다'), findsOneWidget);
    expect(find.text('로그인'), findsOneWidget); // Button text
  });
}