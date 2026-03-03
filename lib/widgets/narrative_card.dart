import 'package:flutter/material.dart';
import 'glass_bento_card.dart';

// ─────────────────────────────────────────────────────────────────────────────
// NarrativeCard — Carte de narration BI coach
//
// GlassBentoCard avec luminosité augmentée, icône coach à gauche,
// 2 phrases texte avec apparition en fondu.
// ─────────────────────────────────────────────────────────────────────────────

class NarrativeCard extends StatefulWidget {
  const NarrativeCard({super.key, required this.narratives, this.accentColor});

  /// Liste des phrases narratives BI (max 2 recommandées).
  final List<String> narratives;

  /// Couleur d'accent optionnelle.
  final Color? accentColor;

  @override
  State<NarrativeCard> createState() => _NarrativeCardState();
}

class _NarrativeCardState extends State<NarrativeCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    );
    _fadeController.forward();
  }

  @override
  void didUpdateWidget(covariant NarrativeCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.narratives != widget.narratives) {
      _fadeController.reset();
      _fadeController.forward();
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return GlassBentoCard(
      brightnessBoost: true,
      accentColor: widget.accentColor,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icône coach
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: (widget.accentColor ?? Colors.white).withValues(
                  alpha: isDark ? 0.1 : 0.08,
                ),
              ),
              child: Icon(
                Icons.psychology_outlined,
                size: 22,
                color:
                    widget.accentColor ??
                    (isDark ? Colors.white70 : Colors.black54),
              ),
            ),
            const SizedBox(width: 12),
            // Phrases narratives
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Coach BI',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color:
                          widget.accentColor ??
                          (isDark ? Colors.white54 : Colors.black38),
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  ...widget.narratives.map(
                    (text) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        text,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: isDark ? Colors.white : Colors.black87,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
