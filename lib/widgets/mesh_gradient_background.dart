import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

// ─────────────────────────────────────────────────────────────────────────────
// MeshGradientBackground v2 — Fond dynamique organique
//
// 4 orbes de couleur se déplacent lentement avec des trajectoires sinusoïdales
// décalées. Les couleurs changent selon le BIState. Rendu optimisé avec
// RepaintBoundary et palette plus subtile.
// ─────────────────────────────────────────────────────────────────────────────

class MeshGradientBackground extends StatefulWidget {
  const MeshGradientBackground({
    super.key,
    required this.child,
    this.biState = BIState.neutral,
  });

  final Widget child;
  final BIState biState;

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
      duration: const Duration(seconds: 20),
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
    final Color baseBg =
        isDark ? SmartSoleColors.darkBg : SmartSoleColors.lightBg;

    return Stack(
      children: [
        // Fond plein
        Container(color: baseBg),

        // Orbes animées
        RepaintBoundary(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              return CustomPaint(
                painter: _MeshPainter(
                  progress: _controller.value,
                  biState: widget.biState,
                  isDark: isDark,
                ),
                size: Size.infinite,
              );
            },
          ),
        ),

        // Noise overlay subtil pour la texture
        if (isDark)
          Positioned.fill(
            child: IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.center,
                    radius: 1.2,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.3),
                    ],
                  ),
                ),
              ),
            ),
          ),

        // Contenu
        widget.child,
      ],
    );
  }
}

// ─── Mesh Painter ───────────────────────────────────────────────────────────

class _MeshPainter extends CustomPainter {
  _MeshPainter({
    required this.progress,
    required this.biState,
    required this.isDark,
  });

  final double progress;
  final BIState biState;
  final bool isDark;

  @override
  void paint(Canvas canvas, Size size) {
    final List<_OrbConfig> orbs = _orbsForState(biState);

    for (int i = 0; i < orbs.length; i++) {
      final _OrbConfig orb = orbs[i];

      // Trajectoire sinusoïdale avec décalage par orbe
      final double phase = progress * 2 * math.pi + orb.phaseOffset;
      final double dx = math.sin(phase * orb.speedX) * size.width * orb.rangeX;
      final double dy = math.cos(phase * orb.speedY) * size.height * orb.rangeY;

      final Offset center = Offset(
        size.width * orb.baseX + dx,
        size.height * orb.baseY + dy,
      );

      final double radius = size.width * orb.radius;

      final Paint paint =
          Paint()
            ..shader = RadialGradient(
              colors: [
                orb.color.withValues(
                  alpha: isDark ? orb.opacity : orb.opacity * 0.4,
                ),
                orb.color.withValues(alpha: 0),
              ],
              stops: const [0.0, 1.0],
            ).createShader(Rect.fromCircle(center: center, radius: radius));

      canvas.drawCircle(center, radius, paint);
    }
  }

