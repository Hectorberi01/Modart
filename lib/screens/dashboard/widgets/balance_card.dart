import 'package:flutter/material.dart';
import '../dashboard_constants.dart';

class BalanceCard extends StatelessWidget {
  const BalanceCard({
    super.key,
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
    if (diff < 0.05) return kDashSuccess;
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
        boxShadow: cardShadow(),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.balance, size: 14, color: kDashTextSec),
                  SizedBox(width: 6),
                  Text('Poids & équilibre',
                      style: TextStyle(color: kDashTextSec, fontSize: 13)),
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
                  color: kDashPrimary,
                  height: 1,
                  letterSpacing: -1,
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(bottom: 5, left: 5),
                child: Text('kg',
                    style: TextStyle(color: kDashTextSec, fontSize: 16)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _BalanceRow(label: 'Gauche', percent: leftPercent, color: kDashAccent),
          const SizedBox(height: 10),
          _BalanceRow(
              label: 'Droite',
              percent: rightPercent,
              color: const Color(0xFF7C3AED)),
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
            Text(label, style: const TextStyle(color: kDashTextSec, fontSize: 12)),
            Text('${(percent * 100).toInt()}%',
                style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                    color: kDashPrimary)),
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
