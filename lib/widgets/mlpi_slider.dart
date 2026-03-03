import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

// ─────────────────────────────────────────────────────────────────────────────
// MLPISlider — Index de Pression Médio-Latéral
//
// Barre horizontale de -1 (externe/supination) à +1 (interne/pronation).
// Le curseur s'anime vers la valeur courante. Couleur dynamique BI.
// ─────────────────────────────────────────────────────────────────────────────

class MLPISlider extends StatelessWidget {
  const MLPISlider({super.key, required this.value, this.height = 56});

  /// Valeur MLPI : -1 (externe) → 0 (centré) → +1 (interne).
  final double value;

  /// Hauteur totale du widget.
  final double height;

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final double clampedValue = value.clamp(-1.0, 1.0);

    // Couleur du curseur selon la déviation
    final Color cursorColor = _colorForValue(clampedValue.abs());

    return SizedBox(
      height: height,
      child: Column(
        children: [
          // Labels
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Externe',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color:
                        isDark
                            ? SmartSoleColors.textSecondaryDark
                            : SmartSoleColors.textSecondaryLight,
                  ),
                ),
                Text(
                  'Centre',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: cursorColor,
                  ),
                ),
                Text(
                  'Interne',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color:
                        isDark
                            ? SmartSoleColors.textSecondaryDark
                            : SmartSoleColors.textSecondaryLight,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Barre + curseur
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final double barWidth = constraints.maxWidth;
                // Position du curseur : -1 → gauche, 0 → centre, +1 → droite
                final double cursorX =
                    (barWidth / 2) + (clampedValue * barWidth / 2);

                return Stack(
                  alignment: Alignment.centerLeft,
                  children: [
                    // Barre de fond
                    Container(
                      height: 6,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(3),
                        color:
                            isDark
                                ? Colors.white.withValues(alpha: 0.08)
                                : Colors.black.withValues(alpha: 0.06),
                      ),
                    ),
                    // Marqueur centre
                    Positioned(
                      left: barWidth / 2 - 0.5,
                      child: Container(
                        width: 1,
                        height: 14,
                        color:
                            isDark
                                ? Colors.white.withValues(alpha: 0.2)
                                : Colors.black.withValues(alpha: 0.15),
                      ),
                    ),
                    // Curseur animé
                    AnimatedPositioned(
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.easeOutCubic,
                      left: cursorX - 8,
                      child: Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: cursorColor,
                          boxShadow: [
                            BoxShadow(
                              color: cursorColor.withValues(alpha: 0.4),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Couleur selon la déviation absolue : teal (centré) → ambre → rouge.
  Color _colorForValue(double absValue) {
    if (absValue < 0.15) return SmartSoleColors.biTeal;
    if (absValue < 0.30) return SmartSoleColors.biWarning;
    return SmartSoleColors.biAlert;
  }
}
