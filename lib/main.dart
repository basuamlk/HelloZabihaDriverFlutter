import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'providers/home_provider.dart';
import 'providers/deliveries_provider.dart';
import 'providers/delivery_detail_provider.dart';
import 'providers/profile_provider.dart';
import 'providers/notifications_provider.dart';
import 'providers/connectivity_provider.dart';
import 'providers/onboarding_provider.dart';
import 'providers/earnings_provider.dart';
import 'providers/messaging_provider.dart';
import 'providers/analytics_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/main_tab_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ConnectivityProvider()..initialize()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => HomeProvider()),
        ChangeNotifierProvider(create: (_) => DeliveriesProvider()),
        ChangeNotifierProvider(create: (_) => DeliveryDetailProvider()),
        ChangeNotifierProvider(create: (_) => ProfileProvider()),
        ChangeNotifierProvider(create: (_) => NotificationsProvider()..initialize()),
        ChangeNotifierProvider(create: (_) => OnboardingProvider()),
        ChangeNotifierProvider(create: (_) => EarningsProvider()),
        ChangeNotifierProvider(create: (_) => MessagingProvider()),
        ChangeNotifierProvider(create: (_) => AnalyticsProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: 'HelloZabiha Driver',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.themeData,
            darkTheme: AppTheme.darkThemeData,
            themeMode: themeProvider.themeMode,
            home: const SplashScreen(),
          );
        },
      ),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _checkingOnboarding = true;
  bool _needsOnboarding = false;

  @override
  void initState() {
    super.initState();
    _checkOnboardingStatus();
  }

  Future<void> _checkOnboardingStatus() async {
    final authProvider = context.read<AuthProvider>();
    if (authProvider.isAuthenticated) {
      final onboardingProvider = context.read<OnboardingProvider>();
      final needsOnboarding = await onboardingProvider.needsOnboarding();
      if (mounted) {
        setState(() {
          _needsOnboarding = needsOnboarding;
          _checkingOnboarding = false;
        });
      }
    } else {
      setState(() {
        _checkingOnboarding = false;
      });
    }
  }

  void _onOnboardingComplete() {
    setState(() {
      _needsOnboarding = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<AuthProvider, ConnectivityProvider>(
      builder: (context, auth, connectivity, child) {
        // Listen to auth changes to re-check onboarding
        if (auth.isAuthenticated && _checkingOnboarding) {
          _checkOnboardingStatus();
        }

        if (!auth.isAuthenticated) {
          // Reset onboarding state when logged out
          if (!_checkingOnboarding) {
            _checkingOnboarding = true;
            _needsOnboarding = false;
          }
          return const LoginScreen();
        }

        // Show loading while checking onboarding status
        if (_checkingOnboarding) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        return Stack(
          children: [
            // Main content
            if (_needsOnboarding)
              OnboardingScreen(onComplete: _onOnboardingComplete)
            else
              const MainTabScreen(),
            // Offline banner
            if (!connectivity.isConnected)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: SafeArea(
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                    color: Colors.orange[700],
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.wifi_off, color: Colors.white, size: 18),
                        SizedBox(width: 8),
                        Text(
                          'You are offline',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
