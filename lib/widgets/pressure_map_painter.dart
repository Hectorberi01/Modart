import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../models/pressure_data.dart';

// ─────────────────────────────────────────────────────────────────────────────
// PressureMapPainter v2 — Forme anatomique réaliste
//
// Contours de pieds dessinés avec des courbes cubiques de Bézier fidèles
// à l'anatomie (voûte plantaire, orteils arrondis, talon ovale).
// 4 zones/pied, RadialGradient dynamique BI, animation pulsation hotspot.
// ─────────────────────────────────────────────────────────────────────────────

/// Seuil à partir duquel une zone est "hotspot".
const double kHotspotThreshold = 0.40;

class PressureMapWidget extends StatefulWidget {
  const PressureMapWidget({
    super.key,
    required this.leftPressure,
    required this.rightPressure,
    this.showHotspotLabels = true,
    this.height = 400,
  });

  final PressureData leftPressure;
  final PressureData rightPressure;
  final bool showHotspotLabels;
  final double height;

  @override
  State<PressureMapWidget> createState() => _PressureMapWidgetState();
}

class _PressureMapWidgetState extends State<PressureMapWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
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

    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return CustomPaint(
            painter: _PressureMapPainter(
              leftPressure: widget.leftPressure,
              rightPressure: widget.rightPressure,
              showHotspotLabels: widget.showHotspotLabels,
              animValue: _controller.value,
              isDark: isDark,
            ),
            size: Size(double.infinity, widget.height),
          );
        },
      ),
    );
  }
}

// ─── Painter ────────────────────────────────────────────────────────────────

class _PressureMapPainter extends CustomPainter {
  _PressureMapPainter({
    required this.leftPressure,
    required this.rightPressure,
    required this.showHotspotLabels,
    required this.animValue,
    required this.isDark,
  });

  final PressureData leftPressure;
  final PressureData rightPressure;
  final bool showHotspotLabels;
  final double animValue;
  final bool isDark;

  @override
  void paint(Canvas canvas, Size size) {
    final double footH = size.height * 0.92;
    final double footW = footH * 0.38; // Ratio anatomique ~38%
    final double gap = size.width * 0.04;

    final Offset leftOrigin = Offset(
      size.width / 2 - footW - gap,
      (size.height - footH) / 2,
    );
    final Offset rightOrigin = Offset(
      size.width / 2 + gap,
      (size.height - footH) / 2,
    );

    _drawFoot(canvas, leftOrigin, footW, footH, leftPressure, isLeft: true);
    _drawFoot(canvas, rightOrigin, footW, footH, rightPressure, isLeft: false);

    // Labels G / D
    _drawFootLabel(
      canvas,
      Offset(leftOrigin.dx + footW / 2, leftOrigin.dy - 14),
      'G',
    );
    _drawFootLabel(
      canvas,
      Offset(rightOrigin.dx + footW / 2, rightOrigin.dy - 14),
      'D',
    );
  }

  // ── Pied complet : contour + zones de pression ──────────────────────────

  void _drawFoot(
    Canvas canvas,
    Offset origin,
    double w,
    double h,
    PressureData pressure, {
    required bool isLeft,
  }) {
    final Path footPath = _anatomicalFootPath(origin, w, h, isLeft);

    // Clip pour que les gradients ne dépassent pas du pied
    canvas.save();
    canvas.clipPath(footPath);

    // Fond subtil du pied
    final Paint bgPaint =
        Paint()
          ..color =
              isDark
                  ? Colors.white.withValues(alpha: 0.03)
                  : Colors.black.withValues(alpha: 0.02);
    canvas.drawPath(footPath, bgPaint);

    // Dessiner les 4 zones de pression
    final List<_Zone> zones = _zonesForFoot(origin, w, h, pressure, isLeft);
    for (final zone in zones) {
      _drawPressureGlow(canvas, zone);
    }

    canvas.restore();

    // Contour du pied par-dessus
    final Paint outlinePaint =
        Paint()
          ..color =
              isDark
                  ? Colors.white.withValues(alpha: 0.12)
                  : Colors.black.withValues(alpha: 0.08)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(footPath, outlinePaint);

    // Labels hotspot
    if (showHotspotLabels) {
      for (final zone in zones) {
        if (zone.value >= kHotspotThreshold) {
          _drawHotspotBadge(canvas, zone);
        }
      }
    }
  }

