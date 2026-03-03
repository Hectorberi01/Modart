import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

// ─────────────────────────────────────────────────────────────────────────────
// GlassBentoCard — Composant glassmorphism réutilisable
//
// BackdropFilter blur + fond semi-transparent + bordure fine + ombre subtile.
// S'adapte au dark/light mode. Supporte une pulsation en cas d'alerte BI.
// ─────────────────────────────────────────────────────────────────────────────

class GlassBentoCard extends StatefulWidget {
  const GlassBentoCard({
    super.key,
    required this.child,
    this.accentColor,
    this.pulseOnAlert = false,
    this.padding,
    this.width,
    this.height,
    this.onTap,
    this.brightnessBoost = false,
  });

  /// Contenu de la carte.
  final Widget child;

  /// Couleur d'accent optionnelle — colore la bordure et le glow.
  final Color? accentColor;

  /// Active une animation de pulsation (utile pour les alertes BI).
  final bool pulseOnAlert;

  /// Padding customisable (défaut : SmartSoleDesign.cardPadding).
  final EdgeInsetsGeometry? padding;

  /// Dimensions optionnelles.
  final double? width;
  final double? height;

  /// Callback tap optionnel.
  final VoidCallback? onTap;

  /// Luminosité augmentée de 20% — utilisé par NarrativeCard.
  final bool brightnessBoost;

  @override
  State<GlassBentoCard> createState() => _GlassBentoCardState();
}

class _GlassBentoCardState extends State<GlassBentoCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.04).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    if (widget.pulseOnAlert) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant GlassBentoCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.pulseOnAlert && !_pulseController.isAnimating) {
      _pulseController.repeat(reverse: true);
    } else if (!widget.pulseOnAlert && _pulseController.isAnimating) {
      _pulseController.stop();
      _pulseController.reset();
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
    final Color bgColor =
        widget.brightnessBoost
            ? (isDark ? const Color(0x2EFFFFFF) : const Color(0x4DFFFFFF))
            : (isDark
                ? SmartSoleColors.glassBgDark
                : SmartSoleColors.glassBgLight);

    final Color borderColor =
        widget.accentColor?.withValues(alpha: 0.3) ??
        (isDark ? SmartSoleColors.glassBorder : const Color(0x22000000));

    Widget card = ClipRRect(
      borderRadius: BorderRadius.circular(SmartSoleDesign.borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: SmartSoleDesign.blurSigma,
          sigmaY: SmartSoleDesign.blurSigma,
        ),
        child: Container(
          width: widget.width,
          height: widget.height,
          padding:
              widget.padding ??
              const EdgeInsets.all(SmartSoleDesign.cardPadding),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(SmartSoleDesign.borderRadius),
            border: Border.all(
              color: borderColor,
              width: SmartSoleDesign.glassBorderWidth,
            ),
            boxShadow: [
              BoxShadow(
                color:
                    widget.accentColor?.withValues(alpha: 0.1) ??
                    Colors.black.withValues(alpha: isDark ? 0.3 : 0.06),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: widget.child,
        ),
      ),
    );

    // Envelopper dans un ScaleTransition si pulsation active.
    if (widget.pulseOnAlert) {
      card = ScaleTransition(scale: _pulseAnimation, child: card);
    }

    // Envelopper dans un GestureDetector si tap activé.
    if (widget.onTap != null) {
      card = GestureDetector(onTap: widget.onTap, child: card);
    }

    return card;
  }
}
