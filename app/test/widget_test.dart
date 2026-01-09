import 'package:flutter_test/flutter_test.dart';
import 'package:app/main.dart';
import 'package:app/screens/login_screen.dart';

void main() {
  testWidgets('App starts with LoginScreen when not logged in', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp(isLoggedIn: false));

        // Verify that LoginScreen is shown

        expect(find.byType(LoginScreen), findsOneWidget);

        expect(find.text('Login'), findsNWidgets(2));

      });

    }

    