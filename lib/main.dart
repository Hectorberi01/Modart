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
// © 2026 SmartSole · MVP v1.0
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
          onGenerateRoute: _generateRoute,
          onUnknownRoute: (_) => _fadeRoute(const HomeShell(), '/home'),
        );
      },
    );
  }

  /// Custom page transitions — fade + slight slide for every route.
  static Route<dynamic> _generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/onboarding':
        return _fadeRoute(const OnboardingScreen(), settings.name!);
      case '/pairing':
        return _fadeRoute(const _PairingPlaceholder(), settings.name!);
      case '/home':
        return _fadeRoute(const HomeShell(), settings.name!);
      case '/dashboard':
        return _fadeRoute(const LiveDashboardScreen(), settings.name!);
      case '/summary':
        return _slideUpRoute(const SessionSummaryScreen(), settings.name!);
      case '/trends':
        return _fadeRoute(const HistoryTrendsScreen(), settings.name!);
      case '/imm':
        return _fadeRoute(const IMMReportScreen(), settings.name!);
      case '/profile':
        return _fadeRoute(const ProfileScreen(), settings.name!);
      default:
        return _fadeRoute(const HomeShell(), '/home');
    }
  }

  /// Fade transition with subtle scale.
  static PageRouteBuilder _fadeRoute(Widget page, String routeName) {
    return PageRouteBuilder(
      settings: RouteSettings(name: routeName),
      transitionDuration: const Duration(milliseconds: 400),
      reverseTransitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (_, __, ___) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        );
        return FadeTransition(
          opacity: curved,
          child: ScaleTransition(
            scale: Tween(begin: 0.96, end: 1.0).animate(curved),
            child: child,
          ),
        );
      },
    );
  }

  /// Slide-up transition (for modals like session summary).
  static PageRouteBuilder _slideUpRoute(Widget page, String routeName) {
    return PageRouteBuilder(
      settings: RouteSettings(name: routeName),
      transitionDuration: const Duration(milliseconds: 450),
      reverseTransitionDuration: const Duration(milliseconds: 350),
      pageBuilder: (_, __, ___) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        );
        return SlideTransition(
          position: Tween(
            begin: const Offset(0, 0.15),
            end: Offset.zero,
          ).animate(curved),
          child: FadeTransition(opacity: curved, child: child),
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

class _HomeShellState extends State<HomeShell>
    with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  int _previousIndex = 0;

  static const List<Widget> _pages = [
    LiveDashboardScreen(),
    HistoryTrendsScreen(),
    IMMReportScreen(),
    ProfileScreen(),
  ];

  void _onTabTapped(int index) {
    if (index == _currentIndex) return;
    setState(() {
      _previousIndex = _currentIndex;
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 350),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        transitionBuilder: (child, animation) {
          // Slide direction depends on tab order
          final bool goingRight = _currentIndex > _previousIndex;
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween(
                begin: Offset(goingRight ? 0.05 : -0.05, 0),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            ),
          );
        },
        child: KeyedSubtree(
          key: ValueKey<int>(_currentIndex),
          child: _pages[_currentIndex],
        ),
      ),
      bottomNavigationBar: _GlassBottomNav(
        currentIndex: _currentIndex,
        isDark: isDark,
        onTap: _onTabTapped,
      ),
    );
  }
}

// ─── Glassmorphism Bottom Nav ────────────────────────────────────────────────

class _GlassBottomNav extends StatelessWidget {
  const _GlassBottomNav({
    required this.currentIndex,
    required this.isDark,
    required this.onTap,
  });

  final int currentIndex;
  final bool isDark;
  final void Function(int) onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color:
            isDark
                ? SmartSoleColors.darkSurface.withValues(alpha: 0.88)
                : SmartSoleColors.lightSurface.withValues(alpha: 0.92),
        border: Border(
          top: BorderSide(
            color:
                isDark
                    ? Colors.white.withValues(alpha: 0.06)
                    : Colors.black.withValues(alpha: 0.06),
            width: 0.5,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: SmartSoleColors.biNormal.withValues(alpha: 0.03),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
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
                isActive: currentIndex == 0,
                onTap: () => onTap(0),
              ),
              _NavItem(
                icon: Icons.timeline,
                label: 'Tendances',
                isActive: currentIndex == 1,
                onTap: () => onTap(1),
              ),
              _NavItem(
                icon: Icons.child_care,
                label: 'IMM',
                isActive: currentIndex == 2,
                onTap: () => onTap(2),
              ),
              _NavItem(
                icon: Icons.person_outline,
                label: 'Profil',
                isActive: currentIndex == 3,
                onTap: () => onTap(3),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Nav Item ───────────────────────────────────────────────────────────────

class _NavItem extends StatefulWidget {
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
  State<_NavItem> createState() => _NavItemState();
}

class _NavItemState extends State<_NavItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _scaleCtrl;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _scaleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnim = Tween(
      begin: 1.0,
      end: 0.88,
    ).animate(CurvedAnimation(parent: _scaleCtrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _scaleCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Color activeColor = SmartSoleColors.biNormal;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color inactiveColor =
        isDark
            ? SmartSoleColors.textTertiaryDark
            : SmartSoleColors.textTertiaryLight;

    return GestureDetector(
      onTapDown: (_) => _scaleCtrl.forward(),
      onTapUp: (_) {
        _scaleCtrl.reverse();
        widget.onTap();
      },
      onTapCancel: () => _scaleCtrl.reverse(),
      behavior: HitTestBehavior.opaque,
      child: ScaleTransition(
        scale: _scaleAnim,
        child: AnimatedContainer(
          duration: SmartSoleDesign.animNormal,
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color:
                widget.isActive
                    ? activeColor.withValues(alpha: 0.10)
                    : Colors.transparent,
            borderRadius: BorderRadius.circular(SmartSoleDesign.borderRadiusSm),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: SmartSoleDesign.animNormal,
                curve: Curves.easeOutCubic,
                transform: Matrix4.translationValues(
                  0,
                  widget.isActive ? -2 : 0,
                  0,
                ),
                child: Icon(
                  widget.icon,
                  size: widget.isActive ? 24 : 22,
                  color: widget.isActive ? activeColor : inactiveColor,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                widget.label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight:
                      widget.isActive ? FontWeight.w700 : FontWeight.w500,
                  color: widget.isActive ? activeColor : inactiveColor,
                ),
              ),
              // Active indicator dot
              AnimatedContainer(
                duration: SmartSoleDesign.animNormal,
                margin: const EdgeInsets.only(top: 3),
                width: widget.isActive ? 4 : 0,
                height: widget.isActive ? 4 : 0,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: activeColor,
                  boxShadow:
                      widget.isActive
                          ? [
                            BoxShadow(
                              color: activeColor.withValues(alpha: 0.4),
                              blurRadius: 6,
                            ),
                          ]
                          : [],
                ),
              ),
            ],
          ),
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
