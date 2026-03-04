import 'package:flutter/material.dart';
import '../dashboard_constants.dart';

class SmallMetricCard extends StatelessWidget {
  const SmallMetricCard({
    super.key,
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
        boxShadow: cardShadow(),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 12, color: kDashTextSec),
              const SizedBox(width: 5),
              Flexible(
                child: Text(label,
                    style: const TextStyle(color: kDashTextSec, fontSize: 12),
                    overflow: TextOverflow.ellipsis),
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
                    color: kDashPrimary,
                    height: 1,
                    letterSpacing: -0.5),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 4, left: 4),
                child: Text(unit,
                    style: const TextStyle(
                        color: kDashTextSec, fontSize: 13)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
