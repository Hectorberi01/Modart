import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/pressure_data.dart';

// ─────────────────────────────────────────────────────────────────────────────
// PressureMapPainter — LE WIDGET CENTRAL de SmartSole
//
// CustomPainter : contours de pied G+D, 4 zones par pied (heel, midfoot,
// forefoot, toe). RadialGradient animé par zone : vert→jaune→orange→rouge
// selon la pression normalisée. Labels hotspot pulsants si seuil dépassé.
// ─────────────────────────────────────────────────────────────────────────────

/// Seuil à partir duquel une zone est considérée comme "hotspot".
const double kHotspotThreshold = 0.40;

class PressureMapWidget extends StatefulWidget {
  const PressureMapWidget({
    super.key,
    required this.leftPressure,
    required this.rightPressure,
    this.showHotspotLabels = true,
    this.height = 380,
  });

  /// Données de pression pied gauche.
  final PressureData leftPressure;

  /// Données de pression pied droit.
  final PressureData rightPressure;

  /// Afficher les labels hotspot sur les zones en surcharge.
  final bool showHotspotLabels;

  /// Hauteur du widget.
  final double height;

  @override
  State<PressureMapWidget> createState() => _PressureMapWidgetState();
}

class _PressureMapWidgetState extends State<PressureMapWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _animController,
        builder: (context, _) {
          return CustomPaint(
            painter: _PressureMapPainter(
              leftPressure: widget.leftPressure,
              rightPressure: widget.rightPressure,
              showHotspotLabels: widget.showHotspotLabels,
              animationValue: _animController.value,
              isDark: isDark,
            ),
            size: Size(double.infinity, widget.height),
          );
        },
      ),
    );
  }
}

class _PressureMapPainter extends CustomPainter {
  _PressureMapPainter({
    required this.leftPressure,
    required this.rightPressure,
    required this.showHotspotLabels,
    required this.animationValue,
    required this.isDark,
  });

  final PressureData leftPressure;
  final PressureData rightPressure;
  final bool showHotspotLabels;
  final double animationValue;
  final bool isDark;

  @override
  void paint(Canvas canvas, Size size) {
    final double footWidth = size.width * 0.32;
    final double footHeight = size.height * 0.85;
    final double spacing = size.width * 0.06;

    // Pied gauche — centré côté gauche
    final Offset leftCenter = Offset(
      size.width / 2 - footWidth / 2 - spacing,
      size.height / 2,
    );

    // Pied droit — centré côté droit
    final Offset rightCenter = Offset(
      size.width / 2 + footWidth / 2 + spacing,
      size.height / 2,
    );

    _drawFoot(canvas, leftCenter, footWidth, footHeight, leftPressure, true);
    _drawFoot(canvas, rightCenter, footWidth, footHeight, rightPressure, false);

    // Labels "G" et "D"
    _drawLabel(canvas, Offset(leftCenter.dx, size.height * 0.06), 'G');
    _drawLabel(canvas, Offset(rightCenter.dx, size.height * 0.06), 'D');
  }

  void _drawFoot(
    Canvas canvas,
    Offset center,
    double width,
    double height,
    PressureData pressure,
    bool isLeft,
  ) {
    final double top = center.dy - height / 2;

    // ── Contour du pied ─────────────────────────────────────────────────────
    final Path footPath = _createFootPath(center, width, height, isLeft);
    final Paint outlinePaint =
        Paint()
          ..color =
              isDark
                  ? Colors.white.withValues(alpha: 0.15)
                  : Colors.black.withValues(alpha: 0.1)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5;
    canvas.drawPath(footPath, outlinePaint);

    // ── Zones de pression (de haut en bas : toe, forefoot, midfoot, heel) ──
    final List<_PressureZone> zones = [
      _PressureZone(
        name: 'Orteil',
        center: Offset(center.dx, top + height * 0.08),
        radius: width * 0.28,
        value: pressure.toe,
      ),
      _PressureZone(
        name: 'Avant-pied',
        center: Offset(center.dx, top + height * 0.28),
        radius: width * 0.42,
        value: pressure.forefoot,
      ),
      _PressureZone(
        name: 'Médio-pied',
        center: Offset(
          center.dx + (isLeft ? width * 0.05 : -width * 0.05),
          top + height * 0.52,
        ),
        radius: width * 0.30,
        value: pressure.midfoot,
      ),
      _PressureZone(
        name: 'Talon',
        center: Offset(center.dx, top + height * 0.80),
        radius: width * 0.38,
        value: pressure.heel,
      ),
    ];

    for (final zone in zones) {
      _drawPressureZone(canvas, zone);
    }
  }

