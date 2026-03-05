import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

// ─────────────────────────────────────────────────────────────────────────────
// GlassBentoCard v2 — Glassmorphism raffiné
//
// Blur doux, bordure subtile avec accent lumineux, micro-animation tap,
// ombre portée légère, pulsation optionnelle pour les alertes BI.
// ─────────────────────────────────────────────────────────────────────────────

class GlassBentoCard extends StatefulWidget {
  const GlassBentoCard({
    super.key,
    required this.child,
    this.accentColor,
    this.pulseOnAlert = false,
    this.onTap,
    this.padding = const EdgeInsets.all(16),
    this.borderRadius,
  });

  final Widget child;
  final Color? accentColor;
  final bool pulseOnAlert;
  final VoidCallback? onTap;
  final EdgeInsets padding;
  final double? borderRadius;

  @override
  State<GlassBentoCard> createState() => _GlassBentoCardState();
}

class _GlassBentoCardState extends State<GlassBentoCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );
    _pulseAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOutSine),
    );
    if (widget.pulseOnAlert) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(GlassBentoCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.pulseOnAlert && !_pulseController.isAnimating) {
      _pulseController.repeat(reverse: true);
    } else if (!widget.pulseOnAlert && _pulseController.isAnimating) {
      _pulseController.stop();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final double radius = widget.borderRadius ?? SmartSoleDesign.borderRadius;

    return GestureDetector(
      onTap: widget.onTap,
      onTapDown:
          widget.onTap != null
              ? (_) => setState(() => _isPressed = true)
              : null,
      onTapUp:
          widget.onTap != null
              ? (_) => setState(() => _isPressed = false)
              : null,
      onTapCancel:
          widget.onTap != null
              ? () => setState(() => _isPressed = false)
              : null,
      child: AnimatedScale(
        scale: _isPressed ? 0.97 : 1.0,
        duration: SmartSoleDesign.animFast,
        curve: SmartSoleDesign.animCurve,
        child: AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            final double pulseValue =
                widget.pulseOnAlert ? _pulseAnimation.value : 0;

            final Color borderColor =
                widget.accentColor != null
                    ? widget.accentColor!.withValues(
                      alpha: 0.15 + pulseValue * 0.15,
                    )
                    : isDark
                    ? SmartSoleColors.glassBorderDark
                    : SmartSoleColors.glassBorderLight;

            return Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(radius),
                boxShadow: [
                  // Ombre portée subtile
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.06),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                  // Lueur accent si couleur active
                  if (widget.accentColor != null && pulseValue > 0)
                    BoxShadow(
                      color: widget.accentColor!.withValues(
                        alpha: 0.08 * pulseValue,
                      ),
                      blurRadius: 30,
                      spreadRadius: 2,
                    ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(radius),
                child: BackdropFilter(
                  filter: ImageFilter.blur(
                    sigmaX: SmartSoleDesign.blurSigma,
                    sigmaY: SmartSoleDesign.blurSigma,
                  ),
                  child: Container(
                    padding: widget.padding,
                    decoration: BoxDecoration(
                      color:
                          isDark
                              ? SmartSoleColors.glassDark
                              : SmartSoleColors.glassLight,
                      borderRadius: BorderRadius.circular(radius),
                      border: Border.all(color: borderColor, width: 1.0),
                      // Gradient interne subtil (lumière en haut à gauche)
                      gradient:
                          isDark
                              ? LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Colors.white.withValues(alpha: 0.05),
                                  Colors.white.withValues(alpha: 0.01),
                                ],
                              )
                              : null,
                    ),
                    child: child,
                  ),
                ),
              ),
            );
          },
          child: widget.child,
        ),
      ),
    );
  }
}
