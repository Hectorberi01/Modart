import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

// ─────────────────────────────────────────────────────────────────────────────
// SegmentBadge — Badge coloré de segment de marche
//
// 4 états : Arrêt (gris) / Lent (bleu) / Normal (vert) / Rapide (orange).
// Transition animée entre les états.
// ─────────────────────────────────────────────────────────────────────────────

/// Type de segment de marche.
enum WalkSegment { stopped, slow, normal, fast }

class SegmentBadge extends StatelessWidget {
  const SegmentBadge({super.key, required this.segment, this.compact = false});

  /// Segment de marche actuel.
  final WalkSegment segment;

  /// Mode compact (uniquement le point + label court).
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final _SegmentStyle style = _styleForSegment(segment);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 12,
        vertical: compact ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: style.color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(compact ? 8 : 12),
        border: Border.all(color: style.color.withValues(alpha: 0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Point indicateur
          AnimatedContainer(
            duration: const Duration(milliseconds: 400),
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: style.color,
            ),
          ),
          const SizedBox(width: 6),
          // Label
          Text(
            style.label,
            style: TextStyle(
              color: style.color,
              fontSize: compact ? 11 : 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  _SegmentStyle _styleForSegment(WalkSegment segment) {
    return switch (segment) {
      WalkSegment.stopped => const _SegmentStyle(
        label: 'Arrêt',
        color: Color(0xFF6B7280),
      ),
      WalkSegment.slow => const _SegmentStyle(
        label: 'Lent',
        color: Color(0xFF3B82F6),
      ),
      WalkSegment.normal => _SegmentStyle(
        label: 'Normal',
        color: SmartSoleColors.biNormal,
      ),
      WalkSegment.fast => const _SegmentStyle(
        label: 'Rapide',
        color: Color(0xFFF97316),
      ),
    };
  }
}

class _SegmentStyle {
  const _SegmentStyle({required this.label, required this.color});

  final String label;
  final Color color;
}
