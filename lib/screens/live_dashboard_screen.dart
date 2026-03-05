import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../theme/app_theme.dart';
import 'bluetooth_screen.dart';
import '../widgets/glass_bento_card.dart';
import '../widgets/mesh_gradient_background.dart';
import '../widgets/pressure_map_painter.dart';
import '../widgets/mlpi_slider.dart';
import '../widgets/segment_badge.dart';
import '../widgets/metric_info_sheet.dart';
import '../models/pressure_data.dart';
import '../services/mock_data_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// LiveDashboardScreen — L'écran central Smartsole
//
// Bento Grid : carte pression (60%) + 4 KPI cards (40%).
// Top bar BLE + batterie + durée + pas. Micro-phrase BI si hotspot détecté.
// ─────────────────────────────────────────────────────────────────────────────

class LiveDashboardScreen extends StatefulWidget {
  const LiveDashboardScreen({super.key, this.showBlePrompt = false});

  /// Affiché une seule fois après connexion/inscription si BLE est déconnecté.
  final bool showBlePrompt;

  @override
  State<LiveDashboardScreen> createState() => _LiveDashboardScreenState();
}

class _LiveDashboardScreenState extends State<LiveDashboardScreen> {
  final MockDataService _mock = MockDataService.instance;

  // Session state
  bool _isSessionActive = false;
  int _totalSteps = 0;
  Duration _sessionDuration = Duration.zero;
  Timer? _sessionTimer;

  // Live data (updated by mock/BLE)
  late PressureData _leftPressure;
  late PressureData _rightPressure;
  double _cadence = 0;
  double _speed = 0;
  double _mlpi = 0;
  WalkSegment _segment = WalkSegment.stopped;

  // Hotspot micro-phrase
  String? _hotspotPhrase;
  Timer? _hotspotTimer;

  // BLE status (mock)
  final bool _bleConnected = false; // Par défaut faux pour simuler
  final int _batteryLeft = 78;
  final int _batteryRight = 82;

