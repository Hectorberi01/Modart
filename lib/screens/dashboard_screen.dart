import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../models/session.dart';
import '../services/database_service.dart';
import 'package:intl/intl.dart';
import 'bluetooth_screen.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

const _kPrimary = Color(0xFF1C1F2E);
const _kAccent = Color(0xFF2F80ED);
const _kSuccess = Color(0xFF27AE60);
const _kTextSec = Color(0xFF6B7280);
const _kBg = Color(0xFFF7F8FA);

List<BoxShadow> _cardShadow() => [
  BoxShadow(
    color: Colors.black.withValues(alpha: 0.06),
    blurRadius: 20,
    offset: const Offset(0, 4),
  ),
];

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
        setState(
          () => _btConnected = FlutterBluePlus.connectedDevices.isNotEmpty,
        );
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
          backgroundColor: _kPrimary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kBg,
        titleSpacing: 20,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              DateFormat('EEEE d MMMM', 'fr').format(DateTime.now()),
              style: const TextStyle(
                color: _kTextSec,
                fontSize: 12,
                fontWeight: FontWeight.w400,
              ),
            ),
            const Text(
              'Session en cours',
              style: TextStyle(
                color: _kPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        actions: [
          // BT indicator
          GestureDetector(
            onTap:
                () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (_) => BluetoothScreen(
                          onContinue: () => Navigator.pop(context),
                        ),
                  ),
                ),
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color:
                    _btConnected
                        ? _kSuccess.withValues(alpha: 0.1)
                        : Colors.grey.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.bluetooth,
                    size: 14,
                    color: _btConnected ? _kSuccess : _kTextSec,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _btConnected ? 'Connecté' : 'Déconnecté',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: _btConnected ? _kSuccess : _kTextSec,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Timer
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: _kPrimary.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.timer_outlined, size: 13, color: _kPrimary),
                SizedBox(width: 4),
                Text(
                  '00:12:34',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _kPrimary,
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
            // Distance — hero card
            _HeroMetricCard(
              label: 'Distance parcourue',
              value: '2.4',
              unit: 'km',
              icon: Icons.route_outlined,
              color: _kAccent,
            ),
            const SizedBox(height: 14),

            // Speed — gauge card
            const _SpeedGaugeCard(
              label: 'Vitesse actuelle',
              value: '8.5',
              unit: 'km/h',
              speedFraction: 0.57,
            ),
            const SizedBox(height: 14),

            // Weight row
            const Row(
              children: [
                Expanded(
                  child: _SmallMetricCard(
                    label: 'Pied gauche',
                    value: '37.5',
                    unit: 'kg',
                    icon: Icons.arrow_back,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: _SmallMetricCard(
                    label: 'Pied droit',
                    value: '34.8',
                    unit: 'kg',
                    icon: Icons.arrow_forward,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Balance card
            const _BalanceCard(
              totalWeight: '72.3',
              leftPercent: 0.52,
              rightPercent: 0.48,
            ),
            const SizedBox(height: 14),

            // Time
            _HeroMetricCard(
              label: 'Temps écoulé',
              value: '12:34',
              unit: 'min',
              icon: Icons.timer_outlined,
              color: const Color(0xFF7C3AED),
            ),
            const SizedBox(height: 32),

            // End session button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () => _saveSession(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kPrimary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.stop_circle_outlined, size: 20),
                    SizedBox(width: 10),
                    Text(
                      'Terminer la session',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
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

// ─── Hero metric card ─────────────────────────────────────────────────────────

class _HeroMetricCard extends StatelessWidget {
  const _HeroMetricCard({
    required this.label,
    required this.value,
    required this.unit,
    required this.icon,
    required this.color,
  });
  final String label;
  final String value;
  final String unit;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: _cardShadow(),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(icon, size: 14, color: color),
                    const SizedBox(width: 6),
                    Text(
                      label,
                      style: const TextStyle(color: _kTextSec, fontSize: 13),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      value,
                      style: const TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: _kPrimary,
                        height: 1,
                        letterSpacing: -1.5,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8, left: 6),
                      child: Text(
                        unit,
                        style: const TextStyle(
                          color: _kTextSec,
                          fontSize: 18,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
        ],
      ),
    );
  }
}

// ─── Speed gauge card ─────────────────────────────────────────────────────────

class _SpeedGaugeCard extends StatelessWidget {
  const _SpeedGaugeCard({
    required this.label,
    required this.value,
    required this.unit,
    required this.speedFraction,
  });
  final String label;
  final String value;
  final String unit;
  final double speedFraction;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: _cardShadow(),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.speed, size: 14, color: Color(0xFFF59E0B)),
                    SizedBox(width: 6),
                    Text(
                      'Vitesse actuelle',
                      style: TextStyle(color: _kTextSec, fontSize: 13),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      value,
                      style: const TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: _kPrimary,
                        height: 1,
                        letterSpacing: -1.5,
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.only(bottom: 8, left: 6),
                      child: Text(
                        'km/h',
                        style: TextStyle(
                          color: _kTextSec,
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(
            width: 80,
            height: 80,
            child: CustomPaint(
              painter: _ArcGaugePainter(fraction: speedFraction),
            ),
          ),
        ],
      ),
    );
  }
}

class _ArcGaugePainter extends CustomPainter {
  const _ArcGaugePainter({required this.fraction});
  final double fraction;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 6;
    const startAngle = math.pi * 0.75;
    const sweepTotal = math.pi * 1.5;

    // Track
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepTotal,
      false,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.06)
        ..strokeWidth = 8
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );

    // Value arc
    if (fraction > 0) {
      final paint =
          Paint()
            ..shader = const SweepGradient(
              colors: [Color(0xFF2F80ED), Color(0xFF7C3AED)],
              startAngle: 0,
              endAngle: math.pi * 2,
            ).createShader(Rect.fromCircle(center: center, radius: radius))
            ..strokeWidth = 8
            ..style = PaintingStyle.stroke
            ..strokeCap = StrokeCap.round;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepTotal * fraction,
        false,
        paint,
      );
    }

    // Center text
    final tp = TextPainter(
      text: TextSpan(
        text: '${(fraction * 100).toInt()}%',
        style: const TextStyle(
          color: _kPrimary,
          fontSize: 13,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: ui.TextDirection.ltr,
    )..layout();
    tp.paint(canvas, center - Offset(tp.width / 2, tp.height / 2));
  }

  @override
  bool shouldRepaint(covariant _ArcGaugePainter old) =>
      old.fraction != fraction;
}

// ─── Small metric card ────────────────────────────────────────────────────────

class _SmallMetricCard extends StatelessWidget {
  const _SmallMetricCard({
    required this.label,
    required this.value,
    required this.unit,
    required this.icon,
  });
  final String label;
  final String value;
  final String unit;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: _cardShadow(),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 12, color: _kTextSec),
              const SizedBox(width: 5),
              Flexible(
                child: Text(
                  label,
                  style: const TextStyle(color: _kTextSec, fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: _kPrimary,
                  height: 1,
                  letterSpacing: -0.5,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 4, left: 4),
                child: Text(
                  unit,
                  style: const TextStyle(color: _kTextSec, fontSize: 13),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Balance card ─────────────────────────────────────────────────────────────

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({
    required this.totalWeight,
    required this.leftPercent,
    required this.rightPercent,
  });
  final String totalWeight;
  final double leftPercent;
  final double rightPercent;

  String get _status {
    final diff = (leftPercent - 0.5).abs();
    if (diff < 0.05) return 'Optimal';
    if (diff < 0.10) return 'Acceptable';
    return 'Déséquilibré';
  }

  Color get _statusColor {
    final diff = (leftPercent - 0.5).abs();
    if (diff < 0.05) return _kSuccess;
    if (diff < 0.10) return const Color(0xFFF59E0B);
    return const Color(0xFFEB5757);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: _cardShadow(),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.balance, size: 14, color: _kTextSec),
                  SizedBox(width: 6),
                  Text(
                    'Poids & équilibre',
                    style: TextStyle(color: _kTextSec, fontSize: 13),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _status,
                  style: TextStyle(
                    color: _statusColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                totalWeight,
                style: const TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: _kPrimary,
                  height: 1,
                  letterSpacing: -1,
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(bottom: 5, left: 5),
                child: Text(
                  'kg',
                  style: TextStyle(color: _kTextSec, fontSize: 16),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _BalanceRow(label: 'Gauche', percent: leftPercent, color: _kAccent),
          const SizedBox(height: 10),
          _BalanceRow(
            label: 'Droite',
            percent: rightPercent,
            color: const Color(0xFF7C3AED),
          ),
        ],
      ),
    );
  }
}

class _BalanceRow extends StatelessWidget {
  const _BalanceRow({
    required this.label,
    required this.percent,
    required this.color,
  });
  final String label;
  final double percent;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(color: _kTextSec, fontSize: 12)),
            Text(
              '${(percent * 100).toInt()}%',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 12,
                color: _kPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: percent,
            minHeight: 6,
            backgroundColor: Colors.black.withValues(alpha: 0.06),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}
