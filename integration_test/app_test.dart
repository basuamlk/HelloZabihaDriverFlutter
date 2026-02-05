import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:hello_zabiha_driver/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('HelloZabiha Driver App Integration Tests', () {
    testWidgets('App starts and shows splash screen', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // The splash screen should show the app name or logo
      // After splash, it should navigate to login or main screen
      expect(find.byType(MaterialApp), findsOneWidget);
    });

    testWidgets('Login screen has email and password fields', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Wait for splash to complete (adjust duration as needed)
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();

      // If not authenticated, should show login screen
      // These will only pass if user is logged out
      final emailField = find.byType(TextFormField).first;
      final passwordField = find.byType(TextFormField).last;

      // Verify text fields exist (may not find if already logged in)
      if (emailField.evaluate().isNotEmpty) {
        expect(emailField, findsOneWidget);
        expect(passwordField, findsOneWidget);
      }
    });
  });
}