  @override
  void initState() {
    super.initState();
    _leftPressure = PressureData.zero;
    _rightPressure = PressureData.zero;

    if (widget.showBlePrompt) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _checkBleAndShowModal();
      });
    }
  }

  /// Vérifie l'état BLE réel et affiche la modale si déconnecté.
  void _checkBleAndShowModal() {
    Future.delayed(const Duration(milliseconds: 700), () {
      if (!mounted) return;
      final connected = FlutterBluePlus.connectedDevices;
      if (connected.isEmpty) _showBleModal();
    });
  }

  void _showBleModal() {
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.55),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => _BleConnectModal(
        onLater: () => Navigator.pop(ctx),
        onConnect: () {
          Navigator.pop(ctx);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (c) =>
                  BluetoothScreen(onContinue: () => Navigator.pop(c)),
            ),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _sessionTimer?.cancel();
    _hotspotTimer?.cancel();
    super.dispose();
  }

  void _toggleSession() {
    if (_isSessionActive) {
      setState(() => _isSessionActive = false);
      _stopSession();
    } else {
      setState(() {
        _isSessionActive = true;
        _startSession();
      });
    }
  }

  void _startSession() {
    _totalSteps = 0;
    _sessionDuration = Duration.zero;

    // Timer session + mise à jour live data
    _sessionTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        _sessionDuration += const Duration(seconds: 1);
        _totalSteps += 2; // ~120 pas/min simulés
        _updateLiveData();
      });
    });
  }

  void _stopSession() {
    _sessionTimer?.cancel();
    _sessionTimer = null;
    _navigateToSummaryWithTransition();
  }

  void _navigateToSummaryWithTransition() {
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.transparent,
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (ctx, anim1, anim2) {
        return FadeTransition(
          opacity: anim1,
          child: Scaffold(
            backgroundColor: SmartSoleColors.darkBg,
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 100,
                    height: 100,
                    child: Image.asset(
                      'assets/images/walk1.gif',
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Analyse en cours...',
                    style: TextStyle(
                      fontFamily: 'Articulat CF',
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: SmartSoleColors.textTertiaryDark,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
    Future.delayed(const Duration(milliseconds: 1400), () {
      if (!mounted) return;
      Navigator.pop(context);
      Navigator.pushNamed(context, '/summary');
    });
  }

  void _updateLiveData() {
    _leftPressure = _mock.thomasLeftPressure;
    _rightPressure = _mock.thomasRightPressure;
    _cadence =
        96 + ((_mock.thomasSessionData['cadence'] as int) - 96).toDouble();
    _speed = _mock.thomasSessionData['avgSpeed'] as double;
    _mlpi = _mock.thomasSessionData['mlpi'] as double;
    _segment = WalkSegment.normal;

    // Détection hotspot live
    if (_rightPressure.forefoot > kHotspotThreshold && _hotspotPhrase == null) {
      _showHotspotPhrase('Zone avant-pied droit — surcharge détectée');
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

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final TextTheme textTheme = Theme.of(context).textTheme;

    return MeshGradientBackground(
      biState: _isSessionActive ? BIState.normal : BIState.neutral,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Column(
            children: [
              // ── Top Bar ───────────────────────────────────────────────────
              _buildTopBar(isDark, textTheme),

              // ── Contenu scrollable ────────────────────────────────────────
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                  child: Column(
                    children: [
                      // ── Bloc principal : Carte Pression (60% logique) ─────
                      GlassBentoCard(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Carte de Pression',
                                  style: textTheme.titleLarge,
                                ),
                                if (_isSessionActive)
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: SmartSoleColors.biNormal,
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _isSessionActive
                                  ? 'Analyse en temps réel'
                                  : 'Démarrez une session',
                              style: textTheme.bodySmall,
                            ),
                            const SizedBox(height: 16),
                            PressureMapWidget(
                              leftPressure: _leftPressure,
                              rightPressure: _rightPressure,
                              showHotspotLabels: _isSessionActive,
                              height: 320,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      // ── Micro-phrase Hotspot ──────────────────────────────
                      if (_hotspotPhrase != null)
                        AnimatedOpacity(
                          opacity: _hotspotPhrase != null ? 1.0 : 0.0,
                          duration: const Duration(milliseconds: 400),
                          child: GlassBentoCard(
                            accentColor: SmartSoleColors.biWarning,
                            pulseOnAlert: true,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.warning_amber_rounded,
                                  color: SmartSoleColors.biWarning,
                                  size: 20,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    _hotspotPhrase!,
                                    style: textTheme.bodyMedium?.copyWith(
                                      color: SmartSoleColors.biWarning,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      if (_hotspotPhrase != null) const SizedBox(height: 12),

                      // ── Bento Grid secondaire (4 KPI cards) ───────────────
                      Row(
                        children: [
                          Expanded(
                            child: _KpiCard(
                              label: 'Cadence',
                              value:
                                  _isSessionActive
                                      ? _cadence.toInt().toString()
                                      : '--',
                              unit: 'pas/min',
                              icon: Icons.speed,
                              biState: _cadenceBIState(),
                              metric: MetricCatalog.cadence,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _KpiCard(
                              label: 'Vitesse',
                              value:
                                  _isSessionActive
                                      ? _speed.toStringAsFixed(1)
                                      : '--',
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
                                        Icon(
                                          Icons.swap_horiz,
                                          size: 16,
                                          color:
                                              isDark
                                                  ? Colors.white54
                                                  : Colors.black45,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          'MLPI',
                                          style: textTheme.titleSmall,
                                        ),
                                        const Spacer(),
                                        const MetricInfoButton(
                                          metric: MetricCatalog.mlpi,
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    MLPISlider(
                                      value: _isSessionActive ? _mlpi : 0,
                                    ),
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
                                        Icon(
                                          Icons.directions_run,
                                          size: 16,
                                          color:
                                              isDark
                                                  ? Colors.white54
                                                  : Colors.black45,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          'Segment',
                                          style: textTheme.titleSmall,
                                        ),
                                        const Spacer(),
                                        const MetricInfoButton(
                                          metric: MetricCatalog.segment,
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    Center(
                                      child: SegmentBadge(
                                        segment:
                                            _isSessionActive
                                                ? _segment
                                                : WalkSegment.stopped,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        // ── FAB Start/Stop ──────────────────────────────────────────────────
        floatingActionButton: _buildFAB(),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      ),
    );
  }

  Widget _buildTopBar(bool isDark, TextTheme textTheme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Row(
        children: [
          // BLE status
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color:
                  _bleConnected
                      ? SmartSoleColors.biNormal.withValues(alpha: 0.15)
                      : SmartSoleColors.biAlert.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.bluetooth,
                  size: 14,
                  color:
                      _bleConnected
                          ? SmartSoleColors.biNormal
                          : SmartSoleColors.biAlert,
                ),
                const SizedBox(width: 4),
                Text(
                  _bleConnected ? 'Connecté' : 'Déconnecté',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color:
                        _bleConnected
                            ? SmartSoleColors.biNormal
                            : SmartSoleColors.biAlert,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Batteries
          _BatteryChip(label: 'G', percent: _batteryLeft),
          const SizedBox(width: 4),
          _BatteryChip(label: 'D', percent: _batteryRight),
          const Spacer(),
          // Durée session
          if (_isSessionActive)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color:
                    isDark
                        ? Colors.white.withValues(alpha: 0.06)
                        : Colors.black.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.timer_outlined,
                    size: 13,
                    color: isDark ? Colors.white70 : Colors.black54,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _formatDuration(_sessionDuration),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'monospace',
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(width: 8),
          // Pas totaux
          if (_isSessionActive)
            Text(
              '$_totalSteps pas',
              style: textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFAB() {
    return SizedBox(
      width: 200,
      height: 56,
      child: FloatingActionButton.extended(
        onPressed: _toggleSession,
        backgroundColor:
            _isSessionActive
                ? SmartSoleColors.biAlert
                : SmartSoleColors.biNormal,
        foregroundColor: Colors.white,
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        icon: Icon(
          _isSessionActive
              ? Icons.stop_circle_outlined
              : Icons.play_circle_outline,
        ),
        label: Text(
          _isSessionActive ? 'Arrêter' : 'Démarrer',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  BIState _cadenceBIState() {
    if (!_isSessionActive) return BIState.neutral;
    if (_cadence >= 80 && _cadence <= 120) return BIState.normal;
    if (_cadence < 80) return BIState.alert;
    return BIState.warning;
  }
}

// ─── KPI Card interne ───────────────────────────────────────────────────────

class _KpiCard extends StatelessWidget {
  const _KpiCard({
    required this.label,
    required this.value,
    required this.unit,
    required this.icon,
    required this.biState,
    this.metric,
  });

  final String label;
  final String value;
  final String unit;
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
              Icon(
                icon,
                size: 16,
                color: isDark ? Colors.white54 : Colors.black45,
              ),
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
              Text(
                value,
                style: Theme.of(
                  context,
                ).textTheme.displaySmall?.copyWith(fontSize: 32, color: accent),
              ),
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

    // Wrap with tooltip for long-press explanation
    if (metric != null) {
      return MetricTooltipWrapper(metric: metric!, child: card);
    }
    return card;
  }
}

// ─── Battery Chip ───────────────────────────────────────────────────────────

class _BatteryChip extends StatelessWidget {
  const _BatteryChip({required this.label, required this.percent});

  final String label;
  final int percent;

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color color =
        percent > 20 ? SmartSoleColors.biNormal : SmartSoleColors.biAlert;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white54 : Colors.black45,
            ),
          ),
          const SizedBox(width: 2),
          Icon(
            percent > 50
                ? Icons.battery_full
                : percent > 20
                ? Icons.battery_3_bar
                : Icons.battery_alert,
            size: 12,
            color: color,
          ),
          const SizedBox(width: 2),
          Text(
            '$percent%',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Bluetooth Connect Modal ──────────────────────────────────────────────────

class _BleConnectModal extends StatelessWidget {
  const _BleConnectModal({required this.onLater, required this.onConnect});

  final VoidCallback onLater;
  final VoidCallback onConnect;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: SmartSoleColors.darkSurface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: SmartSoleColors.biWarning.withValues(alpha: 0.10),
              shape: BoxShape.circle,
              border: Border.all(
                color: SmartSoleColors.biWarning.withValues(alpha: 0.25),
                width: 1.5,
              ),
            ),
            child: const Icon(
              Icons.bluetooth_searching_rounded,
              size: 32,
              color: SmartSoleColors.biWarning,
            ),
          ),
          const SizedBox(height: 20),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'Connecter vos semelles',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Articulat CF',
                color: SmartSoleColors.textPrimaryDark,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 10),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'Connectez vos semelles Smartsole via Bluetooth pour démarrer une session d\'analyse.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Articulat CF',
                color: SmartSoleColors.textSecondaryDark,
                fontSize: 13,
                height: 1.55,
              ),
            ),
          ),
          const SizedBox(height: 28),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: onLater,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: BorderSide(
                          color: Colors.white.withValues(alpha: 0.12),
                        ),
                      ),
                    ),
                    child: const Text(
                      'Plus tard',
                      style: TextStyle(
                        fontFamily: 'Articulat CF',
                        color: SmartSoleColors.textSecondaryDark,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onConnect,
                    icon: const Icon(Icons.bluetooth, size: 18),
                    label: const Text(
                      'Connecter',
                      style: TextStyle(
                        fontFamily: 'Articulat CF',
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: SmartSoleColors.biNormal,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
