import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/splash_screen.dart';
import 'screens/bluetooth_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/history_screen.dart';
import 'screens/position_screen.dart';
import 'screens/settings_screen.dart';

void main() {
  runApp(const ModarApp());
}

class ModarApp extends StatelessWidget {
  const ModarApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Modar',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        scaffoldBackgroundColor: Colors.white,
        cardColor: const Color(0xFFF5F5F7),
        colorScheme: const ColorScheme.light(
          primary: Colors.black,
          onPrimary: Colors.white,
          secondary: Color(0xFF007AFF), // iOS blue accent
          surface: Colors.white,
          onSurface: Colors.black,
          outline: Color(0xFFE5E5E5),
        ),
        textTheme: GoogleFonts.outfitTextTheme(
          ThemeData.light().textTheme,
        ).apply(
          bodyColor: Colors.black,
          displayColor: Colors.black,
        ),
      ),
      home: const AppInitializationFlow(),
    );
  }
}

class AppInitializationFlow extends StatefulWidget {
  const AppInitializationFlow({super.key});

  @override
  State<AppInitializationFlow> createState() => _AppInitializationFlowState();
}

class _AppInitializationFlowState extends State<AppInitializationFlow> {
  bool _showSplash = true;
  bool _showBluetooth = false;

  @override
  Widget build(BuildContext context) {
    if (_showSplash) {
      return SplashScreen(
        onFinished: () {
          setState(() {
            _showSplash = false;
            _showBluetooth = true;
          });
        },
      );
    }

    if (_showBluetooth) {
      return BluetoothScreen(
        onContinue: () {
          setState(() {
            _showBluetooth = false;
          });
        },
      );
    }

    return const MainNavigation();
  }
}

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
    final List<Widget> pages = [
      const DashboardScreen(),
      const PositionScreen(),
      const HistoryScreen(),
      SettingsScreen(onManageBluetooth: () => _openBluetooth(context)),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.grey.shade400,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.analytics_outlined),
            activeIcon: Icon(Icons.analytics),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.directions_walk),
            label: 'Position',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'Historique',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Réglages',
          ),
        ],
      ),
    );
  }
}