  List<_OrbConfig> _orbsForState(BIState state) {
    return switch (state) {
      BIState.normal => [
        _OrbConfig(
          baseX: 0.2,
          baseY: 0.3,
          radius: 0.45,
          opacity: 0.06,
          color: SmartSoleColors.biNormal,
          phaseOffset: 0,
          speedX: 1.0,
          speedY: 0.7,
          rangeX: 0.15,
          rangeY: 0.12,
        ),
        _OrbConfig(
          baseX: 0.8,
          baseY: 0.6,
          radius: 0.38,
          opacity: 0.04,
          color: SmartSoleColors.biTeal,
          phaseOffset: 1.2,
          speedX: 0.8,
          speedY: 1.1,
          rangeX: 0.12,
          rangeY: 0.10,
        ),
        _OrbConfig(
          baseX: 0.5,
          baseY: 0.8,
          radius: 0.30,
          opacity: 0.03,
          color: SmartSoleColors.biNavy,
          phaseOffset: 2.5,
          speedX: 0.6,
          speedY: 0.9,
          rangeX: 0.10,
          rangeY: 0.08,
        ),
      ],
      BIState.warning => [
        _OrbConfig(
          baseX: 0.3,
          baseY: 0.4,
          radius: 0.50,
          opacity: 0.07,
          color: SmartSoleColors.biWarning,
          phaseOffset: 0,
          speedX: 1.2,
          speedY: 0.8,
          rangeX: 0.14,
          rangeY: 0.10,
        ),
        _OrbConfig(
          baseX: 0.7,
          baseY: 0.6,
          radius: 0.35,
          opacity: 0.04,
          color: SmartSoleColors.biNormal,
          phaseOffset: 1.8,
          speedX: 0.9,
          speedY: 1.0,
          rangeX: 0.10,
          rangeY: 0.12,
        ),
      ],
      BIState.alert => [
        _OrbConfig(
          baseX: 0.5,
          baseY: 0.5,
          radius: 0.55,
          opacity: 0.08,
          color: SmartSoleColors.biAlert,
          phaseOffset: 0,
          speedX: 1.5,
          speedY: 1.2,
          rangeX: 0.12,
          rangeY: 0.10,
        ),
        _OrbConfig(
          baseX: 0.2,
          baseY: 0.7,
          radius: 0.30,
          opacity: 0.05,
          color: SmartSoleColors.biWarning,
          phaseOffset: 2.0,
          speedX: 0.7,
          speedY: 0.9,
          rangeX: 0.08,
          rangeY: 0.06,
        ),
      ],
      BIState.teal => [
        _OrbConfig(
          baseX: 0.3,
          baseY: 0.25,
          radius: 0.50,
          opacity: 0.05,
          color: SmartSoleColors.biTeal,
          phaseOffset: 0,
          speedX: 0.8,
          speedY: 0.6,
          rangeX: 0.18,
          rangeY: 0.14,
        ),
        _OrbConfig(
          baseX: 0.7,
          baseY: 0.7,
          radius: 0.40,
          opacity: 0.04,
          color: SmartSoleColors.biNormal,
          phaseOffset: 1.5,
          speedX: 0.7,
          speedY: 0.9,
          rangeX: 0.12,
          rangeY: 0.10,
        ),
        _OrbConfig(
          baseX: 0.15,
          baseY: 0.85,
          radius: 0.25,
          opacity: 0.03,
          color: SmartSoleColors.biNavy,
          phaseOffset: 3.0,
          speedX: 1.0,
          speedY: 0.5,
          rangeX: 0.10,
          rangeY: 0.08,
        ),
      ],
      BIState.navy => [
        _OrbConfig(
          baseX: 0.4,
          baseY: 0.3,
          radius: 0.45,
          opacity: 0.06,
          color: SmartSoleColors.biNavy,
          phaseOffset: 0,
          speedX: 0.7,
          speedY: 0.5,
          rangeX: 0.15,
          rangeY: 0.12,
        ),
        _OrbConfig(
          baseX: 0.7,
          baseY: 0.7,
          radius: 0.35,
          opacity: 0.04,
          color: SmartSoleColors.biTeal,
          phaseOffset: 2.0,
          speedX: 0.9,
          speedY: 0.8,
          rangeX: 0.10,
          rangeY: 0.10,
        ),
      ],
      BIState.neutral => [
        _OrbConfig(
          baseX: 0.25,
          baseY: 0.35,
          radius: 0.45,
          opacity: 0.035,
          color: SmartSoleColors.biTeal,
          phaseOffset: 0,
          speedX: 0.5,
          speedY: 0.4,
          rangeX: 0.15,
          rangeY: 0.12,
        ),
        _OrbConfig(
          baseX: 0.75,
          baseY: 0.65,
          radius: 0.35,
          opacity: 0.025,
          color: SmartSoleColors.biNavy,
          phaseOffset: 1.8,
          speedX: 0.6,
          speedY: 0.5,
          rangeX: 0.10,
          rangeY: 0.10,
        ),
      ],
    };
  }

  @override
  bool shouldRepaint(covariant _MeshPainter old) {
    return old.progress != progress ||
        old.biState != biState ||
        old.isDark != isDark;
  }
}

// ── Config d'orbe ───────────────────────────────────────────────────────────

class _OrbConfig {
  const _OrbConfig({
    required this.baseX,
    required this.baseY,
    required this.radius,
    required this.opacity,
    required this.color,
    required this.phaseOffset,
    required this.speedX,
    required this.speedY,
    required this.rangeX,
    required this.rangeY,
  });

  final double baseX;
  final double baseY;
  final double radius;
  final double opacity;
  final Color color;
  final double phaseOffset;
  final double speedX;
  final double speedY;
  final double rangeX;
  final double rangeY;
}
