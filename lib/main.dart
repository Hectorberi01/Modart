import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'theme/app_theme.dart';
import 'screens/onboarding_screen.dart';
import 'screens/live_dashboard_screen.dart';
import 'screens/session_summary_screen.dart';
import 'screens/history_trends_screen.dart';
import 'screens/imm_report_screen.dart';
import 'screens/profile_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// SmartSole — Entry Point
//
// MultiProvider root, dark theme par défaut, navigation avec BottomNav.
// ─────────────────────────────────────────────────────────────────────────────

void main() {
  WidgetsFlutterBinding.ensureInitialized();

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

/// Gestion du mode dark/light.
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
          initialRoute: '/onboarding',
          routes: {
            '/onboarding': (_) => const OnboardingScreen(),
            '/pairing': (_) => const _PairingPlaceholder(),
            '/home': (_) => const HomeShell(),
            '/dashboard': (_) => const LiveDashboardScreen(),
            '/summary': (_) => const SessionSummaryScreen(),
            '/trends': (_) => const HistoryTrendsScreen(),
            '/imm': (_) => const IMMReportScreen(),
            '/profile': (_) => const ProfileScreen(),
          },
          onUnknownRoute:
              (_) => MaterialPageRoute(builder: (_) => const HomeShell()),
        );
      },
    );
  }
}

// ─── Home Shell avec BottomNav glassmorphism ─────────────────────────────────

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _currentIndex = 0;

  static const List<Widget> _pages = [
    LiveDashboardScreen(),
    HistoryTrendsScreen(),
    IMMReportScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _pages),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color:
              isDark
                  ? SmartSoleColors.darkSurface.withValues(alpha: 0.85)
                  : SmartSoleColors.lightSurface.withValues(alpha: 0.9),
          border: Border(
            top: BorderSide(
              color:
                  isDark
                      ? Colors.white.withValues(alpha: 0.06)
                      : Colors.black.withValues(alpha: 0.06),
              width: 0.5,
            ),
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _NavItem(
                  icon: Icons.grid_view_rounded,
                  label: 'Live',
                  isActive: _currentIndex == 0,
                  onTap: () => setState(() => _currentIndex = 0),
                ),
                _NavItem(
                  icon: Icons.timeline,
                  label: 'Tendances',
                  isActive: _currentIndex == 1,
                  onTap: () => setState(() => _currentIndex = 1),
                ),
                _NavItem(
                  icon: Icons.child_care,
                  label: 'IMM',
                  isActive: _currentIndex == 2,
                  onTap: () => setState(() => _currentIndex = 2),
                ),
                _NavItem(
                  icon: Icons.person_outline,
                  label: 'Profil',
                  isActive: _currentIndex == 3,
                  onTap: () => setState(() => _currentIndex = 3),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Nav Item ───────────────────────────────────────────────────────────────

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color activeColor = SmartSoleColors.biNormal;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color inactiveColor =
        isDark
            ? SmartSoleColors.textTertiaryDark
            : SmartSoleColors.textTertiaryLight;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: SmartSoleDesign.animNormal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color:
              isActive
                  ? activeColor.withValues(alpha: 0.08)
                  : Colors.transparent,
          borderRadius: BorderRadius.circular(SmartSoleDesign.borderRadiusSm),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 22, color: isActive ? activeColor : inactiveColor),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                color: isActive ? activeColor : inactiveColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Pairing Placeholder ────────────────────────────────────────────────────

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
                color: SmartSoleColors.biTeal.withValues(alpha: 0.5),
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
                    () => Navigator.pushReplacementNamed(context, '/home'),
                icon: const Icon(Icons.skip_next, size: 20),
                label: const Text('Skip → Dashboard'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
