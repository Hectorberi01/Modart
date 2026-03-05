import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../l10n/app_localizations.dart';
import '../services/bluetooth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_bento_card.dart';
import '../widgets/mesh_gradient_background.dart';
import '../widgets/pressure_map_painter.dart';
import '../widgets/mlpi_slider.dart';
import '../widgets/segment_badge.dart';
import '../widgets/metric_info_sheet.dart';
import '../models/pressure_data.dart';
import '../models/session.dart';
import '../providers.dart';

// ─────────────────────────────────────────────────────────────────────────────
// LiveDashboardScreen — Real BLE data
// ─────────────────────────────────────────────────────────────────────────────

class LiveDashboardScreen extends ConsumerStatefulWidget {
  const LiveDashboardScreen({super.key});

  @override
  ConsumerState<LiveDashboardScreen> createState() => _LiveDashboardScreenState();
}

class _LiveDashboardScreenState extends ConsumerState<LiveDashboardScreen> {
  // Session state
  bool _isSessionActive = false;
  Duration _sessionDuration = Duration.zero;
  Timer? _sessionTimer;
  DateTime? _sessionStart;

  // Hotspot micro-phrase
  String? _hotspotPhrase;
  Timer? _hotspotTimer;

  @override
  void dispose() {
    _sessionTimer?.cancel();
    _hotspotTimer?.cancel();
    super.dispose();
  }

  void _toggleSession() {
    setState(() {
      _isSessionActive = !_isSessionActive;
      if (_isSessionActive) {
        _startSession();
      } else {
        _stopSession();
      }
    });
  }