  Path _createFootPath(Offset center, double w, double h, bool isLeft) {
    final Path path = Path();
    final double top = center.dy - h / 2;
    final double left = center.dx - w / 2;
    final double right = center.dx + w / 2;

    // Contour simplifié du pied (forme anatomique approximative)
    final double archSide = isLeft ? right : left;
    final double outerSide = isLeft ? left : right;

    path.moveTo(center.dx, top); // Orteils haut

    // Arc des orteils
    path.quadraticBezierTo(
      outerSide - (isLeft ? -w * 0.15 : w * 0.15),
      top + h * 0.05,
      outerSide,
      top + h * 0.15,
    );

    // Côté externe
    path.quadraticBezierTo(
      outerSide - (isLeft ? -w * 0.08 : w * 0.08),
      top + h * 0.35,
      outerSide - (isLeft ? -w * 0.05 : w * 0.05),
      top + h * 0.55,
    );

    // Talon
    path.quadraticBezierTo(
      outerSide - (isLeft ? -w * 0.05 : w * 0.05),
      top + h * 0.85,
      center.dx,
      top + h,
    );

    // Remontée côté interne (voûte plantaire)
    path.quadraticBezierTo(
      archSide + (isLeft ? -w * 0.05 : w * 0.05),
      top + h * 0.85,
      archSide + (isLeft ? -w * 0.15 : w * 0.15),
      top + h * 0.55,
    );

    // Voûte
    path.quadraticBezierTo(
      archSide + (isLeft ? -w * 0.25 : w * 0.25),
      top + h * 0.38,
      archSide,
      top + h * 0.18,
    );

    // Retour orteils
    path.quadraticBezierTo(
      archSide + (isLeft ? -w * 0.1 : w * 0.1),
      top + h * 0.05,
      center.dx,
      top,
    );

    path.close();
    return path;
  }

  void _drawPressureZone(Canvas canvas, _PressureZone zone) {
    // Pulse animation pour les hotspots
    double radius = zone.radius;
    if (zone.value >= kHotspotThreshold) {
      final double pulse = math.sin(animationValue * 2 * math.pi) * 0.08;
      radius *= (1.0 + pulse);
    }

    // Couleur dépend de la pression : vert → jaune → orange → rouge
    final Color zoneColor = _pressureColor(zone.value);

    final Paint paint =
        Paint()
          ..shader = RadialGradient(
            colors: [
              zoneColor.withValues(alpha: 0.7),
              zoneColor.withValues(alpha: 0.2),
              zoneColor.withValues(alpha: 0),
            ],
            stops: const [0.0, 0.6, 1.0],
          ).createShader(Rect.fromCircle(center: zone.center, radius: radius));

    canvas.drawCircle(zone.center, radius, paint);

    // Label hotspot si activé et au-dessus du seuil
    if (showHotspotLabels && zone.value >= kHotspotThreshold) {
      final double alpha = 0.6 + 0.4 * math.sin(animationValue * 2 * math.pi);
      _drawHotspotLabel(canvas, zone, alpha);
    }
  }

  void _drawHotspotLabel(Canvas canvas, _PressureZone zone, double alpha) {
    final TextPainter tp = TextPainter(
      text: TextSpan(
        text: '${(zone.value * 100).toInt()}%',
        style: TextStyle(
          color: Colors.white.withValues(alpha: alpha),
          fontSize: 11,
          fontWeight: FontWeight.w700,
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

  void _drawLabel(Canvas canvas, Offset position, String text) {
    final TextPainter tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color:
              isDark
                  ? Colors.white.withValues(alpha: 0.5)
                  : Colors.black.withValues(alpha: 0.3),
          fontSize: 14,
          fontWeight: FontWeight.w700,
          letterSpacing: 1,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    tp.paint(canvas, Offset(position.dx - tp.width / 2, position.dy));
  }

  /// Couleur interpolée selon la pression : vert → jaune → orange → rouge.
  Color _pressureColor(double value) {
    if (value <= 0.20) return SmartSoleColors.biNormal;
    if (value <= 0.30) {
      final double t = (value - 0.20) / 0.10;
      return Color.lerp(SmartSoleColors.biNormal, const Color(0xFFE2B93B), t)!;
    }
    if (value <= 0.40) {
      final double t = (value - 0.30) / 0.10;
      return Color.lerp(const Color(0xFFE2B93B), SmartSoleColors.biWarning, t)!;
    }
    final double t = ((value - 0.40) / 0.20).clamp(0.0, 1.0);
    return Color.lerp(SmartSoleColors.biWarning, SmartSoleColors.biAlert, t)!;
  }

  @override
  bool shouldRepaint(covariant _PressureMapPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue ||
        oldDelegate.leftPressure != leftPressure ||
        oldDelegate.rightPressure != rightPressure ||
        oldDelegate.isDark != isDark;
  }
}

class _PressureZone {
  const _PressureZone({
    required this.name,
    required this.center,
    required this.radius,
    required this.value,
  });

  final String name;
  final Offset center;
  final double radius;
  final double value; // 0.0 → 1.0
}