  // ── Dessin anatomique réaliste du pied ──────────────────────────────────

  Path _anatomicalFootPath(Offset o, double w, double h, bool isLeft) {
    // On dessine le pied droit puis on flip pour le gauche.
    // Points clés anatomiques (proportions normalisées) :
    //   - Gros orteil proéminent, orteils dégressifs
    //   - Voûte plantaire concave côté interne
    //   - Bord externe convexe
    //   - Talon ovale

    final Path path = Path();

    // Coordonnées normalisées du pied droit (x: 0→w, y: 0→h)
    // Le gros orteil est côté "interne" (gauche pour un pied droit)

    // Points de référence
    final double toeY = h * 0.00;
    final double ballY = h * 0.22;
    final double archTopY = h * 0.38;
    final double archBottomY = h * 0.62;
    final double heelTopY = h * 0.78;
    final double heelBottomY = h * 1.00;

    // Côté interne = gauche pour pied droit
    final double innerX = w * 0.10;
    // Côté externe = droite pour pied droit
    final double outerX = w * 0.90;

    // ── Orteils (haut du pied) ──────────────────────────────────────────

    // Orteils 2-5 (de l'intérieur vers l'extérieur, de plus en plus courts)
    final List<Offset> toeTips = [
      Offset(w * 0.22, toeY), // Gros orteil
      Offset(w * 0.40, toeY + h * 0.01), // 2ème orteil
      Offset(w * 0.55, toeY + h * 0.03), // 3ème
      Offset(w * 0.67, toeY + h * 0.06), // 4ème
      Offset(w * 0.77, toeY + h * 0.10), // Petit orteil
    ];

    // Flipper horizontal pour le pied gauche
    List<Offset> tips = toeTips;
    if (isLeft) {
      tips = toeTips.map((p) => Offset(w - p.dx, p.dy)).toList();
    }

    final double archInnerX = isLeft ? outerX : innerX;
    final double archOuterX = isLeft ? innerX : outerX;

    // Commencer par le gros orteil
    path.moveTo(o.dx + tips[0].dx, o.dy + tips[0].dy);

    // Arc doux entre chaque orteil
    for (int i = 0; i < tips.length - 1; i++) {
      final Offset current = tips[i];
      final Offset next = tips[i + 1];
      final double midX = (current.dx + next.dx) / 2;
      // Creux entre les orteils
      final double valleyY = math.max(current.dy, next.dy) + h * 0.025;

      path.quadraticBezierTo(
        o.dx + midX,
        o.dy + valleyY,
        o.dx + next.dx,
        o.dy + next.dy,
      );
    }

    // ── Bord externe (du petit orteil au talon) ─────────────────────────
    path.cubicTo(
      o.dx + archOuterX + (isLeft ? -w * 0.05 : w * 0.05),
      o.dy + ballY - h * 0.02,
      o.dx + archOuterX + (isLeft ? -w * 0.02 : w * 0.02),
      o.dy + ballY + h * 0.05,
      o.dx + archOuterX,
      o.dy + archTopY,
    );

    // Bord externe : courbe douce vers le bas
    path.cubicTo(
      o.dx + archOuterX + (isLeft ? w * 0.02 : -w * 0.02),
      o.dy + archBottomY - h * 0.08,
      o.dx + archOuterX + (isLeft ? w * 0.02 : -w * 0.02),
      o.dy + archBottomY + h * 0.05,
      o.dx + (isLeft ? w * 0.82 : w * 0.18) + (isLeft ? -w * 0.02 : w * 0.02),
      o.dy + heelTopY,
    );

    // ── Talon (ovale arrondi) ───────────────────────────────────────────
    final double heelCenterX = w * 0.50;
    final double heelW = w * 0.36;

    path.cubicTo(
      o.dx + (isLeft ? heelCenterX + heelW * 0.8 : heelCenterX - heelW * 0.8),
      o.dy + heelTopY + h * 0.04,
      o.dx + (isLeft ? heelCenterX + heelW * 0.6 : heelCenterX - heelW * 0.6),
      o.dy + heelBottomY - h * 0.01,
      o.dx + heelCenterX,
      o.dy + heelBottomY - h * 0.005,
    );

    path.cubicTo(
      o.dx + (isLeft ? heelCenterX - heelW * 0.6 : heelCenterX + heelW * 0.6),
      o.dy + heelBottomY - h * 0.01,
      o.dx + (isLeft ? heelCenterX - heelW * 0.8 : heelCenterX + heelW * 0.8),
      o.dy + heelTopY + h * 0.04,
      o.dx + (isLeft ? w * 0.18 : w * 0.82) + (isLeft ? w * 0.02 : -w * 0.02),
      o.dy + heelTopY,
    );

    // ── Voûte plantaire (côté interne — courbe concave) ─────────────────
    path.cubicTo(
      o.dx + archInnerX + (isLeft ? w * 0.15 : -w * 0.15),
      o.dy + archBottomY + h * 0.02,
      o.dx + archInnerX + (isLeft ? w * 0.20 : -w * 0.20),
      o.dy + archTopY + h * 0.10,
      o.dx + archInnerX + (isLeft ? w * 0.08 : -w * 0.08),
      o.dy + archTopY - h * 0.02,
    );

    // ── Remontée vers les orteils côté interne ──────────────────────────
    path.cubicTo(
      o.dx + archInnerX + (isLeft ? w * 0.02 : -w * 0.02),
      o.dy + ballY + h * 0.05,
      o.dx + archInnerX + (isLeft ? -w * 0.02 : w * 0.02),
      o.dy + ballY - h * 0.04,
      o.dx + tips[0].dx,
      o.dy + tips[0].dy,
    );

    path.close();
    return path;
  }

