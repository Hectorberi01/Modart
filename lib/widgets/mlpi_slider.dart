import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

// ─────────────────────────────────────────────────────────────────────────────
// MLPISlider v2 — Index Medio-Latéral de Pression
//
// Barre horizontale gradient (externe–centre–interne), curseur animé avec
// glow, labels typographiques, couleur BI dynamique.
// ─────────────────────────────────────────────────────────────────────────────

class MLPISlider extends StatefulWidget {
  const MLPISlider({super.key, required this.value});

  /// Valeur entre -1 (externe/supination) et +1 (interne/pronation).
  final double value;

  @override
  State<MLPISlider> createState() => _MLPISliderState();
}

class _MLPISliderState extends State<MLPISlider>
    with SingleTickerProviderStateMixin {
  late AnimationController _glowController;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final TextTheme textTheme = Theme.of(context).textTheme;
    final Color cursorColor = _mlpiColor(widget.value);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Labels
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Externe',
                style: textTheme.labelSmall?.copyWith(
                  color:
                      isDark
                          ? SmartSoleColors.textTertiaryDark
                          : SmartSoleColors.textTertiaryLight,
                ),
              ),
              Text(
                'Centre',
                style: textTheme.labelSmall?.copyWith(
                  color: cursorColor.withValues(alpha: 0.8),
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                'Interne',
                style: textTheme.labelSmall?.copyWith(
                  color:
                      isDark
                          ? SmartSoleColors.textTertiaryDark
                          : SmartSoleColors.textTertiaryLight,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),

        // Slider visuel
        SizedBox(
          height: 28,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final double w = constraints.maxWidth;
              // Map [-1, +1] → [0, w]
              final double pos =
                  ((widget.value + 1.0) / 2.0).clamp(0.0, 1.0) * w;

              return AnimatedBuilder(
                animation: _glowController,
                builder: (context, _) {
                  return CustomPaint(
                    painter: _MLPIPainter(
                      position: pos,
                      width: w,
                      cursorColor: cursorColor,
                      glowValue: _glowController.value,
                      isDark: isDark,
                    ),
                    size: Size(w, 28),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Color _mlpiColor(double v) {
    final double abs = v.abs();
    if (abs <= 0.10) return SmartSoleColors.biNormal;
    if (abs <= 0.25) return SmartSoleColors.biWarning;
    return SmartSoleColors.biAlert;
  }
}

// ─── Painter ────────────────────────────────────────────────────────────────

class _MLPIPainter extends CustomPainter {
  _MLPIPainter({
    required this.position,
    required this.width,
    required this.cursorColor,
    required this.glowValue,
    required this.isDark,
  });

  final double position;
  final double width;
  final Color cursorColor;
  final double glowValue;
  final bool isDark;

  @override
  void paint(Canvas canvas, Size size) {
    final double trackY = size.height / 2;
    final double trackH = 3.0;
    final double cursorR = 7.0;

    // ── Track ─────────────────────────────────────────────────────────────
    final RRect trackRRect = RRect.fromLTRBR(
      0,
      trackY - trackH / 2,
      width,
      trackY + trackH / 2,
      const Radius.circular(2),
    );

    final Paint trackPaint =
        Paint()
          ..shader = LinearGradient(
            colors: [
              SmartSoleColors.biTeal.withValues(alpha: 0.30),
              SmartSoleColors.biNormal.withValues(alpha: 0.40),
              SmartSoleColors.biWarning.withValues(alpha: 0.30),
            ],
            stops: const [0.0, 0.5, 1.0],
          ).createShader(Rect.fromLTWH(0, trackY - trackH / 2, width, trackH));

    canvas.drawRRect(trackRRect, trackPaint);

    // ── Centre marker ─────────────────────────────────────────────────────
    final Paint centerPaint =
        Paint()
          ..color =
              isDark
                  ? Colors.white.withValues(alpha: 0.15)
                  : Colors.black.withValues(alpha: 0.10)
          ..strokeWidth = 1.0;
    canvas.drawLine(
      Offset(width / 2, trackY - 6),
      Offset(width / 2, trackY + 6),
      centerPaint,
    );

    // ── Glow sous le curseur ──────────────────────────────────────────────
    final double glowRadius = cursorR * 3 + glowValue * 4;
    final Paint glowPaint =
        Paint()
          ..shader = RadialGradient(
            colors: [
              cursorColor.withValues(alpha: 0.20 + glowValue * 0.08),
              cursorColor.withValues(alpha: 0),
            ],
          ).createShader(
            Rect.fromCircle(
              center: Offset(position, trackY),
              radius: glowRadius,
            ),
          );
    canvas.drawCircle(Offset(position, trackY), glowRadius, glowPaint);

    // ── Curseur ───────────────────────────────────────────────────────────
    final Paint cursorShadow =
        Paint()
          ..color = cursorColor.withValues(alpha: 0.3)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawCircle(Offset(position, trackY), cursorR, cursorShadow);

    final Paint cursorPaint = Paint()..color = cursorColor;
    canvas.drawCircle(Offset(position, trackY), cursorR, cursorPaint);

    // Point blanc central
    final Paint innerPaint = Paint()..color = Colors.white;
    canvas.drawCircle(Offset(position, trackY), 2.5, innerPaint);
  }

  @override
  bool shouldRepaint(covariant _MLPIPainter old) {
    return old.position != position ||
        old.cursorColor != cursorColor ||
        old.glowValue != glowValue;
  }
}
