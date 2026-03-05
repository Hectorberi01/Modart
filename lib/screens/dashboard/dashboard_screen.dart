import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:intl/intl.dart';
import 'package:modar/models/session.dart';
import 'package:modar/providers.dart';
import 'dashboard_constants.dart';
import 'widgets/hero_metric_card.dart';
import 'widgets/speed_gauge_card.dart';
import 'widgets/small_metric_card.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  bool _saving = false;

  String _formatDuration(Duration d) {
    final m = d.inMinutes;
    final s = d.inSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  Future<void> _finishSession() async {
    final session = ref.read(shoeSessionViewModelProvider);
    if (session.steps == 0) {
      ref.read(shoeSessionViewModelProvider.notifier).resetSession();
      return;
    }

    setState(() => _saving = true);

    final shoeService = ref.read(shoeDataServiceProvider);
    final btService = ref.read(bluetoothServiceProvider);
    final db = ref.read(databaseServiceProvider);
    final now = DateTime.now();

    final distanceKm = session.distance / 1000;
    final distanceStr = '${distanceKm.toStringAsFixed(2)} km';
    final durationStr = _formatDuration(shoeService.sessionDuration);

    final dbSession = Session(
      title: 'Session ${DateFormat('HH:mm').format(now)}',
      date: DateFormat('dd MMMM yyyy', 'fr').format(now),
      time: DateFormat('HH:mm').format(now),
      duration: durationStr,
      distance: distanceStr,
      avgSpeed: '${session.cadence.toStringAsFixed(0)} pas/min',
      steps: session.steps,
      postureScore: session.postureScore,
      globalScore: session.globalScore,
    );

    await db.insertSession(dbSession);

    // Déconnecter le device BT + annuler les subscriptions + arrêter la simulation
    await btService.disconnectAll();

    ref.read(shoeSessionViewModelProvider.notifier).resetSession();
    ref.invalidate(sessionsProvider);

    if (mounted) {
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Session enregistrée avec succès !'),
          backgroundColor: kDashSuccess,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(shoeSessionViewModelProvider);
    final bluetoothService = ref.watch(bluetoothServiceProvider);

    final distanceValue = session.distance >= 1000
        ? (session.distance / 1000).toStringAsFixed(2)
        : session.distance.toStringAsFixed(0);
    final distanceUnit = session.distance >= 1000 ? 'km' : 'm';

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
          if (session.badPosition)
            Container(
              margin: const EdgeInsets.only(right: 4),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFEB5757).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.warning_amber_rounded, size: 14, color: Color(0xFFEB5757)),
                  SizedBox(width: 4),
                  Text(
                    'Posture',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Color(0xFFEB5757)),
                  ),
                ],
              ),
            ),
          StreamBuilder<BluetoothAdapterState>(
            stream: bluetoothService.adapterState,
            initialData: BluetoothAdapterState.unknown,
            builder: (context, snap) {
              final connected = FlutterBluePlus.connectedDevices.isNotEmpty;
              final btOn = snap.data == BluetoothAdapterState.on;
              final label = connected ? 'Connecté' : (btOn ? 'BT actif' : 'Déconnecté');
              final color = connected ? kDashSuccess : (btOn ? kDashAccent : kDashTextSec);
              return Container(
                margin: const EdgeInsets.only(right: 16),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.bluetooth, size: 14, color: color),
                    const SizedBox(width: 4),
                    Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: color)),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        child: Column(
          children: [
            HeroMetricCard(
              label: 'Pas total',
              value: '${session.steps}',
              unit: 'pas',
              icon: Icons.directions_walk,
              color: kDashAccent,
            ),
            const SizedBox(height: 14),
            SpeedGaugeCard(
              label: 'Cadence',
              value: session.cadence.toStringAsFixed(0),
              unit: 'pas/min',
              speedFraction: (session.cadence / 200).clamp(0.0, 1.0),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: SmallMetricCard(
                    label: 'Distance',
                    value: distanceValue,
                    unit: distanceUnit,
                    icon: Icons.route,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SmallMetricCard(
                    label: 'Score posture',
                    value: session.postureScore.toStringAsFixed(0),
                    unit: '%',
                    icon: Icons.self_improvement,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            HeroMetricCard(
              label: 'Score global',
              value: session.globalScore.toStringAsFixed(1),
              unit: '%',
              icon: Icons.star_outline,
              color: const Color(0xFF7C3AED),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _saving ? null : _finishSession,
                style: ElevatedButton.styleFrom(
                  backgroundColor: kDashPrimary,
                  disabledBackgroundColor: kDashPrimary.withValues(alpha: 0.5),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                ),
                child: _saving
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.stop_circle_outlined, size: 20),
                          SizedBox(width: 10),
                          Text('Terminer la session', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
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