  // ── Zones de pression par pied ──────────────────────────────────────────

  List<_Zone> _zonesForFoot(
    Offset o,
    double w,
    double h,
    PressureData p,
    bool isLeft,
  ) {
    return [
      _Zone(
        name: 'Orteils',
        center: Offset(o.dx + w * 0.45, o.dy + h * 0.10),
        radiusX: w * 0.35,
        radiusY: h * 0.08,
        value: p.toe,
      ),
      _Zone(
        name: 'Avant-pied',
        center: Offset(o.dx + w * 0.48, o.dy + h * 0.28),
        radiusX: w * 0.40,
        radiusY: h * 0.10,
        value: p.forefoot,
      ),
      _Zone(
        name: 'Médio-pied',
        center: Offset(o.dx + w * (isLeft ? 0.55 : 0.45), o.dy + h * 0.50),
        radiusX: w * 0.28,
        radiusY: h * 0.10,
        value: p.midfoot,
      ),
      _Zone(
        name: 'Talon',
        center: Offset(o.dx + w * 0.50, o.dy + h * 0.84),
        radiusX: w * 0.32,
        radiusY: h * 0.10,
        value: p.heel,
      ),
    ];
  }

  // ── Glow de pression par zone ───────────────────────────────────────────

  void _drawPressureGlow(Canvas canvas, _Zone zone) {
    final Color color = _pressureColor(zone.value);
    double rx = zone.radiusX;
    double ry = zone.radiusY;

    // Pulsation pour les hotspots
    if (zone.value >= kHotspotThreshold) {
      final double pulse = 0.92 + 0.08 * math.sin(animValue * 2 * math.pi);
      rx *= pulse;
      ry *= pulse;
    }

    // 3 couches de glow pour un rendu plus organique
    for (int layer = 0; layer < 3; layer++) {
      final double spread = 1.0 + layer * 0.4;
      final double opacity = (0.5 - layer * 0.15).clamp(0.05, 0.6);

      final Rect rect = Rect.fromCenter(
        center: zone.center,
        width: rx * 2 * spread,
        height: ry * 2 * spread,
      );

      final Paint paint =
          Paint()
            ..shader = RadialGradient(
              colors: [
                color.withValues(alpha: opacity),
                color.withValues(alpha: opacity * 0.4),
                color.withValues(alpha: 0),
              ],
              stops: const [0.0, 0.5, 1.0],
            ).createShader(rect);

      canvas.drawOval(rect, paint);
    }
  }

