import 'dart:async';
import 'package:flutter/material.dart';
import '../../models/session.dart';
import '../../services/database_service.dart';
import 'package:intl/intl.dart';
import '../bluetooth_screen.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'dashboard_constants.dart';
import 'widgets/hero_metric_card.dart';
import 'widgets/speed_gauge_card.dart';
import 'widgets/small_metric_card.dart';
import 'widgets/balance_card.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _btConnected = false;
  StreamSubscription? _btSub;

  @override
  void initState() {
    super.initState();
    _btConnected = FlutterBluePlus.connectedDevices.isNotEmpty;
    _btSub = FlutterBluePlus.events.onConnectionStateChanged.listen((_) {
      if (mounted) {
        setState(() => _btConnected = FlutterBluePlus.connectedDevices.isNotEmpty);
      }
    });
  }

  @override
  void dispose() {
    _btSub?.cancel();
    super.dispose();
  }

  Future<void> _saveSession(BuildContext context) async {
    final now = DateTime.now();
    final session = Session(
      title: 'Session ${DateFormat('HH:mm').format(now)}',
      date: DateFormat('dd MMMM yyyy').format(now),
      time: DateFormat('HH:mm').format(now),
      duration: '12:34',
      distance: '2.4 km',
      avgSpeed: '8.5 km/h',
    );
    await DatabaseService().insertSession(session);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Session enregistrée avec succès'),
          backgroundColor: kDashPrimary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kDashBg,
      appBar: AppBar(
        backgroundColor: kDashBg,
        titleSpacing: 20,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              DateFormat('EEEE d MMMM', 'fr').format(DateTime.now()),
              style: const TextStyle(
                color: kDashTextSec,
                fontSize: 12,
                fontWeight: FontWeight.w400,
              ),
            ),
            const Text(
              'Session en cours',
              style: TextStyle(
                color: kDashPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        actions: [
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => BluetoothScreen(
                  onContinue: () => Navigator.pop(context),
                ),
              ),
            ),
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: _btConnected
                    ? kDashSuccess.withValues(alpha: 0.1)
                    : Colors.grey.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.bluetooth,
                    size: 14,
                    color: _btConnected ? kDashSuccess : kDashTextSec,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _btConnected ? 'Connecté' : 'Déconnecté',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: _btConnected ? kDashSuccess : kDashTextSec,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: kDashPrimary.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.timer_outlined, size: 13, color: kDashPrimary),
                SizedBox(width: 4),
                Text(
                  '00:12:34',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: kDashPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        child: Column(
          children: [
            HeroMetricCard(
              label: 'Distance parcourue',
              value: '2.4',
              unit: 'km',
              icon: Icons.route_outlined,
              color: kDashAccent,
            ),
            const SizedBox(height: 14),
            const SpeedGaugeCard(
              label: 'Vitesse actuelle',
              value: '8.5',
              unit: 'km/h',
              speedFraction: 0.57,
            ),
            const SizedBox(height: 14),
            const Row(
              children: [
                Expanded(
                  child: SmallMetricCard(
                    label: 'Pied gauche',
                    value: '37.5',
                    unit: 'kg',
                    icon: Icons.arrow_back,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: SmallMetricCard(
                    label: 'Pied droit',
                    value: '34.8',
                    unit: 'kg',
                    icon: Icons.arrow_forward,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            const BalanceCard(
              totalWeight: '72.3',
              leftPercent: 0.52,
              rightPercent: 0.48,
            ),
            const SizedBox(height: 14),
            HeroMetricCard(
              label: 'Temps écoulé',
              value: '12:34',
              unit: 'min',
              icon: Icons.timer_outlined,
              color: const Color(0xFF7C3AED),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () => _saveSession(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: kDashPrimary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18)),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.stop_circle_outlined, size: 20),
                    SizedBox(width: 10),
                    Text(
                      'Terminer la session',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
