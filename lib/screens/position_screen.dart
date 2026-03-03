import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'bluetooth_screen.dart';

class PositionScreen extends StatefulWidget {
  const PositionScreen({super.key});

  @override
  State<PositionScreen> createState() => _PositionScreenState();
}

class _PositionScreenState extends State<PositionScreen> {
  List<BluetoothDevice> _connectedDevices = [];
  StreamSubscription? _connectionEventSub;

  @override
  void initState() {
    super.initState();
    _connectedDevices = FlutterBluePlus.connectedDevices;
    _connectionEventSub =
        FlutterBluePlus.events.onConnectionStateChanged.listen((_) {
      if (mounted) {
        setState(() => _connectedDevices = FlutterBluePlus.connectedDevices);
      }
    });
  }

  @override
  void dispose() {
    _connectionEventSub?.cancel();
    super.dispose();
  }

  void _openBluetooth() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BluetoothScreen(onContinue: () => Navigator.pop(context)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Position des Pieds',
          style: TextStyle(
              fontSize: 18, fontWeight: FontWeight.w500, color: Colors.black),
        ),
      ),
      body: _connectedDevices.isEmpty
          ? _buildNoDeviceView()
          : _buildPressureView(),
    );
  }

  Widget _buildNoDeviceView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F7),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(Icons.bluetooth_disabled,
                  size: 40, color: Colors.grey),
            ),
            const SizedBox(height: 20),
            const Text(
              'Aucune chaussure connectée',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            const Text(
              'Connectez-vous à une chaussure pour visualiser les données de pression plantaire.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 13, height: 1.5),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _openBluetooth,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('Connecter une chaussure',
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPressureView() {
    final bool showLeft = _connectedDevices.isNotEmpty;
    final bool showRight = _connectedDevices.length >= 2;

    // Mock data — à remplacer par les vraies données BLE
    const double leftWeight = 34.2;
    const double rightWeight = 35.8;
    final double totalWeight = showRight ? leftWeight + rightWeight : leftWeight;
    final double leftPercent = leftWeight / (leftWeight + rightWeight);
    final double rightPercent = rightWeight / (leftWeight + rightWeight);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          // Pressure map card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF1C1C2E),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              children: [
                const Text(
                  'Carte de Pression Plantaire',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Analyse biomécanique en direct',
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
                const SizedBox(height: 28),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    if (showLeft)
                      _FootView(
                        label: 'Gauche',
                        pressure: leftPercent,
                      ),
                    if (showRight)
                      _FootView(
                        label: 'Droit',
                        pressure: rightPercent,
                      ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _LegendDot(
                        color: Colors.white.withValues(alpha: 0.3),
                        label: 'Faible'),
                    const SizedBox(width: 16),
                    _LegendDot(
                        color: Colors.white.withValues(alpha: 0.65),
                        label: 'Moyen'),
                    const SizedBox(width: 16),
                    _LegendDot(color: Colors.white, label: 'Élevé'),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          // Weight cards
          Row(
            children: [
              if (showLeft)
                Expanded(
                  child: _MetricCard(
                    label: 'Pied Gauche',
                    value: leftWeight.toStringAsFixed(1),
                    unit: 'kg',
                  ),
                ),
              if (showLeft && showRight) const SizedBox(width: 12),
              if (showRight)
                Expanded(
                  child: _MetricCard(
                    label: 'Pied Droit',
                    value: rightWeight.toStringAsFixed(1),
                    unit: 'kg',
                  ),
                ),
            ],
          ),
          if (showLeft && showRight) ...[
            const SizedBox(height: 12),
            _BalanceCard(leftPercent: leftPercent, rightPercent: rightPercent),
          ],
          const SizedBox(height: 12),
          _MetricCard(
            label: 'Poids Total',
            value: totalWeight.toStringAsFixed(1),
            unit: 'kg',
            centered: true,
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

// ─── Foot Visualization ───────────────────────────────────────────────────────

class _FootView extends StatelessWidget {
  const _FootView({required this.label, required this.pressure});
  final String label;
  final double pressure; // 0.0 – 1.0

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: 110,
          height: 200,
          child: CustomPaint(painter: _FootPainter(pressure: pressure)),
        ),
        const SizedBox(height: 10),
        Text(
          label,
          style:
              const TextStyle(color: Colors.white70, fontSize: 13, height: 1),
        ),
      ],
    );
  }
}

class _FootPainter extends CustomPainter {
  const _FootPainter({required this.pressure});
  final double pressure;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final r = w / 2;

    // Build arch path (arch top + rectangular body)
    final path = Path()
      ..moveTo(0, h)
      ..lineTo(0, r)
      ..arcTo(Rect.fromLTWH(0, 0, w, w), math.pi, -math.pi, false)
      ..lineTo(w, h)
      ..close();

    // Clip to arch
    canvas.save();
    canvas.clipPath(path);

    // Background fill
    canvas.drawRect(
      Rect.fromLTWH(0, 0, w, h),
      Paint()..color = const Color(0xFF2A2A4A),
    );

    // Helper: draw radial pressure spot
    void drawSpot(Offset center, double radius, double opacity) {
      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..shader = RadialGradient(
            colors: [
              Colors.white.withValues(alpha: opacity),
              Colors.white.withValues(alpha: 0),
            ],
          ).createShader(
              Rect.fromCircle(center: center, radius: radius)),
      );
    }

    // Ball of foot (upper)
    drawSpot(Offset(w * 0.5, h * 0.32), 38, 0.85 * pressure);
    // Arch (middle, lighter)
    drawSpot(Offset(w * 0.38, h * 0.55), 18, 0.25 * pressure);
    // Heel
    drawSpot(Offset(w * 0.5, h * 0.79), 28, 0.75 * pressure);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _FootPainter old) => old.pressure != pressure;
}

