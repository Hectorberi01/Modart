import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

// ─────────────────────────────────────────────────────────────────────────────
// CustomLoadingIndicator — Loader GIF animé avec anneau pulsant
//
// Utilisé dans l'_AuthGate et partout où l'app doit indiquer un chargement.
// Paramètres optionnels : size, assetName (loading1.gif | loading2.gif), label.
// ─────────────────────────────────────────────────────────────────────────────

class CustomLoadingIndicator extends StatefulWidget {
  final double size;
  final String assetName;
  final String? label;

  const CustomLoadingIndicator({
    super.key,
    this.size = 60.0,
    this.assetName = 'assets/images/loading1.gif',
    this.label,
  });

  @override
  State<CustomLoadingIndicator> createState() =>
      _CustomLoadingIndicatorState();
}

class _CustomLoadingIndicatorState extends State<CustomLoadingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.15, end: 0.65).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedBuilder(
          animation: _pulseAnim,
          builder: (context, child) {
            return Container(
              width: widget.size + 20,
              height: widget.size + 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: SmartSoleColors.biNormal.withValues(
                    alpha: _pulseAnim.value * 0.5,
                  ),
                  width: 1.5,
                ),
              ),
              child: child,
            );
          },
          child: Center(
            child: SizedBox(
              width: widget.size,
              height: widget.size,
              child: Image.asset(
                widget.assetName,
                fit: BoxFit.contain,
                semanticLabel: widget.label ?? 'Chargement en cours',
              ),
            ),
          ),
        ),
        if (widget.label != null) ...[
          const SizedBox(height: 14),
          Text(
            widget.label!,
            style: const TextStyle(
              fontFamily: 'Articulat CF',
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: SmartSoleColors.textTertiaryDark,
            ),
          ),
        ],
      ],
    );
  }
}
