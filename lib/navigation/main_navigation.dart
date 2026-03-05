import 'package:flutter/material.dart';
import 'package:modar/l10n/app_localizations.dart';
import '../screens/bluetooth_screen.dart';
import '../screens/dashboard_screen.dart';
import '../screens/history_screen.dart';
import '../screens/position_screen.dart';
import '../screens/settings_screen.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _openBluetooth(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BluetoothScreen(onContinue: () => Navigator.pop(context)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);

    final List<Widget> pages = [
      const DashboardScreen(),
      const PositionScreen(),
      const HistoryScreen(),
      SettingsScreen(onManageBluetooth: () => _openBluetooth(context)),
    ];

    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: pages),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: Theme.of(context).colorScheme.surface,
        selectedItemColor: Theme.of(context).colorScheme.onSurface,
        unselectedItemColor: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.analytics_outlined),
            activeIcon: const Icon(Icons.analytics),
            label: l.navDashboard,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.directions_walk),
            label: l.navPosition,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.history),
            label: l.navHistory,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.settings),
            label: l.navSettings,
          ),
        ],
      ),
    );
  }
}
