import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:hello_zabiha_driver/screens/profile/profile_screen.dart';
import 'package:hello_zabiha_driver/providers/profile_provider.dart';
import 'package:hello_zabiha_driver/providers/auth_provider.dart';
import 'package:hello_zabiha_driver/theme/app_theme.dart';

void main() {
  group('ProfileScreen Widget Tests', () {
    late ProfileProvider profileProvider;
    late AuthProvider authProvider;

    setUp(() {
      profileProvider = ProfileProvider();
      authProvider = AuthProvider();
    });

    Widget createTestWidget() {
      return MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: profileProvider),
          ChangeNotifierProvider.value(value: authProvider),
        ],
        child: MaterialApp(
          theme: AppTheme.themeData,
          home: const ProfileScreen(),
        ),
      );
    }

    testWidgets('shows loading indicator initially', (tester) async {
      await tester.pumpWidget(createTestWidget());

      // Should show loading indicator when driver is null
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows profile title in app bar', (tester) async {
      await tester.pumpWidget(createTestWidget());

      expect(find.text('Profile'), findsOneWidget);
    });
  });
}
