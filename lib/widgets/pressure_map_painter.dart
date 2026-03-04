import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/pressure_data.dart';

// ─────────────────────────────────────────────────────────────────────────────
// PressureMapPainter v3 — Forme anatomique avec orteils ovales séparés
//
// Inspiré de la silhouette référence : orteils ovales distincts, voûte
// plantaire prononcée, talon arrondi. Gradients BI dynamiques, pulsation
// hotspot, badges de pression.
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
    final double footW = footH * 0.38;
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
    // 1. Main body path (sole sans orteils)
    final Path bodyPath = _soleBodyPath(origin, w, h, isLeft);
    // 2. Toe ovals
    final List<_ToeOval> toes = _toeOvals(origin, w, h, isLeft);

    // Combined path = body + toes
    final Path fullPath = Path();
    fullPath.addPath(bodyPath, Offset.zero);
    for (final toe in toes) {
      fullPath.addOval(
        Rect.fromCenter(
          center: toe.center,
          width: toe.rx * 2,
          height: toe.ry * 2,
        ),
      );
    }

    // Clip pour que les gradients ne dépassent pas du pied
    canvas.save();
    canvas.clipPath(fullPath);

    // Fond subtil du pied
    final Paint bgPaint =
        Paint()
          ..color =
              isDark
                  ? Colors.white.withValues(alpha: 0.03)
                  : Colors.black.withValues(alpha: 0.02);
    canvas.drawRect(
      Rect.fromLTWH(origin.dx - 10, origin.dy - 20, w + 20, h + 40),
      bgPaint,
    );

    // Dessiner les 4 zones de pression
    final List<_Zone> zones = _zonesForFoot(origin, w, h, pressure, isLeft);
    for (final zone in zones) {
      _drawPressureGlow(canvas, zone);
    }

    canvas.restore();

    // Contour du body
    final Paint outlinePaint =
        Paint()
          ..color =
              isDark
                  ? Colors.white.withValues(alpha: 0.18)
                  : Colors.black.withValues(alpha: 0.12)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(bodyPath, outlinePaint);

    // Contour et fill subtil des orteils
    for (final toe in toes) {
      final Rect ovalRect = Rect.fromCenter(
        center: toe.center,
        width: toe.rx * 2,
        height: toe.ry * 2,
      );

      // Fill léger
      final Paint toeFill =
          Paint()
            ..color =
                isDark
                    ? Colors.white.withValues(alpha: 0.02)
                    : Colors.black.withValues(alpha: 0.01);
      canvas.drawOval(ovalRect, toeFill);

      // Contour
      canvas.drawOval(ovalRect, outlinePaint);
    }

    // Labels hotspot
    if (showHotspotLabels) {
      for (final zone in zones) {
        if (zone.value >= kHotspotThreshold) {
          _drawHotspotBadge(canvas, zone);
        }
      }
    }
  }

  // ── Corps du pied (sole) — sans orteils ──────────────────────────────────

  Path _soleBodyPath(Offset o, double w, double h, bool isLeft) {
    final Path path = Path();

    // Points de référence verticaux
    final double toeBaseY = h * 0.18; // Où les orteils se connectent
    final double ballY = h * 0.24;
    final double archTopY = h * 0.40;
    final double archBottomY = h * 0.64;
    final double heelTopY = h * 0.80;
    final double heelBottomY = h * 0.98;

    // Points latéraux
    final double innerX = isLeft ? w * 0.88 : w * 0.12;
    final double outerX = isLeft ? w * 0.12 : w * 0.88;

    // ── Haut du pied (base des orteils — courbe convexe) ─────────────────
    final double leftEdge = isLeft ? outerX : w * 0.12;
    final double rightEdge = isLeft ? w * 0.88 : outerX;

    path.moveTo(o.dx + leftEdge, o.dy + toeBaseY);

    // Courbe du haut (métatarses) — légèrement convexe
    path.cubicTo(
      o.dx + w * 0.35,
      o.dy + toeBaseY - h * 0.015,
      o.dx + w * 0.65,
      o.dy + toeBaseY - h * 0.015,
      o.dx + rightEdge,
      o.dy + toeBaseY,
    );

    // ── Bord externe (du petit orteil au talon) ──────────────────────────
    path.cubicTo(
      o.dx + outerX + (isLeft ? -w * 0.04 : w * 0.04),
      o.dy + ballY + h * 0.04,
      o.dx + outerX + (isLeft ? -w * 0.01 : w * 0.01),
      o.dy + archTopY,
      o.dx + outerX,
      o.dy + archTopY + h * 0.02,
    );

    path.cubicTo(
      o.dx + outerX + (isLeft ? w * 0.01 : -w * 0.01),
      o.dy + archBottomY - h * 0.06,
      o.dx + outerX + (isLeft ? w * 0.01 : -w * 0.01),
      o.dy + archBottomY + h * 0.04,
      o.dx + (isLeft ? w * 0.16 : w * 0.84),
      o.dy + heelTopY,
    );

    // ── Talon arrondi ────────────────────────────────────────────────────
    final double heelCX = w * 0.50;
    final double heelR = w * 0.34;

    path.cubicTo(
      o.dx + (isLeft ? heelCX + heelR * 0.7 : heelCX - heelR * 0.7),
      o.dy + heelTopY + h * 0.04,
      o.dx + (isLeft ? heelCX + heelR * 0.5 : heelCX - heelR * 0.5),
      o.dy + heelBottomY,
      o.dx + heelCX,
      o.dy + heelBottomY,
    );

    path.cubicTo(
      o.dx + (isLeft ? heelCX - heelR * 0.5 : heelCX + heelR * 0.5),
      o.dy + heelBottomY,
      o.dx + (isLeft ? heelCX - heelR * 0.7 : heelCX + heelR * 0.7),
      o.dy + heelTopY + h * 0.04,
      o.dx + (isLeft ? w * 0.84 : w * 0.16),
      o.dy + heelTopY,
    );

    // ── Voûte plantaire (concave côté interne) ───────────────────────────
    path.cubicTo(
      o.dx + innerX + (isLeft ? -w * 0.12 : w * 0.12),
      o.dy + archBottomY + h * 0.02,
      o.dx + innerX + (isLeft ? -w * 0.18 : w * 0.18),
      o.dy + archTopY + h * 0.08,
      o.dx + innerX + (isLeft ? -w * 0.06 : w * 0.06),
      o.dy + archTopY - h * 0.02,
    );

    // ── Remontée vers la base des orteils côté interne ───────────────────
    path.cubicTo(
      o.dx + innerX + (isLeft ? -w * 0.01 : w * 0.01),
      o.dy + ballY + h * 0.04,
      o.dx + innerX + (isLeft ? w * 0.02 : -w * 0.02),
      o.dy + ballY - h * 0.02,
      o.dx + leftEdge,
      o.dy + toeBaseY,
    );

    path.close();
    return path;
  }

  // ── Orteils ovales séparés ─────────────────────────────────────────────

  List<_ToeOval> _toeOvals(Offset o, double w, double h, bool isLeft) {
    // Pied droit : gros orteil à gauche (interne), petit à droite
    // Pied gauche : miroir

    // Positions normalisées pour pied droit
    final List<_ToeSpec> specs = [
      // Gros orteil — plus gros, plus bas (plus haut en y = plus haut visuellement)
      _ToeSpec(cx: 0.22, cy: 0.07, rx: 0.10, ry: 0.055),
      // 2ème orteil — un peu plus haut que le gros
      _ToeSpec(cx: 0.38, cy: 0.035, rx: 0.065, ry: 0.04),
      // 3ème orteil
      _ToeSpec(cx: 0.52, cy: 0.04, rx: 0.058, ry: 0.035),
      // 4ème orteil
      _ToeSpec(cx: 0.64, cy: 0.055, rx: 0.052, ry: 0.032),
      // Petit orteil — le plus petit et le plus bas
      _ToeSpec(cx: 0.75, cy: 0.08, rx: 0.048, ry: 0.028),
    ];

    return specs.map((s) {
      final double cx = isLeft ? (1.0 - s.cx) : s.cx;
      return _ToeOval(
        center: Offset(o.dx + cx * w, o.dy + s.cy * h),
        rx: s.rx * w,
        ry: s.ry * h,
      );
    }).toList();
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
        center: Offset(o.dx + w * 0.45, o.dy + h * 0.07),
        radiusX: w * 0.38,
        radiusY: h * 0.06,
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
        center: Offset(o.dx + w * (isLeft ? 0.55 : 0.45), o.dy + h * 0.52),
        radiusX: w * 0.28,
        radiusY: h * 0.10,
        value: p.midfoot,
      ),
      _Zone(
        name: 'Talon',
        center: Offset(o.dx + w * 0.50, o.dy + h * 0.86),
        radiusX: w * 0.30,
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

    // 3 couches de glow pour un rendu organique
    for (int layer = 0; layer < 3; layer++) {
      final double spread = 1.0 + layer * 0.4;
      final double opacity = (0.55 - layer * 0.15).clamp(0.05, 0.65);

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
                color.withValues(alpha: opacity * 0.35),
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
          ..color = _pressureColor(zone.value).withValues(alpha: alpha * 0.75);
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
                  ? Colors.white.withValues(alpha: 0.40)
                  : Colors.black.withValues(alpha: 0.22),
          fontSize: 13,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.5,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    tp.paint(canvas, Offset(pos.dx - tp.width / 2, pos.dy));
  }

  // ── Couleur BI interpolée — gradients CdC ──────────────────────────────

  Color _pressureColor(double v) {
    // CdC : vert → jaune → orange → rouge
    if (v <= 0.15) return const Color(0xFF10B981); // Émeraude (normal)
    if (v <= 0.25) {
      final double t = (v - 0.15) / 0.10;
      return Color.lerp(
        const Color(0xFF10B981),
        const Color(0xFFFBBF24), // Ambre doré
        t,
      )!;
    }
    if (v <= 0.35) {
      final double t = (v - 0.25) / 0.10;
      return Color.lerp(
        const Color(0xFFFBBF24),
        const Color(0xFFF97316), // Orange vibrant
        t,
      )!;
    }
    if (v <= 0.50) {
      final double t = (v - 0.35) / 0.15;
      return Color.lerp(
        const Color(0xFFF97316),
        const Color(0xFFEF4444), // Rouge signal
        t,
      )!;
    }
    return const Color(0xFFEF4444);
  }

  @override
  bool shouldRepaint(covariant _PressureMapPainter old) {
    return old.animValue != animValue ||
        old.leftPressure != leftPressure ||
        old.rightPressure != rightPressure ||
        old.isDark != isDark;
  }
}

// ── Data Structures ─────────────────────────────────────────────────────────

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

class _ToeSpec {
  const _ToeSpec({
    required this.cx,
    required this.cy,
    required this.rx,
    required this.ry,
  });
  final double cx, cy, rx, ry;
}

class _ToeOval {
  const _ToeOval({required this.center, required this.rx, required this.ry});
  final Offset center;
  final double rx, ry;
}
