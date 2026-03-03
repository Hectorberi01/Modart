import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'bluetooth_screen.dart';

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
    _connectionEventSub = FlutterBluePlus.events.onConnectionStateChanged
        .listen((_) {
          if (mounted) {
            setState(
              () => _connectedDevices = FlutterBluePlus.connectedDevices,
            );
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
        builder:
            (_) => BluetoothScreen(onContinue: () => Navigator.pop(context)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kBg,
        centerTitle: true,
        title: const Text(
          'Position des Pieds',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: _kPrimary,
          ),
        ),
      ),
      body:
          _connectedDevices.isEmpty
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
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: _cardShadow(),
              ),
              child: const Icon(
                Icons.bluetooth_disabled,
                size: 36,
                color: _kTextSec,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Aucune chaussure connectée',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: _kPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Connectez-vous à une chaussure pour visualiser les données de pression plantaire.',
              textAlign: TextAlign.center,
              style: TextStyle(color: _kTextSec, fontSize: 13, height: 1.6),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _openBluetooth,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kPrimary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  'Connecter une chaussure',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPressureView() {
    final showLeft = _connectedDevices.isNotEmpty;
    final showRight = _connectedDevices.length >= 2;

    // Mock data — à remplacer par les vraies données BLE
    const double leftWeight = 34.2;
    const double rightWeight = 35.8;
    final double total = showRight ? leftWeight + rightWeight : leftWeight;
    final double leftPct = leftWeight / (leftWeight + rightWeight);
    final double rightPct = rightWeight / (leftWeight + rightWeight);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      child: Column(
        children: [
          // Heatmap card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: const Color(0xFF0F1623),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0F1623).withValues(alpha: 0.3),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              children: [
                const Text(
                  'Carte de Pression Plantaire',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Analyse biomécanique en direct',
                  style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 12),
                ),
                const SizedBox(height: 28),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    if (showLeft) _FootView(label: 'Gauche', pressure: leftPct),
                    if (showRight)
                      _FootView(label: 'Droit', pressure: rightPct),
                  ],
                ),
                const SizedBox(height: 22),
                // Legend
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _LegendItem(
                      color: _kAccent.withValues(alpha: 0.8),
                      label: 'Faible',
                    ),
                    const SizedBox(width: 18),
                    _LegendItem(color: const Color(0xFFF59E0B), label: 'Moyen'),
                    const SizedBox(width: 18),
                    _LegendItem(color: const Color(0xFFEB5757), label: 'Élevé'),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Weight chips
          Row(
            children: [
              if (showLeft)
                Expanded(
                  child: _StatCard(
                    icon: Icons.arrow_back,
                    label: 'Pied Gauche',
                    value: leftWeight.toStringAsFixed(1),
                    unit: 'kg',
                    accentColor: _kAccent,
                  ),
                ),
              if (showLeft && showRight) const SizedBox(width: 12),
              if (showRight)
                Expanded(
                  child: _StatCard(
                    icon: Icons.arrow_forward,
                    label: 'Pied Droit',
                    value: rightWeight.toStringAsFixed(1),
                    unit: 'kg',
                    accentColor: const Color(0xFF7C3AED),
                  ),
                ),
            ],
          ),

          if (showLeft && showRight) ...[
            const SizedBox(height: 12),
            _BalanceCard(leftPercent: leftPct, rightPercent: rightPct),
          ],

          const SizedBox(height: 12),

          // Total weight
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 22),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: _cardShadow(),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Column(
                  children: [
                    const Text(
                      'Poids Total',
                      style: TextStyle(color: _kTextSec, fontSize: 12),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          total.toStringAsFixed(1),
                          style: const TextStyle(
                            fontSize: 40,
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
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Foot Visualization ───────────────────────────────────────────────────────

class _FootView extends StatelessWidget {
  const _FootView({required this.label, required this.pressure});
  final String label;
  final double pressure;

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
          style: const TextStyle(
            color: Color(0xFF9CA3AF),
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
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

    final path =
        Path()
          ..moveTo(0, h)
          ..lineTo(0, r)
          ..arcTo(Rect.fromLTWH(0, 0, w, w), math.pi, -math.pi, false)
          ..lineTo(w, h)
          ..close();

    canvas.save();
    canvas.clipPath(path);

    // Background
    canvas.drawRect(
      Rect.fromLTWH(0, 0, w, h),
      Paint()..color = const Color(0xFF1A2035),
    );

    // Pressure blobs — bleu (low) → orange → rouge (high)
    void drawSpot(
      Offset center,
      double radius,
      Color innerColor,
      double opacity,
    ) {
      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..shader = RadialGradient(
            colors: [
              innerColor.withValues(alpha: opacity),
              innerColor.withValues(alpha: 0),
            ],
          ).createShader(Rect.fromCircle(center: center, radius: radius)),
      );
    }

    // Avant-pied — pression haute → rouge
    drawSpot(
      Offset(w * 0.5, h * 0.30),
      40,
      const Color(0xFFEB5757),
      0.90 * pressure,
    );
    // Milieu voûte — pression basse → bleu
    drawSpot(Offset(w * 0.38, h * 0.54), 20, _kAccent, 0.45 * pressure);
    // Talon — pression moyenne → orange
    drawSpot(
      Offset(w * 0.5, h * 0.78),
      30,
      const Color(0xFFF59E0B),
      0.80 * pressure,
    );

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _FootPainter old) => old.pressure != pressure;
}

// ─── Legend ───────────────────────────────────────────────────────────────────

class _LegendItem extends StatelessWidget {
  const _LegendItem({required this.color, required this.label});
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
        Text(
          label,
          style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 11),
        ),
      ],
    );
  }
}

