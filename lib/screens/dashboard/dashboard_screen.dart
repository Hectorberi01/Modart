import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:intl/intl.dart';
import 'package:modar/l10n/app_localizations.dart';
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
    final l = AppLocalizations.of(context);
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
    final locale = ref.read(appSettingsProvider).locale.languageCode;

    final distanceKm = session.distance / 1000;
    final distanceStr = '${distanceKm.toStringAsFixed(2)} km';
    final durationStr = _formatDuration(shoeService.sessionDuration);

    final dbSession = Session(
      title: 'Session ${DateFormat('HH:mm').format(now)}',
      date: DateFormat('dd MMMM yyyy', locale).format(now),
      time: DateFormat('HH:mm').format(now),
      duration: durationStr,
      distance: distanceStr,
      avgSpeed: '${session.cadence.toStringAsFixed(0)} ${l.dashStepsPerMin}',
      steps: session.steps,
      postureScore: session.postureScore,
      globalScore: session.globalScore,
    );

    await db.insertSession(dbSession);
    await btService.disconnectAll();

    ref.read(shoeSessionViewModelProvider.notifier).resetSession();
    ref.invalidate(sessionsProvider);

    if (mounted) {
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l.dashSessionSaved),
          backgroundColor: kDashSuccess,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final session = ref.watch(shoeSessionViewModelProvider);
    final bluetoothService = ref.watch(bluetoothServiceProvider);
    final locale = ref.watch(appSettingsProvider).locale.languageCode;

    final distanceValue = session.distance >= 1000
        ? (session.distance / 1000).toStringAsFixed(2)
        : session.distance.toStringAsFixed(0);
    final distanceUnit = session.distance >= 1000 ? 'km' : 'm';

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 20,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              DateFormat('EEEE d MMMM', locale).format(DateTime.now()),
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                fontSize: 12,
                fontWeight: FontWeight.w400,
              ),
            ),
            Text(
              l.dashTitle,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
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
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFEB5757).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.warning_amber_rounded,
                      size: 14, color: Color(0xFFEB5757)),
                  const SizedBox(width: 4),
                  Text(
                    l.dashPostureWarning,
                    style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFFEB5757)),
                  ),
                ],
              ),
            ),
          StreamBuilder<BluetoothAdapterState>(
            stream: bluetoothService.adapterState,
            initialData: BluetoothAdapterState.unknown,
            builder: (context, snap) {
              final connected =
                  FlutterBluePlus.connectedDevices.isNotEmpty;
              final btOn = snap.data == BluetoothAdapterState.on;
              final label = connected
                  ? l.dashConnected
                  : (btOn ? l.dashBtActive : l.dashDisconnected);
              final color = connected
                  ? kDashSuccess
                  : (btOn ? kDashAccent : kDashTextSec);
              return Container(
                margin: const EdgeInsets.only(right: 16),
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.bluetooth, size: 14, color: color),
                    const SizedBox(width: 4),
                    Text(label,
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: color)),
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
              label: l.dashStepsLabel,
              value: '${session.steps}',
              unit: l.dashStepUnit,
              icon: Icons.directions_walk,
              color: kDashAccent,
            ),
            const SizedBox(height: 14),
            SpeedGaugeCard(
              label: l.dashCadenceLabel,
              value: session.cadence.toStringAsFixed(0),
              unit: l.dashStepsPerMin,
              speedFraction: (session.cadence / 200).clamp(0.0, 1.0),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: SmallMetricCard(
                    label: l.dashDistanceLabel,
                    value: distanceValue,
                    unit: distanceUnit,
                    icon: Icons.route,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SmallMetricCard(
                    label: l.dashPostureScoreLabel,
                    value: session.postureScore.toStringAsFixed(0),
                    unit: '%',
                    icon: Icons.self_improvement,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            HeroMetricCard(
              label: l.dashGlobalScoreLabel,
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
                  disabledBackgroundColor:
                      kDashPrimary.withValues(alpha: 0.5),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18)),
                ),
                child: _saving
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.stop_circle_outlined, size: 20),
                          const SizedBox(width: 10),
                          Text(l.dashFinishSession,
                              style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600)),
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
