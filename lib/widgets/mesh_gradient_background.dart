import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

// ─────────────────────────────────────────────────────────────────────────────
// MeshGradientBackground — Fond animé contextuel
//
// Plusieurs cercles de gradient superposés animés lentement (8–12s loop).
// La couleur dominante varie selon l'état BI (vert/ambre/rouge/teal).
// ─────────────────────────────────────────────────────────────────────────────

class MeshGradientBackground extends StatefulWidget {
  const MeshGradientBackground({
    super.key,
    required this.child,
    this.biState = BIState.neutral,
    this.animationDuration = const Duration(seconds: 10),
  });

  /// Widget enfant affiché par dessus le mesh gradient.
  final Widget child;

  /// État BI qui détermine la couleur dominante des gradients.
  final BIState biState;

  /// Durée du cycle d'animation.
  final Duration animationDuration;

  @override
  State<MeshGradientBackground> createState() => _MeshGradientBackgroundState();
}

class _MeshGradientBackgroundState extends State<MeshGradientBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.animationDuration,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          painter: _MeshGradientPainter(
            progress: _controller.value,
            biState: widget.biState,
            isDark: isDark,
          ),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

class _MeshGradientPainter extends CustomPainter {
  _MeshGradientPainter({
    required this.progress,
    required this.biState,
    required this.isDark,
  });

  final double progress;
  final BIState biState;
  final bool isDark;

  @override
  void paint(Canvas canvas, Size size) {
    // Fond de base
    final Paint bgPaint =
        Paint()
          ..color = isDark ? SmartSoleColors.darkBg : SmartSoleColors.lightBg;
    canvas.drawRect(Offset.zero & size, bgPaint);

    if (!isDark) {
      // En light mode, les gradients sont très subtils
      _drawGradientOrb(
        canvas,
        size,
        centerFactor: Offset(
          0.3 + 0.1 * math.sin(progress * 2 * math.pi),
          0.2 + 0.1 * math.cos(progress * 2 * math.pi),
        ),
        radius: size.width * 0.6,
        color: SmartSoleColors.colorForState(biState).withValues(alpha: 0.04),
      );
      return;
    }

    // En dark mode — 4 orbes de gradient animés
    final Color biColor = SmartSoleColors.colorForState(biState);
    final double t = progress * 2 * math.pi;

    // Orbe 1 — Grande, biColor dominant, bouge lentement
    _drawGradientOrb(
      canvas,
      size,
      centerFactor: Offset(
        0.2 + 0.15 * math.sin(t),
        0.3 + 0.1 * math.cos(t * 0.7),
      ),
      radius: size.width * 0.7,
      color: biColor.withValues(alpha: 0.12),
    );

    // Orbe 2 — Bleu nuit, mouvement inverse
    _drawGradientOrb(
      canvas,
      size,
      centerFactor: Offset(
        0.7 + 0.12 * math.cos(t * 0.8),
        0.6 + 0.15 * math.sin(t * 0.6),
      ),
      radius: size.width * 0.5,
      color: SmartSoleColors.meshBlue.withValues(alpha: 0.15),
    );

    // Orbe 3 — Violet pour la profondeur
    _drawGradientOrb(
      canvas,
      size,
      centerFactor: Offset(
        0.5 + 0.1 * math.sin(t * 1.2),
        0.15 + 0.08 * math.cos(t),
      ),
      radius: size.width * 0.4,
      color: SmartSoleColors.meshPurple.withValues(alpha: 0.1),
    );

    // Orbe 4 — Teal subtil en bas
    _drawGradientOrb(
      canvas,
      size,
      centerFactor: Offset(
        0.4 + 0.08 * math.cos(t * 0.5),
        0.85 + 0.05 * math.sin(t * 0.9),
      ),
      radius: size.width * 0.45,
      color: SmartSoleColors.meshTeal.withValues(alpha: 0.08),
    );
  }

  void _drawGradientOrb(
    Canvas canvas,
    Size size, {
    required Offset centerFactor,
    required double radius,
    required Color color,
  }) {
    final Offset center = Offset(
      size.width * centerFactor.dx,
      size.height * centerFactor.dy,
    );

    final Paint paint =
        Paint()
          ..shader = RadialGradient(
            colors: [color, color.withValues(alpha: 0)],
            stops: const [0.0, 1.0],
          ).createShader(Rect.fromCircle(center: center, radius: radius));

    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(covariant _MeshGradientPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.biState != biState ||
        oldDelegate.isDark != isDark;
  }
}
