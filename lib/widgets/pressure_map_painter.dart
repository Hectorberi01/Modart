import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../models/pressure_data.dart';
import '../theme/app_theme.dart';

const double kHotspotThreshold = 0.38;

const double _kNatX0 = 5.0;
const double _kNatY0 = 80.0;
const double _kNatBW = 100.0;
const double _kNatBH = 150.0;

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
      child: AnimatedBuilder(
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
    );
  }
}

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
    const double widthRatio = 0.40;
    final double footH = size.height * 0.88;
    final double footW = footH * widthRatio;
    final double gap = size.width * 0.05;
    final double toeAreaH = footH * 0.38;
    final double bodyH = footH - toeAreaH;

    final Offset leftO = Offset(
      size.width / 2 - footW - gap,
      (size.height - footH) / 2 + toeAreaH,
    );
    final Offset rightO = Offset(
      size.width / 2 + gap,
      (size.height - footH) / 2 + toeAreaH,
    );

    _drawFoot(
      canvas,
      leftO,
      footW,
      bodyH,
      leftPressure,
      toeAreaH,
      isLeft: true,
    );
    _drawFoot(
      canvas,
      rightO,
      footW,
      bodyH,
      rightPressure,
      toeAreaH,
      isLeft: false,
    );

    _drawLabel(canvas, leftO.translate(footW / 2, -toeAreaH - 10), 'G');
    _drawLabel(canvas, rightO.translate(footW / 2, -toeAreaH - 10), 'D');
  }

  void _drawFoot(
    Canvas canvas,
    Offset o,
    double w,
    double bodyH,
    PressureData pressure,
    double toeAreaH, {
    required bool isLeft,
  }) {
    final double sx = w / _kNatBW;
    final double sy = bodyH / _kNatBH;

    final Float64List m =
        isLeft
            ? Float64List.fromList([
              sx,
              0,
              0,
              0,
              0,
              sy,
              0,
              0,
              0,
              0,
              1,
              0,
              o.dx - _kNatX0 * sx,
              o.dy - _kNatY0 * sy,
              0,
              1,
            ])
            : Float64List.fromList([
              -sx,
              0,
              0,
              0,
              0,
              sy,
              0,
              0,
              0,
              0,
              1,
              0,
              o.dx + w + _kNatX0 * sx,
              o.dy - _kNatY0 * sy,
              0,
              1,
            ]);

    final Path clipPath = _buildNativeSole().transform(m);

    final Color silFill = (isDark ? Colors.white : const Color(0xFF374151))
        .withValues(alpha: isDark ? 0.10 : 0.06);
    final Color silStroke = (isDark ? Colors.white : const Color(0xFF374151))
        .withValues(alpha: isDark ? 0.22 : 0.18);

    canvas.drawPath(clipPath, Paint()..color = silFill);

    canvas.save();
    canvas.clipPath(clipPath);
    for (final z in _pressureZones(o, w, bodyH, pressure, isLeft)) {
      _paintZone(canvas, z);
    }
    canvas.restore();

    canvas.drawPath(
      clipPath,
      Paint()
        ..color = silStroke
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    _drawToes(canvas, o, w, bodyH, toeAreaH, isLeft, silFill, silStroke);

    if (showHotspotLabels) {
      for (final z in _pressureZones(o, w, bodyH, pressure, isLeft)) {
        if (z.value >= kHotspotThreshold) _drawBadge(canvas, z);
      }
    }
  }

  Path _buildNativeSole() {
    return Path()
      ..moveTo(35, 80)
      ..quadraticBezierTo(55, 65, 85, 75)
      ..quadraticBezierTo(105, 90, 75, 140)
      ..quadraticBezierTo(65, 160, 70, 190)
      ..quadraticBezierTo(75, 230, 45, 230)
      ..quadraticBezierTo(15, 230, 25, 180)
      ..quadraticBezierTo(35, 130, 15, 100)
      ..quadraticBezierTo(5, 80, 35, 80)
      ..close();
  }

  void _drawToes(
    Canvas canvas,
    Offset o,
    double w,
    double bodyH,
    double toeAreaH,
    bool isLeft,
    Color fill,
    Color stroke,
  ) {
    final double sx = w / _kNatBW;
    final double sy = bodyH / _kNatBH;

    const List<List<double>> nativeToes = [
      [80, 35, 30, 45, -0.15],
      [50, 32, 22, 34, -0.05],
      [28, 42, 18, 28, 0.10],
      [10, 60, 16, 22, 0.30],
      [-2, 82, 14, 18, 0.50],
    ];

    for (final t in nativeToes) {
      final double absCx =
          isLeft
              ? o.dx + (t[0] - _kNatX0) * sx
              : o.dx + w - (t[0] - _kNatX0) * sx;
      final double absCy = o.dy + (t[1] - _kNatY0) * sy;
      final double tw = t[2] * sx;
      final double th = t[3] * sy;
      final double angle = isLeft ? t[4] : -t[4];

      canvas.save();
      canvas.translate(absCx, absCy);
      canvas.rotate(angle);
      final Rect r = Rect.fromCenter(
        center: Offset.zero,
        width: tw,
        height: th,
      );
      canvas.drawOval(r, Paint()..color = fill);
      canvas.drawOval(
        r,
        Paint()
          ..color = stroke
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2,
      );
      canvas.restore();
    }
  }

  List<_Zone> _pressureZones(
    Offset o,
    double w,
    double h,
    PressureData p,
    bool isLeft,
  ) {
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

  void _paintZone(Canvas canvas, _Zone zone) {
    final Color color = SmartSoleColors.getPressureColor(zone.value);
    double rx = zone.rx;
    double ry = zone.ry;

    if (zone.value >= kHotspotThreshold) {
      final double pulse = 0.93 + 0.07 * math.sin(animValue * 2 * math.pi);
      rx *= pulse;
      ry *= pulse;
    }

    final double baseOpacity = (zone.value * 1.4).clamp(0.0, 0.85);
    if (baseOpacity < 0.04) return;

    for (int layer = 0; layer < 3; layer++) {
      final double spread = 1.0 + layer * 0.40;
      final double layerOpacity = (baseOpacity * (0.65 - layer * 0.20)).clamp(
        0.0,
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

  void _drawBadge(Canvas canvas, _Zone zone) {
    final double pulse = 0.60 + 0.40 * math.sin(animValue * 2 * math.pi);
    final Color c = SmartSoleColors.getPressureColor(zone.value);
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

  @override
  bool shouldRepaint(covariant _PressureMapPainter old) =>
      old.animValue != animValue ||
      old.leftPressure != leftPressure ||
      old.rightPressure != rightPressure ||
      old.isDark != isDark;
}

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