// ─── Stat Card ────────────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.unit,
    required this.accentColor,
  });
  final IconData icon;
  final String label;
  final String value;
  final String unit;
  final Color accentColor;

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
              Icon(icon, size: 12, color: accentColor),
              const SizedBox(width: 5),
              Text(
                label,
                style: const TextStyle(color: _kTextSec, fontSize: 12),
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

// ─── Balance Card ─────────────────────────────────────────────────────────────

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({required this.leftPercent, required this.rightPercent});
  final double leftPercent;
  final double rightPercent;

  String get _status {
    final d = (leftPercent - 0.5).abs();
    if (d < 0.05) return 'Optimal';
    if (d < 0.10) return 'Acceptable';
    return 'Déséquilibré';
  }

  Color get _statusColor {
    final d = (leftPercent - 0.5).abs();
    if (d < 0.05) return _kSuccess;
    if (d < 0.10) return const Color(0xFFF59E0B);
    return const Color(0xFFEB5757);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: _cardShadow(),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Équilibre',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: _kPrimary,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _statusColor,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      _status,
                      style: TextStyle(
                        color: _statusColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(
              height: 10,
              child: LayoutBuilder(
                builder: (_, c) {
                  final lw = c.maxWidth * leftPercent;
                  return Stack(
                    children: [
                      Container(
                        color: const Color(0xFF7C3AED).withValues(alpha: 0.15),
                      ),
                      Container(
                        width: lw,
                        color: _kAccent.withValues(alpha: 0.25),
                      ),
                      Positioned(
                        left: c.maxWidth / 2 - 1,
                        child: Container(
                          width: 2,
                          height: 10,
                          color: Colors.white,
                        ),
                      ),
                      // Accent line proportional
                      Positioned(
                        left: lw - 2,
                        child: Container(
                          width: 4,
                          height: 10,
                          decoration: BoxDecoration(
                            color: _kAccent,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${(leftPercent * 100).toStringAsFixed(1)}%',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: _kAccent,
                    ),
                  ),
                  const Text(
                    'Gauche',
                    style: TextStyle(color: _kTextSec, fontSize: 12),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${(rightPercent * 100).toStringAsFixed(1)}%',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Color(0xFF7C3AED),
                    ),
                  ),
                  const Text(
                    'Droit',
                    style: TextStyle(color: _kTextSec, fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
