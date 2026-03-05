import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:modar/l10n/app_localizations.dart';
import 'package:modar/navigation/main_navigation.dart';
import 'package:modar/providers.dart';
import 'package:modar/theme/app_theme.dart';
import 'package:modar/viewModel/app_settings_notifier.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/splash_screen.dart';
import 'screens/bluetooth_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Future.wait([
    initializeDateFormatting('fr'),
    initializeDateFormatting('en'),
  ]);
  final prefs = await SharedPreferences.getInstance();
  runApp(
    ProviderScope(
      overrides: [
        appSettingsProvider.overrideWith((ref) => AppSettingsNotifier(prefs)),
      ],
      child: const ModarApp(),
    ),
  );
}

class ModarApp extends ConsumerWidget {
  const ModarApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(appSettingsProvider);
    return MaterialApp(
      title: 'Modart',
      debugShowCheckedModeBanner: false,
      themeMode: settings.themeMode,
      locale: settings.locale,
      supportedLocales: const [Locale('fr'), Locale('en')],
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: lightTheme,
      darkTheme: darkTheme,
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
