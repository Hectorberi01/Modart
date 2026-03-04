import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/pressure_data.dart';
import '../theme/app_theme.dart';

// ─────────────────────────────────────────────────────────────────────────────
// PressureMapPainter v5 — Forme anatomique fidèle à la référence
//
// La référence montre (vue plantaire, vu d'en bas) :
//   • Avant-pied (haut) : LARGE, bord extérieur très bombé
//   • Voûte (milieu interne) : concavité profonde en S
//   • Talon (bas) : arrondi, PLUS ÉTROIT que l'avant-pied
//   • Orteils : ovales SÉPARÉS du corps du pied, décroissants du gros au petit
//
// Gradients pression (CdC) : vert émeraude → ambre → orange → rouge profond
// ─────────────────────────────────────────────────────────────────────────────

const double kHotspotThreshold = 0.38;

// ── Widget conteneur ────────────────────────────────────────────────────────

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
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return RepaintBoundary(
      child: Stack(
        alignment: Alignment.center,
        children: [
          // L'image de référence demandée par l'utilisateur
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24.0),
            child: Image.asset(
              'assets/images/feet_reference.png',
              height: widget.height * 0.85,
              fit: BoxFit.contain,
              errorBuilder:
                  (context, error, stackTrace) => const Icon(
                    Icons.broken_image,
                    size: 100,
                    color: Colors.grey,
                  ),
            ),
          ),
          // Les hotspots overlay
          AnimatedBuilder(
            animation: _ctrl,
            builder:
                (_, __) => CustomPaint(
                  painter: _PressureMapPainter(
                    leftPressure: widget.leftPressure,
                    rightPressure: widget.rightPressure,
                    showHotspotLabels: widget.showHotspotLabels,
                    animValue: _ctrl.value,
                    isDark: isDark,
                  ),
                  size: Size(double.infinity, widget.height),
                ),
          ),
        ],
      ),
    );
  }
}