  void _startSession() {
    // Reset the shoe data service for a fresh session
    ref.read(shoeDataServiceProvider).resetSession();
    ref.read(shoeSessionViewModelProvider.notifier).resetSession();

    _sessionStart = DateTime.now();
    _sessionDuration = Duration.zero;

    // Timer for session duration display
    _sessionTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        _sessionDuration = DateTime.now().difference(_sessionStart!);
      });

      // Check for posture warnings
      final session = ref.read(shoeSessionViewModelProvider);
      if (session.badPosition && _hotspotPhrase == null && mounted) {
        _showHotspotPhrase(AppLocalizations.of(context).dashBadPosture);
      }
    });
  }

  void _stopSession() {
    _sessionTimer?.cancel();
    _sessionTimer = null;

    // Save the session to database
    _saveSession();
  }

  Future<void> _saveSession() async {
    final session = ref.read(shoeSessionViewModelProvider);
    final now = DateTime.now();

    final newSession = Session(
      title: 'Session ${DateFormat('dd/MM').format(now)}',
      date: DateFormat('dd/MM/yyyy').format(now),
      time: DateFormat('HH:mm').format(_sessionStart ?? now),
      duration: _formatDuration(_sessionDuration),
      distance: '${(session.distance / 1000).toStringAsFixed(2)} km',
      avgSpeed: '${session.cadence.toStringAsFixed(0)} pas/min',
      steps: session.steps,
      postureScore: session.postureScore,
      globalScore: session.globalScore,
    );

    await ref.read(databaseServiceProvider).insertSession(newSession);
    ref.invalidate(sessionsProvider);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).dashSessionSaved),
          backgroundColor: SmartSoleColors.biSuccess,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  void _showHotspotPhrase(String phrase) {
    setState(() => _hotspotPhrase = phrase);
    _hotspotTimer?.cancel();
    _hotspotTimer = Timer(const Duration(seconds: 8), () {
      if (mounted) setState(() => _hotspotPhrase = null);
    });
  }

  String _formatDuration(Duration d) {
    final String hours = d.inHours.toString().padLeft(2, '0');
    final String minutes = (d.inMinutes % 60).toString().padLeft(2, '0');
    final String seconds = (d.inSeconds % 60).toString().padLeft(2, '0');
    if (d.inHours > 0) return '$hours:$minutes:$seconds';
    return '$minutes:$seconds';
  }

  WalkSegment _computeSegment(double cadence) {
    if (cadence <= 0) return WalkSegment.stopped;
    if (cadence < 60) return WalkSegment.slow;
    if (cadence < 120) return WalkSegment.normal;
    return WalkSegment.fast;
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final TextTheme textTheme = Theme.of(context).textTheme;

    // Watch real-time session data from Riverpod
    final session = ref.watch(shoeSessionViewModelProvider);
    final bluetoothService = ref.watch(bluetoothServiceProvider);

    // Check if we have live data (session active OR BLE connected)
    final hasData = _isSessionActive || session.steps > 0;

    // Derive pressure data from posture score (simplified mapping)
    final postureRatio = (100 - session.postureScore) / 100;
    final leftPressure = hasData
        ? PressureData(
            heel: 0.20 + postureRatio * 0.1,
            midfoot: 0.15,
            forefoot: 0.25 + postureRatio * 0.15,
            toe: 0.10 + postureRatio * 0.05,
          )
        : PressureData.zero;
    final rightPressure = hasData
        ? PressureData(
            heel: 0.22 + postureRatio * 0.08,
            midfoot: 0.18,
            forefoot: 0.20 + postureRatio * 0.12,
            toe: 0.12 + postureRatio * 0.03,
          )
        : PressureData.zero;

    // Derive MLPI from posture (simplified)
    final mlpi = hasData ? (session.postureScore - 50) / 100 : 0.0;
    final segment = hasData ? _computeSegment(session.cadence) : WalkSegment.stopped;
    final speed = _isSessionActive && _sessionDuration.inSeconds > 0
        ? (session.distance / 1000) / (_sessionDuration.inSeconds / 3600).clamp(0.001, double.infinity)
        : 0.0;

    return MeshGradientBackground(
      biState: _isSessionActive ? BIState.normal : BIState.neutral,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Column(
            children: [
              // -- Top Bar
              _buildTopBar(isDark, textTheme, session.steps, bluetoothService),

              // -- Scrollable content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                  child: Column(
                    children: [
                      // -- Main block: Pressure Map
                      GlassBentoCard(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(AppLocalizations.of(context).dashPressureMap, style: textTheme.titleLarge),
                                if (hasData)
                                  Container(
                                    width: 8, height: 8,
                                    decoration: const BoxDecoration(shape: BoxShape.circle, color: SmartSoleColors.biNormal),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              hasData ? AppLocalizations.of(context).dashRealTimeAnalysis : AppLocalizations.of(context).dashStartSession,
                              style: textTheme.bodySmall,
                            ),
                            const SizedBox(height: 16),
                            PressureMapWidget(
                              leftPressure: leftPressure,
                              rightPressure: rightPressure,
                              showHotspotLabels: hasData,
                              height: 320,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      // -- Hotspot micro-phrase
                      if (_hotspotPhrase != null)
                        AnimatedOpacity(
                          opacity: 1.0,
                          duration: const Duration(milliseconds: 400),
                          child: GlassBentoCard(
                            accentColor: SmartSoleColors.biWarning,
                            pulseOnAlert: true,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            child: Row(
                              children: [
                                const Icon(Icons.warning_amber_rounded, color: SmartSoleColors.biWarning, size: 20),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    _hotspotPhrase!,
                                    style: textTheme.bodyMedium?.copyWith(color: SmartSoleColors.biWarning, fontWeight: FontWeight.w600),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      if (_hotspotPhrase != null) const SizedBox(height: 12),

                      // -- KPI cards
                      Row(
                        children: [
                          Expanded(
                            child: _KpiCard(
                              label: AppLocalizations.of(context).dashCadenceLabel,
                              value: hasData ? session.cadence.toInt().toString() : '--',
                              unit: 'pas/min',
                              icon: Icons.speed,
                              biState: _cadenceBIState(session.cadence, hasData),
                              metric: MetricCatalog.cadence,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _KpiCard(
                              label: AppLocalizations.of(context).dashSpeed,
                              value: hasData ? speed.toStringAsFixed(1) : '--',
                              unit: 'km/h',
                              icon: Icons.directions_walk,
                              biState: BIState.normal,
                              metric: MetricCatalog.speed,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: MetricTooltipWrapper(
                              metric: MetricCatalog.mlpi,
                              child: GlassBentoCard(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(Icons.swap_horiz, size: 16, color: isDark ? Colors.white54 : Colors.black45),
                                        const SizedBox(width: 6),
                                        Text('MLPI', style: textTheme.titleSmall),
                                        const Spacer(),
                                        const MetricInfoButton(metric: MetricCatalog.mlpi),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    MLPISlider(value: hasData ? mlpi : 0),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: MetricTooltipWrapper(
                              metric: MetricCatalog.segment,
                              child: GlassBentoCard(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(Icons.directions_run, size: 16, color: isDark ? Colors.white54 : Colors.black45),
                                        const SizedBox(width: 6),
                                        Text(AppLocalizations.of(context).dashSegment, style: textTheme.titleSmall),
                                        const Spacer(),
                                        const MetricInfoButton(metric: MetricCatalog.segment),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    Center(child: SegmentBadge(segment: segment)),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      // -- Score global
                      const SizedBox(height: 10),
                      GlassBentoCard(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Icon(Icons.score, size: 20, color: isDark ? Colors.white54 : Colors.black45),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(AppLocalizations.of(context).dashGlobalScore, style: textTheme.titleSmall),
                                  const SizedBox(height: 4),
                                  Text('${AppLocalizations.of(context).dashPostureScoreLabel}: ${session.postureScore.toStringAsFixed(0)}%', style: textTheme.bodySmall),
                                ],
                              ),
                            ),
                            Text(
                              hasData ? '${session.globalScore.toStringAsFixed(0)}%' : '--',
                              style: textTheme.displaySmall?.copyWith(
                                fontSize: 32,
                                color: _scoreColor(session.globalScore),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        // -- FAB Start/Stop
        floatingActionButton: _buildFAB(),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      ),
    );
  }

  Color _scoreColor(double score) {
    if (score >= 70) return SmartSoleColors.biSuccess;
    if (score >= 40) return SmartSoleColors.biAlert;
    return const Color(0xFFEB5757);
  }

  Widget _buildTopBar(bool isDark, TextTheme textTheme, int totalSteps, AppBluetoothService bluetoothService) {
    return StreamBuilder<BluetoothAdapterState>(
      stream: bluetoothService.adapterState,
      initialData: BluetoothAdapterState.unknown,
      builder: (context, snapshot) {
        final bleOn = snapshot.data == BluetoothAdapterState.on;
        final isConnected = bluetoothService.isConnected;

        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: Row(
            children: [
              // BLE status
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: isConnected
                      ? SmartSoleColors.biNormal.withValues(alpha: 0.15)
                      : SmartSoleColors.biAlert.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.bluetooth, size: 14, color: isConnected ? SmartSoleColors.biNormal : SmartSoleColors.biAlert),
                    const SizedBox(width: 4),
                    Text(
                      isConnected ? AppLocalizations.of(context).dashConnected : (bleOn ? AppLocalizations.of(context).dashBtOn : AppLocalizations.of(context).dashBtOff),
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: isConnected ? SmartSoleColors.biNormal : SmartSoleColors.biAlert),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              // Session duration
              if (_isSessionActive)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.timer_outlined, size: 13, color: isDark ? Colors.white70 : Colors.black54),
                      const SizedBox(width: 4),
                      Text(
                        _formatDuration(_sessionDuration),
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, fontFamily: 'monospace', color: isDark ? Colors.white : Colors.black87),
                      ),
                    ],
                  ),
                ),
              const SizedBox(width: 8),
              if (_isSessionActive)
                Text('$totalSteps ${AppLocalizations.of(context).dashStepUnit}', style: textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFAB() {
    return SizedBox(
      width: 200,
      height: 56,
      child: FloatingActionButton.extended(
        onPressed: _toggleSession,
        backgroundColor: _isSessionActive ? SmartSoleColors.biAlert : SmartSoleColors.biNormal,
        foregroundColor: Colors.white,
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        icon: Icon(_isSessionActive ? Icons.stop_circle_outlined : Icons.play_circle_outline),
        label: Text(
          _isSessionActive ? AppLocalizations.of(context).dashStop : AppLocalizations.of(context).dashStart,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  BIState _cadenceBIState(double cadence, bool hasData) {
    if (!hasData) return BIState.neutral;
    if (cadence >= 80 && cadence <= 120) return BIState.normal;
    if (cadence < 80) return BIState.alert;
    return BIState.warning;
  }
}

// --- KPI Card

class _KpiCard extends StatelessWidget {
  const _KpiCard({required this.label, required this.value, required this.unit, required this.icon, required this.biState, this.metric});

  final String label, value, unit;
  final IconData icon;
  final BIState biState;
  final MetricInfo? metric;

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color accent = SmartSoleColors.colorForState(biState);

    final Widget card = GlassBentoCard(
      accentColor: accent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: isDark ? Colors.white54 : Colors.black45),
              const SizedBox(width: 6),
              Text(label, style: Theme.of(context).textTheme.titleSmall),
              const Spacer(),
              if (metric != null) MetricInfoButton(metric: metric!),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(value, style: Theme.of(context).textTheme.displaySmall?.copyWith(fontSize: 32, color: accent)),
              const SizedBox(width: 4),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(unit, style: Theme.of(context).textTheme.bodySmall),
              ),
            ],
          ),
        ],
      ),
    );

    if (metric != null) return MetricTooltipWrapper(metric: metric!, child: card);
    return card;
  }
}