// ─── Legend ───────────────────────────────────────────────────────────────────

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        ),
        const SizedBox(width: 5),
        Text(label,
            style: const TextStyle(color: Colors.white54, fontSize: 11)),
      ],
    );
  }
}

// ─── Metric Card ─────────────────────────────────────────────────────────────

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    required this.unit,
    this.centered = false,
  });

  final String label;
  final String value;
  final String unit;
  final bool centered;

  @override
  Widget build(BuildContext context) {
    final alignment =
        centered ? CrossAxisAlignment.center : CrossAxisAlignment.start;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F7),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: alignment,
        children: [
          Row(
            mainAxisAlignment: centered
                ? MainAxisAlignment.center
                : MainAxisAlignment.start,
            children: [
              const Icon(Icons.speed, size: 14, color: Colors.grey),
              const SizedBox(width: 4),
              Text(label,
                  style: const TextStyle(color: Colors.grey, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: centered
                ? MainAxisAlignment.center
                : MainAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -1),
              ),
              const SizedBox(width: 4),
              Padding(
                padding: const EdgeInsets.only(bottom: 5),
                child: Text(unit,
                    style:
                        const TextStyle(color: Colors.grey, fontSize: 13)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Balance Card ─────────────────────────────────────────────────────────────

class _BalanceCard extends StatelessWidget {
  const _BalanceCard(
      {required this.leftPercent, required this.rightPercent});
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
    if (diff < 0.05) return Colors.green;
    if (diff < 0.10) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F7),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Équilibre',
                  style: TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 14)),
              Row(
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                        shape: BoxShape.circle, color: _statusColor),
                  ),
                  const SizedBox(width: 5),
                  Text(_status,
                      style: TextStyle(
                          color: _statusColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w600)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Balance bar
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(
              height: 12,
              child: LayoutBuilder(builder: (context, constraints) {
                final totalWidth = constraints.maxWidth;
                final leftWidth = totalWidth * leftPercent;
                return Stack(
                  children: [
                    // Right side (dark)
                    Container(color: Colors.black),
                    // Left side (lighter)
                    Container(
                      width: leftWidth,
                      color: Colors.black.withValues(alpha: 0.25),
                    ),
                    // Center marker
                    Positioned(
                      left: totalWidth / 2 - 1,
                      child: Container(
                          width: 2, height: 12, color: Colors.white),
                    ),
                  ],
                );
              }),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${(leftPercent * 100).toStringAsFixed(1)}%',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const Text('Gauche',
                      style: TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${(rightPercent * 100).toStringAsFixed(1)}%',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const Text('Droit',
                      style: TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
