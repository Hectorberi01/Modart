import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

// ─────────────────────────────────────────────────────────────────────────────
// SegmentBadge v2 — Badge de segment de marche
//
// Icône contextuelle + label + animation pulsation pour "fast".
// ─────────────────────────────────────────────────────────────────────────────

enum WalkSegment { stopped, slow, normal, fast }

class SegmentBadge extends StatelessWidget {
  const SegmentBadge({super.key, required this.segment});

  final WalkSegment segment;

  @override
  Widget build(BuildContext context) {
    final _SegmentStyle style = _styleFor(segment);
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedContainer(
      duration: SmartSoleDesign.animNormal,
      curve: SmartSoleDesign.animCurve,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: style.color.withValues(alpha: isDark ? 0.12 : 0.08),
        borderRadius: BorderRadius.circular(SmartSoleDesign.borderRadiusXs),
        border: Border.all(
          color: style.color.withValues(alpha: 0.25),
          width: 0.8,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(style.icon, size: 14, color: style.color),
          const SizedBox(width: 6),
          Text(
            style.label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: style.color,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  _SegmentStyle _styleFor(WalkSegment segment) {
    return switch (segment) {
      WalkSegment.stopped => _SegmentStyle(
        label: 'Arrêt',
        icon: Icons.pause_circle_outline,
        color: SmartSoleColors.textSecondaryDark,
      ),
      WalkSegment.slow => _SegmentStyle(
        label: 'Lent',
        icon: Icons.accessibility_new,
        color: SmartSoleColors.biTeal,
      ),
      WalkSegment.normal => _SegmentStyle(
        label: 'Normal',
        icon: Icons.directions_walk,
        color: SmartSoleColors.biNormal,
      ),
      WalkSegment.fast => _SegmentStyle(
        label: 'Rapide',
        icon: Icons.directions_run,
        color: SmartSoleColors.biWarning,
      ),
    };
  }
}

class _SegmentStyle {
  const _SegmentStyle({
    required this.label,
    required this.icon,
    required this.color,
  });

  final String label;
  final IconData icon;
  final Color color;
}