  // ── Badge hotspot ───────────────────────────────────────────────────────

  void _drawHotspotBadge(Canvas canvas, _Zone zone) {
    final double alpha = 0.6 + 0.4 * math.sin(animValue * 2 * math.pi);
    final String label = '${(zone.value * 100).toInt()}%';

    // Fond du badge
    final double badgeW = 36;
    final double badgeH = 18;
    final Rect badgeRect = Rect.fromCenter(
      center: zone.center,
      width: badgeW,
      height: badgeH,
    );
    final RRect badgeRRect = RRect.fromRectAndRadius(
      badgeRect,
      const Radius.circular(9),
    );

    final Paint badgeBgPaint =
        Paint()
          ..color = _pressureColor(zone.value).withValues(alpha: alpha * 0.7);
    canvas.drawRRect(badgeRRect, badgeBgPaint);

    // Texte
    final TextPainter tp = TextPainter(
      text: TextSpan(
        text: label,
        style: TextStyle(
          color: Colors.white.withValues(alpha: alpha),
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.3,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    tp.paint(
      canvas,
      Offset(zone.center.dx - tp.width / 2, zone.center.dy - tp.height / 2),
    );
  }

  // ── Label G / D ─────────────────────────────────────────────────────────

  void _drawFootLabel(Canvas canvas, Offset pos, String text) {
    final TextPainter tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color:
              isDark
                  ? Colors.white.withValues(alpha: 0.35)
                  : Colors.black.withValues(alpha: 0.2),
          fontSize: 13,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.5,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    tp.paint(canvas, Offset(pos.dx - tp.width / 2, pos.dy));
  }

  // ── Couleur BI interpolée ───────────────────────────────────────────────

  Color _pressureColor(double v) {
    if (v <= 0.15) return const Color(0xFF22C55E); // Vert vif
    if (v <= 0.25) {
      final double t = (v - 0.15) / 0.10;
      return Color.lerp(const Color(0xFF22C55E), const Color(0xFFFACC15), t)!;
    }
    if (v <= 0.35) {
      final double t = (v - 0.25) / 0.10;
      return Color.lerp(const Color(0xFFFACC15), const Color(0xFFF97316), t)!;
    }
    if (v <= 0.50) {
      final double t = (v - 0.35) / 0.15;
      return Color.lerp(const Color(0xFFF97316), const Color(0xFFEF4444), t)!;
    }
    return const Color(0xFFEF4444); // Rouge vif
  }

  @override
  bool shouldRepaint(covariant _PressureMapPainter old) {
    return old.animValue != animValue ||
        old.leftPressure != leftPressure ||
        old.rightPressure != rightPressure ||
        old.isDark != isDark;
  }
}

// ── Zone de pression ────────────────────────────────────────────────────────

class _Zone {
  const _Zone({
    required this.name,
    required this.center,
    required this.radiusX,
    required this.radiusY,
    required this.value,
  });

  final String name;
  final Offset center;
  final double radiusX;
  final double radiusY;
  final double value;
}
