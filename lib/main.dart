import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'theme/app_theme.dart';
import 'screens/onboarding_screen.dart';
import 'screens/live_dashboard_screen.dart';
import 'screens/session_summary_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// SmartSole — Application Entry Point
//
// MultiProvider root pour le state management.
// Thème dark par défaut, navigation personas-aware.
// ─────────────────────────────────────────────────────────────────────────────

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Barres système transparentes pour l'immersion mesh gradient.
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.transparent,
    ),
  );

  runApp(
    MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => ThemeProvider())],
      child: const SmartSoleApp(),
    ),
  );
}

/// Provider pour le toggle dark/light mode.
class ThemeProvider extends ChangeNotifier {
  bool _isDarkMode = true;

  bool get isDarkMode => _isDarkMode;

  ThemeData get theme =>
      _isDarkMode ? SmartSoleTheme.dark : SmartSoleTheme.light;

  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
  }

  void setDarkMode(bool value) {
    _isDarkMode = value;
    notifyListeners();
  }
}

class SmartSoleApp extends StatelessWidget {
  const SmartSoleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        return MaterialApp(
          title: 'SmartSole',
          debugShowCheckedModeBanner: false,
          theme: themeProvider.theme,

          // Navigation
          initialRoute: '/onboarding',
          routes: {
            '/onboarding': (_) => const OnboardingScreen(),
            '/pairing': (_) => const _PairingPlaceholder(),
            '/dashboard': (_) => const LiveDashboardScreen(),
            '/summary': (_) => const SessionSummaryScreen(),
          },

          // Route inconnue — fallback dashboard
          onUnknownRoute:
              (settings) => MaterialPageRoute(
                builder: (_) => const LiveDashboardScreen(),
              ),
        );
      },
    );
  }
}

/// Placeholder pour PairingScreen (sera remplacé en Phase 5 complète).
class _PairingPlaceholder extends StatelessWidget {
  const _PairingPlaceholder();

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? SmartSoleColors.darkBg : SmartSoleColors.lightBg,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.bluetooth_searching,
                size: 64,
                color: SmartSoleColors.biTeal.withValues(alpha: 0.6),
              ),
              const SizedBox(height: 24),
              Text(
                'Appairage BLE',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'En cours de développement...',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 40),
              ElevatedButton.icon(
                onPressed:
                    () => Navigator.pushReplacementNamed(context, '/dashboard'),
                icon: const Icon(Icons.skip_next),
                label: const Text('Skip → Dashboard'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