// ── Painter principal ────────────────────────────────────────────────────────

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
    // ── Proportions ────────────────────────────────────────────────────────
    const double widthRatio = 0.40; // rapport largeur/hauteur du pied
    final double footH = size.height * 0.88;
    final double footW = footH * widthRatio;
    final double gap = size.width * 0.05;

    // Origines (coin supérieur-gauche de la bounding box du CORPS du pied)
    // Les orteils débordent au-dessus de cette bounding box
    final double toeAreaH = footH * 0.14; // hauteur réservée aux orteils
    final double bodyH = footH - toeAreaH;

    final Offset leftBodyOrigin = Offset(
      size.width / 2 - footW - gap,
      (size.height - footH) / 2 + toeAreaH,
    );
    final Offset rightBodyOrigin = Offset(
      size.width / 2 + gap,
      (size.height - footH) / 2 + toeAreaH,
    );

    _drawFoot(
      canvas,
      leftBodyOrigin,
      footW,
      bodyH,
      leftPressure,
      toeAreaH: toeAreaH,
      isLeft: true,
    );
    _drawFoot(
      canvas,
      rightBodyOrigin,
      footW,
      bodyH,
      rightPressure,
      toeAreaH: toeAreaH,
      isLeft: false,
    );

    // Labels G / D
    _drawLabel(
      canvas,
      leftBodyOrigin.translate(footW / 2, -toeAreaH - 12),
      'G',
    );
    _drawLabel(
      canvas,
      rightBodyOrigin.translate(footW / 2, -toeAreaH - 12),
      'D',
    );
  }

  // ── Dessin d'un pied complet ─────────────────────────────────────────────

  void _drawFoot(
    Canvas canvas,
    Offset bodyOrigin,
    double w,
    double bodyH,
    PressureData pressure, {
    required double toeAreaH,
    required bool isLeft,
  }) {
    // ── 1. Zones de pression (dégradés radiaux) ───────────────────────────
    canvas.save();
    for (final zone in _pressureZones(bodyOrigin, w, bodyH, pressure, isLeft)) {
      _paintZone(canvas, zone);
    }
    canvas.restore();

    // ── 2. Badges hotspot ─────────────────────────────────────────────────
    if (showHotspotLabels) {
      for (final z in _pressureZones(bodyOrigin, w, bodyH, pressure, isLeft)) {
        if (z.value >= kHotspotThreshold) _drawBadge(canvas, z);
      }
    }
  }

  // ── Zones de pression ────────────────────────────────────────────────────

  List<_Zone> _pressureZones(
    Offset o,
    double w,
    double h,
    PressureData p,
    bool isLeft,
  ) {
    // Côté de la voûte : interne
    final double archX = isLeft ? w * 0.72 : w * 0.28;
    return [
      _Zone(
        name: 'Avant-pied',
        center: Offset(o.dx + w * 0.52, o.dy + h * 0.18),
        rx: w * 0.38,
        ry: h * 0.115,
        value: p.forefoot,
      ),
      _Zone(
        name: 'Médio-pied',
        center: Offset(o.dx + archX, o.dy + h * 0.46),
        rx: w * 0.22,
        ry: h * 0.09,
        value: p.midfoot,
      ),
      _Zone(
        name: 'Talon',
        center: Offset(o.dx + w * 0.52, o.dy + h * 0.84),
        rx: w * 0.30,
        ry: h * 0.10,
        value: p.heel,
      ),
    ];
  }

  // ── Rendu d'une zone (glow radial multi-couche) ──────────────────────────

  void _paintZone(Canvas canvas, _Zone zone) {
    final Color color = _pressureColor(zone.value);
    double rx = zone.rx;
    double ry = zone.ry;

    // Pulsation pour les hotspots
    if (zone.value >= kHotspotThreshold) {
      final double p = 0.93 + 0.07 * math.sin(animValue * 2 * math.pi);
      rx *= p;
      ry *= p;
    }

    // Opacité proportionnelle à la valeur (pas de glow si pression nulle)
    final double baseOpacity = (zone.value * 1.4).clamp(0.0, 0.85);
    if (baseOpacity < 0.04) return;

    for (int layer = 0; layer < 3; layer++) {
      final double spread = 1.0 + layer * 0.40;
      final double layerOpacity = (baseOpacity * (0.65 - layer * 0.20)).clamp(
        0,
        0.85,
      );

      final Rect rect = Rect.fromCenter(
        center: zone.center,
        width: rx * 2 * spread,
        height: ry * 2 * spread,
      );

      canvas.drawOval(
        rect,
        Paint()
          ..shader = RadialGradient(
            colors: [
              color.withValues(alpha: layerOpacity),
              color.withValues(alpha: layerOpacity * 0.35),
              Colors.transparent,
            ],
            stops: const [0.0, 0.50, 1.0],
          ).createShader(rect),
      );
    }
  }

  // ── Badge hotspot ────────────────────────────────────────────────────────

  void _drawBadge(Canvas canvas, _Zone zone) {
    final double pulse = 0.60 + 0.40 * math.sin(animValue * 2 * math.pi);
    final Color c = _pressureColor(zone.value);
    const double bw = 36, bh = 18;

    final RRect rr = RRect.fromRectAndRadius(
      Rect.fromCenter(center: zone.center, width: bw, height: bh),
      const Radius.circular(9),
    );
    canvas.drawRRect(rr, Paint()..color = c.withValues(alpha: pulse * 0.85));

    final TextPainter tp = TextPainter(
      text: TextSpan(
        text: '${(zone.value * 100).toInt()}%',
        style: TextStyle(
          color: Colors.white.withValues(alpha: pulse),
          fontSize: 9,
          fontWeight: FontWeight.w900,
          letterSpacing: -0.2,
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

  void _drawLabel(Canvas canvas, Offset pos, String text) {
    final TextPainter tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color:
              isDark
                  ? Colors.white.withValues(alpha: 0.38)
                  : const Color(0xFF374151).withValues(alpha: 0.45),
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(pos.dx - tp.width / 2, pos.dy));
  }

  // ── Palette de couleurs CdC ──────────────────────────────────────────────
  //
  // Gradients chauds : émeraude → ambre → orange → rouge profond

  Color _pressureColor(double v) {
    return SmartSoleColors.getPressureColor(v);
  }

  @override
  bool shouldRepaint(covariant _PressureMapPainter old) =>
      old.animValue != animValue ||
      old.leftPressure != leftPressure ||
      old.rightPressure != rightPressure ||
      old.isDark != isDark;
}

// ── Data structs ─────────────────────────────────────────────────────────────

class _Zone {
  const _Zone({
    required this.name,
    required this.center,
    required this.rx,
    required this.ry,
    required this.value,
  });
  final String name;
  final Offset center;
  final double rx, ry;
  final double value;
}
